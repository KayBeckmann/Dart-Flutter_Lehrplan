# Ressourcen: Passwort-Hashing & Benutzer-Registrierung

## Offizielle Dokumentation

- [bcrypt Package (pub.dev)](https://pub.dev/packages/bcrypt)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- [NIST Password Guidelines](https://pages.nist.gov/800-63-3/sp800-63b.html)

## Cheat Sheet: bcrypt

```dart
import 'package:bcrypt/bcrypt.dart';

// Salt generieren
final salt = BCrypt.gensalt(logRounds: 12);
// Ergebnis: "$2a$12$LQv3c1yqBWVHxkd0LHAkCO"

// Passwort hashen
final hash = BCrypt.hashpw('password', salt);
// Ergebnis: "$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.N1tJ9vPmUHPK3a"

// Passwort verifizieren
final isValid = BCrypt.checkpw('password', hash);
// Ergebnis: true
```

## Cheat Sheet: Hash-Format

```
$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.N1tJ9vPmUHPK3a
│ │  │                              │
│ │  │                              └── Hash (31 Zeichen, Base64)
│ │  └── Salt (22 Zeichen, Base64)
│ └── Cost Factor (Exponentiell: 2^12 = 4096 Iterationen)
└── Algorithmus ($2a = bcrypt)
```

## Cheat Sheet: Cost Factor

| Cost | Iterationen | Zeit (ca.) | Empfehlung |
|------|-------------|------------|------------|
| 10 | 1.024 | ~100ms | Minimum |
| 11 | 2.048 | ~200ms | Okay |
| 12 | 4.096 | ~300ms | **Empfohlen** |
| 13 | 8.192 | ~600ms | Gut |
| 14 | 16.384 | ~1s | Hoch |

**Faustregel:** 100-300ms ist ein guter Kompromiss.

## Cheat Sheet: Password Validation

```dart
class PasswordRules {
  // Mindestlänge
  static bool hasMinLength(String p, int min) => p.length >= min;

  // Großbuchstaben
  static bool hasUppercase(String p) => p.contains(RegExp(r'[A-Z]'));

  // Kleinbuchstaben
  static bool hasLowercase(String p) => p.contains(RegExp(r'[a-z]'));

  // Ziffern
  static bool hasDigit(String p) => p.contains(RegExp(r'[0-9]'));

  // Sonderzeichen
  static bool hasSpecial(String p) =>
      p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  // Keine Sequenzen (123, abc)
  static bool noSequences(String p) =>
      !p.contains(RegExp(r'(012|123|234|345|456|567|678|789|890)')) &&
      !p.contains(RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi)', caseSensitive: false));

  // Keine Wiederholungen (aaa, 111)
  static bool noRepeats(String p) => !p.contains(RegExp(r'(.)\1{2,}'));
}
```

## Cheat Sheet: Timing Attack Prevention

```dart
// SCHLECHT - Timing Attack möglich
Future<User?> authenticate(String email, String password) async {
  final user = await userRepo.findByEmail(email);
  if (user == null) {
    return null; // Schnelle Antwort
  }
  if (!bcrypt.verify(password, user.hash)) {
    return null; // Langsame Antwort
  }
  return user;
}

// GUT - Konstante Zeit
Future<User?> authenticate(String email, String password) async {
  final user = await userRepo.findByEmail(email);

  // Immer hashen, auch wenn User nicht existiert
  final hashToCheck = user?.hash ?? _dummyHash;
  final isValid = bcrypt.verify(password, hashToCheck);

  if (user == null || !isValid) {
    return null;
  }
  return user;
}
```

## Cheat Sheet: Email Validation

```dart
// Einfache Regex
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

// Umfassendere Regex (RFC 5322)
final emailRegexFull = RegExp(
  r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9]'
  r'(?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
  r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
);

// Normalisierung
String normalizeEmail(String email) {
  return email.toLowerCase().trim();
}
```

## Cheat Sheet: Common Passwords

```dart
const commonPasswords = [
  // Top 20 weltweit
  '123456', 'password', '12345678', 'qwerty', '123456789',
  '12345', '1234', '111111', '1234567', 'dragon',
  '123123', 'baseball', 'iloveyou', 'trustno1', 'sunshine',
  'princess', 'welcome', 'shadow', 'superman', 'michael',

  // Deutsche Klassiker
  'hallo', 'schatz', 'passwort', 'sommer', 'berlin',
];

bool isCommon(String password) {
  return commonPasswords.contains(password.toLowerCase());
}
```

## Best Practices

### DO

1. **bcrypt oder Argon2 verwenden** - Nie MD5/SHA für Passwörter
2. **Cost Factor mindestens 12** - Anpassen an Hardware
3. **Generische Fehlermeldungen** - "Invalid credentials"
4. **Email normalisieren** - Lowercase, trim
5. **Rate Limiting** - Brute-Force verhindern
6. **Passwort-Policies** - Mindestlänge, Komplexität
7. **Timing Attack verhindern** - Konstante Antwortzeit

### DON'T

1. **Passwörter im Klartext speichern** - Nie!
2. **MD5/SHA1 für Passwörter** - Zu schnell
3. **Eigenen Hash-Algorithmus** - Nutze bewährte Bibliotheken
4. **Salt wiederverwenden** - Immer neu generieren
5. **Spezifische Fehlermeldungen** - "Email nicht gefunden"
6. **Maximum-Länge für Passwörter** - Keine künstlichen Limits

## Algorithmen-Vergleich

| Algorithmus | Geschwindigkeit | Memory | Empfehlung |
|-------------|-----------------|--------|------------|
| **bcrypt** | Langsam | Niedrig | Standard |
| **Argon2id** | Langsam | Hoch | Beste Wahl |
| **scrypt** | Langsam | Hoch | Alternative |
| PBKDF2 | Langsam | Niedrig | Veraltet |
| SHA-256 | Schnell | Niedrig | Nicht für Passwörter |
| MD5 | Sehr schnell | Niedrig | Nie verwenden |

## SQL Schema

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    role VARCHAR(50) NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT true,
    failed_login_attempts INT NOT NULL DEFAULT 0,
    locked_until TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP
);

-- Index für schnelle Email-Suche
CREATE INDEX idx_users_email ON users(email);

-- Partial Index für aktive User
CREATE INDEX idx_users_active ON users(is_active) WHERE is_active = true;
```

