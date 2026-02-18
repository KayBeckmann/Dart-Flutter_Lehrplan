# Lösung 5.2: Shelf Framework Basics

## Vollständige Lösung

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  // Shutdown-Handler
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nServer wird beendet...');
    exit(0);
  });

  // Pipeline aufbauen
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(requestTimer())
      .addMiddleware(apiKeyAuth('secret-key-123'))
      .addHandler(router);

  // Server starten
  final server = await shelf_io.serve(pipeline, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
  print('API-Key für geschützte Routen: secret-key-123');
}

// ============================================
// Aufgabe 2: Router/Handler
// ============================================

Future<Response> router(Request request) async {
  final path = request.url.path;
  final method = request.method;

  // Root-Route
  if (path == '' && method == 'GET') {
    return _handleRoot(request);
  }

  // API-Routen
  if (path == 'api/status' && method == 'GET') {
    return _handleStatus(request);
  }

  if (path == 'api/headers' && method == 'GET') {
    return _handleHeaders(request);
  }

  if (path == 'api/echo' && method == 'POST') {
    return await _handleEcho(request);
  }

  // Bonus: Whoami
  if (path == 'api/whoami' && method == 'GET') {
    return _handleWhoami(request);
  }

  // 404 für alles andere
  return jsonResponse(
    {'error': 'Not Found', 'path': '/$path'},
    statusCode: 404,
  );
}

Response _handleRoot(Request request) {
  const html = '''
<!DOCTYPE html>
<html>
<head><title>Shelf Server</title></head>
<body><h1>Willkommen!</h1></body>
</html>
''';

  return Response.ok(
    html,
    headers: {'content-type': 'text/html; charset=utf-8'},
  );
}

Response _handleStatus(Request request) {
  return jsonResponse({
    'status': 'running',
    'version': '1.0.0',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
}

Response _handleHeaders(Request request) {
  final headers = <String, String>{};
  request.headers.forEach((key, value) {
    headers[key] = value;
  });

  return jsonResponse({'headers': headers});
}

Future<Response> _handleEcho(Request request) async {
  try {
    final bodyString = await request.readAsString();
    final body = bodyString.isNotEmpty ? jsonDecode(bodyString) : null;

    return jsonResponse({
      'method': request.method,
      'path': '/${request.url.path}',
      'body': body,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  } catch (e) {
    return jsonResponse(
      {'error': 'Invalid JSON', 'details': e.toString()},
      statusCode: 400,
    );
  }
}

// Bonus: Whoami Handler
Response _handleWhoami(Request request) {
  final authenticated = request.context['authenticated'] as bool? ?? false;
  final apiKeyPrefix = request.context['apiKeyPrefix'] as String? ?? 'none';

  return jsonResponse({
    'authenticated': authenticated,
    'api_key_prefix': apiKeyPrefix,
  });
}

// ============================================
// Aufgabe 3: JSON-Helper
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}

// ============================================
// Aufgabe 4: Custom Middleware
// ============================================

// Middleware 1: Request-Timer
Middleware requestTimer() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();

      final response = await innerHandler(request);

      stopwatch.stop();

      return response.change(headers: {
        'X-Response-Time': '${stopwatch.elapsedMilliseconds}ms',
      });
    };
  };
}

// Middleware 2: API-Key-Authentifizierung
Middleware apiKeyAuth(String validApiKey) {
  return (Handler innerHandler) {
    return (Request request) async {
      final path = request.url.path;

      // Nur /api/* Pfade schützen
      if (!path.startsWith('api/')) {
        return innerHandler(request);
      }

      // API-Key aus Header lesen
      final apiKey = request.headers['x-api-key'];

      if (apiKey == null) {
        return jsonResponse(
          {'error': 'Unauthorized', 'message': 'API-Key required'},
          statusCode: 401,
        );
      }

      if (apiKey != validApiKey) {
        return jsonResponse(
          {'error': 'Unauthorized', 'message': 'Invalid API-Key'},
          statusCode: 401,
        );
      }

      // Bonus: Context mit Auth-Infos anreichern
      final enrichedRequest = request.change(context: {
        'authenticated': true,
        'apiKeyPrefix': '${apiKey.substring(0, 4)}...',
      });

      return innerHandler(enrichedRequest);
    };
  };
}
```

---

## Erklärungen

### Aufgabe 2: Router

Der Router ist eine einfache Funktion, die basierend auf Pfad und Methode entscheidet:

```dart
Future<Response> router(Request request) async {
  final path = request.url.path;  // Ohne führenden /
  final method = request.method;

  if (path == '' && method == 'GET') { ... }
  // ...
}
```

**Wichtig:** `request.url.path` enthält den Pfad OHNE führenden Slash!
- URL: `http://localhost:8080/api/status`
- `request.url.path` → `api/status` (nicht `/api/status`)

### Aufgabe 3: JSON-Helper

Die Funktion kapselt die JSON-Erstellung:

```dart
Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
```

### Aufgabe 4: Middleware

#### Request-Timer

Die Middleware misst die Zeit:

```dart
Middleware requestTimer() {
  return (Handler innerHandler) {        // Nimmt den nächsten Handler
    return (Request request) async {     // Gibt neuen Handler zurück
      final stopwatch = Stopwatch()..start();

      final response = await innerHandler(request);  // Handler ausführen

      stopwatch.stop();

      return response.change(headers: {
        'X-Response-Time': '${stopwatch.elapsedMilliseconds}ms',
      });
    };
  };
}
```

#### API-Key-Auth

Die Auth-Middleware prüft nur API-Routen:

```dart
// Nur /api/* Pfade schützen
if (!path.startsWith('api/')) {
  return innerHandler(request);  // Durchlassen
}
```

Und gibt bei fehlendem/falschem Key eine Error-Response zurück:

```dart
if (apiKey == null || apiKey != validApiKey) {
  return jsonResponse({...}, statusCode: 401);  // NICHT innerHandler aufrufen
}
```

### Bonus: Request-Context

Der Context wird über `request.change()` modifiziert:

```dart
final enrichedRequest = request.change(context: {
  'authenticated': true,
  'apiKeyPrefix': '${apiKey.substring(0, 4)}...',
});

return innerHandler(enrichedRequest);  // Weiterreichen
```

Im Handler wird der Context gelesen:

```dart
final authenticated = request.context['authenticated'] as bool? ?? false;
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# Root (kein API-Key nötig)
curl http://localhost:8080/

# Status ohne API-Key (401)
curl http://localhost:8080/api/status
# {"error":"Unauthorized","message":"API-Key required"}

# Status mit API-Key
curl -H "X-API-Key: secret-key-123" http://localhost:8080/api/status
# {"status":"running","version":"1.0.0","timestamp":"..."}

# Headers
curl -H "X-API-Key: secret-key-123" http://localhost:8080/api/headers

# Echo
curl -X POST \
  -H "X-API-Key: secret-key-123" \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}' \
  http://localhost:8080/api/echo

# Response-Time Header prüfen (verbose)
curl -v -H "X-API-Key: secret-key-123" http://localhost:8080/api/status
# Suche nach: < X-Response-Time: 2ms

# Whoami (Bonus)
curl -H "X-API-Key: secret-key-123" http://localhost:8080/api/whoami
# {"authenticated":true,"api_key_prefix":"secr..."}

# 404
curl -H "X-API-Key: secret-key-123" http://localhost:8080/api/unknown
# {"error":"Not Found","path":"/api/unknown"}
```

---

## Beispiel-Ausgabe

### Server-Konsole:

```
Server running on http://localhost:8080
API-Key für geschützte Routen: secret-key-123

2024-01-15T14:30:00.000000 0:00:00.002000 GET     [200] /
2024-01-15T14:30:05.000000 0:00:00.001000 GET     [401] /api/status
2024-01-15T14:30:10.000000 0:00:00.003000 GET     [200] /api/status
2024-01-15T14:30:15.000000 0:00:00.004000 POST    [200] /api/echo
```

---

## Häufige Fehler

### 1. Pfad mit/ohne Slash

```dart
// FALSCH
if (path == '/api/status') { ... }

// RICHTIG (request.url.path hat keinen führenden Slash)
if (path == 'api/status') { ... }
```

### 2. Middleware-Reihenfolge

```dart
// Logging sollte ZUERST kommen
final pipeline = Pipeline()
    .addMiddleware(logRequests())     // 1. Logging
    .addMiddleware(requestTimer())     // 2. Timer
    .addMiddleware(apiKeyAuth(...))    // 3. Auth
    .addHandler(router);
```

### 3. Async vergessen

```dart
// FALSCH
Response router(Request request) {
  final body = await request.readAsString();  // Error!
}

// RICHTIG
Future<Response> router(Request request) async {
  final body = await request.readAsString();
}
```

### 4. Context nicht weitergeben

```dart
// FALSCH: Neuer Request ohne Context-Daten
return innerHandler(request);

// RICHTIG: Request mit Context-Daten
final newRequest = request.change(context: {'key': 'value'});
return innerHandler(newRequest);
```
