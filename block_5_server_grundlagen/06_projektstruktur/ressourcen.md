# Ressourcen: Projekt-Struktur & Architektur

## Architektur-Patterns

- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html) - Robert C. Martin
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html) - Martin Fowler
- [Service Layer](https://martinfowler.com/eaaCatalog/serviceLayer.html) - Martin Fowler

## Dart-spezifisch

- [Effective Dart: Design](https://dart.dev/guides/language/effective-dart/design)
- [Dart Package Layout](https://dart.dev/tools/pub/package-layout)

## Cheat Sheet: Projektstruktur

```
project/
├── bin/                    # Einstiegspunkte
│   └── server.dart
├── lib/
│   ├── app.dart            # App-Setup
│   ├── config/             # Konfiguration
│   ├── middleware/         # HTTP-Middleware
│   ├── routes/             # Route-Definitionen
│   ├── controllers/        # Request-Handler
│   ├── services/           # Geschäftslogik
│   ├── repositories/       # Datenzugriff
│   ├── models/             # Datenstrukturen
│   ├── dto/                # Input-Strukturen
│   └── utils/              # Hilfsfunktionen
├── test/
│   ├── unit/
│   └── integration/
└── pubspec.yaml
```

## Cheat Sheet: Layered Architecture

```
┌──────────────────────────────────┐
│  Presentation (Routes/Controllers)│
├──────────────────────────────────┤
│  Business Logic (Services)        │
├──────────────────────────────────┤
│  Data Access (Repositories)       │
└──────────────────────────────────┘
```

## Cheat Sheet: Repository Pattern

```dart
// Interface
abstract class UserRepository {
  Future<List<User>> findAll();
  Future<User?> findById(String id);
  Future<User> create(User user);
  Future<User> update(User user);
  Future<void> delete(String id);
}

// Implementierung
class PostgresUserRepository implements UserRepository {
  final Database _db;
  PostgresUserRepository(this._db);

  @override
  Future<List<User>> findAll() async {
    final result = await _db.query('SELECT * FROM users');
    return result.map(User.fromRow).toList();
  }
  // ...
}

// In-Memory für Tests
class InMemoryUserRepository implements UserRepository {
  final _users = <String, User>{};
  // ...
}
```

## Cheat Sheet: Service Pattern

```dart
class UserService {
  final UserRepository _repo;
  final EmailService _email;

  UserService(this._repo, this._email);

  Future<User> createUser(CreateUserDto dto) async {
    // 1. Validierung
    _validate(dto);

    // 2. Business-Logik
    final existing = await _repo.findByEmail(dto.email);
    if (existing != null) throw ConflictException('Email exists');

    // 3. Daten speichern
    final user = await _repo.create(User.fromDto(dto));

    // 4. Side-Effects
    await _email.sendWelcome(user.email);

    return user;
  }
}
```

## Cheat Sheet: Controller

```dart
class UserController {
  final UserService _service;
  UserController(this._service);

  Router get router {
    final r = Router();
    r.get('/', list);
    r.get('/<id>', getById);
    r.post('/', create);
    r.put('/<id>', update);
    r.delete('/<id>', delete);
    return r;
  }

  Future<Response> list(Request req) async {
    final users = await _service.getAll();
    return jsonResponse(users);
  }
  // ...
}
```

## Cheat Sheet: Dependency Injection

```dart
class App {
  // Repositories (unterste Schicht)
  final UserRepository userRepo;
  final ProductRepository productRepo;

  // Services (mittlere Schicht)
  late final UserService userService;
  late final ProductService productService;

  // Controllers (oberste Schicht)
  late final UserController userController;

  App(Database db)
      : userRepo = PostgresUserRepository(db),
        productRepo = PostgresProductRepository(db) {
    userService = UserService(userRepo);
    productService = ProductService(productRepo);
    userController = UserController(userService);
  }
}
```

## Cheat Sheet: DTOs

```dart
// Input (vom Client)
class CreateUserDto {
  final String email;
  final String name;
  final String password;

  factory CreateUserDto.fromJson(Map<String, dynamic> json) => CreateUserDto(
    email: json['email'] ?? '',
    name: json['name'] ?? '',
    password: json['password'] ?? '',
  );
}

// Output (zum Client)
class UserResponse {
  final String id;
  final String email;
  final String name;
  // Kein Passwort!

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
  };
}
```

## Cheat Sheet: Exceptions

```dart
abstract class AppException implements Exception {
  final String message;
  final int statusCode;
  AppException(this.message, this.statusCode);
}

class NotFoundException extends AppException {
  NotFoundException(String msg) : super(msg, 404);
}

class ValidationException extends AppException {
  ValidationException(String msg) : super(msg, 400);
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String msg = 'Unauthorized']) : super(msg, 401);
}
```

## Best Practices

### 1. Eine Datei pro Klasse

```
lib/models/
├── user.dart
├── product.dart
└── order.dart
```

### 2. Barrel-Files für Exports

```dart
// lib/models/models.dart
export 'user.dart';
export 'product.dart';
export 'order.dart';
```

### 3. Klare Namenskonventionen

```
UserRepository      (nicht: UserRepo, UsersRepository)
UserService         (nicht: UserSvc, UsersService)
UserController      (nicht: UserCtrl)
CreateUserDto       (nicht: CreateUser, UserCreateDto)
```

### 4. Interfaces für Abstraktion

```dart
// Immer ein Interface
abstract class UserRepository { ... }

// Dann Implementierungen
class PostgresUserRepository implements UserRepository { ... }
class MongoUserRepository implements UserRepository { ... }
class InMemoryUserRepository implements UserRepository { ... }
```
