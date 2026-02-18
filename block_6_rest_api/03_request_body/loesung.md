# Lösung 6.3: Request Body Parsing

## Vollständige Lösung

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Aufgabe 3: Body Parser Middleware
// ============================================

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

      // Body lesen
      final bodyString = await request.readAsString();

      // Leerer Body
      if (bodyString.isEmpty) {
        final updated = request.change(context: {
          ...request.context,
          'body': <String, dynamic>{},
        });
        return innerHandler(updated);
      }

      // JSON parsen
      try {
        final json = jsonDecode(bodyString);
        final updated = request.change(context: {
          ...request.context,
          'body': json,
        });
        return innerHandler(updated);
      } on FormatException catch (e) {
        return errorResponse(400, 'INVALID_JSON', 'Invalid JSON: ${e.message}');
      }
    };
  };
}

// ============================================
// Aufgabe 4: Request Extension
// ============================================

extension RequestJsonBody on Request {
  /// Gibt den JSON Body zurück (oder leeres Map)
  Map<String, dynamic> get json {
    final body = context['body'];
    if (body is Map<String, dynamic>) {
      return body;
    }
    return {};
  }

  /// Extrahiert ein Feld mit Typ-Sicherheit
  T? field<T>(String key) {
    final value = json[key];
    if (value is T) {
      return value;
    }
    return null;
  }

  /// Extrahiert ein Pflichtfeld (wirft Exception wenn fehlt)
  String requireString(String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw MissingFieldException(key);
  }

  /// Extrahiert eine Pflicht-Map
  Map<String, dynamic> requireMap(String key) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw MissingFieldException(key);
  }

  /// Extrahiert eine Pflicht-Liste
  List<dynamic> requireList(String key) {
    final value = json[key];
    if (value is List && value.isNotEmpty) {
      return value;
    }
    throw MissingFieldException(key);
  }
}

class MissingFieldException implements Exception {
  final String field;
  MissingFieldException(this.field);

  @override
  String toString() => 'Missing required field: $field';
}

// ============================================
// Helper Functions
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Response errorResponse(int statusCode, String code, String message) {
  return Response(
    statusCode,
    body: jsonEncode({
      'error': {
        'code': code,
        'message': message,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}

// ============================================
// Data Storage
// ============================================

final _tasks = <String, Map<String, dynamic>>{};
var _nextTaskId = 1;

final _orders = <String, Map<String, dynamic>>{};
var _nextOrderId = 1;

// ============================================
// Aufgabe 1 & 2: Task Handler
// ============================================

Future<Response> createTask(Request request) async {
  // Aufgabe 2: Content-Type prüfen
  final contentType = request.headers['content-type'] ?? '';
  if (!contentType.contains('application/json')) {
    return errorResponse(415, 'UNSUPPORTED_MEDIA_TYPE',
        'Content-Type must be application/json');
  }

  // Body ist bereits durch Middleware geparst
  final body = request.json;

  // Aufgabe 2: Leerer Body
  if (body.isEmpty && request.context['body'] == null) {
    return errorResponse(400, 'EMPTY_BODY', 'Request body is empty');
  }

  // Aufgabe 2: Pflichtfeld prüfen
  final title = body['title'] as String?;
  if (title == null || title.isEmpty) {
    return errorResponse(400, 'MISSING_FIELD',
        "Required field 'title' is missing");
  }

  final description = body['description'] as String?;

  // Task erstellen
  final id = 'task-${_nextTaskId++}';
  final task = {
    'id': id,
    'title': title,
    'description': description,
    'completed': false,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  _tasks[id] = task;

  return jsonResponse(task, statusCode: 201);
}

// Alternative mit Extension
Future<Response> createTaskWithExtension(Request request) async {
  final contentType = request.headers['content-type'] ?? '';
  if (!contentType.contains('application/json')) {
    return errorResponse(415, 'UNSUPPORTED_MEDIA_TYPE',
        'Content-Type must be application/json');
  }

  try {
    final title = request.requireString('title');
    final description = request.field<String>('description');
    final priority = request.field<int>('priority') ?? 0;

    final id = 'task-${_nextTaskId++}';
    final task = {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'completed': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    _tasks[id] = task;
    return jsonResponse(task, statusCode: 201);

  } on MissingFieldException catch (e) {
    return errorResponse(400, 'MISSING_FIELD',
        "Required field '${e.field}' is missing");
  }
}

// ============================================
// Aufgabe 5: Komplexer Order Handler
// ============================================

Future<Response> createOrder(Request request) async {
  final contentType = request.headers['content-type'] ?? '';
  if (!contentType.contains('application/json')) {
    return errorResponse(415, 'UNSUPPORTED_MEDIA_TYPE',
        'Content-Type must be application/json');
  }

  try {
    // Customer validieren
    final customer = request.requireMap('customer');

    final customerName = customer['name'] as String?;
    if (customerName == null || customerName.isEmpty) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'customer.name' is missing");
    }

    final customerEmail = customer['email'] as String?;
    if (customerEmail == null || customerEmail.isEmpty) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'customer.email' is missing");
    }

    final address = customer['address'] as Map<String, dynamic>?;
    if (address == null) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'customer.address' is missing");
    }

    final city = address['city'] as String?;
    if (city == null || city.isEmpty) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'customer.address.city' is missing");
    }

    final zip = address['zip'] as String?;
    if (zip == null || zip.isEmpty) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'customer.address.zip' is missing");
    }

    // Items validieren
    final items = request.json['items'] as List<dynamic>?;
    if (items == null || items.isEmpty) {
      return errorResponse(400, 'MISSING_FIELD',
          "Required field 'items' must have at least 1 element");
    }

    var totalQuantity = 0;
    final validatedItems = <Map<String, dynamic>>[];

    for (var i = 0; i < items.length; i++) {
      final item = items[i] as Map<String, dynamic>?;
      if (item == null) {
        return errorResponse(400, 'INVALID_ITEM',
            "Item at index $i is invalid");
      }

      final productId = item['productId'] as String?;
      if (productId == null || productId.isEmpty) {
        return errorResponse(400, 'MISSING_FIELD',
            "Required field 'items[$i].productId' is missing");
      }

      final quantity = item['quantity'] as int?;
      if (quantity == null || quantity <= 0) {
        return errorResponse(400, 'INVALID_VALUE',
            "Field 'items[$i].quantity' must be greater than 0");
      }

      totalQuantity += quantity;
      validatedItems.add({
        'productId': productId,
        'quantity': quantity,
      });
    }

    // Optional: Notes
    final notes = request.field<String>('notes');

    // Order erstellen
    final orderId = 'order-${_nextOrderId++}';
    final order = {
      'orderId': orderId,
      'customer': {
        'name': customerName,
        'email': customerEmail,
        'address': {
          'street': address['street'] as String? ?? '',
          'city': city,
          'zip': zip,
        },
      },
      'items': validatedItems,
      'itemCount': totalQuantity,
      if (notes != null) 'notes': notes,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    _orders[orderId] = order;

    return jsonResponse(order, statusCode: 201);

  } on MissingFieldException catch (e) {
    return errorResponse(400, 'MISSING_FIELD',
        "Required field '${e.field}' is missing");
  }
}

// ============================================
// Bonus: Form Data Handler
// ============================================

Future<Response> handleLogin(Request request) async {
  final contentType = request.headers['content-type'] ?? '';

  if (!contentType.contains('application/x-www-form-urlencoded')) {
    return errorResponse(415, 'UNSUPPORTED_MEDIA_TYPE',
        'Content-Type must be application/x-www-form-urlencoded');
  }

  final body = await request.readAsString();

  if (body.isEmpty) {
    return errorResponse(400, 'EMPTY_BODY', 'Request body is empty');
  }

  final params = Uri.splitQueryString(body);

  final username = params['username'];
  final password = params['password'];

  if (username == null || username.isEmpty) {
    return errorResponse(400, 'MISSING_FIELD',
        "Required field 'username' is missing");
  }

  if (password == null || password.isEmpty) {
    return errorResponse(400, 'MISSING_FIELD',
        "Required field 'password' is missing");
  }

  // Einfache Demo-Validierung
  if (password.length < 6) {
    return errorResponse(401, 'INVALID_CREDENTIALS',
        'Invalid username or password');
  }

  return jsonResponse({
    'success': true,
    'message': 'Welcome, $username!',
  });
}

// ============================================
// Main
// ============================================

void main() async {
  final app = Router();

  // Task Endpoints
  app.post('/api/tasks', createTask);
  app.post('/api/tasks/v2', createTaskWithExtension);

  // Order Endpoint
  app.post('/api/orders', createOrder);

  // Login Endpoint (Form Data)
  app.post('/login', handleLogin);

  // Liste aller Tasks (für Tests)
  app.get('/api/tasks', (Request request) {
    return jsonResponse({
      'tasks': _tasks.values.toList(),
      'total': _tasks.length,
    });
  });

  // Liste aller Orders (für Tests)
  app.get('/api/orders', (Request request) {
    return jsonResponse({
      'orders': _orders.values.toList(),
      'total': _orders.length,
    });
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('');
  print('Test-Befehle:');
  print('');
  print('# Task erstellen');
  print('curl -X POST http://localhost:8080/api/tasks \\');
  print('  -H "Content-Type: application/json" \\');
  print('  -d \'{"title": "Einkaufen", "description": "Milch"}\'');
  print('');
  print('# Order erstellen');
  print('curl -X POST http://localhost:8080/api/orders \\');
  print('  -H "Content-Type: application/json" \\');
  print('  -d \'{"customer":{"name":"Max","email":"max@test.de","address":{"city":"Berlin","zip":"10115"}},"items":[{"productId":"p1","quantity":2}]}\'');
  print('');
  print('# Login (Form Data)');
  print('curl -X POST http://localhost:8080/login \\');
  print('  -H "Content-Type: application/x-www-form-urlencoded" \\');
  print('  -d "username=max&password=secret123"');
}
```

---

## Test-Befehle

```bash
# === Aufgabe 1: Task erstellen ===
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Einkaufen", "description": "Milch und Brot"}'

# === Aufgabe 2: Fehler testen ===

# Ohne Content-Type → 415
curl -X POST http://localhost:8080/api/tasks \
  -d '{"title": "Test"}'

# Leerer Body → 400
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d ''

# Ungültiges JSON → 400
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{invalid}'

# Fehlendes Pflichtfeld → 400
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"description": "ohne title"}'

# === Aufgabe 5: Order erstellen ===

# Erfolgreiche Order
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {
      "name": "Max Mustermann",
      "email": "max@example.com",
      "address": {
        "street": "Hauptstraße 1",
        "city": "Berlin",
        "zip": "10115"
      }
    },
    "items": [
      {"productId": "prod-1", "quantity": 2},
      {"productId": "prod-2", "quantity": 1}
    ],
    "notes": "Bitte klingeln"
  }'

# Fehlende Items → 400
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {"name": "Max", "email": "max@test.de", "address": {"city": "Berlin", "zip": "10115"}},
    "items": []
  }'

# Ungültige Quantity → 400
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{
    "customer": {"name": "Max", "email": "max@test.de", "address": {"city": "Berlin", "zip": "10115"}},
    "items": [{"productId": "p1", "quantity": 0}]
  }'

# === Bonus: Login ===
curl -X POST http://localhost:8080/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=max&password=secret123"

# === Listen abrufen ===
curl http://localhost:8080/api/tasks
curl http://localhost:8080/api/orders
```

---

## Ausgabe-Beispiele

### Task erstellen (201)

```json
{
  "id": "task-1",
  "title": "Einkaufen",
  "description": "Milch und Brot",
  "completed": false,
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

### Fehler: Missing Field (400)

```json
{
  "error": {
    "code": "MISSING_FIELD",
    "message": "Required field 'title' is missing"
  }
}
```

### Order erstellen (201)

```json
{
  "orderId": "order-1",
  "customer": {
    "name": "Max Mustermann",
    "email": "max@example.com",
    "address": {
      "street": "Hauptstraße 1",
      "city": "Berlin",
      "zip": "10115"
    }
  },
  "items": [
    {"productId": "prod-1", "quantity": 2},
    {"productId": "prod-2", "quantity": 1}
  ],
  "itemCount": 3,
  "notes": "Bitte klingeln",
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

### Login Erfolg (200)

```json
{
  "success": true,
  "message": "Welcome, max!"
}
```

---

## Wichtige Patterns

### Middleware speichert geparseten Body

```dart
final updated = request.change(context: {
  ...request.context,
  'body': json,  // Hier speichern
});
return innerHandler(updated);

// Später im Handler:
final body = request.context['body'] as Map<String, dynamic>;
```

### Extension für sauberen Zugriff

```dart
extension RequestJsonBody on Request {
  Map<String, dynamic> get json {
    final body = context['body'];
    return body is Map<String, dynamic> ? body : {};
  }
}

// Verwendung
final title = request.json['title'];
```

### Strukturierte Fehler-Responses

```dart
Response errorResponse(int statusCode, String code, String message) {
  return Response(
    statusCode,
    body: jsonEncode({
      'error': {
        'code': code,
        'message': message,
      },
    }),
    headers: {'content-type': 'application/json'},
  );
}
```
