# Lösung 6.4: CRUD-Operationen

## Vollständige Lösung

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Aufgabe 1: Models
// ============================================

class Note {
  final String id;
  final String title;
  final String content;
  final String? category;
  final List<String> tags;
  final bool pinned;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category,
    this.tags = const [],
    this.pinned = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String?,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      pinned: json['pinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': content,
    if (category != null) 'category': category,
    'tags': tags,
    'pinned': pinned,
    'createdAt': createdAt.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  Note copyWith({
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? pinned,
    DateTime? updatedAt,
  }) => Note(
    id: id,
    title: title ?? this.title,
    content: content ?? this.content,
    category: category ?? this.category,
    tags: tags ?? this.tags,
    pinned: pinned ?? this.pinned,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class Comment {
  final String id;
  final String noteId;
  final String author;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.noteId,
    required this.author,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'noteId': noteId,
    'author': author,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ============================================
// Aufgabe 1: Repository
// ============================================

class NoteRepository {
  final _notes = <String, Note>{};
  var _nextId = 1;

  String _generateId() => 'note-${_nextId++}';

  List<Note> findAll() => _notes.values.toList();

  Note? findById(String id) => _notes[id];

  Note create({
    required String title,
    required String content,
    String? category,
    List<String> tags = const [],
    bool pinned = false,
  }) {
    final id = _generateId();
    final note = Note(
      id: id,
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
      createdAt: DateTime.now().toUtc(),
    );
    _notes[id] = note;
    return note;
  }

  Note? update(
    String id, {
    String? title,
    String? content,
    String? category,
    List<String>? tags,
    bool? pinned,
  }) {
    final existing = _notes[id];
    if (existing == null) return null;

    final updated = existing.copyWith(
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
      updatedAt: DateTime.now().toUtc(),
    );
    _notes[id] = updated;
    return updated;
  }

  Note? replace(
    String id, {
    required String title,
    required String content,
    String? category,
    List<String> tags = const [],
    bool pinned = false,
  }) {
    final existing = _notes[id];
    if (existing == null) return null;

    final replaced = Note(
      id: id,
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
    _notes[id] = replaced;
    return replaced;
  }

  bool delete(String id) => _notes.remove(id) != null;
}

class CommentRepository {
  final _comments = <String, Comment>{};
  var _nextId = 1;

  String _generateId() => 'comment-${_nextId++}';

  List<Comment> findByNoteId(String noteId) =>
      _comments.values.where((c) => c.noteId == noteId).toList();

  Comment? findById(String id) => _comments[id];

  Comment create({
    required String noteId,
    required String author,
    required String text,
  }) {
    final id = _generateId();
    final comment = Comment(
      id: id,
      noteId: noteId,
      author: author,
      text: text,
      createdAt: DateTime.now().toUtc(),
    );
    _comments[id] = comment;
    return comment;
  }

  bool delete(String id) => _comments.remove(id) != null;
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

Response notFound(String message) =>
    jsonResponse({'error': message}, statusCode: 404);

Response badRequest(String message) =>
    jsonResponse({'error': message}, statusCode: 400);

Response created(Object data, String location) {
  return Response(201,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json',
      'location': location,
    },
  );
}

extension RequestJson on Request {
  Map<String, dynamic> get json {
    final body = context['body'];
    return body is Map<String, dynamic> ? body : {};
  }
}

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
        return handler(request.change(context: {...request.context, 'body': <String, dynamic>{}}));
      }
      try {
        final json = jsonDecode(body);
        return handler(request.change(context: {...request.context, 'body': json}));
      } on FormatException {
        return badRequest('Invalid JSON');
      }
    };
  };
}

// ============================================
// API Handlers
// ============================================

class NotesApi {
  final NoteRepository noteRepo;
  final CommentRepository commentRepo;

  NotesApi(this.noteRepo, this.commentRepo);

  // ========== Aufgabe 3: READ ==========

  Response listNotes(Request request) {
    var notes = noteRepo.findAll();

    // Filter: ?category=work
    final category = request.url.queryParameters['category'];
    if (category != null) {
      notes = notes.where((n) => n.category == category).toList();
    }

    // Filter: ?pinned=true
    final pinnedParam = request.url.queryParameters['pinned'];
    if (pinnedParam != null) {
      final pinned = pinnedParam == 'true';
      notes = notes.where((n) => n.pinned == pinned).toList();
    }

    // Filter: ?tag=meeting
    final tag = request.url.queryParameters['tag'];
    if (tag != null) {
      notes = notes.where((n) => n.tags.contains(tag)).toList();
    }

    return jsonResponse({
      'data': notes.map((n) => n.toJson()).toList(),
      'total': notes.length,
    });
  }

  Response getNote(Request request, String id) {
    final note = noteRepo.findById(id);
    if (note == null) {
      return notFound('Note not found');
    }
    return jsonResponse(note.toJson());
  }

  // ========== Aufgabe 2: CREATE ==========

  Response createNote(Request request) {
    final body = request.json;

    // Validierung
    final title = body['title'] as String?;
    final content = body['content'] as String?;

    if (title == null || title.isEmpty) {
      return badRequest('title is required');
    }
    if (content == null || content.isEmpty) {
      return badRequest('content is required');
    }

    final category = body['category'] as String?;
    final tags = (body['tags'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];
    final pinned = body['pinned'] as bool? ?? false;

    final note = noteRepo.create(
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
    );

    return created(note.toJson(), '/api/notes/${note.id}');
  }

  // ========== Aufgabe 4: UPDATE ==========

  Response replaceNote(Request request, String id) {
    if (noteRepo.findById(id) == null) {
      return notFound('Note not found');
    }

    final body = request.json;

    // PUT: Alle Pflichtfelder validieren
    final title = body['title'] as String?;
    final content = body['content'] as String?;

    if (title == null || title.isEmpty) {
      return badRequest('title is required');
    }
    if (content == null || content.isEmpty) {
      return badRequest('content is required');
    }

    final category = body['category'] as String?;
    final tags = (body['tags'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [];
    final pinned = body['pinned'] as bool? ?? false;

    final note = noteRepo.replace(
      id,
      title: title,
      content: content,
      category: category,
      tags: tags,
      pinned: pinned,
    );

    return jsonResponse(note!.toJson());
  }

  Response updateNote(Request request, String id) {
    if (noteRepo.findById(id) == null) {
      return notFound('Note not found');
    }

    final body = request.json;

    // PATCH: Nur angegebene Felder
    final tags = (body['tags'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList();

    final note = noteRepo.update(
      id,
      title: body['title'] as String?,
      content: body['content'] as String?,
      category: body['category'] as String?,
      tags: tags,
      pinned: body['pinned'] as bool?,
    );

    return jsonResponse(note!.toJson());
  }

  // ========== Aufgabe 5: DELETE ==========

  Response deleteNote(Request request, String id) {
    if (!noteRepo.delete(id)) {
      return notFound('Note not found');
    }
    return Response(204);
  }

  // ========== Aufgabe 6: Comments ==========

  Response listComments(Request request, String noteId) {
    if (noteRepo.findById(noteId) == null) {
      return notFound('Note not found');
    }

    final comments = commentRepo.findByNoteId(noteId);
    return jsonResponse({
      'data': comments.map((c) => c.toJson()).toList(),
      'total': comments.length,
    });
  }

  Response createComment(Request request, String noteId) {
    if (noteRepo.findById(noteId) == null) {
      return notFound('Note not found');
    }

    final body = request.json;

    final author = body['author'] as String?;
    final text = body['text'] as String?;

    if (author == null || author.isEmpty) {
      return badRequest('author is required');
    }
    if (text == null || text.isEmpty) {
      return badRequest('text is required');
    }

    final comment = commentRepo.create(
      noteId: noteId,
      author: author,
      text: text,
    );

    return created(comment.toJson(), '/api/notes/$noteId/comments/${comment.id}');
  }

  Response deleteComment(Request request, String noteId, String commentId) {
    if (noteRepo.findById(noteId) == null) {
      return notFound('Note not found');
    }

    final comment = commentRepo.findById(commentId);
    if (comment == null || comment.noteId != noteId) {
      return notFound('Comment not found');
    }

    commentRepo.delete(commentId);
    return Response(204);
  }
}

// ============================================
// Main
// ============================================

void main() async {
  final noteRepo = NoteRepository();
  final commentRepo = CommentRepository();
  final api = NotesApi(noteRepo, commentRepo);

  // Seed-Daten
  noteRepo.create(
    title: 'Welcome',
    content: 'This is your first note!',
    tags: ['welcome', 'getting-started'],
    pinned: true,
  );
  noteRepo.create(
    title: 'Meeting Notes',
    content: 'Agenda: ...',
    category: 'work',
    tags: ['meeting'],
  );

  final router = Router();

  // Notes CRUD
  router.get('/api/notes', api.listNotes);
  router.get('/api/notes/<id>', api.getNote);
  router.post('/api/notes', api.createNote);
  router.put('/api/notes/<id>', api.replaceNote);
  router.patch('/api/notes/<id>', api.updateNote);
  router.delete('/api/notes/<id>', api.deleteNote);

  // Comments (Sub-Ressource)
  router.get('/api/notes/<noteId>/comments', api.listComments);
  router.post('/api/notes/<noteId>/comments', api.createComment);
  router.delete('/api/notes/<noteId>/comments/<commentId>', api.deleteComment);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('');
  print('Endpoints:');
  print('  GET    /api/notes');
  print('  GET    /api/notes/:id');
  print('  POST   /api/notes');
  print('  PUT    /api/notes/:id');
  print('  PATCH  /api/notes/:id');
  print('  DELETE /api/notes/:id');
  print('  GET    /api/notes/:id/comments');
  print('  POST   /api/notes/:id/comments');
  print('  DELETE /api/notes/:id/comments/:commentId');
}
```

---

## Test-Befehle

```bash
# ========== CREATE ==========
curl -X POST http://localhost:8080/api/notes \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Note", "content": "Hello World", "tags": ["test"]}'

# ========== READ ALL ==========
curl http://localhost:8080/api/notes

# Mit Filter
curl "http://localhost:8080/api/notes?pinned=true"
curl "http://localhost:8080/api/notes?category=work"
curl "http://localhost:8080/api/notes?tag=meeting"

# ========== READ ONE ==========
curl http://localhost:8080/api/notes/note-1

# 404 Test
curl http://localhost:8080/api/notes/not-exists

# ========== UPDATE (PATCH) ==========
# Nur pinned ändern
curl -X PATCH http://localhost:8080/api/notes/note-1 \
  -H "Content-Type: application/json" \
  -d '{"pinned": false}'

# Nur title ändern
curl -X PATCH http://localhost:8080/api/notes/note-2 \
  -H "Content-Type: application/json" \
  -d '{"title": "Updated Meeting Notes"}'

# ========== UPDATE (PUT) ==========
# Komplett ersetzen (category wird null weil nicht angegeben!)
curl -X PUT http://localhost:8080/api/notes/note-2 \
  -H "Content-Type: application/json" \
  -d '{"title": "Replaced Note", "content": "New content"}'

# ========== DELETE ==========
curl -X DELETE http://localhost:8080/api/notes/note-3 -w "\nStatus: %{http_code}\n"

# ========== COMMENTS ==========
# Kommentar erstellen
curl -X POST http://localhost:8080/api/notes/note-1/comments \
  -H "Content-Type: application/json" \
  -d '{"author": "Max", "text": "Great note!"}'

# Kommentare auflisten
curl http://localhost:8080/api/notes/note-1/comments

# Kommentar löschen
curl -X DELETE http://localhost:8080/api/notes/note-1/comments/comment-1
```

---

## Ausgabe-Beispiele

### Liste aller Notizen (200)

```json
{
  "data": [
    {
      "id": "note-1",
      "title": "Welcome",
      "content": "This is your first note!",
      "tags": ["welcome", "getting-started"],
      "pinned": true,
      "createdAt": "2024-01-15T10:00:00.000Z"
    },
    {
      "id": "note-2",
      "title": "Meeting Notes",
      "content": "Agenda: ...",
      "category": "work",
      "tags": ["meeting"],
      "pinned": false,
      "createdAt": "2024-01-15T10:00:00.000Z"
    }
  ],
  "total": 2
}
```

### Notiz erstellt (201)

```json
{
  "id": "note-3",
  "title": "Test Note",
  "content": "Hello World",
  "tags": ["test"],
  "pinned": false,
  "createdAt": "2024-01-15T10:30:00.000Z"
}
```

### PUT vs PATCH Unterschied

```bash
# Original:
{"id": "note-2", "title": "Meeting", "content": "...", "category": "work", "pinned": false}

# Nach PATCH mit {"pinned": true}:
{"id": "note-2", "title": "Meeting", "content": "...", "category": "work", "pinned": true}
# → Nur pinned geändert

# Nach PUT mit {"title": "New", "content": "..."}:
{"id": "note-2", "title": "New", "content": "...", "pinned": false}
# → category ist weg (null), pinned auf default
```

---

## Wichtige Erkenntnisse

### Repository-Pattern

```dart
// Trennung von Datenzugriff und API-Logik
class NoteRepository {
  List<Note> findAll();
  Note? findById(String id);
  Note create(...);
  Note? update(...);
  bool delete(String id);
}

// API-Handler nutzt Repository
class NotesApi {
  final NoteRepository repo;
  // ...
}
```

### copyWith für PATCH

```dart
// Nur nicht-null Werte werden überschrieben
Note copyWith({
  String? title,
  String? content,
}) => Note(
  id: id,
  title: title ?? this.title,  // Behalte alten Wert wenn null
  content: content ?? this.content,
);
```

### Location-Header bei 201

```dart
Response created(Object data, String location) {
  return Response(201,
    body: jsonEncode(data),
    headers: {
      'content-type': 'application/json',
      'location': location,  // URL der neuen Ressource
    },
  );
}
```
