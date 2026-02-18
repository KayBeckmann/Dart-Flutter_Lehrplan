# Einheit 5.6: Projekt-Struktur & Architektur

## Lernziele

Nach dieser Einheit kannst du:
- Ein Backend-Projekt sinnvoll strukturieren
- Layered Architecture anwenden
- Dependency Injection nutzen
- Das Service- und Repository-Pattern implementieren

---

## Warum Struktur wichtig ist

Ein gut strukturiertes Projekt:
- Ist **wartbar** (Code leicht zu finden und ändern)
- Ist **testbar** (Komponenten isoliert testbar)
- Ist **skalierbar** (neue Features leicht hinzufügen)
- Hat **klare Verantwortlichkeiten** (Single Responsibility)

---

## Empfohlene Projektstruktur

```
my_api/
├── bin/
│   └── server.dart           # Einstiegspunkt
├── lib/
│   ├── app.dart              # App-Setup (Pipeline, Router)
│   ├── config/
│   │   ├── config.dart       # Konfigurationsklassen
│   │   └── config_loader.dart
│   ├── middleware/
│   │   ├── auth_middleware.dart
│   │   ├── cors_middleware.dart
│   │   └── error_middleware.dart
│   ├── routes/
│   │   ├── routes.dart       # Alle Routes zusammen
│   │   ├── user_routes.dart
│   │   └── product_routes.dart
│   ├── controllers/
│   │   ├── user_controller.dart
│   │   └── product_controller.dart
│   ├── services/
│   │   ├── user_service.dart
│   │   └── auth_service.dart
│   ├── repositories/
│   │   ├── user_repository.dart
│   │   └── product_repository.dart
│   ├── models/
│   │   ├── user.dart
│   │   └── product.dart
│   ├── dto/                  # Data Transfer Objects
│   │   ├── create_user_dto.dart
│   │   └── update_user_dto.dart
│   └── utils/
│       ├── json_response.dart
│       └── validators.dart
├── test/
│   ├── unit/
│   ├── integration/
│   └── helpers/
├── pubspec.yaml
├── analysis_options.yaml
├── .env.example
└── README.md
```

---

## Layered Architecture

Die Schichten einer Backend-Anwendung:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (Routes, Controllers, Middleware)                          │
│  HTTP-Request → Response                                    │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                      │
│  (Services)                                                 │
│  Geschäftslogik, Validierung, Orchestrierung                │
└───────────────────────────┬─────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│                    Data Access Layer                         │
│  (Repositories)                                             │
│  Datenbankzugriff, externe APIs                             │
└─────────────────────────────────────────────────────────────┘
```

### Regeln

1. **Höhere Schichten** dürfen **niedrigere Schichten** aufrufen
2. **Niedrigere Schichten** kennen **höhere Schichten** nicht
3. Jede Schicht hat eine **klare Verantwortung**

---

## Models / Entities

Models repräsentieren die Datenstrukturen:

```dart
// lib/models/user.dart
class User {
  final String id;
  final String email;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.createdAt,
    this.updatedAt,
  });

  // JSON-Serialisierung
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Kopie mit geänderten Werten
  User copyWith({
    String? email,
    String? name,
    DateTime? updatedAt,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

## Repository Pattern

Repositories abstrahieren den Datenzugriff:

```dart
// lib/repositories/user_repository.dart

/// Interface für UserRepository
abstract class UserRepository {
  Future<List<User>> findAll();
  Future<User?> findById(String id);
  Future<User?> findByEmail(String email);
  Future<User> create(User user);
  Future<User> update(User user);
  Future<void> delete(String id);
}

/// In-Memory Implementierung (für Entwicklung/Tests)
class InMemoryUserRepository implements UserRepository {
  final _users = <String, User>{};
  var _nextId = 1;

  @override
  Future<List<User>> findAll() async {
    return _users.values.toList();
  }

  @override
  Future<User?> findById(String id) async {
    return _users[id];
  }

  @override
  Future<User?> findByEmail(String email) async {
    return _users.values.where((u) => u.email == email).firstOrNull;
  }

  @override
  Future<User> create(User user) async {
    final id = '${_nextId++}';
    final newUser = User(
      id: id,
      email: user.email,
      name: user.name,
      createdAt: DateTime.now(),
    );
    _users[id] = newUser;
    return newUser;
  }

  @override
  Future<User> update(User user) async {
    if (!_users.containsKey(user.id)) {
      throw NotFoundException('User ${user.id} not found');
    }
    final updated = user.copyWith(updatedAt: DateTime.now());
    _users[user.id] = updated;
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    _users.remove(id);
  }
}
```

---

## Service Pattern

Services enthalten die Geschäftslogik:

```dart
// lib/services/user_service.dart
class UserService {
  final UserRepository _repository;
  final AuthService _authService;

  UserService(this._repository, this._authService);

  Future<List<User>> getAllUsers() {
    return _repository.findAll();
  }

  Future<User> getUserById(String id) async {
    final user = await _repository.findById(id);
    if (user == null) {
      throw NotFoundException('User $id not found');
    }
    return user;
  }

  Future<User> createUser(CreateUserDto dto) async {
    // Validierung
    _validateEmail(dto.email);
    _validatePassword(dto.password);

    // Prüfen ob Email bereits existiert
    final existing = await _repository.findByEmail(dto.email);
    if (existing != null) {
      throw ValidationException('Email already in use');
    }

    // Passwort hashen
    final passwordHash = await _authService.hashPassword(dto.password);

    // User erstellen
    final user = User(
      id: '', // Wird vom Repository gesetzt
      email: dto.email,
      name: dto.name,
      createdAt: DateTime.now(),
    );

    return _repository.create(user);
  }

  Future<User> updateUser(String id, UpdateUserDto dto) async {
    final user = await getUserById(id);

    if (dto.email != null) {
      _validateEmail(dto.email!);
      final existing = await _repository.findByEmail(dto.email!);
      if (existing != null && existing.id != id) {
        throw ValidationException('Email already in use');
      }
    }

    final updated = user.copyWith(
      email: dto.email,
      name: dto.name,
    );

    return _repository.update(updated);
  }

  Future<void> deleteUser(String id) async {
    await getUserById(id); // Prüft ob User existiert
    await _repository.delete(id);
  }

  void _validateEmail(String email) {
    if (!email.contains('@')) {
      throw ValidationException('Invalid email format');
    }
  }

  void _validatePassword(String password) {
    if (password.length < 8) {
      throw ValidationException('Password must be at least 8 characters');
    }
  }
}
```

---

## DTOs (Data Transfer Objects)

DTOs definieren die Struktur von Input-Daten:

```dart
// lib/dto/create_user_dto.dart
class CreateUserDto {
  final String email;
  final String name;
  final String password;

  CreateUserDto({
    required this.email,
    required this.name,
    required this.password,
  });

  factory CreateUserDto.fromJson(Map<String, dynamic> json) {
    return CreateUserDto(
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );
  }
}

// lib/dto/update_user_dto.dart
class UpdateUserDto {
  final String? email;
  final String? name;

  UpdateUserDto({this.email, this.name});

  factory UpdateUserDto.fromJson(Map<String, dynamic> json) {
    return UpdateUserDto(
      email: json['email'] as String?,
      name: json['name'] as String?,
    );
  }
}
```

---

## Controllers

Controllers verbinden Routes mit Services:

```dart
// lib/controllers/user_controller.dart
class UserController {
  final UserService _service;

  UserController(this._service);

  Router get router {
    final router = Router();

    router.get('/', _list);
    router.get('/<id>', _getById);
    router.post('/', _create);
    router.put('/<id>', _update);
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _list(Request request) async {
    final users = await _service.getAllUsers();
    return jsonResponse(users.map((u) => u.toJson()).toList());
  }

  Future<Response> _getById(Request request, String id) async {
    final user = await _service.getUserById(id);
    return jsonResponse(user.toJson());
  }

  Future<Response> _create(Request request) async {
    final body = await _parseJson(request);
    final dto = CreateUserDto.fromJson(body);
    final user = await _service.createUser(dto);
    return jsonResponse(user.toJson(), statusCode: 201);
  }

  Future<Response> _update(Request request, String id) async {
    final body = await _parseJson(request);
    final dto = UpdateUserDto.fromJson(body);
    final user = await _service.updateUser(id, dto);
    return jsonResponse(user.toJson());
  }

  Future<Response> _delete(Request request, String id) async {
    await _service.deleteUser(id);
    return Response(204);
  }

  Future<Map<String, dynamic>> _parseJson(Request request) async {
    final body = await request.readAsString();
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
```

---

## Dependency Injection

Abhängigkeiten werden von außen übergeben:

```dart
// lib/app.dart
class App {
  final AppConfig config;
  final UserRepository userRepository;
  final AuthService authService;
  late final UserService userService;
  late final UserController userController;

  App(this.config)
      : userRepository = InMemoryUserRepository(),
        authService = AuthService(config.auth.jwtSecret) {
    // Services erstellen
    userService = UserService(userRepository, authService);

    // Controllers erstellen
    userController = UserController(userService);
  }

  Handler get handler {
    final router = Router();

    // Routes mounten
    router.mount('/api/users', userController.router.call);
    router.get('/health', _healthCheck);

    // Pipeline
    return Pipeline()
        .addMiddleware(errorHandler())
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware())
        .addMiddleware(authMiddleware(authService))
        .addHandler(router.call);
  }

  Response _healthCheck(Request request) {
    return jsonResponse({'status': 'ok'});
  }
}

// bin/server.dart
void main() async {
  final config = await loadConfig();
  final app = App(config);

  await shelf_io.serve(app.handler, config.server.host, config.server.port);
}
```

---

## Exceptions

Zentrale Exception-Definitionen:

```dart
// lib/utils/exceptions.dart
abstract class AppException implements Exception {
  final String message;
  final int statusCode;

  AppException(this.message, this.statusCode);
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends AppException {
  final List<String>? errors;
  ValidationException(String message, {this.errors}) : super(message, 400);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(message, 401);
}

class ForbiddenException extends AppException {
  ForbiddenException([String message = 'Forbidden']) : super(message, 403);
}

class ConflictException extends AppException {
  ConflictException(String message) : super(message, 409);
}
```

---

## Zusammenfassung

| Schicht | Verantwortung | Beispiel |
|---------|---------------|----------|
| **Routes/Controllers** | HTTP-Handling | Request parsen, Response senden |
| **Services** | Geschäftslogik | Validierung, Orchestrierung |
| **Repositories** | Datenzugriff | CRUD-Operationen |
| **Models** | Datenstrukturen | User, Product |
| **DTOs** | Input-Strukturen | CreateUserDto |

### Vorteile dieser Struktur

1. **Testbarkeit**: Services können mit Mock-Repositories getestet werden
2. **Austauschbarkeit**: Repository-Implementierung kann gewechselt werden
3. **Klarheit**: Jede Datei hat einen klaren Zweck
4. **Wartbarkeit**: Änderungen sind lokal begrenzt

---

## Nächste Schritte

Im nächsten Block (Block 6) lernst du **REST API Entwicklung**: REST-Prinzipien, JSON-Serialisierung, CRUD-Operationen und mehr.
