# Einheit 7.8: Redis & Caching

## Lernziele

Nach dieser Einheit kannst du:
- Redis-Grundlagen verstehen und anwenden
- Caching-Strategien implementieren
- Session-Management mit Redis umsetzen
- Cache-Invalidierung richtig handhaben

---

## Was ist Redis?

**Redis** (Remote Dictionary Server) ist ein In-Memory-Datenstore, der als Cache, Message Broker und Datenbank verwendet wird.

### Eigenschaften

- **In-Memory**: Extrem schnell (< 1ms Latenz)
- **Persistent**: Optional auf Disk speichern
- **Datenstrukturen**: Strings, Lists, Sets, Hashes, Sorted Sets
- **Pub/Sub**: Messaging zwischen Services
- **TTL**: Automatisches Ablaufen von Keys

### Wann Redis?

- Caching von Datenbankabfragen
- Session-Speicherung
- Rate Limiting
- Echtzeit-Leaderboards
- Pub/Sub Messaging

---

## Redis Setup

### Docker

```bash
docker run --name redis \
  -p 6379:6379 \
  -d redis:7
```

### Dart Package

```yaml
dependencies:
  redis: ^3.1.0
```

---

## Verbindung herstellen

```dart
import 'package:redis/redis.dart';

Future<void> main() async {
  final conn = RedisConnection();
  final command = await conn.connect('localhost', 6379);

  // Einfacher Test
  await command.send_object(['SET', 'hello', 'world']);
  final result = await command.send_object(['GET', 'hello']);
  print(result); // 'world'

  await conn.close();
}
```

---

## Basis-Operationen

### Strings

```dart
// SET und GET
await command.send_object(['SET', 'user:1:name', 'Max']);
final name = await command.send_object(['GET', 'user:1:name']);

// Mit TTL (Sekunden)
await command.send_object(['SET', 'session:abc123', 'data', 'EX', '3600']);

// Inkrementieren
await command.send_object(['SET', 'counter', '0']);
await command.send_object(['INCR', 'counter']);
await command.send_object(['INCRBY', 'counter', '5']);

// Nur setzen wenn nicht existiert
await command.send_object(['SETNX', 'lock:resource', '1']);
```

### Hashes (Objekte)

```dart
// Hash setzen
await command.send_object([
  'HSET', 'user:1',
  'name', 'Max',
  'email', 'max@example.com',
  'age', '30'
]);

// Einzelnes Feld lesen
final email = await command.send_object(['HGET', 'user:1', 'email']);

// Alle Felder lesen
final user = await command.send_object(['HGETALL', 'user:1']);
// ['name', 'Max', 'email', 'max@example.com', 'age', '30']

// Feld inkrementieren
await command.send_object(['HINCRBY', 'user:1', 'age', '1']);
```

### Listen

```dart
// Am Ende hinzufügen
await command.send_object(['RPUSH', 'queue:tasks', 'task1', 'task2']);

// Am Anfang hinzufügen
await command.send_object(['LPUSH', 'queue:tasks', 'task0']);

// Vom Anfang entfernen
final task = await command.send_object(['LPOP', 'queue:tasks']);

// Bereich lesen
final tasks = await command.send_object(['LRANGE', 'queue:tasks', '0', '-1']);
```

### Sets

```dart
// Hinzufügen
await command.send_object(['SADD', 'tags:product:1', 'new', 'sale', 'featured']);

// Prüfen ob enthalten
final isMember = await command.send_object(['SISMEMBER', 'tags:product:1', 'new']);

// Alle Elemente
final tags = await command.send_object(['SMEMBERS', 'tags:product:1']);

// Entfernen
await command.send_object(['SREM', 'tags:product:1', 'sale']);
```

### Sorted Sets (Rankings)

```dart
// Hinzufügen mit Score
await command.send_object(['ZADD', 'leaderboard', '100', 'player1', '85', 'player2']);

// Top 10
final top10 = await command.send_object(['ZREVRANGE', 'leaderboard', '0', '9', 'WITHSCORES']);

// Rang eines Players
final rank = await command.send_object(['ZREVRANK', 'leaderboard', 'player1']);
```

---

## Caching-Strategien

### Cache-Aside (Lazy Loading)

```dart
class ProductCache {
  final Command _redis;
  final ProductRepository _repo;

  ProductCache(this._redis, this._repo);

  Future<Product?> getProduct(int id) async {
    final key = 'product:$id';

    // 1. Cache prüfen
    final cached = await _redis.send_object(['GET', key]);
    if (cached != null) {
      return Product.fromJson(jsonDecode(cached as String));
    }

    // 2. Aus DB laden
    final product = await _repo.findById(id);
    if (product == null) return null;

    // 3. In Cache speichern (1 Stunde TTL)
    await _redis.send_object([
      'SET', key, jsonEncode(product.toJson()),
      'EX', '3600'
    ]);

    return product;
  }
}
```

### Write-Through

```dart
class ProductService {
  final Command _redis;
  final ProductRepository _repo;

  Future<Product> updateProduct(int id, ProductUpdate data) async {
    // 1. In DB speichern
    final product = await _repo.update(id, data);

    // 2. Cache aktualisieren
    await _redis.send_object([
      'SET', 'product:$id', jsonEncode(product.toJson()),
      'EX', '3600'
    ]);

    return product;
  }
}
```

### Write-Behind (Async)

```dart
class ProductService {
  final Command _redis;
  final ProductRepository _repo;

  Future<void> updateProduct(int id, ProductUpdate data) async {
    // 1. Sofort in Cache schreiben
    await _redis.send_object([
      'SET', 'product:$id', jsonEncode(data.toJson()),
    ]);

    // 2. In Queue für DB-Write
    await _redis.send_object([
      'RPUSH', 'queue:db_writes',
      jsonEncode({'type': 'update_product', 'id': id, 'data': data.toJson()})
    ]);

    // Background Worker verarbeitet die Queue
  }
}
```

---

## Cache-Invalidierung

### Einzelnen Key löschen

```dart
await _redis.send_object(['DEL', 'product:$id']);
```

### Pattern-basiert löschen

```dart
// Alle Produkt-Keys finden
final keys = await _redis.send_object(['KEYS', 'product:*']);

// Löschen
if (keys != null && (keys as List).isNotEmpty) {
  await _redis.send_object(['DEL', ...keys]);
}
```

### Cache-Tags

```dart
class TaggedCache {
  final Command _redis;

  Future<void> set(String key, String value, List<String> tags) async {
    // Wert speichern
    await _redis.send_object(['SET', key, value, 'EX', '3600']);

    // Tags tracken
    for (final tag in tags) {
      await _redis.send_object(['SADD', 'tag:$tag', key]);
    }
  }

  Future<void> invalidateTag(String tag) async {
    // Alle Keys mit Tag finden
    final keys = await _redis.send_object(['SMEMBERS', 'tag:$tag']);

    if (keys != null && (keys as List).isNotEmpty) {
      await _redis.send_object(['DEL', ...keys]);
    }

    // Tag-Set löschen
    await _redis.send_object(['DEL', 'tag:$tag']);
  }
}

// Verwendung
await cache.set('product:1', data, ['products', 'category:electronics']);
await cache.invalidateTag('category:electronics'); // Invalidiert alle
```

---

## Session-Management

```dart
class SessionManager {
  final Command _redis;
  final Duration sessionDuration;

  SessionManager(this._redis, {this.sessionDuration = const Duration(hours: 24)});

  Future<String> createSession(Map<String, dynamic> userData) async {
    final sessionId = Uuid().v4();
    final key = 'session:$sessionId';

    await _redis.send_object([
      'SET', key, jsonEncode(userData),
      'EX', sessionDuration.inSeconds.toString()
    ]);

    return sessionId;
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    final key = 'session:$sessionId';
    final data = await _redis.send_object(['GET', key]);

    if (data == null) return null;

    // Session verlängern
    await _redis.send_object(['EXPIRE', key, sessionDuration.inSeconds.toString()]);

    return jsonDecode(data as String);
  }

  Future<void> destroySession(String sessionId) async {
    await _redis.send_object(['DEL', 'session:$sessionId']);
  }
}
```

---

## Rate Limiting

```dart
class RateLimiter {
  final Command _redis;

  Future<bool> isAllowed(String clientId, {int maxRequests = 100, int windowSeconds = 60}) async {
    final key = 'ratelimit:$clientId';
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - (windowSeconds * 1000);

    // Alte Einträge entfernen
    await _redis.send_object(['ZREMRANGEBYSCORE', key, '0', windowStart.toString()]);

    // Anzahl Requests im Fenster
    final count = await _redis.send_object(['ZCARD', key]);

    if ((count as int) >= maxRequests) {
      return false;
    }

    // Request hinzufügen
    await _redis.send_object(['ZADD', key, now.toString(), '$now']);
    await _redis.send_object(['EXPIRE', key, windowSeconds.toString()]);

    return true;
  }
}
```

---

## Redis-Wrapper Klasse

```dart
class RedisClient {
  final RedisConnection _conn;
  Command? _command;

  RedisClient({String host = 'localhost', int port = 6379})
      : _conn = RedisConnection();

  Future<void> connect() async {
    _command = await _conn.connect('localhost', 6379);
  }

  Future<void> close() async {
    await _conn.close();
  }

  // String Operations
  Future<void> set(String key, String value, {Duration? ttl}) async {
    if (ttl != null) {
      await _command!.send_object(['SET', key, value, 'EX', ttl.inSeconds.toString()]);
    } else {
      await _command!.send_object(['SET', key, value]);
    }
  }

  Future<String?> get(String key) async {
    final result = await _command!.send_object(['GET', key]);
    return result as String?;
  }

  Future<void> del(String key) async {
    await _command!.send_object(['DEL', key]);
  }

  // Hash Operations
  Future<void> hset(String key, Map<String, String> fields) async {
    final args = ['HSET', key];
    fields.forEach((k, v) {
      args.add(k);
      args.add(v);
    });
    await _command!.send_object(args);
  }

  Future<Map<String, String>> hgetall(String key) async {
    final result = await _command!.send_object(['HGETALL', key]);
    if (result == null) return {};

    final list = result as List;
    final map = <String, String>{};
    for (var i = 0; i < list.length; i += 2) {
      map[list[i] as String] = list[i + 1] as String;
    }
    return map;
  }

  // JSON Helpers
  Future<void> setJson(String key, Map<String, dynamic> value, {Duration? ttl}) async {
    await set(key, jsonEncode(value), ttl: ttl);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final data = await get(key);
    if (data == null) return null;
    return jsonDecode(data);
  }
}
```

---

## Zusammenfassung

| Operation | Redis Befehl |
|-----------|--------------|
| String setzen | SET key value |
| String lesen | GET key |
| Mit TTL | SET key value EX seconds |
| Löschen | DEL key |
| Hash setzen | HSET key field value |
| Hash lesen | HGETALL key |
| Liste pushen | RPUSH key value |
| Liste poppen | LPOP key |

| Strategie | Verwendung |
|-----------|------------|
| Cache-Aside | Lazy Loading, lesen-intensiv |
| Write-Through | Konsistenz wichtig |
| Write-Behind | Hohe Schreiblast |

---

## Fazit Block 7

Du hast in diesem Block gelernt:

1. **SQL-Grundlagen** - Relationale Datenbanken verstehen
2. **PostgreSQL mit Dart** - Queries ausführen
3. **Repository Pattern** - Saubere Architektur
4. **Relationale Modellierung** - Beziehungen und JOINs
5. **Migrations** - Versionierte Schema-Änderungen
6. **MongoDB** - Dokumentenorientierte Alternative
7. **Komplexe Queries** - Aggregationen und Analytics
8. **Redis & Caching** - Performance-Optimierung

Mit diesen Kenntnissen kannst du professionelle Backend-Systeme mit effizienter Datenhaltung entwickeln.
