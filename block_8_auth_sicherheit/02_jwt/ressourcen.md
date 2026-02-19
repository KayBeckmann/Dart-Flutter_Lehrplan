# Ressourcen: JWT-Authentifizierung

## Offizielle Dokumentation

- [dart_jsonwebtoken Package](https://pub.dev/packages/dart_jsonwebtoken)
- [JWT.io](https://jwt.io/) - JWT Debugger und Dokumentation
- [RFC 7519 - JSON Web Token](https://tools.ietf.org/html/rfc7519)
- [OWASP JWT Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/JSON_Web_Token_for_Java_Cheat_Sheet.html)

## Cheat Sheet: JWT Struktur

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4iLCJpYXQiOjE1MTYyMzkwMjJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
│                                      │                                                                            │
└─────────── Header (Base64) ──────────┴────────────────────── Payload (Base64) ────────────────────────────────────┴──── Signature ────┘
```

**Header (dekodiert):**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload (dekodiert):**
```json
{
  "sub": "1234567890",
  "name": "John",
  "iat": 1516239022
}
```

## Cheat Sheet: Registered Claims

| Claim | Name | Beschreibung |
|-------|------|--------------|
| `sub` | Subject | User-ID oder eindeutiger Identifier |
| `iss` | Issuer | Wer hat das Token ausgestellt |
| `aud` | Audience | Für wen ist das Token bestimmt |
| `exp` | Expiration | Ablaufzeit (Unix Timestamp) |
| `iat` | Issued At | Ausstellungszeit (Unix Timestamp) |
| `nbf` | Not Before | Gültig ab (Unix Timestamp) |
| `jti` | JWT ID | Eindeutige Token-ID |

## Cheat Sheet: dart_jsonwebtoken

```dart
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

// Token erstellen
final jwt = JWT(
  {
    'sub': '123',
    'name': 'Max',
    'role': 'admin',
  },
  issuer: 'my-api',
);

// Mit Secret signieren (HS256)
final token = jwt.sign(
  SecretKey('super-secret-key'),
  expiresIn: Duration(hours: 1),
);

// Token verifizieren
try {
  final verified = JWT.verify(token, SecretKey('super-secret-key'));
  print(verified.payload); // {'sub': '123', 'name': 'Max', ...}
} on JWTExpiredException {
  print('Token abgelaufen');
} on JWTException catch (e) {
  print('Ungültiges Token: ${e.message}');
}

// Token ohne Verifizierung dekodieren (UNSICHER!)
final decoded = JWT.decode(token);
print(decoded.payload);
```

## Cheat Sheet: Algorithmen

| Algorithmus | Typ | Beschreibung |
|-------------|-----|--------------|
| **HS256** | Symmetrisch | HMAC mit SHA-256 |
| **HS384** | Symmetrisch | HMAC mit SHA-384 |
| **HS512** | Symmetrisch | HMAC mit SHA-512 |
| **RS256** | Asymmetrisch | RSA mit SHA-256 |
| **RS384** | Asymmetrisch | RSA mit SHA-384 |
| **RS512** | Asymmetrisch | RSA mit SHA-512 |
| **ES256** | Asymmetrisch | ECDSA mit P-256 |

**Empfehlung:**
- HS256 für einfache APIs (ein Secret)
- RS256 für Microservices (Public Key zur Verifizierung)

## Cheat Sheet: Token Typen

```dart
// Access Token (kurzlebig)
final accessToken = JWT({
  'sub': userId,
  'email': email,
  'role': role,
  'type': 'access',
}).sign(secret, expiresIn: Duration(minutes: 15));

// Refresh Token (langlebig)
final refreshToken = JWT({
  'sub': userId,
  'type': 'refresh',
}).sign(secret, expiresIn: Duration(days: 7));

// ID Token (für OpenID Connect)
final idToken = JWT({
  'sub': userId,
  'email': email,
  'name': name,
  'type': 'id',
}).sign(secret, expiresIn: Duration(hours: 1));
```

## Cheat Sheet: Token Refresh Flow

```
Client                  Server
  │                       │
  ├── Login ─────────────>│
  │                       │
  │<── Access + Refresh ──┤
  │                       │
  ├── API Request ───────>│ (mit Access Token)
  │<── Response ──────────┤
  │                       │
  ├── API Request ───────>│ (Access Token abgelaufen)
  │<── 401 Unauthorized ──┤
  │                       │
  ├── Refresh ───────────>│ (mit Refresh Token)
  │<── New Access Token ──┤
  │                       │
  ├── API Request ───────>│ (mit neuem Access Token)
  │<── Response ──────────┤
```

## Cheat Sheet: Authorization Header

```dart
// Token aus Header extrahieren
String? extractToken(Request request) {
  final auth = request.headers['authorization'];
  if (auth == null) return null;
  if (!auth.startsWith('Bearer ')) return null;
  return auth.substring(7);
}

// Request mit Token senden (Client)
final response = await http.get(
  Uri.parse('https://api.example.com/data'),
  headers: {
    'Authorization': 'Bearer $accessToken',
  },
);
```

## Best Practices

### DO

1. **Kurze Access Token Lebensdauer** - 15-60 Minuten
2. **Token Rotation** - Neuer Refresh Token bei jedem Refresh
3. **Sichere Secrets** - Mindestens 256 Bit, zufällig generiert
4. **HTTPS verwenden** - Tokens nie über HTTP
5. **Claims minimal halten** - Nur nötige Daten
6. **Refresh Tokens in DB** - Zum Widerrufen

### DON'T

1. **Sensitive Daten in Payload** - Passwörter, Secrets
2. **Token in URL** - Als Query Parameter
3. **Token in localStorage** - XSS-Anfällig
4. **Zu lange Lebensdauer** - Risiko bei Kompromittierung
5. **"none" Algorithmus akzeptieren** - Sicherheitslücke

## SQL Schema

```sql
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    expires_at TIMESTAMP NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT false,
    -- Optional: Device/Client Info
    user_agent TEXT,
    ip_address INET
);

CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at) WHERE is_revoked = false;
```

## Token Blacklist (für Access Tokens)

```dart
// Mit Redis
class TokenBlacklist {
  final RedisClient _redis;

  Future<void> blacklist(String token, Duration ttl) async {
    // Token hashen (Speicher sparen)
    final hash = sha256.convert(utf8.encode(token)).toString();
    await _redis.set('blacklist:$hash', '1', ttl: ttl);
  }

  Future<bool> isBlacklisted(String token) async {
    final hash = sha256.convert(utf8.encode(token)).toString();
    return await _redis.exists('blacklist:$hash');
  }
}
```

## Secret Generierung

```bash
# 256-Bit Secret generieren (Linux/Mac)
openssl rand -hex 32

# Mit Dart
dart -e "import 'dart:math'; print(List.generate(32, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join());"

# Ergebnis z.B.: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

