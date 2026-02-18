# Einheit 6.6: Error Handling & HTTP-Statuscodes

## Lernziele

Nach dieser Einheit kannst du:
- HTTP-Statuscodes korrekt einsetzen
- Fehler systematisch behandeln und loggen
- Einheitliche Fehler-Responses erstellen
- Globale Fehlerbehandlung mit Middleware implementieren

---

## HTTP-Statuscodes Übersicht

### 2xx - Erfolg

| Code | Name | Verwendung |
|------|------|------------|
| 200 | OK | Standard-Erfolg (GET, PUT, PATCH) |
| 201 | Created | Ressource erstellt (POST) |
| 204 | No Content | Erfolg ohne Body (DELETE) |

### 4xx - Client-Fehler

| Code | Name | Verwendung |
|------|------|------------|
| 400 | Bad Request | Ungültige Syntax, fehlende Felder |
| 401 | Unauthorized | Nicht authentifiziert |
| 403 | Forbidden | Authentifiziert, aber keine Berechtigung |
| 404 | Not Found | Ressource existiert nicht |
| 405 | Method Not Allowed | HTTP-Methode nicht unterstützt |
| 409 | Conflict | Konflikt (z.B. Duplikat) |
| 415 | Unsupported Media Type | Content-Type nicht unterstützt |
| 422 | Unprocessable Entity | Valide Syntax, semantischer Fehler |
| 429 | Too Many Requests | Rate Limit überschritten |

### 5xx - Server-Fehler

| Code | Name | Verwendung |
|------|------|------------|
| 500 | Internal Server Error | Unerwarteter Fehler |
| 502 | Bad Gateway | Upstream-Server-Fehler |
| 503 | Service Unavailable | Überlastet/Wartung |
| 504 | Gateway Timeout | Upstream-Timeout |

---

## Fehler-Response Format

### Einheitliches Format

```dart
class ApiError {
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? traceId;

  ApiError({
    required this.code,
    required this.message,
    this.details,
    this.traceId,
  });

  Map<String, dynamic> toJson() => {
    'error': {
      'code': code,
      'message': message,
      if (details != null) 'details': details,
      if (traceId != null) 'traceId': traceId,
    },
  };
}
```

### Beispiel-Responses

```json
// 400 Bad Request
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "fields": [
        {"field": "email", "message": "Invalid email format"}
      ]
    }
  }
}

// 404 Not Found
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User with ID '123' not found"
  }
}

// 500 Internal Server Error
{
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred",
    "traceId": "abc123-def456"
  }
}
```

---

## Exception-Klassen

### Benutzerdefinierte Exceptions

```dart
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
  @override
  int get statusCode => 401;

  @override
  String get code => 'UNAUTHORIZED';

  @override
  String get message => 'Authentication required';
}

class ForbiddenException extends ApiException {
  @override
  int get statusCode => 403;

  @override
  String get code => 'FORBIDDEN';

  @override
  String get message => 'You do not have permission to access this resource';
}

class ConflictException extends ApiException {
  final String conflictMessage;

  ConflictException(this.conflictMessage);

  @override
  int get statusCode => 409;

  @override
  String get code => 'CONFLICT';

  @override
  String get message => conflictMessage;
}
```

### Verwendung

```dart
Response getUser(Request request, String id) {
  final user = userRepo.findById(id);
  if (user == null) {
    throw NotFoundException('User', id);
  }
  return jsonResponse(user.toJson());
}

Response createUser(Request request) {
  final body = request.json;

  // Validierung
  final result = UserValidator.validate(body);
  if (!result.isValid) {
    throw ValidationException(result.errors);
  }

  // Duplikat-Check
  if (userRepo.existsByEmail(body['email'])) {
    throw ConflictException('A user with this email already exists');
  }

  // User erstellen...
}
```

---

## Globale Fehlerbehandlung

### Error Handler Middleware

```dart
Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        // Bekannte API-Fehler
        final traceId = _generateTraceId();
        _logError(request, e, traceId);
        return e.toResponse(traceId: traceId);
      } on FormatException catch (e) {
        // JSON-Parsing-Fehler
        return Response(400,
          body: jsonEncode({
            'error': {
              'code': 'INVALID_JSON',
              'message': 'Invalid JSON: ${e.message}',
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stackTrace) {
        // Unerwartete Fehler
        final traceId = _generateTraceId();
        _logError(request, e, traceId, stackTrace: stackTrace);

        // In Produktion: Keine Details preisgeben
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
    };
  };
}

String _generateTraceId() {
  final random = Random();
  return List.generate(16, (_) => random.nextInt(16).toRadixString(16)).join();
}

void _logError(Request request, Object error, String traceId, {StackTrace? stackTrace}) {
  final timestamp = DateTime.now().toIso8601String();
  print('[$timestamp] ERROR [$traceId] ${request.method} ${request.url}');
  print('  Error: $error');
  if (stackTrace != null) {
    print('  Stack: $stackTrace');
  }
}
```

### Pipeline-Setup

```dart
void main() async {
  final router = Router();

  // Routes definieren...

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(errorHandler())  // Fehlerbehandlung NACH logging
      .addMiddleware(jsonBodyParser())
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
}
```

---

## Fehler-Logging

### Strukturiertes Logging

```dart
enum LogLevel { debug, info, warn, error }

class Logger {
  final String name;

  Logger(this.name);

  void debug(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.debug, message, context);
  }

  void info(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, message, context);
  }

  void warn(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.warn, message, context);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stack': stackTrace.toString(),
    });
  }

  void _log(LogLevel level, String message, Map<String, dynamic>? context) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(5);
    final contextStr = context != null ? ' $context' : '';
    print('[$timestamp] $levelStr [$name] $message$contextStr');
  }
}

// Verwendung
final logger = Logger('UserService');

void createUser(Map<String, dynamic> data) {
  logger.info('Creating user', {'email': data['email']});

  try {
    // ...
    logger.info('User created', {'userId': user.id});
  } catch (e, stack) {
    logger.error('Failed to create user', e, stack);
    rethrow;
  }
}
```

---

## Entwicklung vs. Produktion

### Unterschiedliche Fehler-Details

```dart
final isProduction = Platform.environment['ENV'] == 'production';

Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stackTrace) {
        final traceId = _generateTraceId();

        if (isProduction) {
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
        } else {
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
        }
      }
    };
  };
}
```

---

## 404 Handler für unbekannte Routen

```dart
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

// Verwendung
final handler = Pipeline()
    .addMiddleware(errorHandler())
    .addHandler(Cascade()
        .add(router.call)
        .add(notFoundHandler())  // Fallback für unbekannte Routen
        .handler);
```

---

## Method Not Allowed (405)

```dart
// Shelf_router gibt automatisch 404 zurück
// Für 405 müssen wir selbst prüfen

Middleware methodNotAllowed(Map<String, List<String>> allowedMethods) {
  return (Handler handler) {
    return (Request request) {
      final path = request.url.path;
      final method = request.method;

      for (final entry in allowedMethods.entries) {
        // Einfacher Path-Match (für komplexere Patterns: Regex)
        if (path.startsWith(entry.key)) {
          if (!entry.value.contains(method)) {
            return Response(405,
              headers: {
                'allow': entry.value.join(', '),
                'content-type': 'application/json',
              },
              body: jsonEncode({
                'error': {
                  'code': 'METHOD_NOT_ALLOWED',
                  'message': 'Method $method not allowed for $path',
                  'allowed': entry.value,
                },
              }),
            );
          }
        }
      }

      return handler(request);
    };
  };
}
```

---

## Zusammenfassung

| Situation | Statuscode | Error Code |
|-----------|------------|------------|
| Ressource nicht gefunden | 404 | NOT_FOUND |
| Validierungsfehler | 400 | VALIDATION_ERROR |
| Ungültiges JSON | 400 | INVALID_JSON |
| Nicht authentifiziert | 401 | UNAUTHORIZED |
| Keine Berechtigung | 403 | FORBIDDEN |
| Duplikat | 409 | CONFLICT |
| Server-Fehler | 500 | INTERNAL_ERROR |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Pagination & Filtering**: Wie du große Datenmengen in Seiten aufteilst und filterbar machst.
