# Ressourcen: MongoDB mit Dart

## Offizielle Dokumentation

- [mongo_dart (pub.dev)](https://pub.dev/packages/mongo_dart)
- [MongoDB Documentation](https://www.mongodb.com/docs/)
- [MongoDB Query Operators](https://www.mongodb.com/docs/manual/reference/operator/query/)

## Cheat Sheet: Verbindung

```dart
import 'package:mongo_dart/mongo_dart.dart';

// Verbinden
final db = Db('mongodb://user:password@localhost:27017/dbname');
await db.open();

// Collection
final collection = db.collection('products');

// Schließen
await db.close();
```

## Cheat Sheet: Insert

```dart
// Einzeln
await collection.insertOne({'name': 'Product', 'price': 99.99});

// Mehrere
await collection.insertMany([
  {'name': 'A', 'price': 10},
  {'name': 'B', 'price': 20},
]);

// Mit ID-Rückgabe
final result = await collection.insertOne({...});
final id = result.id.toHexString();
```

## Cheat Sheet: Find

```dart
// Alle
final all = await collection.find().toList();

// Mit Filter
final filtered = await collection.find(where.eq('category', 'electronics')).toList();

// Einzeln
final one = await collection.findOne(where.eq('name', 'Product'));

// Nach ID
final byId = await collection.findOne(where.id(ObjectId.parse(id)));

// Vergleiche
where.gt('price', 100)    // >
where.gte('price', 100)   // >=
where.lt('price', 100)    // <
where.lte('price', 100)   // <=
where.ne('status', 'deleted')  // !=

// Kombinationen
where.eq('category', 'electronics').gt('price', 100)  // AND
where.oneFrom('category', ['a', 'b'])  // IN

// Sortierung
where.sortBy('price', descending: true)

// Pagination
where.skip(10).limit(10)

// Regex
where.match('name', '.*laptop.*', caseInsensitive: true)
```

## Cheat Sheet: Update

```dart
// Einzeln
await collection.updateOne(
  where.eq('name', 'Product'),
  modify.set('price', 89.99),
);

// Mehrere Felder
modify.set('price', 89.99).set('stock', 100)

// Increment
modify.inc('stock', 10)   // +10
modify.inc('stock', -5)   // -5

// Array Operations
modify.push('tags', 'new')       // Add to array
modify.pull('tags', 'old')       // Remove from array
modify.addToSet('tags', 'sale')  // Add if not exists

// Mehrere Dokumente
await collection.updateMany(
  where.eq('category', 'electronics'),
  modify.mul('price', 0.9),  // -10%
);
```

## Cheat Sheet: Delete

```dart
// Einzeln
await collection.deleteOne(where.eq('name', 'Product'));

// Mehrere
await collection.deleteMany(where.eq('stock', 0));

// Alle
await collection.deleteMany({});
```

## Cheat Sheet: Aggregation

```dart
final pipeline = AggregationPipelineBuilder()
    .addStage(Match(where.eq('category', 'electronics')))
    .addStage(Group(
      id: r'$category',
      fields: {
        'avgPrice': {r'$avg': r'$price'},
        'count': {r'$sum': 1},
      },
    ))
    .build();

final result = await collection.aggregateToStream(pipeline).toList();
```

## Cheat Sheet: Indexes

```dart
// Einfach
await collection.createIndex(keys: {'name': 1});

// Unique
await collection.createIndex(keys: {'email': 1}, unique: true);

// Compound
await collection.createIndex(keys: {'category': 1, 'price': -1});

// 1 = ascending, -1 = descending
```

## SQL vs MongoDB

| SQL | MongoDB |
|-----|---------|
| `SELECT * FROM t` | `find()` |
| `WHERE a = 1` | `where.eq('a', 1)` |
| `WHERE a > 1` | `where.gt('a', 1)` |
| `ORDER BY a` | `where.sortBy('a')` |
| `LIMIT 10` | `where.limit(10)` |
| `INSERT INTO` | `insertOne/Many` |
| `UPDATE` | `updateOne/Many` |
| `DELETE` | `deleteOne/Many` |
