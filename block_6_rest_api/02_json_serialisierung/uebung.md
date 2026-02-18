# Übung 6.2: JSON Serialisierung

## Ziel

Erstelle Model-Klassen mit JSON-Serialisierung für ein Blog-System.

---

## Aufgabe 1: Einfache Model-Klasse (15 min)

Erstelle eine `Author`-Klasse.

### JSON-Format

```json
{
  "id": "author-123",
  "name": "Max Mustermann",
  "email": "max@example.com",
  "bio": "Dart-Entwickler seit 2020",
  "avatar_url": "https://example.com/avatar.jpg"
}
```

### Anforderungen

- `id`, `name`, `email` sind Pflichtfelder
- `bio` und `avatarUrl` sind optional
- Beachte: JSON verwendet `snake_case`, Dart `camelCase`

---

## Aufgabe 2: Model mit DateTime (10 min)

Erstelle eine `Post`-Klasse für Blog-Artikel.

### JSON-Format

```json
{
  "id": "post-456",
  "title": "Einführung in Dart",
  "content": "Dart ist eine moderne Programmiersprache...",
  "author_id": "author-123",
  "published_at": "2024-01-15T10:30:00Z",
  "updated_at": "2024-01-16T14:00:00Z",
  "tags": ["dart", "programming", "tutorial"],
  "view_count": 1250
}
```

### Anforderungen

- `updatedAt` ist optional (kann null sein)
- `tags` ist eine Liste von Strings
- `viewCount` hat Default-Wert 0

---

## Aufgabe 3: Verschachtelte Objekte (15 min)

Erstelle eine `Comment`-Klasse und erweitere `Post`.

### Comment JSON

```json
{
  "id": "comment-789",
  "post_id": "post-456",
  "author": {
    "id": "author-999",
    "name": "Anna Schmidt",
    "email": "anna@example.com"
  },
  "content": "Toller Artikel!",
  "created_at": "2024-01-15T12:00:00Z"
}
```

### Post mit eingebettetem Author

```json
{
  "id": "post-456",
  "title": "Einführung in Dart",
  "author": {
    "id": "author-123",
    "name": "Max Mustermann",
    "email": "max@example.com"
  },
  "content": "...",
  "published_at": "2024-01-15T10:30:00Z"
}
```

Erstelle eine neue Klasse `PostWithAuthor` oder erweitere `Post`.

---

## Aufgabe 4: Listen von Objekten (10 min)

Erstelle eine Funktion zum Parsen einer API-Response.

### API-Response

```json
{
  "posts": [
    {"id": "1", "title": "Post 1", ...},
    {"id": "2", "title": "Post 2", ...}
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "per_page": 10
  }
}
```

### Funktion

```dart
class PostListResponse {
  final List<Post> posts;
  final int total;
  final int page;
  final int perPage;

  // fromJson implementieren
}
```

---

## Aufgabe 5: Enum-Serialisierung (10 min)

Füge einen Status zu Posts hinzu.

### Status-Enum

```dart
enum PostStatus { draft, published, archived }
```

### JSON

```json
{
  "id": "post-456",
  "title": "...",
  "status": "published"
}
```

---

## Bonus: json_serializable

Erstelle die Models mit `json_serializable` und Code-Generierung.

```dart
@JsonSerializable()
class Author {
  final String id;
  final String name;

  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;

  Author({required this.id, required this.name, this.avatarUrl});

  factory Author.fromJson(Map<String, dynamic> json) => _$AuthorFromJson(json);
  Map<String, dynamic> toJson() => _$AuthorToJson(this);
}
```

---

## Testen

```dart
void main() {
  // Author testen
  final authorJson = {
    'id': 'author-1',
    'name': 'Max',
    'email': 'max@example.com',
    'bio': 'Developer',
    'avatar_url': 'https://...',
  };

  final author = Author.fromJson(authorJson);
  print(author.name);
  print(jsonEncode(author.toJson()));

  // Post testen
  final postJson = {
    'id': 'post-1',
    'title': 'Hello',
    'content': 'World',
    'author_id': 'author-1',
    'published_at': '2024-01-15T10:00:00Z',
    'tags': ['dart', 'json'],
    'view_count': 100,
  };

  final post = Post.fromJson(postJson);
  print(post.title);
  print(post.tags);

  // Verschachtelt testen
  final commentJson = {
    'id': 'comment-1',
    'post_id': 'post-1',
    'author': {'id': 'a-1', 'name': 'Anna', 'email': 'a@b.com'},
    'content': 'Nice!',
    'created_at': '2024-01-15T12:00:00Z',
  };

  final comment = Comment.fromJson(commentJson);
  print(comment.author.name);
}
```

---

## Abgabe-Checkliste

- [ ] Author-Klasse mit fromJson/toJson
- [ ] Post-Klasse mit DateTime und Listen
- [ ] Comment-Klasse mit verschachteltem Author
- [ ] PostListResponse für API-Response
- [ ] PostStatus-Enum serialisiert
- [ ] (Bonus) json_serializable Setup
