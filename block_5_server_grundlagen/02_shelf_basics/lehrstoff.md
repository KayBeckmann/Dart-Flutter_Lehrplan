# Einheit 5.2: Shelf Framework Basics

## Lernziele

Nach dieser Einheit kannst du:
- Die Shelf-Architektur verstehen
- Handler und Middleware-Konzepte anwenden
- Request/Response-Objekte von Shelf nutzen
- Einen Shelf-Server aufsetzen und konfigurieren

---

## Was ist Shelf?

**Shelf** ist das offizielle Web-Server-Framework für Dart. Es bietet eine elegante, funktionale Abstraktion für HTTP-Server.

### Vorteile gegenüber dart:io

| dart:io | Shelf |
|---------|-------|
| Low-Level API | High-Level Abstraktion |
| Manuelle Request-Verarbeitung | Funktionale Handler |
| Kein Middleware-Konzept | Middleware-Pipeline |
| Schwer testbar | Einfach testbar |
| Callback-basiert | Funktional/komposierbar |

### Installation

```yaml
# pubspec.yaml
dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0  # Für Routing (nächste Einheit)

dev_dependencies:
  test: ^1.24.0
```

---

## Shelf-Architektur

Shelf basiert auf drei Kernkonzepten:

```
┌─────────────────────────────────────────────────────────────┐
│                      Request                                 │
│  (HTTP-Methode, URL, Headers, Body)                         │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Handler                                 │
│  Funktion: Request → Response                               │
│  (oder Future<Response>)                                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                      Response                                │
│  (Statuscode, Headers, Body)                                │
└─────────────────────────────────────────────────────────────┘
```

### Der Handler

Ein **Handler** ist eine Funktion, die einen `Request` nimmt und eine `Response` (oder `Future<Response>`) zurückgibt:

```dart
typedef Handler = FutureOr<Response> Function(Request request);
```

Das ist alles! Diese einfache Signatur macht Shelf extrem flexibel und testbar.

---

## Erster Shelf-Server

### Minimales Beispiel

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  // Handler definieren
  Response handler(Request request) {
    return Response.ok('Hallo von Shelf!');
  }

  // Server starten
  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server läuft auf http://${server.address.host}:${server.port}');
}
```

### Handler als Closure

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final handler = (Request request) {
    return Response.ok('Pfad: ${request.url.path}');
  };

  await shelf_io.serve(handler, 'localhost', 8080);
}
```

### Async Handler

```dart
Future<Response> handler(Request request) async {
  // Simuliere Datenbankabfrage
  await Future.delayed(Duration(milliseconds: 100));

  return Response.ok('Daten geladen');
}
```

---

## Request-Objekt

Das `Request`-Objekt enthält alle Informationen über die eingehende Anfrage.

### Request-Eigenschaften

```dart
Response handler(Request request) {
  // HTTP-Methode
  print('Methode: ${request.method}'); // GET, POST, etc.

  // URL-Informationen
  print('URL: ${request.url}');           // Relative URL
  print('Pfad: ${request.url.path}');     // /api/users
  print('Query: ${request.url.query}');   // name=Max&age=25
  print('Requested URL: ${request.requestedUri}'); // Absolute URL

  // Headers
  print('Content-Type: ${request.headers['content-type']}');
  print('Accept: ${request.headers['accept']}');
  print('Custom: ${request.headers['x-custom-header']}');

  // Alle Headers
  request.headers.forEach((key, value) {
    print('$key: $value');
  });

  return Response.ok('OK');
}
```

### Request-Body lesen

```dart
import 'dart:convert';

Future<Response> handler(Request request) async {
  // Body als String
  final bodyString = await request.readAsString();

  // Body als JSON
  final bodyJson = jsonDecode(bodyString);

  // Oder direkt:
  // final bodyBytes = await request.read().toList();

  return Response.ok('Empfangen: $bodyJson');
}
```

### Query-Parameter

```dart
Response handler(Request request) {
  // URL: /search?q=dart&limit=10
  final params = request.url.queryParameters;

  final query = params['q'] ?? '';
  final limit = int.tryParse(params['limit'] ?? '10') ?? 10;

  return Response.ok('Suche nach: $query (Limit: $limit)');
}
```

### Request mit Context

Shelf ermöglicht es, Daten zwischen Middleware und Handlern zu teilen:

```dart
Response handler(Request request) {
  // Wert aus Context lesen (gesetzt von Middleware)
  final userId = request.context['userId'] as String?;

  return Response.ok('User: $userId');
}

// In Middleware:
Request requestWithContext = request.change(
  context: {'userId': '12345'},
);
```

---

## Response-Objekt

Das `Response`-Objekt repräsentiert die HTTP-Antwort.

### Response erstellen

```dart
// Einfache Text-Response
Response.ok('Hello World');

// Mit Statuscode
Response(200, body: 'OK');
Response(201, body: 'Created');
Response(204); // No Content

// Vordefinierte Konstruktoren
Response.ok('Success');           // 200
Response.movedPermanently('/new'); // 301
Response.found('/new');           // 302
Response.seeOther('/new');        // 303
Response.notModified();           // 304
Response.notFound('Not Found');   // 404
Response.forbidden('Forbidden');  // 403
Response.internalServerError();   // 500
```

### Response mit Headers

```dart
Response handler(Request request) {
  return Response.ok(
    '{"data": "value"}',
    headers: {
      'content-type': 'application/json',
      'cache-control': 'no-cache',
      'x-custom-header': 'custom-value',
    },
  );
}
```

### JSON-Response (Hilfsfunktion)

```dart
import 'dart:convert';

Response jsonResponse(
  Object? data, {
  int statusCode = 200,
  Map<String, String>? headers,
}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...?headers,
    },
  );
}

// Verwendung:
Response handler(Request request) {
  return jsonResponse({
    'users': [
      {'id': 1, 'name': 'Max'},
      {'id': 2, 'name': 'Anna'},
    ],
  });
}
```

### Response mit Stream-Body

Für große Dateien oder Streaming:

```dart
import 'dart:io';

Response handler(Request request) {
  final file = File('large_file.zip');
  final stream = file.openRead();

  return Response.ok(
    stream,
    headers: {
      'content-type': 'application/zip',
      'content-length': file.lengthSync().toString(),
    },
  );
}
```

---

## Pipeline

Die `Pipeline` ermöglicht das Verketten von Middleware und Handlern:

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  // Handler
  Response handler(Request request) {
    return Response.ok('Hello!');
  }

  // Pipeline mit Middleware
  final pipeline = Pipeline()
      .addMiddleware(logRequests())    // Built-in Logging
      .addHandler(handler);

  await shelf_io.serve(pipeline, 'localhost', 8080);
}
```

### Mehrere Middleware verketten

```dart
final pipeline = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(corsHeaders())
    .addMiddleware(authentication())
    .addHandler(router);
```

Die Middleware wird in der Reihenfolge ausgeführt, in der sie hinzugefügt wird.

---

## Eingebaute Middleware

Shelf bietet einige nützliche Middleware-Funktionen:

### logRequests()

Loggt alle eingehenden Requests:

```dart
import 'package:shelf/shelf.dart';

final pipeline = Pipeline()
    .addMiddleware(logRequests())
    .addHandler(handler);

// Ausgabe:
// 2024-01-15T14:30:00.000000 0:00:00.005000 GET     [200] /api/users
```

### createMiddleware()

Erstellt einfache Middleware:

```dart
Middleware corsHeaders() {
  return createMiddleware(
    responseHandler: (response) {
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      });
    },
  );
}
```

---

## Server-Konfiguration

### serve() Optionen

```dart
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final server = await shelf_io.serve(
    handler,
    'localhost',  // oder '0.0.0.0' für alle Interfaces
    8080,
    poweredByHeader: 'My Dart Server',  // Server-Header
    shared: true,  // Shared-Mode für mehrere Isolates
  );

  // Server-Informationen
  print('Adresse: ${server.address.host}');
  print('Port: ${server.port}');
}
```

### Graceful Shutdown

```dart
import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;

HttpServer? _server;

void main() async {
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutdown...');
    await _server?.close();
    exit(0);
  });

  _server = await shelf_io.serve(handler, 'localhost', 8080);
  print('Server läuft');
}
```

### Port aus Umgebungsvariable

```dart
void main() async {
  final port = int.parse(Platform.environment['PORT'] ?? '8080');

  await shelf_io.serve(handler, '0.0.0.0', port);
  print('Server läuft auf Port $port');
}
```

---

## Beispiel: Vollständiger Server

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

HttpServer? _server;

void main() async {
  // Shutdown-Handler
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n[Shutdown] Server wird beendet...');
    await _server?.close();
    exit(0);
  });

  // Pipeline aufbauen
  final pipeline = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsHeaders())
      .addHandler(_router);

  // Server starten
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  _server = await shelf_io.serve(pipeline, '0.0.0.0', port);

  print('Server läuft auf http://localhost:$port');
}

// Einfaches Routing
Response _router(Request request) {
  final path = request.url.path;
  final method = request.method;

  if (path == '' && method == 'GET') {
    return Response.ok('Willkommen!');
  }

  if (path == 'api/health' && method == 'GET') {
    return _jsonResponse({'status': 'ok'});
  }

  if (path == 'api/echo' && method == 'POST') {
    return _handleEcho(request);
  }

  return Response.notFound('Not Found: $path');
}

Future<Response> _handleEcho(Request request) async {
  final body = await request.readAsString();
  try {
    final json = jsonDecode(body);
    return _jsonResponse({
      'echo': json,
      'timestamp': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    return Response.badRequest(body: 'Invalid JSON');
  }
}

// Hilfsfunktionen
Response _jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Middleware _corsHeaders() {
  return createMiddleware(
    responseHandler: (response) => response.change(headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    }),
  );
}
```

---

## Zusammenfassung

- **Shelf** ist das Standard-Framework für Dart-Server
- **Handler** sind einfache Funktionen: `Request → Response`
- **Request** enthält alle Anfrage-Informationen
- **Response** wird über Konstruktoren erstellt
- **Pipeline** verkettet Middleware und Handler
- **logRequests()** ist eine nützliche eingebaute Middleware
- Der Server wird mit `shelf_io.serve()` gestartet

---

## Nächste Schritte

In der nächsten Einheit lernst du **shelf_router** für deklaratives Routing mit URL-Parametern und Route-Gruppen.
