# Ressourcen: Middleware

## Offizielle Dokumentation

- [Shelf Middleware](https://pub.dev/documentation/shelf/latest/shelf/Middleware.html) - API-Referenz
- [createMiddleware](https://pub.dev/documentation/shelf/latest/shelf/createMiddleware.html) - Helper-Funktion

## Nützliche Middleware-Packages

| Package | Beschreibung | Link |
|---------|--------------|------|
| `shelf_cors_headers` | CORS-Middleware | [pub.dev](https://pub.dev/packages/shelf_cors_headers) |
| `shelf_helmet` | Security Headers | [pub.dev](https://pub.dev/packages/shelf_helmet) |
| `shelf_rate_limiter` | Rate Limiting | [pub.dev](https://pub.dev/packages/shelf_rate_limiter) |
| `shelf_static` | Statische Dateien | [pub.dev](https://pub.dev/packages/shelf_static) |

## Cheat Sheet: Middleware-Struktur

```dart
// Vollständige Middleware-Signatur
Middleware myMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // 1. VOR Handler (Request bearbeiten)

      // 2. Handler aufrufen
      final response = await innerHandler(request);

      // 3. NACH Handler (Response bearbeiten)

      return response;
    };
  };
}
```

## Cheat Sheet: createMiddleware

```dart
Middleware simple() {
  return createMiddleware(
    // Request abfangen (return Response oder null)
    requestHandler: (Request request) => null,

    // Response modifizieren
    responseHandler: (Response response) => response,

    // Fehler behandeln
    errorHandler: (error, stack) => Response.internalServerError(),
  );
}
```

## Cheat Sheet: Häufige Patterns

### Logging

```dart
Middleware logger() => (Handler h) => (Request r) async {
  final sw = Stopwatch()..start();
  final res = await h(r);
  print('${r.method} ${r.url} - ${res.statusCode} (${sw.elapsedMilliseconds}ms)');
  return res;
};
```

### CORS

```dart
Middleware cors() => createMiddleware(
  requestHandler: (r) => r.method == 'OPTIONS'
    ? Response.ok('', headers: {'Access-Control-Allow-Origin': '*'})
    : null,
  responseHandler: (r) => r.change(headers: {
    'Access-Control-Allow-Origin': '*',
  }),
);
```

### Auth

```dart
Middleware auth(String Function(String) validate) => (Handler h) => (Request r) async {
  final token = r.headers['authorization']?.replaceFirst('Bearer ', '');
  if (token == null) return Response(401);
  try {
    final userId = validate(token);
    return h(r.change(context: {'userId': userId}));
  } catch (e) {
    return Response(401);
  }
};
```

### Error Handler

```dart
Middleware errors() => (Handler h) => (Request r) async {
  try {
    return await h(r);
  } catch (e, s) {
    print('Error: $e\n$s');
    return Response.internalServerError();
  }
};
```

### Request Timer

```dart
Middleware timer() => (Handler h) => (Request r) async {
  final sw = Stopwatch()..start();
  final res = await h(r);
  return res.change(headers: {'X-Response-Time': '${sw.elapsedMilliseconds}ms'});
};
```

## Pipeline-Reihenfolge

```dart
Pipeline()
    .addMiddleware(errorHandler())    // 1. Außen: Fehler fangen
    .addMiddleware(logger())          // 2. Logging
    .addMiddleware(cors())            // 3. CORS (vor Auth!)
    .addMiddleware(auth())            // 4. Authentication
    .addMiddleware(bodyParser())      // 5. Body parsen
    .addHandler(router);              // 6. Handler
```

## Context verwenden

```dart
// In Middleware setzen
final newRequest = request.change(context: {
  'userId': '123',
  'roles': ['admin', 'user'],
});

// Im Handler lesen
final userId = request.context['userId'] as String?;
final roles = request.context['roles'] as List<String>?;
```

## Bedingte Middleware

```dart
Middleware onlyFor(String pathPrefix, Middleware m) {
  return (Handler h) {
    final wrapped = m(h);
    return (Request r) {
      if (r.url.path.startsWith(pathPrefix)) {
        return wrapped(r);
      }
      return h(r);
    };
  };
}

// Verwendung
.addMiddleware(onlyFor('api/', authMiddleware()))
```

## Test-Middleware

```dart
import 'package:test/test.dart';

void main() {
  test('auth middleware rejects missing token', () async {
    final middleware = authMiddleware();
    final handler = middleware((r) => Response.ok('OK'));

    final request = Request('GET', Uri.parse('http://localhost/api/data'));
    final response = await handler(request);

    expect(response.statusCode, 401);
  });
}
```
