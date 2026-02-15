# Lösung 3.4: HTTP Requests

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   └── post.dart
├── services/
│   └── post_service.dart
└── pages/
    ├── posts_page.dart
    └── post_detail_page.dart
```

---

## models/post.dart

```dart
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;

  Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      userId: json['userId'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
    };
  }

  Post copyWith({
    int? id,
    int? userId,
    String? title,
    String? body,
  }) {
    return Post(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }
}
```

---

## services/post_service.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/post.dart';

class PostService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration timeout = Duration(seconds: 10);

  final http.Client _client;

  PostService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Post>> fetchPosts({int? userId}) async {
    try {
      final uri = userId != null
          ? Uri.parse('$baseUrl/posts?userId=$userId')
          : Uri.parse('$baseUrl/posts');

      final response = await _client.get(uri).timeout(timeout);

      _checkResponse(response);

      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((json) => Post.fromJson(json)).toList();
    } on SocketException {
      throw NetworkException('Keine Internetverbindung');
    } on TimeoutException {
      throw NetworkException('Zeitüberschreitung - Server antwortet nicht');
    }
  }

  Future<Post> fetchPost(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/posts/$id');
      final response = await _client.get(uri).timeout(timeout);

      _checkResponse(response);

      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw NetworkException('Keine Internetverbindung');
    } on TimeoutException {
      throw NetworkException('Zeitüberschreitung');
    }
  }

  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/posts');
      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              'title': title,
              'body': body,
              'userId': userId,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 201) {
        throw ServerException(response.statusCode);
      }

      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw NetworkException('Keine Internetverbindung');
    } on TimeoutException {
      throw NetworkException('Zeitüberschreitung');
    }
  }

  Future<Post> updatePost(int id, {String? title, String? body}) async {
    try {
      final uri = Uri.parse('$baseUrl/posts/$id');
      final response = await _client
          .patch(
            uri,
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({
              if (title != null) 'title': title,
              if (body != null) 'body': body,
            }),
          )
          .timeout(timeout);

      _checkResponse(response);

      return Post.fromJson(jsonDecode(response.body));
    } on SocketException {
      throw NetworkException('Keine Internetverbindung');
    } on TimeoutException {
      throw NetworkException('Zeitüberschreitung');
    }
  }

  Future<void> deletePost(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/posts/$id');
      final response = await _client.delete(uri).timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException(response.statusCode);
      }
    } on SocketException {
      throw NetworkException('Keine Internetverbindung');
    } on TimeoutException {
      throw NetworkException('Zeitüberschreitung');
    }
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode == 200) return;

    switch (response.statusCode) {
      case 400:
        throw ServerException(400, message: 'Ungültige Anfrage');
      case 401:
        throw ServerException(401, message: 'Nicht autorisiert');
      case 404:
        throw ServerException(404, message: 'Nicht gefunden');
      case 500:
        throw ServerException(500, message: 'Server-Fehler');
      default:
        throw ServerException(response.statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}

// Custom Exceptions
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => message;
}

class ServerException implements Exception {
  final int statusCode;
  final String? message;

  ServerException(this.statusCode, {this.message});

  @override
  String toString() =>
      message ?? 'Server-Fehler (Status: $statusCode)';
}
```

---

## pages/posts_page.dart

```dart
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';
import 'post_detail_page.dart';

class PostsPage extends StatefulWidget {
  const PostsPage({super.key});

  @override
  State<PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {
  final PostService _postService = PostService();

  List<Post>? _posts;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _postService.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final posts = await _postService.fetchPosts();
      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } on ServerException catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unbekannter Fehler: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePost(Post post) async {
    try {
      await _postService.deletePost(post.id);

      setState(() {
        _posts?.removeWhere((p) => p.id == post.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post "${post.title}" gelöscht')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateDialog() async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neuer Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Inhalt'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      try {
        final newPost = await _postService.createPost(
          title: titleController.text,
          body: bodyController.text,
          userId: 1,
        );

        setState(() {
          _posts?.insert(0, newPost);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post erstellt')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPosts,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Lade Posts...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPosts,
                icon: const Icon(Icons.refresh),
                label: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts == null || _posts!.isEmpty) {
      return const Center(
        child: Text('Keine Posts vorhanden'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: _posts!.length,
        itemBuilder: (context, index) {
          final post = _posts![index];
          return _PostCard(
            post: post,
            onTap: () => _navigateToDetail(post),
            onDelete: () => _deletePost(post),
          );
        },
      ),
    );
  }

  void _navigateToDetail(Post post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(
          post: post,
          onUpdate: (updatedPost) {
            setState(() {
              final index = _posts?.indexWhere((p) => p.id == updatedPost.id);
              if (index != null && index != -1) {
                _posts![index] = updatedPost;
              }
            });
          },
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(post.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Post löschen?'),
            content: Text('Möchtest du "${post.title}" wirklich löschen?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Löschen'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text(
            post.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            post.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
```

---

## pages/post_detail_page.dart

```dart
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class PostDetailPage extends StatefulWidget {
  final Post post;
  final void Function(Post)? onUpdate;

  const PostDetailPage({
    super.key,
    required this.post,
    this.onUpdate,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  final PostService _postService = PostService();
  late Post _post;
  bool _isEditing = false;

  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _titleController = TextEditingController(text: _post.title);
    _bodyController = TextEditingController(text: _post.body);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _postService.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    try {
      final updatedPost = await _postService.updatePost(
        _post.id,
        title: _titleController.text,
        body: _bodyController.text,
      );

      setState(() {
        _post = _post.copyWith(
          title: _titleController.text,
          body: _bodyController.text,
        );
        _isEditing = false;
      });

      widget.onUpdate?.call(_post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post aktualisiert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Bearbeiten' : 'Post Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _titleController.text = _post.title;
                _bodyController.text = _post.body;
                setState(() => _isEditing = false);
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Post #${_post.id}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (_isEditing) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                ),
                maxLines: 10,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Speichern'),
                ),
              ),
            ] else ...[
              Text(
                _post.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                _post.body,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'pages/posts_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PostsPage(),
    );
  }
}
```

---

## Verständnisfragen - Antworten

### 1. Uri.parse() vs Uri.https()

- `Uri.parse()`: Parst einen kompletten URL-String
- `Uri.https()`: Konstruiert eine URL aus Teilen (Host, Path, Query-Parameter)

`Uri.https()` ist sicherer, da Query-Parameter automatisch URL-encoded werden.

### 2. Warum http.Client?

- Wiederverwendet TCP-Verbindungen (Connection Pooling)
- Effizienter bei mehreren Requests
- Ermöglicht sauberes Cleanup mit `close()`

### 3. Statuscode 201 vs 200

- **200 OK**: Allgemeiner Erfolg, Ressource zurückgegeben
- **201 Created**: Neue Ressource wurde erfolgreich erstellt

### 4. Warum `as http`?

Verhindert Namenskonflikte, z.B. wenn du auch ein `Response`-Objekt aus einem anderen Package hast. Mit `http.Response` ist klar, welches gemeint ist.

### 5. Was wenn close() fehlt?

- TCP-Verbindungen bleiben offen
- Ressourcen werden nicht freigegeben
- Bei vielen Requests: Memory Leaks und Connection-Limits
