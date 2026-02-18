# Einheit 6.3: Request Body Parsing

## Lernziele

Nach dieser Einheit kannst du:
- Request Bodies aus HTTP-Anfragen auslesen
- JSON-Daten aus POST/PUT/PATCH-Requests parsen
- Content-Type Header korrekt verarbeiten
- Fehlerhafte Request Bodies behandeln

---

## Request Body Grundlagen

### HTTP Request Anatomie

```
POST /api/users HTTP/1.1
Host: localhost:8080
Content-Type: application/json
Content-Length: 45

{"name": "Max", "email": "max@example.com"}
```

Ein HTTP-Request besteht aus:
1. **Request Line**: Methode, Pfad, HTTP-Version
2. **Headers**: Metadaten (Content-Type, Authorization, etc.)
3. **Body**: Die eigentlichen Daten (bei POST, PUT, PATCH)

---

## Body lesen mit Shelf

### Einfaches Body-Lesen

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Future<Response> handlePost(Request request) async {
  // Body als String lesen
  final bodyString = await request.readAsString();
  print('Received: $bodyString');

  // JSON parsen
  final json = jsonDecode(bodyString) as Map<String, dynamic>;

  return Response.ok('Received: ${json['name']}');
}
```

### Body kann nur einmal gelesen werden!

```dart
Future<Response> handleRequest(Request request) async {
  // Erstes Lesen funktioniert
  final body1 = await request.readAsString();

  // Zweites Lesen gibt leeren String!
  final body2 = await request.readAsString();
  print(body2); // ""

  return Response.ok('OK');
}
```

**Wichtig**: Der Request Body ist ein Stream und kann nur einmal konsumiert werden!

---

## JSON Body Parsing

### Sichere JSON-Verarbeitung

```dart
Future<Response> createUser(Request request) async {
  // 1. Content-Type prüfen
  final contentType = request.headers['content-type'];
  if (contentType == null || !contentType.contains('application/json')) {
    return Response(
      415, // Unsupported Media Type
      body: jsonEncode({'error': 'Content-Type must be application/json'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // 2. Body lesen
  final bodyString = await request.readAsString();

  // 3. Leeren Body abfangen
  if (bodyString.isEmpty) {
    return Response(
      400,
      body: jsonEncode({'error': 'Request body is empty'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // 4. JSON parsen (mit Fehlerbehandlung)
  Map<String, dynamic> json;
  try {
    json = jsonDecode(bodyString) as Map<String, dynamic>;
  } on FormatException catch (e) {
    return Response(
      400,
      body: jsonEncode({'error': 'Invalid JSON: ${e.message}'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // 5. Daten verarbeiten
  final name = json['name'] as String?;
  final email = json['email'] as String?;

  if (name == null || email == null) {
    return Response(
      400,
      body: jsonEncode({'error': 'Missing required fields: name, email'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // Erfolg
  return Response(
    201,
    body: jsonEncode({'id': '123', 'name': name, 'email': email}),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Body Parser Middleware

### Wiederverwendbare Middleware

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

/// Middleware die JSON Body parst und in request.context speichert
Middleware jsonBodyParser() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Nur bei relevanten Methoden
      if (!['POST', 'PUT', 'PATCH'].contains(request.method)) {
        return innerHandler(request);
      }

      // Content-Type prüfen
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return innerHandler(request);
      }

      // Body lesen und parsen
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        // Leerer Body als leeres Objekt
        final updated = request.change(context: {
          ...request.context,
          'body': <String, dynamic>{},
        });
        return innerHandler(updated);
      }

      try {
        final json = jsonDecode(bodyString);
        final updated = request.change(context: {
          ...request.context,
          'body': json,
        });
        return innerHandler(updated);
      } on FormatException {
        return Response(
          400,
          body: jsonEncode({'error': 'Invalid JSON in request body'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
```

### Verwendung der Middleware

```dart
void main() async {
  final router = Router();

  router.post('/users', (Request request) {
    // Body ist bereits geparst im Context
    final body = request.context['body'] as Map<String, dynamic>;

    final name = body['name'];
    final email = body['email'];

    return Response.ok(jsonEncode({
      'message': 'User $name created',
    }));
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())  // Body Parser aktivieren
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
}
```

---

## Extension für einfacheren Zugriff

### Request Extension

```dart
extension RequestBody on Request {
  /// Gibt den geparseten JSON Body zurück
  Map<String, dynamic> get jsonBody {
    final body = context['body'];
    if (body is Map<String, dynamic>) {
      return body;
    }
    return {};
  }

  /// Prüft ob ein JSON Body vorhanden ist
  bool get hasJsonBody => context.containsKey('body');
}

// Verwendung
router.post('/users', (Request request) {
  final body = request.jsonBody;
  final name = body['name'];
  // ...
});
```

---

## Model aus Body erstellen

### Direkte Konvertierung

```dart
class CreateUserRequest {
  final String name;
  final String email;
  final String? phone;

  CreateUserRequest({
    required this.name,
    required this.email,
    this.phone,
  });

  factory CreateUserRequest.fromJson(Map<String, dynamic> json) {
    return CreateUserRequest(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }
}

// Im Handler
router.post('/users', (Request request) async {
  final body = await request.readAsString();
  final json = jsonDecode(body) as Map<String, dynamic>;

  final createRequest = CreateUserRequest.fromJson(json);

  // User erstellen...
  final user = User(
    id: generateId(),
    name: createRequest.name,
    email: createRequest.email,
    phone: createRequest.phone,
  );

  return Response(201, body: jsonEncode(user.toJson()));
});
```

---

## Verschiedene Content-Types

### Form Data (URL-encoded)

```dart
Future<Response> handleFormData(Request request) async {
  final contentType = request.headers['content-type'] ?? '';

  if (contentType.contains('application/x-www-form-urlencoded')) {
    final body = await request.readAsString();
    // username=max&password=secret
    final params = Uri.splitQueryString(body);

    final username = params['username'];
    final password = params['password'];

    return Response.ok('Username: $username');
  }

  return Response(415, body: 'Unsupported Media Type');
}
```

### Multipart Form Data (Datei-Upload)

```dart
// Für Datei-Uploads wird meist ein spezielles Package verwendet
// z.B. shelf_multipart

import 'package:shelf_multipart/shelf_multipart.dart';

Future<Response> handleFileUpload(Request request) async {
  if (!request.isMultipart) {
    return Response(400, body: 'Expected multipart request');
  }

  await for (final part in request.parts) {
    final contentDisposition = part.headers['content-disposition'];
    final filename = // ... aus contentDisposition extrahieren

    final bytes = await part.readBytes();
    // Datei speichern...
  }

  return Response.ok('File uploaded');
}
```

---

## Fehlerbehandlung Best Practices

### Strukturierte Fehler-Responses

```dart
Response badRequest(String message, {Map<String, dynamic>? details}) {
  return Response(
    400,
    body: jsonEncode({
      'error': {
        'code': 'BAD_REQUEST',
        'message': message,
        if (details != null) 'details': details,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

// Verwendung
if (json['name'] == null) {
  return badRequest('Missing required field', details: {
    'field': 'name',
    'expected': 'string',
  });
}
```

---

## Zusammenfassung

| Aufgabe | Lösung |
|---------|--------|
| Body lesen | `await request.readAsString()` |
| JSON parsen | `jsonDecode(bodyString)` |
| Content-Type prüfen | `request.headers['content-type']` |
| Wiederverwendbar | Middleware mit `request.context` |
| Fehlerbehandlung | try/catch mit passenden HTTP-Codes |

### HTTP Status Codes für Body-Fehler

| Code | Bedeutung | Verwendung |
|------|-----------|------------|
| 400 | Bad Request | Ungültiges JSON, fehlende Felder |
| 415 | Unsupported Media Type | Falscher Content-Type |
| 422 | Unprocessable Entity | Valides JSON, aber ungültige Daten |

---

## Nächste Schritte

In der nächsten Einheit lernst du **CRUD-Operationen**: Wie du alle grundlegenden Datenbankoperationen (Create, Read, Update, Delete) über REST-Endpoints implementierst.
