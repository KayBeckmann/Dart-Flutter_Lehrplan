# Ressourcen: Dart auf dem Server

## Offizielle Dokumentation

- [Dart auf dem Server](https://dart.dev/server) - Offizielle Übersicht
- [dart:io Bibliothek](https://api.dart.dev/stable/dart-io/dart-io-library.html) - API-Referenz
- [HttpServer Klasse](https://api.dart.dev/stable/dart-io/HttpServer-class.html) - Detaillierte Dokumentation
- [Write command-line apps](https://dart.dev/tutorials/server/cmdline) - CLI-Tutorial

## HTTP-Grundlagen

- [HTTP-Übersicht (MDN)](https://developer.mozilla.org/de/docs/Web/HTTP/Overview) - Grundlagen
- [HTTP-Statuscodes](https://developer.mozilla.org/de/docs/Web/HTTP/Status) - Alle Codes erklärt
- [HTTP-Methoden](https://developer.mozilla.org/de/docs/Web/HTTP/Methods) - GET, POST, PUT, etc.
- [HTTP-Headers](https://developer.mozilla.org/de/docs/Web/HTTP/Headers) - Header-Referenz

## Tools zum Testen

### curl (Kommandozeile)

```bash
# GET-Request
curl http://localhost:8080

# POST-Request mit JSON
curl -X POST http://localhost:8080/api/data \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'

# Mit Headers
curl -H "Authorization: Bearer token" http://localhost:8080/api/protected

# Verbose-Modus (zeigt Request/Response-Details)
curl -v http://localhost:8080
```

### HTTPie (benutzerfreundliche Alternative zu curl)

```bash
# Installation
# macOS: brew install httpie
# Linux: apt install httpie

# GET-Request
http localhost:8080

# POST mit JSON
http POST localhost:8080/api/data name=Test

# Mit Headers
http localhost:8080/api/protected Authorization:"Bearer token"
```

### GUI-Tools

- [Postman](https://www.postman.com/) - Beliebtes API-Testing-Tool
- [Insomnia](https://insomnia.rest/) - Leichtgewichtige Alternative
- [Bruno](https://www.usebruno.com/) - Open-Source, Git-freundlich
- [Thunder Client](https://www.thunderclient.com/) - VS Code Extension

## Dart-Pakete für Server-Entwicklung

| Paket | Beschreibung | pub.dev |
|-------|--------------|---------|
| `shelf` | Modulares Web-Server-Framework | [Link](https://pub.dev/packages/shelf) |
| `shelf_router` | Routing für Shelf | [Link](https://pub.dev/packages/shelf_router) |
| `dart_frog` | Full-Stack Framework | [Link](https://pub.dev/packages/dart_frog) |
| `serverpod` | Backend-Framework mit ORM | [Link](https://pub.dev/packages/serverpod) |

## Videos & Tutorials

- [Building a Dart Server](https://www.youtube.com/watch?v=example) - Einführung
- [Dart Backend Development](https://dart.dev/tutorials/server/httpserver) - Offizielles Tutorial

## Beispielprojekte

- [shelf Beispiele](https://github.com/dart-lang/shelf/tree/master/pkgs/shelf/example)
- [Dart Samples](https://github.com/dart-lang/samples)

## Cheat Sheet: curl-Befehle

```bash
# Verschiedene HTTP-Methoden
curl -X GET http://localhost:8080/users
curl -X POST http://localhost:8080/users -d '{"name":"Max"}'
curl -X PUT http://localhost:8080/users/1 -d '{"name":"Updated"}'
curl -X DELETE http://localhost:8080/users/1

# JSON senden
curl -X POST http://localhost:8080/api \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'

# Response-Header anzeigen
curl -I http://localhost:8080

# Nur Statuscode anzeigen
curl -s -o /dev/null -w "%{http_code}" http://localhost:8080

# Mit Timeout
curl --max-time 5 http://localhost:8080

# Datei hochladen
curl -X POST http://localhost:8080/upload \
  -F "file=@/path/to/file.txt"
```

## Cheat Sheet: Dart-Server

```dart
// Server starten
final server = await HttpServer.bind(
  InternetAddress.anyIPv4,
  8080,
);

// Request-Infos
request.method          // GET, POST, etc.
request.uri.path        // /api/users
request.uri.queryParameters  // {key: value}
request.headers         // HttpHeaders

// Response senden
response.statusCode = 200;
response.headers.contentType = ContentType.json;
response.write('{"data": "value"}');
response.close();

// Body lesen
final body = await utf8.decoder.bind(request).join();
final json = jsonDecode(body);
```
