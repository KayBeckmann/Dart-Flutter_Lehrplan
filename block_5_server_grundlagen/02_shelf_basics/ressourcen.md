# Ressourcen: Shelf Framework Basics

## Offizielle Dokumentation

- [Shelf Package](https://pub.dev/packages/shelf) - pub.dev
- [Shelf API-Dokumentation](https://pub.dev/documentation/shelf/latest/) - API-Referenz
- [Shelf GitHub Repository](https://github.com/dart-lang/shelf) - Quellcode & Beispiele
- [Write HTTP servers](https://dart.dev/tutorials/server/httpserver) - Offizielles Tutorial

## Verwandte Packages

| Package | Beschreibung | Link |
|---------|--------------|------|
| `shelf` | Core-Framework | [pub.dev](https://pub.dev/packages/shelf) |
| `shelf_router` | Deklaratives Routing | [pub.dev](https://pub.dev/packages/shelf_router) |
| `shelf_static` | Statische Dateien | [pub.dev](https://pub.dev/packages/shelf_static) |
| `shelf_cors_headers` | CORS-Middleware | [pub.dev](https://pub.dev/packages/shelf_cors_headers) |
| `shelf_web_socket` | WebSocket-Support | [pub.dev](https://pub.dev/packages/shelf_web_socket) |

## Code-Beispiele

### Minimaler Server

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  var handler = (Request request) => Response.ok('Hello!');
  await io.serve(handler, 'localhost', 8080);
}
```

### Mit Pipeline und Logging

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

void main() async {
  var handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler((req) => Response.ok('Hello!'));

  await io.serve(handler, 'localhost', 8080);
}
```

### JSON-Response Helper

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

Response json(Object? data, {int status = 200}) => Response(
  status,
  body: jsonEncode(data),
  headers: {'content-type': 'application/json'},
);
```

## Cheat Sheet: Request

```dart
// Methode & URL
request.method           // GET, POST, etc.
request.url              // Uri (relativ)
request.url.path         // /api/users
request.url.query        // name=Max
request.requestedUri     // Vollständige Uri

// Query-Parameter
request.url.queryParameters        // Map<String, String>
request.url.queryParametersAll     // Map<String, List<String>>

// Headers
request.headers['content-type']
request.headers['authorization']

// Body lesen
await request.readAsString()
await request.read().toList()  // Stream<List<int>>

// Context (von Middleware gesetzt)
request.context['userId']

// Request modifizieren
request.change(context: {'key': 'value'})
```

## Cheat Sheet: Response

```dart
// Konstruktoren
Response.ok('body')              // 200
Response.created('location')    // 201
Response.notFound('msg')        // 404
Response.forbidden('msg')       // 403
Response.internalServerError() // 500
Response(statusCode, body: 'x')

// Mit Headers
Response.ok('body', headers: {'x-custom': 'value'})

// Response modifizieren
response.change(headers: {'new': 'header'})

// Statuscode-Konstanten
200  // OK
201  // Created
204  // No Content
301  // Moved Permanently
302  // Found
400  // Bad Request
401  // Unauthorized
403  // Forbidden
404  // Not Found
500  // Internal Server Error
```

## Cheat Sheet: Pipeline

```dart
final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(customMiddleware())
    .addHandler(myHandler);

await shelf_io.serve(handler, 'localhost', 8080);
```

## Cheat Sheet: Middleware

```dart
// Einfache Middleware mit createMiddleware
Middleware myMiddleware() {
  return createMiddleware(
    requestHandler: (request) {
      // Vor dem Handler
      // Return Response um Handler zu überspringen
      // Return null um fortzufahren
      return null;
    },
    responseHandler: (response) {
      // Nach dem Handler
      return response.change(headers: {'x-processed': 'true'});
    },
  );
}

// Manuelle Middleware
Middleware customMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Vor Handler
      print('Before: ${request.url}');

      final response = await innerHandler(request);

      // Nach Handler
      print('After: ${response.statusCode}');

      return response;
    };
  };
}
```

## Test-Setup

```dart
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('handler returns ok', () async {
    final handler = (Request req) => Response.ok('Hello');

    final request = Request('GET', Uri.parse('http://localhost/'));
    final response = await handler(request);

    expect(response.statusCode, 200);
    expect(await response.readAsString(), 'Hello');
  });
}
```

## Weiterführende Links

- [Dart Server Tutorial](https://dart.dev/tutorials/server/httpserver)
- [Shelf Best Practices](https://github.com/dart-lang/shelf/blob/master/pkgs/shelf/README.md)
- [Building REST APIs with Shelf](https://dart.dev/tutorials/server/httpserver#write-a-handler)
