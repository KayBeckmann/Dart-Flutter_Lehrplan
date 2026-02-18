# Übung 6.4: CRUD-Operationen

## Ziel

Implementiere eine vollständige REST-API für eine Notizen-Anwendung.

---

## Aufgabe 1: Model & Repository (15 min)

Erstelle die Datenstrukturen für Notizen.

### Note Model

```dart
class Note {
  final String id;
  final String title;
  final String content;
  final String? category;
  final List<String> tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Constructor, fromJson, toJson, copyWith implementieren
}
```

### Repository Interface

```dart
class NoteRepository {
  // In-Memory Storage
  final _notes = <String, Note>{};

  List<Note> findAll();
  Note? findById(String id);
  Note create({required String title, required String content, String? category, List<String> tags});
  Note? update(String id, {String? title, String? content, String? category, List<String>? tags, bool? pinned});
  bool delete(String id);
}
```

---

## Aufgabe 2: CREATE Endpoint (10 min)

Implementiere den POST-Endpoint für neue Notizen.

### Anforderungen

- POST `/api/notes`
- `title` und `content` sind Pflichtfelder
- `category` und `tags` sind optional
- `pinned` default: false
- Status 201 mit Location-Header bei Erfolg
- Status 400 bei fehlenden Pflichtfeldern

### Request Body

```json
{
  "title": "Meeting Notes",
  "content": "Agenda: ...",
  "category": "work",
  "tags": ["meeting", "important"]
}
```

### Response (201)

```json
{
  "id": "note-1",
  "title": "Meeting Notes",
  "content": "Agenda: ...",
  "category": "work",
  "tags": ["meeting", "important"],
  "pinned": false,
  "createdAt": "2024-01-15T10:00:00Z"
}
```

---

## Aufgabe 3: READ Endpoints (15 min)

Implementiere die GET-Endpoints.

### Liste aller Notizen

- GET `/api/notes`
- Optional: Filter per Query-Parameter
  - `?category=work` - Nach Kategorie filtern
  - `?pinned=true` - Nur gepinnte Notizen
  - `?tag=meeting` - Nach Tag filtern

### Response

```json
{
  "data": [
    {"id": "note-1", "title": "Meeting Notes", ...},
    {"id": "note-2", "title": "Ideas", ...}
  ],
  "total": 2
}
```

### Einzelne Notiz

- GET `/api/notes/:id`
- Status 404 wenn nicht gefunden

---

## Aufgabe 4: UPDATE Endpoints (15 min)

Implementiere PUT und PATCH.

### PUT `/api/notes/:id` (Replace)

- Ersetzt die komplette Notiz
- `title` und `content` sind Pflicht
- Andere Felder werden auf Default zurückgesetzt wenn nicht angegeben

### PATCH `/api/notes/:id` (Partial Update)

- Aktualisiert nur die angegebenen Felder
- Perfekt für "Pin/Unpin":

```bash
curl -X PATCH http://localhost:8080/api/notes/1 \
  -H "Content-Type: application/json" \
  -d '{"pinned": true}'
```

### Unterschied demonstrieren

```bash
# Original: {"title": "Test", "content": "Hello", "category": "work", "pinned": false}

# PUT ohne category:
# → {"title": "New", "content": "World", "category": null, "pinned": false}

# PATCH mit nur pinned:
# → {"title": "Test", "content": "Hello", "category": "work", "pinned": true}
```

---

## Aufgabe 5: DELETE Endpoint (5 min)

Implementiere den DELETE-Endpoint.

### DELETE `/api/notes/:id`

- Status 204 (No Content) bei Erfolg
- Status 404 wenn nicht gefunden

---

## Aufgabe 6: Sub-Ressourcen (Bonus, 15 min)

Erweitere die API um Kommentare zu Notizen.

### Comment Model

```dart
class Comment {
  final String id;
  final String noteId;
  final String author;
  final String text;
  final DateTime createdAt;
}
```

### Endpoints

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | /api/notes/:noteId/comments | Alle Kommentare einer Notiz |
| POST | /api/notes/:noteId/comments | Kommentar hinzufügen |
| DELETE | /api/notes/:noteId/comments/:commentId | Kommentar löschen |

---

## Vollständige API-Übersicht

| Methode | Pfad | Beschreibung | Status |
|---------|------|--------------|--------|
| GET | /api/notes | Alle Notizen | 200 |
| GET | /api/notes/:id | Eine Notiz | 200/404 |
| POST | /api/notes | Notiz erstellen | 201/400 |
| PUT | /api/notes/:id | Notiz ersetzen | 200/400/404 |
| PATCH | /api/notes/:id | Notiz aktualisieren | 200/404 |
| DELETE | /api/notes/:id | Notiz löschen | 204/404 |

---

## Testen

```bash
# CREATE
curl -X POST http://localhost:8080/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "content": "Hello World"}'

# READ ALL
curl http://localhost:8080/api/notes

# READ ONE
curl http://localhost:8080/api/notes/note-1

# UPDATE (PATCH)
curl -X PATCH http://localhost:8080/api/notes/note-1 \
  -H "Content-Type: application/json" \
  -d '{"pinned": true}'

# UPDATE (PUT)
curl -X PUT http://localhost:8080/api/notes/note-1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated", "content": "New content"}'

# DELETE
curl -X DELETE http://localhost:8080/api/notes/note-1

# FILTER
curl "http://localhost:8080/api/notes?pinned=true"
curl "http://localhost:8080/api/notes?category=work"
```

---

## Abgabe-Checkliste

- [ ] Note Model mit allen Feldern
- [ ] NoteRepository mit allen Methoden
- [ ] POST /api/notes funktioniert (201 + Location)
- [ ] GET /api/notes listet alle Notizen
- [ ] GET /api/notes/:id gibt einzelne Notiz zurück
- [ ] PUT /api/notes/:id ersetzt komplett
- [ ] PATCH /api/notes/:id aktualisiert teilweise
- [ ] DELETE /api/notes/:id löscht (204)
- [ ] 404 bei nicht existierenden Notizen
- [ ] 400 bei fehlenden Pflichtfeldern
- [ ] (Bonus) Filtering per Query-Parameter
- [ ] (Bonus) Comment Sub-Ressourcen
