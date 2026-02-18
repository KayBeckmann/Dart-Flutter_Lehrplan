# Ressourcen: Routing mit shelf_router

## Offizielle Dokumentation

- [shelf_router Package](https://pub.dev/packages/shelf_router) - pub.dev
- [shelf_router API](https://pub.dev/documentation/shelf_router/latest/) - API-Referenz
- [shelf_router GitHub](https://github.com/dart-lang/shelf/tree/master/pkgs/shelf_router) - Quellcode

## Cheat Sheet: Router

```dart
import 'package:shelf_router/shelf_router.dart';

final router = Router();

// HTTP-Methoden
router.get('/path', handler);
router.post('/path', handler);
router.put('/path', handler);
router.patch('/path', handler);
router.delete('/path', handler);
router.head('/path', handler);
router.options('/path', handler);
router.all('/path', handler);  // Alle Methoden

// URL-Parameter
router.get('/users/<id>', (Request req, String id) => ...);
router.get('/a/<x>/b/<y>', (Request req, String x, String y) => ...);

// Regex-Parameter
router.get('/users/<id|[0-9]+>', handler);     // Nur Zahlen
router.get('/files/<path|.*>', handler);       // Catch-all

// Router mounten
router.mount('/api', subRouter.call);

// Als Handler verwenden
final handler = router.call;
// oder: router
```

## Cheat Sheet: Parameter

```dart
// URL-Parameter
router.get('/users/<id>', (Request request, String id) {
  // /users/42 -> id = "42"
  return Response.ok('User: $id');
});

// Query-Parameter
router.get('/search', (Request request) {
  // /search?q=dart&limit=10
  final params = request.url.queryParameters;
  final q = params['q'];      // "dart"
  final limit = params['limit']; // "10"
  return Response.ok('...');
});

// Mehrfache Query-Parameter
router.get('/filter', (Request request) {
  // /filter?tag=a&tag=b
  final all = request.url.queryParametersAll;
  final tags = all['tag']; // ["a", "b"]
  return Response.ok('...');
});
```

## Cheat Sheet: Route-Gruppen

```dart
// Sub-Router definieren
Router userRoutes() {
  final r = Router();
  r.get('/', listUsers);       // -> /api/users
  r.get('/<id>', getUser);     // -> /api/users/42
  r.post('/', createUser);     // -> /api/users
  return r;
}

// Mounten
final app = Router();
app.mount('/api/users', userRoutes().call);
```

## Cheat Sheet: Controller-Pattern

```dart
class TodoController {
  final TodoRepository _repo;
  TodoController(this._repo);

  Router get router {
    final r = Router();
    r.get('/', list);
    r.get('/<id>', getById);
    r.post('/', create);
    r.put('/<id>', update);
    r.delete('/<id>', delete);
    return r;
  }

  Response list(Request req) => ...;
  Response getById(Request req, String id) => ...;
  Future<Response> create(Request req) async => ...;
  Future<Response> update(Request req, String id) async => ...;
  Response delete(Request req, String id) => ...;
}

// Verwendung
final controller = TodoController(repo);
app.mount('/api/todos', controller.router.call);
```

## Beispiel: CRUD-API

```dart
final router = Router();

// CREATE
router.post('/items', (Request request) async {
  final body = jsonDecode(await request.readAsString());
  // Item erstellen...
  return Response(201, body: jsonEncode(item));
});

// READ (alle)
router.get('/items', (Request request) {
  // Items laden...
  return Response.ok(jsonEncode(items));
});

// READ (einzeln)
router.get('/items/<id>', (Request request, String id) {
  // Item laden...
  if (item == null) return Response.notFound('Not found');
  return Response.ok(jsonEncode(item));
});

// UPDATE
router.put('/items/<id>', (Request request, String id) async {
  final body = jsonDecode(await request.readAsString());
  // Item aktualisieren...
  return Response.ok(jsonEncode(updated));
});

// DELETE
router.delete('/items/<id>', (Request request, String id) {
  // Item löschen...
  return Response(204); // No Content
});
```

## Best Practices

### 1. Route-Organisation

```
lib/
├── routes/
│   ├── api_routes.dart
│   ├── user_routes.dart
│   └── product_routes.dart
├── controllers/
│   ├── user_controller.dart
│   └── product_controller.dart
└── main.dart
```

### 2. Konsistente Pfade

```dart
// GUT: Konsistent, plural, lowercase
/api/users
/api/users/123
/api/products
/api/products/456/reviews

// SCHLECHT: Inkonsistent
/api/User
/api/getUsers
/api/product_list
```

### 3. Versionierung

```dart
final app = Router();
app.mount('/api/v1', v1Router().call);
app.mount('/api/v2', v2Router().call);
```

### 4. 404-Handler

```dart
// Am Ende des Routers
router.all('/<path|.*>', (Request req, String path) {
  return Response.notFound(jsonEncode({
    'error': 'Not Found',
    'path': '/$path',
  }));
});
```

## Test-Befehle

```bash
# GET
curl http://localhost:8080/api/users
curl http://localhost:8080/api/users/42

# POST
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max"}'

# PUT
curl -X PUT http://localhost:8080/api/users/42 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated"}'

# DELETE
curl -X DELETE http://localhost:8080/api/users/42

# Query-Parameter
curl "http://localhost:8080/api/search?q=test&limit=5"
```

## Weiterführende Links

- [RESTful API Design](https://restfulapi.net/)
- [HTTP Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
- [URL Design Best Practices](https://blog.restcase.com/5-basic-rest-api-design-guidelines/)
