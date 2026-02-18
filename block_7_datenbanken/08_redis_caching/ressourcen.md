# Ressourcen: Redis & Caching

## Offizielle Dokumentation

- [redis Package (pub.dev)](https://pub.dev/packages/redis)
- [Redis Documentation](https://redis.io/docs/)
- [Redis Commands](https://redis.io/commands/)

## Cheat Sheet: Verbindung

```dart
import 'package:redis/redis.dart';

final conn = RedisConnection();
final command = await conn.connect('localhost', 6379);

// Mit Passwort
await command.send_object(['AUTH', 'password']);

// Schließen
await conn.close();
```

## Cheat Sheet: String Commands

```dart
// SET
await cmd.send_object(['SET', 'key', 'value']);

// SET mit TTL (Sekunden)
await cmd.send_object(['SET', 'key', 'value', 'EX', '3600']);

// SET mit TTL (Millisekunden)
await cmd.send_object(['SET', 'key', 'value', 'PX', '60000']);

// SET nur wenn nicht existiert
await cmd.send_object(['SETNX', 'key', 'value']);

// GET
final value = await cmd.send_object(['GET', 'key']);

// DEL
await cmd.send_object(['DEL', 'key']);

// INCR / DECR
await cmd.send_object(['INCR', 'counter']);
await cmd.send_object(['INCRBY', 'counter', '5']);

// EXPIRE
await cmd.send_object(['EXPIRE', 'key', '3600']);

// TTL (verbleibende Zeit)
final ttl = await cmd.send_object(['TTL', 'key']);
```

## Cheat Sheet: Hash Commands

```dart
// HSET
await cmd.send_object(['HSET', 'user:1', 'name', 'Max', 'email', 'max@example.com']);

// HGET
final name = await cmd.send_object(['HGET', 'user:1', 'name']);

// HGETALL
final user = await cmd.send_object(['HGETALL', 'user:1']);
// ['name', 'Max', 'email', 'max@example.com']

// HINCRBY
await cmd.send_object(['HINCRBY', 'user:1', 'visits', '1']);
```

## Cheat Sheet: List Commands

```dart
// RPUSH (Ende)
await cmd.send_object(['RPUSH', 'queue', 'item1', 'item2']);

// LPUSH (Anfang)
await cmd.send_object(['LPUSH', 'queue', 'item0']);

// LPOP (vom Anfang)
final item = await cmd.send_object(['LPOP', 'queue']);

// RPOP (vom Ende)
final item = await cmd.send_object(['RPOP', 'queue']);

// LRANGE (Bereich)
final items = await cmd.send_object(['LRANGE', 'queue', '0', '-1']);
```

## Cheat Sheet: Set Commands

```dart
// SADD
await cmd.send_object(['SADD', 'tags', 'new', 'sale']);

// SMEMBERS
final tags = await cmd.send_object(['SMEMBERS', 'tags']);

// SISMEMBER
final exists = await cmd.send_object(['SISMEMBER', 'tags', 'new']);

// SREM
await cmd.send_object(['SREM', 'tags', 'sale']);
```

## Cheat Sheet: Sorted Set Commands

```dart
// ZADD
await cmd.send_object(['ZADD', 'leaderboard', '100', 'player1']);

// ZRANGE (aufsteigend)
final bottom = await cmd.send_object(['ZRANGE', 'leaderboard', '0', '9']);

// ZREVRANGE (absteigend)
final top = await cmd.send_object(['ZREVRANGE', 'leaderboard', '0', '9', 'WITHSCORES']);

// ZRANK / ZREVRANK
final rank = await cmd.send_object(['ZREVRANK', 'leaderboard', 'player1']);

// ZINCRBY
await cmd.send_object(['ZINCRBY', 'leaderboard', '10', 'player1']);
```

## Caching Strategien

| Strategie | Beschreibung | Use Case |
|-----------|--------------|----------|
| Cache-Aside | Bei Miss aus DB laden | Lesen-intensiv |
| Write-Through | Bei Write sofort cachen | Konsistenz wichtig |
| Write-Behind | Async in DB schreiben | Hohe Schreiblast |
| Read-Through | Cache lädt selbst | Transparentes Caching |

## Best Practices

1. **Kurze TTLs** - Lieber oft refreshen als stale data
2. **Konsistente Keys** - `type:id:field` Konvention
3. **JSON für komplexe Objekte** - Einfach zu serialisieren
4. **Pipelines für Bulk-Ops** - Mehrere Commands in einem Roundtrip
5. **Memory-Limits setzen** - Redis wächst unbegrenzt
6. **Invalidierung bei Writes** - Write-Through oder explizit
