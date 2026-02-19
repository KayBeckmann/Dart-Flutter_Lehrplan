# Übung 8.6: Testing der Auth-Schicht

## Ziel

Erstelle eine umfassende Test-Suite für die Auth-Komponenten.

---

## Vorbereitung

### Dependencies

```yaml
dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

### Test-Datenbank

```bash
# Test-Datenbank erstellen
docker exec -it postgres psql -U postgres -c "CREATE DATABASE test_db;"
```

---

## Aufgabe 1: Password Service Tests (15 min)

```dart
// test/services/password_service_test.dart

void main() {
  group('PasswordService', () {
    late PasswordService service;

    setUp(() {
      service = PasswordService(costFactor: 4); // Niedrig für schnelle Tests
    });

    group('hash', () {
      test('generates valid bcrypt hash', () {
        // TODO: Hash generieren und Format prüfen
      });

      test('generates different hashes for same password (salt)', () {
        // TODO: Zwei Hashes vergleichen
      });
    });

    group('verify', () {
      test('returns true for correct password', () {
        // TODO
      });

      test('returns false for wrong password', () {
        // TODO
      });

      test('handles invalid hash gracefully', () {
        // TODO: verify mit ungültigem Hash
      });
    });

    group('needsRehash', () {
      test('returns true when cost factor increased', () {
        // TODO: Mit verschiedenen Cost Factors testen
      });
    });
  });
}
```

---

## Aufgabe 2: JWT Service Tests (20 min)

```dart
// test/services/jwt_service_test.dart

void main() {
  group('JwtService', () {
    late JwtService jwtService;
    late User testUser;

    setUp(() {
      jwtService = JwtService(
        secret: 'test-secret-key-that-is-at-least-32-characters',
        accessTokenDuration: Duration(minutes: 15),
        refreshTokenDuration: Duration(days: 7),
      );

      testUser = User(
        id: 1,
        email: 'test@example.com',
        passwordHash: 'hash',
        name: 'Test',
        role: 'user',
      );
    });

    group('generateAccessToken', () {
      test('creates valid JWT format', () {
        // TODO: Token generieren, Format prüfen (3 Teile)
      });

      test('includes correct claims', () {
        // TODO: Token generieren, verifizieren, Claims prüfen
      });

      test('sets correct token type', () {
        // TODO: isAccessToken == true
      });
    });

    group('generateRefreshToken', () {
      test('creates token with minimal claims', () {
        // TODO: Nur sub und type, kein email/name
      });

      test('sets refresh token type', () {
        // TODO: isRefreshToken == true
      });
    });

    group('verifyToken', () {
      test('validates correct token', () {
        // TODO
      });

      test('throws InvalidTokenException for malformed token', () {
        // TODO
      });

      test('throws TokenExpiredException for expired token', () {
        // TODO: Token mit kurzer Duration generieren, warten
      });

      test('throws for token signed with different secret', () {
        // TODO
      });
    });

    group('generateTokenPair', () {
      test('returns both tokens', () {
        // TODO
      });

      test('sets correct expiresIn', () {
        // TODO: expiresIn entspricht accessTokenDuration
      });
    });

    group('extractTokenFromHeader', () {
      test('extracts Bearer token', () {
        // TODO
      });

      test('returns null for null header', () {
        // TODO
      });

      test('returns null for wrong scheme', () {
        // TODO: 'Basic xyz'
      });

      test('returns null for malformed header', () {
        // TODO: 'Bearer' ohne Token
      });
    });
  });
}
```

---

## Aufgabe 3: Auth Service Tests mit Mocks (25 min)

```dart
// test/services/auth_service_test.dart
import 'package:mocktail/mocktail.dart';

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
      test('returns tokens for valid credentials', () async {
        // TODO:
        // 1. Mocks konfigurieren
        // 2. login aufrufen
        // 3. Ergebnis prüfen
        // 4. Verify dass Methoden aufgerufen wurden
      });

      test('returns error for non-existent user', () async {
        // TODO: userRepo.findByEmail returns null
      });

      test('returns error for wrong password', () async {
        // TODO: passwordService.verify returns false
      });

      test('returns error for inactive user', () async {
        // TODO: User mit isActive=false
      });

      test('prevents timing attack on non-existent user', () async {
        // TODO: Verify dass passwordService.hash aufgerufen wird
        // auch wenn User nicht existiert
      });
    });

    group('refreshAccessToken', () {
      test('returns new tokens for valid refresh token', () async {
        // TODO
      });

      test('revokes old token (rotation)', () async {
        // TODO: verify refreshTokenRepo.revoke called
      });

      test('throws for access token', () async {
        // TODO: Token mit type='access' sollte fehlschlagen
      });

      test('throws for revoked token', () async {
        // TODO: refreshTokenRepo.findByToken returns null
      });

      test('throws for inactive user', () async {
        // TODO
      });
    });

    group('logout', () {
      test('revokes refresh token', () async {
        // TODO: verify refreshTokenRepo.revoke called
      });
    });
  });
}
```

---

## Aufgabe 4: Auth Middleware Tests (20 min)

```dart
// test/middleware/auth_middleware_test.dart

void main() {
  group('authMiddleware', () {
    late JwtService jwtService;
    late Handler testHandler;
    late int? capturedUserId;

    setUp(() {
      jwtService = JwtService(
        secret: 'test-secret-key-that-is-long-enough-32',
      );

      capturedUserId = null;

      final innerHandler = (Request request) {
        capturedUserId = getUserId(request);
        return Response.ok('OK');
      };

      testHandler = const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler(innerHandler);
    });

    test('rejects request without Authorization header', () async {
      // TODO
    });

    test('rejects request with invalid token', () async {
      // TODO
    });

    test('rejects request with expired token', () async {
      // TODO: Token mit abgelaufener Duration
    });

    test('rejects refresh token', () async {
      // TODO: Refresh Token sollte 401 geben
    });

    test('accepts valid access token', () async {
      // TODO
    });

    test('adds userId to context', () async {
      // TODO: capturedUserId prüfen
    });

    test('adds auth payload to context', () async {
      // TODO: getAuthPayload(request) prüfen
    });
  });
}
```

---

## Aufgabe 5: Role Middleware Tests (15 min)

```dart
// test/middleware/role_middleware_test.dart

void main() {
  group('requireRole', () {
    late JwtService jwtService;

    setUp(() {
      jwtService = JwtService(secret: 'test-secret-32-chars-long-key');
    });

    Handler createHandler(Role requiredRole) {
      return const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addMiddleware(requireRole(requiredRole))
          .addHandler((r) => Response.ok('OK'));
    }

    test('allows user with sufficient role', () async {
      // TODO: Admin-Token für admin-Route
    });

    test('rejects user with insufficient role', () async {
      // TODO: User-Token für admin-Route → 403
    });

    test('returns 401 without authentication', () async {
      // TODO: Kein Token → 401
    });

    test('respects role hierarchy', () async {
      // TODO: Superadmin kann Admin-Route nutzen
    });
  });

  group('requirePermission', () {
    test('allows user with required permission', () async {
      // TODO
    });

    test('rejects user without permission', () async {
      // TODO
    });

    test('superadmin has all permissions', () async {
      // TODO
    });
  });
}
```

---

## Aufgabe 6: Integration Tests (20 min)

```dart
// test/integration/auth_flow_test.dart

void main() {
  group('Auth Flow Integration', () {
    late TestDatabase testDb;
    late Handler handler;

    setUpAll(() async {
      testDb = await TestDatabase.create();
      await testDb.migrate();
      // Services und Handler aufsetzen...
    });

    tearDownAll(() async {
      await testDb.close();
    });

    setUp(() async {
      await testDb.truncate(['users', 'refresh_tokens']);
    });

    test('complete registration flow', () async {
      // TODO:
      // 1. POST /register
      // 2. Prüfen: 201, User-Daten in Response
      // 3. Prüfen: User in DB
    });

    test('complete login flow', () async {
      // TODO:
      // 1. User registrieren
      // 2. POST /login
      // 3. Prüfen: Tokens in Response
    });

    test('complete token refresh flow', () async {
      // TODO:
      // 1. Registrieren + Login
      // 2. POST /refresh mit refresh_token
      // 3. Prüfen: Neue Tokens
      // 4. Prüfen: Alter Token invalidiert
    });

    test('protected endpoint with valid token', () async {
      // TODO:
      // 1. Login
      // 2. GET /protected mit access_token
      // 3. Prüfen: 200 OK
    });

    test('protected endpoint without token', () async {
      // TODO: 401
    });

    test('protected endpoint with expired token', () async {
      // TODO: 401
    });
  });
}
```

---

## Aufgabe 7: Test Fixtures erstellen (10 min)

```dart
// test/fixtures/auth_fixtures.dart

class AuthFixtures {
  /// Test-User erstellen
  static User createUser({
    int? id,
    String? email,
    String role = 'user',
    bool isActive = true,
  }) {
    // TODO
  }

  /// Admin-User erstellen
  static User createAdmin({int? id}) {
    // TODO
  }

  /// Token-Paar erstellen
  static TokenPair createTokenPair() {
    // TODO
  }

  /// JWT Payload erstellen
  static JwtPayload createPayload({
    int userId = 1,
    String type = 'access',
    String role = 'user',
  }) {
    // TODO
  }

  /// Authenticated Request erstellen
  static Request createAuthRequest(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
  }) {
    // TODO
  }
}
```

---

## Aufgabe 8: Mock Auth Middleware (10 min)

```dart
// test/helpers/mock_auth.dart

/// Middleware die Auth simuliert ohne echten JWT
Middleware mockAuthMiddleware({
  int userId = 1,
  String email = 'test@example.com',
  String role = 'user',
}) {
  // TODO:
  // Payload erstellen und in Context setzen
  // Ohne echte Token-Validierung
}

/// Request mit Auth-Context erstellen
Request withAuth(
  Request request, {
  int userId = 1,
  String role = 'user',
}) {
  // TODO:
  // request.change mit Auth-Context
}
```

---

## Testen

```bash
# Alle Tests
dart test

# Nur Auth-Tests
dart test test/services/auth_service_test.dart

# Mit Coverage
dart test --coverage=coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## Abgabe-Checkliste

- [ ] PasswordService Tests (hash, verify, needsRehash)
- [ ] JwtService Tests (generate, verify, extract)
- [ ] AuthService Tests mit Mocks (login, refresh, logout)
- [ ] Auth Middleware Tests (Token-Validierung, Context)
- [ ] Role Middleware Tests (Hierarchie, Permissions)
- [ ] Integration Tests (vollständige Flows)
- [ ] Test Fixtures für User, Tokens
- [ ] Mock Auth Middleware für Handler-Tests
- [ ] Alle Tests grün

