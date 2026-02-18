# Lösung 6.2: JSON Serialisierung

## Vollständige Lösung

```dart
import 'dart:convert';

// ============================================
// Aufgabe 1: Author
// ============================================

class Author {
  final String id;
  final String name;
  final String email;
  final String? bio;
  final String? avatarUrl;

  Author({
    required this.id,
    required this.name,
    required this.email,
    this.bio,
    this.avatarUrl,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatar_url': avatarUrl,
    };
  }
}

// ============================================
// Aufgabe 2: Post mit DateTime
// ============================================

class Post {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int viewCount;
  final PostStatus status;

  Post({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.publishedAt,
    this.updatedAt,
    this.tags = const [],
    this.viewCount = 0,
    this.status = PostStatus.draft,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      publishedAt: DateTime.parse(json['published_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      viewCount: json['view_count'] as int? ?? 0,
      status: PostStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PostStatus.draft,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'published_at': publishedAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'tags': tags,
      'view_count': viewCount,
      'status': status.name,
    };
  }
}

// ============================================
// Aufgabe 5: PostStatus Enum
// ============================================

enum PostStatus { draft, published, archived }

// ============================================
// Aufgabe 3: Comment mit verschachteltem Author
// ============================================

class Comment {
  final String id;
  final String postId;
  final Author author;
  final String content;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.postId,
    required this.author,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'author': author.toJson(),
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// ============================================
// Post mit eingebettetem Author
// ============================================

class PostWithAuthor {
  final String id;
  final String title;
  final String content;
  final Author author;
  final DateTime publishedAt;
  final List<String> tags;

  PostWithAuthor({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.publishedAt,
    this.tags = const [],
  });

  factory PostWithAuthor.fromJson(Map<String, dynamic> json) {
    return PostWithAuthor(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      author: Author.fromJson(json['author'] as Map<String, dynamic>),
      publishedAt: DateTime.parse(json['published_at'] as String),
      tags: (json['tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author': author.toJson(),
      'published_at': publishedAt.toIso8601String(),
      'tags': tags,
    };
  }
}

// ============================================
// Aufgabe 4: API Response mit Liste
// ============================================

class PostListResponse {
  final List<Post> posts;
  final int total;
  final int page;
  final int perPage;

  PostListResponse({
    required this.posts,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory PostListResponse.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;

    return PostListResponse(
      posts: (json['posts'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: meta['total'] as int,
      page: meta['page'] as int,
      perPage: meta['per_page'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'posts': posts.map((p) => p.toJson()).toList(),
      'meta': {
        'total': total,
        'page': page,
        'per_page': perPage,
      },
    };
  }

  int get totalPages => (total / perPage).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;
}

// ============================================
// Test
// ============================================

void main() {
  // Author testen
  print('=== Author ===');
  final authorJson = {
    'id': 'author-1',
    'name': 'Max Mustermann',
    'email': 'max@example.com',
    'bio': 'Dart Developer',
    'avatar_url': 'https://example.com/avatar.jpg',
  };
  final author = Author.fromJson(authorJson);
  print('Name: ${author.name}');
  print('JSON: ${jsonEncode(author.toJson())}');

  // Post testen
  print('\n=== Post ===');
  final postJson = {
    'id': 'post-1',
    'title': 'Hello Dart',
    'content': 'Dart is awesome!',
    'author_id': 'author-1',
    'published_at': '2024-01-15T10:00:00Z',
    'tags': ['dart', 'tutorial'],
    'view_count': 100,
    'status': 'published',
  };
  final post = Post.fromJson(postJson);
  print('Title: ${post.title}');
  print('Tags: ${post.tags}');
  print('Status: ${post.status}');

  // Comment testen
  print('\n=== Comment ===');
  final commentJson = {
    'id': 'comment-1',
    'post_id': 'post-1',
    'author': {
      'id': 'author-2',
      'name': 'Anna',
      'email': 'anna@example.com',
    },
    'content': 'Great article!',
    'created_at': '2024-01-15T12:00:00Z',
  };
  final comment = Comment.fromJson(commentJson);
  print('Author: ${comment.author.name}');
  print('Content: ${comment.content}');

  // PostListResponse testen
  print('\n=== PostListResponse ===');
  final responseJson = {
    'posts': [postJson, postJson],
    'meta': {
      'total': 50,
      'page': 1,
      'per_page': 10,
    },
  };
  final response = PostListResponse.fromJson(responseJson);
  print('Posts: ${response.posts.length}');
  print('Total: ${response.total}');
  print('Has next: ${response.hasNextPage}');
}
```

---

## Ausgabe

```
=== Author ===
Name: Max Mustermann
JSON: {"id":"author-1","name":"Max Mustermann","email":"max@example.com","bio":"Dart Developer","avatar_url":"https://example.com/avatar.jpg"}

=== Post ===
Title: Hello Dart
Tags: [dart, tutorial]
Status: PostStatus.published

=== Comment ===
Author: Anna
Content: Great article!

=== PostListResponse ===
Posts: 2
Total: 50
Has next: true
```

---

## Wichtige Patterns

### snake_case ↔ camelCase

```dart
// JSON: avatar_url → Dart: avatarUrl
avatarUrl: json['avatar_url'] as String?,

// Dart: avatarUrl → JSON: avatar_url
'avatar_url': avatarUrl,
```

### Optionale Felder

```dart
// Nur wenn nicht null ausgeben
if (bio != null) 'bio': bio,
```

### Listen parsen

```dart
tags: (json['tags'] as List<dynamic>?)
    ?.map((e) => e as String)
    .toList() ?? [],
```

### Enum-Handling

```dart
// Parse mit Fallback
status: PostStatus.values.firstWhere(
  (e) => e.name == json['status'],
  orElse: () => PostStatus.draft,
),

// Serialize
'status': status.name,
```
