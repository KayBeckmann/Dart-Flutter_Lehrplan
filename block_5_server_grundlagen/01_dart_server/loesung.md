# Lösung 5.1: Dart auf dem Server

## Vollständige Lösung

```dart
import 'dart:io';
import 'dart:convert';

// Globale Variablen für Statistiken
DateTime? _serverStartTime;
int _requestCount = 0;
HttpServer? _server;

Future<void> main() async {
  _serverStartTime = DateTime.now();

  // Signal-Handler für Ctrl+C
  ProcessSignal.sigint.watch().listen((_) async {
    print('\n[Shutdown] Server wird heruntergefahren...');
    await _server?.close();
    print('[Shutdown] Auf Wiedersehen!');
    exit(0);
  });

  _server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    8080,
  );

  print('Server läuft auf http://localhost:8080');
  print('Drücke Ctrl+C zum Beenden\n');

  await for (final request in _server!) {
    await _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final startTime = DateTime.now();
  _requestCount++;

  final path = request.uri.path;
  final method = request.method;

  try {
    // Routing
    if (path == '/' && method == 'GET') {
      _handleRoot(request);
    } else if (path == '/api/info' && method == 'GET') {
      _handleInfo(request);
    } else if (path == '/api/time' && method == 'GET') {
      _handleTime(request);
    } else if (path == '/api/echo' && method == 'POST') {
      await _handleEcho(request);
    } else if (path == '/api/greet' && method == 'GET') {
      _handleGreet(request);
    } else if (path == '/health' && method == 'GET') {
      _handleHealth(request);
    } else {
      _handleNotFound(request);
    }
  } catch (e) {
    _handleError(request, e);
  }

  // Logging
  final duration = DateTime.now().difference(startTime).inMilliseconds;
  final timestamp = _formatTimestamp(DateTime.now());
  final statusCode = request.response.statusCode;
  print('[$timestamp] $method $path - $statusCode (${duration}ms)');
}

// Aufgabe 2: Routing

void _handleRoot(HttpRequest request) {
  request.response
    ..statusCode = HttpStatus.ok
    ..headers.contentType = ContentType.text
    ..write('Willkommen beim Simple Server!')
    ..close();
}

void _handleInfo(HttpRequest request) {
  final info = {
    'name': 'Simple Server',
    'version': '1.0.0',
    'dart_version': Platform.version.split(' ').first,
  };
  _sendJson(request.response, info);
}

void _handleTime(HttpRequest request) {
  final now = DateTime.now();
  final timeInfo = {
    'timestamp': now.toUtc().toIso8601String(),
    'timezone': now.timeZoneName,
  };
  _sendJson(request.response, timeInfo);
}

Future<void> _handleEcho(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final data = body.isNotEmpty ? jsonDecode(body) : {};

    final response = {
      'received': data,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    _sendJson(request.response, response);
  } catch (e) {
    _sendJson(
      request.response,
      {'error': 'Invalid JSON'},
      statusCode: HttpStatus.badRequest,
    );
  }
}

// Aufgabe 3: Query-Parameter

void _handleGreet(HttpRequest request) {
  final params = request.uri.queryParameters;
  final name = params['name'] ?? 'Gast';
  final lang = params['lang'] ?? 'de';

  String greeting;
  switch (lang) {
    case 'en':
      greeting = 'Hello, $name!';
      break;
    case 'de':
    default:
      greeting = 'Hallo, $name!';
  }

  final response = {
    'greeting': greeting,
    'language': lang,
  };
  _sendJson(request.response, response);
}

// Bonus: Health Check

void _handleHealth(HttpRequest request) {
  final uptime = DateTime.now().difference(_serverStartTime!);
  final uptimeSeconds = uptime.inSeconds;
  final requestsPerMinute = uptimeSeconds > 0
      ? (_requestCount / (uptimeSeconds / 60)).toStringAsFixed(1)
      : '0.0';

  // Speicherverbrauch in MB
  final memoryBytes = ProcessInfo.currentRss;
  final memoryMb = (memoryBytes / (1024 * 1024)).toStringAsFixed(1);

  final health = {
    'status': 'healthy',
    'uptime_seconds': uptimeSeconds,
    'requests_total': _requestCount,
    'requests_per_minute': double.parse(requestsPerMinute),
    'memory_usage_mb': double.parse(memoryMb),
  };
  _sendJson(request.response, health);
}

// Error-Handler

void _handleNotFound(HttpRequest request) {
  _sendJson(
    request.response,
    {
      'error': 'Not Found',
      'path': request.uri.path,
      'method': request.method,
    },
    statusCode: HttpStatus.notFound,
  );
}

void _handleError(HttpRequest request, dynamic error) {
  _sendJson(
    request.response,
    {
      'error': 'Internal Server Error',
      'message': error.toString(),
    },
    statusCode: HttpStatus.internalServerError,
  );
}

// Hilfsfunktionen

void _sendJson(
  HttpResponse response,
  Map<String, dynamic> data, {
  int statusCode = HttpStatus.ok,
}) {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(data))
    ..close();
}

String _formatTimestamp(DateTime dt) {
  return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
      '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
}

String _pad(int n) => n.toString().padLeft(2, '0');
```

---

## Erklärungen

### Aufgabe 1: Projekt-Setup

Das Projekt wird mit `dart create -t console` erstellt. Die `-t console`-Option erstellt ein minimales Projekt ohne zusätzliche Abhängigkeiten.

### Aufgabe 2: Routing

Das Routing erfolgt über einfache `if-else`-Bedingungen:
- Jede Route prüft Pfad UND Methode
- Am Ende steht `_handleNotFound` als Fallback
- JSON-Responses werden über die Hilfsfunktion `_sendJson` gesendet

### Aufgabe 3: Query-Parameter

Query-Parameter werden über `request.uri.queryParameters` ausgelesen:
- Gibt eine `Map<String, String>` zurück
- Bei fehlenden Parametern wird `null` zurückgegeben
- Der `??`-Operator setzt Default-Werte

### Aufgabe 4: Logging

Das Logging misst die Zeit vor und nach der Request-Verarbeitung:
- `startTime` wird zu Beginn gespeichert
- Nach `close()` wird die Differenz berechnet
- Das Format ist konfigurierbar

### Aufgabe 5: Graceful Shutdown

Der Shutdown wird über `ProcessSignal.sigint` implementiert:
- `watch()` gibt einen Stream zurück
- `listen()` registriert einen Handler
- `server.close()` beendet den Server sauber

### Bonus: Health Check

Der Health-Endpunkt sammelt verschiedene Metriken:
- **Uptime**: Differenz zwischen Start und Jetzt
- **Request-Count**: Globale Variable, die bei jedem Request erhöht wird
- **Memory**: `ProcessInfo.currentRss` gibt den aktuellen Speicherverbrauch zurück

---

## Test-Befehle

```bash
# Server starten
dart run bin/simple_server.dart

# In einem anderen Terminal testen:

# Root
curl http://localhost:8080/

# Info
curl http://localhost:8080/api/info

# Time
curl http://localhost:8080/api/time

# Echo
curl -X POST http://localhost:8080/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Hallo", "count": 42}'

# Greet (verschiedene Varianten)
curl "http://localhost:8080/api/greet"
curl "http://localhost:8080/api/greet?name=Max"
curl "http://localhost:8080/api/greet?name=Max&lang=en"
curl "http://localhost:8080/api/greet?name=Anna&lang=de"

# Health
curl http://localhost:8080/health

# 404 testen
curl http://localhost:8080/nicht-vorhanden
curl -X POST http://localhost:8080/api/info

# Shutdown testen: Drücke Ctrl+C im Server-Terminal
```

---

## Beispiel-Ausgabe

### Server-Konsole:

```
Server läuft auf http://localhost:8080
Drücke Ctrl+C zum Beenden

[2024-01-15 14:30:00] GET / - 200 (2ms)
[2024-01-15 14:30:05] GET /api/info - 200 (1ms)
[2024-01-15 14:30:10] GET /api/time - 200 (1ms)
[2024-01-15 14:30:15] POST /api/echo - 200 (3ms)
[2024-01-15 14:30:20] GET /api/greet?name=Max&lang=en - 200 (1ms)
[2024-01-15 14:30:25] GET /health - 200 (2ms)
[2024-01-15 14:30:30] GET /unknown - 404 (1ms)

^C
[Shutdown] Server wird heruntergefahren...
[Shutdown] Auf Wiedersehen!
```

### curl-Responses:

```bash
$ curl http://localhost:8080/
Willkommen beim Simple Server!

$ curl http://localhost:8080/api/info
{"name":"Simple Server","version":"1.0.0","dart_version":"3.2.0"}

$ curl http://localhost:8080/api/time
{"timestamp":"2024-01-15T13:30:00.000Z","timezone":"CET"}

$ curl -X POST http://localhost:8080/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Test"}'
{"received":{"message":"Test"},"timestamp":"2024-01-15T13:30:00.000Z"}

$ curl "http://localhost:8080/api/greet?name=Max&lang=en"
{"greeting":"Hello, Max!","language":"en"}

$ curl http://localhost:8080/health
{"status":"healthy","uptime_seconds":120,"requests_total":6,"requests_per_minute":3.0,"memory_usage_mb":45.2}

$ curl http://localhost:8080/unknown
{"error":"Not Found","path":"/unknown","method":"GET"}
```

---

## Häufige Fehler

### 1. Response wird nicht gesendet

```dart
// FALSCH: close() fehlt
request.response.write('Hello');

// RICHTIG
request.response
  ..write('Hello')
  ..close();
```

### 2. Body wird nicht korrekt gelesen

```dart
// FALSCH: Synchrones Lesen
final body = request.toString();

// RICHTIG: Asynchrones Lesen mit await
final body = await utf8.decoder.bind(request).join();
```

### 3. JSON-Fehler nicht abgefangen

```dart
// FALSCH: Kein Error-Handling
final data = jsonDecode(body);

// RICHTIG: Mit try-catch
try {
  final data = jsonDecode(body);
} catch (e) {
  // Fehler-Response senden
}
```

### 4. Content-Type nicht gesetzt

```dart
// FALSCH: Browser interpretiert als Text
response.write('{"data": "value"}');

// RICHTIG: Content-Type setzen
response.headers.contentType = ContentType.json;
response.write('{"data": "value"}');
```
