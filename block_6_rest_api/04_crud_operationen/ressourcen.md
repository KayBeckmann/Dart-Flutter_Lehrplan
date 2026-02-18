# Ressourcen: CRUD-Operationen

## Offizielle Dokumentation

- [HTTP Request Methods](https://developer.mozilla.org/en-US/docs/Web/HTTP/Methods)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [REST API Design](https://restfulapi.net/)

## Cheat Sheet: HTTP Methoden

| Methode | Verwendung | Body? | Idempotent? |
|---------|------------|-------|-------------|
| GET | Lesen | Nein | Ja |
| POST | Erstellen | Ja | Nein |
| PUT | Ersetzen | Ja | Ja |
| PATCH | Teilupdate | Ja | Meistens |
| DELETE | Löschen | Nein | Ja |

## Cheat Sheet: CRUD Mapping

```dart
// CREATE
router.post('/api/items', createItem);
// → 201 Created + Location Header

// READ (all)
router.get('/api/items', listItems);
// → 200 OK

// READ (one)
router.get('/api/items/<id>', getItem);
// → 200 OK oder 404 Not Found

// UPDATE (replace)
router.put('/api/items/<id>', replaceItem);
// → 200 OK oder 404 Not Found

// UPDATE (partial)
router.patch('/api/items/<id>', updateItem);
// → 200 OK oder 404 Not Found

// DELETE
router.delete('/api/items/<id>', deleteItem);
// → 204 No Content oder 404 Not Found
```

## Cheat Sheet: Response Helper

```dart
Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Response notFound(String message) {
  return jsonResponse({'error': message}, statusCode: 404);
}

Response badRequest(String message) {
  return jsonResponse({'error': message}, statusCode: 400);
}

Response created(Object data, String location) {
  return Response(201,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json',
      'location': location,
    },
  );
}

Response noContent() => Response(204);
```

## Cheat Sheet: Model mit copyWith

```dart
class Item {
  final String id;
  final String name;
  final double price;
  final bool active;

  Item({
    required this.id,
    required this.name,
    required this.price,
    this.active = true,
  });

  // Für PATCH: nur angegebene Felder ändern
  Item copyWith({
    String? name,
    double? price,
    bool? active,
  }) => Item(
    id: id,  // ID bleibt immer gleich
    name: name ?? this.name,
    price: price ?? this.price,
    active: active ?? this.active,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'active': active,
  };
}
```

## Cheat Sheet: Repository Pattern

```dart
abstract class Repository<T> {
  List<T> findAll();
  T? findById(String id);
  T create(T item);
  T? update(String id, T item);
  bool delete(String id);
}

class InMemoryRepository<T> implements Repository<T> {
  final _items = <String, T>{};

  @override
  List<T> findAll() => _items.values.toList();

  @override
  T? findById(String id) => _items[id];

  @override
  T create(T item) {
    // ID-Generierung hier oder im Aufrufer
    _items[item.id] = item;
    return item;
  }

  @override
  T? update(String id, T item) {
    if (!_items.containsKey(id)) return null;
    _items[id] = item;
    return item;
  }

  @override
  bool delete(String id) => _items.remove(id) != null;
}
```

## Cheat Sheet: PUT vs PATCH

```dart
// PUT: Komplett ersetzen (alle Felder nötig)
Future<Response> replaceItem(Request request, String id) async {
  final body = request.json;

  // Validierung: alle Felder müssen da sein
  if (body['name'] == null || body['price'] == null) {
    return badRequest('name and price are required');
  }

  // Komplett neues Objekt erstellen
  final item = Item(
    id: id,
    name: body['name'],
    price: body['price'],
    active: body['active'] ?? true,  // Default wenn nicht angegeben
  );

  return jsonResponse(repo.update(id, item)!.toJson());
}

// PATCH: Teilweise aktualisieren (nur angegebene Felder)
Future<Response> updateItem(Request request, String id) async {
  final existing = repo.findById(id);
  if (existing == null) return notFound('Item not found');

  final body = request.json;

  // Nur angegebene Felder überschreiben
  final updated = existing.copyWith(
    name: body['name'],
    price: body['price'],
    active: body['active'],
  );

  return jsonResponse(repo.update(id, updated)!.toJson());
}
```

## HTTP Statuscodes

### Erfolg (2xx)

| Code | Name | Verwendung |
|------|------|------------|
| 200 | OK | Erfolgreiche GET/PUT/PATCH |
| 201 | Created | Erfolgreiche POST |
| 204 | No Content | Erfolgreiche DELETE |

### Client-Fehler (4xx)

| Code | Name | Verwendung |
|------|------|------------|
| 400 | Bad Request | Ungültige Daten |
| 404 | Not Found | Ressource existiert nicht |
| 409 | Conflict | Konflikt (z.B. Duplikat) |
| 422 | Unprocessable Entity | Semantischer Fehler |

### Server-Fehler (5xx)

| Code | Name | Verwendung |
|------|------|------------|
| 500 | Internal Server Error | Unerwarteter Fehler |
| 503 | Service Unavailable | Server überlastet |

## Test-Befehle

```bash
# CREATE
curl -X POST http://localhost:8080/api/items \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "price": 9.99}'

# READ (all)
curl http://localhost:8080/api/items

# READ (one)
curl http://localhost:8080/api/items/1

# UPDATE (PUT - replace)
curl -X PUT http://localhost:8080/api/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Updated", "price": 19.99, "active": true}'

# UPDATE (PATCH - partial)
curl -X PATCH http://localhost:8080/api/items/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 14.99}'

# DELETE
curl -X DELETE http://localhost:8080/api/items/1

# DELETE mit Response-Code anzeigen
curl -X DELETE http://localhost:8080/api/items/1 -w "\n%{http_code}\n"
```

## Best Practices

1. **Konsistente URL-Struktur**
   - Plural für Collections: `/api/users`
   - ID für einzelne Ressourcen: `/api/users/:id`

2. **Korrekte Statuscodes**
   - Nicht 200 für alles
   - 201 bei Erstellung
   - 204 bei Löschung

3. **Location-Header bei POST**
   - URL der neuen Ressource zurückgeben

4. **Idempotenz beachten**
   - PUT/DELETE sollten idempotent sein

5. **Konsistente Fehler-Responses**
   - Immer JSON zurückgeben
   - Aussagekräftige Fehlermeldungen
