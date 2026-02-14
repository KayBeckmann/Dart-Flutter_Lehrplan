# Modul 10: Loesung -- Benutzerverzeichnis-App

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   └── post.dart
├── repositories/
│   └── user_repository.dart
├── viewmodels/
│   └── user_viewmodel.dart
├── screens/
│   ├── user_list_screen.dart
│   └── user_detail_screen.dart
└── widgets/
    ├── user_card.dart
    ├── post_tile.dart
    └── error_view.dart
```

## pubspec.yaml (relevanter Ausschnitt)

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  provider: ^6.1.2
```

---

## models/user.dart

```dart
class Company {
  final String name;
  final String catchPhrase;

  const Company({
    required this.name,
    required this.catchPhrase,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['name'] as String,
      catchPhrase: json['catchPhrase'] as String,
    );
  }
}

class Address {
  final String street;
  final String suite;
  final String city;
  final String zipcode;

  const Address({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] as String,
      suite: json['suite'] as String,
      city: json['city'] as String,
      zipcode: json['zipcode'] as String,
    );
  }

  String get fullAddress => '$street, $suite, $zipcode $city';
}

class User {
  final int id;
  final String name;
  final String username;
  final String email;
  final String phone;
  final String website;
  final Company company;
  final Address address;

  const User({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.company,
    required this.address,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      company: Company.fromJson(json['company'] as Map<String, dynamic>),
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
    );
  }

  /// Initiale fuer den Avatar
  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
```

---

## models/post.dart

```dart
class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  const Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      userId: json['userId'] as int,
      id: json['id'] as int,
      title: json['title'] as String,
      body: json['body'] as String,
    );
  }
}
```

---

## repositories/user_repository.dart

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/post.dart';

/// Eigene Exception-Klasse fuer API-Fehler.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class UserRepository {
  final http.Client _client;
  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Duration _timeout = Duration(seconds: 10);

  UserRepository({http.Client? client}) : _client = client ?? http.Client();

  /// Laedt alle Benutzer.
  Future<List<User>> getUsers() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/users'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => User.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Fehler beim Laden der Benutzer (Status: ${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Keine Internetverbindung. Bitte pruefen und erneut versuchen.');
    } on TimeoutException {
      throw ApiException('Der Server antwortet nicht. Bitte spaeter erneut versuchen.');
    } on FormatException {
      throw ApiException('Die Serverantwort konnte nicht verarbeitet werden.');
    }
  }

  /// Laedt einen einzelnen Benutzer anhand seiner ID.
  Future<User> getUserById(int id) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/users/$id'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw ApiException('Benutzer nicht gefunden.', 404);
      } else {
        throw ApiException(
          'Fehler beim Laden des Benutzers (Status: ${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Keine Internetverbindung.');
    } on TimeoutException {
      throw ApiException('Zeitlimit ueberschritten.');
    } on FormatException {
      throw ApiException('Ungueltige Serverantwort.');
    }
  }

  /// Laedt alle Posts eines Benutzers.
  Future<List<Post>> getUserPosts(int userId) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/posts?userId=$userId'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Post.fromJson(json)).toList();
      } else {
        throw ApiException(
          'Fehler beim Laden der Posts (Status: ${response.statusCode})',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('Keine Internetverbindung.');
    } on TimeoutException {
      throw ApiException('Zeitlimit ueberschritten.');
    } on FormatException {
      throw ApiException('Ungueltige Serverantwort.');
    }
  }

  void dispose() {
    _client.close();
  }
}
```

---

## viewmodels/user_viewmodel.dart

```dart
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../repositories/user_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  // --- Benutzerliste ---
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  // --- Suche ---
  String _searchQuery = '';

  UserViewModel({required UserRepository repository})
      : _repository = repository;

  List<User> get users {
    if (_searchQuery.isEmpty) return List.unmodifiable(_users);
    return _users.where((user) {
      final query = _searchQuery.toLowerCase();
      return user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  int get userCount => _users.length;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await _repository.getUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUsers() async {
    // Beim Refresh keinen Ladeindikator zeigen (RefreshIndicator hat eigenen)
    try {
      _users = await _repository.getUsers();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  // --- Posts eines Benutzers ---

  List<Post> _currentUserPosts = [];
  bool _isLoadingPosts = false;
  String? _postsError;

  List<Post> get currentUserPosts => List.unmodifiable(_currentUserPosts);
  bool get isLoadingPosts => _isLoadingPosts;
  String? get postsError => _postsError;

  Future<void> loadUserPosts(int userId) async {
    _isLoadingPosts = true;
    _postsError = null;
    _currentUserPosts = [];
    notifyListeners();

    try {
      _currentUserPosts = await _repository.getUserPosts(userId);
    } catch (e) {
      _postsError = e.toString();
    } finally {
      _isLoadingPosts = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
```

---

## widgets/error_view.dart

```dart
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Etwas ist schiefgelaufen',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## widgets/user_card.dart

```dart
import 'package:flutter/material.dart';
import '../models/user.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Hero(
          tag: 'avatar_${user.id}',
          child: CircleAvatar(
            backgroundColor: Colors.primaries[user.id % Colors.primaries.length],
            child: Text(
              user.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              user.company.name,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
        onTap: onTap,
      ),
    );
  }
}
```

---

## widgets/post_tile.dart

```dart
import 'package:flutter/material.dart';
import '../models/post.dart';

class PostTile extends StatelessWidget {
  final Post post;

  const PostTile({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## screens/user_list_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/user_card.dart';
import '../widgets/error_view.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    // Daten laden nach dem ersten Build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().loadUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzerverzeichnis'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Benutzer suchen...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (query) {
                context.read<UserViewModel>().setSearchQuery(query);
              },
            ),
          ),
        ),
      ),
      body: Consumer<UserViewModel>(
        builder: (context, viewModel, _) {
          // Ladezustand
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Fehlerzustand
          if (viewModel.error != null) {
            return ErrorView(
              message: viewModel.error!,
              onRetry: () => context.read<UserViewModel>().loadUsers(),
            );
          }

          // Leere Liste
          if (viewModel.users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.searchQuery.isEmpty
                        ? 'Keine Benutzer vorhanden'
                        : 'Kein Benutzer gefunden fuer "${viewModel.searchQuery}"',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          // Benutzerliste mit Pull-to-Refresh
          return RefreshIndicator(
            onRefresh: () => context.read<UserViewModel>().refreshUsers(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: viewModel.users.length,
              itemBuilder: (context, index) {
                final user = viewModel.users[index];
                return UserCard(
                  user: user,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserDetailScreen(user: user),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## screens/user_detail_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../viewmodels/user_viewmodel.dart';
import '../widgets/post_tile.dart';
import '../widgets/error_view.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserViewModel>().loadUserPosts(widget.user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- App Bar mit Hero-Avatar ---
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(user.name),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.primaries[user.id % Colors.primaries.length],
                      Colors.primaries[user.id % Colors.primaries.length]
                          .withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'avatar_${user.id}',
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Text(
                        user.initials,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.primaries[
                              user.id % Colors.primaries.length],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Benutzerinformationen ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kontaktinformationen
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.person,
                          label: 'Username',
                          value: '@${user.username}',
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.email,
                          label: 'E-Mail',
                          value: user.email,
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.phone,
                          label: 'Telefon',
                          value: user.phone,
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.language,
                          label: 'Website',
                          value: user.website,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Firma
                  Card(
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.business,
                          label: 'Firma',
                          value: user.company.name,
                        ),
                        const Divider(height: 1),
                        _InfoTile(
                          icon: Icons.format_quote,
                          label: 'Slogan',
                          value: user.company.catchPhrase,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Adresse
                  Card(
                    child: _InfoTile(
                      icon: Icons.location_on,
                      label: 'Adresse',
                      value: user.address.fullAddress,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Posts-Ueberschrift
                  Text(
                    'Posts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // --- Posts ---
          Consumer<UserViewModel>(
            builder: (context, viewModel, _) {
              // Laden
              if (viewModel.isLoadingPosts) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              // Fehler
              if (viewModel.postsError != null) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(viewModel.postsError!),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => context
                              .read<UserViewModel>()
                              .loadUserPosts(user.id),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Erneut versuchen'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Keine Posts
              if (viewModel.currentUserPosts.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('Keine Posts vorhanden')),
                  ),
                );
              }

              // Posts anzeigen
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return PostTile(post: viewModel.currentUserPosts[index]);
                  },
                  childCount: viewModel.currentUserPosts.length,
                ),
              );
            },
          ),

          // Abstand unten
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(
        label,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(fontSize: 15),
      ),
    );
  }
}
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'repositories/user_repository.dart';
import 'viewmodels/user_viewmodel.dart';
import 'screens/user_list_screen.dart';

void main() {
  final userRepository = UserRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => UserViewModel(repository: userRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Benutzerverzeichnis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const UserListScreen(),
    );
  }
}
```

---

## Erklaerung der Loesung

### Architektur

```
UI (Screens/Widgets)
        |
        | context.read / context.watch / Consumer
        v
ViewModel (UserViewModel -- ChangeNotifier)
        |
        | Methodenaufrufe
        v
Repository (UserRepository)
        |
        | http.get()
        v
API (JSONPlaceholder)
```

### Wichtige Design-Entscheidungen

1. **Repository als separate Klasse:** Der UserViewModel kennt das Repository ueber sein Interface. Das macht die Klasse testbar (man kann ein Mock-Repository injizieren).

2. **Eigene ApiException:** Statt generische Exceptions weiterzureichen, werden alle Netzwerk-Fehler in verstaendliche Meldungen uebersetzt.

3. **Getrennte Loading-States:** `isLoading` fuer die Benutzerliste und `isLoadingPosts` fuer die Posts. So koennen beide unabhaengig voneinander laden.

4. **Pull-to-Refresh:** `refreshUsers()` zeigt keinen eigenen Ladeindikator, weil `RefreshIndicator` bereits einen anzeigt.

5. **Hero-Animation:** Der CircleAvatar hat ein `Hero`-Tag, sodass er animiert zur Detail-Seite uebergeht.

6. **Suchfunktion:** Die Suche filtert die bereits geladene Liste lokal (kein neuer API-Call). Die gefilterte Liste wird im Getter berechnet.

7. **CustomScrollView + Slivers:** Die Detail-Seite verwendet Slivers fuer eine fliessende Scroll-Erfahrung mit expandierendem Header.

### Fehlerbehandlung

| Fehler | Anzeige |
|--------|---------|
| Kein Internet (SocketException) | "Keine Internetverbindung" + Retry |
| Timeout (TimeoutException) | "Server antwortet nicht" + Retry |
| HTTP 404 | "Nicht gefunden" + Retry |
| HTTP 5xx | "Serverfehler" + Retry |
| JSON-Fehler (FormatException) | "Ungueltige Serverantwort" + Retry |
