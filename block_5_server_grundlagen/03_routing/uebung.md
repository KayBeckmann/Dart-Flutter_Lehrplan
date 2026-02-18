# Übung 5.3: Routing mit shelf_router

## Ziel

Erstelle eine REST API für eine Bücherverwaltung mit shelf_router. Du implementierst CRUD-Operationen, URL-Parameter, Query-Parameter und Route-Gruppen.

---

## Aufgabe 1: Projekt-Setup (5 min)

1. Erstelle ein neues Projekt oder verwende das vorherige
2. Stelle sicher, dass `shelf_router` installiert ist:
   ```yaml
   dependencies:
     shelf: ^1.4.0
     shelf_router: ^1.1.0
   ```

3. Erstelle die Grundstruktur:
   ```dart
   import 'dart:convert';
   import 'package:shelf/shelf.dart';
   import 'package:shelf/shelf_io.dart' as shelf_io;
   import 'package:shelf_router/shelf_router.dart';

   void main() async {
     final app = Router();

     // Routes hier...

     await shelf_io.serve(app.call, 'localhost', 8080);
     print('Server: http://localhost:8080');
   }
   ```

---

## Aufgabe 2: Book CRUD API (25 min)

Implementiere eine vollständige CRUD-API für Bücher.

### Datenmodell

Verwende eine In-Memory Map als "Datenbank":

```dart
final _books = <String, Map<String, dynamic>>{};
var _nextId = 1;
```

Ein Buch hat folgende Felder:
- `id` (String)
- `title` (String)
- `author` (String)
- `year` (int)
- `isbn` (String, optional)

### Endpunkte

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | `/api/books` | Alle Bücher auflisten |
| GET | `/api/books/<id>` | Ein Buch abrufen |
| POST | `/api/books` | Neues Buch erstellen |
| PUT | `/api/books/<id>` | Buch aktualisieren |
| DELETE | `/api/books/<id>` | Buch löschen |

### Erwartete Responses

**GET /api/books**
```json
{
  "books": [
    {"id": "1", "title": "Clean Code", "author": "Robert C. Martin", "year": 2008}
  ],
  "total": 1
}
```

**GET /api/books/1**
```json
{"id": "1", "title": "Clean Code", "author": "Robert C. Martin", "year": 2008}
```

**POST /api/books** (Request-Body: `{"title": "...", "author": "...", "year": 2024}`)
- Status: 201 Created
- Response: Das erstellte Buch mit ID

**PUT /api/books/1**
- Status: 200 OK
- Response: Das aktualisierte Buch

**DELETE /api/books/1**
- Status: 204 No Content
- Response: Leer

**Fehlerfall: Buch nicht gefunden**
- Status: 404
- Response: `{"error": "Book not found"}`

---

## Aufgabe 3: Query-Parameter für Filterung (15 min)

Erweitere den `GET /api/books`-Endpunkt um Filterung.

### Parameter

| Parameter | Beschreibung | Beispiel |
|-----------|--------------|----------|
| `author` | Nach Autor filtern | `?author=Martin` |
| `year` | Nach Jahr filtern | `?year=2008` |
| `q` | Volltextsuche im Titel | `?q=clean` |
| `limit` | Max. Anzahl Ergebnisse | `?limit=10` |
| `offset` | Überspringen (Pagination) | `?offset=20` |

### Beispiele

```bash
# Alle Bücher von "Martin"
GET /api/books?author=Martin

# Bücher aus 2020
GET /api/books?year=2020

# Suche nach "code" im Titel
GET /api/books?q=code

# Pagination: Seite 2 mit 10 Einträgen
GET /api/books?limit=10&offset=10

# Kombiniert
GET /api/books?author=Martin&limit=5
```

### Response mit Pagination-Info

```json
{
  "books": [...],
  "total": 50,
  "limit": 10,
  "offset": 0,
  "hasMore": true
}
```

---

## Aufgabe 4: Route-Gruppen (10 min)

Extrahiere die Book-Routes in einen eigenen Sub-Router.

### Anforderungen

1. Erstelle eine Funktion `Router bookRouter()`
2. Mounte sie unter `/api/books`
3. Die Pfade im bookRouter sind dann relativ (ohne `/api/books` Prefix)

### Struktur

```dart
Router bookRouter() {
  final router = Router();

  router.get('/', _listBooks);          // GET /api/books
  router.get('/<id>', _getBook);        // GET /api/books/42
  router.post('/', _createBook);        // POST /api/books
  // ...

  return router;
}

void main() async {
  final app = Router();

  app.mount('/api/books', bookRouter().call);

  // Weitere Routes...
}
```

---

## Aufgabe 5: Zusätzliche Routes (5 min)

Füge folgende Endpunkte hinzu:

### Health Check

```
GET /health
Response: {"status": "ok", "timestamp": "..."}
```

### API Info

```
GET /api
Response: {
  "name": "Book API",
  "version": "1.0.0",
  "endpoints": [
    "GET /api/books",
    "GET /api/books/:id",
    "POST /api/books",
    "PUT /api/books/:id",
    "DELETE /api/books/:id"
  ]
}
```

### 404 Handler

Alle nicht gefundenen Routes sollen ein JSON-Error zurückgeben:

```json
{
  "error": "Not Found",
  "path": "/unknown/path",
  "method": "GET"
}
```

---

## Bonus: Nested Resource

Füge Reviews zu Büchern hinzu.

### Endpunkte

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | `/api/books/<bookId>/reviews` | Reviews eines Buchs |
| POST | `/api/books/<bookId>/reviews` | Review hinzufügen |
| DELETE | `/api/books/<bookId>/reviews/<reviewId>` | Review löschen |

### Datenmodell

```dart
final _reviews = <String, List<Map<String, dynamic>>>{};
// Key: bookId, Value: Liste von Reviews
```

Ein Review:
```json
{
  "id": "1",
  "bookId": "1",
  "rating": 5,
  "comment": "Excellent book!",
  "createdAt": "2024-01-15T..."
}
```

---

## Testen

```bash
# Books CRUD
curl http://localhost:8080/api/books
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Clean Code", "author": "Robert C. Martin", "year": 2008}'

curl http://localhost:8080/api/books/1
curl -X PUT http://localhost:8080/api/books/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Clean Code (Updated)", "author": "Robert C. Martin", "year": 2008}'

curl -X DELETE http://localhost:8080/api/books/1

# Filter
curl "http://localhost:8080/api/books?author=Martin"
curl "http://localhost:8080/api/books?q=code&limit=5"

# Health & Info
curl http://localhost:8080/health
curl http://localhost:8080/api

# 404
curl http://localhost:8080/not/found
```

---

## Abgabe-Checkliste

- [ ] Alle CRUD-Operationen funktionieren
- [ ] URL-Parameter werden korrekt extrahiert
- [ ] Query-Parameter für Filterung funktionieren
- [ ] Routes sind in Sub-Router organisiert
- [ ] Health und API-Info Endpunkte vorhanden
- [ ] 404-Handler gibt JSON zurück
- [ ] (Bonus) Nested Reviews funktionieren
