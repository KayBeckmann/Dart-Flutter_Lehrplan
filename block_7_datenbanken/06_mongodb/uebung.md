# Übung 7.6: MongoDB mit Dart

## Ziel

Implementiere eine Produkt-API mit MongoDB als Backend.

---

## Vorbereitung

### MongoDB starten

```bash
docker run --name mongodb \
  -e MONGO_INITDB_ROOT_USERNAME=root \
  -e MONGO_INITDB_ROOT_PASSWORD=secret \
  -p 27017:27017 \
  -d mongo:7
```

### Projekt Setup

```yaml
# pubspec.yaml
dependencies:
  mongo_dart: ^0.10.0
```

---

## Aufgabe 1: Verbindung & Collection (10 min)

```dart
// lib/database.dart
import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static Db? _db;

  static Future<Db> connect() async {
    // TODO: Verbindung herstellen
    // URL: mongodb://root:secret@localhost:27017/shop
  }

  static DbCollection get products {
    // TODO: products Collection zurückgeben
  }

  static Future<void> close() async {
    // TODO: Verbindung schließen
  }
}
```

---

## Aufgabe 2: CRUD Operationen (25 min)

### Create

```dart
Future<String> createProduct(Map<String, dynamic> data) async {
  // TODO: createdAt hinzufügen
  // TODO: insertOne
  // TODO: ID als String zurückgeben
}
```

### Read

```dart
Future<List<Map<String, dynamic>>> getAllProducts() async {
  // TODO: find().toList()
}

Future<Map<String, dynamic>?> getProductById(String id) async {
  // TODO: findOne mit ObjectId
}

Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
  // TODO: find mit where.eq
}

Future<List<Map<String, dynamic>>> searchProducts(String query) async {
  // TODO: Suche in name und description
  // Hint: where.match('name', '.*$query.*', caseInsensitive: true)
}
```

### Update

```dart
Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
  // TODO: updateOne
  // TODO: updatedAt setzen
}

Future<bool> adjustStock(String id, int delta) async {
  // TODO: modify.inc('stock', delta)
}
```

### Delete

```dart
Future<bool> deleteProduct(String id) async {
  // TODO: deleteOne
}
```

---

## Aufgabe 3: Eingebettete Dokumente (15 min)

### Produkt mit Specs

```dart
await products.insertOne({
  'name': 'MacBook Pro',
  'price': 2499.99,
  'category': 'electronics',
  'specs': {
    'display': '16 inch',
    'cpu': 'M3 Pro',
    'ram': '18GB',
    'storage': '512GB SSD',
  },
  'variants': [
    {'color': 'Space Black', 'sku': 'MBP-16-BLK'},
    {'color': 'Silver', 'sku': 'MBP-16-SLV'},
  ],
  'reviews': [],
});
```

### Abfragen

```dart
// Produkte mit mindestens 16GB RAM
Future<List<Map<String, dynamic>>> findByMinRam(int minGb) async {
  // TODO: where.gte('specs.ram', '${minGb}GB')
}

// Review hinzufügen
Future<void> addReview(String productId, Map<String, dynamic> review) async {
  // TODO: modify.push('reviews', review)
}
```

---

## Aufgabe 4: Pagination & Sortierung (10 min)

```dart
Future<List<Map<String, dynamic>>> getProductsPaginated({
  int page = 1,
  int perPage = 10,
  String sortBy = 'createdAt',
  bool descending = true,
}) async {
  // TODO: skip, limit, sortBy
}

Future<int> countProducts({String? category}) async {
  // TODO: count() mit optionalem Filter
}
```

---

## Aufgabe 5: Repository Pattern (20 min)

```dart
// lib/repositories/product_repository.dart

class Product {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String category;
  final List<String> tags;
  final DateTime? createdAt;

  // TODO: Konstruktor
  // TODO: factory fromMap
  // TODO: Map<String, dynamic> toMap()
}

class ProductRepository {
  final DbCollection _collection;

  ProductRepository(Db db) : _collection = db.collection('products');

  Future<List<Product>> findAll() async {
    // TODO
  }

  Future<Product?> findById(String id) async {
    // TODO
  }

  Future<Product> create(Product product) async {
    // TODO
  }

  Future<Product?> update(String id, Product product) async {
    // TODO
  }

  Future<bool> delete(String id) async {
    // TODO
  }
}
```

---

## Aufgabe 6: Indizes erstellen (5 min)

```dart
Future<void> createIndexes(DbCollection products) async {
  // Index auf name (für Suche)
  await products.createIndex(keys: {'name': 1});

  // Compound Index für Kategorie + Preis
  await products.createIndex(keys: {'category': 1, 'price': -1});

  // Index auf Tags (Array)
  await products.createIndex(keys: {'tags': 1});
}
```

---

## Testen

```dart
Future<void> main() async {
  final db = await Database.connect();

  try {
    // Produkt erstellen
    final id = await createProduct({
      'name': 'Test Product',
      'price': 99.99,
      'stock': 50,
      'category': 'test',
      'tags': ['new'],
    });
    print('Created: $id');

    // Alle Produkte
    final all = await getAllProducts();
    print('Total: ${all.length}');

    // Nach ID
    final product = await getProductById(id);
    print('Found: ${product?['name']}');

    // Suchen
    final results = await searchProducts('Test');
    print('Search results: ${results.length}');

    // Stock erhöhen
    await adjustStock(id, 10);

    // Löschen
    await deleteProduct(id);

  } finally {
    await Database.close();
  }
}
```

---

## Abgabe-Checkliste

- [ ] Datenbankverbindung funktioniert
- [ ] createProduct mit ID-Rückgabe
- [ ] getAllProducts
- [ ] getProductById
- [ ] getProductsByCategory
- [ ] searchProducts
- [ ] updateProduct
- [ ] adjustStock mit inc
- [ ] deleteProduct
- [ ] Eingebettete Dokumente (specs, variants)
- [ ] Pagination mit skip/limit
- [ ] Product Model mit fromMap/toMap
- [ ] ProductRepository implementiert
- [ ] Indizes erstellt
