# Übung 8.1: Passwort-Hashing & Benutzer-Registrierung

## Ziel

Implementiere ein sicheres User-Management-System mit Passwort-Hashing.

---

## Vorbereitung

### Projekt erstellen

```bash
dart create -t server-shelf auth_api
cd auth_api
```

### Dependencies

```yaml
dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  bcrypt: ^1.1.3
  postgres: ^3.0.0

dev_dependencies:
  test: ^1.24.0
```

### Datenbank

```bash
docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15
```

```sql
CREATE DATABASE auth_db;

\c auth_db

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
```

---

## Aufgabe 1: Password Service (15 min)

Implementiere den PasswordService mit bcrypt:

```dart
// lib/services/password_service.dart

class PasswordService {
  final int _costFactor;

  PasswordService({int costFactor = 12}) : _costFactor = costFactor;

  /// Hash ein Passwort mit bcrypt
  String hash(String password) {
    // TODO: bcrypt verwenden
  }

  /// Verifiziere ein Passwort gegen einen Hash
  bool verify(String password, String hash) {
    // TODO: bcrypt.checkpw verwenden
  }

  /// Prüfe ob ein Hash neu gehasht werden sollte
  /// (z.B. wenn Cost Factor erhöht wurde)
  bool needsRehash(String hash) {
    // TODO: Cost Factor aus Hash extrahieren und vergleichen
  }
}
```

**Test:**

```dart
void main() {
  final service = PasswordService(costFactor: 10);

  final hash = service.hash('MySecurePassword123!');
  print('Hash: $hash');
  print('Verify correct: ${service.verify('MySecurePassword123!', hash)}');
  print('Verify wrong: ${service.verify('WrongPassword', hash)}');
}
```

---

## Aufgabe 2: Passwort-Validierung (15 min)

Implementiere einen PasswordValidator:

```dart
// lib/validators/password_validator.dart

class PasswordValidationResult {
  final bool isValid;
  final List<String> errors;
  final int strength; // 0-4

  PasswordValidationResult({
    required this.isValid,
    required this.errors,
    required this.strength,
  });
}

class PasswordValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecialChar;

  PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireLowercase = true,
    this.requireDigit = true,
    this.requireSpecialChar = true,
  });

  PasswordValidationResult validate(String password) {
    final errors = <String>[];
    int strength = 0;

    // TODO: Implementiere Validierungsregeln
    // - Mindestlänge prüfen
    // - Großbuchstaben prüfen
    // - Kleinbuchstaben prüfen
    // - Ziffern prüfen
    // - Sonderzeichen prüfen
    // - Stärke berechnen (0-4)

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: strength,
    );
  }

  /// Prüft ob Passwort in Common-Password-Liste
  bool isCommonPassword(String password) {
    final common = [
      'password', '123456', '12345678', 'qwerty', 'abc123',
      'password1', 'admin', 'letmein', 'welcome', 'monkey',
    ];
    return common.contains(password.toLowerCase());
  }
}
```

---

## Aufgabe 3: User Model & Repository (20 min)

### User Model

```dart
// lib/models/user.dart

class User {
  final int? id;
  final String email;
  final String passwordHash;
  final String? name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    this.id,
    required this.email,
    required this.passwordHash,
    this.name,
    this.role = 'user',
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // TODO: fromJson, toJson, toPublicJson implementieren
}
```

### User Repository

```dart
// lib/repositories/user_repository.dart

abstract class UserRepository {
  Future<User?> findByEmail(String email);
  Future<User?> findById(int id);
  Future<User> create(User user);
  Future<bool> emailExists(String email);
  Future<void> updatePassword(int userId, String newPasswordHash);
  Future<void> deactivate(int userId);
}

class PostgresUserRepository implements UserRepository {
  final Connection _db;

  PostgresUserRepository(this._db);

  // TODO: Alle Methoden implementieren
}
```

---

## Aufgabe 4: Auth Service (20 min)

```dart
// lib/services/auth_service.dart

class AuthResult {
  final bool success;
  final User? user;
  final String? error;
  final int statusCode;

  AuthResult.success(this.user)
      : success = true,
        error = null,
        statusCode = 200;

  AuthResult.failure(this.error, {this.statusCode = 400})
      : success = false,
        user = null;
}

class AuthService {
  final UserRepository _userRepo;
  final PasswordService _passwordService;
  final PasswordValidator _passwordValidator;

  AuthService(this._userRepo, this._passwordService, this._passwordValidator);

  /// Registriere einen neuen Benutzer
  Future<AuthResult> register({
    required String email,
    required String password,
    String? name,
  }) async {
    // TODO:
    // 1. Email validieren (Format)
    // 2. Email normalisieren (lowercase, trim)
    // 3. Prüfen ob Email schon existiert
    // 4. Passwort validieren
    // 5. Passwort hashen
    // 6. User erstellen
  }

  /// Authentifiziere einen Benutzer
  Future<AuthResult> authenticate({
    required String email,
    required String password,
  }) async {
    // TODO:
    // 1. User laden
    // 2. Timing-Attack verhindern (auch bei nicht existierendem User hashen)
    // 3. Prüfen ob Account aktiv
    // 4. Passwort verifizieren
    // 5. Optional: Rehash wenn nötig
  }

  /// Passwort ändern
  Future<AuthResult> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // TODO:
    // 1. User laden
    // 2. Aktuelles Passwort prüfen
    // 3. Neues Passwort validieren
    // 4. Neues Passwort hashen
    // 5. Speichern
  }
}
```

---

## Aufgabe 5: Auth Handler (15 min)

```dart
// lib/handlers/auth_handler.dart

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
    // TODO:
    // 1. Body parsen
    // 2. AuthService.register aufrufen
    // 3. Response erstellen (201 bei Erfolg)
  }

  Future<Response> _login(Request request) async {
    // TODO:
    // 1. Body parsen
    // 2. AuthService.authenticate aufrufen
    // 3. Response erstellen
  }
}
```

---

## Aufgabe 6: Rate Limiter (Bonus, 15 min)

```dart
// lib/services/rate_limiter.dart

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int resetInSeconds;

  RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.resetInSeconds,
  });
}

class LoginRateLimiter {
  final Map<String, List<DateTime>> _attempts = {};
  final int maxAttempts;
  final Duration window;

  LoginRateLimiter({
    this.maxAttempts = 5,
    this.window = const Duration(minutes: 15),
  });

  /// Prüfe ob Login erlaubt ist
  RateLimitResult check(String identifier) {
    // TODO:
    // 1. Alte Einträge entfernen
    // 2. Aktuelle Anzahl zählen
    // 3. RateLimitResult zurückgeben
  }

  /// Registriere einen fehlgeschlagenen Versuch
  void recordFailedAttempt(String identifier) {
    // TODO: Timestamp hinzufügen
  }

  /// Lösche alle Versuche nach erfolgreichem Login
  void clearAttempts(String identifier) {
    // TODO: Einträge löschen
  }
}
```

---

## Aufgabe 7: Main Server (10 min)

```dart
// bin/server.dart

Future<void> main() async {
  // Database Connection
  final db = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'auth_db',
      username: 'postgres',
      password: 'postgres',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  // Services
  final passwordService = PasswordService();
  final passwordValidator = PasswordValidator();
  final userRepo = PostgresUserRepository(db);
  final authService = AuthService(userRepo, passwordService, passwordValidator);

  // Handler
  final authHandler = AuthHandler(authService);

  // Router
  final router = Router();
  router.mount('/api/auth', authHandler.router);

  // Server
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await serve(handler, 'localhost', 8080);
  print('Server running on http://${server.address.host}:${server.port}');
}
```

---

## Testen

### Registrierung

```bash
# Erfolgreiche Registrierung
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "SecurePass123!", "name": "Test User"}'

# Schwaches Passwort
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test2@example.com", "password": "weak"}'

# Duplicate Email
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "AnotherPass123!"}'
```

### Login

```bash
# Erfolgreicher Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "SecurePass123!"}'

# Falsches Passwort
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "WrongPassword"}'
```

---

## Abgabe-Checkliste

- [ ] PasswordService mit hash/verify
- [ ] PasswordValidator mit Stärke-Berechnung
- [ ] User Model mit toPublicJson (ohne passwordHash)
- [ ] UserRepository mit allen Methoden
- [ ] AuthService mit register/authenticate/changePassword
- [ ] AuthHandler mit /register und /login Endpoints
- [ ] Timing-Attack-Schutz implementiert
- [ ] Generische Fehlermeldungen
- [ ] (Bonus) Rate Limiter

