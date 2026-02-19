# Lösung 8.2: JWT-Authentifizierung

## JWT Payload Model

```dart
// lib/models/jwt_payload.dart

class JwtPayload {
  final String sub;
  final String? email;
  final String? name;
  final String? role;
  final String type;
  final DateTime? expiresAt;
  final DateTime? issuedAt;

  JwtPayload({
    required this.sub,
    this.email,
    this.name,
    this.role,
    required this.type,
    this.expiresAt,
    this.issuedAt,
  });

  int get userId => int.parse(sub);

  bool get isAccessToken => type == 'access';
  bool get isRefreshToken => type == 'refresh';

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  factory JwtPayload.fromJwtPayload(Map<String, dynamic> payload) {
    return JwtPayload(
      sub: payload['sub'] as String,
      email: payload['email'] as String?,
      name: payload['name'] as String?,
      role: payload['role'] as String?,
      type: payload['type'] as String? ?? 'access',
      expiresAt: payload['exp'] != null
          ? DateTime.fromMillisecondsSinceEpoch((payload['exp'] as int) * 1000)
          : null,
      issuedAt: payload['iat'] != null
          ? DateTime.fromMillisecondsSinceEpoch((payload['iat'] as int) * 1000)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'sub': sub,
        if (email != null) 'email': email,
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        'type': type,
      };
}
```

---

## Token Pair Model

```dart
// lib/models/token_pair.dart

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'token_type': 'Bearer',
      };

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    return TokenPair(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}
```

---

## Exceptions

```dart
// lib/exceptions/auth_exceptions.dart

class TokenExpiredException implements Exception {
  final String message;
  TokenExpiredException([this.message = 'Token has expired']);

  @override
  String toString() => message;
}

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException([this.message = 'Invalid token']);

  @override
  String toString() => message;
}

class RefreshTokenRevokedException implements Exception {
  final String message;
  RefreshTokenRevokedException([this.message = 'Refresh token has been revoked']);

  @override
  String toString() => message;
}

class TokenTypeMismatchException implements Exception {
  final String expected;
  final String actual;

  TokenTypeMismatchException(this.expected, this.actual);

  String get message => 'Expected $expected token, got $actual';

  @override
  String toString() => message;
}
```

---

## JWT Service

```dart
// lib/services/jwt_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/user.dart';
import '../models/jwt_payload.dart';
import '../models/token_pair.dart';
import '../exceptions/auth_exceptions.dart';

class JwtService {
  final String _secret;
  final String _issuer;
  final Duration _accessTokenDuration;
  final Duration _refreshTokenDuration;

  JwtService({
    required String secret,
    String issuer = 'my-api',
    Duration? accessTokenDuration,
    Duration? refreshTokenDuration,
  })  : _secret = secret,
        _issuer = issuer,
        _accessTokenDuration = accessTokenDuration ?? const Duration(minutes: 15),
        _refreshTokenDuration = refreshTokenDuration ?? const Duration(days: 7);

  Duration get accessTokenDuration => _accessTokenDuration;
  Duration get refreshTokenDuration => _refreshTokenDuration;

  /// Generiere Access Token für User
  String generateAccessToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'type': 'access',
      },
      issuer: _issuer,
      subject: user.id.toString(),
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: _accessTokenDuration,
    );
  }

  /// Generiere Refresh Token für User
  String generateRefreshToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'type': 'refresh',
      },
      issuer: _issuer,
      subject: user.id.toString(),
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: _refreshTokenDuration,
    );
  }

  /// Generiere Token-Paar
  TokenPair generateTokenPair(User user) {
    return TokenPair(
      accessToken: generateAccessToken(user),
      refreshToken: generateRefreshToken(user),
      expiresIn: _accessTokenDuration.inSeconds,
    );
  }

  /// Verifiziere und dekodiere Token
  JwtPayload verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));
      final payload = jwt.payload as Map<String, dynamic>;
      return JwtPayload.fromJwtPayload(payload);
    } on JWTExpiredException {
      throw TokenExpiredException();
    } on JWTInvalidException catch (e) {
      throw InvalidTokenException('Invalid token: ${e.message}');
    } on JWTException catch (e) {
      throw InvalidTokenException('Token error: ${e.message}');
    }
  }

  /// Prüfen ob Token gültig ist (ohne Exception)
  bool isValid(String token) {
    try {
      verifyToken(token);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dekodiere Token ohne Verifizierung (nur für Debugging!)
  Map<String, dynamic>? decodeWithoutVerification(String token) {
    try {
      final jwt = JWT.decode(token);
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Extrahiere Token aus Authorization Header
  String? extractTokenFromHeader(String? authHeader) {
    if (authHeader == null) return null;
    if (!authHeader.startsWith('Bearer ')) return null;
    return authHeader.substring(7);
  }
}
```

---

## Refresh Token Repository

```dart
// lib/repositories/refresh_token_repository.dart
import 'package:postgres/postgres.dart';

class RefreshTokenRecord {
  final int? id;
  final int userId;
  final String token;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isRevoked;

  RefreshTokenRecord({
    this.id,
    required this.userId,
    required this.token,
    DateTime? createdAt,
    required this.expiresAt,
    this.isRevoked = false,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RefreshTokenRecord.fromRow(Map<String, dynamic> row) {
    return RefreshTokenRecord(
      id: row['id'] as int,
      userId: row['user_id'] as int,
      token: row['token'] as String,
      createdAt: row['created_at'] as DateTime,
      expiresAt: row['expires_at'] as DateTime,
      isRevoked: row['is_revoked'] as bool,
    );
  }
}

class RefreshTokenRepository {
  final Connection _db;

  RefreshTokenRepository(this._db);

  Future<void> create(RefreshTokenRecord record) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO refresh_tokens (user_id, token, expires_at, is_revoked)
        VALUES (@userId, @token, @expiresAt, @isRevoked)
      '''),
      parameters: {
        'userId': record.userId,
        'token': record.token,
        'expiresAt': record.expiresAt,
        'isRevoked': record.isRevoked,
      },
    );
  }

  Future<RefreshTokenRecord?> findByToken(String token) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM refresh_tokens
        WHERE token = @token AND is_revoked = false AND expires_at > NOW()
      '''),
      parameters: {'token': token},
    );

    if (result.isEmpty) return null;
    return RefreshTokenRecord.fromRow(result.first.toColumnMap());
  }

  Future<void> revoke(String token) async {
    await _db.execute(
      Sql.named('''
        UPDATE refresh_tokens
        SET is_revoked = true
        WHERE token = @token
      '''),
      parameters: {'token': token},
    );
  }

  Future<void> revokeAllForUser(int userId) async {
    await _db.execute(
      Sql.named('''
        UPDATE refresh_tokens
        SET is_revoked = true
        WHERE user_id = @userId AND is_revoked = false
      '''),
      parameters: {'userId': userId},
    );
  }

  Future<int> deleteExpired() async {
    final result = await _db.execute(
      Sql.named('''
        DELETE FROM refresh_tokens
        WHERE expires_at < NOW() OR is_revoked = true
        RETURNING id
      '''),
    );
    return result.length;
  }

  Future<List<RefreshTokenRecord>> findActiveByUser(int userId) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM refresh_tokens
        WHERE user_id = @userId AND is_revoked = false AND expires_at > NOW()
        ORDER BY created_at DESC
      '''),
      parameters: {'userId': userId},
    );

    return result.map((row) => RefreshTokenRecord.fromRow(row.toColumnMap())).toList();
  }
}
```

---

## Auth Service (erweitert)

```dart
// lib/services/auth_service.dart
import '../models/user.dart';
import '../models/token_pair.dart';
import '../repositories/user_repository.dart';
import '../repositories/refresh_token_repository.dart';
import 'password_service.dart';
import 'jwt_service.dart';
import '../exceptions/auth_exceptions.dart';

class AuthResult {
  final bool success;
  final User? user;
  final TokenPair? tokens;
  final String? error;
  final int statusCode;

  AuthResult.success(this.user, {this.tokens})
      : success = true,
        error = null,
        statusCode = 200;

  AuthResult.failure(this.error, {this.statusCode = 400})
      : success = false,
        user = null,
        tokens = null;
}

class AuthService {
  final UserRepository _userRepo;
  final PasswordService _passwordService;
  final JwtService _jwtService;
  final RefreshTokenRepository _refreshTokenRepo;

  AuthService(
    this._userRepo,
    this._passwordService,
    this._jwtService,
    this._refreshTokenRepo,
  );

  /// Login mit Token-Generierung
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // 1. User finden
    final user = await _userRepo.findByEmail(email.toLowerCase().trim());

    if (user == null) {
      // Timing-Attack verhindern
      _passwordService.hash('dummy_password');
      return AuthResult.failure('Invalid credentials', statusCode: 401);
    }

    // 2. Account aktiv?
    if (!user.isActive) {
      return AuthResult.failure('Account is deactivated', statusCode: 403);
    }

    // 3. Passwort prüfen
    if (!_passwordService.verify(password, user.passwordHash)) {
      return AuthResult.failure('Invalid credentials', statusCode: 401);
    }

    // 4. Token-Paar generieren
    final tokenPair = _jwtService.generateTokenPair(user);

    // 5. Refresh Token speichern
    await _refreshTokenRepo.create(RefreshTokenRecord(
      userId: user.id!,
      token: tokenPair.refreshToken,
      expiresAt: DateTime.now().add(_jwtService.refreshTokenDuration),
    ));

    return AuthResult.success(user, tokens: tokenPair);
  }

  /// Access Token erneuern
  Future<TokenPair> refreshAccessToken(String refreshToken) async {
    // 1. Token verifizieren
    JwtPayload payload;
    try {
      payload = _jwtService.verifyToken(refreshToken);
    } on TokenExpiredException {
      throw TokenExpiredException('Refresh token has expired');
    }

    // 2. Prüfen ob es ein Refresh Token ist
    if (!payload.isRefreshToken) {
      throw TokenTypeMismatchException('refresh', payload.type);
    }

    // 3. In DB prüfen
    final record = await _refreshTokenRepo.findByToken(refreshToken);
    if (record == null) {
      throw RefreshTokenRevokedException();
    }

    // 4. User laden
    final user = await _userRepo.findById(payload.userId);
    if (user == null) {
      throw InvalidTokenException('User not found');
    }

    if (!user.isActive) {
      throw InvalidTokenException('User account is deactivated');
    }

    // 5. Alten Token revoken (Token Rotation)
    await _refreshTokenRepo.revoke(refreshToken);

    // 6. Neues Token-Paar generieren
    final newTokenPair = _jwtService.generateTokenPair(user);

    // 7. Neuen Refresh Token speichern
    await _refreshTokenRepo.create(RefreshTokenRecord(
      userId: user.id!,
      token: newTokenPair.refreshToken,
      expiresAt: DateTime.now().add(_jwtService.refreshTokenDuration),
    ));

    return newTokenPair;
  }

  /// Logout - Refresh Token invalidieren
  Future<void> logout(String refreshToken) async {
    await _refreshTokenRepo.revoke(refreshToken);
  }

  /// Alle Sessions beenden
  Future<void> logoutAllSessions(int userId) async {
    await _refreshTokenRepo.revokeAllForUser(userId);
  }

  /// Token aus Header verifizieren und User zurückgeben
  Future<User?> getUserFromToken(String? authHeader) async {
    final token = _jwtService.extractTokenFromHeader(authHeader);
    if (token == null) return null;

    try {
      final payload = _jwtService.verifyToken(token);
      if (!payload.isAccessToken) return null;

      return await _userRepo.findById(payload.userId);
    } catch (e) {
      return null;
    }
  }
}
```

---

## Auth Handler (erweitert)

```dart
// lib/handlers/auth_handler.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../services/auth_service.dart';
import '../exceptions/auth_exceptions.dart';

class AuthHandler {
  final AuthService _authService;

  AuthHandler(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refresh);
    router.post('/logout', _logout);

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

      // Hier würde register aufgerufen (aus Einheit 8.1)
      // final result = await _authService.register(...);

      return _jsonResponse(
        {'message': 'Registration not implemented in this example'},
        statusCode: 501,
      );
    } catch (e) {
      return _jsonResponse({'error': 'Registration failed'}, statusCode: 500);
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

      final result = await _authService.login(
        email: email,
        password: password,
      );

      if (result.success) {
        return _jsonResponse({
          'message': 'Login successful',
          'user': result.user!.toPublicJson(),
          ...result.tokens!.toJson(),
        });
      }

      return _jsonResponse(
        {'error': result.error},
        statusCode: result.statusCode,
      );
    } on FormatException {
      return _jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
    } catch (e) {
      return _jsonResponse({'error': 'Login failed'}, statusCode: 500);
    }
  }

  Future<Response> _refresh(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final refreshToken = data['refresh_token'] as String?;

      if (refreshToken == null) {
        return _jsonResponse(
          {'error': 'Refresh token is required'},
          statusCode: 400,
        );
      }

      final newTokens = await _authService.refreshAccessToken(refreshToken);

      return _jsonResponse(newTokens.toJson());
    } on TokenExpiredException catch (e) {
      return _jsonResponse({'error': e.message}, statusCode: 401);
    } on RefreshTokenRevokedException catch (e) {
      return _jsonResponse({'error': e.message}, statusCode: 401);
    } on TokenTypeMismatchException catch (e) {
      return _jsonResponse({'error': e.message}, statusCode: 400);
    } on InvalidTokenException catch (e) {
      return _jsonResponse({'error': e.message}, statusCode: 401);
    } on FormatException {
      return _jsonResponse({'error': 'Invalid JSON'}, statusCode: 400);
    } catch (e) {
      return _jsonResponse({'error': 'Token refresh failed'}, statusCode: 500);
    }
  }

  Future<Response> _logout(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final refreshToken = data['refresh_token'] as String?;

      if (refreshToken != null) {
        await _authService.logout(refreshToken);
      }

      return _jsonResponse({'message': 'Logged out successfully'});
    } catch (e) {
      // Logout sollte nie fehlschlagen aus User-Perspektive
      return _jsonResponse({'message': 'Logged out'});
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

## JWT Config

```dart
// lib/config/jwt_config.dart
import 'dart:io';

class JwtConfig {
  final String secret;
  final String issuer;
  final Duration accessTokenDuration;
  final Duration refreshTokenDuration;

  JwtConfig({
    required this.secret,
    this.issuer = 'my-api',
    this.accessTokenDuration = const Duration(minutes: 15),
    this.refreshTokenDuration = const Duration(days: 7),
  });

  factory JwtConfig.fromEnvironment() {
    final secret = Platform.environment['JWT_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_SECRET environment variable is not set');
    }

    if (secret.length < 32) {
      throw Exception('JWT_SECRET must be at least 32 characters');
    }

    return JwtConfig(
      secret: secret,
      issuer: Platform.environment['JWT_ISSUER'] ?? 'my-api',
      accessTokenDuration: Duration(
        minutes: int.parse(
          Platform.environment['JWT_ACCESS_DURATION_MINUTES'] ?? '15',
        ),
      ),
      refreshTokenDuration: Duration(
        days: int.parse(
          Platform.environment['JWT_REFRESH_DURATION_DAYS'] ?? '7',
        ),
      ),
    );
  }
}
```

---

## Unit Tests

```dart
// test/jwt_service_test.dart
import 'package:test/test.dart';
import '../lib/services/jwt_service.dart';
import '../lib/models/user.dart';

void main() {
  group('JwtService', () {
    late JwtService jwtService;
    late User testUser;

    setUp(() {
      jwtService = JwtService(
        secret: 'test-secret-key-that-is-at-least-32-characters-long',
        issuer: 'test-api',
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

    test('generateAccessToken creates valid token', () {
      final token = jwtService.generateAccessToken(testUser);

      expect(token, isNotEmpty);
      expect(token.split('.').length, equals(3)); // JWT has 3 parts
    });

    test('generateRefreshToken creates valid token', () {
      final token = jwtService.generateRefreshToken(testUser);

      expect(token, isNotEmpty);
    });

    test('verifyToken returns correct payload for access token', () {
      final token = jwtService.generateAccessToken(testUser);
      final payload = jwtService.verifyToken(token);

      expect(payload.userId, equals(1));
      expect(payload.email, equals('test@example.com'));
      expect(payload.isAccessToken, isTrue);
      expect(payload.isRefreshToken, isFalse);
    });

    test('verifyToken returns correct payload for refresh token', () {
      final token = jwtService.generateRefreshToken(testUser);
      final payload = jwtService.verifyToken(token);

      expect(payload.userId, equals(1));
      expect(payload.isRefreshToken, isTrue);
      expect(payload.isAccessToken, isFalse);
    });

    test('verifyToken throws for invalid token', () {
      expect(
        () => jwtService.verifyToken('invalid.token.here'),
        throwsA(isA<InvalidTokenException>()),
      );
    });

    test('generateTokenPair returns both tokens', () {
      final tokenPair = jwtService.generateTokenPair(testUser);

      expect(tokenPair.accessToken, isNotEmpty);
      expect(tokenPair.refreshToken, isNotEmpty);
      expect(tokenPair.expiresIn, equals(900)); // 15 min in seconds
    });

    test('extractTokenFromHeader parses Bearer token', () {
      final token = jwtService.extractTokenFromHeader('Bearer abc123');
      expect(token, equals('abc123'));
    });

    test('extractTokenFromHeader returns null for invalid header', () {
      expect(jwtService.extractTokenFromHeader(null), isNull);
      expect(jwtService.extractTokenFromHeader(''), isNull);
      expect(jwtService.extractTokenFromHeader('Basic abc'), isNull);
    });
  });
}
```

