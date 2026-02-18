# Lösung 5.3: Routing mit shelf_router

## Vollständige Lösung

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// "Datenbank"
// ============================================

final _books = <String, Map<String, dynamic>>{};
var _bookId = 1;

final _reviews = <String, List<Map<String, dynamic>>>{};
var _reviewId = 1;

void main() async {
  // Testdaten einfügen
  _seedData();

  // Router aufbauen
  final app = Router();

  // Health & API Info
  app.get('/health', _healthHandler);
  app.get('/api', _apiInfoHandler);

  // Book Routes
  app.mount('/api/books', bookRouter().call);

  // 404 Handler (muss am Ende stehen!)
  app.all('/<path|.*>', _notFoundHandler);

  // Pipeline mit Logging
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
}

void _seedData() {
  _books['1'] = {
    'id': '1',
    'title': 'Clean Code',
    'author': 'Robert C. Martin',
    'year': 2008,
    'isbn': '978-0132350884',
  };
  _books['2'] = {
    'id': '2',
    'title': 'The Pragmatic Programmer',
    'author': 'David Thomas',
    'year': 2019,
    'isbn': '978-0135957059',
  };
  _bookId = 3;
}

// ============================================
// Aufgabe 4: Book Router (Sub-Router)
// ============================================

Router bookRouter() {
  final router = Router();

  // CRUD
  router.get('/', _listBooks);
  router.get('/<id>', _getBook);
  router.post('/', _createBook);
  router.put('/<id>', _updateBook);
  router.delete('/<id>', _deleteBook);

  // Bonus: Reviews
  router.get('/<bookId>/reviews', _listReviews);
  router.post('/<bookId>/reviews', _createReview);
  router.delete('/<bookId>/reviews/<reviewId>', _deleteReview);

  return router;
}

// ============================================
// Aufgabe 2 & 3: Book CRUD mit Filter
// ============================================

Response _listBooks(Request request) {
  final params = request.url.queryParameters;

  // Filter-Parameter
  final author = params['author']?.toLowerCase();
  final year = int.tryParse(params['year'] ?? '');
  final query = params['q']?.toLowerCase();
  final limit = int.tryParse(params['limit'] ?? '') ?? 100;
  final offset = int.tryParse(params['offset'] ?? '') ?? 0;

  // Filtern
  var results = _books.values.where((book) {
    if (author != null) {
      final bookAuthor = (book['author'] as String).toLowerCase();
      if (!bookAuthor.contains(author)) return false;
    }
    if (year != null && book['year'] != year) return false;
    if (query != null) {
      final title = (book['title'] as String).toLowerCase();
      if (!title.contains(query)) return false;
    }
    return true;
  }).toList();

  final total = results.length;

  // Pagination
  if (offset > 0) {
    results = results.skip(offset).toList();
  }
  if (limit > 0) {
    results = results.take(limit).toList();
  }

  return jsonResponse({
    'books': results,
    'total': total,
    'limit': limit,
    'offset': offset,
    'hasMore': offset + results.length < total,
  });
}

Response _getBook(Request request, String id) {
  final book = _books[id];
  if (book == null) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }
  return jsonResponse(book);
}

Future<Response> _createBook(Request request) async {
  try {
    final body = jsonDecode(await request.readAsString());

    // Validierung
    if (body['title'] == null || body['author'] == null) {
      return jsonResponse(
        {'error': 'Missing required fields: title, author'},
        statusCode: 400,
      );
    }

    final id = '${_bookId++}';
    final book = {
      'id': id,
      'title': body['title'],
      'author': body['author'],
      'year': body['year'],
      'isbn': body['isbn'],
    };

    _books[id] = book;
    return jsonResponse(book, statusCode: 201);
  } catch (e) {
    return jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
  }
}

Future<Response> _updateBook(Request request, String id) async {
  if (!_books.containsKey(id)) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }

  try {
    final body = jsonDecode(await request.readAsString());

    _books[id] = {
      ..._books[id]!,
      if (body['title'] != null) 'title': body['title'],
      if (body['author'] != null) 'author': body['author'],
      if (body['year'] != null) 'year': body['year'],
      if (body['isbn'] != null) 'isbn': body['isbn'],
      'id': id, // ID nicht überschreiben
    };

    return jsonResponse(_books[id]);
  } catch (e) {
    return jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
  }
}

Response _deleteBook(Request request, String id) {
  if (!_books.containsKey(id)) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }

  _books.remove(id);
  _reviews.remove(id); // Reviews auch löschen
  return Response(204);
}

// ============================================
// Bonus: Reviews
// ============================================

Response _listReviews(Request request, String bookId) {
  if (!_books.containsKey(bookId)) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }

  final reviews = _reviews[bookId] ?? [];
  return jsonResponse({
    'bookId': bookId,
    'reviews': reviews,
    'count': reviews.length,
  });
}

Future<Response> _createReview(Request request, String bookId) async {
  if (!_books.containsKey(bookId)) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }

  try {
    final body = jsonDecode(await request.readAsString());

    if (body['rating'] == null) {
      return jsonResponse(
        {'error': 'Missing required field: rating'},
        statusCode: 400,
      );
    }

    final rating = body['rating'] as int;
    if (rating < 1 || rating > 5) {
      return jsonResponse(
        {'error': 'Rating must be between 1 and 5'},
        statusCode: 400,
      );
    }

    final id = '${_reviewId++}';
    final review = {
      'id': id,
      'bookId': bookId,
      'rating': rating,
      'comment': body['comment'] ?? '',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    _reviews.putIfAbsent(bookId, () => []);
    _reviews[bookId]!.add(review);

    return jsonResponse(review, statusCode: 201);
  } catch (e) {
    return jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
  }
}

Response _deleteReview(Request request, String bookId, String reviewId) {
  if (!_books.containsKey(bookId)) {
    return jsonResponse({'error': 'Book not found'}, statusCode: 404);
  }

  final reviews = _reviews[bookId];
  if (reviews == null) {
    return jsonResponse({'error': 'Review not found'}, statusCode: 404);
  }

  final index = reviews.indexWhere((r) => r['id'] == reviewId);
  if (index == -1) {
    return jsonResponse({'error': 'Review not found'}, statusCode: 404);
  }

  reviews.removeAt(index);
  return Response(204);
}

// ============================================
// Aufgabe 5: Health, API Info, 404
// ============================================

Response _healthHandler(Request request) {
  return jsonResponse({
    'status': 'ok',
    'timestamp': DateTime.now().toUtc().toIso8601String(),
  });
}

Response _apiInfoHandler(Request request) {
  return jsonResponse({
    'name': 'Book API',
    'version': '1.0.0',
    'endpoints': [
      'GET /api/books',
      'GET /api/books/:id',
      'POST /api/books',
      'PUT /api/books/:id',
      'DELETE /api/books/:id',
      'GET /api/books/:bookId/reviews',
      'POST /api/books/:bookId/reviews',
      'DELETE /api/books/:bookId/reviews/:reviewId',
    ],
  });
}

Response _notFoundHandler(Request request, String path) {
  return jsonResponse({
    'error': 'Not Found',
    'path': '/$path',
    'method': request.method,
  }, statusCode: 404);
}

// ============================================
// Helper
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# === Books CRUD ===

# Alle Bücher
curl http://localhost:8080/api/books

# Ein Buch
curl http://localhost:8080/api/books/1

# Neues Buch
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{"title": "Design Patterns", "author": "Gang of Four", "year": 1994}'

# Buch aktualisieren
curl -X PUT http://localhost:8080/api/books/1 \
  -H "Content-Type: application/json" \
  -d '{"title": "Clean Code (Updated)"}'

# Buch löschen
curl -X DELETE http://localhost:8080/api/books/3

# === Filter ===

# Nach Autor
curl "http://localhost:8080/api/books?author=martin"

# Nach Jahr
curl "http://localhost:8080/api/books?year=2019"

# Volltextsuche
curl "http://localhost:8080/api/books?q=code"

# Pagination
curl "http://localhost:8080/api/books?limit=1&offset=0"
curl "http://localhost:8080/api/books?limit=1&offset=1"

# Kombiniert
curl "http://localhost:8080/api/books?author=martin&limit=5"

# === Reviews (Bonus) ===

# Reviews eines Buchs
curl http://localhost:8080/api/books/1/reviews

# Review erstellen
curl -X POST http://localhost:8080/api/books/1/reviews \
  -H "Content-Type: application/json" \
  -d '{"rating": 5, "comment": "Excellent book!"}'

curl -X POST http://localhost:8080/api/books/1/reviews \
  -H "Content-Type: application/json" \
  -d '{"rating": 4, "comment": "Very good"}'

# Reviews auflisten
curl http://localhost:8080/api/books/1/reviews

# Review löschen
curl -X DELETE http://localhost:8080/api/books/1/reviews/1

# === Health & Info ===

curl http://localhost:8080/health
curl http://localhost:8080/api

# === 404 ===

curl http://localhost:8080/not/found
curl -X POST http://localhost:8080/api/unknown

# === Fehler testen ===

# Ungültiges JSON
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d 'invalid json'

# Pflichtfelder fehlen
curl -X POST http://localhost:8080/api/books \
  -H "Content-Type: application/json" \
  -d '{}'

# Ungültiges Rating
curl -X POST http://localhost:8080/api/books/1/reviews \
  -H "Content-Type: application/json" \
  -d '{"rating": 10}'
```

---

## Beispiel-Ausgaben

```bash
$ curl http://localhost:8080/api/books
{
  "books": [
    {"id": "1", "title": "Clean Code", "author": "Robert C. Martin", "year": 2008, "isbn": "978-0132350884"},
    {"id": "2", "title": "The Pragmatic Programmer", "author": "David Thomas", "year": 2019, "isbn": "978-0135957059"}
  ],
  "total": 2,
  "limit": 100,
  "offset": 0,
  "hasMore": false
}

$ curl "http://localhost:8080/api/books?author=martin"
{
  "books": [
    {"id": "1", "title": "Clean Code", "author": "Robert C. Martin", "year": 2008, "isbn": "978-0132350884"}
  ],
  "total": 1,
  "limit": 100,
  "offset": 0,
  "hasMore": false
}

$ curl http://localhost:8080/api/books/99
{"error": "Book not found"}

$ curl http://localhost:8080/health
{"status": "ok", "timestamp": "2024-01-15T14:30:00.000Z"}
```

---

## Wichtige Erkenntnisse

### 1. Pfade im Sub-Router

Im `bookRouter()` sind die Pfade RELATIV zum Mount-Point:

```dart
// Im bookRouter():
router.get('/', ...);      // wird zu: /api/books
router.get('/<id>', ...);  // wird zu: /api/books/42
```

### 2. 404-Handler Position

Der 404-Handler MUSS am Ende stehen, weil shelf_router die erste passende Route nimmt:

```dart
// RICHTIG
app.get('/health', ...);
app.mount('/api/books', ...);
app.all('/<path|.*>', _notFound);  // Am Ende!

// FALSCH
app.all('/<path|.*>', _notFound);  // Fängt ALLES ab!
app.get('/health', ...);           // Wird nie erreicht
```

### 3. Mehrere URL-Parameter

Bei verschachtelten Ressourcen werden alle Parameter übergeben:

```dart
router.delete('/<bookId>/reviews/<reviewId>',
    (Request request, String bookId, String reviewId) {
  // Beide Parameter verfügbar
});
```

### 4. Filter-Logik

Die Filter werden mit `where()` kombiniert:

```dart
var results = _books.values.where((book) {
  if (author != null && !book['author'].contains(author)) return false;
  if (year != null && book['year'] != year) return false;
  return true;  // Alle Filter bestanden
});
```
