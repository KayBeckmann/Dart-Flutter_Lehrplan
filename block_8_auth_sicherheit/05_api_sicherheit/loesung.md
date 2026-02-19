# Lösung 8.5: API-Sicherheit

## CORS Middleware

```dart
// lib/middleware/cors_middleware.dart
import 'package:shelf/shelf.dart';

class CorsConfig {
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool allowCredentials;
  final Duration? maxAge;

  const CorsConfig({
    this.allowedOrigins = const ['*'],
    this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    this.allowedHeaders = const ['Content-Type', 'Authorization', 'Accept'],
    this.allowCredentials = false,
    this.maxAge,
  });

  static const development = CorsConfig();

  static CorsConfig production(List<String> origins) => CorsConfig(
        allowedOrigins: origins,
        allowCredentials: true,
        maxAge: const Duration(hours: 1),
      );
}

Middleware corsMiddleware(CorsConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      final origin = request.headers['origin'];
      final corsHeaders = <String, String>{};

      // Origin prüfen und Header setzen
      if (origin != null) {
        if (config.allowedOrigins.contains('*')) {
          corsHeaders['Access-Control-Allow-Origin'] = '*';
        } else if (config.allowedOrigins.contains(origin)) {
          corsHeaders['Access-Control-Allow-Origin'] = origin;
          corsHeaders['Vary'] = 'Origin';
        } else {
          // Origin nicht erlaubt - keine CORS-Header
          if (request.method == 'OPTIONS') {
            return Response.forbidden('Origin not allowed');
          }
          return await innerHandler(request);
        }
      }

      // Weitere CORS-Header
      corsHeaders['Access-Control-Allow-Methods'] =
          config.allowedMethods.join(', ');
      corsHeaders['Access-Control-Allow-Headers'] =
          config.allowedHeaders.join(', ');

      if (config.allowCredentials) {
        corsHeaders['Access-Control-Allow-Credentials'] = 'true';
      }

      if (config.maxAge != null) {
        corsHeaders['Access-Control-Max-Age'] =
            config.maxAge!.inSeconds.toString();
      }

      // Preflight Request
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: corsHeaders);
      }

      // Normaler Request mit CORS-Headers
      final response = await innerHandler(request);
      return response.change(headers: corsHeaders);
    };
  };
}
```

---

## Rate Limiter

```dart
// lib/services/rate_limiter.dart
import 'dart:async';

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

  int get retryAfterSeconds {
    final seconds = resetAt.difference(DateTime.now()).inSeconds;
    return seconds > 0 ? seconds : 0;
  }
}

abstract class RateLimiter {
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  });
}

/// In-Memory Rate Limiter
class InMemoryRateLimiter implements RateLimiter {
  final Map<String, List<DateTime>> _requests = {};
  Timer? _cleanupTimer;

  InMemoryRateLimiter() {
    // Periodisches Cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanup(),
    );
  }

  void dispose() {
    _cleanupTimer?.cancel();
  }

  @override
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  }) async {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    // Requests für diesen Client
    final requests = _requests.putIfAbsent(clientId, () => []);

    // Alte Requests entfernen
    requests.removeWhere((time) => time.isBefore(windowStart));

    final resetAt = now.add(window);

    if (requests.length >= maxRequests) {
      // Rate Limit erreicht
      return RateLimitResult(
        allowed: false,
        remaining: 0,
        limit: maxRequests,
        resetAt: requests.isNotEmpty
            ? requests.first.add(window)
            : resetAt,
      );
    }

    // Request hinzufügen
    requests.add(now);

    return RateLimitResult(
      allowed: true,
      remaining: maxRequests - requests.length,
      limit: maxRequests,
      resetAt: resetAt,
    );
  }

  void _cleanup() {
    final now = DateTime.now();
    final maxAge = const Duration(hours: 1);

    _requests.removeWhere((_, requests) {
      requests.removeWhere((time) =>
          now.difference(time) > maxAge);
      return requests.isEmpty;
    });
  }
}

/// Redis Rate Limiter
class RedisRateLimiter implements RateLimiter {
  final dynamic _redis; // RedisClient

  RedisRateLimiter(this._redis);

  @override
  Future<RateLimitResult> check({
    required String clientId,
    required int maxRequests,
    required Duration window,
  }) async {
    final key = 'ratelimit:$clientId';
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;
    final windowStartMs = nowMs - window.inMilliseconds;

    // Sliding Window mit Sorted Set
    // 1. Alte Einträge entfernen
    await _redis.zremrangebyscore(key, 0, windowStartMs.toDouble());

    // 2. Aktuelle Anzahl
    final count = await _redis.zcard(key) as int;

    final resetAt = now.add(window);

    if (count >= maxRequests) {
      return RateLimitResult(
        allowed: false,
        remaining: 0,
        limit: maxRequests,
        resetAt: resetAt,
      );
    }

    // 3. Request hinzufügen
    await _redis.zadd(key, nowMs.toDouble(), nowMs.toString());

    // 4. TTL setzen
    await _redis.expire(key, window);

    return RateLimitResult(
      allowed: true,
      remaining: maxRequests - count - 1,
      limit: maxRequests,
      resetAt: resetAt,
    );
  }
}
```

---

## Rate Limit Middleware

```dart
// lib/middleware/rate_limit_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/rate_limiter.dart';

Middleware rateLimitMiddleware({
  required RateLimiter rateLimiter,
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
  String Function(Request)? keyExtractor,
}) {
  final getKey = keyExtractor ?? defaultKeyExtractor;

  return (Handler innerHandler) {
    return (Request request) async {
      final clientId = getKey(request);

      final result = await rateLimiter.check(
        clientId: clientId,
        maxRequests: maxRequests,
        window: window,
      );

      // Rate Limit Headers
      final headers = {
        'X-RateLimit-Limit': result.limit.toString(),
        'X-RateLimit-Remaining': result.remaining.toString(),
        'X-RateLimit-Reset': (result.resetAt.millisecondsSinceEpoch ~/ 1000).toString(),
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

String defaultKeyExtractor(Request request) {
  // 1. Authentifizierter User
  final userId = request.context['userId'];
  if (userId != null) return 'user:$userId';

  // 2. X-Forwarded-For (erster Eintrag)
  final forwarded = request.headers['x-forwarded-for'];
  if (forwarded != null) {
    final ip = forwarded.split(',').first.trim();
    return 'ip:$ip';
  }

  // 3. X-Real-IP
  final realIp = request.headers['x-real-ip'];
  if (realIp != null) return 'ip:$realIp';

  // 4. Fallback
  return 'ip:unknown';
}
```

---

## Validator

```dart
// lib/validation/validator.dart

class ValidationResult {
  final bool isValid;
  final Map<String, List<String>> errors;

  ValidationResult(this.errors) : isValid = errors.isEmpty;

  Map<String, dynamic> toJson() => {
        'valid': isValid,
        if (!isValid) 'errors': errors,
      };
}

class Validator {
  final Map<String, List<String>> _errors = {};

  ValidationResult get result => ValidationResult(Map.from(_errors));
  bool get isValid => _errors.isEmpty;

  void addError(String field, String message) {
    _errors.putIfAbsent(field, () => []).add(message);
  }

  void clear() => _errors.clear();

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
    if (value == null || (value is String && value.trim().isEmpty)) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    if (value is! String) {
      addError(field, '$field must be a string');
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

  /// Validiere Email
  String? email(String field, dynamic value, {bool required = true}) {
    return string(
      field,
      value,
      required: required,
      pattern: RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$'),
      patternMessage: 'Invalid email format',
    );
  }

  /// Validiere Integer
  int? integer(
    String field,
    dynamic value, {
    bool required = true,
    int? min,
    int? max,
  }) {
    if (value == null) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    int? intValue;
    if (value is int) {
      intValue = value;
    } else if (value is String) {
      intValue = int.tryParse(value);
    }

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

  /// Validiere Double
  double? number(
    String field,
    dynamic value, {
    bool required = true,
    double? min,
    double? max,
  }) {
    if (value == null) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    double? doubleValue;
    if (value is num) {
      doubleValue = value.toDouble();
    } else if (value is String) {
      doubleValue = double.tryParse(value);
    }

    if (doubleValue == null) {
      addError(field, '$field must be a valid number');
      return null;
    }

    if (min != null && doubleValue < min) {
      addError(field, '$field must be at least $min');
    }

    if (max != null && doubleValue > max) {
      addError(field, '$field must be at most $max');
    }

    return doubleValue;
  }

  /// Validiere Boolean
  bool? boolean(String field, dynamic value, {bool required = true}) {
    if (value == null) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    if (value is bool) return value;

    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }

    addError(field, '$field must be a boolean');
    return null;
  }

  /// Validiere Liste
  List<T>? list<T>(
    String field,
    dynamic value, {
    bool required = true,
    int? minLength,
    int? maxLength,
  }) {
    if (value == null) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    if (value is! List) {
      addError(field, '$field must be a list');
      return null;
    }

    if (minLength != null && value.length < minLength) {
      addError(field, '$field must have at least $minLength items');
    }

    if (maxLength != null && value.length > maxLength) {
      addError(field, '$field must have at most $maxLength items');
    }

    try {
      return value.cast<T>();
    } catch (e) {
      addError(field, '$field contains invalid items');
      return null;
    }
  }

  /// Validiere Enum
  T? enumValue<T extends Enum>(
    String field,
    dynamic value,
    List<T> values, {
    bool required = true,
  }) {
    if (value == null) {
      if (required) {
        addError(field, '$field is required');
      }
      return null;
    }

    final stringValue = value.toString();

    try {
      return values.firstWhere(
        (e) => e.name == stringValue || e.toString() == stringValue,
      );
    } catch (e) {
      addError(
        field,
        '$field must be one of: ${values.map((e) => e.name).join(", ")}',
      );
      return null;
    }
  }
}
```

---

## Sanitizer

```dart
// lib/utils/sanitizer.dart

class Sanitizer {
  /// Entferne HTML-Tags
  static String stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Escape HTML-Entities
  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Escape für SQL LIKE-Pattern
  static String escapeLike(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
  }

  /// Sanitize Dateiname
  static String sanitizeFilename(String filename) {
    // Nur sichere Zeichen
    var safe = filename.replaceAll(RegExp(r'[^\w\-\.]'), '_');

    // Keine doppelten Punkte (Path Traversal)
    safe = safe.replaceAll(RegExp(r'\.{2,}'), '.');

    // Keine führenden/trailing Punkte
    safe = safe.replaceAll(RegExp(r'^\.+|\.+$'), '');

    // Leerer Name?
    if (safe.isEmpty) safe = 'file';

    return safe;
  }

  /// Sanitize für Logging
  static String sanitizeForLog(String input, {int maxLength = 200}) {
    var sanitized = input
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');

    if (sanitized.length > maxLength) {
      sanitized = '${sanitized.substring(0, maxLength)}...';
    }

    return sanitized;
  }

  /// Normalize Whitespace
  static String normalizeWhitespace(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// URL-Parameter encoden
  static String encodeUrlParam(String input) {
    return Uri.encodeComponent(input);
  }

  /// JSON-String escapen
  static String escapeJson(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }
}
```

---

## Security Headers Middleware

```dart
// lib/middleware/security_headers_middleware.dart
import 'package:shelf/shelf.dart';

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
      final response = await innerHandler(request);

      final headers = <String, String>{};

      if (config.noSniff) {
        headers['X-Content-Type-Options'] = 'nosniff';
      }

      headers['X-Frame-Options'] = config.frameOptions;

      if (config.xssProtection) {
        headers['X-XSS-Protection'] = '1; mode=block';
      }

      headers['Referrer-Policy'] = config.referrerPolicy;

      if (config.contentSecurityPolicy != null) {
        headers['Content-Security-Policy'] = config.contentSecurityPolicy!;
      }

      if (config.noCache) {
        headers['Cache-Control'] = 'no-store, no-cache, must-revalidate';
        headers['Pragma'] = 'no-cache';
      }

      return response.change(headers: headers);
    };
  };
}
```

---

## Error Handler Middleware

```dart
// lib/middleware/error_handler_middleware.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {this.statusCode = 400});
}

class ValidationException extends ApiException {
  final Map<String, List<String>> errors;

  ValidationException(this.errors)
      : super('Validation failed', statusCode: 400);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Not found'])
      : super(message, statusCode: 404);
}

Middleware errorHandlerMiddleware({
  required bool isDevelopment,
  void Function(Object error, StackTrace stack)? onError,
}) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ValidationException catch (e) {
        return _jsonResponse(400, {
          'error': e.message,
          'errors': e.errors,
        });
      } on ApiException catch (e) {
        return _jsonResponse(e.statusCode, {'error': e.message});
      } catch (e, stack) {
        // Loggen
        onError?.call(e, stack);
        print('Error: $e\n$stack');

        // Response
        if (isDevelopment) {
          return _jsonResponse(500, {
            'error': e.toString(),
            'stack': stack.toString().split('\n').take(10).toList(),
          });
        }

        return _jsonResponse(500, {'error': 'Internal server error'});
      }
    };
  };
}

Response _jsonResponse(int statusCode, Map<String, dynamic> body) {
  return Response(
    statusCode,
    body: jsonEncode(body),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Sichere Repository Methoden

```dart
// lib/repositories/secure_product_repository.dart
import 'package:postgres/postgres.dart';
import '../utils/sanitizer.dart';

class ProductRepository {
  final Connection _db;

  static const _allowedSortColumns = {'id', 'name', 'price', 'created_at'};
  static const _maxLimit = 100;

  ProductRepository(this._db);

  Future<List<Product>> search(String query) async {
    // Query sanitizen
    final escapedQuery = Sanitizer.escapeLike(query.trim());

    if (escapedQuery.isEmpty) {
      return [];
    }

    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM products
        WHERE name ILIKE @pattern OR description ILIKE @pattern
        LIMIT 50
      '''),
      parameters: {'pattern': '%$escapedQuery%'},
    );

    return result.map((r) => Product.fromRow(r.toColumnMap())).toList();
  }

  Future<List<Product>> findAll({
    String sortBy = 'created_at',
    bool descending = true,
    int limit = 20,
    int offset = 0,
  }) async {
    // Whitelist für Sortierung
    if (!_allowedSortColumns.contains(sortBy)) {
      sortBy = 'created_at';
    }

    // Limits validieren
    limit = limit.clamp(1, _maxLimit);
    offset = offset.clamp(0, 10000);

    final direction = descending ? 'DESC' : 'ASC';

    // Spalte ist gewhitelistet - sicher
    final result = await _db.execute(
      Sql.named('''
        SELECT * FROM products
        ORDER BY $sortBy $direction
        LIMIT @limit OFFSET @offset
      '''),
      parameters: {'limit': limit, 'offset': offset},
    );

    return result.map((r) => Product.fromRow(r.toColumnMap())).toList();
  }
}
```

