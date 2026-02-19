# Übung 8.3: Auth-Middleware & geschützte Routen

## Ziel

Implementiere ein vollständiges Autorisierungssystem mit Middleware, Rollen und Guards.

---

## Aufgabe 1: Auth Middleware (15 min)

```dart
// lib/middleware/auth_middleware.dart

/// Authentication Middleware
/// - Extrahiert JWT aus Authorization Header
/// - Verifiziert Token
/// - Fügt Payload zum Request-Context hinzu
Middleware authMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Authorization Header lesen
      // 2. Token extrahieren (Bearer-Schema)
      // 3. Token verifizieren mit jwtService
      // 4. Prüfen ob es ein Access Token ist
      // 5. Payload in request.context speichern
      // 6. Bei Fehler: 401 Response zurückgeben
    };
  };
}

/// Hilfsfunktion: Auth-Payload aus Request lesen
JwtPayload? getAuthPayload(Request request) {
  // TODO: Aus request.context lesen
}

/// Hilfsfunktion: User-ID aus Request lesen
int? getUserId(Request request) {
  // TODO: Aus Payload extrahieren
}
```

---

## Aufgabe 2: Optional Auth Middleware (10 min)

```dart
// lib/middleware/optional_auth_middleware.dart

/// Fügt Auth-Info hinzu wenn vorhanden, aber erzwingt keine Auth
Middleware optionalAuthMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Token extrahieren (wenn vorhanden)
      // 2. Token verifizieren (Fehler ignorieren)
      // 3. Bei gültigem Token: Payload zum Context
      // 4. Immer zum Handler weiter
    };
  };
}
```

---

## Aufgabe 3: Role-Based Access Control (20 min)

### Role Enum

```dart
// lib/models/role.dart

enum Role {
  guest,
  user,
  moderator,
  admin,
  superadmin;

  /// Hierarchie-Level
  int get level {
    // TODO: Level für jede Rolle (0-100)
  }

  /// Hat diese Rolle mindestens required?
  bool hasAtLeast(Role required) {
    // TODO: Level-Vergleich
  }

  /// String zu Role konvertieren
  static Role fromString(String? value) {
    // TODO: Fallback auf guest
  }
}
```

### Role Middleware

```dart
// lib/middleware/role_middleware.dart

/// Middleware die eine Mindest-Rolle erfordert
Middleware requireRole(Role requiredRole) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Auth-Payload holen
      // 2. Rolle aus Payload extrahieren
      // 3. Rolle prüfen mit hasAtLeast
      // 4. 401 wenn nicht authentifiziert
      // 5. 403 wenn unzureichende Rolle
    };
  };
}

// Convenience-Funktionen
Middleware requireAdmin() => requireRole(Role.admin);
Middleware requireModerator() => requireRole(Role.moderator);
Middleware requireUser() => requireRole(Role.user);
```

---

## Aufgabe 4: Permission-Based Access Control (15 min)

```dart
// lib/models/permission.dart

class Permission {
  // Definiere Permissions als Konstanten
  static const String readUsers = 'users:read';
  static const String writeUsers = 'users:write';
  static const String deleteUsers = 'users:delete';

  static const String readProducts = 'products:read';
  static const String writeProducts = 'products:write';
  static const String deleteProducts = 'products:delete';

  // TODO: Weitere Permissions nach Bedarf

  /// Permissions pro Rolle definieren
  static const Map<Role, Set<String>> rolePermissions = {
    // TODO: Permissions für jede Rolle
    // guest: {}
    // user: {readProducts}
    // moderator: {readProducts, writeProducts}
    // admin: alle Products + Users
    // superadmin: alles
  };

  /// Prüfen ob Rolle eine Permission hat
  static bool hasPermission(Role role, String permission) {
    // TODO: Implementieren (Superadmin hat alle Rechte)
  }
}

/// Permission Middleware
Middleware requirePermission(String permission) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Auth-Payload holen
      // 2. Permission prüfen mit hasPermission
      // 3. 403 wenn nicht erlaubt
    };
  };
}
```

---

## Aufgabe 5: Owner Guard (15 min)

```dart
// lib/guards/owner_guard.dart

/// Guard der prüft ob User der Owner einer Ressource ist
///
/// Beispiel: User kann nur eigene Orders sehen/bearbeiten
Middleware ownerGuard({
  required String paramName,
  required Future<int?> Function(int resourceId) getOwnerId,
  bool allowAdmin = true,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Auth-Payload prüfen
      // 2. Resource-ID aus URL-Params extrahieren
      // 3. Admin-Bypass wenn allowAdmin=true
      // 4. Owner-ID laden mit getOwnerId
      // 5. Mit aktuellem User vergleichen
      // 6. 403 wenn nicht Owner
    };
  };
}
```

---

## Aufgabe 6: Protected Router (20 min)

```dart
// lib/routes/api_router.dart

class ApiRouter {
  final JwtService _jwtService;
  final AuthHandler _authHandler;
  final UserHandler _userHandler;
  final ProductHandler _productHandler;
  final OrderHandler _orderHandler;

  ApiRouter({
    required JwtService jwtService,
    required AuthHandler authHandler,
    required UserHandler userHandler,
    required ProductHandler productHandler,
    required OrderHandler orderHandler,
  })  : _jwtService = jwtService,
        _authHandler = authHandler,
        _userHandler = userHandler,
        _productHandler = productHandler,
        _orderHandler = orderHandler;

  Handler get handler {
    final router = Router();

    // Öffentliche Routen
    router.mount('/auth', _publicAuthRoutes);
    router.mount('/products', _publicProductRoutes);

    // Geschützte User-Routen
    router.mount('/users', _protectedUserRoutes);

    // Geschützte Order-Routen
    router.mount('/orders', _protectedOrderRoutes);

    // Admin-Routen
    router.mount('/admin', _adminRoutes);

    return router;
  }

  Handler get _publicAuthRoutes {
    // TODO: Auth-Routen ohne Middleware
  }

  Handler get _publicProductRoutes {
    final router = Router();
    // TODO: GET / und GET /<id> ohne Auth
    return router;
  }

  Handler get _protectedUserRoutes {
    // TODO:
    // GET /me - eigenes Profil
    // PUT /me - Profil bearbeiten
    // DELETE /me - Account löschen
    // Mit authMiddleware
  }

  Handler get _protectedOrderRoutes {
    // TODO:
    // GET / - eigene Orders
    // POST / - neue Order
    // GET /<id> - nur eigene Order (ownerGuard)
    // Mit authMiddleware + ownerGuard
  }

  Handler get _adminRoutes {
    // TODO:
    // CRUD für alle User/Products/Orders
    // Mit authMiddleware + requireAdmin
  }
}
```

---

## Aufgabe 7: Handler mit Context (10 min)

```dart
// lib/handlers/user_handler.dart

class UserHandler {
  final UserService _userService;

  UserHandler(this._userService);

  /// GET /users/me - Eigenes Profil
  Future<Response> getMe(Request request) async {
    // TODO:
    // 1. userId aus Context holen
    // 2. User laden
    // 3. Als JSON zurückgeben
  }

  /// PUT /users/me - Profil bearbeiten
  Future<Response> updateMe(Request request) async {
    // TODO:
    // 1. userId aus Context
    // 2. Body parsen
    // 3. Update durchführen
    // 4. Aktualisiertes Profil zurückgeben
  }

  /// DELETE /users/me - Account löschen
  Future<Response> deleteMe(Request request) async {
    // TODO:
    // 1. userId aus Context
    // 2. Account deaktivieren/löschen
    // 3. 204 No Content zurückgeben
  }
}
```

---

## Aufgabe 8: Integration Test (Bonus, 15 min)

```dart
// test/middleware/auth_middleware_test.dart

void main() {
  late JwtService jwtService;
  late Handler testHandler;

  setUp(() {
    jwtService = JwtService(secret: 'test-secret-key-at-least-32-chars');

    final innerHandler = (Request request) {
      final userId = getUserId(request);
      return Response.ok('User: $userId');
    };

    testHandler = const Pipeline()
        .addMiddleware(authMiddleware(jwtService))
        .addHandler(innerHandler);
  });

  test('rejects request without token', () async {
    final request = Request('GET', Uri.parse('http://localhost/test'));
    final response = await testHandler(request);

    expect(response.statusCode, equals(401));
  });

  test('rejects request with invalid token', () async {
    final request = Request(
      'GET',
      Uri.parse('http://localhost/test'),
      headers: {'authorization': 'Bearer invalid-token'},
    );
    final response = await testHandler(request);

    expect(response.statusCode, equals(401));
  });

  test('accepts request with valid token', () async {
    // TODO:
    // 1. Gültigen Token generieren
    // 2. Request mit Token senden
    // 3. 200 OK erwarten
    // 4. Body prüfen
  });

  test('adds user info to context', () async {
    // TODO:
    // 1. Token für User mit ID 123 generieren
    // 2. Request senden
    // 3. Prüfen ob Handler die User-ID aus Context bekommt
  });
}
```

---

## Testen

### Ohne Token

```bash
curl http://localhost:8080/api/users/me
# 401 {"error": "No authorization token provided"}
```

### Mit gültigem Token

```bash
# Zuerst einloggen
TOKEN=$(curl -s -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@example.com", "password": "Password123!"}' \
  | jq -r '.access_token')

# Geschützte Route aufrufen
curl http://localhost:8080/api/users/me \
  -H "Authorization: Bearer $TOKEN"
# 200 {"id": 1, "email": "user@example.com", ...}
```

### Admin-Route als User

```bash
curl http://localhost:8080/api/admin/users \
  -H "Authorization: Bearer $TOKEN"
# 403 {"error": "Insufficient permissions. Required: admin"}
```

### Fremde Ressource

```bash
curl http://localhost:8080/api/orders/999 \
  -H "Authorization: Bearer $TOKEN"
# 403 {"error": "You do not own this resource"}
```

---

## Abgabe-Checkliste

- [ ] authMiddleware mit Token-Extraktion und -Verifizierung
- [ ] optionalAuthMiddleware
- [ ] Hilfsfunktionen getAuthPayload und getUserId
- [ ] Role Enum mit Level-System
- [ ] requireRole Middleware
- [ ] Permission-Klasse mit Rollen-Mapping
- [ ] requirePermission Middleware
- [ ] ownerGuard mit Admin-Bypass
- [ ] ApiRouter mit öffentlichen und geschützten Routen
- [ ] Handler die userId aus Context nutzen
- [ ] (Bonus) Integration Tests

