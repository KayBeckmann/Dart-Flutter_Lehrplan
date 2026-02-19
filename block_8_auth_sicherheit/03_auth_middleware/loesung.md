# Lösung 8.3: Auth-Middleware & geschützte Routen

## Auth Middleware

```dart
// lib/middleware/auth_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/jwt_service.dart';
import '../models/jwt_payload.dart';
import '../exceptions/auth_exceptions.dart';

/// Authentication Middleware
Middleware authMiddleware(JwtService jwtService) {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. Authorization Header lesen
      final authHeader = request.headers['authorization'];
      final token = jwtService.extractTokenFromHeader(authHeader);

      if (token == null) {
        return _errorResponse(401, 'No authorization token provided');
      }

      // 2. Token verifizieren
      try {
        final payload = jwtService.verifyToken(token);

        // 3. Nur Access Tokens akzeptieren
        if (!payload.isAccessToken) {
          return _errorResponse(401, 'Invalid token type');
        }

        // 4. Payload in Context speichern
        final updatedRequest = request.change(
          context: {
            ...request.context,
            'auth': payload,
            'userId': payload.userId,
            'userRole': payload.role,
          },
        );

        return innerHandler(updatedRequest);
      } on TokenExpiredException {
        return _errorResponse(401, 'Token has expired');
      } on InvalidTokenException catch (e) {
        return _errorResponse(401, e.message);
      } catch (e) {
        return _errorResponse(401, 'Invalid token');
      }
    };
  };
}

/// Optional Authentication Middleware
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
                'userRole': payload.role,
              },
            );
            return innerHandler(updatedRequest);
          }
        } catch (e) {
          // Token ungültig - ignorieren
        }
      }

      return innerHandler(request);
    };
  };
}

// Hilfsfunktionen
JwtPayload? getAuthPayload(Request request) {
  return request.context['auth'] as JwtPayload?;
}

int? getUserId(Request request) {
  return request.context['userId'] as int?;
}

String? getUserRole(Request request) {
  return request.context['userRole'] as String?;
}

Response _errorResponse(int statusCode, String message) {
  return Response(
    statusCode,
    body: jsonEncode({'error': message}),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Role System

```dart
// lib/models/role.dart

enum Role {
  guest,
  user,
  moderator,
  admin,
  superadmin;

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

  bool hasAtLeast(Role required) => level >= required.level;

  bool canManage(Role other) => level > other.level;

  static Role fromString(String? value) {
    if (value == null) return Role.guest;
    return Role.values.firstWhere(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
      orElse: () => Role.guest,
    );
  }

  String get displayName {
    switch (this) {
      case Role.guest:
        return 'Guest';
      case Role.user:
        return 'User';
      case Role.moderator:
        return 'Moderator';
      case Role.admin:
        return 'Administrator';
      case Role.superadmin:
        return 'Super Administrator';
    }
  }
}
```

---

## Role Middleware

```dart
// lib/middleware/role_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../models/role.dart';
import 'auth_middleware.dart';

/// Middleware die eine Mindest-Rolle erfordert
Middleware requireRole(Role requiredRole) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!userRole.hasAtLeast(requiredRole)) {
        return Response(
          403,
          body: jsonEncode({
            'error': 'Insufficient permissions',
            'required': requiredRole.name,
            'current': userRole.name,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

// Convenience-Funktionen
Middleware requireAdmin() => requireRole(Role.admin);
Middleware requireModerator() => requireRole(Role.moderator);
Middleware requireUser() => requireRole(Role.user);
Middleware requireSuperadmin() => requireRole(Role.superadmin);
```

---

## Permission System

```dart
// lib/models/permission.dart
import 'role.dart';

class Permission {
  // User Permissions
  static const String readUsers = 'users:read';
  static const String writeUsers = 'users:write';
  static const String deleteUsers = 'users:delete';

  // Product Permissions
  static const String readProducts = 'products:read';
  static const String writeProducts = 'products:write';
  static const String deleteProducts = 'products:delete';

  // Order Permissions
  static const String readOrders = 'orders:read';
  static const String writeOrders = 'orders:write';
  static const String deleteOrders = 'orders:delete';

  // Admin Permissions
  static const String manageRoles = 'roles:manage';
  static const String viewLogs = 'logs:view';
  static const String manageSettings = 'settings:manage';

  /// Permissions pro Rolle
  static const Map<Role, Set<String>> rolePermissions = {
    Role.guest: {
      readProducts,
    },
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
      viewLogs,
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
      viewLogs,
    },
    Role.superadmin: {
      // Hat alle Permissions (wird in hasPermission gehandelt)
    },
  };

  /// Alle verfügbaren Permissions
  static Set<String> get allPermissions => {
        readUsers, writeUsers, deleteUsers,
        readProducts, writeProducts, deleteProducts,
        readOrders, writeOrders, deleteOrders,
        manageRoles, viewLogs, manageSettings,
      };

  /// Prüfen ob Rolle eine Permission hat
  static bool hasPermission(Role role, String permission) {
    // Superadmin hat alle Rechte
    if (role == Role.superadmin) return true;

    return rolePermissions[role]?.contains(permission) ?? false;
  }

  /// Mehrere Permissions prüfen (alle müssen erfüllt sein)
  static bool hasAllPermissions(Role role, List<String> permissions) {
    return permissions.every((p) => hasPermission(role, p));
  }

  /// Mindestens eine Permission haben
  static bool hasAnyPermission(Role role, List<String> permissions) {
    return permissions.any((p) => hasPermission(role, p));
  }
}
```

---

## Permission Middleware

```dart
// lib/middleware/permission_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../models/role.dart';
import '../models/permission.dart';
import 'auth_middleware.dart';

/// Middleware die eine bestimmte Permission erfordert
Middleware requirePermission(String permission) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!Permission.hasPermission(userRole, permission)) {
        return Response(
          403,
          body: jsonEncode({
            'error': 'Missing permission',
            'required': permission,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Mehrere Permissions erforderlich (alle)
Middleware requireAllPermissions(List<String> permissions) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!Permission.hasAllPermissions(userRole, permissions)) {
        final missing = permissions
            .where((p) => !Permission.hasPermission(userRole, p))
            .toList();
        return Response(
          403,
          body: jsonEncode({
            'error': 'Missing permissions',
            'required': missing,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Mindestens eine Permission erforderlich
Middleware requireAnyPermission(List<String> permissions) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final userRole = Role.fromString(payload.role);

      if (!Permission.hasAnyPermission(userRole, permissions)) {
        return Response(
          403,
          body: jsonEncode({
            'error': 'Requires at least one of these permissions',
            'required': permissions,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}
```

---

## Owner Guard

```dart
// lib/guards/owner_guard.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../models/role.dart';
import '../middleware/auth_middleware.dart';

/// Guard der prüft ob User der Owner einer Ressource ist
Middleware ownerGuard({
  required String paramName,
  required Future<int?> Function(int resourceId) getOwnerId,
  bool allowAdmin = true,
  Role? adminRole,
}) {
  final requiredAdminRole = adminRole ?? Role.admin;

  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Resource-ID aus URL-Params
      final resourceIdStr = request.params[paramName];
      if (resourceIdStr == null) {
        // Kein Parameter - weiter zum Handler
        return innerHandler(request);
      }

      final resourceId = int.tryParse(resourceIdStr);
      if (resourceId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid resource ID'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Admin-Bypass
      if (allowAdmin) {
        final userRole = Role.fromString(payload.role);
        if (userRole.hasAtLeast(requiredAdminRole)) {
          return innerHandler(request);
        }
      }

      // Owner prüfen
      final ownerId = await getOwnerId(resourceId);

      if (ownerId == null) {
        return Response(
          404,
          body: jsonEncode({'error': 'Resource not found'}),
          headers: {'content-type': 'application/json'},
        );
      }

      if (ownerId != payload.userId) {
        return Response(
          403,
          body: jsonEncode({'error': 'You do not own this resource'}),
          headers: {'content-type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

/// Selbst-oder-Admin Guard
/// Erlaubt Zugriff wenn User sich selbst oder Admin
Middleware selfOrAdminGuard({String paramName = 'id'}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = getAuthPayload(request);

      if (payload == null) {
        return Response(
          401,
          body: jsonEncode({'error': 'Authentication required'}),
          headers: {'content-type': 'application/json'},
        );
      }

      final targetIdStr = request.params[paramName];
      if (targetIdStr == null) {
        return innerHandler(request);
      }

      final targetId = int.tryParse(targetIdStr);
      if (targetId == null) {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid ID'}),
          headers: {'content-type': 'application/json'},
        );
      }

      // Selbst?
      if (targetId == payload.userId) {
        return innerHandler(request);
      }

      // Admin?
      final userRole = Role.fromString(payload.role);
      if (userRole.hasAtLeast(Role.admin)) {
        return innerHandler(request);
      }

      return Response(
        403,
        body: jsonEncode({'error': 'Access denied'}),
        headers: {'content-type': 'application/json'},
      );
    };
  };
}
```

---

## API Router

```dart
// lib/routes/api_router.dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/jwt_service.dart';
import '../handlers/auth_handler.dart';
import '../handlers/user_handler.dart';
import '../handlers/product_handler.dart';
import '../handlers/order_handler.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../guards/owner_guard.dart';
import '../models/permission.dart';
import '../repositories/order_repository.dart';

class ApiRouter {
  final JwtService _jwtService;
  final AuthHandler _authHandler;
  final UserHandler _userHandler;
  final ProductHandler _productHandler;
  final OrderHandler _orderHandler;
  final OrderRepository _orderRepo;

  ApiRouter({
    required JwtService jwtService,
    required AuthHandler authHandler,
    required UserHandler userHandler,
    required ProductHandler productHandler,
    required OrderHandler orderHandler,
    required OrderRepository orderRepo,
  })  : _jwtService = jwtService,
        _authHandler = authHandler,
        _userHandler = userHandler,
        _productHandler = productHandler,
        _orderHandler = orderHandler,
        _orderRepo = orderRepo;

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
    return _authHandler.router;
  }

  Handler get _publicProductRoutes {
    final router = Router();
    router.get('/', _productHandler.list);
    router.get('/<id>', _productHandler.get);
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

  Handler get _protectedOrderRoutes {
    final router = Router();

    // Liste eigener Orders
    router.get('/', _orderHandler.listMine);

    // Neue Order erstellen
    router.post('/', _orderHandler.create);

    // Einzelne Order (nur eigene oder Admin)
    final orderDetailRouter = Router();
    orderDetailRouter.get('/<id>', _orderHandler.get);
    orderDetailRouter.put('/<id>', _orderHandler.update);
    orderDetailRouter.delete('/<id>', _orderHandler.cancel);

    router.mount(
      '/',
      const Pipeline()
          .addMiddleware(ownerGuard(
            paramName: 'id',
            getOwnerId: (id) async {
              final order = await _orderRepo.findById(id);
              return order?.userId;
            },
          ))
          .addHandler(orderDetailRouter),
    );

    return const Pipeline()
        .addMiddleware(authMiddleware(_jwtService))
        .addHandler(router);
  }

  Handler get _adminRoutes {
    final router = Router();

    // User Management
    router.get('/users', _userHandler.listAll);
    router.get('/users/<id>', _userHandler.getById);
    router.put('/users/<id>', _userHandler.updateById);
    router.delete('/users/<id>', _userHandler.deleteById);

    // Product Management
    router.post('/products', _productHandler.create);
    router.put('/products/<id>', _productHandler.update);
    router.delete('/products/<id>', _productHandler.delete);

    // Order Management
    router.get('/orders', _orderHandler.listAll);
    router.get('/orders/<id>', _orderHandler.getAny);
    router.put('/orders/<id>', _orderHandler.updateAny);

    return const Pipeline()
        .addMiddleware(authMiddleware(_jwtService))
        .addMiddleware(requireAdmin())
        .addHandler(router);
  }
}
```

---

## User Handler

```dart
// lib/handlers/user_handler.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/user_service.dart';
import '../middleware/auth_middleware.dart';

class UserHandler {
  final UserService _userService;

  UserHandler(this._userService);

  /// GET /users/me - Eigenes Profil
  Future<Response> getMe(Request request) async {
    final userId = getUserId(request);

    if (userId == null) {
      return Response(401,
        body: jsonEncode({'error': 'Not authenticated'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final user = await _userService.findById(userId);

    if (user == null) {
      return Response(404,
        body: jsonEncode({'error': 'User not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(user.toPublicJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  /// PUT /users/me - Profil bearbeiten
  Future<Response> updateMe(Request request) async {
    final userId = getUserId(request);

    if (userId == null) {
      return Response(401,
        body: jsonEncode({'error': 'Not authenticated'}),
        headers: {'content-type': 'application/json'},
      );
    }

    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final user = await _userService.update(userId, data);

      return Response.ok(
        jsonEncode(user.toPublicJson()),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response(400,
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  /// DELETE /users/me - Account löschen
  Future<Response> deleteMe(Request request) async {
    final userId = getUserId(request);

    if (userId == null) {
      return Response(401,
        body: jsonEncode({'error': 'Not authenticated'}),
        headers: {'content-type': 'application/json'},
      );
    }

    await _userService.deactivate(userId);

    return Response(204);
  }

  /// GET /admin/users - Alle User (Admin)
  Future<Response> listAll(Request request) async {
    final users = await _userService.findAll();

    return Response.ok(
      jsonEncode(users.map((u) => u.toPublicJson()).toList()),
      headers: {'content-type': 'application/json'},
    );
  }

  /// GET /admin/users/:id - User by ID (Admin)
  Future<Response> getById(Request request) async {
    final id = int.tryParse(request.params['id'] ?? '');

    if (id == null) {
      return Response(400,
        body: jsonEncode({'error': 'Invalid ID'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final user = await _userService.findById(id);

    if (user == null) {
      return Response(404,
        body: jsonEncode({'error': 'User not found'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode(user.toPublicJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> updateById(Request request) async {
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) {
      return Response(400,
        body: jsonEncode({'error': 'Invalid ID'}),
        headers: {'content-type': 'application/json'},
      );
    }

    final body = await request.readAsString();
    final data = jsonDecode(body) as Map<String, dynamic>;

    final user = await _userService.update(id, data);

    return Response.ok(
      jsonEncode(user.toPublicJson()),
      headers: {'content-type': 'application/json'},
    );
  }

  Future<Response> deleteById(Request request) async {
    final id = int.tryParse(request.params['id'] ?? '');
    if (id == null) {
      return Response(400,
        body: jsonEncode({'error': 'Invalid ID'}),
        headers: {'content-type': 'application/json'},
      );
    }

    await _userService.deactivate(id);

    return Response(204);
  }
}
```

---

## Tests

```dart
// test/middleware/auth_middleware_test.dart
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import '../lib/services/jwt_service.dart';
import '../lib/middleware/auth_middleware.dart';
import '../lib/models/user.dart';

void main() {
  late JwtService jwtService;

  setUp(() {
    jwtService = JwtService(
      secret: 'test-secret-key-that-is-long-enough-for-testing',
    );
  });

  group('authMiddleware', () {
    test('rejects request without token', () async {
      final handler = const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler((r) => Response.ok('OK'));

      final request = Request('GET', Uri.parse('http://localhost/test'));
      final response = await handler(request);

      expect(response.statusCode, equals(401));
    });

    test('rejects invalid token', () async {
      final handler = const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler((r) => Response.ok('OK'));

      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer invalid'},
      );
      final response = await handler(request);

      expect(response.statusCode, equals(401));
    });

    test('accepts valid token and adds context', () async {
      final user = User(
        id: 123,
        email: 'test@example.com',
        passwordHash: 'hash',
        role: 'user',
      );

      final token = jwtService.generateAccessToken(user);

      int? receivedUserId;
      final handler = const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler((r) {
            receivedUserId = getUserId(r);
            return Response.ok('OK');
          });

      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $token'},
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(receivedUserId, equals(123));
    });
  });
}
```

