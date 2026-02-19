# Einheit 8.5: API-Sicherheit

## Lernziele

Nach dieser Einheit kannst du:
- CORS richtig konfigurieren
- Rate Limiting implementieren
- Input Sanitization durchführen
- SQL Injection verhindern
- HTTPS und Security Headers einsetzen

---

## OWASP Top 10

Die häufigsten Sicherheitsrisiken für Web-APIs:

| Rang | Risiko | Beschreibung |
|------|--------|--------------|
| 1 | Broken Access Control | Unzureichende Autorisierung |
| 2 | Cryptographic Failures | Schwache Verschlüsselung |
| 3 | Injection | SQL/NoSQL/Command Injection |
| 4 | Insecure Design | Architektur-Schwächen |
| 5 | Security Misconfiguration | Falsche Konfiguration |
| 6 | Vulnerable Components | Unsichere Dependencies |
| 7 | Authentication Failures | Schwache Authentifizierung |
| 8 | Data Integrity Failures | Manipulierte Daten |
| 9 | Logging Failures | Unzureichendes Logging |
| 10 | SSRF | Server-Side Request Forgery |

---

## CORS (Cross-Origin Resource Sharing)

### Problem

Browser blockieren Requests von anderen Domains (Same-Origin Policy).

### Lösung

Server erlaubt explizit bestimmte Origins:

```dart
// lib/middleware/cors_middleware.dart

Middleware corsMiddleware({
  List<String>? allowedOrigins,
  List<String>? allowedMethods,
  List<String>? allowedHeaders,
  bool allowCredentials = false,
  Duration? maxAge,
}) {
  final origins = allowedOrigins ?? ['*'];
  final methods = allowedMethods ?? ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];
  final headers = allowedHeaders ?? ['Content-Type', 'Authorization'];

  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'];

      // CORS-Header erstellen
      final corsHeaders = <String, String>{};

      // Origin prüfen
      if (origin != null) {
        if (origins.contains('*')) {
          corsHeaders['Access-Control-Allow-Origin'] = '*';
        } else if (origins.contains(origin)) {
          corsHeaders['Access-Control-Allow-Origin'] = origin;
          corsHeaders['Vary'] = 'Origin';
        }
      }

      corsHeaders['Access-Control-Allow-Methods'] = methods.join(', ');
      corsHeaders['Access-Control-Allow-Headers'] = headers.join(', ');

      if (allowCredentials) {
        corsHeaders['Access-Control-Allow-Credentials'] = 'true';
      }

      if (maxAge != null) {
        corsHeaders['Access-Control-Max-Age'] = maxAge.inSeconds.toString();
      }

      // Preflight Request (OPTIONS)
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      // Normaler Request
      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}
```

### Konfiguration für Produktion

```dart
// Entwicklung
final cors = corsMiddleware(
  allowedOrigins: ['*'],
);

// Produktion
final cors = corsMiddleware(
  allowedOrigins: [
    'https://myapp.com',
    'https://admin.myapp.com',
  ],
  allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  allowCredentials: true,
  maxAge: Duration(hours: 1),
);
```

---

## Rate Limiting

### Sliding Window mit Redis

```dart
// lib/middleware/rate_limit_middleware.dart
import '../services/rate_limiter.dart';

Middleware rateLimitMiddleware({
  required RateLimiter rateLimiter,
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
  String Function(Request)? keyExtractor,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      // Client-Identifier extrahieren
      final clientId = keyExtractor?.call(request) ?? _getClientId(request);

      // Rate Limit prüfen
      final result = await rateLimiter.check(
        clientId: clientId,
        maxRequests: maxRequests,
        window: window,
      );

      // Response-Header setzen
      final headers = {
        'X-RateLimit-Limit': maxRequests.toString(),
        'X-RateLimit-Remaining': result.remaining.toString(),
        'X-RateLimit-Reset': result.resetAt.toIso8601String(),
      };

      if (!result.allowed) {
        return Response(
          429,
          body: jsonEncode({
            'error': 'Too many requests',
            'retry_after': result.retryAfterSeconds,
          }),
          headers: {
            ...headers,
            'content-type': 'application/json',
            'Retry-After': result.retryAfterSeconds.toString(),
          },
        );
      }

      final response = await innerHandler(request);
      return response.change(headers: headers);
    };
  };
}

String _getClientId(Request request) {
  // 1. Authentifizierter User
  final userId = request.context['userId'] as int?;
  if (userId != null) return 'user:$userId';

  // 2. IP-Adresse
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null) return 'ip:${forwarded.split(',').first.trim()}';

  final realIp = request.headers['x-real-ip'];
  if (realIp != null) return 'ip:$realIp';

  return 'ip:unknown';
}
```

### Rate Limiter Service

```dart
// lib/services/rate_limiter.dart

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final DateTime resetAt;
  final int retryAfterSeconds;

  RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.resetAt,
    this.retryAfterSeconds = 0,
  });
}

class RateLimiter {
  final RedisClient _redis;

  RateLimiter(this._redis);

  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  }) async {
    final key = 'ratelimit:$clientId';
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Sliding Window: Alte Einträge entfernen
    await _redis.zremrangebyscore(
      key,
      0,
      windowStart.millisecondsSinceEpoch.toDouble(),
    );

    // Aktuelle Anzahl
    final count = await _redis.zcard(key);

    final resetAt = now.add(window);

    if (count >= maxRequests) {
      // Rate Limit erreicht
      final oldestEntry = await _redis.command.send_object([
        'ZRANGE', key, '0', '0', 'WITHSCORES'
      ]);

      int retryAfter = window.inSeconds;
      if (oldestEntry != null && (oldestEntry as List).length >= 2) {
        final oldestTime = double.parse(oldestEntry[1] as String).toInt();
        final oldestDate = DateTime.fromMillisecondsSinceEpoch(oldestTime);
        retryAfter = oldestDate.add(window).difference(now).inSeconds;
        if (retryAfter < 0) retryAfter = 0;
      }

      return RateLimitResult(
        allowed: false,
        remaining: 0,
        resetAt: resetAt,
        retryAfterSeconds: retryAfter,
      );
    }

    // Request hinzufügen
    await _redis.zadd(
      key,
      now.millisecondsSinceEpoch.toDouble(),
      now.millisecondsSinceEpoch.toString(),
    );

    // TTL setzen
    await _redis.expire(key, window);

    return RateLimitResult(
      allowed: true,
      remaining: maxRequests - count - 1,
      resetAt: resetAt,
    );
  }
}
```

---

## Input Validation & Sanitization

### Validation Middleware

```dart
// lib/middleware/validation_middleware.dart

class ValidationError {
  final String field;
  final String message;

  ValidationError(this.field, this.message);

  Map<String, dynamic> toJson() => {'field': field, 'message': message};
}

class Validator {
  final List<ValidationError> _errors = [];

  List<ValidationError> get errors => List.unmodifiable(_errors);
  bool get hasErrors => _errors.isNotEmpty;
  bool get isValid => _errors.isEmpty;

  void addError(String field, String message) {
    _errors.add(ValidationError(field, message));
  }

  // String Validierung
  String? validateString(
    String field,
    String? value, {
    bool required = true,
    int? minLength,
    int? maxLength,
    RegExp? pattern,
    String? patternMessage,
  }) {
    if (value == null || value.isEmpty) {
      if (required) addError(field, '$field is required');
      return null;
    }

    final trimmed = value.trim();

    if (minLength != null && trimmed.length < minLength) {
      addError(field, '$field must be at least $minLength characters');
    }

    if (maxLength != null && trimmed.length > maxLength) {
      addError(field, '$field must be at most $maxLength characters');
    }

    if (pattern != null && !pattern.hasMatch(trimmed)) {
      addError(field, patternMessage ?? '$field has invalid format');
    }

    return trimmed;
  }

  // Email Validierung
  String? validateEmail(String field, String? value, {bool required = true}) {
    return validateString(
      field,
      value,
      required: required,
      pattern: RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'),
      patternMessage: 'Invalid email format',
    );
  }

  // Integer Validierung
  int? validateInt(
    String field,
    dynamic value, {
    bool required = true,
    int? min,
    int? max,
  }) {
    if (value == null) {
      if (required) addError(field, '$field is required');
      return null;
    }

    final intValue = value is int ? value : int.tryParse(value.toString());

    if (intValue == null) {
      addError(field, '$field must be a valid integer');
      return null;
    }

    if (min != null && intValue < min) {
      addError(field, '$field must be at least $min');
    }

    if (max != null && intValue > max) {
      addError(field, '$field must be at most $max');
    }

    return intValue;
  }
}
```

### HTML/XSS Sanitization

```dart
// lib/utils/sanitizer.dart

class Sanitizer {
  /// HTML-Tags entfernen
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// HTML-Entities escapen
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// SQL-kritische Zeichen (für Logging, nicht als SQL-Schutz!)
  static String sanitizeForLog(String input) {
    return input
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  /// URL-Parameter sanitizen
  static String sanitizeUrlParam(String input) {
    return Uri.encodeComponent(input);
  }

  /// Dateinamen sanitizen
  static String sanitizeFilename(String filename) {
    return filename
        .replaceAll(RegExp(r'[^\w\-\.]'), '_')
        .replaceAll(RegExp(r'\.{2,}'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
  }
}
```

---

## SQL Injection Prevention

### Prepared Statements (immer verwenden!)

```dart
// SICHER: Prepared Statements
final result = await db.execute(
  Sql.named('SELECT * FROM users WHERE email = @email'),
  parameters: {'email': userInput},
);

// UNSICHER: String Concatenation - NIEMALS!
final result = await db.execute(
  "SELECT * FROM users WHERE email = '$userInput'",  // GEFÄHRLICH!
);
```

### Repository mit sicheren Queries

```dart
class UserRepository {
  final Connection _db;

  // SICHER
  Future<User?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM users WHERE email = @email'),
      parameters: {'email': email.toLowerCase().trim()},
    );
    if (result.isEmpty) return null;
    return User.fromJson(result.first.toColumnMap());
  }

  // SICHER: Dynamische Sortierung mit Whitelist
  Future<List<User>> findAll({
    String orderBy = 'created_at',
    bool descending = true,
  }) async {
    // Whitelist für erlaubte Spalten
    const allowedColumns = {'id', 'email', 'name', 'created_at'};

    if (!allowedColumns.contains(orderBy)) {
      orderBy = 'created_at';
    }

    final direction = descending ? 'DESC' : 'ASC';

    // Spaltenname ist gewhitelistet, daher sicher
    final result = await _db.execute(
      'SELECT * FROM users ORDER BY $orderBy $direction',
    );

    return result.map((r) => User.fromJson(r.toColumnMap())).toList();
  }

  // SICHER: LIKE-Suche mit Escaping
  Future<List<User>> search(String query) async {
    // Sonderzeichen in LIKE escapen
    final escapedQuery = query
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');

    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM users
        WHERE name ILIKE @pattern OR email ILIKE @pattern
      '''),
      parameters: {'pattern': '%$escapedQuery%'},
    );

    return result.map((r) => User.fromJson(r.toColumnMap())).toList();
  }
}
```

---

## Security Headers

```dart
// lib/middleware/security_headers_middleware.dart

Middleware securityHeadersMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final response = await innerHandler(request);

      return response.change(headers: {
        // Verhindert MIME-Type Sniffing
        'X-Content-Type-Options': 'nosniff',

        // Clickjacking-Schutz
        'X-Frame-Options': 'DENY',

        // XSS-Filter (Legacy-Browser)
        'X-XSS-Protection': '1; mode=block',

        // Referrer einschränken
        'Referrer-Policy': 'strict-origin-when-cross-origin',

        // Content Security Policy
        'Content-Security-Policy': "default-src 'self'",

        // Strict Transport Security (nur mit HTTPS)
        // 'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',

        // Keine Cache für API-Responses
        'Cache-Control': 'no-store',
        'Pragma': 'no-cache',
      });
    };
  };
}
```

---

## HTTPS

### TLS mit Shelf

```dart
// bin/server.dart
import 'dart:io';

void main() async {
  final securityContext = SecurityContext()
    ..useCertificateChain('cert.pem')
    ..usePrivateKey('key.pem');

  final server = await HttpServer.bindSecure(
    InternetAddress.anyIPv4,
    443,
    securityContext,
  );

  serveRequests(server, handler);
}
```

### In Produktion: Reverse Proxy

Besser: nginx/Caddy vor der Dart-App für TLS-Terminierung.

```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    server_name api.example.com;

    ssl_certificate /etc/letsencrypt/live/api.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.example.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

---

## Error Handling (ohne Leak)

```dart
// lib/middleware/error_handler_middleware.dart

Middleware errorHandlerMiddleware({bool isDevelopment = false}) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stack) {
        // Immer loggen
        print('Error: $e\n$stack');

        // Produktion: Keine Details leaken
        if (!isDevelopment) {
          return Response.internalServerError(
            body: jsonEncode({'error': 'Internal server error'}),
            headers: {'content-type': 'application/json'},
          );
        }

        // Development: Details anzeigen
        return Response.internalServerError(
          body: jsonEncode({
            'error': e.toString(),
            'stack': stack.toString(),
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
```

---

## Zusammenfassung

| Maßnahme | Schutz gegen |
|----------|--------------|
| **CORS** | Unauthorized Cross-Origin Requests |
| **Rate Limiting** | DoS, Brute Force |
| **Input Validation** | Invalid Data, Injection |
| **Prepared Statements** | SQL Injection |
| **Sanitization** | XSS, Injection |
| **Security Headers** | Clickjacking, MIME Sniffing |
| **HTTPS** | Man-in-the-Middle |
| **Error Handling** | Information Disclosure |

