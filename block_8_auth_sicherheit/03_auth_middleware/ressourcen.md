# Ressourcen: Auth-Middleware & geschützte Routen

## Offizielle Dokumentation

- [Shelf Middleware](https://pub.dev/documentation/shelf/latest/shelf/Middleware.html)
- [shelf_router Package](https://pub.dev/packages/shelf_router)
- [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)

## Cheat Sheet: Shelf Middleware

```dart
// Middleware Grundstruktur
Middleware myMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // VOR dem Handler
      // ...

      // Handler aufrufen
      final response = await innerHandler(request);

      // NACH dem Handler
      // ...

      return response;
    };
  };
}

// Middleware verketten
final handler = const Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(authMiddleware(jwtService))
    .addMiddleware(requireRole(Role.admin))
    .addHandler(router);
```

## Cheat Sheet: Request Context

```dart
// Wert zum Context hinzufügen
final updatedRequest = request.change(
  context: {
    ...request.context,
    'userId': 123,
    'role': 'admin',
  },
);

// Wert aus Context lesen
final userId = request.context['userId'] as int?;

// Typ-sichere Helper-Funktion
T? getContext<T>(Request request, String key) {
  return request.context[key] as T?;
}
```

## Cheat Sheet: HTTP Status Codes

| Code | Name | Verwendung |
|------|------|------------|
| 200 | OK | Erfolgreiche Anfrage |
| 201 | Created | Ressource erstellt |
| 204 | No Content | Erfolg ohne Body |
| 400 | Bad Request | Ungültige Anfrage |
| **401** | **Unauthorized** | **Nicht authentifiziert** |
| **403** | **Forbidden** | **Keine Berechtigung** |
| 404 | Not Found | Ressource nicht gefunden |
| 409 | Conflict | Konflikt (z.B. Duplikat) |
| 429 | Too Many Requests | Rate Limit |
| 500 | Internal Server Error | Server-Fehler |

## Cheat Sheet: Role-Based Access Control

```dart
// Hierarchisches Rollen-System
enum Role {
  guest(0),
  user(10),
  moderator(50),
  admin(90),
  superadmin(100);

  final int level;
  const Role(this.level);

  bool hasAtLeast(Role other) => level >= other.level;
}

// Middleware
Middleware requireRole(Role required) {
  return (Handler handler) => (Request request) async {
    final userRole = getUserRole(request);
    if (!userRole.hasAtLeast(required)) {
      return Response(403, body: 'Forbidden');
    }
    return handler(request);
  };
}
```

## Cheat Sheet: Permission-Based Access Control

```dart
// Permissions als Konstanten
class Permissions {
  static const read = 'resource:read';
  static const write = 'resource:write';
  static const delete = 'resource:delete';
  static const admin = 'resource:admin';
}

// Rollen → Permissions Mapping
final rolePermissions = {
  Role.user: {Permissions.read},
  Role.moderator: {Permissions.read, Permissions.write},
  Role.admin: {Permissions.read, Permissions.write, Permissions.delete},
};

// Middleware
Middleware requirePermission(String permission) {
  return (Handler handler) => (Request request) async {
    final role = getUserRole(request);
    if (!hasPermission(role, permission)) {
      return Response(403, body: 'Missing permission: $permission');
    }
    return handler(request);
  };
}
```

## Cheat Sheet: Guard Patterns

```dart
// Owner Guard
Middleware ownerGuard(Future<int?> Function(int) getOwnerId) {
  return (Handler handler) => (Request request) async {
    final resourceId = getResourceId(request);
    final userId = getUserId(request);
    final ownerId = await getOwnerId(resourceId);

    if (ownerId != userId && !isAdmin(request)) {
      return Response(403, body: 'Not owner');
    }
    return handler(request);
  };
}

// Self-or-Admin Guard
Middleware selfOrAdmin({String param = 'id'}) {
  return (Handler handler) => (Request request) async {
    final targetId = int.parse(request.params[param]!);
    final userId = getUserId(request);

    if (targetId != userId && !isAdmin(request)) {
      return Response(403, body: 'Access denied');
    }
    return handler(request);
  };
}
```

## Cheat Sheet: Route Protection

```dart
// Mit Pipeline (Gruppen)
final publicRouter = Router()
  ..get('/products', listProducts)
  ..get('/products/<id>', getProduct);

final protectedRouter = const Pipeline()
    .addMiddleware(authMiddleware(jwt))
    .addHandler(Router()
      ..get('/orders', listOrders)
      ..post('/orders', createOrder));

final adminRouter = const Pipeline()
    .addMiddleware(authMiddleware(jwt))
    .addMiddleware(requireAdmin())
    .addHandler(Router()
      ..get('/users', listUsers)
      ..delete('/users/<id>', deleteUser));

// Mit Cascade
final cascade = Cascade()
    .add(publicRouter)
    .add(protectedRouter)
    .add(adminRouter);
```

## Best Practices

### DO

1. **401 vs 403 unterscheiden**
   - 401: Nicht authentifiziert (kein/ungültiger Token)
   - 403: Authentifiziert, aber keine Berechtigung

2. **Principle of Least Privilege**
   - Nur nötige Berechtigungen vergeben
   - Standardmäßig alles verbieten

3. **Defense in Depth**
   - Mehrere Sicherheitsebenen
   - Middleware + Handler-Prüfungen

4. **Generische Fehlermeldungen**
   - Keine Details über Berechtigungssystem
   - "Access denied" statt "Admin required"

### DON'T

1. **Autorisierung nur im Frontend**
   - Backend muss immer prüfen

2. **Berechtigungen in JWT speichern (langlebig)**
   - Bei Änderungen bleiben alte Tokens gültig

3. **Hardcoded Rollen-Checks**
   - Nutze flexibles System mit Permissions

4. **Ungeprüfte URL-Parameter**
   - Immer validieren und autorisieren

## Häufige Patterns

```dart
// Optional Auth (öffentlich, aber mit User-Info wenn eingeloggt)
router.get('/products', (Request request) async {
  final userId = getUserId(request); // Kann null sein
  final products = await getProducts(userId: userId);
  return Response.ok(jsonEncode(products));
});

// Eigene Ressourcen filtern
router.get('/orders', (Request request) async {
  final userId = getUserId(request)!;
  final orders = await orderRepo.findByUser(userId);
  return Response.ok(jsonEncode(orders));
});

// Admin sieht alles, User nur eigenes
router.get('/orders', (Request request) async {
  final userId = getUserId(request)!;
  final role = getUserRole(request);

  final orders = role.hasAtLeast(Role.admin)
      ? await orderRepo.findAll()
      : await orderRepo.findByUser(userId);

  return Response.ok(jsonEncode(orders));
});
```

