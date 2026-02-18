# Lösung 7.8: Redis & Caching

## Redis Client

```dart
// lib/cache/redis_client.dart
import 'dart:convert';
import 'package:redis/redis.dart';

class RedisClient {
  final RedisConnection _conn = RedisConnection();
  Command? _command;

  Future<void> connect({String host = 'localhost', int port = 6379}) async {
    _command = await _conn.connect(host, port);
  }

  Future<void> close() async {
    await _conn.close();
  }

  Command get command {
    if (_command == null) throw StateError('Not connected');
    return _command!;
  }

  // String Operations
  Future<void> set(String key, String value, {Duration? ttl}) async {
    if (ttl != null) {
      await command.send_object(['SET', key, value, 'EX', ttl.inSeconds.toString()]);
    } else {
      await command.send_object(['SET', key, value]);
    }
  }

  Future<String?> get(String key) async {
    final result = await command.send_object(['GET', key]);
    return result as String?;
  }

  Future<void> del(String key) async {
    await command.send_object(['DEL', key]);
  }

  Future<void> delPattern(String pattern) async {
    final keys = await command.send_object(['KEYS', pattern]);
    if (keys != null && (keys as List).isNotEmpty) {
      await command.send_object(['DEL', ...keys]);
    }
  }

  Future<bool> exists(String key) async {
    final result = await command.send_object(['EXISTS', key]);
    return (result as int) > 0;
  }

  Future<void> expire(String key, Duration ttl) async {
    await command.send_object(['EXPIRE', key, ttl.inSeconds.toString()]);
  }

  // JSON Helpers
  Future<void> setJson(String key, Map<String, dynamic> value, {Duration? ttl}) async {
    await set(key, jsonEncode(value), ttl: ttl);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final data = await get(key);
    if (data == null) return null;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Hash Operations
  Future<void> hset(String key, String field, String value) async {
    await command.send_object(['HSET', key, field, value]);
  }

  Future<void> hmset(String key, Map<String, String> fields) async {
    final args = ['HSET', key];
    fields.forEach((k, v) {
      args.add(k);
      args.add(v);
    });
    await command.send_object(args);
  }

  Future<String?> hget(String key, String field) async {
    final result = await command.send_object(['HGET', key, field]);
    return result as String?;
  }

  Future<Map<String, String>> hgetall(String key) async {
    final result = await command.send_object(['HGETALL', key]);
    if (result == null) return {};

    final list = result as List;
    final map = <String, String>{};
    for (var i = 0; i < list.length; i += 2) {
      map[list[i] as String] = list[i + 1] as String;
    }
    return map;
  }

  // Set Operations
  Future<void> sadd(String key, String value) async {
    await command.send_object(['SADD', key, value]);
  }

  Future<List<String>> smembers(String key) async {
    final result = await command.send_object(['SMEMBERS', key]);
    if (result == null) return [];
    return (result as List).cast<String>();
  }

  // Sorted Set Operations
  Future<void> zadd(String key, double score, String member) async {
    await command.send_object(['ZADD', key, score.toString(), member]);
  }

  Future<int> zcard(String key) async {
    final result = await command.send_object(['ZCARD', key]);
    return result as int;
  }

  Future<void> zremrangebyscore(String key, double min, double max) async {
    await command.send_object(['ZREMRANGEBYSCORE', key, min.toString(), max.toString()]);
  }
}
```

---

## Product Cache

```dart
// lib/cache/product_cache.dart
import 'dart:convert';

class ProductCache {
  final RedisClient _redis;
  final ProductRepository _repo;
  final Duration _ttl;

  ProductCache(this._redis, this._repo, {Duration? ttl})
      : _ttl = ttl ?? const Duration(hours: 1);

  String _productKey(int id) => 'product:$id';
  String _listKey(String? category) =>
      category != null ? 'products:category:$category' : 'products:all';

  Future<Product?> getProduct(int id) async {
    final key = _productKey(id);

    // 1. Cache prüfen
    final cached = await _redis.getJson(key);
    if (cached != null) {
      return Product.fromJson(cached);
    }

    // 2. Aus DB laden
    final product = await _repo.findById(id);
    if (product == null) return null;

    // 3. In Cache speichern
    await _redis.setJson(key, product.toJson(), ttl: _ttl);

    return product;
  }

  Future<List<Product>> getProducts({String? category}) async {
    final key = _listKey(category);

    // Cache prüfen
    final cached = await _redis.get(key);
    if (cached != null) {
      final list = jsonDecode(cached) as List;
      return list.map((e) => Product.fromJson(e)).toList();
    }

    // Aus DB laden
    final products = category != null
        ? await _repo.findByCategory(category)
        : await _repo.findAll();

    // Cachen
    await _redis.set(
      key,
      jsonEncode(products.map((p) => p.toJson()).toList()),
      ttl: _ttl,
    );

    return products;
  }

  Future<void> invalidateProduct(int id) async {
    await _redis.del(_productKey(id));
    // Listen auch invalidieren
    await _redis.delPattern('products:*');
  }

  Future<void> invalidateAll() async {
    await _redis.delPattern('product:*');
    await _redis.delPattern('products:*');
  }

  Future<Product> updateProduct(int id, ProductUpdate data) async {
    // 1. DB updaten
    final product = await _repo.update(id, data);
    if (product == null) throw NotFoundException('Product not found');

    // 2. Cache aktualisieren
    await _redis.setJson(_productKey(id), product.toJson(), ttl: _ttl);

    // 3. Listen invalidieren
    await _redis.delPattern('products:*');

    return product;
  }
}
```

---

## Session Manager

```dart
// lib/cache/session_manager.dart
import 'dart:convert';
import 'package:uuid/uuid.dart';

class Session {
  final String id;
  final int userId;
  final String email;
  final DateTime createdAt;
  final DateTime expiresAt;

  Session({
    required this.id,
    required this.userId,
    required this.email,
    required this.createdAt,
    required this.expiresAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['userId'] as int,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'email': email,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class SessionManager {
  final RedisClient _redis;
  final Duration _sessionDuration;

  SessionManager(this._redis, {Duration? duration})
      : _sessionDuration = duration ?? const Duration(hours: 24);

  String _sessionKey(String id) => 'session:$id';
  String _userSessionsKey(int userId) => 'user_sessions:$userId';

  Future<Session> createSession(int userId, String email) async {
    final sessionId = const Uuid().v4();
    final now = DateTime.now();

    final session = Session(
      id: sessionId,
      userId: userId,
      email: email,
      createdAt: now,
      expiresAt: now.add(_sessionDuration),
    );

    // Session speichern
    await _redis.setJson(_sessionKey(sessionId), session.toJson(), ttl: _sessionDuration);

    // Session zu User-Sessions hinzufügen
    await _redis.sadd(_userSessionsKey(userId), sessionId);

    return session;
  }

  Future<Session?> getSession(String sessionId) async {
    final data = await _redis.getJson(_sessionKey(sessionId));
    if (data == null) return null;

    final session = Session.fromJson(data);

    // Sliding Expiration: TTL erneuern
    await _redis.expire(_sessionKey(sessionId), _sessionDuration);

    // expiresAt aktualisieren
    final updated = Session(
      id: session.id,
      userId: session.userId,
      email: session.email,
      createdAt: session.createdAt,
      expiresAt: DateTime.now().add(_sessionDuration),
    );
    await _redis.setJson(_sessionKey(sessionId), updated.toJson(), ttl: _sessionDuration);

    return updated;
  }

  Future<void> destroySession(String sessionId) async {
    // Session-Daten laden für User-ID
    final data = await _redis.getJson(_sessionKey(sessionId));
    if (data != null) {
      final userId = data['userId'] as int;
      // Aus User-Sessions entfernen
      await _redis.command.send_object(['SREM', _userSessionsKey(userId), sessionId]);
    }

    // Session löschen
    await _redis.del(_sessionKey(sessionId));
  }

  Future<void> destroyUserSessions(int userId) async {
    final sessionIds = await _redis.smembers(_userSessionsKey(userId));

    for (final sessionId in sessionIds) {
      await _redis.del(_sessionKey(sessionId));
    }

    await _redis.del(_userSessionsKey(userId));
  }
}
```

---

## Rate Limiter

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

  Future<RateLimitResult> checkLimit({
    required String clientId,
    int maxRequests = 100,
    int windowSeconds = 60,
  }) async {
    final key = 'ratelimit:$clientId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - (windowSeconds * 1000);

    // 1. Alte Einträge entfernen
    await _redis.zremrangebyscore(key, 0, windowStart.toDouble());

    // 2. Aktuelle Anzahl
    final count = await _redis.zcard(key);

    if (count >= maxRequests) {
      // Rate limit exceeded
      final oldestEntry = await _redis.command.send_object([
        'ZRANGE', key, '0', '0', 'WITHSCORES'
      ]);

      int resetIn = windowSeconds;
      if (oldestEntry != null && (oldestEntry as List).length >= 2) {
        final oldestTime = double.parse(oldestEntry[1] as String).toInt();
        resetIn = ((oldestTime + windowSeconds * 1000) - now) ~/ 1000;
        if (resetIn < 0) resetIn = 0;
      }

      return RateLimitResult(
        allowed: false,
        remaining: 0,
        resetInSeconds: resetIn,
      );
    }

    // 3. Request hinzufügen
    await _redis.zadd(key, now.toDouble(), '$now');

    // 4. TTL setzen
    await _redis.expire(key, Duration(seconds: windowSeconds));

    return RateLimitResult(
      allowed: true,
      remaining: maxRequests - count - 1,
      resetInSeconds: windowSeconds,
    );
  }
}
```

---

## Tagged Cache

```dart
// lib/cache/tagged_cache.dart

class TaggedCache {
  final RedisClient _redis;

  TaggedCache(this._redis);

  String _tagKey(String tag) => 'tag:$tag';

  Future<void> set(
    String key,
    String value,
    List<String> tags, {
    Duration? ttl,
  }) async {
    // Wert speichern
    await _redis.set(key, value, ttl: ttl);

    // Key zu Tag-Sets hinzufügen
    for (final tag in tags) {
      await _redis.sadd(_tagKey(tag), key);
    }
  }

  Future<String?> get(String key) async {
    return _redis.get(key);
  }

  Future<int> invalidateTag(String tag) async {
    final tagKey = _tagKey(tag);

    // Keys aus Tag-Set holen
    final keys = await _redis.smembers(tagKey);

    if (keys.isEmpty) return 0;

    // Alle Keys löschen
    for (final key in keys) {
      await _redis.del(key);
    }

    // Tag-Set löschen
    await _redis.del(tagKey);

    return keys.length;
  }

  Future<int> invalidateTags(List<String> tags) async {
    int total = 0;
    for (final tag in tags) {
      total += await invalidateTag(tag);
    }
    return total;
  }
}
```

---

## Main

```dart
Future<void> main() async {
  final redis = RedisClient();
  await redis.connect();

  print('=== Redis Connected ===\n');

  // Basis-Test
  await redis.set('test', 'hello', ttl: Duration(seconds: 60));
  print('GET test: ${await redis.get("test")}');

  // Session Test
  final sessions = SessionManager(redis);
  final session = await sessions.createSession(1, 'test@example.com');
  print('\nSession created: ${session.id}');

  final loaded = await sessions.getSession(session.id);
  print('Session loaded: ${loaded?.email}');

  // Rate Limiter Test
  final limiter = RateLimiter(redis);
  for (var i = 0; i < 5; i++) {
    final result = await limiter.checkLimit(
      clientId: 'test-client',
      maxRequests: 3,
      windowSeconds: 60,
    );
    print('\nRequest ${i + 1}: allowed=${result.allowed}, remaining=${result.remaining}');
  }

  // Tagged Cache Test
  final taggedCache = TaggedCache(redis);
  await taggedCache.set('product:1', '{"name":"Laptop"}', ['products', 'electronics']);
  await taggedCache.set('product:2', '{"name":"Mouse"}', ['products', 'electronics']);
  await taggedCache.set('product:3', '{"name":"Shirt"}', ['products', 'clothing']);

  print('\nInvalidating electronics tag...');
  final deleted = await taggedCache.invalidateTag('electronics');
  print('Deleted $deleted keys');

  await redis.close();
  print('\n=== Redis Closed ===');
}
```
