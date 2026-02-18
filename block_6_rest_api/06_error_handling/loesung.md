# Lösung 6.6: Error Handling & HTTP-Statuscodes

## Vollständige Lösung

```dart
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Aufgabe 1: Exception-Klassen
// ============================================

abstract class ApiException implements Exception {
  int get statusCode;
  String get code;
  String get message;
  Map<String, dynamic>? get details => null;

  Response toResponse({String? traceId}) {
    return Response(
      statusCode,
      body: jsonEncode({
        'error': {
          'code': code,
          'message': message,
          if (details != null) 'details': details,
          if (traceId != null) 'traceId': traceId,
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }
}

class NotFoundException extends ApiException {
  final String resourceType;
  final String resourceId;

  NotFoundException(this.resourceType, this.resourceId);

  @override
  int get statusCode => 404;

  @override
  String get code => 'NOT_FOUND';

  @override
  String get message => '$resourceType with ID \'$resourceId\' not found';
}

class BadRequestException extends ApiException {
  @override
  final String message;

  BadRequestException(this.message);

  @override
  int get statusCode => 400;

  @override
  String get code => 'BAD_REQUEST';
}

class ValidationError {
  final String field;
  final String message;
  final String code;

  ValidationError({required this.field, required this.message, required this.code});

  Map<String, dynamic> toJson() => {'field': field, 'message': message, 'code': code};
}

class ValidationException extends ApiException {
  final List<ValidationError> errors;

  ValidationException(this.errors);

  @override
  int get statusCode => 400;

  @override
  String get code => 'VALIDATION_ERROR';

  @override
  String get message => 'Validation failed';

  @override
  Map<String, dynamic>? get details => {
    'fields': errors.map((e) => e.toJson()).toList(),
  };
}

class UnauthorizedException extends ApiException {
  final String? customMessage;

  UnauthorizedException([this.customMessage]);

  @override
  int get statusCode => 401;

  @override
  String get code => 'UNAUTHORIZED';

  @override
  String get message => customMessage ?? 'Authentication required';
}

class ForbiddenException extends ApiException {
  final String? customMessage;

  ForbiddenException([this.customMessage]);

  @override
  int get statusCode => 403;

  @override
  String get code => 'FORBIDDEN';

  @override
  String get message => customMessage ?? 'You do not have permission to access this resource';
}

class ConflictException extends ApiException {
  @override
  final String message;

  ConflictException(this.message);

  @override
  int get statusCode => 409;

  @override
  String get code => 'CONFLICT';
}

// ============================================
// Aufgabe 2: Error Handler Middleware
// ============================================

String _generateTraceId() {
  final random = Random();
  return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
}

void _logError(String traceId, Request request, Object error, {StackTrace? stackTrace}) {
  final timestamp = DateTime.now().toIso8601String();
  print('[$timestamp] ERROR [$traceId] ${request.method} ${request.url}');
  print('  Error: $error');
  if (stackTrace != null) {
    // Nur erste 5 Zeilen des Stack Traces
    final lines = stackTrace.toString().split('\n').take(5);
    for (final line in lines) {
      print('  $line');
    }
  }
}

Middleware errorHandler({bool isDevelopment = false}) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        // Bekannte API-Fehler
        final traceId = _generateTraceId();
        if (e.statusCode >= 500) {
          _logError(traceId, request, e);
        }
        return e.toResponse(traceId: traceId);
      } on FormatException catch (e) {
        // JSON-Parsing-Fehler
        final traceId = _generateTraceId();
        return Response(400,
          body: jsonEncode({
            'error': {
              'code': 'INVALID_JSON',
              'message': 'Invalid JSON: ${e.message}',
              'traceId': traceId,
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stackTrace) {
        // Unbekannte Fehler
        final traceId = _generateTraceId();
        _logError(traceId, request, e, stackTrace: stackTrace);

        if (isDevelopment) {
          // Entwicklung: Volle Details
          return Response(500,
            body: jsonEncode({
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': e.toString(),
                'traceId': traceId,
                'stack': stackTrace.toString().split('\n').take(10).toList(),
              },
            }),
            headers: {'content-type': 'application/json'},
          );
        } else {
          // Produktion: Minimale Details
          return Response(500,
            body: jsonEncode({
              'error': {
                'code': 'INTERNAL_ERROR',
                'message': 'An unexpected error occurred',
                'traceId': traceId,
              },
            }),
            headers: {'content-type': 'application/json'},
          );
        }
      }
    };
  };
}

// ============================================
// Aufgabe 3: Helper-Funktionen
// ============================================

Response notFound(String resource, String id) {
  return Response(404,
    body: jsonEncode({
      'error': {
        'code': 'NOT_FOUND',
        'message': '$resource with ID \'$id\' not found',
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response badRequest(String message) {
  return Response(400,
    body: jsonEncode({
      'error': {
        'code': 'BAD_REQUEST',
        'message': message,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response unauthorized({String? message}) {
  return Response(401,
    body: jsonEncode({
      'error': {
        'code': 'UNAUTHORIZED',
        'message': message ?? 'Authentication required',
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response forbidden({String? message}) {
  return Response(403,
    body: jsonEncode({
      'error': {
        'code': 'FORBIDDEN',
        'message': message ?? 'Access denied',
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response conflict(String message) {
  return Response(409,
    body: jsonEncode({
      'error': {
        'code': 'CONFLICT',
        'message': message,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response validationError(List<ValidationError> errors) {
  return Response(400,
    body: jsonEncode({
      'error': {
        'code': 'VALIDATION_ERROR',
        'message': 'Validation failed',
        'details': {
          'fields': errors.map((e) => e.toJson()).toList(),
        },
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response internalError({String? traceId}) {
  return Response(500,
    body: jsonEncode({
      'error': {
        'code': 'INTERNAL_ERROR',
        'message': 'An unexpected error occurred',
        if (traceId != null) 'traceId': traceId,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

// ============================================
// Aufgabe 5: 404 Fallback Handler
// ============================================

Handler notFoundHandler() {
  return (Request request) {
    return Response(404,
      body: jsonEncode({
        'error': {
          'code': 'NOT_FOUND',
          'message': 'Endpoint ${request.method} ${request.url.path} not found',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  };
}

// ============================================
// Aufgabe 6: Request Logging (Bonus)
// ============================================

Middleware requestLogger() {
  return (Handler handler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final response = await handler(request);
      stopwatch.stop();

      final timestamp = DateTime.now().toIso8601String();
      final level = response.statusCode >= 400 ? 'ERROR' : 'INFO';
      final duration = '${stopwatch.elapsedMilliseconds}ms';

      var logLine = '[$timestamp] $level ${request.method} ${request.url.path} ${response.statusCode} $duration';

      // Bei Fehlern: Error-Details extrahieren (wenn möglich)
      if (response.statusCode >= 400) {
        // Response Body kann nur einmal gelesen werden, daher clonen
        final body = await response.readAsString();
        try {
          final json = jsonDecode(body) as Map<String, dynamic>;
          final error = json['error'] as Map<String, dynamic>?;
          if (error != null) {
            logLine += ' {"code": "${error['code']}"';
            if (error['traceId'] != null) {
              logLine += ', "traceId": "${error['traceId']}"';
            }
            logLine += '}';
          }
        } catch (_) {}
        // Response neu erstellen
        return response.change(body: body);
      }

      print(logLine);
      return response;
    };
  };
}

// ============================================
// Aufgabe 4: API Server
// ============================================

extension RequestJson on Request {
  Map<String, dynamic> get json {
    final body = context['body'];
    return body is Map<String, dynamic> ? body : {};
  }
}

Middleware jsonBodyParser() {
  return (Handler handler) {
    return (Request request) async {
      if (!['POST', 'PUT', 'PATCH'].contains(request.method)) {
        return handler(request);
      }
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return handler(request);
      }
      final body = await request.readAsString();
      if (body.isEmpty) {
        return handler(request.change(context: {...request.context, 'body': <String, dynamic>{}}));
      }
      final json = jsonDecode(body); // FormatException wird von errorHandler gefangen
      return handler(request.change(context: {...request.context, 'body': json}));
    };
  };
}

// User Storage
final _users = <String, Map<String, dynamic>>{};
var _nextUserId = 1;

void _seedUsers() {
  _users['user-1'] = {
    'id': 'user-1',
    'name': 'Max Mustermann',
    'email': 'max@example.com',
    'age': 30,
    'createdAt': DateTime.now().toIso8601String(),
  };
  _nextUserId = 2;
}

// Validation
List<ValidationError> validateUser(Map<String, dynamic> data, {bool isUpdate = false, String? excludeEmail}) {
  final errors = <ValidationError>[];

  // Name
  final name = data['name'] as String?;
  if (!isUpdate || data.containsKey('name')) {
    if (name == null || name.isEmpty) {
      errors.add(ValidationError(field: 'name', message: 'name is required', code: 'REQUIRED'));
    } else if (name.length < 2) {
      errors.add(ValidationError(field: 'name', message: 'name must be at least 2 characters', code: 'MIN_LENGTH'));
    } else if (name.length > 100) {
      errors.add(ValidationError(field: 'name', message: 'name must be at most 100 characters', code: 'MAX_LENGTH'));
    }
  }

  // Email
  final email = data['email'] as String?;
  if (!isUpdate || data.containsKey('email')) {
    if (email == null || email.isEmpty) {
      errors.add(ValidationError(field: 'email', message: 'email is required', code: 'REQUIRED'));
    } else {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        errors.add(ValidationError(field: 'email', message: 'email must be a valid email', code: 'INVALID_EMAIL'));
      }
    }
  }

  // Age (optional)
  final age = data['age'] as int?;
  if (age != null && (age < 0 || age > 150)) {
    errors.add(ValidationError(field: 'age', message: 'age must be between 0 and 150', code: 'RANGE'));
  }

  return errors;
}

bool emailExists(String email, {String? excludeId}) {
  return _users.values.any((u) => u['email'] == email && u['id'] != excludeId);
}

// Handlers
Response listUsers(Request request) {
  return jsonResponse({
    'data': _users.values.toList(),
    'total': _users.length,
  });
}

Response getUser(Request request, String id) {
  final user = _users[id];
  if (user == null) {
    throw NotFoundException('User', id);
  }
  return jsonResponse(user);
}

Response createUser(Request request) {
  final body = request.json;

  // Validierung
  final errors = validateUser(body);
  if (errors.isNotEmpty) {
    throw ValidationException(errors);
  }

  // Duplikat-Check
  final email = body['email'] as String;
  if (emailExists(email)) {
    throw ConflictException('A user with email \'$email\' already exists');
  }

  // User erstellen
  final id = 'user-${_nextUserId++}';
  final user = {
    'id': id,
    'name': body['name'],
    'email': email,
    if (body['age'] != null) 'age': body['age'],
    'createdAt': DateTime.now().toIso8601String(),
  };
  _users[id] = user;

  return Response(201,
    body: jsonEncode(user),
    headers: {
      'content-type': 'application/json',
      'location': '/api/users/$id',
    },
  );
}

Response updateUser(Request request, String id) {
  final existing = _users[id];
  if (existing == null) {
    throw NotFoundException('User', id);
  }

  final body = request.json;

  // Validierung
  final errors = validateUser(body, isUpdate: true);
  if (errors.isNotEmpty) {
    throw ValidationException(errors);
  }

  // Duplikat-Check (wenn Email geändert wird)
  final email = body['email'] as String?;
  if (email != null && emailExists(email, excludeId: id)) {
    throw ConflictException('A user with email \'$email\' already exists');
  }

  // Update
  final updated = {
    ...existing,
    if (body['name'] != null) 'name': body['name'],
    if (body['email'] != null) 'email': body['email'],
    if (body.containsKey('age')) 'age': body['age'],
    'updatedAt': DateTime.now().toIso8601String(),
  };
  _users[id] = updated;

  return jsonResponse(updated);
}

Response deleteUser(Request request, String id) {
  if (_users.remove(id) == null) {
    throw NotFoundException('User', id);
  }
  return Response(204);
}

// Simulierter Fehler für Tests
Response simulateError(Request request) {
  throw Exception('This is a simulated internal error');
}

// ============================================
// Main
// ============================================

void main() async {
  _seedUsers();

  final router = Router();

  // User CRUD
  router.get('/api/users', listUsers);
  router.get('/api/users/<id>', getUser);
  router.post('/api/users', createUser);
  router.put('/api/users/<id>', updateUser);
  router.delete('/api/users/<id>', deleteUser);

  // Test-Endpoint für 500 Error
  router.get('/api/error', simulateError);

  // Pipeline mit Error Handler
  final handler = Pipeline()
      .addMiddleware(requestLogger())
      .addMiddleware(errorHandler(isDevelopment: true))
      .addMiddleware(jsonBodyParser())
      .addHandler(Cascade()
          .add(router.call)
          .add(notFoundHandler())
          .handler);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('');
  print('Test-Befehle:');
  print('  curl http://localhost:8080/api/users');
  print('  curl http://localhost:8080/api/users/user-1');
  print('  curl http://localhost:8080/api/users/not-exists  # 404');
  print('  curl http://localhost:8080/api/unknown  # 404 route');
  print('  curl http://localhost:8080/api/error  # 500');
}
```

---

## Test-Befehle

```bash
# ========== Erfolgreiche Requests ==========

# Liste alle User
curl http://localhost:8080/api/users

# Einen User abrufen
curl http://localhost:8080/api/users/user-1

# User erstellen
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Anna Schmidt", "email": "anna@test.de", "age": 25}'

# User aktualisieren
curl -X PUT http://localhost:8080/api/users/user-1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Max Updated"}'

# User löschen
curl -X DELETE http://localhost:8080/api/users/user-2

# ========== Fehler-Szenarien ==========

# 404 - User nicht gefunden
curl http://localhost:8080/api/users/not-exists

# 404 - Route nicht gefunden
curl http://localhost:8080/api/unknown

# 400 - Validierungsfehler
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "A"}'

# 400 - Ungültige Email
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "email": "invalid"}'

# 400 - Ungültiges JSON
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{invalid json}'

# 409 - Duplikat
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max Copy", "email": "max@example.com"}'

# 500 - Interner Fehler
curl http://localhost:8080/api/error

# Mit Response-Headers anzeigen
curl -i http://localhost:8080/api/users/not-exists
```

---

## Ausgabe-Beispiele

### 404 Not Found

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User with ID 'not-exists' not found",
    "traceId": "a1b2c3d4e5f6g7h8"
  }
}
```

### 400 Validation Error

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "fields": [
        {
          "field": "name",
          "message": "name must be at least 2 characters",
          "code": "MIN_LENGTH"
        },
        {
          "field": "email",
          "message": "email is required",
          "code": "REQUIRED"
        }
      ]
    },
    "traceId": "b2c3d4e5f6g7h8i9"
  }
}
```

### 409 Conflict

```json
{
  "error": {
    "code": "CONFLICT",
    "message": "A user with email 'max@example.com' already exists",
    "traceId": "c3d4e5f6g7h8i9j0"
  }
}
```

### 500 Internal Error (Development)

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "Exception: This is a simulated internal error",
    "traceId": "d4e5f6g7h8i9j0k1",
    "stack": [
      "#0      simulateError (file:///app/main.dart:123:3)",
      "#1      Router.call (package:shelf_router/router.dart:45:12)",
      "..."
    ]
  }
}
```

### 500 Internal Error (Production)

```json
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "traceId": "d4e5f6g7h8i9j0k1"
  }
}
```

---

## Log-Ausgabe

```
[2024-01-15T10:30:00.000Z] INFO GET /api/users 200 5ms
[2024-01-15T10:30:01.000Z] INFO GET /api/users/user-1 200 2ms
[2024-01-15T10:30:02.000Z] ERROR GET /api/users/not-exists 404 3ms {"code": "NOT_FOUND"}
[2024-01-15T10:30:03.000Z] ERROR POST /api/users 400 8ms {"code": "VALIDATION_ERROR"}
[2024-01-15T10:30:04.000Z] ERROR GET /api/error 500 1ms {"code": "INTERNAL_ERROR", "traceId": "abc123"}
```

---

## Wichtige Patterns

### Exception-Hierarchie

```dart
abstract class ApiException {
  int get statusCode;
  String get code;
  String get message;
  Response toResponse();
}

class NotFoundException extends ApiException { ... }
class ValidationException extends ApiException { ... }
```

### Cascade für 404 Fallback

```dart
final handler = Cascade()
    .add(router.call)           // Erst Router versuchen
    .add(notFoundHandler())     // Dann 404 Handler
    .handler;
```

### Error Handler Middleware

```dart
Middleware errorHandler() {
  return (handler) => (request) async {
    try {
      return await handler(request);
    } on ApiException catch (e) {
      return e.toResponse();
    } catch (e) {
      return internalError();
    }
  };
}
```
