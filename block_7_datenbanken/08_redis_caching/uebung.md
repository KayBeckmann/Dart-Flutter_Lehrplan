# Übung 7.8: Redis & Caching

## Ziel

Implementiere ein Caching-System für die Produkt-API.

---

## Vorbereitung

### Redis starten

```bash
docker run --name redis -p 6379:6379 -d redis:7
```

### Dependencies

```yaml
dependencies:
  redis: ^3.1.0
```

---

## Aufgabe 1: Redis-Verbindung (10 min)

```dart
// lib/cache/redis_client.dart

class RedisClient {
  final RedisConnection _conn = RedisConnection();
  Command? _command;

  Future<void> connect({String host = 'localhost', int port = 6379}) async {
    // TODO: Verbindung herstellen
  }

  Future<void> close() async {
    // TODO: Verbindung schließen
  }

  // TODO: set, get, del Methoden
}
```

---

## Aufgabe 2: Basis-Operationen (15 min)

Implementiere die grundlegenden Cache-Methoden:

```dart
// String Operations
Future<void> set(String key, String value, {Duration? ttl});
Future<String?> get(String key);
Future<void> del(String key);

// JSON Helpers
Future<void> setJson(String key, Map<String, dynamic> value, {Duration? ttl});
Future<Map<String, dynamic>?> getJson(String key);

// Hilfsmethoden
Future<bool> exists(String key);
Future<void> expire(String key, Duration ttl);
```

---

## Aufgabe 3: Product Cache (20 min)

```dart
// lib/cache/product_cache.dart

class ProductCache {
  final RedisClient _redis;
  final ProductRepository _repo;
  final Duration _ttl;

  ProductCache(this._redis, this._repo, {Duration? ttl})
      : _ttl = ttl ?? Duration(hours: 1);

  /// Produkt aus Cache oder DB laden
  Future<Product?> getProduct(int id) async {
    // TODO: Cache-Aside Pattern
    // 1. Cache prüfen
    // 2. Bei Miss: aus DB laden und cachen
  }

  /// Liste von Produkten cachen
  Future<List<Product>> getProducts({String? category}) async {
    // TODO: Cache-Key basierend auf Parametern
    // z.B. "products:all" oder "products:category:electronics"
  }

  /// Cache invalidieren
  Future<void> invalidateProduct(int id) async {
    // TODO: Produkt-Key löschen
  }

  Future<void> invalidateAll() async {
    // TODO: Alle Produkt-Keys löschen
  }

  /// Produkt aktualisieren (Write-Through)
  Future<Product> updateProduct(int id, ProductUpdate data) async {
    // TODO: DB updaten + Cache aktualisieren
  }
}
```

---

## Aufgabe 4: Session-Manager (15 min)

```dart
// lib/cache/session_manager.dart

class Session {
  final String id;
  final int userId;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;

  // TODO: Konstruktor, toJson, fromJson
}

class SessionManager {
  final RedisClient _redis;
  final Duration _sessionDuration;

  SessionManager(this._redis, {Duration? duration})
      : _sessionDuration = duration ?? Duration(hours: 24);

  /// Neue Session erstellen
  Future<Session> createSession(int userId, String email) async {
    // TODO: Session-ID generieren (UUID)
    // TODO: In Redis speichern mit TTL
  }

  /// Session validieren und laden
  Future<Session?> getSession(String sessionId) async {
    // TODO: Session laden
    // TODO: Bei Erfolg: TTL erneuern (Sliding Expiration)
  }

  /// Session beenden
  Future<void> destroySession(String sessionId) async {
    // TODO: Aus Redis löschen
  }

  /// Alle Sessions eines Users beenden
  Future<void> destroyUserSessions(int userId) async {
    // TODO: Pattern-basiert suchen und löschen
  }
}
```

---

## Aufgabe 5: Rate Limiter (15 min)

```dart
// lib/cache/rate_limiter.dart

class RateLimitResult {
  final bool allowed;
  final int remaining;
  final int resetInSeconds;

  RateLimitResult({
    required this.allowed,
    required this.remaining,
    required this.resetInSeconds,
  });
}

class RateLimiter {
  final RedisClient _redis;

  RateLimiter(this._redis);

  /// Sliding Window Rate Limiting
  Future<RateLimitResult> checkLimit({
    required String clientId,
    int maxRequests = 100,
    int windowSeconds = 60,
  }) async {
    // TODO: Sorted Set für Sliding Window
    // 1. Alte Einträge entfernen (ZREMRANGEBYSCORE)
    // 2. Anzahl prüfen (ZCARD)
    // 3. Bei erlaubt: Request hinzufügen (ZADD)
    // 4. TTL setzen (EXPIRE)
  }
}
```

---

## Aufgabe 6: Cache Middleware (10 min)

```dart
// Middleware für shelf

Middleware cacheMiddleware(ProductCache cache) {
  return (Handler handler) {
    return (Request request) async {
      // Nur GET-Requests cachen
      if (request.method != 'GET') {
        return handler(request);
      }

      final path = request.url.path;

      // Pattern: /api/products/:id
      final productMatch = RegExp(r'^api/products/(\d+)$').firstMatch(path);
      if (productMatch != null) {
        final id = int.parse(productMatch.group(1)!);
        final cached = await cache.getProduct(id);

        if (cached != null) {
          return Response.ok(
            jsonEncode(cached.toJson()),
            headers: {
              'content-type': 'application/json',
              'x-cache': 'HIT',
            },
          );
        }
      }

      // Cache Miss - normale Handler-Kette
      final response = await handler(request);
      return response.change(headers: {'x-cache': 'MISS'});
    };
  };
}
```

---

## Aufgabe 7: Cache-Tags (Bonus, 15 min)

```dart
// lib/cache/tagged_cache.dart

class TaggedCache {
  final RedisClient _redis;

  TaggedCache(this._redis);

  /// Mit Tags cachen
  Future<void> set(
    String key,
    String value,
    List<String> tags, {
    Duration? ttl,
  }) async {
    // TODO: Wert speichern
    // TODO: Key zu Tag-Sets hinzufügen
  }

  /// Tag invalidieren (alle zugehörigen Keys löschen)
  Future<int> invalidateTag(String tag) async {
    // TODO: Keys aus Tag-Set holen
    // TODO: Alle Keys löschen
    // TODO: Tag-Set löschen
    // Return: Anzahl gelöschter Keys
  }

  /// Mehrere Tags invalidieren
  Future<int> invalidateTags(List<String> tags) async {
    // TODO
  }
}

// Verwendung:
// await cache.set('product:1', data, ['products', 'category:electronics']);
// await cache.invalidateTag('category:electronics');
```

---

## Testen

```dart
Future<void> main() async {
  final redis = RedisClient();
  await redis.connect();

  // Basis-Tests
  await redis.set('test', 'value', ttl: Duration(seconds: 60));
  print(await redis.get('test')); // 'value'

  // Product Cache
  final cache = ProductCache(redis, productRepo);
  final product = await cache.getProduct(1);
  print('Product: ${product?.name}');

  // Session
  final sessions = SessionManager(redis);
  final session = await sessions.createSession(1, 'test@example.com');
  print('Session ID: ${session.id}');

  // Rate Limiting
  final limiter = RateLimiter(redis);
  final result = await limiter.checkLimit(clientId: '127.0.0.1');
  print('Allowed: ${result.allowed}, Remaining: ${result.remaining}');

  await redis.close();
}
```

---

## Abgabe-Checkliste

- [ ] RedisClient mit connect/close
- [ ] set, get, del Methoden
- [ ] setJson, getJson Helpers
- [ ] ProductCache mit Cache-Aside
- [ ] Cache-Invalidierung (einzeln + alle)
- [ ] SessionManager mit create/get/destroy
- [ ] Sliding Expiration für Sessions
- [ ] RateLimiter mit Sliding Window
- [ ] (Bonus) TaggedCache
- [ ] (Bonus) Cache Middleware
