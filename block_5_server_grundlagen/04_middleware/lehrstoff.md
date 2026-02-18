# Einheit 5.4: Middleware

## Lernziele

Nach dieser Einheit kannst du:
- Das Middleware-Konzept verstehen und anwenden
- Eigene Middleware für Logging, CORS und Auth erstellen
- Middleware-Ketten aufbauen
- Error-Handling-Middleware implementieren

---

## Was ist Middleware?

**Middleware** ist Code, der zwischen dem Empfang eines Requests und dem Senden der Response ausgeführt wird. Sie ermöglicht die Verarbeitung von Requests/Responses an einem zentralen Ort.

```
Request  ──▶  Middleware 1  ──▶  Middleware 2  ──▶  Handler
                  │                   │                │
                  ▼                   ▼                ▼
Response ◀──  Middleware 1  ◀──  Middleware 2  ◀──────┘
```

### Typische Middleware-Aufgaben

- **Logging**: Requests protokollieren
- **CORS**: Cross-Origin-Headers setzen
- **Authentication**: Tokens validieren
- **Authorization**: Berechtigungen prüfen
- **Compression**: Responses komprimieren
- **Rate Limiting**: Anfragelimit durchsetzen
- **Error Handling**: Fehler abfangen und formatieren

---

## Middleware-Grundstruktur

In Shelf ist Middleware eine Funktion, die einen Handler nimmt und einen neuen Handler zurückgibt:

```dart
typedef Middleware = Handler Function(Handler innerHandler);
```

### Einfaches Beispiel

```dart
Middleware simpleMiddleware() {
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

### Middleware verwenden

```dart
final handler = Pipeline()
    .addMiddleware(simpleMiddleware())
    .addHandler(myHandler);
```

---

## createMiddleware Helper

Shelf bietet `createMiddleware` für einfache Fälle:

```dart
Middleware myMiddleware() {
  return createMiddleware(
    // Wird VOR dem Handler aufgerufen
    requestHandler: (Request request) {
      // Return Response um Handler zu überspringen
      // Return null um fortzufahren
      return null;
    },

    // Wird NACH dem Handler aufgerufen
    responseHandler: (Response response) {
      // Response modifizieren
      return response.change(headers: {'X-Custom': 'value'});
    },

    // Fehler abfangen
    errorHandler: (error, stackTrace) {
      print('Error: $error');
      return Response.internalServerError();
    },
  );
}
```

---

## Logging Middleware

### Einfaches Logging

```dart
Middleware requestLogger() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final timestamp = DateTime.now().toIso8601String();

      // Handler aufrufen
      final response = await innerHandler(request);

      stopwatch.stop();

      // Log-Ausgabe
      print('[$timestamp] ${request.method.padRight(6)} '
          '${request.requestedUri.path} '
          '- ${response.statusCode} '
          '(${stopwatch.elapsedMilliseconds}ms)');

      return response;
    };
  };
}
```

### Strukturiertes Logging mit JSON

```dart
Middleware jsonLogger() {
  return (Handler innerHandler) {
    return (Request request) async {
      final startTime = DateTime.now();
      final stopwatch = Stopwatch()..start();

      Response response;
      String? error;

      try {
        response = await innerHandler(request);
      } catch (e, stack) {
        error = e.toString();
        response = Response.internalServerError();
      }

      stopwatch.stop();

      final logEntry = {
        'timestamp': startTime.toUtc().toIso8601String(),
        'method': request.method,
        'path': request.requestedUri.path,
        'query': request.requestedUri.query,
        'status': response.statusCode,
        'duration_ms': stopwatch.elapsedMilliseconds,
        'client_ip': request.headers['x-forwarded-for'] ??
            request.headers['x-real-ip'],
        'user_agent': request.headers['user-agent'],
        if (error != null) 'error': error,
      };

      print(jsonEncode(logEntry));

      return response;
    };
  };
}
```

---

## CORS Middleware

Cross-Origin Resource Sharing (CORS) erlaubt Browser-Anfragen von anderen Domains.

### Einfache CORS Middleware

```dart
Middleware corsHeaders({
  String origin = '*',
  List<String> methods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  List<String> headers = const ['Content-Type', 'Authorization'],
}) {
  return createMiddleware(
    requestHandler: (Request request) {
      // Preflight-Request (OPTIONS) beantworten
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': origin,
          'Access-Control-Allow-Methods': methods.join(', '),
          'Access-Control-Allow-Headers': headers.join(', '),
          'Access-Control-Max-Age': '86400', // 24 Stunden Cache
        });
      }
      return null; // Weiter zum Handler
    },
    responseHandler: (Response response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': origin,
        'Access-Control-Allow-Methods': methods.join(', '),
        'Access-Control-Allow-Headers': headers.join(', '),
      });
    },
  );
}
```

### Verwendung

```dart
final handler = Pipeline()
    .addMiddleware(corsHeaders(
      origin: 'https://example.com',  // Oder '*' für alle
      methods: ['GET', 'POST'],
      headers: ['Content-Type', 'Authorization', 'X-Custom-Header'],
    ))
    .addHandler(router);
```

---

## Authentication Middleware

### Bearer Token Middleware

```dart
Middleware bearerAuth(String Function(String token) validateToken) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Public Paths überspringen
      final publicPaths = ['/', '/health', '/api/auth/login'];
      if (publicPaths.contains(request.url.path)) {
        return innerHandler(request);
      }

      // Authorization Header prüfen
      final authHeader = request.headers['authorization'];

      if (authHeader == null) {
        return Response(401,
            body: jsonEncode({'error': 'Missing Authorization header'}),
            headers: {'content-type': 'application/json'});
      }

      if (!authHeader.startsWith('Bearer ')) {
        return Response(401,
            body: jsonEncode({'error': 'Invalid Authorization format'}),
            headers: {'content-type': 'application/json'});
      }

      final token = authHeader.substring(7); // "Bearer " entfernen

      try {
        final userId = validateToken(token);

        // User-ID in Context speichern
        final enrichedRequest = request.change(context: {
          'userId': userId,
          'authenticated': true,
        });

        return innerHandler(enrichedRequest);
      } catch (e) {
        return Response(401,
            body: jsonEncode({'error': 'Invalid token'}),
            headers: {'content-type': 'application/json'});
      }
    };
  };
}
```

### API Key Middleware

```dart
Middleware apiKeyAuth(Set<String> validKeys) {
  return (Handler innerHandler) {
    return (Request request) async {
      final apiKey = request.headers['x-api-key'];

      if (apiKey == null || !validKeys.contains(apiKey)) {
        return Response(401,
            body: jsonEncode({'error': 'Invalid or missing API key'}),
            headers: {'content-type': 'application/json'});
      }

      return innerHandler(request);
    };
  };
}
```

---

## Error Handling Middleware

### Globaler Error Handler

```dart
Middleware errorHandler() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Bad Request',
            'message': e.message,
          }),
          headers: {'content-type': 'application/json'},
        );
      } on NotFoundException catch (e) {
        return Response.notFound(
          jsonEncode({
            'error': 'Not Found',
            'message': e.message,
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, stack) {
        // Unerwartete Fehler loggen
        print('Unhandled error: $e\n$stack');

        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// Custom Exceptions
class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
```

### Verwendung mit Custom Exceptions

```dart
Response getUser(Request request, String id) {
  final user = userRepository.findById(id);
  if (user == null) {
    throw NotFoundException('User $id not found');
  }
  return jsonResponse(user);
}
```

---

## Request/Response Transformation

### Request Body Parsing Middleware

```dart
Middleware jsonBodyParser() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'GET' || request.method == 'DELETE') {
        return innerHandler(request);
      }

      final contentType = request.headers['content-type'];
      if (contentType?.contains('application/json') != true) {
        return innerHandler(request);
      }

      try {
        final body = await request.readAsString();
        final json = body.isNotEmpty ? jsonDecode(body) : {};

        // Parsed JSON in Context speichern
        final enrichedRequest = request.change(context: {
          'body': json,
        });

        return innerHandler(enrichedRequest);
      } catch (e) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid JSON body'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// Verwendung im Handler
Response createUser(Request request) {
  final body = request.context['body'] as Map<String, dynamic>;
  // body ist bereits geparst!
}
```

### Response Compression

```dart
import 'dart:io';

Middleware gzipCompression() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);

      // Nur komprimieren wenn Client es akzeptiert
      final acceptEncoding = request.headers['accept-encoding'] ?? '';
      if (!acceptEncoding.contains('gzip')) {
        return response;
      }

      // Body komprimieren
      final body = await response.readAsString();
      final compressed = gzip.encode(utf8.encode(body));

      return Response(
        response.statusCode,
        body: compressed,
        headers: {
          ...response.headers,
          'content-encoding': 'gzip',
          'content-length': compressed.length.toString(),
        },
      );
    };
  };
}
```

---

## Middleware-Ketten

Die Reihenfolge der Middleware ist wichtig:

```dart
final handler = Pipeline()
    // 1. Error Handler (fängt alle Fehler)
    .addMiddleware(errorHandler())
    // 2. Logging (loggt alle Requests)
    .addMiddleware(requestLogger())
    // 3. CORS (vor Auth, damit OPTIONS funktioniert)
    .addMiddleware(corsHeaders())
    // 4. Authentication
    .addMiddleware(bearerAuth(validateToken))
    // 5. Body Parser
    .addMiddleware(jsonBodyParser())
    // 6. Handler
    .addHandler(router);
```

### Ausführungsreihenfolge

```
Request  ──▶ errorHandler ──▶ logger ──▶ cors ──▶ auth ──▶ handler
                │                │         │        │          │
                │                │         │        │          ▼
Response ◀─────┴────────────────┴─────────┴────────┴──────────┘
```

---

## Bedingte Middleware

Middleware nur für bestimmte Pfade:

```dart
Middleware conditionalMiddleware(
  Middleware middleware, {
  required bool Function(Request) when,
}) {
  return (Handler innerHandler) {
    final wrappedHandler = middleware(innerHandler);

    return (Request request) {
      if (when(request)) {
        return wrappedHandler(request);
      }
      return innerHandler(request);
    };
  };
}

// Verwendung
final handler = Pipeline()
    .addMiddleware(conditionalMiddleware(
      bearerAuth(validate),
      when: (r) => r.url.path.startsWith('api/'),
    ))
    .addHandler(router);
```

---

## Zusammenfassung

- **Middleware** verarbeitet Requests/Responses zentral
- **createMiddleware** für einfache Fälle
- **Error Handling** sollte ganz außen sein
- **CORS** vor Authentication (wegen OPTIONS)
- **Context** zum Teilen von Daten zwischen Middleware und Handlern
- **Reihenfolge** ist entscheidend für korrektes Verhalten

---

## Nächste Schritte

In der nächsten Einheit lernst du **Konfiguration & Umgebungsvariablen** für unterschiedliche Environments (Development, Production).
