# Einheit 5.1: Dart auf dem Server

## Lernziele

Nach dieser Einheit kannst du:
- Dart-Programme ohne Flutter ausführen
- Die `dart:io`-Bibliothek für Server-Operationen nutzen
- Einen einfachen HTTP-Server erstellen
- Den Request/Response-Lifecycle verstehen

---

## Dart außerhalb von Flutter

Dart ist nicht nur für Flutter-Apps geeignet. Die Sprache wurde ursprünglich als allgemeine Programmiersprache entwickelt und eignet sich hervorragend für:

- **Command-Line Tools** (CLI)
- **Backend-Server** (REST APIs, WebSockets)
- **Automatisierungsskripte**
- **Microservices**

### Dart-Projekt ohne Flutter erstellen

```bash
# Einfaches Dart-Projekt
dart create my_cli_tool

# Server-Projekt mit Shelf-Template
dart create -t server-shelf my_api

# Package-Projekt
dart create -t package my_package
```

### Projektstruktur eines Server-Projekts

```
my_api/
├── bin/
│   └── server.dart      # Einstiegspunkt
├── lib/
│   └── my_api.dart      # Bibliotheks-Code
├── test/
│   └── my_api_test.dart # Tests
├── pubspec.yaml         # Abhängigkeiten
├── analysis_options.yaml
└── README.md
```

### Dart-Programm ausführen

```bash
# Direkt ausführen (JIT-Kompilierung)
dart run bin/server.dart

# Mit Argumenten
dart run bin/server.dart --port=8080

# Zu nativer Executable kompilieren (AOT)
dart compile exe bin/server.dart -o server
./server
```

---

## Die dart:io Bibliothek

`dart:io` ist die Kernbibliothek für I/O-Operationen auf dem Server. Sie ist nur verfügbar, wenn Dart nativ läuft (nicht im Browser).

### Wichtige Klassen in dart:io

| Klasse | Zweck |
|--------|-------|
| `HttpServer` | HTTP-Server erstellen |
| `HttpRequest` | Eingehende Anfragen |
| `HttpResponse` | Antworten senden |
| `File` | Dateioperationen |
| `Directory` | Verzeichnisoperationen |
| `Socket` | TCP-Sockets |
| `Platform` | Plattform-Informationen |

### Plattform-Informationen abrufen

```dart
import 'dart:io';

void main() {
  print('Betriebssystem: ${Platform.operatingSystem}');
  print('Anzahl Prozessoren: ${Platform.numberOfProcessors}');
  print('Hostname: ${Platform.localHostname}');
  print('Dart-Version: ${Platform.version}');

  // Umgebungsvariablen
  final home = Platform.environment['HOME'];
  print('Home-Verzeichnis: $home');
}
```

### Dateioperationen

```dart
import 'dart:io';

Future<void> main() async {
  // Datei lesen
  final file = File('config.json');

  if (await file.exists()) {
    final content = await file.readAsString();
    print('Inhalt: $content');
  }

  // Datei schreiben
  final logFile = File('app.log');
  await logFile.writeAsString(
    '${DateTime.now()}: Server gestartet\n',
    mode: FileMode.append,
  );

  // Verzeichnis auflisten
  final dir = Directory('.');
  await for (final entity in dir.list()) {
    print(entity.path);
  }
}
```

---

## HTTP-Grundlagen

Bevor wir einen Server bauen, müssen wir HTTP verstehen.

### Das HTTP-Protokoll

HTTP (Hypertext Transfer Protocol) ist ein Request-Response-Protokoll:

1. **Client** sendet einen **Request** an den Server
2. **Server** verarbeitet den Request
3. **Server** sendet eine **Response** zurück

### HTTP-Request-Struktur

```
GET /api/users HTTP/1.1
Host: localhost:8080
Accept: application/json
Authorization: Bearer token123
```

Bestandteile:
- **Methode**: GET, POST, PUT, DELETE, PATCH, etc.
- **Pfad**: /api/users
- **HTTP-Version**: HTTP/1.1
- **Headers**: Metadaten (Host, Content-Type, etc.)
- **Body**: Daten (bei POST/PUT)

### HTTP-Response-Struktur

```
HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 45

{"users": [{"id": 1, "name": "Max"}]}
```

Bestandteile:
- **Statuscode**: 200, 404, 500, etc.
- **Status-Text**: OK, Not Found, etc.
- **Headers**: Metadaten
- **Body**: Antwortdaten

### Wichtige HTTP-Statuscodes

| Code | Bedeutung | Verwendung |
|------|-----------|------------|
| 200 | OK | Erfolgreiche GET/PUT-Anfrage |
| 201 | Created | Ressource erfolgreich erstellt |
| 204 | No Content | Erfolg ohne Rückgabedaten |
| 400 | Bad Request | Ungültige Anfrage |
| 401 | Unauthorized | Authentifizierung erforderlich |
| 403 | Forbidden | Keine Berechtigung |
| 404 | Not Found | Ressource nicht gefunden |
| 500 | Internal Server Error | Serverfehler |

### HTTP-Methoden

| Methode | Zweck | Idempotent | Body |
|---------|-------|------------|------|
| GET | Daten abrufen | Ja | Nein |
| POST | Neue Ressource erstellen | Nein | Ja |
| PUT | Ressource ersetzen | Ja | Ja |
| PATCH | Ressource teilweise ändern | Nein | Ja |
| DELETE | Ressource löschen | Ja | Nein |

---

## Einfacher HTTP-Server mit dart:io

Lass uns einen minimalen HTTP-Server bauen:

### Minimaler Server

```dart
import 'dart:io';

Future<void> main() async {
  // Server auf localhost:8080 starten
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4, // 127.0.0.1
    8080,
  );

  print('Server läuft auf http://localhost:8080');

  // Auf eingehende Requests warten
  await for (final request in server) {
    // Einfache Antwort senden
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..write('Hallo vom Dart-Server!')
      ..close();
  }
}
```

### Server mit einfachem Routing

```dart
import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8080,
  );

  print('Server läuft auf http://localhost:8080');

  await for (final request in server) {
    await handleRequest(request);
  }
}

Future<void> handleRequest(HttpRequest request) async {
  final path = request.uri.path;
  final method = request.method;

  print('$method $path');

  // Einfaches Routing
  if (path == '/' && method == 'GET') {
    _sendJson(request.response, {'message': 'Willkommen!'});
  } else if (path == '/health' && method == 'GET') {
    _sendJson(request.response, {'status': 'ok'});
  } else if (path == '/echo' && method == 'POST') {
    await _handleEcho(request);
  } else {
    _sendNotFound(request.response);
  }
}

void _sendJson(HttpResponse response, Map<String, dynamic> data) {
  response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(data))
    ..close();
}

void _sendNotFound(HttpResponse response) {
  response
    ..statusCode = HttpStatus.notFound
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'error': 'Not Found'}))
    ..close();
}

Future<void> _handleEcho(HttpRequest request) async {
  // Request-Body lesen
  final body = await utf8.decoder.bind(request).join();

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'echo': body,
      'timestamp': DateTime.now().toIso8601String(),
    }))
    ..close();
}
```

### Server mit Query-Parametern

```dart
import 'dart:io';
import 'dart:convert';

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server läuft auf http://localhost:8080');

  await for (final request in server) {
    if (request.uri.path == '/search') {
      handleSearch(request);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..close();
    }
  }
}

void handleSearch(HttpRequest request) {
  // Query-Parameter auslesen
  // URL: /search?q=dart&limit=10
  final params = request.uri.queryParameters;
  final query = params['q'] ?? '';
  final limit = int.tryParse(params['limit'] ?? '10') ?? 10;

  // Alle Query-Parameter (auch mehrfache)
  final allParams = request.uri.queryParametersAll;
  // /search?tag=dart&tag=flutter -> {'tag': ['dart', 'flutter']}

  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({
      'query': query,
      'limit': limit,
      'allParams': allParams,
    }))
    ..close();
}
```

---

## Request/Response Lifecycle

Der Lebenszyklus einer HTTP-Anfrage:

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                                │
│  1. Baut HTTP-Request auf (Methode, URL, Headers, Body)     │
│  2. Sendet Request über TCP-Verbindung                      │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                        SERVER                                │
│  3. Empfängt TCP-Verbindung                                 │
│  4. Parsed HTTP-Request                                      │
│  5. Verarbeitet Request (Routing, Business-Logik)           │
│  6. Erstellt HTTP-Response                                   │
│  7. Sendet Response zurück                                   │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT                                │
│  8. Empfängt Response                                        │
│  9. Parsed Response (Status, Headers, Body)                 │
│ 10. Verarbeitet Daten                                        │
└─────────────────────────────────────────────────────────────┘
```

### Request-Eigenschaften in dart:io

```dart
await for (final request in server) {
  // HTTP-Methode
  print('Methode: ${request.method}');

  // URI-Informationen
  print('Pfad: ${request.uri.path}');
  print('Query: ${request.uri.query}');
  print('Query-Params: ${request.uri.queryParameters}');

  // Headers
  print('Content-Type: ${request.headers.contentType}');
  print('Accept: ${request.headers.value('accept')}');
  print('User-Agent: ${request.headers.value('user-agent')}');

  // Alle Headers ausgeben
  request.headers.forEach((name, values) {
    print('$name: ${values.join(', ')}');
  });

  // Client-Informationen
  print('Client-IP: ${request.connectionInfo?.remoteAddress.address}');
  print('Client-Port: ${request.connectionInfo?.remotePort}');

  // Body lesen (für POST/PUT)
  if (request.method == 'POST') {
    final body = await utf8.decoder.bind(request).join();
    print('Body: $body');
  }

  // Response senden
  request.response.close();
}
```

### Response konfigurieren

```dart
void sendResponse(HttpRequest request) {
  final response = request.response;

  // Statuscode setzen
  response.statusCode = HttpStatus.ok; // 200

  // Headers setzen
  response.headers.contentType = ContentType.json;
  response.headers.add('X-Custom-Header', 'Wert');
  response.headers.add('Cache-Control', 'no-cache');

  // CORS-Headers (für Browser-Zugriff)
  response.headers.add('Access-Control-Allow-Origin', '*');

  // Body schreiben
  response.write('{"data": "Hello"}');

  // Oder mit Bytes
  // response.add(utf8.encode('{"data": "Hello"}'));

  // Response abschließen
  response.close();
}
```

---

## Graceful Shutdown

Ein Server sollte sauber herunterfahren können:

```dart
import 'dart:io';

HttpServer? _server;

Future<void> main() async {
  // Signal-Handler für Ctrl+C (SIGINT)
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nServer wird heruntergefahren...');
    await _server?.close();
    exit(0);
  });

  _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  print('Server läuft auf http://localhost:8080');
  print('Drücke Ctrl+C zum Beenden');

  await for (final request in _server!) {
    request.response
      ..write('Hello')
      ..close();
  }
}
```

---

## Zusammenfassung

- **dart:io** ermöglicht Server-Entwicklung ohne Flutter
- **HttpServer** ist die Basis-Klasse für HTTP-Server
- Der **Request/Response-Lifecycle** folgt dem HTTP-Protokoll
- **Query-Parameter** werden über `uri.queryParameters` ausgelesen
- **Request-Body** wird als Stream gelesen
- Für produktive Server verwenden wir in der nächsten Einheit das **Shelf-Framework**

---

## Nächste Schritte

In der nächsten Einheit lernst du das **Shelf-Framework**, das eine elegantere Abstraktion für HTTP-Server bietet und Features wie Middleware, Routing und Testing erleichtert.
