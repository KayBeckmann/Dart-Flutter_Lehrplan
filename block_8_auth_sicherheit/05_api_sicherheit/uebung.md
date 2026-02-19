# Übung 8.5: API-Sicherheit

## Ziel

Implementiere umfassende Sicherheitsmaßnahmen für deine API.

---

## Aufgabe 1: CORS Middleware (15 min)

```dart
// lib/middleware/cors_middleware.dart

class CorsConfig {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool allowCredentials;
  final Duration? maxAge;

  const CorsConfig({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    this.allowedHeaders = const ['Content-Type', 'Authorization'],
    this.allowCredentials = false,
    this.maxAge,
  });

  // Vordefinierte Configs
  static const development = CorsConfig();

  static const production = CorsConfig(
    allowedOrigins: [], // Muss konfiguriert werden
    allowCredentials: true,
    maxAge: Duration(hours: 1),
  );
}

Middleware corsMiddleware(CorsConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Origin aus Request-Header lesen
      // 2. Prüfen ob Origin erlaubt ist
      // 3. CORS-Header erstellen:
      //    - Access-Control-Allow-Origin
      //    - Access-Control-Allow-Methods
      //    - Access-Control-Allow-Headers
      //    - Access-Control-Allow-Credentials (wenn true)
      //    - Access-Control-Max-Age (wenn gesetzt)
      //    - Vary: Origin (wenn nicht '*')
      // 4. Bei OPTIONS (Preflight): 200 OK mit Headers
      // 5. Sonst: Response mit CORS-Headers erweitern
    };
  };
}
```

---

## Aufgabe 2: Rate Limiter (20 min)

```dart
// lib/services/rate_limiter.dart

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int limit;
  final DateTime resetAt;

  RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.limit,
    required this.resetAt,
  });

  int get retryAfterSeconds =>
      resetAt.difference(DateTime.now()).inSeconds.clamp(0, 999999);
}

abstract class RateLimiter {
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  });
}

/// In-Memory Rate Limiter (für Entwicklung/kleine Apps)
class InMemoryRateLimiter implements RateLimiter {
  final Map<String, List<DateTime>> _requests = {};

  @override
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  }) async {
    // TODO:
    // 1. Alte Requests außerhalb des Fensters entfernen
    // 2. Aktuelle Anzahl prüfen
    // 3. Bei Überschreitung: allowed=false
    // 4. Sonst: Request hinzufügen, allowed=true
  }
}

/// Redis Rate Limiter (für Produktion)
class RedisRateLimiter implements RateLimiter {
  final RedisClient _redis;

  RedisRateLimiter(this._redis);

  @override
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  }) async {
    // TODO: Sliding Window mit Redis Sorted Sets
  }
}
```

### Rate Limit Middleware

```dart
// lib/middleware/rate_limit_middleware.dart

Middleware rateLimitMiddleware({
  required RateLimiter rateLimiter,
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
  String Function(Request)? keyExtractor,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Client-ID extrahieren (keyExtractor oder default)
      // 2. Rate Limit prüfen
      // 3. Header setzen:
      //    - X-RateLimit-Limit
      //    - X-RateLimit-Remaining
      //    - X-RateLimit-Reset
      // 4. Bei Überschreitung: 429 Too Many Requests
      //    - Retry-After Header
      // 5. Sonst: Handler aufrufen
    };
  };
}

/// Standard Key Extractor (User-ID oder IP)
String defaultKeyExtractor(Request request) {
  // TODO:
  // 1. Prüfen ob authentifiziert (userId in context)
  // 2. X-Forwarded-For Header prüfen
  // 3. X-Real-IP Header prüfen
  // 4. Fallback: 'unknown'
}
```

---

## Aufgabe 3: Input Validator (20 min)

```dart
// lib/validation/validator.dart

class ValidationResult {
  final bool isValid;
  final Map<String, List<String>> errors;

  ValidationResult(this.errors) : isValid = errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'valid': isValid,
        'errors': errors,
      };
}

class Validator {
  final Map<String, List<String>> _errors = {};

  ValidationResult get result => ValidationResult(Map.from(_errors));

  void addError(String field, String message) {
    _errors.putIfAbsent(field, () => []).add(message);
  }

  /// Validiere String-Feld
  String? string(
    String field,
    dynamic value, {
    bool required = true,
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    String? patternMessage,
  }) {
    // TODO: Implementieren
  }

  /// Validiere Email
  String? email(String field, dynamic value, {bool required = true}) {
    // TODO: Implementieren (mit email Regex)
  }

  /// Validiere Integer
  int? integer(
    String field,
    dynamic value, {
    bool required = true,
    int? min,
    int? max,
  }) {
    // TODO: Implementieren
  }

  /// Validiere Liste
  List<T>? list<T>(
    String field,
    dynamic value, {
    bool required = true,
    int? minLength,
    int? maxLength,
  }) {
    // TODO: Implementieren
  }

  /// Validiere Enum
  T? enumValue<T extends Enum>(
    String field,
    dynamic value,
    List<T> values, {
    bool required = true,
  }) {
    // TODO: Implementieren
  }
}
```

### Validation Middleware

```dart
// lib/middleware/validation_middleware.dart

Middleware validateBody<T>({
  required T Function(Map<String, dynamic>) fromJson,
  required void Function(Validator, T) validate,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Body parsen
      // 2. DTO erstellen mit fromJson
      // 3. Validator erstellen und validate aufrufen
      // 4. Bei Fehlern: 400 Bad Request mit errors
      // 5. Sonst: DTO in context speichern, Handler aufrufen
    };
  };
}
```

---

## Aufgabe 4: Sanitizer (15 min)

```dart
// lib/utils/sanitizer.dart

class Sanitizer {
  /// Entferne HTML-Tags
  static String stripHtml(String input) {
    // TODO: Regex für HTML-Tags
  }

  /// Escape HTML-Entities
  static String escapeHtml(String input) {
    // TODO: &, <, >, ", ' ersetzen
  }

  /// Sanitize für SQL LIKE-Queries
  static String escapeLike(String input) {
    // TODO: %, _ escapen
  }

  /// Sanitize Dateiname
  static String sanitizeFilename(String filename) {
    // TODO:
    // - Nur alphanumerisch, -, _, .
    // - Keine doppelten Punkte
    // - Keine führenden/trailing Punkte
  }

  /// Sanitize für Logging (keine Newlines etc.)
  static String sanitizeForLog(String input, {int maxLength = 200}) {
    // TODO: \n, \r, \t ersetzen, Länge begrenzen
  }

  /// Trim und Normalize Whitespace
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
```

---

## Aufgabe 5: Security Headers Middleware (10 min)

```dart
// lib/middleware/security_headers_middleware.dart

class SecurityHeadersConfig {
  final bool noSniff;
  final String frameOptions;
  final bool xssProtection;
  final String referrerPolicy;
  final String? contentSecurityPolicy;
  final bool noCache;

  const SecurityHeadersConfig({
    this.noSniff = true,
    this.frameOptions = 'DENY',
    this.xssProtection = true,
    this.referrerPolicy = 'strict-origin-when-cross-origin',
    this.contentSecurityPolicy,
    this.noCache = true,
  });

  static const api = SecurityHeadersConfig(
    contentSecurityPolicy: "default-src 'none'",
  );
}

Middleware securityHeadersMiddleware([
  SecurityHeadersConfig config = const SecurityHeadersConfig(),
]) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO:
      // 1. Handler aufrufen
      // 2. Security-Header zur Response hinzufügen:
      //    - X-Content-Type-Options: nosniff
      //    - X-Frame-Options
      //    - X-XSS-Protection
      //    - Referrer-Policy
      //    - Content-Security-Policy
      //    - Cache-Control, Pragma (wenn noCache)
    };
  };
}
```

---

## Aufgabe 6: Error Handler (ohne Leak) (10 min)

```dart
// lib/middleware/error_handler_middleware.dart

Middleware errorHandlerMiddleware({
  required bool isDevelopment,
  void Function(Object error, StackTrace stack)? onError,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stack) {
        // TODO:
        // 1. Error loggen (onError callback)
        // 2. In Development: Details zurückgeben
        // 3. In Production: Generische Fehlermeldung
        // 4. Passenden Status Code verwenden:
        //    - ValidationException → 400
        //    - AuthException → 401/403
        //    - NotFoundException → 404
        //    - Sonstige → 500
      }
    };
  };
}
```

---

## Aufgabe 7: Sichere Repository-Methoden (15 min)

```dart
// lib/repositories/secure_product_repository.dart

class ProductRepository {
  final Connection _db;

  ProductRepository(this._db);

  /// Suche mit sicherer LIKE-Query
  Future<List<Product>> search(String query) async {
    // TODO:
    // 1. Query sanitizen mit Sanitizer.escapeLike
    // 2. Prepared Statement verwenden
    // 3. ILIKE für case-insensitive Suche
  }

  /// Sortierung mit Whitelist
  Future<List<Product>> findAll({
    String sortBy = 'created_at',
    bool descending = true,
    int limit = 20,
    int offset = 0,
  }) async {
    // TODO:
    // 1. sortBy gegen Whitelist prüfen
    // 2. limit/offset validieren (max 100)
    // 3. Sichere Query bauen
  }

  /// Bulk-Insert mit Prepared Statements
  Future<void> createMany(List<Product> products) async {
    // TODO: Transaction mit mehreren INSERT-Statements
  }
}
```

---

## Aufgabe 8: Integration (10 min)

```dart
// bin/server.dart

void main() async {
  final isDevelopment = Platform.environment['ENV'] != 'production';

  // Rate Limiter
  final rateLimiter = isDevelopment
      ? InMemoryRateLimiter()
      : RedisRateLimiter(redisClient);

  // CORS Config
  final corsConfig = isDevelopment
      ? CorsConfig.development
      : CorsConfig(
          allowedOrigins: ['https://myapp.com'],
          allowCredentials: true,
        );

  // Pipeline aufbauen
  final handler = const Pipeline()
      .addMiddleware(errorHandlerMiddleware(isDevelopment: isDevelopment))
      .addMiddleware(securityHeadersMiddleware())
      .addMiddleware(corsMiddleware(corsConfig))
      .addMiddleware(rateLimitMiddleware(
        rateLimiter: rateLimiter,
        maxRequests: 100,
        window: Duration(minutes: 1),
      ))
      .addMiddleware(logRequests())
      .addHandler(router);

  await serve(handler, 'localhost', 8080);
}
```

---

## Testen

### Rate Limiting

```bash
# Viele Requests schnell senden
for i in {1..110}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/api/products
done

# Sollte nach 100 Requests "429" zurückgeben
```

### CORS

```bash
# Preflight Request
curl -X OPTIONS http://localhost:8080/api/products \
  -H "Origin: https://example.com" \
  -H "Access-Control-Request-Method: POST" \
  -v

# Prüfe Access-Control-* Header in Response
```

### Security Headers

```bash
curl -v http://localhost:8080/api/products 2>&1 | grep -i "x-content-type\|x-frame\|x-xss"
```

---

## Abgabe-Checkliste

- [ ] CORS Middleware mit konfigurierbaren Origins
- [ ] Rate Limiter (InMemory und/oder Redis)
- [ ] Rate Limit Middleware mit Headers
- [ ] Validator für String, Email, Integer, List
- [ ] Sanitizer für HTML, LIKE, Filename, Log
- [ ] Security Headers Middleware
- [ ] Error Handler ohne Information Disclosure
- [ ] Sichere Repository-Methoden mit Prepared Statements
- [ ] Integration aller Middleware in Pipeline

