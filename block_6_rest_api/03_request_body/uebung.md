# Übung 6.3: Request Body Parsing

## Ziel

Implementiere einen Server, der verschiedene Request Bodies verarbeitet.

---

## Aufgabe 1: Einfacher JSON-Handler (15 min)

Erstelle einen Endpoint der einen neuen Task erstellt.

### Anforderungen

- POST `/api/tasks`
- Erwartet JSON-Body mit `title` (required) und `description` (optional)
- Gibt den erstellten Task mit generierter `id` zurück
- Status 201 bei Erfolg

### Beispiel Request

```bash
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Einkaufen", "description": "Milch und Brot"}'
```

### Erwartete Response

```json
{
  "id": "task-1",
  "title": "Einkaufen",
  "description": "Milch und Brot",
  "completed": false,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

---

## Aufgabe 2: Fehlerbehandlung (15 min)

Erweitere den Handler mit robuster Fehlerbehandlung.

### Zu behandelnde Fehler

1. **Kein JSON Content-Type** → 415 Unsupported Media Type
2. **Leerer Body** → 400 Bad Request
3. **Ungültiges JSON** → 400 Bad Request
4. **Fehlendes Pflichtfeld** → 400 Bad Request

### Fehler-Response Format

```json
{
  "error": {
    "code": "MISSING_FIELD",
    "message": "Required field 'title' is missing"
  }
}
```

### Test-Fälle

```bash
# Ohne Content-Type
curl -X POST http://localhost:8080/api/tasks -d '{"title": "Test"}'

# Leerer Body
curl -X POST http://localhost:8080/api/tasks -H "Content-Type: application/json"

# Ungültiges JSON
curl -X POST http://localhost:8080/api/tasks -H "Content-Type: application/json" -d '{invalid}'

# Fehlendes Pflichtfeld
curl -X POST http://localhost:8080/api/tasks -H "Content-Type: application/json" -d '{}'
```

---

## Aufgabe 3: Body Parser Middleware (15 min)

Erstelle eine wiederverwendbare Middleware für JSON Body Parsing.

### Anforderungen

- Parst JSON Body nur für POST, PUT, PATCH
- Speichert geparstes JSON in `request.context['body']`
- Gibt 400 bei ungültigem JSON zurück
- Ignoriert Requests ohne JSON Content-Type

### Verwendung

```dart
final handler = Pipeline()
    .addMiddleware(logRequests())
    .addMiddleware(jsonBodyParser())  // Deine Middleware
    .addHandler(router.call);

// Im Handler:
router.post('/tasks', (Request request) {
  final body = request.context['body'] as Map<String, dynamic>;
  final title = body['title'];
  // ...
});
```

---

## Aufgabe 4: Request Extension (10 min)

Erstelle eine Extension für einfacheren Zugriff auf den Body.

### Extension

```dart
extension RequestJsonBody on Request {
  /// Gibt den JSON Body zurück (oder leeres Map)
  Map<String, dynamic> get json => ???;

  /// Extrahiert ein Feld mit Typ-Sicherheit
  T? field<T>(String key) => ???;

  /// Extrahiert ein Pflichtfeld (wirft Exception wenn fehlt)
  String requireString(String key) => ???;
}
```

### Verwendung

```dart
router.post('/tasks', (Request request) {
  final title = request.requireString('title');
  final description = request.field<String>('description');
  final priority = request.field<int>('priority') ?? 0;
  // ...
});
```

---

## Aufgabe 5: Komplexer Body (15 min)

Implementiere einen Handler für verschachtelte JSON-Strukturen.

### Endpoint

POST `/api/orders` - Neue Bestellung erstellen

### Request Body

```json
{
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
}
```

### Anforderungen

- Alle Customer-Felder sind Pflicht (außer address.street ist optional)
- Items muss mindestens 1 Element haben
- Quantity muss > 0 sein
- Notes ist optional

### Response bei Erfolg (201)

```json
{
  "orderId": "order-123",
  "customer": { ... },
  "items": [ ... ],
  "itemCount": 3,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

---

## Bonus: Form Data Handler

Implementiere einen Login-Endpoint der Form-Daten akzeptiert.

### Endpoint

POST `/login`
Content-Type: `application/x-www-form-urlencoded`

### Body

```
username=max&password=secret123
```

### Response

```json
{
  "success": true,
  "message": "Welcome, max!"
}
```

---

## Testen

```dart
void main() async {
  final app = Router();

  // Deine Endpoints hier...

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
}
```

---

## Abgabe-Checkliste

- [ ] Task-Endpoint erstellt und getestet
- [ ] Alle Fehler werden korrekt behandelt
- [ ] JSON Body Parser Middleware funktioniert
- [ ] Request Extension implementiert
- [ ] Komplexer Order-Body wird validiert
- [ ] (Bonus) Form Data Login funktioniert
