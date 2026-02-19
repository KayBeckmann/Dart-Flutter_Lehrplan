# Einheit 8.3: Auth-Middleware & geschützte Routen

## Lernziele

Nach dieser Einheit kannst du:
- Authentication Middleware implementieren
- Routen mit Berechtigungen schützen
- Role-Based Access Control (RBAC) umsetzen
- Guards für verschiedene Anforderungen erstellen

---

## Middleware-Konzept

Middleware sitzt zwischen dem HTTP-Request und deinem Handler:

```
Request → Middleware 1 → Middleware 2 → Handler → Response
              ↓              ↓
         (Logging)    (Auth-Check)
```

### Shelf Middleware

```dart
import 'package:shelf/shelf.dart';

Middleware myMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // VOR dem Handler
      print('Request: ${request.method} ${request.url}');

      // Handler aufrufen
      final response = await innerHandler(request);

      // NACH dem Handler
      print('Response: ${response.statusCode}');

      return response;
    };
  };
}
```

---

## Authentication Middleware

```dart
// lib/middleware/auth_middleware.dart
import 'package:shelf/shelf.dart';
import '../services/jwt_service.dart';
import '../models/jwt_payload.dart';

/// Middleware für JWT-Authentifizierung
Middleware authMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. Token aus Header extrahieren
      final authHeader = request.headers['authorization'];
      final token = jwtService.extractTokenFromHeader(authHeader);

      if (token == null) {
        return Response(401,
          body: '{"error": "No authorization token provided"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // 2. Token verifizieren
      try {
        final payload = jwtService.verifyToken(token);

        // Nur Access Tokens akzeptieren
        if (!payload.isAccessToken) {
          return Response(401,
            body: '{"error": "Invalid token type"}',
            headers: {'content-type': 'application/json'},
          );
        }

        // 3. Payload in Request-Context speichern
        final updatedRequest = request.change(
          context: {
            ...request.context,
            'auth': payload,
            'userId': payload.userId,
          },
        );

        return innerHandler(updatedRequest);
      } on TokenExpiredException {
        return Response(401,
          body: '{"error": "Token has expired"}',
          headers: {'content-type': 'application/json'},
        );
      } on InvalidTokenException {
        return Response(401,
          body: '{"error": "Invalid token"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

/// Hilfsfunktion: Auth-Payload aus Request lesen
JwtPayload? getAuthPayload(Request request) {
  return request.context['auth'] as JwtPayload?;
}

/// Hilfsfunktion: User-ID aus Request lesen
int? getUserId(Request request) {
  return request.context['userId'] as int?;
}
```

---

## Optionale Authentifizierung

```dart
// lib/middleware/optional_auth_middleware.dart

/// Middleware die Auth-Info hinzufügt, aber nicht erzwingt
Middleware optionalAuthMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      final token = jwtService.extractTokenFromHeader(authHeader);

      if (token != null) {
        try {
          final payload = jwtService.verifyToken(token);
          if (payload.isAccessToken) {
            final updatedRequest = request.change(
              context: {
                ...request.context,
                'auth': payload,
                'userId': payload.userId,
              },
            );
            return innerHandler(updatedRequest);
          }
        } catch (e) {
          // Token ungültig - ignorieren
        }
      }

      // Ohne Auth weiter
      return innerHandler(request);
    };
  };
}
```

---

## Role-Based Access Control (RBAC)

### Rollen-System

```dart
// lib/models/role.dart

enum Role {
  guest,
  user,
  moderator,
  admin,
  superadmin;

  /// Hierarchie-Level (höher = mehr Rechte)
  int get level {
    switch (this) {
      case Role.guest:
        return 0;
      case Role.user:
        return 10;
      case Role.moderator:
        return 50;
      case Role.admin:
        return 90;
      case Role.superadmin:
        return 100;
    }
  }

  /// Prüfen ob diese Rolle mindestens so hoch ist wie required
  bool hasAtLeast(Role required) => level >= required.level;

  static Role fromString(String? value) {
    return Role.values.firstWhere(
      (r) => r.name == value,
      orElse: () => Role.guest,
    );
  }
}
```

### Rollen-Middleware

```dart
// lib/middleware/role_middleware.dart

/// Middleware die eine Mindest-Rolle erfordert
Middleware requireRole(Role requiredRole) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(401,
          body: '{"error": "Authentication required"}',
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!userRole.hasAtLeast(requiredRole)) {
        return Response(403,
          body: '{"error": "Insufficient permissions. Required: ${requiredRole.name}"}',
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Convenience-Middleware für häufige Rollen
Middleware requireAdmin() => requireRole(Role.admin);
Middleware requireModerator() => requireRole(Role.moderator);
Middleware requireUser() => requireRole(Role.user);
```

---

## Permission-Based Access Control

```dart
// lib/models/permission.dart

class Permission {
  static const String readUsers = 'users:read';
  static const String writeUsers = 'users:write';
  static const String deleteUsers = 'users:delete';

  static const String readProducts = 'products:read';
  static const String writeProducts = 'products:write';
  static const String deleteProducts = 'products:delete';

  static const String readOrders = 'orders:read';
  static const String writeOrders = 'orders:write';
  static const String deleteOrders = 'orders:delete';

  static const String manageRoles = 'roles:manage';

  /// Permissions pro Rolle
  static const Map<Role, Set<String>> rolePermissions = {
    Role.guest: {},
    Role.user: {
      readProducts,
      readOrders,
      writeOrders,
    },
    Role.moderator: {
      readUsers,
      readProducts,
      writeProducts,
      readOrders,
      writeOrders,
    },
    Role.admin: {
      readUsers,
      writeUsers,
      readProducts,
      writeProducts,
      deleteProducts,
      readOrders,
      writeOrders,
      deleteOrders,
    },
    Role.superadmin: {
      readUsers,
      writeUsers,
      deleteUsers,
      readProducts,
      writeProducts,
      deleteProducts,
      readOrders,
      writeOrders,
      deleteOrders,
      manageRoles,
    },
  };

  static bool hasPermission(Role role, String permission) {
    // Superadmin hat alle Rechte
    if (role == Role.superadmin) return true;

    return rolePermissions[role]?.contains(permission) ?? false;
  }
}

/// Middleware die eine bestimmte Permission erfordert
Middleware requirePermission(String permission) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(401,
          body: '{"error": "Authentication required"}',
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!Permission.hasPermission(userRole, permission)) {
        return Response(403,
          body: '{"error": "Missing permission: $permission"}',
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}
```

---

## Guards

Guards sind spezialisierte Middleware für komplexere Prüfungen.

### Owner Guard

```dart
// lib/guards/owner_guard.dart

/// Guard der prüft ob der User der Owner einer Ressource ist
Middleware ownerGuard({
  required String paramName,
  required Future<int?> Function(int resourceId) getOwnerId,
  bool allowAdmin = true,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);
      if (payload == null) {
        return Response(401,
          body: '{"error": "Authentication required"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Ressourcen-ID aus URL-Parametern
      final resourceIdStr = request.params[paramName];
      if (resourceIdStr == null) {
        return innerHandler(request);
      }

      final resourceId = int.tryParse(resourceIdStr);
      if (resourceId == null) {
        return Response(400,
          body: '{"error": "Invalid resource ID"}',
          headers: {'content-type': 'application/json'},
        );
      }

      // Admin-Bypass
      if (allowAdmin) {
        final userRole = Role.fromString(payload.role);
        if (userRole.hasAtLeast(Role.admin)) {
          return innerHandler(request);
        }
      }

      // Owner prüfen
      final ownerId = await getOwnerId(resourceId);
      if (ownerId == null || ownerId != payload.userId) {
        return Response(403,
          body: '{"error": "You do not own this resource"}',
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}
```

### Verwendung

```dart
// Router mit Owner Guard
final router = Router();

router.get('/orders/<id>', (Request request) async {
  // Handler nur erreicht wenn User der Owner ist oder Admin
  final orderId = int.parse(request.params['id']!);
  final order = await orderRepo.findById(orderId);
  return Response.ok(jsonEncode(order?.toJson()));
});

// Mit Guard
final protectedRouter = const Pipeline()
    .addMiddleware(authMiddleware(jwtService))
    .addMiddleware(ownerGuard(
      paramName: 'id',
      getOwnerId: (id) async {
        final order = await orderRepo.findById(id);
        return order?.userId;
      },
    ))
    .addHandler(router);
```

---

## Geschützte Routen

### Router-basiert

```dart
// lib/routes/routes.dart

class Routes {
  final JwtService _jwtService;
  final AuthHandler _authHandler;
  final UserHandler _userHandler;
  final ProductHandler _productHandler;

  Routes(this._jwtService, this._authHandler, this._userHandler, this._productHandler);

  Handler get handler {
    final router = Router();

    // Öffentliche Routen
    router.mount('/api/auth', _authHandler.router);
    router.get('/api/products', _productHandler.list);
    router.get('/api/products/<id>', _productHandler.get);

    // Geschützte Routen (User)
    router.mount('/api/users', _protectedUserRoutes);

    // Admin-Routen
    router.mount('/api/admin', _adminRoutes);

    return router;
  }

  Handler get _protectedUserRoutes {
    final router = Router();

    router.get('/me', _userHandler.getMe);
    router.put('/me', _userHandler.updateMe);
    router.delete('/me', _userHandler.deleteMe);

    return const Pipeline()
        .addMiddleware(authMiddleware(_jwtService))
        .addHandler(router);
  }

  Handler get _adminRoutes {
    final router = Router();

    router.get('/users', _userHandler.listAll);
    router.get('/users/<id>', _userHandler.getById);
    router.put('/users/<id>', _userHandler.updateById);
    router.delete('/users/<id>', _userHandler.deleteById);

    return const Pipeline()
        .addMiddleware(authMiddleware(_jwtService))
        .addMiddleware(requireRole(Role.admin))
        .addHandler(router);
  }
}
```

### Handler-basiert

```dart
// lib/handlers/product_handler.dart

class ProductHandler {
  final ProductService _productService;
  final JwtService _jwtService;

  ProductHandler(this._productService, this._jwtService);

  Router get router {
    final router = Router();

    // Öffentlich
    router.get('/', list);
    router.get('/<id>', get);

    // Geschützt
    router.post('/', _withAuth(_withPermission(Permission.writeProducts, create)));
    router.put('/<id>', _withAuth(_withPermission(Permission.writeProducts, update)));
    router.delete('/<id>', _withAuth(_withPermission(Permission.deleteProducts, delete)));

    return router;
  }

  // Handler-Level Middleware
  Handler _withAuth(Handler handler) {
    return const Pipeline()
        .addMiddleware(authMiddleware(_jwtService))
        .addHandler(handler);
  }

  Handler _withPermission(String permission, Handler handler) {
    return const Pipeline()
        .addMiddleware(requirePermission(permission))
        .addHandler(handler);
  }

  // Handler-Methoden
  Future<Response> list(Request request) async {
    final products = await _productService.findAll();
    return Response.ok(jsonEncode(products.map((p) => p.toJson()).toList()));
  }

  Future<Response> create(Request request) async {
    // Nur erreicht mit gültiger Auth und Permission
    final userId = getUserId(request)!;
    // ...
  }
}
```

---

## Request Context

```dart
// lib/middleware/context_middleware.dart

/// Fügt Kontext-Informationen zum Request hinzu
Middleware contextMiddleware({
  required UserRepository userRepo,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final context = <String, Object>{
        'requestId': _generateRequestId(),
        'timestamp': DateTime.now(),
      };

      // Falls authentifiziert: User laden
      final payload = getAuthPayload(request);
      if (payload != null) {
        final user = await userRepo.findById(payload.userId);
        if (user != null) {
          context['user'] = user;
        }
      }

      final updatedRequest = request.change(
        context: {...request.context, ...context},
      );

      return innerHandler(updatedRequest);
    };
  };
}

String _generateRequestId() {
  return DateTime.now().millisecondsSinceEpoch.toRadixString(36) +
         Random().nextInt(10000).toRadixString(36);
}

/// User aus Context lesen
User? getUser(Request request) {
  return request.context['user'] as User?;
}
```

---

## Middleware-Pipeline

```dart
// bin/server.dart

void main() async {
  // Services initialisieren...

  // Routen
  final publicRouter = Router()
    ..get('/health', (_) => Response.ok('OK'))
    ..mount('/api/auth', authHandler.router)
    ..get('/api/products', productHandler.list);

  final protectedRouter = Router()
    ..mount('/api/users', userHandler.router)
    ..mount('/api/orders', orderHandler.router);

  final adminRouter = Router()
    ..mount('/api/admin/users', adminUserHandler.router)
    ..mount('/api/admin/settings', settingsHandler.router);

  // Cascade: Versucht jeden Router der Reihe nach
  final cascade = Cascade()
      .add(publicRouter)
      .add(const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler(protectedRouter))
      .add(const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addMiddleware(requireRole(Role.admin))
          .addHandler(adminRouter));

  // Globale Middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addHandler(cascade.handler);

  await serve(handler, 'localhost', 8080);
}
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| **Auth Middleware** | Prüft JWT und fügt Payload zum Context |
| **RBAC** | Zugriff basierend auf Rollen |
| **Permissions** | Feingranulare Berechtigungen |
| **Guards** | Komplexe Zugriffsprüfungen |
| **Context** | Request-spezifische Daten durchreichen |
| **Pipeline** | Middleware-Ketten für Routen |

