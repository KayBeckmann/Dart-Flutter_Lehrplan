# Ressourcen: Error Handling & HTTP-Statuscodes

## Offizielle Dokumentation

- [HTTP Status Codes (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [RFC 7807 Problem Details](https://www.rfc-editor.org/rfc/rfc7807)
- [REST API Error Handling](https://restfulapi.net/http-status-codes/)

## Cheat Sheet: HTTP-Statuscodes

### Erfolg (2xx)

```dart
// 200 OK - Standard-Erfolg
return Response.ok(jsonEncode(data));

// 201 Created - Ressource erstellt
return Response(201,
  body: jsonEncode(data),
  headers: {'location': '/api/items/$id'},
);

// 204 No Content - Erfolg ohne Body
return Response(204);
```

### Client-Fehler (4xx)

```dart
// 400 Bad Request
return Response(400, body: '{"error": "Invalid request"}');

// 401 Unauthorized
return Response(401, body: '{"error": "Authentication required"}');

// 403 Forbidden
return Response(403, body: '{"error": "Access denied"}');

// 404 Not Found
return Response(404, body: '{"error": "Resource not found"}');

// 409 Conflict
return Response(409, body: '{"error": "Resource already exists"}');

// 422 Unprocessable Entity
return Response(422, body: '{"error": "Validation failed"}');

// 429 Too Many Requests
return Response(429,
  headers: {'retry-after': '60'},
  body: '{"error": "Rate limit exceeded"}',
);
```

### Server-Fehler (5xx)

```dart
// 500 Internal Server Error
return Response(500, body: '{"error": "Internal server error"}');

// 503 Service Unavailable
return Response(503,
  headers: {'retry-after': '300'},
  body: '{"error": "Service temporarily unavailable"}',
);
```

## Cheat Sheet: ApiException Klassen

```dart
abstract class ApiException implements Exception {
  int get statusCode;
  String get code;
  String get message;

  Response toResponse() => Response(statusCode,
    body: jsonEncode({'error': {'code': code, 'message': message}}),
    headers: {'content-type': 'application/json'},
  );
}

class NotFoundException extends ApiException {
  final String resource;
  NotFoundException(this.resource);

  @override int get statusCode => 404;
  @override String get code => 'NOT_FOUND';
  @override String get message => '$resource not found';
}

class BadRequestException extends ApiException {
  @override final String message;
  BadRequestException(this.message);

  @override int get statusCode => 400;
  @override String get code => 'BAD_REQUEST';
}

class UnauthorizedException extends ApiException {
  @override int get statusCode => 401;
  @override String get code => 'UNAUTHORIZED';
  @override String get message => 'Authentication required';
}

class ForbiddenException extends ApiException {
  @override int get statusCode => 403;
  @override String get code => 'FORBIDDEN';
  @override String get message => 'Access denied';
}

class ConflictException extends ApiException {
  @override final String message;
  ConflictException(this.message);

  @override int get statusCode => 409;
  @override String get code => 'CONFLICT';
}
```

## Cheat Sheet: Error Handler Middleware

```dart
Middleware errorHandler() {
  return (Handler handler) {
    return (Request request) async {
      try {
        return await handler(request);
      } on ApiException catch (e) {
        return e.toResponse();
      } on FormatException {
        return Response(400,
          body: '{"error": {"code": "INVALID_JSON", "message": "Invalid JSON"}}',
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stack) {
        print('ERROR: $e\n$stack');
        return Response(500,
          body: '{"error": {"code": "INTERNAL_ERROR", "message": "An unexpected error occurred"}}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
```

## Cheat Sheet: Fehler-Response Format

```dart
// Standard-Format
Response errorResponse(int status, String code, String message, {Map<String, dynamic>? details}) {
  return Response(status,
    body: jsonEncode({
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

// RFC 7807 Problem Details
Response problemDetails(int status, String type, String title, String detail) {
  return Response(status,
    body: jsonEncode({
      'type': type,
      'title': title,
      'status': status,
      'detail': detail,
    }),
    headers: {'content-type': 'application/problem+json'},
  );
}
```

## Cheat Sheet: Logger

```dart
class Logger {
  static void info(String message) {
    print('[${DateTime.now()}] INFO: $message');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    print('[${DateTime.now()}] ERROR: $message');
    if (error != null) print('  Error: $error');
    if (stack != null) print('  Stack: $stack');
  }

  static void warn(String message) {
    print('[${DateTime.now()}] WARN: $message');
  }
}
```

## HTTP Status Quick Reference

| Code | Name | Wann verwenden |
|------|------|----------------|
| 200 | OK | GET erfolgreich, PUT/PATCH erfolgreich |
| 201 | Created | POST erfolgreich (neue Ressource) |
| 204 | No Content | DELETE erfolgreich |
| 400 | Bad Request | Ungültige Eingabe, fehlendes Feld |
| 401 | Unauthorized | Kein/ungültiger Token |
| 403 | Forbidden | Token gültig, aber keine Berechtigung |
| 404 | Not Found | Ressource existiert nicht |
| 405 | Method Not Allowed | z.B. DELETE auf read-only |
| 409 | Conflict | Duplikat, Race Condition |
| 415 | Unsupported Media Type | Falscher Content-Type |
| 422 | Unprocessable Entity | Semantischer Fehler |
| 429 | Too Many Requests | Rate Limit |
| 500 | Internal Server Error | Unerwarteter Fehler |
| 503 | Service Unavailable | Wartung, Überlastung |

## Fehlercode-Konventionen

```dart
// Konstanten für Error Codes
class ErrorCodes {
  static const notFound = 'NOT_FOUND';
  static const badRequest = 'BAD_REQUEST';
  static const validationError = 'VALIDATION_ERROR';
  static const unauthorized = 'UNAUTHORIZED';
  static const forbidden = 'FORBIDDEN';
  static const conflict = 'CONFLICT';
  static const internalError = 'INTERNAL_ERROR';
  static const rateLimited = 'RATE_LIMITED';
}
```

## Best Practices

1. **Konsistentes Format**
   - Immer JSON zurückgeben
   - Einheitliche Fehlerstruktur

2. **Aussagekräftige Meldungen**
   - Für Menschen lesbar
   - Konkrete Hinweise zur Behebung

3. **Sicherheit**
   - Keine Stack Traces in Produktion
   - Keine internen Details preisgeben

4. **Logging**
   - Alle Fehler loggen
   - Trace-ID für Debugging

5. **Richtige Statuscodes**
   - 4xx für Client-Fehler
   - 5xx für Server-Fehler

## Test-Befehle

```bash
# 404 testen
curl http://localhost:8080/api/users/not-exists

# 400 testen (ungültiges JSON)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{invalid}'

# 401 testen
curl http://localhost:8080/api/protected

# Response-Code anzeigen
curl -w "\nStatus: %{http_code}\n" http://localhost:8080/api/users/123
```
