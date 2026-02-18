# Einheit 6.4: CRUD-Operationen

## Lernziele

Nach dieser Einheit kannst du:
- Alle CRUD-Operationen (Create, Read, Update, Delete) implementieren
- Die passenden HTTP-Methoden und Statuscodes verwenden
- Eine vollständige REST-API für eine Ressource erstellen
- PUT vs. PATCH korrekt einsetzen

---

## CRUD Übersicht

CRUD beschreibt die vier grundlegenden Operationen für persistente Daten:

| Operation | HTTP-Methode | Pfad | Beschreibung |
|-----------|--------------|------|--------------|
| **C**reate | POST | /items | Neue Ressource erstellen |
| **R**ead | GET | /items/:id | Eine Ressource lesen |
| **R**ead All | GET | /items | Alle Ressourcen listen |
| **U**pdate | PUT/PATCH | /items/:id | Ressource aktualisieren |
| **D**elete | DELETE | /items/:id | Ressource löschen |

---

## Projekt-Setup

### Model-Klasse

```dart
class Todo {
  final String id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    if (description != null) 'description': description,
    'completed': completed,
    'created_at': createdAt.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  Todo copyWith({
    String? title,
    String? description,
    bool? completed,
    DateTime? updatedAt,
  }) => Todo(
    id: id,
    title: title ?? this.title,
    description: description ?? this.description,
    completed: completed ?? this.completed,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
```

### In-Memory Storage

```dart
class TodoRepository {
  final _todos = <String, Todo>{};
  var _nextId = 1;

  String _generateId() => 'todo-${_nextId++}';

  List<Todo> findAll() => _todos.values.toList();

  Todo? findById(String id) => _todos[id];

  Todo create(String title, String? description) {
    final id = _generateId();
    final todo = Todo(
      id: id,
      title: title,
      description: description,
      createdAt: DateTime.now().toUtc(),
    );
    _todos[id] = todo;
    return todo;
  }

  Todo? update(String id, {String? title, String? description, bool? completed}) {
    final existing = _todos[id];
    if (existing == null) return null;

    final updated = existing.copyWith(
      title: title,
      description: description,
      completed: completed,
      updatedAt: DateTime.now().toUtc(),
    );
    _todos[id] = updated;
    return updated;
  }

  bool delete(String id) => _todos.remove(id) != null;
}
```

---

## CREATE (POST)

### Neue Ressource erstellen

```dart
final repo = TodoRepository();

Future<Response> createTodo(Request request) async {
  final body = request.json;

  // Validierung
  final title = body['title'] as String?;
  if (title == null || title.isEmpty) {
    return Response(400,
      body: jsonEncode({'error': 'title is required'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final description = body['description'] as String?;

  // Erstellen
  final todo = repo.create(title, description);

  // 201 Created mit Location-Header
  return Response(201,
    body: jsonEncode(todo.toJson()),
    headers: {
      'content-type': 'application/json',
      'location': '/api/todos/${todo.id}',
    },
  );
}
```

### Wichtige Punkte

- **Status 201 Created** bei Erfolg
- **Location-Header** mit URL der neuen Ressource
- Validierung der Pflichtfelder
- Generierte ID zurückgeben

---

## READ (GET)

### Einzelne Ressource lesen

```dart
Response getTodo(Request request, String id) {
  final todo = repo.findById(id);

  if (todo == null) {
    return Response(404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  return Response.ok(
    jsonEncode(todo.toJson()),
    headers: {'content-type': 'application/json'},
  );
}
```

### Alle Ressourcen listen

```dart
Response listTodos(Request request) {
  final todos = repo.findAll();

  return Response.ok(
    jsonEncode({
      'data': todos.map((t) => t.toJson()).toList(),
      'total': todos.length,
    }),
    headers: {'content-type': 'application/json'},
  );
}
```

### Mit Query-Parametern filtern

```dart
Response listTodos(Request request) {
  var todos = repo.findAll();

  // Filter: ?completed=true
  final completedParam = request.url.queryParameters['completed'];
  if (completedParam != null) {
    final completed = completedParam == 'true';
    todos = todos.where((t) => t.completed == completed).toList();
  }

  // Sortierung: ?sort=created_at&order=desc
  final sort = request.url.queryParameters['sort'];
  final order = request.url.queryParameters['order'] ?? 'asc';

  if (sort == 'created_at') {
    todos.sort((a, b) => order == 'desc'
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));
  } else if (sort == 'title') {
    todos.sort((a, b) => order == 'desc'
        ? b.title.compareTo(a.title)
        : a.title.compareTo(b.title));
  }

  return Response.ok(
    jsonEncode({
      'data': todos.map((t) => t.toJson()).toList(),
      'total': todos.length,
    }),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## UPDATE (PUT vs. PATCH)

### PUT - Vollständiges Ersetzen

PUT ersetzt die **gesamte** Ressource. Alle Felder müssen angegeben werden.

```dart
Future<Response> replaceTodo(Request request, String id) async {
  final existing = repo.findById(id);
  if (existing == null) {
    return Response(404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final body = request.json;

  // Bei PUT müssen alle Felder vorhanden sein
  final title = body['title'] as String?;
  if (title == null || title.isEmpty) {
    return Response(400,
      body: jsonEncode({'error': 'title is required'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // Alle Felder werden überschrieben (auch mit null/default)
  final updated = repo.update(
    id,
    title: title,
    description: body['description'] as String?,
    completed: body['completed'] as bool? ?? false,
  );

  return Response.ok(
    jsonEncode(updated!.toJson()),
    headers: {'content-type': 'application/json'},
  );
}
```

### PATCH - Teilweise Aktualisierung

PATCH aktualisiert nur die **angegebenen** Felder.

```dart
Future<Response> updateTodo(Request request, String id) async {
  final existing = repo.findById(id);
  if (existing == null) {
    return Response(404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  final body = request.json;

  // Nur übergebene Felder aktualisieren
  final updated = repo.update(
    id,
    title: body['title'] as String?,
    description: body['description'] as String?,
    completed: body['completed'] as bool?,
  );

  return Response.ok(
    jsonEncode(updated!.toJson()),
    headers: {'content-type': 'application/json'},
  );
}
```

### Unterschied PUT vs. PATCH

```
# Ursprünglicher Todo:
{
  "id": "1",
  "title": "Einkaufen",
  "description": "Milch und Brot",
  "completed": false
}

# PUT /todos/1 mit {"title": "Kochen", "completed": true}
# → description wird auf null gesetzt!
{
  "id": "1",
  "title": "Kochen",
  "description": null,
  "completed": true
}

# PATCH /todos/1 mit {"completed": true}
# → Nur completed wird geändert, Rest bleibt!
{
  "id": "1",
  "title": "Einkaufen",
  "description": "Milch und Brot",
  "completed": true
}
```

---

## DELETE

### Ressource löschen

```dart
Response deleteTodo(Request request, String id) {
  final deleted = repo.delete(id);

  if (!deleted) {
    return Response(404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // 204 No Content - Erfolg ohne Body
  return Response(204);
}
```

### Alternative: Soft Delete

```dart
Response softDeleteTodo(Request request, String id) {
  final existing = repo.findById(id);
  if (existing == null) {
    return Response(404,
      body: jsonEncode({'error': 'Todo not found'}),
      headers: {'content-type': 'application/json'},
    );
  }

  // Statt löschen: als gelöscht markieren
  repo.update(id, deletedAt: DateTime.now().toUtc());

  return Response(204);
}
```

---

## Vollständiger Router

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  final repo = TodoRepository();
  final api = TodoApi(repo);

  final router = Router();

  // CRUD Routen
  router.get('/api/todos', api.listTodos);
  router.get('/api/todos/<id>', api.getTodo);
  router.post('/api/todos', api.createTodo);
  router.put('/api/todos/<id>', api.replaceTodo);
  router.patch('/api/todos/<id>', api.updateTodo);
  router.delete('/api/todos/<id>', api.deleteTodo);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
}

class TodoApi {
  final TodoRepository repo;

  TodoApi(this.repo);

  Response listTodos(Request request) { /* ... */ }
  Response getTodo(Request request, String id) { /* ... */ }
  Future<Response> createTodo(Request request) async { /* ... */ }
  Future<Response> replaceTodo(Request request, String id) async { /* ... */ }
  Future<Response> updateTodo(Request request, String id) async { /* ... */ }
  Response deleteTodo(Request request, String id) { /* ... */ }
}
```

---

## HTTP Statuscodes Übersicht

| Operation | Erfolg | Nicht gefunden | Validierungsfehler |
|-----------|--------|----------------|-------------------|
| GET (one) | 200 OK | 404 Not Found | - |
| GET (all) | 200 OK | - | - |
| POST | 201 Created | - | 400 Bad Request |
| PUT | 200 OK | 404 Not Found | 400 Bad Request |
| PATCH | 200 OK | 404 Not Found | 400 Bad Request |
| DELETE | 204 No Content | 404 Not Found | - |

---

## Idempotenz

**Idempotent** bedeutet: Mehrfaches Ausführen hat das gleiche Ergebnis.

| Methode | Idempotent? | Erklärung |
|---------|-------------|-----------|
| GET | Ja | Liest nur, ändert nichts |
| PUT | Ja | Gleiches Ergebnis bei wiederholtem Aufruf |
| DELETE | Ja | Nach dem Löschen: 404 (aber Ressource bleibt gelöscht) |
| POST | **Nein** | Jeder Aufruf erstellt neue Ressource |
| PATCH | Meistens | Hängt von der Implementation ab |

---

## Zusammenfassung

| Operation | Methode | Pfad | Status |
|-----------|---------|------|--------|
| Create | POST | /api/todos | 201 + Location |
| Read One | GET | /api/todos/:id | 200 / 404 |
| Read All | GET | /api/todos | 200 |
| Replace | PUT | /api/todos/:id | 200 / 404 |
| Update | PATCH | /api/todos/:id | 200 / 404 |
| Delete | DELETE | /api/todos/:id | 204 / 404 |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Input-Validierung**: Wie du Eingabedaten systematisch prüfst und aussagekräftige Fehlermeldungen zurückgibst.
