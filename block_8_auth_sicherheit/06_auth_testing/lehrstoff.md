# Einheit 8.6: Testing der Auth-Schicht

## Lernziele

Nach dieser Einheit kannst du:
- Unit Tests für Auth-Komponenten schreiben
- Integration Tests für Auth-Flows erstellen
- Mocks für Auth-Services implementieren
- Test-Fixtures für User und Tokens nutzen

---

## Test-Strategie für Auth

### Test-Pyramide

```
         /\
        /  \
       / E2E \        ← Wenige: Vollständige Auth-Flows
      /--------\
     /Integration\    ← Einige: Handler mit Services
    /--------------\
   /   Unit Tests   \  ← Viele: Services, Validators, etc.
  /------------------\
```

### Was testen?

| Komponente | Test-Fokus |
|------------|------------|
| **PasswordService** | Hashing, Verifizierung |
| **JwtService** | Token-Generierung, Validierung |
| **AuthService** | Login, Register, Refresh |
| **Auth Middleware** | Token-Extraktion, Context |
| **Guards** | Rollen, Permissions, Owner |
| **Auth Handler** | HTTP-Requests, Responses |

---

## Unit Tests: Password Service

```dart
// test/services/password_service_test.dart
import 'package:test/test.dart';
import 'package:my_api/services/password_service.dart';

void main() {
  group('PasswordService', () {
    late PasswordService service;

    setUp(() {
      // Niedriger Cost für schnelle Tests
      service = PasswordService(costFactor: 4);
    });

    group('hash', () {
      test('generates valid bcrypt hash', () {
        final hash = service.hash('password123');

        expect(hash, startsWith(r'$2'));
        expect(hash.length, greaterThan(50));
      });

      test('generates different hashes for same password', () {
        final hash1 = service.hash('password');
        final hash2 = service.hash('password');

        expect(hash1, isNot(equals(hash2)));
      });
    });

    group('verify', () {
      test('returns true for correct password', () {
        final hash = service.hash('secret123');

        expect(service.verify('secret123', hash), isTrue);
      });

      test('returns false for wrong password', () {
        final hash = service.hash('secret123');

        expect(service.verify('wrong', hash), isFalse);
      });

      test('returns false for invalid hash format', () {
        expect(service.verify('password', 'invalid'), isFalse);
      });
    });

    group('needsRehash', () {
      test('returns true when cost factor increased', () {
        final lowCostService = PasswordService(costFactor: 4);
        final hash = lowCostService.hash('password');

        final highCostService = PasswordService(costFactor: 10);
        expect(highCostService.needsRehash(hash), isTrue);
      });

      test('returns false when cost factor same or higher', () {
        final hash = service.hash('password');
        expect(service.needsRehash(hash), isFalse);
      });
    });
  });
}
```

---

## Unit Tests: JWT Service

```dart
// test/services/jwt_service_test.dart
import 'package:test/test.dart';
import 'package:my_api/services/jwt_service.dart';
import 'package:my_api/models/user.dart';

void main() {
  group('JwtService', () {
    late JwtService jwtService;
    late User testUser;

    setUp(() {
      jwtService = JwtService(
        secret: 'test-secret-key-that-is-at-least-32-characters',
        accessTokenDuration: const Duration(minutes: 15),
        refreshTokenDuration: const Duration(days: 7),
      );

      testUser = User(
        id: 1,
        email: 'test@example.com',
        passwordHash: 'hash',
        name: 'Test User',
        role: 'user',
      );
    });

    group('generateAccessToken', () {
      test('creates valid JWT', () {
        final token = jwtService.generateAccessToken(testUser);

        expect(token, isNotEmpty);
        expect(token.split('.').length, equals(3));
      });

      test('contains correct claims', () {
        final token = jwtService.generateAccessToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.userId, equals(1));
        expect(payload.email, equals('test@example.com'));
        expect(payload.role, equals('user'));
        expect(payload.isAccessToken, isTrue);
      });
    });

    group('generateRefreshToken', () {
      test('creates token with refresh type', () {
        final token = jwtService.generateRefreshToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.isRefreshToken, isTrue);
        expect(payload.userId, equals(1));
        expect(payload.email, isNull); // Minimal payload
      });
    });

    group('verifyToken', () {
      test('validates correct token', () {
        final token = jwtService.generateAccessToken(testUser);

        expect(() => jwtService.verifyToken(token), returnsNormally);
      });

      test('throws for invalid token', () {
        expect(
          () => jwtService.verifyToken('invalid.token.here'),
          throwsA(isA<InvalidTokenException>()),
        );
      });

      test('throws for expired token', () async {
        final shortLivedService = JwtService(
          secret: 'test-secret-key-that-is-at-least-32-characters',
          accessTokenDuration: const Duration(milliseconds: 1),
        );

        final token = shortLivedService.generateAccessToken(testUser);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(
          () => shortLivedService.verifyToken(token),
          throwsA(isA<TokenExpiredException>()),
        );
      });

      test('throws for wrong secret', () {
        final token = jwtService.generateAccessToken(testUser);

        final otherService = JwtService(
          secret: 'different-secret-key-that-is-also-32-chars',
        );

        expect(
          () => otherService.verifyToken(token),
          throwsA(isA<InvalidTokenException>()),
        );
      });
    });

    group('extractTokenFromHeader', () {
      test('extracts Bearer token', () {
        final token = jwtService.extractTokenFromHeader('Bearer abc123');
        expect(token, equals('abc123'));
      });

      test('returns null for missing header', () {
        expect(jwtService.extractTokenFromHeader(null), isNull);
      });

      test('returns null for wrong scheme', () {
        expect(jwtService.extractTokenFromHeader('Basic abc'), isNull);
      });
    });
  });
}
```

---

## Unit Tests: Auth Service

```dart
// test/services/auth_service_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

// Mocks
class MockUserRepository extends Mock implements UserRepository {}
class MockPasswordService extends Mock implements PasswordService {}
class MockJwtService extends Mock implements JwtService {}
class MockRefreshTokenRepository extends Mock implements RefreshTokenRepository {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockUserRepository userRepo;
    late MockPasswordService passwordService;
    late MockJwtService jwtService;
    late MockRefreshTokenRepository refreshTokenRepo;

    setUp(() {
      userRepo = MockUserRepository();
      passwordService = MockPasswordService();
      jwtService = MockJwtService();
      refreshTokenRepo = MockRefreshTokenRepository();

      authService = AuthService(
        userRepo,
        passwordService,
        jwtService,
        refreshTokenRepo,
      );
    });

    group('login', () {
      final testUser = User(
        id: 1,
        email: 'test@example.com',
        passwordHash: 'hashed',
        isActive: true,
      );

      test('returns tokens for valid credentials', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => testUser);
        when(() => passwordService.verify(any(), any()))
            .thenReturn(true);
        when(() => jwtService.generateTokenPair(any()))
            .thenReturn(TokenPair(
              accessToken: 'access',
              refreshToken: 'refresh',
              expiresIn: 900,
            ));
        when(() => jwtService.refreshTokenDuration)
            .thenReturn(const Duration(days: 7));
        when(() => refreshTokenRepo.create(any()))
            .thenAnswer((_) async {});

        final result = await authService.login(
          email: 'test@example.com',
          password: 'password',
        );

        expect(result.success, isTrue);
        expect(result.tokens, isNotNull);
        expect(result.user?.id, equals(1));
      });

      test('returns error for non-existent user', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => null);
        when(() => passwordService.hash(any()))
            .thenReturn('dummy'); // Timing attack prevention

        final result = await authService.login(
          email: 'nonexistent@example.com',
          password: 'password',
        );

        expect(result.success, isFalse);
        expect(result.statusCode, equals(401));
        expect(result.error, contains('Invalid credentials'));
      });

      test('returns error for wrong password', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => testUser);
        when(() => passwordService.verify(any(), any()))
            .thenReturn(false);

        final result = await authService.login(
          email: 'test@example.com',
          password: 'wrong',
        );

        expect(result.success, isFalse);
        expect(result.statusCode, equals(401));
      });

      test('returns error for inactive user', () async {
        final inactiveUser = User(
          id: 1,
          email: 'test@example.com',
          passwordHash: 'hashed',
          isActive: false,
        );

        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => inactiveUser);

        final result = await authService.login(
          email: 'test@example.com',
          password: 'password',
        );

        expect(result.success, isFalse);
        expect(result.statusCode, equals(403));
      });
    });

    group('refreshAccessToken', () {
      test('returns new tokens for valid refresh token', () async {
        final payload = JwtPayload(
          sub: '1',
          type: 'refresh',
        );

        when(() => jwtService.verifyToken(any()))
            .thenReturn(payload);
        when(() => refreshTokenRepo.findByToken(any()))
            .thenAnswer((_) async => RefreshTokenRecord(
              userId: 1,
              token: 'old-refresh',
              expiresAt: DateTime.now().add(const Duration(days: 1)),
            ));
        when(() => userRepo.findById(any()))
            .thenAnswer((_) async => User(
              id: 1,
              email: 'test@example.com',
              passwordHash: 'hash',
              isActive: true,
            ));
        when(() => refreshTokenRepo.revoke(any()))
            .thenAnswer((_) async {});
        when(() => jwtService.generateTokenPair(any()))
            .thenReturn(TokenPair(
              accessToken: 'new-access',
              refreshToken: 'new-refresh',
              expiresIn: 900,
            ));
        when(() => jwtService.refreshTokenDuration)
            .thenReturn(const Duration(days: 7));
        when(() => refreshTokenRepo.create(any()))
            .thenAnswer((_) async {});

        final tokens = await authService.refreshAccessToken('old-refresh');

        expect(tokens.accessToken, equals('new-access'));
        verify(() => refreshTokenRepo.revoke('old-refresh')).called(1);
      });

      test('throws for revoked token', () async {
        final payload = JwtPayload(sub: '1', type: 'refresh');

        when(() => jwtService.verifyToken(any()))
            .thenReturn(payload);
        when(() => refreshTokenRepo.findByToken(any()))
            .thenAnswer((_) async => null);

        expect(
          () => authService.refreshAccessToken('revoked-token'),
          throwsA(isA<RefreshTokenRevokedException>()),
        );
      });
    });
  });
}
```

---

## Integration Tests: Auth Handler

```dart
// test/handlers/auth_handler_test.dart
import 'dart:convert';
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void main() {
  group('AuthHandler Integration', () {
    late Handler handler;
    late TestDatabase testDb;

    setUpAll(() async {
      testDb = await TestDatabase.create();
      await testDb.migrate();

      final userRepo = PostgresUserRepository(testDb.connection);
      final passwordService = PasswordService(costFactor: 4);
      final jwtService = JwtService(secret: 'test-secret-32-chars-long-key');
      final refreshTokenRepo = RefreshTokenRepository(testDb.connection);
      final authService = AuthService(
        userRepo,
        passwordService,
        jwtService,
        refreshTokenRepo,
      );

      final authHandler = AuthHandler(authService);
      handler = authHandler.router;
    });

    tearDownAll(() async {
      await testDb.close();
    });

    setUp(() async {
      await testDb.truncate(['users', 'refresh_tokens']);
    });

    group('POST /register', () {
      test('creates user with valid data', () async {
        final request = _postRequest('/register', {
          'email': 'new@example.com',
          'password': 'SecurePass123!',
          'name': 'New User',
        });

        final response = await handler(request);
        final body = await _parseBody(response);

        expect(response.statusCode, equals(201));
        expect(body['user']['email'], equals('new@example.com'));
        expect(body['user']['name'], equals('New User'));
        expect(body['user'], isNot(contains('passwordHash')));
      });

      test('rejects weak password', () async {
        final request = _postRequest('/register', {
          'email': 'test@example.com',
          'password': 'weak',
        });

        final response = await handler(request);

        expect(response.statusCode, equals(400));
      });

      test('rejects duplicate email', () async {
        // Ersten User erstellen
        await handler(_postRequest('/register', {
          'email': 'existing@example.com',
          'password': 'SecurePass123!',
        }));

        // Duplikat versuchen
        final response = await handler(_postRequest('/register', {
          'email': 'existing@example.com',
          'password': 'AnotherPass123!',
        }));

        expect(response.statusCode, equals(409));
      });
    });

    group('POST /login', () {
      setUp(() async {
        // Test-User erstellen
        await handler(_postRequest('/register', {
          'email': 'user@example.com',
          'password': 'Password123!',
        }));
      });

      test('returns tokens for valid credentials', () async {
        final request = _postRequest('/login', {
          'email': 'user@example.com',
          'password': 'Password123!',
        });

        final response = await handler(request);
        final body = await _parseBody(response);

        expect(response.statusCode, equals(200));
        expect(body['access_token'], isNotEmpty);
        expect(body['refresh_token'], isNotEmpty);
        expect(body['expires_in'], isA<int>());
        expect(body['token_type'], equals('Bearer'));
      });

      test('rejects invalid password', () async {
        final request = _postRequest('/login', {
          'email': 'user@example.com',
          'password': 'WrongPassword',
        });

        final response = await handler(request);

        expect(response.statusCode, equals(401));
      });
    });

    group('POST /refresh', () {
      late String refreshToken;

      setUp(() async {
        await handler(_postRequest('/register', {
          'email': 'refresh@example.com',
          'password': 'Password123!',
        }));

        final loginResponse = await handler(_postRequest('/login', {
          'email': 'refresh@example.com',
          'password': 'Password123!',
        }));

        final body = await _parseBody(loginResponse);
        refreshToken = body['refresh_token'];
      });

      test('returns new tokens for valid refresh token', () async {
        final request = _postRequest('/refresh', {
          'refresh_token': refreshToken,
        });

        final response = await handler(request);
        final body = await _parseBody(response);

        expect(response.statusCode, equals(200));
        expect(body['access_token'], isNotEmpty);
        expect(body['refresh_token'], isNotEmpty);
        expect(body['refresh_token'], isNot(equals(refreshToken))); // Rotation
      });

      test('rejects reused refresh token', () async {
        // Ersten Refresh
        await handler(_postRequest('/refresh', {
          'refresh_token': refreshToken,
        }));

        // Zweiter Versuch mit gleichem Token
        final response = await handler(_postRequest('/refresh', {
          'refresh_token': refreshToken,
        }));

        expect(response.statusCode, equals(401));
      });
    });
  });
}

// Helper Funktionen
Request _postRequest(String path, Map<String, dynamic> body) {
  return Request(
    'POST',
    Uri.parse('http://localhost$path'),
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}

Future<Map<String, dynamic>> _parseBody(Response response) async {
  final body = await response.readAsString();
  return jsonDecode(body) as Map<String, dynamic>;
}
```

---

## Test-Fixtures

```dart
// test/fixtures/auth_fixtures.dart

class AuthFixtures {
  static User createUser({
    int? id,
    String? email,
    String? passwordHash,
    String? name,
    String role = 'user',
    bool isActive = true,
  }) {
    return User(
      id: id ?? 1,
      email: email ?? 'test@example.com',
      passwordHash: passwordHash ?? 'hashed_password',
      name: name ?? 'Test User',
      role: role,
      isActive: isActive,
    );
  }

  static User createAdmin({int? id, String? email}) {
    return createUser(
      id: id ?? 99,
      email: email ?? 'admin@example.com',
      role: 'admin',
    );
  }

  static TokenPair createTokenPair({
    String? accessToken,
    String? refreshToken,
    int expiresIn = 900,
  }) {
    return TokenPair(
      accessToken: accessToken ?? 'test-access-token',
      refreshToken: refreshToken ?? 'test-refresh-token',
      expiresIn: expiresIn,
    );
  }

  static JwtPayload createPayload({
    int userId = 1,
    String? email,
    String? role,
    String type = 'access',
  }) {
    return JwtPayload(
      sub: userId.toString(),
      email: email ?? 'test@example.com',
      role: role ?? 'user',
      type: type,
    );
  }

  static Request createAuthenticatedRequest(
    String method,
    String path, {
    String? accessToken,
    Map<String, dynamic>? body,
  }) {
    return Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        'authorization': 'Bearer ${accessToken ?? "test-token"}',
        if (body != null) 'content-type': 'application/json',
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }
}
```

---

## Mock Auth Middleware

```dart
// test/helpers/mock_auth_middleware.dart

/// Middleware für Tests die Auth simuliert
Middleware mockAuthMiddleware({
  int? userId,
  String? email,
  String? role,
  bool isAuthenticated = true,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (!isAuthenticated) {
        return innerHandler(request);
      }

      final payload = JwtPayload(
        sub: (userId ?? 1).toString(),
        email: email ?? 'test@example.com',
        role: role ?? 'user',
        type: 'access',
      );

      final updatedRequest = request.change(
        context: {
          ...request.context,
          'auth': payload,
          'userId': payload.userId,
          'userRole': payload.role,
        },
      );

      return innerHandler(updatedRequest);
    };
  };
}

// Verwendung in Tests:
test('protected endpoint works with auth', () async {
  final handler = const Pipeline()
      .addMiddleware(mockAuthMiddleware(userId: 1, role: 'admin'))
      .addHandler(protectedHandler);

  final response = await handler(Request('GET', Uri.parse('/protected')));
  expect(response.statusCode, equals(200));
});
```

---

## Test Database

```dart
// test/helpers/test_database.dart
import 'package:postgres/postgres.dart';

class TestDatabase {
  final Connection connection;

  TestDatabase._(this.connection);

  static Future<TestDatabase> create() async {
    final connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'test_db',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    return TestDatabase._(connection);
  }

  Future<void> migrate() async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) NOT NULL UNIQUE,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255),
        role VARCHAR(50) DEFAULT 'user',
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS refresh_tokens (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        token TEXT NOT NULL UNIQUE,
        expires_at TIMESTAMP NOT NULL,
        is_revoked BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT NOW()
      );
    ''');
  }

  Future<void> truncate(List<String> tables) async {
    for (final table in tables.reversed) {
      await connection.execute('TRUNCATE TABLE $table CASCADE');
    }
  }

  Future<void> close() async {
    await connection.close();
  }
}
```

---

## Zusammenfassung

| Test-Typ | Fokus | Tools |
|----------|-------|-------|
| **Unit Tests** | Einzelne Services | mocktail, test |
| **Integration** | Handler + Services | TestDatabase |
| **E2E** | Vollständige Flows | HTTP Client |
| **Fixtures** | Test-Daten | Helper Classes |
| **Mocks** | Dependencies | mocktail |

