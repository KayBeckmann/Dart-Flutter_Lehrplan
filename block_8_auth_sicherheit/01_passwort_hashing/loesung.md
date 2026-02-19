# Lösung 8.1: Passwort-Hashing & Benutzer-Registrierung

## Password Service

```dart
// lib/services/password_service.dart
import 'package:bcrypt/bcrypt.dart';

class PasswordService {
  final int _costFactor;

  PasswordService({int costFactor = 12}) : _costFactor = costFactor;

  /// Hash ein Passwort mit bcrypt
  String hash(String password) {
    final salt = BCrypt.gensalt(logRounds: _costFactor);
    return BCrypt.hashpw(password, salt);
  }

  /// Verifiziere ein Passwort gegen einen Hash
  bool verify(String password, String hash) {
    try {
      return BCrypt.checkpw(password, hash);
    } catch (e) {
      return false;
    }
  }

  /// Prüfe ob ein Hash neu gehasht werden sollte
  bool needsRehash(String hash) {
    // bcrypt Hash Format: $2a$XX$...
    // XX = Cost Factor
    final match = RegExp(r'^\$2[aby]?\$(\d+)\$').firstMatch(hash);
    if (match == null) return true;

    final hashCost = int.tryParse(match.group(1) ?? '0') ?? 0;
    return hashCost < _costFactor;
  }

  /// Generiere einen zufälligen Salt (für Tests)
  String generateSalt() {
    return BCrypt.gensalt(logRounds: _costFactor);
  }
}
```

---

## Password Validator

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

  String get strengthLabel {
    switch (strength) {
      case 0:
        return 'Very Weak';
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Strong';
      case 4:
        return 'Very Strong';
      default:
        return 'Unknown';
    }
  }
}

class PasswordValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireLowercase;
  final bool requireDigit;
  final bool requireSpecialChar;

  static const List<String> _commonPasswords = [
    'password', '123456', '12345678', 'qwerty', 'abc123',
    'password1', 'admin', 'letmein', 'welcome', 'monkey',
    'dragon', 'master', 'login', 'princess', 'sunshine',
    'passw0rd', 'shadow', 'trustno1', 'iloveyou', 'football',
  ];

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

    // Mindestlänge
    if (password.length < minLength) {
      errors.add('Password must be at least $minLength characters');
    } else {
      strength++;
    }

    // Bonus für längere Passwörter
    if (password.length >= 12) strength++;

    // Großbuchstaben
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    if (requireUppercase && !hasUppercase) {
      errors.add('Password must contain at least one uppercase letter');
    }
    if (hasUppercase) strength++;

    // Kleinbuchstaben
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    if (requireLowercase && !hasLowercase) {
      errors.add('Password must contain at least one lowercase letter');
    }

    // Ziffern
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    if (requireDigit && !hasDigit) {
      errors.add('Password must contain at least one digit');
    }
    if (hasDigit) strength++;

    // Sonderzeichen
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]'));
    if (requireSpecialChar && !hasSpecial) {
      errors.add('Password must contain at least one special character');
    }
    if (hasSpecial) strength++;

    // Common Password Check
    if (isCommonPassword(password)) {
      errors.add('Password is too common');
      strength = 0;
    }

    // Strength auf 0-4 begrenzen
    strength = strength.clamp(0, 4);

    return PasswordValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      strength: strength,
    );
  }

  bool isCommonPassword(String password) {
    return _commonPasswords.contains(password.toLowerCase());
  }
}
```

---

## User Model

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

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      email: json['email'] as String,
      passwordHash: json['password_hash'] as String,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'user',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] is DateTime
          ? json['created_at'] as DateTime
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] is DateTime
              ? json['updated_at'] as DateTime
              : DateTime.parse(json['updated_at'] as String))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'email': email,
        'password_hash': passwordHash,
        'name': name,
        'role': role,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  /// Für API-Responses (ohne sensible Daten)
  Map<String, dynamic> toPublicJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'created_at': createdAt.toIso8601String(),
      };

  User copyWith({
    int? id,
    String? email,
    String? passwordHash,
    String? name,
    String? role,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
```

---

## User Repository

```dart
// lib/repositories/user_repository.dart
import 'package:postgres/postgres.dart';
import '../models/user.dart';

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

  @override
  Future<User?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE LOWER(email) = LOWER(@email)'),
      parameters: {'email': email},
    );

    if (result.isEmpty) return null;
    return User.fromJson(result.first.toColumnMap());
  }

  @override
  Future<User?> findById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE id = @id'),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    return User.fromJson(result.first.toColumnMap());
  }

  @override
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

  @override
  Future<bool> emailExists(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT 1 FROM users WHERE LOWER(email) = LOWER(@email)'),
      parameters: {'email': email},
    );
    return result.isNotEmpty;
  }

  @override
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

  @override
  Future<void> deactivate(int userId) async {
    await _db.execute(
      Sql.named('''
        UPDATE users
        SET is_active = false, updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {'id': userId},
    );
  }
}
```

---

## Auth Service

```dart
// lib/services/auth_service.dart
import '../models/user.dart';
import '../repositories/user_repository.dart';
import 'password_service.dart';
import '../validators/password_validator.dart';

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
    // 1. Email validieren
    if (!_isValidEmail(email)) {
      return AuthResult.failure('Invalid email format');
    }

    // 2. Email normalisieren
    final normalizedEmail = email.toLowerCase().trim();

    // 3. Prüfen ob Email existiert
    if (await _userRepo.emailExists(normalizedEmail)) {
      return AuthResult.failure('Email already registered', statusCode: 409);
    }

    // 4. Passwort validieren
    final passwordResult = _passwordValidator.validate(password);
    if (!passwordResult.isValid) {
      return AuthResult.failure(passwordResult.errors.join(', '));
    }

    // 5. Passwort hashen
    final passwordHash = _passwordService.hash(password);

    // 6. User erstellen
    final user = User(
      email: normalizedEmail,
      passwordHash: passwordHash,
      name: name?.trim(),
    );

    try {
      final createdUser = await _userRepo.create(user);
      return AuthResult.success(createdUser);
    } catch (e) {
      return AuthResult.failure('Registration failed', statusCode: 500);
    }
  }

  /// Authentifiziere einen Benutzer
  Future<AuthResult> authenticate({
    required String email,
    required String password,
  }) async {
    // 1. User laden
    final user = await _userRepo.findByEmail(email.toLowerCase().trim());

    if (user == null) {
      // 2. Timing-Attack verhindern
      _passwordService.hash('dummy_password_to_prevent_timing_attack');
      return AuthResult.failure('Invalid credentials', statusCode: 401);
    }

    // 3. Account aktiv?
    if (!user.isActive) {
      return AuthResult.failure('Account is deactivated', statusCode: 403);
    }

    // 4. Passwort verifizieren
    if (!_passwordService.verify(password, user.passwordHash)) {
      return AuthResult.failure('Invalid credentials', statusCode: 401);
    }

    // 5. Optional: Rehash wenn nötig
    if (_passwordService.needsRehash(user.passwordHash)) {
      final newHash = _passwordService.hash(password);
      await _userRepo.updatePassword(user.id!, newHash);
    }

    return AuthResult.success(user);
  }

  /// Passwort ändern
  Future<AuthResult> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    // 1. User laden
    final user = await _userRepo.findById(userId);
    if (user == null) {
      return AuthResult.failure('User not found', statusCode: 404);
    }

    // 2. Aktuelles Passwort prüfen
    if (!_passwordService.verify(currentPassword, user.passwordHash)) {
      return AuthResult.failure('Current password is incorrect', statusCode: 401);
    }

    // 3. Neues Passwort validieren
    final passwordResult = _passwordValidator.validate(newPassword);
    if (!passwordResult.isValid) {
      return AuthResult.failure(passwordResult.errors.join(', '));
    }

    // 4. Prüfen dass neues Passwort nicht gleich altem ist
    if (_passwordService.verify(newPassword, user.passwordHash)) {
      return AuthResult.failure('New password must be different from current password');
    }

    // 5. Neues Passwort hashen und speichern
    final newHash = _passwordService.hash(newPassword);
    await _userRepo.updatePassword(userId, newHash);

    return AuthResult.success(user);
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
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
import '../services/auth_service.dart';

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

      final email = data['email'] as String?;
      final password = data['password'] as String?;
      final name = data['name'] as String?;

      if (email == null || password == null) {
        return _jsonResponse(
          {'error': 'Email and password are required'},
          statusCode: 400,
        );
      }

      final result = await _authService.register(
        email: email,
        password: password,
        name: name,
      );

      if (result.success) {
        return _jsonResponse(
          {
            'message': 'User registered successfully',
            'user': result.user!.toPublicJson(),
          },
          statusCode: 201,
        );
      } else {
        return _jsonResponse(
          {'error': result.error},
          statusCode: result.statusCode,
        );
      }
    } on FormatException {
      return _jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
    } catch (e) {
      return _jsonResponse(
        {'error': 'Registration failed'},
        statusCode: 500,
      );
    }
  }

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final email = data['email'] as String?;
      final password = data['password'] as String?;

      if (email == null || password == null) {
        return _jsonResponse(
          {'error': 'Email and password are required'},
          statusCode: 400,
        );
      }

      final result = await _authService.authenticate(
        email: email,
        password: password,
      );

      if (result.success) {
        return _jsonResponse({
          'message': 'Login successful',
          'user': result.user!.toPublicJson(),
          // Token wird in nächster Einheit hinzugefügt
        });
      } else {
        return _jsonResponse(
          {'error': result.error},
          statusCode: result.statusCode,
        );
      }
    } on FormatException {
      return _jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
    } catch (e) {
      return _jsonResponse({'error': 'Login failed'}, statusCode: 500);
    }
  }

  Response _jsonResponse(Map<String, dynamic> data, {int statusCode = 200}) {
    return Response(
      statusCode,
      body: jsonEncode(data),
      headers: {'content-type': 'application/json'},
    );
  }
}
```

---

## Rate Limiter

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
    _cleanupOldAttempts(identifier);

    final attempts = _attempts[identifier] ?? [];
    final remaining = maxAttempts - attempts.length;

    if (attempts.length >= maxAttempts) {
      final oldestAttempt = attempts.first;
      final resetTime = oldestAttempt.add(window);
      final resetInSeconds = resetTime.difference(DateTime.now()).inSeconds;

      return RateLimitResult(
        allowed: false,
        remaining: 0,
        resetInSeconds: resetInSeconds > 0 ? resetInSeconds : 0,
      );
    }

    return RateLimitResult(
      allowed: true,
      remaining: remaining,
      resetInSeconds: window.inSeconds,
    );
  }

  /// Registriere einen fehlgeschlagenen Versuch
  void recordFailedAttempt(String identifier) {
    _attempts.putIfAbsent(identifier, () => []);
    _attempts[identifier]!.add(DateTime.now());
  }

  /// Lösche alle Versuche nach erfolgreichem Login
  void clearAttempts(String identifier) {
    _attempts.remove(identifier);
  }

  void _cleanupOldAttempts(String identifier) {
    final attempts = _attempts[identifier];
    if (attempts == null) return;

    final cutoff = DateTime.now().subtract(window);
    attempts.removeWhere((attempt) => attempt.isBefore(cutoff));

    if (attempts.isEmpty) {
      _attempts.remove(identifier);
    }
  }
}
```

---

## Main Server

```dart
// bin/server.dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';

import '../lib/services/password_service.dart';
import '../lib/validators/password_validator.dart';
import '../lib/repositories/user_repository.dart';
import '../lib/services/auth_service.dart';
import '../lib/handlers/auth_handler.dart';

Future<void> main() async {
  // Database Connection
  final db = await Connection.open(
    Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      database: Platform.environment['DB_NAME'] ?? 'auth_db',
      username: Platform.environment['DB_USER'] ?? 'postgres',
      password: Platform.environment['DB_PASSWORD'] ?? 'postgres',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  print('Connected to database');

  // Services
  final passwordService = PasswordService(costFactor: 12);
  final passwordValidator = PasswordValidator(
    minLength: 8,
    requireUppercase: true,
    requireLowercase: true,
    requireDigit: true,
    requireSpecialChar: true,
  );
  final userRepo = PostgresUserRepository(db);
  final authService = AuthService(userRepo, passwordService, passwordValidator);

  // Handler
  final authHandler = AuthHandler(authService);

  // Router
  final router = Router();
  router.mount('/api/auth', authHandler.router);

  // Health Check
  router.get('/health', (Request request) {
    return Response.ok('OK');
  });

  // Pipeline
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router);

  // Server starten
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await shelf_io.serve(handler, 'localhost', port);
  print('Server running on http://${server.address.host}:${server.port}');
}

Middleware _corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await handler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
};
```

---

## Unit Tests

```dart
// test/password_service_test.dart
import 'package:test/test.dart';
import '../lib/services/password_service.dart';

void main() {
  group('PasswordService', () {
    late PasswordService service;

    setUp(() {
      service = PasswordService(costFactor: 4); // Niedriger für schnelle Tests
    });

    test('hash() generates valid bcrypt hash', () {
      final hash = service.hash('password123');

      expect(hash, startsWith(r'$2'));
      expect(hash.length, greaterThan(50));
    });

    test('verify() returns true for correct password', () {
      final hash = service.hash('MySecretPassword!');

      expect(service.verify('MySecretPassword!', hash), isTrue);
    });

    test('verify() returns false for wrong password', () {
      final hash = service.hash('MySecretPassword!');

      expect(service.verify('WrongPassword', hash), isFalse);
    });

    test('same password generates different hashes', () {
      final hash1 = service.hash('password');
      final hash2 = service.hash('password');

      expect(hash1, isNot(equals(hash2)));
    });

    test('needsRehash() returns true for lower cost factor', () {
      final lowCostService = PasswordService(costFactor: 4);
      final hash = lowCostService.hash('password');

      final highCostService = PasswordService(costFactor: 10);
      expect(highCostService.needsRehash(hash), isTrue);
    });
  });
}
```

```dart
// test/password_validator_test.dart
import 'package:test/test.dart';
import '../lib/validators/password_validator.dart';

void main() {
  group('PasswordValidator', () {
    late PasswordValidator validator;

    setUp(() {
      validator = PasswordValidator();
    });

    test('valid password passes', () {
      final result = validator.validate('SecurePass123!');

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.strength, greaterThanOrEqualTo(3));
    });

    test('short password fails', () {
      final result = validator.validate('Abc1!');

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('8 characters')));
    });

    test('password without uppercase fails', () {
      final result = validator.validate('lowercase123!');

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('uppercase')));
    });

    test('common password fails', () {
      final result = validator.validate('password');

      expect(result.isValid, isFalse);
      expect(result.errors, contains(contains('common')));
    });

    test('strength increases with complexity', () {
      final weak = validator.validate('abcdefgh');
      final strong = validator.validate('SecurePass123!@#');

      expect(strong.strength, greaterThan(weak.strength));
    });
  });
}
```

