# Ressourcen: Request Body Parsing

## Offizielle Dokumentation

- [Shelf Request API](https://pub.dev/documentation/shelf/latest/shelf/Request-class.html)
- [dart:convert](https://api.dart.dev/stable/dart-convert/dart-convert-library.html)
- [HTTP Content-Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Type)

## Cheat Sheet: Body lesen

```dart
// Body als String
final body = await request.readAsString();

// Body als Bytes
final bytes = await request.read().toList();
final allBytes = bytes.expand((b) => b).toList();

// Achtung: Body kann nur einmal gelesen werden!
```

## Cheat Sheet: JSON Body

```dart
import 'dart:convert';

Future<Response> handler(Request request) async {
  // Body lesen und parsen
  final body = await request.readAsString();
  final json = jsonDecode(body) as Map<String, dynamic>;

  // Felder extrahieren
  final name = json['name'] as String;
  final age = json['age'] as int;
  final email = json['email'] as String?;  // Optional

  return Response.ok('OK');
}
```

## Cheat Sheet: Content-Type prüfen

```dart
final contentType = request.headers['content-type'] ?? '';

if (contentType.contains('application/json')) {
  // JSON verarbeiten
} else if (contentType.contains('application/x-www-form-urlencoded')) {
  // Form-Daten verarbeiten
} else if (contentType.contains('multipart/form-data')) {
  // Datei-Upload verarbeiten
} else {
  return Response(415); // Unsupported Media Type
}
```

## Cheat Sheet: Sichere Extraktion

```dart
// Mit Default-Werten
final name = json['name'] as String? ?? 'Unknown';
final age = json['age'] as int? ?? 0;

// Mit Null-Check
final name = json['name'] as String?;
if (name == null) {
  return badRequest('name is required');
}

// Typ-sichere Konvertierung
int parseId(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
```

## Cheat Sheet: Body Parser Middleware

```dart
Middleware jsonBodyParser() {
  return (Handler handler) {
    return (Request request) async {
      if (!['POST', 'PUT', 'PATCH'].contains(request.method)) {
        return handler(request);
      }

      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return handler(request);
      }

      final body = await request.readAsString();
      if (body.isEmpty) {
        return handler(request.change(context: {
          ...request.context,
          'body': <String, dynamic>{},
        }));
      }

      try {
        final json = jsonDecode(body);
        return handler(request.change(context: {
          ...request.context,
          'body': json,
        }));
      } on FormatException {
        return Response(400,
          body: '{"error": "Invalid JSON"}',
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

// Verwendung
final handler = Pipeline()
    .addMiddleware(jsonBodyParser())
    .addHandler(router.call);
```

## Cheat Sheet: Form Data

```dart
// application/x-www-form-urlencoded
// Body: username=max&password=secret

final body = await request.readAsString();
final params = Uri.splitQueryString(body);

final username = params['username'];  // "max"
final password = params['password'];  // "secret"
```

## Cheat Sheet: Fehler-Responses

```dart
// 400 Bad Request - Allgemeiner Client-Fehler
Response badRequest(String message) => Response(400,
  body: jsonEncode({'error': message}),
  headers: {'content-type': 'application/json'},
);

// 415 Unsupported Media Type - Falscher Content-Type
Response unsupportedMediaType() => Response(415,
  body: jsonEncode({'error': 'Content-Type must be application/json'}),
  headers: {'content-type': 'application/json'},
);

// 422 Unprocessable Entity - Semantische Fehler
Response unprocessableEntity(String message) => Response(422,
  body: jsonEncode({'error': message}),
  headers: {'content-type': 'application/json'},
);
```

## Cheat Sheet: Request Extension

```dart
extension RequestBody on Request {
  Map<String, dynamic> get jsonBody {
    final body = context['body'];
    if (body is Map<String, dynamic>) return body;
    return {};
  }

  T? getField<T>(String key) {
    return jsonBody[key] as T?;
  }

  String requireField(String key) {
    final value = jsonBody[key] as String?;
    if (value == null) {
      throw ArgumentError('Missing required field: $key');
    }
    return value;
  }
}
```

## HTTP Content-Types

| Content-Type | Verwendung |
|-------------|------------|
| `application/json` | REST APIs, strukturierte Daten |
| `application/x-www-form-urlencoded` | HTML-Formulare |
| `multipart/form-data` | Datei-Uploads |
| `text/plain` | Einfacher Text |
| `application/xml` | XML-Daten |

## HTTP Status Codes für Body-Fehler

| Code | Name | Verwendung |
|------|------|------------|
| 400 | Bad Request | Ungültiges JSON, Syntax-Fehler |
| 415 | Unsupported Media Type | Content-Type nicht unterstützt |
| 422 | Unprocessable Entity | Valide Syntax, aber ungültige Semantik |

## Test-Befehle

```bash
# JSON Body senden
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max", "email": "max@example.com"}'

# Form Data senden
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=max&password=secret"

# Datei hochladen
curl -X POST http://localhost:8080/upload \
  -F "file=@/path/to/file.pdf"

# Ohne Content-Type (sollte 415 geben)
curl -X POST http://localhost:8080/api/users \
  -d '{"name": "Max"}'

# Ungültiges JSON (sollte 400 geben)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{invalid json}'
```

## Debugging-Tipps

```dart
// Body und Headers loggen
Future<Response> debugHandler(Request request) async {
  print('Method: ${request.method}');
  print('Path: ${request.url.path}');
  print('Headers: ${request.headers}');

  final body = await request.readAsString();
  print('Body: $body');

  return Response.ok('Debug logged');
}
```
