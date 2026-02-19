# Einheit 8.2: JWT-Authentifizierung

## Lernziele

Nach dieser Einheit kannst du:
- JWT-Struktur und -Funktionsweise verstehen
- Access und Refresh Tokens implementieren
- Tokens generieren und validieren
- Token-basierte Authentifizierung aufbauen

---

## Was ist JWT?

**JWT** (JSON Web Token) ist ein offener Standard (RFC 7519) für die sichere Übertragung von Informationen zwischen Parteien als JSON-Objekt.

### Eigenschaften

- **Kompakt**: URL-sicher, kann in HTTP-Header übertragen werden
- **Selbstbeschreibend**: Enthält alle nötigen Informationen
- **Signiert**: Integrität und Authentizität gewährleistet
- **Optional verschlüsselt**: JWE für sensitive Daten

### Wann JWT?

| Use Case | JWT geeignet? |
|----------|---------------|
| Stateless API Auth | ✅ Ideal |
| Single Sign-On (SSO) | ✅ Ideal |
| Microservices | ✅ Ideal |
| Session-basierte Apps | ⚠️ Sessions oft einfacher |
| Sensitive Daten im Token | ❌ Nicht empfohlen |

---

## JWT-Struktur

Ein JWT besteht aus drei Teilen, getrennt durch Punkte:

```
xxxxx.yyyyy.zzzzz
Header.Payload.Signature
```

### 1. Header

```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

- **alg**: Signatur-Algorithmus (HS256, RS256, ES256)
- **typ**: Token-Typ (immer "JWT")

### 2. Payload (Claims)

```json
{
  "sub": "1234567890",
  "name": "Max Mustermann",
  "email": "max@example.com",
  "role": "admin",
  "iat": 1516239022,
  "exp": 1516242622
}
```

**Registered Claims (Standard):**

| Claim | Beschreibung |
|-------|--------------|
| `sub` | Subject (User-ID) |
| `iss` | Issuer (Aussteller) |
| `aud` | Audience (Empfänger) |
| `exp` | Expiration Time |
| `iat` | Issued At |
| `nbf` | Not Before |
| `jti` | JWT ID (einmalig) |

**Private Claims (Custom):**
- `role`, `email`, `permissions`, etc.

### 3. Signature

```
HMACSHA256(
  base64UrlEncode(header) + "." + base64UrlEncode(payload),
  secret
)
```

---

## JWT in Dart

### Installation

```yaml
dependencies:
  dart_jsonwebtoken: ^2.12.0
```

### Token generieren

```dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtService {
  final String _secret;
  final Duration _accessTokenDuration;
  final Duration _refreshTokenDuration;

  JwtService({
    required String secret,
    Duration? accessTokenDuration,
    Duration? refreshTokenDuration,
  })  : _secret = secret,
        _accessTokenDuration = accessTokenDuration ?? const Duration(minutes: 15),
        _refreshTokenDuration = refreshTokenDuration ?? const Duration(days: 7);

  /// Access Token generieren
  String generateAccessToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'email': user.email,
        'name': user.name,
        'role': user.role,
        'type': 'access',
      },
      issuer: 'my-api',
      subject: user.id.toString(),
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: _accessTokenDuration,
    );
  }

  /// Refresh Token generieren
  String generateRefreshToken(User user) {
    final jwt = JWT(
      {
        'sub': user.id.toString(),
        'type': 'refresh',
      },
      issuer: 'my-api',
      subject: user.id.toString(),
    );

    return jwt.sign(
      SecretKey(_secret),
      expiresIn: _refreshTokenDuration,
    );
  }

  /// Token-Paar generieren
  TokenPair generateTokenPair(User user) {
    return TokenPair(
      accessToken: generateAccessToken(user),
      refreshToken: generateRefreshToken(user),
      expiresIn: _accessTokenDuration.inSeconds,
    );
  }
}

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
}
```

### Token validieren

```dart
class JwtService {
  // ... vorheriger Code ...

  /// Token verifizieren und Payload extrahieren
  JwtPayload? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(_secret));

      return JwtPayload(
        sub: jwt.payload['sub'] as String,
        email: jwt.payload['email'] as String?,
        name: jwt.payload['name'] as String?,
        role: jwt.payload['role'] as String?,
        type: jwt.payload['type'] as String,
        exp: jwt.payload['exp'] as int?,
        iat: jwt.payload['iat'] as int?,
      );
    } on JWTExpiredException {
      throw TokenExpiredException();
    } on JWTException catch (e) {
      throw InvalidTokenException(e.message);
    }
  }

  /// Prüfen ob Token abgelaufen ist
  bool isExpired(String token) {
    try {
      JWT.verify(token, SecretKey(_secret));
      return false;
    } on JWTExpiredException {
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Payload ohne Verifizierung lesen (unsicher!)
  Map<String, dynamic>? decodePayload(String token) {
    try {
      final jwt = JWT.decode(token);
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}

class JwtPayload {
  final String sub;
  final String? email;
  final String? name;
  final String? role;
  final String type;
  final int? exp;
  final int? iat;

  JwtPayload({
    required this.sub,
    this.email,
    this.name,
    this.role,
    required this.type,
    this.exp,
    this.iat,
  });

  int get userId => int.parse(sub);

  bool get isAccessToken => type == 'access';
  bool get isRefreshToken => type == 'refresh';
}
```

### Exceptions

```dart
// lib/exceptions/auth_exceptions.dart

class TokenExpiredException implements Exception {
  final String message = 'Token has expired';
}

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException([this.message = 'Invalid token']);
}

class RefreshTokenRevokedException implements Exception {
  final String message = 'Refresh token has been revoked';
}
```

---

## Access vs Refresh Tokens

### Access Token

- **Kurze Lebensdauer**: 15-60 Minuten
- **Verwendung**: In jedem API-Request
- **Enthält**: User-Daten für Autorisierung
- **Speicherung**: Im Memory (Frontend)

### Refresh Token

- **Lange Lebensdauer**: Tage/Wochen
- **Verwendung**: Nur zum Erneuern des Access Tokens
- **Enthält**: Nur User-ID
- **Speicherung**: HttpOnly Cookie oder Secure Storage

### Flow

```
1. Login → Access Token + Refresh Token
2. API Request mit Access Token
3. Access Token abgelaufen → 401
4. Refresh Request mit Refresh Token → Neuer Access Token
5. Logout → Refresh Token invalidieren
```

---

## Token Refresh

```dart
// lib/services/auth_service.dart

class AuthService {
  final UserRepository _userRepo;
  final JwtService _jwtService;
  final RefreshTokenRepository _refreshTokenRepo;

  // ... constructor ...

  /// Login mit Token-Generierung
  Future<AuthResult> login(LoginRequest request) async {
    final user = await _authenticate(request);
    if (user == null) {
      return AuthResult.failure('Invalid credentials', statusCode: 401);
    }

    final tokenPair = _jwtService.generateTokenPair(user);

    // Refresh Token in DB speichern
    await _refreshTokenRepo.create(RefreshTokenRecord(
      userId: user.id!,
      token: tokenPair.refreshToken,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ));

    return AuthResult.success(user, tokens: tokenPair);
  }

  /// Access Token erneuern
  Future<TokenPair> refreshAccessToken(String refreshToken) async {
    // 1. Token verifizieren
    final payload = _jwtService.verifyToken(refreshToken);
    if (payload == null || !payload.isRefreshToken) {
      throw InvalidTokenException('Invalid refresh token');
    }

    // 2. Prüfen ob Token in DB existiert (nicht revoked)
    final record = await _refreshTokenRepo.findByToken(refreshToken);
    if (record == null || record.isRevoked) {
      throw RefreshTokenRevokedException();
    }

    // 3. User laden
    final user = await _userRepo.findById(payload.userId);
    if (user == null || !user.isActive) {
      throw InvalidTokenException('User not found or inactive');
    }

    // 4. Neues Token-Paar generieren (Token Rotation)
    final newTokenPair = _jwtService.generateTokenPair(user);

    // 5. Alten Refresh Token revoken
    await _refreshTokenRepo.revoke(refreshToken);

    // 6. Neuen Refresh Token speichern
    await _refreshTokenRepo.create(RefreshTokenRecord(
      userId: user.id!,
      token: newTokenPair.refreshToken,
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ));

    return newTokenPair;
  }

  /// Logout - Refresh Token invalidieren
  Future<void> logout(String refreshToken) async {
    await _refreshTokenRepo.revoke(refreshToken);
  }

  /// Alle Sessions eines Users beenden
  Future<void> logoutAllSessions(int userId) async {
    await _refreshTokenRepo.revokeAllForUser(userId);
  }
}
```

---

## Refresh Token Repository

```dart
// lib/repositories/refresh_token_repository.dart

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
}

class RefreshTokenRepository {
  final Connection _db;

  RefreshTokenRepository(this._db);

  Future<void> create(RefreshTokenRecord record) async {
    await _db.execute(
      Sql.named('''
        INSERT INTO refresh_tokens (user_id, token, expires_at)
        VALUES (@userId, @token, @expiresAt)
      '''),
      parameters: {
        'userId': record.userId,
        'token': record.token,
        'expiresAt': record.expiresAt,
      },
    );
  }

  Future<RefreshTokenRecord?> findByToken(String token) async {
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM refresh_tokens
        WHERE token = @token AND is_revoked = false
      '''),
      parameters: {'token': token},
    );

    if (result.isEmpty) return null;
    return _mapToRecord(result.first.toColumnMap());
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
        WHERE user_id = @userId
      '''),
      parameters: {'userId': userId},
    );
  }

  Future<void> deleteExpired() async {
    await _db.execute(
      Sql.named('''
        DELETE FROM refresh_tokens
        WHERE expires_at < NOW() OR is_revoked = true
      '''),
    );
  }

  RefreshTokenRecord _mapToRecord(Map<String, dynamic> row) {
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
```

---

## Auth Handler (erweitert)

```dart
// lib/handlers/auth_handler.dart

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

  Future<Response> _login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body) as Map<String, dynamic>;

      final result = await _authService.login(LoginRequest(
        email: data['email'] as String,
        password: data['password'] as String,
      ));

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
          {'error': 'Refresh token required'},
          statusCode: 400,
        );
      }

      final newTokens = await _authService.refreshAccessToken(refreshToken);

      return _jsonResponse(newTokens.toJson());
    } on TokenExpiredException {
      return _jsonResponse(
        {'error': 'Refresh token expired'},
        statusCode: 401,
      );
    } on RefreshTokenRevokedException {
      return _jsonResponse(
        {'error': 'Refresh token revoked'},
        statusCode: 401,
      );
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
      return _jsonResponse({'message': 'Logged out'});
    }
  }

  // ... _register, _jsonResponse ...
}
```

---

## Datenbank-Schema

```sql
-- migrations/002_create_refresh_tokens.sql

CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT false
);

-- Index für Token-Lookup
CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);

-- Index für User-Cleanup
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);

-- Index für Expired-Cleanup
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);
```

---

## Best Practices

### Token-Sicherheit

1. **Kurze Access Token Lifetime** - 15-60 Minuten
2. **Refresh Token Rotation** - Bei jedem Refresh neues Token
3. **Sichere Secrets** - Mindestens 256 Bit, aus sicherer Quelle
4. **HTTPS** - Tokens nur über verschlüsselte Verbindung
5. **Nicht in localStorage** - XSS-Gefahr

### Token-Invalidierung

```dart
// Alle Tokens eines Users invalidieren (z.B. bei Passwortänderung)
Future<void> invalidateAllTokens(int userId) async {
  await _refreshTokenRepo.revokeAllForUser(userId);
}

// Token-Blacklist für Access Tokens (optional)
class TokenBlacklist {
  final RedisClient _redis;

  Future<void> blacklist(String token, Duration ttl) async {
    await _redis.set('blacklist:$token', '1', ttl: ttl);
  }

  Future<bool> isBlacklisted(String token) async {
    return await _redis.exists('blacklist:$token');
  }
}
```

### Secret Management

```dart
// NIEMALS hardcoded!
// FALSCH:
final secret = 'my-super-secret-key';

// RICHTIG:
final secret = Platform.environment['JWT_SECRET']
    ?? (throw Exception('JWT_SECRET not set'));

// Secret-Generierung (einmalig):
// dart -e "import 'dart:math'; print(List.generate(32, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join());"
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| **JWT** | Signiertes JSON-Token |
| **Header** | Algorithmus und Typ |
| **Payload** | Claims (User-Daten) |
| **Signature** | Integritätsprüfung |
| **Access Token** | Kurzlebig, für API-Requests |
| **Refresh Token** | Langlebig, für Token-Erneuerung |
| **Token Rotation** | Neues Refresh Token bei jedem Refresh |

