# Lösung 8.6: Testing der Auth-Schicht

## Password Service Tests

```dart
// test/services/password_service_test.dart
import 'package:test/test.dart';
import 'package:my_api/services/password_service.dart';

void main() {
  group('PasswordService', () {
    late PasswordService service;

    setUp(() {
      service = PasswordService(costFactor: 4);
    });

    group('hash', () {
      test('generates valid bcrypt hash', () {
        final hash = service.hash('password123');

        expect(hash, startsWith(r'$2'));
        expect(hash.length, greaterThan(50));
        expect(hash.contains(r'$'), isTrue);
      });

      test('generates different hashes for same password (salt)', () {
        final hash1 = service.hash('samePassword');
        final hash2 = service.hash('samePassword');

        expect(hash1, isNot(equals(hash2)));

        // Aber beide sollten verifizierbar sein
        expect(service.verify('samePassword', hash1), isTrue);
        expect(service.verify('samePassword', hash2), isTrue);
      });

      test('hash contains cost factor', () {
        final serviceHighCost = PasswordService(costFactor: 10);
        final hash = serviceHighCost.hash('password');

        // Format: $2a$10$...
        expect(hash, contains(r'$10$'));
      });
    });

    group('verify', () {
      test('returns true for correct password', () {
        final hash = service.hash('correctPassword');
        expect(service.verify('correctPassword', hash), isTrue);
      });

      test('returns false for wrong password', () {
        final hash = service.hash('correctPassword');
        expect(service.verify('wrongPassword', hash), isFalse);
      });

      test('is case sensitive', () {
        final hash = service.hash('Password');
        expect(service.verify('password', hash), isFalse);
        expect(service.verify('PASSWORD', hash), isFalse);
      });

      test('handles invalid hash gracefully', () {
        expect(service.verify('password', 'invalid'), isFalse);
        expect(service.verify('password', ''), isFalse);
        expect(service.verify('password', 'short'), isFalse);
      });

      test('handles empty password', () {
        final hash = service.hash('');
        expect(service.verify('', hash), isTrue);
        expect(service.verify('something', hash), isFalse);
      });
    });

    group('needsRehash', () {
      test('returns true when cost factor increased', () {
        final lowCostService = PasswordService(costFactor: 4);
        final hash = lowCostService.hash('password');

        final highCostService = PasswordService(costFactor: 10);
        expect(highCostService.needsRehash(hash), isTrue);
      });

      test('returns false when cost factor same', () {
        final hash = service.hash('password');
        expect(service.needsRehash(hash), isFalse);
      });

      test('returns false when cost factor lower', () {
        final highCostService = PasswordService(costFactor: 10);
        final hash = highCostService.hash('password');

        final lowCostService = PasswordService(costFactor: 4);
        expect(lowCostService.needsRehash(hash), isFalse);
      });

      test('returns true for invalid hash', () {
        expect(service.needsRehash('invalid'), isTrue);
      });
    });
  });
}
```

---

## JWT Service Tests

```dart
// test/services/jwt_service_test.dart
import 'package:test/test.dart';
import 'package:my_api/services/jwt_service.dart';
import 'package:my_api/models/user.dart';
import 'package:my_api/exceptions/auth_exceptions.dart';

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
        id: 42,
        email: 'test@example.com',
        passwordHash: 'hash',
        name: 'Test User',
        role: 'moderator',
      );
    });

    group('generateAccessToken', () {
      test('creates valid JWT format', () {
        final token = jwtService.generateAccessToken(testUser);
        final parts = token.split('.');

        expect(parts.length, equals(3));
        expect(parts[0], isNotEmpty); // Header
        expect(parts[1], isNotEmpty); // Payload
        expect(parts[2], isNotEmpty); // Signature
      });

      test('includes correct claims', () {
        final token = jwtService.generateAccessToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.userId, equals(42));
        expect(payload.email, equals('test@example.com'));
        expect(payload.name, equals('Test User'));
        expect(payload.role, equals('moderator'));
      });

      test('sets correct token type', () {
        final token = jwtService.generateAccessToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.isAccessToken, isTrue);
        expect(payload.isRefreshToken, isFalse);
      });
    });

    group('generateRefreshToken', () {
      test('creates token with minimal claims', () {
        final token = jwtService.generateRefreshToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.userId, equals(42));
        expect(payload.email, isNull);
        expect(payload.name, isNull);
      });

      test('sets refresh token type', () {
        final token = jwtService.generateRefreshToken(testUser);
        final payload = jwtService.verifyToken(token);

        expect(payload.isRefreshToken, isTrue);
        expect(payload.isAccessToken, isFalse);
      });
    });

    group('verifyToken', () {
      test('validates correct token', () {
        final token = jwtService.generateAccessToken(testUser);

        expect(() => jwtService.verifyToken(token), returnsNormally);
      });

      test('throws InvalidTokenException for malformed token', () {
        expect(
          () => jwtService.verifyToken('not.a.valid.token'),
          throwsA(isA<InvalidTokenException>()),
        );

        expect(
          () => jwtService.verifyToken(''),
          throwsA(isA<InvalidTokenException>()),
        );

        expect(
          () => jwtService.verifyToken('abc'),
          throwsA(isA<InvalidTokenException>()),
        );
      });

      test('throws TokenExpiredException for expired token', () async {
        final shortLivedService = JwtService(
          secret: 'test-secret-key-that-is-at-least-32-characters',
          accessTokenDuration: const Duration(milliseconds: 1),
        );

        final token = shortLivedService.generateAccessToken(testUser);

        // Warten bis Token abläuft
        await Future.delayed(const Duration(milliseconds: 50));

        expect(
          () => shortLivedService.verifyToken(token),
          throwsA(isA<TokenExpiredException>()),
        );
      });

      test('throws for token signed with different secret', () {
        final token = jwtService.generateAccessToken(testUser);

        final otherService = JwtService(
          secret: 'different-secret-that-is-also-32-characters',
        );

        expect(
          () => otherService.verifyToken(token),
          throwsA(isA<InvalidTokenException>()),
        );
      });
    });

    group('generateTokenPair', () {
      test('returns both tokens', () {
        final pair = jwtService.generateTokenPair(testUser);

        expect(pair.accessToken, isNotEmpty);
        expect(pair.refreshToken, isNotEmpty);
        expect(pair.accessToken, isNot(equals(pair.refreshToken)));
      });

      test('sets correct expiresIn', () {
        final pair = jwtService.generateTokenPair(testUser);

        expect(pair.expiresIn, equals(15 * 60)); // 15 Minuten in Sekunden
      });

      test('access token is verifiable', () {
        final pair = jwtService.generateTokenPair(testUser);
        final payload = jwtService.verifyToken(pair.accessToken);

        expect(payload.isAccessToken, isTrue);
      });

      test('refresh token is verifiable', () {
        final pair = jwtService.generateTokenPair(testUser);
        final payload = jwtService.verifyToken(pair.refreshToken);

        expect(payload.isRefreshToken, isTrue);
      });
    });

    group('extractTokenFromHeader', () {
      test('extracts Bearer token', () {
        final token = jwtService.extractTokenFromHeader('Bearer abc123xyz');
        expect(token, equals('abc123xyz'));
      });

      test('handles real JWT', () {
        final realToken = jwtService.generateAccessToken(testUser);
        final extracted = jwtService.extractTokenFromHeader('Bearer $realToken');
        expect(extracted, equals(realToken));
      });

      test('returns null for null header', () {
        expect(jwtService.extractTokenFromHeader(null), isNull);
      });

      test('returns null for empty header', () {
        expect(jwtService.extractTokenFromHeader(''), isNull);
      });

      test('returns null for wrong scheme', () {
        expect(jwtService.extractTokenFromHeader('Basic abc'), isNull);
        expect(jwtService.extractTokenFromHeader('Token abc'), isNull);
      });

      test('returns null for malformed header', () {
        expect(jwtService.extractTokenFromHeader('Bearer'), isNull);
        expect(jwtService.extractTokenFromHeader('Bearer '), isNull);
      });

      test('is case sensitive for scheme', () {
        expect(jwtService.extractTokenFromHeader('bearer abc'), isNull);
        expect(jwtService.extractTokenFromHeader('BEARER abc'), isNull);
      });
    });
  });
}
```

---

## Auth Service Tests mit Mocks

```dart
// test/services/auth_service_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockPasswordService extends Mock implements PasswordService {}
class MockJwtService extends Mock implements JwtService {}
class MockRefreshTokenRepository extends Mock implements RefreshTokenRepository {}

class FakeUser extends Fake implements User {}
class FakeRefreshTokenRecord extends Fake implements RefreshTokenRecord {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUser());
    registerFallbackValue(FakeRefreshTokenRecord());
  });

  group('AuthService', () {
    late AuthService authService;
    late MockUserRepository userRepo;
    late MockPasswordService passwordService;
    late MockJwtService jwtService;
    late MockRefreshTokenRepository refreshTokenRepo;

    final testUser = User(
      id: 1,
      email: 'test@example.com',
      passwordHash: 'hashed_password',
      name: 'Test',
      role: 'user',
      isActive: true,
    );

    final testTokenPair = TokenPair(
      accessToken: 'access_token',
      refreshToken: 'refresh_token',
      expiresIn: 900,
    );

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

      // Default Mocks
      when(() => jwtService.refreshTokenDuration)
          .thenReturn(const Duration(days: 7));
    });

    group('login', () {
      test('returns tokens for valid credentials', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => testUser);
        when(() => passwordService.verify(any(), any()))
            .thenReturn(true);
        when(() => jwtService.generateTokenPair(any()))
            .thenReturn(testTokenPair);
        when(() => refreshTokenRepo.create(any()))
            .thenAnswer((_) async {});

        final result = await authService.login(
          email: 'test@example.com',
          password: 'password123',
        );

        expect(result.success, isTrue);
        expect(result.tokens?.accessToken, equals('access_token'));
        expect(result.user?.id, equals(1));

        verify(() => userRepo.findByEmail('test@example.com')).called(1);
        verify(() => passwordService.verify('password123', 'hashed_password')).called(1);
        verify(() => refreshTokenRepo.create(any())).called(1);
      });

      test('returns error for non-existent user', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => null);
        when(() => passwordService.hash(any()))
            .thenReturn('dummy_hash');

        final result = await authService.login(
          email: 'nonexistent@example.com',
          password: 'password',
        );

        expect(result.success, isFalse);
        expect(result.statusCode, equals(401));
        expect(result.error, contains('Invalid credentials'));
      });

      test('prevents timing attack on non-existent user', () async {
        when(() => userRepo.findByEmail(any()))
            .thenAnswer((_) async => null);
        when(() => passwordService.hash(any()))
            .thenReturn('dummy');

        await authService.login(
          email: 'nonexistent@example.com',
          password: 'password',
        );

        // Verify hash wird aufgerufen auch bei nicht-existentem User
        verify(() => passwordService.hash(any())).called(1);
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
          passwordHash: 'hash',
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
        final payload = JwtPayload(sub: '1', type: 'refresh');

        when(() => jwtService.verifyToken(any()))
            .thenReturn(payload);
        when(() => refreshTokenRepo.findByToken(any()))
            .thenAnswer((_) async => RefreshTokenRecord(
                  userId: 1,
                  token: 'old_refresh',
                  expiresAt: DateTime.now().add(const Duration(days: 1)),
                ));
        when(() => userRepo.findById(any()))
            .thenAnswer((_) async => testUser);
        when(() => refreshTokenRepo.revoke(any()))
            .thenAnswer((_) async {});
        when(() => jwtService.generateTokenPair(any()))
            .thenReturn(testTokenPair);
        when(() => refreshTokenRepo.create(any()))
            .thenAnswer((_) async {});

        final tokens = await authService.refreshAccessToken('old_refresh');

        expect(tokens.accessToken, equals('access_token'));
        verify(() => refreshTokenRepo.revoke('old_refresh')).called(1);
      });

      test('throws for access token', () async {
        final payload = JwtPayload(sub: '1', type: 'access');

        when(() => jwtService.verifyToken(any()))
            .thenReturn(payload);

        expect(
          () => authService.refreshAccessToken('access_token'),
          throwsA(isA<TokenTypeMismatchException>()),
        );
      });

      test('throws for revoked token', () async {
        final payload = JwtPayload(sub: '1', type: 'refresh');

        when(() => jwtService.verifyToken(any()))
            .thenReturn(payload);
        when(() => refreshTokenRepo.findByToken(any()))
            .thenAnswer((_) async => null);

        expect(
          () => authService.refreshAccessToken('revoked'),
          throwsA(isA<RefreshTokenRevokedException>()),
        );
      });
    });

    group('logout', () {
      test('revokes refresh token', () async {
        when(() => refreshTokenRepo.revoke(any()))
            .thenAnswer((_) async {});

        await authService.logout('refresh_token');

        verify(() => refreshTokenRepo.revoke('refresh_token')).called(1);
      });
    });

    group('logoutAllSessions', () {
      test('revokes all user tokens', () async {
        when(() => refreshTokenRepo.revokeAllForUser(any()))
            .thenAnswer((_) async {});

        await authService.logoutAllSessions(1);

        verify(() => refreshTokenRepo.revokeAllForUser(1)).called(1);
      });
    });
  });
}
```

---

## Auth Middleware Tests

```dart
// test/middleware/auth_middleware_test.dart
import 'package:test/test.dart';
import 'package:shelf/shelf.dart';

void main() {
  group('authMiddleware', () {
    late JwtService jwtService;
    late User testUser;
    late int? capturedUserId;
    late JwtPayload? capturedPayload;

    setUp(() {
      jwtService = JwtService(
        secret: 'test-secret-key-that-is-long-enough-32',
      );

      testUser = User(
        id: 123,
        email: 'test@example.com',
        passwordHash: 'hash',
        role: 'admin',
      );

      capturedUserId = null;
      capturedPayload = null;
    });

    Handler createHandler() {
      return const Pipeline()
          .addMiddleware(authMiddleware(jwtService))
          .addHandler((Request request) {
            capturedUserId = getUserId(request);
            capturedPayload = getAuthPayload(request);
            return Response.ok('OK');
          });
    }

    test('rejects request without Authorization header', () async {
      final handler = createHandler();
      final request = Request('GET', Uri.parse('http://localhost/test'));

      final response = await handler(request);

      expect(response.statusCode, equals(401));
    });

    test('rejects request with invalid token', () async {
      final handler = createHandler();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer invalid-token'},
      );

      final response = await handler(request);

      expect(response.statusCode, equals(401));
    });

    test('rejects refresh token', () async {
      final refreshToken = jwtService.generateRefreshToken(testUser);
      final handler = createHandler();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $refreshToken'},
      );

      final response = await handler(request);

      expect(response.statusCode, equals(401));
    });

    test('accepts valid access token', () async {
      final accessToken = jwtService.generateAccessToken(testUser);
      final handler = createHandler();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $accessToken'},
      );

      final response = await handler(request);

      expect(response.statusCode, equals(200));
    });

    test('adds userId to context', () async {
      final accessToken = jwtService.generateAccessToken(testUser);
      final handler = createHandler();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $accessToken'},
      );

      await handler(request);

      expect(capturedUserId, equals(123));
    });

    test('adds auth payload to context', () async {
      final accessToken = jwtService.generateAccessToken(testUser);
      final handler = createHandler();
      final request = Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {'authorization': 'Bearer $accessToken'},
      );

      await handler(request);

      expect(capturedPayload, isNotNull);
      expect(capturedPayload!.userId, equals(123));
      expect(capturedPayload!.email, equals('test@example.com'));
      expect(capturedPayload!.role, equals('admin'));
    });
  });
}
```

---

## Test Fixtures

```dart
// test/fixtures/auth_fixtures.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

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
      email: email ?? 'test${id ?? 1}@example.com',
      passwordHash: passwordHash ?? 'hashed_password',
      name: name ?? 'Test User ${id ?? 1}',
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

  static User createSuperadmin({int? id}) {
    return createUser(
      id: id ?? 100,
      email: 'superadmin@example.com',
      role: 'superadmin',
    );
  }

  static TokenPair createTokenPair({
    String? accessToken,
    String? refreshToken,
    int expiresIn = 900,
  }) {
    return TokenPair(
      accessToken: accessToken ?? 'test-access-token-${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: refreshToken ?? 'test-refresh-token-${DateTime.now().millisecondsSinceEpoch}',
      expiresIn: expiresIn,
    );
  }

  static JwtPayload createPayload({
    int userId = 1,
    String? email,
    String? name,
    String role = 'user',
    String type = 'access',
  }) {
    return JwtPayload(
      sub: userId.toString(),
      email: email ?? 'test@example.com',
      name: name,
      role: role,
      type: type,
    );
  }

  static Request createAuthRequest(
    String method,
    String path, {
    String? token,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    return Request(
      method,
      Uri.parse('http://localhost$path'),
      headers: {
        if (token != null) 'authorization': 'Bearer $token',
        if (body != null) 'content-type': 'application/json',
        ...?headers,
      },
      body: body != null ? jsonEncode(body) : null,
    );
  }

  static Request createPostRequest(String path, Map<String, dynamic> body) {
    return Request(
      'POST',
      Uri.parse('http://localhost$path'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
```

---

## Mock Auth Middleware

```dart
// test/helpers/mock_auth.dart
import 'package:shelf/shelf.dart';

/// Middleware die Auth simuliert ohne echten JWT
Middleware mockAuthMiddleware({
  int userId = 1,
  String email = 'test@example.com',
  String? name,
  String role = 'user',
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      final payload = JwtPayload(
        sub: userId.toString(),
        email: email,
        name: name,
        role: role,
        type: 'access',
      );

      final updatedRequest = request.change(
        context: {
          ...request.context,
          'auth': payload,
          'userId': userId,
          'userRole': role,
        },
      );

      return innerHandler(updatedRequest);
    };
  };
}

/// Request mit Auth-Context erweitern
Request withAuth(
  Request request, {
  int userId = 1,
  String email = 'test@example.com',
  String role = 'user',
}) {
  final payload = JwtPayload(
    sub: userId.toString(),
    email: email,
    role: role,
    type: 'access',
  );

  return request.change(
    context: {
      ...request.context,
      'auth': payload,
      'userId': userId,
      'userRole': role,
    },
  );
}

/// Middleware die immer 401 zurückgibt
Middleware denyAuthMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      return Response(401, body: '{"error": "Unauthorized"}');
    };
  };
}
```

