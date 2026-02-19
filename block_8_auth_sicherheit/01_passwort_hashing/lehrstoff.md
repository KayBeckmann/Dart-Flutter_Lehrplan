# Einheit 8.1: Passwort-Hashing & Benutzer-Registrierung

## Lernziele

Nach dieser Einheit kannst du:
- Passwörter sicher hashen mit bcrypt
- Salt und Hashing-Algorithmen verstehen
- Einen User-Registrierungsflow implementieren
- Passwort-Validierung durchführen

---

## Warum Passwort-Hashing?

**Niemals Passwörter im Klartext speichern!**

Wenn deine Datenbank kompromittiert wird:
- Klartext: Sofort alle Accounts übernommen
- Gehashte Passwörter: Angreifer muss jeden Hash knacken

### Was ist Hashing?

```
Passwort → Hash-Funktion → Hash (nicht umkehrbar)
"geheim123" → bcrypt → "$2a$12$LQv3c1yqBW..."
```

**Eigenschaften einer guten Hash-Funktion:**
- **Einweg**: Hash → Passwort nicht möglich
- **Deterministisch**: Gleiches Passwort = Gleicher Hash
- **Kollisionsresistent**: Unterschiedliche Passwörter ≠ Gleicher Hash
- **Langsam**: Brute-Force erschweren

---

## Hashing-Algorithmen

### Nicht geeignet (zu schnell!)

```dart
// NIEMALS verwenden für Passwörter!
import 'dart:convert';
import 'crypto/crypto.dart';

final hash = md5.convert(utf8.encode('password')).toString();
final hash2 = sha256.convert(utf8.encode('password')).toString();
```

MD5 und SHA sind für Passwörter **ungeeignet** - zu schnell, milliarden Hashes pro Sekunde möglich.

### Geeignete Algorithmen

| Algorithmus | Beschreibung | Empfehlung |
|-------------|--------------|------------|
| **bcrypt** | Bewährt, überall verfügbar | Standard-Wahl |
| **Argon2** | Modernster Algorithmus | Beste Sicherheit |
| **scrypt** | Memory-hard | Gute Alternative |

---

## bcrypt in Dart

### Installation

```yaml
dependencies:
  bcrypt: ^1.1.3
```

### Passwort hashen

```dart
import 'package:bcrypt/bcrypt.dart';

class PasswordService {
  // Cost Factor: Erhöht Rechenzeit exponentiell
  // 10 = ~100ms, 12 = ~300ms, 14 = ~1s
  static const int _costFactor = 12;

  /// Passwort hashen
  String hashPassword(String password) {
    // Salt wird automatisch generiert und im Hash gespeichert
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: _costFactor));
  }

  /// Passwort verifizieren
  bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword);
  }
}
```

### bcrypt Hash-Format

```
$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.N1tJ9vPmUHPK3a
│ │  │                              │
│ │  │                              └── Hash (31 Zeichen)
│ │  └── Salt (22 Zeichen, Base64)
│ └── Cost Factor (12 Runden = 2^12 Iterationen)
└── Algorithmus-Version (2a = bcrypt)
```

---

## Was ist Salt?

**Salt** ist ein zufälliger Wert, der dem Passwort vor dem Hashing hinzugefügt wird.

### Ohne Salt (Rainbow Table Attack)

```
"password" → hash("password") → "5f4dcc3b5aa765d61d8327deb882cf99"
```

Angreifer kann vorberechnete Tabellen (Rainbow Tables) verwenden.

### Mit Salt

```
salt = "x7Km9pQ2"
"password" + salt → hash → "$2a$12$x7Km9pQ2..."
```

- Gleiche Passwörter haben unterschiedliche Hashes
- Rainbow Tables werden nutzlos
- bcrypt speichert Salt automatisch im Hash

---

## User-Model

```dart
// lib/models/user.dart

class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String? name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final String role;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    this.name,
    DateTime? createdAt,
    this.updatedAt,
    this.isActive = true,
    this.role = 'user',
  }) : createdAt = createdAt ?? DateTime.now();

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isActive: json['is_active'] as bool? ?? true,
      role: json['role'] as String? ?? 'user',
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'email': email,
    'password_hash': passwordHash,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt?.toIso8601String(),
    'is_active': isActive,
    'role': role,
  };

  /// Für API-Responses (ohne sensible Daten)
  Map<String, dynamic> toPublicJson() => {
    'id': id,
    'email': email,
    'name': name,
    'created_at': createdAt.toIso8601String(),
    'role': role,
  };
}
```

---

## Registrierungs-DTOs

```dart
// lib/models/auth_dto.dart

class RegisterRequest {
  final String email;
  final String password;
  final String? name;

  RegisterRequest({
    required this.email,
    required this.password,
    this.name,
  });

  factory RegisterRequest.fromJson(Map<String, dynamic> json) {
    return RegisterRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      name: json['name'] as String?,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    // Email validieren
    if (!_isValidEmail(email)) {
      errors.add('Invalid email format');
    }

    // Passwort validieren
    errors.addAll(validatePassword(password));

    return errors;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static List<String> validatePassword(String password) {
    final errors = <String>[];

    if (password.length < 8) {
      errors.add('Password must be at least 8 characters');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Password must contain an uppercase letter');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('Password must contain a lowercase letter');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('Password must contain a number');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      errors.add('Password must contain a special character');
    }

    return errors;
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }
}
```

---

## User Repository

```dart
// lib/repositories/user_repository.dart
import 'package:postgres/postgres.dart';

class UserRepository {
  final Connection _db;

  UserRepository(this._db);

  Future<User?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE email = @email'),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;
    return User.fromJson(result.first.toColumnMap());
  }

  Future<User?> findById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return User.fromJson(result.first.toColumnMap());
  }

  Future<User> create(User user) async {
    final result = await _db.execute(
      Sql.named('''
        INSERT INTO users (email, password_hash, name, role, is_active, created_at)
        VALUES (@email, @passwordHash, @name, @role, @isActive, @createdAt)
        RETURNING *
      '''),
      parameters: {
        'email': user.email,
        'passwordHash': user.passwordHash,
        'name': user.name,
        'role': user.role,
        'isActive': user.isActive,
        'createdAt': user.createdAt,
      },
    );

    return User.fromJson(result.first.toColumnMap());
  }

  Future<bool> emailExists(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT 1 FROM users WHERE email = @email'),
      parameters: {'email': email},
    );
    return result.isNotEmpty;
  }

  Future<void> updatePassword(int userId, String newPasswordHash) async {
    await _db.execute(
      Sql.named('''
        UPDATE users
        SET password_hash = @passwordHash, updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': userId,
        'passwordHash': newPasswordHash,
      },
    );
  }
}
```

---

## Auth Service

```dart
// lib/services/auth_service.dart
import 'package:bcrypt/bcrypt.dart';

class AuthException implements Exception {
  final String message;
  final int statusCode;

  AuthException(this.message, {this.statusCode = 400});
}

class AuthService {
  final UserRepository _userRepo;
  static const int _bcryptCost = 12;

  AuthService(this._userRepo);

  /// Benutzer registrieren
  Future<User> register(RegisterRequest request) async {
    // 1. Validierung
    final errors = request.validate();
    if (errors.isNotEmpty) {
      throw AuthException(errors.join(', '));
    }

    // 2. Email-Duplikat prüfen
    if (await _userRepo.emailExists(request.email)) {
      throw AuthException('Email already registered', statusCode: 409);
    }

    // 3. Passwort hashen
    final passwordHash = BCrypt.hashpw(
      request.password,
      BCrypt.gensalt(logRounds: _bcryptCost),
    );

    // 4. User erstellen
    final user = User(
      email: request.email.toLowerCase().trim(),
      passwordHash: passwordHash,
      name: request.name?.trim(),
    );

    return await _userRepo.create(user);
  }

  /// Benutzer authentifizieren
  Future<User> authenticate(LoginRequest request) async {
    // 1. User laden
    final user = await _userRepo.findByEmail(request.email.toLowerCase());

    if (user == null) {
      // Timing-Attack verhindern: Immer hashen, auch wenn User nicht existiert
      BCrypt.hashpw('dummy', BCrypt.gensalt(logRounds: _bcryptCost));
      throw AuthException('Invalid credentials', statusCode: 401);
    }

    // 2. Account aktiv?
    if (!user.isActive) {
      throw AuthException('Account is deactivated', statusCode: 403);
    }

    // 3. Passwort prüfen
    if (!BCrypt.checkpw(request.password, user.passwordHash)) {
      throw AuthException('Invalid credentials', statusCode: 401);
    }

    return user;
  }

  /// Passwort ändern
  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // 1. User laden
    final user = await _userRepo.findById(userId);
    if (user == null) {
      throw AuthException('User not found', statusCode: 404);
    }

    // 2. Aktuelles Passwort prüfen
    if (!BCrypt.checkpw(currentPassword, user.passwordHash)) {
      throw AuthException('Current password is incorrect', statusCode: 401);
    }

    // 3. Neues Passwort validieren
    final errors = RegisterRequest.validatePassword(newPassword);
    if (errors.isNotEmpty) {
      throw AuthException(errors.join(', '));
    }

    // 4. Neues Passwort hashen und speichern
    final newHash = BCrypt.hashpw(
      newPassword,
      BCrypt.gensalt(logRounds: _bcryptCost),
    );

    await _userRepo.updatePassword(userId, newHash);
  }
}
```

---

## Auth Handler

```dart
// lib/handlers/auth_handler.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthHandler {
  final AuthService _authService;

  AuthHandler(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);

    return router;
  }

  Future<Response> _register(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final registerRequest = RegisterRequest.fromJson(data);

      final user = await _authService.register(registerRequest);

      return Response(
        201,
        body: jsonEncode({
          'message': 'User registered successfully',
          'user': user.toPublicJson(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } on AuthException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Registration failed'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final loginRequest = LoginRequest.fromJson(data);

      final user = await _authService.authenticate(loginRequest);

      // TODO: JWT-Token generieren (nächste Einheit)
      return Response.ok(
        jsonEncode({
          'message': 'Login successful',
          'user': user.toPublicJson(),
        }),
        headers: {'content-type': 'application/json'},
      );
    } on AuthException catch (e) {
      return Response(
        e.statusCode,
        body: jsonEncode({'error': e.message}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Login failed'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }
}
```

---

## Datenbank-Schema

```sql
-- migrations/001_create_users.sql

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Index für Login-Queries
CREATE INDEX idx_users_email ON users(email);

-- Index für aktive User
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;
```

---

## Sicherheits-Best-Practices

### 1. Timing Attacks verhindern

```dart
// SCHLECHT: Verrät, ob Email existiert
if (user == null) {
  throw AuthException('Email not found');  // Schnelle Antwort
}
if (!verifyPassword()) {
  throw AuthException('Wrong password');   // Langsame Antwort
}

// GUT: Konstante Zeit für beide Fälle
if (user == null) {
  // Trotzdem hashen, um gleiche Antwortzeit zu haben
  BCrypt.hashpw('dummy', BCrypt.gensalt(logRounds: 12));
  throw AuthException('Invalid credentials');
}
if (!verifyPassword()) {
  throw AuthException('Invalid credentials');
}
```

### 2. Generische Fehlermeldungen

```dart
// SCHLECHT
throw AuthException('Email not found');
throw AuthException('Wrong password');

// GUT
throw AuthException('Invalid credentials');
```

### 3. Rate Limiting

```dart
// Brute-Force-Schutz (mit Redis)
class LoginRateLimiter {
  final RedisClient _redis;
  final int maxAttempts = 5;
  final Duration window = Duration(minutes: 15);

  Future<bool> isBlocked(String email) async {
    final key = 'login_attempts:$email';
    final attempts = await _redis.get(key);
    return (int.tryParse(attempts ?? '0') ?? 0) >= maxAttempts;
  }

  Future<void> recordFailedAttempt(String email) async {
    final key = 'login_attempts:$email';
    await _redis.command.send_object(['INCR', key]);
    await _redis.expire(key, window);
  }

  Future<void> clearAttempts(String email) async {
    await _redis.del('login_attempts:$email');
  }
}
```

### 4. Account Lockout

```dart
// Nach 5 fehlgeschlagenen Versuchen Account sperren
if (await _rateLimiter.isBlocked(request.email)) {
  throw AuthException(
    'Account temporarily locked. Try again later.',
    statusCode: 429,
  );
}

// Bei Fehlschlag
await _rateLimiter.recordFailedAttempt(request.email);

// Bei Erfolg
await _rateLimiter.clearAttempts(request.email);
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| **Hashing** | Einweg-Transformation, nicht umkehrbar |
| **Salt** | Zufälliger Wert, verhindert Rainbow Tables |
| **bcrypt** | Standard für Passwort-Hashing, inkl. Salt |
| **Cost Factor** | Erhöht Rechenzeit exponentiell |
| **Timing Attack** | Konstante Antwortzeit wichtig |
| **Rate Limiting** | Brute-Force-Schutz |

**Wichtigste Regeln:**
1. Niemals Klartext-Passwörter speichern
2. bcrypt oder Argon2 verwenden
3. Generische Fehlermeldungen
4. Rate Limiting implementieren
5. Passwort-Policies durchsetzen

