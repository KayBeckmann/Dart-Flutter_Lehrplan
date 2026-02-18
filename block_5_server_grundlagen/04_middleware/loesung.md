# Lösung 5.4: Middleware

## Vollständige Lösung

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  // Router mit Test-Endpunkten
  final router = Router();

  router.get('/health', (Request r) => jsonResponse({'status': 'ok'}));

  router.get('/api/users', (Request r) {
    final userId = r.context['userId'];
    return jsonResponse({
      'users': [
        {'id': 1, 'name': 'Alice'},
        {'id': 2, 'name': 'Bob'},
      ],
      'requestedBy': userId,
    });
  });

  router.get('/api/error', (Request r) {
    throw NotFoundException('This is a test error');
  });

  router.get('/api/validate', (Request r) {
    throw ValidationException('Invalid input data');
  });

  // Pipeline aufbauen
  final handler = Pipeline()
      .addMiddleware(errorHandler())
      .addMiddleware(requestLogger())
      .addMiddleware(corsMiddleware())
      .addMiddleware(rateLimiter(maxRequests: 10, window: Duration(seconds: 30)))
      .addMiddleware(authMiddleware(secret: 'mysecret'))
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('Test-Token: ${base64Encode(utf8.encode('user123:mysecret'))}');
}

// ============================================
// Aufgabe 1: Logging Middleware
// ============================================

Middleware requestLogger() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final timestamp = _formatTimestamp(DateTime.now());

      Response response;
      try {
        response = await innerHandler(request);
      } catch (e) {
        response = Response.internalServerError();
        rethrow;
      } finally {
        stopwatch.stop();

        final method = request.method.padRight(6);
        var path = '/${request.url.path}';
        if (path.length > 20) {
          path = '${path.substring(0, 17)}...';
        }
        path = path.padRight(20);

        final status = response.statusCode;
        final duration = '${stopwatch.elapsedMilliseconds}ms'.padLeft(6);

        // Farbcodes (ANSI)
        final color = _getStatusColor(status);
        final reset = '\x1B[0m';

        print('[$timestamp] $method $path $color$status$reset $duration');
      }

      return response;
    };
  };
}

String _formatTimestamp(DateTime dt) {
  return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');

String _getStatusColor(int status) {
  if (status >= 200 && status < 300) return '\x1B[32m'; // Grün
  if (status >= 400 && status < 500) return '\x1B[33m'; // Gelb
  if (status >= 500) return '\x1B[31m'; // Rot
  return '\x1B[0m'; // Reset
}

// ============================================
// Aufgabe 2: CORS Middleware
// ============================================

Middleware corsMiddleware({
  String origin = '*',
  List<String> methods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  List<String> allowedHeaders = const ['Content-Type', 'Authorization'],
  int maxAge = 86400,
}) {
  final corsHeaders = {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Methods': methods.join(', '),
    'Access-Control-Allow-Headers': allowedHeaders.join(', '),
    'Access-Control-Max-Age': maxAge.toString(),
  };

  return createMiddleware(
    requestHandler: (Request request) {
      // Preflight-Request (OPTIONS) direkt beantworten
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }
      return null;
    },
    responseHandler: (Response response) {
      // CORS-Headers an alle Responses anhängen
      return response.change(headers: corsHeaders);
    },
  );
}

// ============================================
// Aufgabe 3: Rate Limiting Middleware
// ============================================

final _requestCounts = <String, List<DateTime>>{};

Middleware rateLimiter({
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Client-IP ermitteln
      final clientIp = request.headers['x-forwarded-for'] ??
          request.headers['x-real-ip'] ??
          'unknown';

      final now = DateTime.now();
      final windowStart = now.subtract(window);

      // Alte Einträge entfernen
      _requestCounts.putIfAbsent(clientIp, () => []);
      _requestCounts[clientIp]!.removeWhere((t) => t.isBefore(windowStart));

      final currentCount = _requestCounts[clientIp]!.length;
      final remaining = maxRequests - currentCount - 1;
      final resetTime = now.add(window).millisecondsSinceEpoch ~/ 1000;

      // Rate-Limit Headers
      final rateLimitHeaders = {
        'X-RateLimit-Limit': maxRequests.toString(),
        'X-RateLimit-Remaining': remaining.clamp(0, maxRequests).toString(),
        'X-RateLimit-Reset': resetTime.toString(),
      };

      // Limit erreicht?
      if (currentCount >= maxRequests) {
        final retryAfter = window.inSeconds -
            now.difference(_requestCounts[clientIp]!.first).inSeconds;

        return Response(
          429,
          body: jsonEncode({
            'error': 'Too Many Requests',
            'message': 'Rate limit exceeded. Try again later.',
            'retryAfter': retryAfter,
          }),
          headers: {
            'content-type': 'application/json',
            'Retry-After': retryAfter.toString(),
            ...rateLimitHeaders,
          },
        );
      }

      // Request zählen
      _requestCounts[clientIp]!.add(now);

      // Handler aufrufen und Headers hinzufügen
      final response = await innerHandler(request);
      return response.change(headers: rateLimitHeaders);
    };
  };
}

// ============================================
// Aufgabe 4: Authentication Middleware
// ============================================

Middleware authMiddleware({
  required String secret,
  List<String> publicPaths = const ['/health', '/api/auth/login'],
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = '/${request.url.path}';

      // Public Paths durchlassen
      if (publicPaths.any((p) => path == p || path.startsWith('$p/'))) {
        return innerHandler(request);
      }

      // Authorization Header prüfen
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response(
          401,
          body: jsonEncode({
            'error': 'Unauthorized',
            'message': 'Missing Authorization header',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      if (!authHeader.startsWith('Bearer ')) {
        return Response(
          401,
          body: jsonEncode({
            'error': 'Unauthorized',
            'message': 'Invalid Authorization format. Use: Bearer <token>',
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final token = authHeader.substring(7);

      try {
        // Token validieren (vereinfacht)
        final decoded = utf8.decode(base64Decode(token));
        final parts = decoded.split(':');

        if (parts.length != 2 || parts[1] != secret) {
          throw FormatException('Invalid token');
        }

        final userId = parts[0];

        // User-ID in Context speichern
        final enrichedRequest = request.change(context: {
          'userId': userId,
          'authenticated': true,
        });

        return innerHandler(enrichedRequest);
      } catch (e) {
        return Response(
          401,
          body: jsonEncode({
            'error': 'Unauthorized',
            'message': 'Invalid or expired token',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// ============================================
// Aufgabe 5: Error Handler Middleware
// ============================================

Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        return Response(
          e.statusCode,
          body: jsonEncode({
            'error': _getErrorName(e.statusCode),
            'message': e.message,
            'statusCode': e.statusCode,
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stack) {
        // Unerwartete Fehler loggen (nicht an Client senden)
        print('Unhandled error: $e');
        print('Stack trace: $stack');

        return Response(
          500,
          body: jsonEncode({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred',
            'statusCode': 500,
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

String _getErrorName(int statusCode) {
  switch (statusCode) {
    case 400:
      return 'Bad Request';
    case 401:
      return 'Unauthorized';
    case 403:
      return 'Forbidden';
    case 404:
      return 'Not Found';
    case 429:
      return 'Too Many Requests';
    default:
      return 'Error';
  }
}

// ============================================
// Custom Exceptions
// ============================================

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message, 400);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message, 403);
}

// ============================================
// Helper
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# Token generieren
TOKEN=$(echo -n "user123:mysecret" | base64)
echo "Token: $TOKEN"

# === Health (public, keine Auth) ===
curl http://localhost:8080/health

# === Ohne Auth (401) ===
curl http://localhost:8080/api/users

# === Mit Auth (200) ===
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/users

# === CORS Preflight ===
curl -X OPTIONS http://localhost:8080/api/users \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: POST" -v

# === Rate Limit testen ===
for i in {1..12}; do
  echo "Request $i:"
  curl -s http://localhost:8080/health | head -1
done

# === Error Handler testen ===
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/error
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/validate

# === Ungültiger Token ===
curl -H "Authorization: Bearer invalid" http://localhost:8080/api/users
```

---

## Beispiel-Ausgaben

### Server-Konsole

```
Server: http://localhost:8080
Test-Token: dXNlcjEyMzpteXNlY3JldA==
[2024-01-15 14:30:00] GET    /health              200    2ms
[2024-01-15 14:30:01] GET    /api/users           401    1ms
[2024-01-15 14:30:02] GET    /api/users           200    3ms
[2024-01-15 14:30:03] OPTIONS /api/users          200    1ms
[2024-01-15 14:30:04] GET    /api/error           404    2ms
```

### Response: /api/users (mit Auth)

```json
{
  "users": [
    {"id": 1, "name": "Alice"},
    {"id": 2, "name": "Bob"}
  ],
  "requestedBy": "user123"
}
```

### Response: Rate Limit erreicht

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Try again later.",
  "retryAfter": 25
}
```

### Response: Error Handler

```json
{
  "error": "Not Found",
  "message": "This is a test error",
  "statusCode": 404
}
```

---

## Wichtige Erkenntnisse

### 1. Middleware-Reihenfolge

```dart
Pipeline()
    .addMiddleware(errorHandler())    // 1. Ganz außen
    .addMiddleware(requestLogger())   // 2. Logging für alle
    .addMiddleware(corsMiddleware())  // 3. Vor Auth (OPTIONS!)
    .addMiddleware(rateLimiter())     // 4. Vor Auth
    .addMiddleware(authMiddleware())  // 5. Authentication
    .addHandler(router);
```

### 2. Error Handler Position

Der Error Handler muss ganz außen sein, damit er Fehler aller anderen Middleware abfängt.

### 3. CORS vor Auth

OPTIONS-Requests (Preflight) haben keinen Authorization-Header. Daher muss CORS vor Auth kommen.

### 4. Context für Datenübertragung

```dart
// In Middleware
final newRequest = request.change(context: {'userId': userId});

// Im Handler
final userId = request.context['userId'];
```

### 5. createMiddleware vs. manuelle Middleware

- `createMiddleware`: Für einfache Fälle (nur Response modifizieren)
- Manuelle Middleware: Für komplexe Logik (Rate Limiting, Auth)
