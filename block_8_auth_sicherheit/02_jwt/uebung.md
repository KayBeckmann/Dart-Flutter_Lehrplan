# Übung 8.2: JWT-Authentifizierung

## Ziel

Erweitere das Auth-System aus Einheit 8.1 um JWT-basierte Authentifizierung mit Access und Refresh Tokens.

---

## Vorbereitung

### Dependencies hinzufügen

```yaml
dependencies:
  dart_jsonwebtoken: ^2.12.0
  # ... bestehende Dependencies
```

### Datenbank erweitern

```sql
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
```

---

## Aufgabe 1: JWT Payload Model (10 min)

```dart
// lib/models/jwt_payload.dart

class JwtPayload {
  final String sub;         // User ID
  final String? email;
  final String? name;
  final String? role;
  final String type;        // 'access' oder 'refresh'
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

  // TODO: Getter für userId (int parse)
  // TODO: Getter isAccessToken / isRefreshToken
  // TODO: Getter isExpired

  factory JwtPayload.fromJwtPayload(Map<String, dynamic> payload) {
    // TODO: Payload aus JWT extrahieren
    // Hinweis: exp und iat sind Unix-Timestamps (Sekunden)
  }
}
```

---

## Aufgabe 2: Token Pair Model (5 min)

```dart
// lib/models/token_pair.dart

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;  // Sekunden bis Access Token abläuft

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  Map<String, dynamic> toJson() {
    // TODO: JSON-Response für Client
    // {
    //   "access_token": "...",
    //   "refresh_token": "...",
    //   "expires_in": 900,
    //   "token_type": "Bearer"
    // }
  }
}
```

---

## Aufgabe 3: JWT Service (25 min)

```dart
// lib/services/jwt_service.dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

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

  /// Generiere Access Token für User
  String generateAccessToken(User user) {
    // TODO:
    // 1. JWT mit Payload erstellen (sub, email, name, role, type: 'access')
    // 2. Mit SecretKey signieren
    // 3. expiresIn setzen
  }

  /// Generiere Refresh Token für User
  String generateRefreshToken(User user) {
    // TODO:
    // 1. JWT mit minimalem Payload (sub, type: 'refresh')
    // 2. Längere Lebensdauer
  }

  /// Generiere Token-Paar
  TokenPair generateTokenPair(User user) {
    // TODO: Beide Tokens generieren und als TokenPair zurückgeben
  }

  /// Verifiziere und dekodiere Token
  JwtPayload? verifyToken(String token) {
    // TODO:
    // 1. JWT.verify mit SecretKey
    // 2. JwtPayload aus payload erstellen
    // 3. Bei Fehler: entsprechende Exception werfen
  }

  /// Dekodiere Token ohne Verifizierung (nur für Debugging!)
  Map<String, dynamic>? decodeWithoutVerification(String token) {
    // TODO: JWT.decode (unsicher, nur für Debugging)
  }
}
```

---

## Aufgabe 4: Refresh Token Repository (15 min)

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

  /// Neuen Refresh Token speichern
  Future<void> create(RefreshTokenRecord record) async {
    // TODO: INSERT INTO refresh_tokens
  }

  /// Token suchen (nur wenn nicht revoked)
  Future<RefreshTokenRecord?> findByToken(String token) async {
    // TODO: SELECT WHERE token = @token AND is_revoked = false
  }

  /// Token als revoked markieren
  Future<void> revoke(String token) async {
    // TODO: UPDATE SET is_revoked = true
  }

  /// Alle Tokens eines Users revoken
  Future<void> revokeAllForUser(int userId) async {
    // TODO: UPDATE WHERE user_id = @userId
  }

  /// Abgelaufene Tokens löschen (Cleanup-Job)
  Future<int> deleteExpired() async {
    // TODO: DELETE WHERE expires_at < NOW()
    // Return: Anzahl gelöschter Einträge
  }
}
```

---

## Aufgabe 5: Auth Service erweitern (20 min)

Erweitere deinen AuthService aus Einheit 8.1:

```dart
// lib/services/auth_service.dart

class AuthService {
  final UserRepository _userRepo;
  final PasswordService _passwordService;
  final JwtService _jwtService;
  final RefreshTokenRepository _refreshTokenRepo;

  // ... Constructor ...

  /// Login mit Token-Generierung
  Future<AuthResult> login(LoginRequest request) async {
    // TODO:
    // 1. User authentifizieren (wie in 8.1)
    // 2. Token-Paar generieren
    // 3. Refresh Token in DB speichern
    // 4. AuthResult mit Tokens zurückgeben
  }

  /// Access Token erneuern
  Future<TokenPair> refreshAccessToken(String refreshToken) async {
    // TODO:
    // 1. Refresh Token verifizieren
    // 2. Prüfen ob type == 'refresh'
    // 3. Prüfen ob in DB existiert und nicht revoked
    // 4. User laden
    // 5. Alten Token revoken (Token Rotation!)
    // 6. Neues Token-Paar generieren
    // 7. Neuen Refresh Token speichern
    // 8. TokenPair zurückgeben
  }

  /// Logout - Refresh Token invalidieren
  Future<void> logout(String refreshToken) async {
    // TODO: Token revoken
  }

  /// Alle Sessions beenden
  Future<void> logoutAllSessions(int userId) async {
    // TODO: Alle Tokens des Users revoken
  }
}

// AuthResult erweitern
class AuthResult {
  final bool success;
  final User? user;
  final TokenPair? tokens;  // NEU
  final String? error;
  final int statusCode;

  // ... Constructors anpassen ...
}
```

---

## Aufgabe 6: Auth Handler erweitern (15 min)

```dart
// lib/handlers/auth_handler.dart

class AuthHandler {
  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refresh);   // NEU
    router.post('/logout', _logout);     // NEU

    return router;
  }

  Future<Response> _login(Request request) async {
    // TODO: Login Response mit Tokens erweitern
    // {
    //   "message": "Login successful",
    //   "user": { ... },
    //   "access_token": "...",
    //   "refresh_token": "...",
    //   "expires_in": 900,
    //   "token_type": "Bearer"
    // }
  }

  Future<Response> _refresh(Request request) async {
    // TODO:
    // 1. refresh_token aus Body lesen
    // 2. authService.refreshAccessToken aufrufen
    // 3. Neues Token-Paar zurückgeben
    // 4. Fehlerbehandlung (expired, revoked, invalid)
  }

  Future<Response> _logout(Request request) async {
    // TODO:
    // 1. refresh_token aus Body lesen
    // 2. authService.logout aufrufen
    // 3. Erfolg zurückgeben
  }
}
```

---

## Aufgabe 7: Exceptions (5 min)

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

class TokenTypeMismatchException implements Exception {
  final String expected;
  final String actual;

  TokenTypeMismatchException(this.expected, this.actual);

  String get message => 'Expected $expected token, got $actual';
}
```

---

## Aufgabe 8: Konfiguration (5 min)

```dart
// lib/config/jwt_config.dart

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
      throw Exception('JWT_SECRET environment variable not set');
    }

    return JwtConfig(
      secret: secret,
      issuer: Platform.environment['JWT_ISSUER'] ?? 'my-api',
      accessTokenDuration: Duration(
        minutes: int.parse(Platform.environment['JWT_ACCESS_DURATION'] ?? '15'),
      ),
      refreshTokenDuration: Duration(
        days: int.parse(Platform.environment['JWT_REFRESH_DURATION'] ?? '7'),
      ),
    );
  }
}
```

---

## Testen

### Login mit Token-Response

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com", "password": "SecurePass123!"}'

# Response:
# {
#   "message": "Login successful",
#   "user": { "id": 1, "email": "test@example.com", ... },
#   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "expires_in": 900,
#   "token_type": "Bearer"
# }
```

### Token Refresh

```bash
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'

# Response:
# {
#   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "expires_in": 900,
#   "token_type": "Bearer"
# }
```

### Logout

```bash
curl -X POST http://localhost:8080/api/auth/logout \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'

# Nach Logout: Refresh sollte fehlschlagen
curl -X POST http://localhost:8080/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{"refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}'

# Response: 401 { "error": "Refresh token revoked" }
```

---

## Abgabe-Checkliste

- [ ] JwtPayload Model mit Gettern
- [ ] TokenPair Model mit toJson
- [ ] JwtService mit generateAccessToken/generateRefreshToken
- [ ] JwtService mit verifyToken
- [ ] RefreshTokenRepository mit CRUD
- [ ] AuthService.login mit Token-Generierung
- [ ] AuthService.refreshAccessToken mit Token Rotation
- [ ] AuthService.logout mit Token Revocation
- [ ] Auth Handler /refresh Endpoint
- [ ] Auth Handler /logout Endpoint
- [ ] Exception-Klassen für Token-Fehler
- [ ] JWT_SECRET aus Environment Variable

