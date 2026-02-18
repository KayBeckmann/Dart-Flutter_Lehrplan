# Einheit 7.6: MongoDB mit Dart

## Lernziele

Nach dieser Einheit kannst du:
- Die Grundlagen von MongoDB verstehen
- Dokumente mit Dart erstellen und abfragen
- CRUD-Operationen mit mongo_dart durchführen
- Wann NoSQL vs. SQL sinnvoll ist

---

## Was ist MongoDB?

**MongoDB** ist eine dokumentenorientierte NoSQL-Datenbank.

### SQL vs. NoSQL

| SQL (PostgreSQL) | NoSQL (MongoDB) |
|------------------|-----------------|
| Tabellen | Collections |
| Zeilen | Documents |
| Spalten | Fields |
| Schema-gebunden | Schema-flexibel |
| JOINs | Eingebettete Dokumente |
| ACID | BASE (eventual consistency) |

### Wann MongoDB?

- Flexible, sich ändernde Datenstrukturen
- Hierarchische Daten (verschachtelte Objekte)
- Schnelle Iteration/Prototyping
- Horizontale Skalierung nötig

### Wann SQL?

- Komplexe Beziehungen zwischen Daten
- Transaktionen über mehrere Tabellen
- Strikte Datenintegrität
- Komplexe Aggregationen/JOINs

---

## MongoDB Setup

### Docker

```bash
docker run --name mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -p 27017:27017 \
  -d mongo:7
```

### Dart Package

```yaml
dependencies:
  mongo_dart: ^0.10.0
```

---

## Verbindung herstellen

```dart
import 'package:mongo_dart/mongo_dart.dart';

Future<void> main() async {
  // Verbindung
  final db = Db('mongodb://root:secret@localhost:27017/shop');
  await db.open();

  print('Connected to MongoDB');

  // Collection (ähnlich Tabelle)
  final products = db.collection('products');

  // ... Operationen ...

  await db.close();
}
```

---

## Dokumente einfügen

### Einzelnes Dokument

```dart
final products = db.collection('products');

await products.insertOne({
  'name': 'Laptop Pro',
  'description': 'High-end laptop',
  'price': 1299.99,
  'stock': 25,
  'category': 'electronics',
  'tags': ['new', 'bestseller'],
  'specs': {
    'cpu': 'M3 Pro',
    'ram': '16GB',
    'storage': '512GB SSD',
  },
  'createdAt': DateTime.now(),
});
```

### Mehrere Dokumente

```dart
await products.insertMany([
  {
    'name': 'Wireless Mouse',
    'price': 49.99,
    'stock': 100,
    'category': 'electronics',
  },
  {
    'name': 'USB-C Hub',
    'price': 79.99,
    'stock': 50,
    'category': 'electronics',
  },
]);
```

### Mit automatischer ID

```dart
final result = await products.insertOne({
  'name': 'New Product',
  'price': 99.99,
});

print('Inserted ID: ${result.id}');
```

---

## Dokumente abfragen

### Alle Dokumente

```dart
final allProducts = await products.find().toList();
for (final p in allProducts) {
  print('${p['name']}: €${p['price']}');
}
```

### Mit Filter

```dart
// Exakter Match
final electronics = await products
    .find(where.eq('category', 'electronics'))
    .toList();

// Preisbereich
final affordable = await products
    .find(where.gte('price', 50).lte('price', 200))
    .toList();

// Mehrere Bedingungen (AND)
final inStock = await products
    .find(where.eq('category', 'electronics').gt('stock', 0))
    .toList();

// OR-Verknüpfung
final selected = await products
    .find(where.oneFrom('category', ['electronics', 'books']))
    .toList();
```

### Einzelnes Dokument

```dart
final product = await products.findOne(where.eq('name', 'Laptop Pro'));
if (product != null) {
  print('Found: ${product['name']}');
}

// Nach ID
final byId = await products.findOne(where.id(ObjectId.parse('...')));
```

### Sortierung und Limit

```dart
// Nach Preis sortiert, Top 10
final topProducts = await products
    .find(where.sortBy('price', descending: true).limit(10))
    .toList();

// Mit Skip (Pagination)
final page2 = await products
    .find(where.sortBy('name').skip(10).limit(10))
    .toList();
```

---

## Dokumente aktualisieren

### Einzelnes Dokument

```dart
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify.set('price', 1199.99),
);
```

### Mehrere Felder

```dart
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify
      .set('price', 1199.99)
      .set('stock', 30)
      .set('updatedAt', DateTime.now()),
);
```

### Inkrementieren

```dart
// Stock um 10 erhöhen
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify.inc('stock', 10),
);

// Stock um 5 verringern
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify.inc('stock', -5),
);
```

### Array-Operationen

```dart
// Tag hinzufügen
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify.push('tags', 'sale'),
);

// Tag entfernen
await products.updateOne(
  where.eq('name', 'Laptop Pro'),
  modify.pull('tags', 'sale'),
);
```

### Mehrere Dokumente

```dart
// Alle Produkte in Kategorie um 10% reduzieren
await products.updateMany(
  where.eq('category', 'electronics'),
  modify.mul('price', 0.9),
);
```

---

## Dokumente löschen

```dart
// Einzelnes Dokument
await products.deleteOne(where.eq('name', 'Old Product'));

// Mehrere Dokumente
await products.deleteMany(where.eq('stock', 0));

// Alle Dokumente (Collection leeren)
await products.deleteMany({});
```

---

## Eingebettete Dokumente

MongoDB unterstützt verschachtelte Objekte nativ.

```dart
// Dokument mit eingebettetem Objekt
await orders.insertOne({
  'customer': {
    'name': 'Max Müller',
    'email': 'max@example.com',
    'address': {
      'street': 'Hauptstr. 1',
      'city': 'Berlin',
      'zip': '10115',
    },
  },
  'items': [
    {'productId': 'p1', 'name': 'Laptop', 'quantity': 1, 'price': 1299.99},
    {'productId': 'p2', 'name': 'Mouse', 'quantity': 2, 'price': 49.99},
  ],
  'total': 1399.97,
  'status': 'pending',
  'createdAt': DateTime.now(),
});

// Abfragen auf eingebettete Felder
final berlinOrders = await orders
    .find(where.eq('customer.address.city', 'Berlin'))
    .toList();
```

---

## Indizes

```dart
// Einfacher Index
await products.createIndex(keys: {'name': 1});

// Unique Index
await products.createIndex(
  keys: {'email': 1},
  unique: true,
);

// Compound Index
await products.createIndex(keys: {'category': 1, 'price': -1});

// Text Index für Suche
await products.createIndex(keys: {r'$**': 'text'});
```

---

## Repository Pattern

```dart
class ProductRepository {
  final DbCollection _collection;

  ProductRepository(Db db) : _collection = db.collection('products');

  Future<List<Map<String, dynamic>>> findAll() async {
    return await _collection.find().toList();
  }

  Future<Map<String, dynamic>?> findById(String id) async {
    return await _collection.findOne(where.id(ObjectId.parse(id)));
  }

  Future<String> create(Map<String, dynamic> data) async {
    data['createdAt'] = DateTime.now();
    final result = await _collection.insertOne(data);
    return result.id.toHexString();
  }

  Future<bool> update(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now();
    final result = await _collection.updateOne(
      where.id(ObjectId.parse(id)),
      modify.set('name', data['name']).set('price', data['price']),
    );
    return result.nModified > 0;
  }

  Future<bool> delete(String id) async {
    final result = await _collection.deleteOne(
      where.id(ObjectId.parse(id)),
    );
    return result.nRemoved > 0;
  }
}
```

---

## Zusammenfassung

| SQL | MongoDB |
|-----|---------|
| `INSERT INTO` | `insertOne/Many` |
| `SELECT * FROM` | `find()` |
| `WHERE` | `where.eq()` |
| `UPDATE` | `updateOne/Many` |
| `DELETE` | `deleteOne/Many` |
| `JOIN` | Eingebettete Dokumente |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Queries & Aggregationen**: Komplexe Abfragen und Datenauswertungen in beiden Datenbanksystemen.
