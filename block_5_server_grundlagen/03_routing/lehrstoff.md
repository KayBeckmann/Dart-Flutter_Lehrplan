# Einheit 5.3: Routing mit shelf_router

## Lernziele

Nach dieser Einheit kannst du:
- Das `shelf_router`-Package für deklaratives Routing nutzen
- URL-Parameter und Query-Parameter extrahieren
- Routes gruppieren und organisieren
- Verschiedene HTTP-Methoden handhaben

---

## Warum shelf_router?

In der letzten Einheit haben wir Routing mit `if-else` implementiert. Das funktioniert, wird aber schnell unübersichtlich:

```dart
// Ohne shelf_router - wird schnell unübersichtlich
if (path == 'api/users' && method == 'GET') { ... }
if (path == 'api/users' && method == 'POST') { ... }
if (path.startsWith('api/users/') && method == 'GET') {
  final id = path.split('/').last;  // Manuelles Parsen
  ...
}
```

**shelf_router** bietet:
- Deklarative Route-Definitionen
- Automatisches URL-Parameter-Parsing
- Methodenspezifische Handler
- Route-Gruppen (Mounting)

### Installation

```yaml
dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
```

---

## Router Basics

### Router erstellen

```dart
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final router = Router();

// Routes definieren
router.get('/', (Request request) {
  return Response.ok('Home');
});

router.get('/api/status', (Request request) {
  return Response.ok('OK');
});

// Router als Handler verwenden
final handler = Pipeline()
    .addMiddleware(logRequests())
    .addHandler(router.call);
```

### HTTP-Methoden

```dart
final router = Router();

router.get('/users', _getUsers);
router.post('/users', _createUser);
router.put('/users/<id>', _updateUser);
router.patch('/users/<id>', _patchUser);
router.delete('/users/<id>', _deleteUser);

// Alle Methoden
router.all('/any', (Request request) {
  return Response.ok('Method: ${request.method}');
});
```

---

## URL-Parameter

URL-Parameter werden mit `<name>` definiert und automatisch extrahiert.

### Einfache Parameter

```dart
// Route: /users/<id>
// URL:   /users/42
router.get('/users/<id>', (Request request, String id) {
  return Response.ok('User ID: $id');
});

// Mehrere Parameter
// Route: /projects/<projectId>/tasks/<taskId>
// URL:   /projects/abc/tasks/123
router.get('/projects/<projectId>/tasks/<taskId>',
    (Request request, String projectId, String taskId) {
  return Response.ok('Project: $projectId, Task: $taskId');
});
```

### Parameter-Typen

Standardmäßig sind Parameter Strings. Konvertierung erfolgt manuell:

```dart
router.get('/users/<id>', (Request request, String id) async {
  final userId = int.tryParse(id);

  if (userId == null) {
    return Response.badRequest(body: 'Invalid user ID');
  }

  // Benutzer laden...
  return Response.ok('User: $userId');
});
```

### Regex-Parameter

Für komplexere Muster:

```dart
// Nur Zahlen erlauben
router.get('/users/<id|[0-9]+>', (Request request, String id) {
  // id ist garantiert nur Ziffern
  return Response.ok('User: $id');
});

// UUID-Format
router.get('/items/<uuid|[a-f0-9-]{36}>', (Request request, String uuid) {
  return Response.ok('Item: $uuid');
});
```

### Catch-All Parameter

Für Pfade mit beliebiger Tiefe:

```dart
// Alle Pfade unter /files/ abfangen
router.get('/files/<path|.*>', (Request request, String path) {
  // path = 'documents/2024/report.pdf'
  return Response.ok('File path: $path');
});
```

---

## Query-Parameter

Query-Parameter werden über `request.url.queryParameters` ausgelesen:

```dart
// URL: /search?q=dart&limit=10&sort=name
router.get('/search', (Request request) {
  final params = request.url.queryParameters;

  final query = params['q'] ?? '';
  final limit = int.tryParse(params['limit'] ?? '10') ?? 10;
  final sort = params['sort'] ?? 'id';

  return Response.ok('Search: $query, Limit: $limit, Sort: $sort');
});
```

### Mehrfache Query-Parameter

```dart
// URL: /filter?tag=dart&tag=flutter&tag=server
router.get('/filter', (Request request) {
  final allParams = request.url.queryParametersAll;

  // {'tag': ['dart', 'flutter', 'server']}
  final tags = allParams['tag'] ?? [];

  return Response.ok('Tags: ${tags.join(', ')}');
});
```

### Query-Parameter validieren

```dart
router.get('/users', (Request request) {
  final params = request.url.queryParameters;

  // Pflichtparameter prüfen
  if (!params.containsKey('status')) {
    return Response.badRequest(body: 'Missing required parameter: status');
  }

  // Gültige Werte prüfen
  final status = params['status']!;
  if (!['active', 'inactive', 'pending'].contains(status)) {
    return Response.badRequest(body: 'Invalid status value');
  }

  return Response.ok('Status: $status');
});
```

---

## Route-Gruppen (Mounting)

Für bessere Organisation können Router ineinander gemountet werden:

### Sub-Router erstellen

```dart
// User-Routes
Router userRouter() {
  final router = Router();

  router.get('/', (Request request) {
    return Response.ok('List all users');
  });

  router.get('/<id>', (Request request, String id) {
    return Response.ok('Get user $id');
  });

  router.post('/', (Request request) async {
    return Response.ok('Create user');
  });

  router.put('/<id>', (Request request, String id) async {
    return Response.ok('Update user $id');
  });

  router.delete('/<id>', (Request request, String id) {
    return Response.ok('Delete user $id');
  });

  return router;
}

// Product-Routes
Router productRouter() {
  final router = Router();

  router.get('/', (Request request) => Response.ok('List products'));
  router.get('/<id>', (Request request, String id) => Response.ok('Product $id'));

  return router;
}
```

### Router mounten

```dart
void main() async {
  final app = Router();

  // Sub-Router mounten
  app.mount('/api/users', userRouter().call);
  app.mount('/api/products', productRouter().call);

  // Root-Route
  app.get('/', (Request request) => Response.ok('API Home'));

  // Health-Check
  app.get('/health', (Request request) => Response.ok('OK'));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
}
```

### Resultierende Routes

```
GET  /                    -> API Home
GET  /health              -> OK
GET  /api/users           -> List all users
GET  /api/users/42        -> Get user 42
POST /api/users           -> Create user
PUT  /api/users/42        -> Update user 42
DELETE /api/users/42      -> Delete user 42
GET  /api/products        -> List products
GET  /api/products/123    -> Product 123
```

---

## Handler-Klassen

Für größere Projekte empfiehlt sich die Aufteilung in Klassen:

### Controller-Pattern

```dart
class UserController {
  // Abhängigkeiten
  final UserRepository _repository;

  UserController(this._repository);

  // Handler als Router
  Router get router {
    final router = Router();

    router.get('/', _list);
    router.get('/<id>', _getById);
    router.post('/', _create);
    router.put('/<id>', _update);
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _list(Request request) async {
    final users = await _repository.findAll();
    return jsonResponse(users);
  }

  Future<Response> _getById(Request request, String id) async {
    final user = await _repository.findById(id);
    if (user == null) {
      return Response.notFound('User not found');
    }
    return jsonResponse(user);
  }

  Future<Response> _create(Request request) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final user = await _repository.create(data);
    return jsonResponse(user, statusCode: 201);
  }

  Future<Response> _update(Request request, String id) async {
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final user = await _repository.update(id, data);
    return jsonResponse(user);
  }

  Future<Response> _delete(Request request, String id) async {
    await _repository.delete(id);
    return Response(204); // No Content
  }
}
```

### Controller verwenden

```dart
void main() async {
  // Abhängigkeiten erstellen
  final userRepo = UserRepository();

  // Controller erstellen
  final userController = UserController(userRepo);

  // Router aufbauen
  final app = Router();
  app.mount('/api/users', userController.router.call);

  await shelf_io.serve(app.call, 'localhost', 8080);
}
```

---

## 404 Handling

Wenn keine Route matcht, gibt shelf_router automatisch 404 zurück. Du kannst das anpassen:

```dart
final router = Router();

// Normale Routes
router.get('/api/status', (Request request) => Response.ok('OK'));

// Catch-All für 404
router.all('/<ignored|.*>', (Request request, String ignored) {
  return Response.notFound(
    jsonEncode({
      'error': 'Not Found',
      'path': request.requestedUri.path,
      'method': request.method,
    }),
    headers: {'content-type': 'application/json'},
  );
});
```

---

## Beispiel: Vollständige API

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// In-Memory Datenbank
final _users = <String, Map<String, dynamic>>{};
var _nextId = 1;

void main() async {
  final app = Router();

  // API-Routen
  app.mount('/api/v1', apiRouter().call);

  // Root
  app.get('/', (Request r) => Response.ok('API Server v1.0'));

  // 404
  app.all('/<path|.*>', (Request r, String p) {
    return jsonResponse({'error': 'Not Found'}, statusCode: 404);
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
}

Router apiRouter() {
  final router = Router();

  // User CRUD
  router.get('/users', _listUsers);
  router.get('/users/<id>', _getUser);
  router.post('/users', _createUser);
  router.put('/users/<id>', _updateUser);
  router.delete('/users/<id>', _deleteUser);

  // Search
  router.get('/search', _search);

  return router;
}

Response _listUsers(Request request) {
  return jsonResponse({
    'users': _users.values.toList(),
    'count': _users.length,
  });
}

Response _getUser(Request request, String id) {
  final user = _users[id];
  if (user == null) {
    return jsonResponse({'error': 'User not found'}, statusCode: 404);
  }
  return jsonResponse(user);
}

Future<Response> _createUser(Request request) async {
  final body = jsonDecode(await request.readAsString());
  final id = '${_nextId++}';

  _users[id] = {
    'id': id,
    'name': body['name'],
    'email': body['email'],
    'createdAt': DateTime.now().toIso8601String(),
  };

  return jsonResponse(_users[id], statusCode: 201);
}

Future<Response> _updateUser(Request request, String id) async {
  if (!_users.containsKey(id)) {
    return jsonResponse({'error': 'User not found'}, statusCode: 404);
  }

  final body = jsonDecode(await request.readAsString());
  _users[id] = {..._users[id]!, ...body, 'id': id};

  return jsonResponse(_users[id]);
}

Response _deleteUser(Request request, String id) {
  if (!_users.containsKey(id)) {
    return jsonResponse({'error': 'User not found'}, statusCode: 404);
  }

  _users.remove(id);
  return Response(204);
}

Response _search(Request request) {
  final params = request.url.queryParameters;
  final query = params['q']?.toLowerCase() ?? '';

  final results = _users.values.where((user) {
    final name = (user['name'] as String?)?.toLowerCase() ?? '';
    return name.contains(query);
  }).toList();

  return jsonResponse({'results': results, 'query': query});
}

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Zusammenfassung

- **shelf_router** bietet deklaratives Routing
- **URL-Parameter** werden mit `<name>` definiert
- **Regex-Parameter** erlauben Validierung: `<id|[0-9]+>`
- **Query-Parameter** über `request.url.queryParameters`
- **Route-Gruppen** mit `router.mount('/prefix', subRouter.call)`
- **Controller-Pattern** für bessere Code-Organisation

---

## Nächste Schritte

In der nächsten Einheit lernst du **Middleware** im Detail: Logging, CORS, Error-Handling und eigene Middleware-Funktionen.
