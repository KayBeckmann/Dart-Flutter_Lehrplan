# Lösung 7.6: MongoDB mit Dart

## Database Connection

```dart
// lib/database.dart
import 'package:mongo_dart/mongo_dart.dart';

class Database {
  static Db? _db;

  static Future<Db> connect() async {
    _db ??= Db('mongodb://root:secret@localhost:27017/shop');
    if (!_db!.isConnected) {
      await _db!.open();
    }
    return _db!;
  }

  static DbCollection get products {
    if (_db == null || !_db!.isConnected) {
      throw StateError('Database not connected');
    }
    return _db!.collection('products');
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
```

---

## CRUD Operations

```dart
// lib/product_operations.dart
import 'package:mongo_dart/mongo_dart.dart';
import 'database.dart';

// CREATE
Future<String> createProduct(Map<String, dynamic> data) async {
  data['createdAt'] = DateTime.now();
  data['tags'] ??= <String>[];

  final result = await Database.products.insertOne(data);
  return result.id.toHexString();
}

// READ - All
Future<List<Map<String, dynamic>>> getAllProducts() async {
  return await Database.products.find().toList();
}

// READ - By ID
Future<Map<String, dynamic>?> getProductById(String id) async {
  try {
    return await Database.products.findOne(
      where.id(ObjectId.parse(id)),
    );
  } catch (_) {
    return null;
  }
}

// READ - By Category
Future<List<Map<String, dynamic>>> getProductsByCategory(String category) async {
  return await Database.products
      .find(where.eq('category', category))
      .toList();
}

// READ - Search
Future<List<Map<String, dynamic>>> searchProducts(String query) async {
  return await Database.products
      .find(where.match('name', '.*$query.*', caseInsensitive: true))
      .toList();
}

// READ - By Price Range
Future<List<Map<String, dynamic>>> getProductsByPriceRange(
  double min,
  double max,
) async {
  return await Database.products
      .find(where.gte('price', min).lte('price', max))
      .toList();
}

// UPDATE
Future<bool> updateProduct(String id, Map<String, dynamic> data) async {
  try {
    var modifier = ModifierBuilder();

    if (data['name'] != null) modifier = modifier.set('name', data['name']);
    if (data['price'] != null) modifier = modifier.set('price', data['price']);
    if (data['stock'] != null) modifier = modifier.set('stock', data['stock']);
    if (data['description'] != null) {
      modifier = modifier.set('description', data['description']);
    }

    modifier = modifier.set('updatedAt', DateTime.now());

    final result = await Database.products.updateOne(
      where.id(ObjectId.parse(id)),
      modifier,
    );

    return result.nModified > 0;
  } catch (_) {
    return false;
  }
}

// UPDATE - Adjust Stock
Future<bool> adjustStock(String id, int delta) async {
  try {
    final result = await Database.products.updateOne(
      where.id(ObjectId.parse(id)),
      modify.inc('stock', delta).set('updatedAt', DateTime.now()),
    );
    return result.nModified > 0;
  } catch (_) {
    return false;
  }
}

// DELETE
Future<bool> deleteProduct(String id) async {
  try {
    final result = await Database.products.deleteOne(
      where.id(ObjectId.parse(id)),
    );
    return result.nRemoved > 0;
  } catch (_) {
    return false;
  }
}
```

---

## Pagination & Sorting

```dart
Future<List<Map<String, dynamic>>> getProductsPaginated({
  int page = 1,
  int perPage = 10,
  String sortBy = 'createdAt',
  bool descending = true,
  String? category,
}) async {
  var query = where.sortBy(sortBy, descending: descending);

  if (category != null) {
    query = query.eq('category', category);
  }

  query = query.skip((page - 1) * perPage).limit(perPage);

  return await Database.products.find(query).toList();
}

Future<int> countProducts({String? category}) async {
  if (category != null) {
    return await Database.products.count(where.eq('category', category));
  }
  return await Database.products.count();
}
```

---

## Product Model & Repository

```dart
// lib/models/product.dart
import 'package:mongo_dart/mongo_dart.dart';

class Product {
  final String? id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String category;
  final List<String> tags;
  final Map<String, dynamic>? specs;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    required this.category,
    this.tags = const [],
    this.specs,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['_id']?.toHexString(),
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int? ?? 0,
      category: map['category'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      specs: map['specs'] as Map<String, dynamic>?,
      createdAt: map['createdAt'] as DateTime?,
      updatedAt: map['updatedAt'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) '_id': ObjectId.parse(id!),
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'category': category,
      'tags': tags,
      if (specs != null) 'specs': specs,
      'createdAt': createdAt ?? DateTime.now(),
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  @override
  String toString() => 'Product($id: $name, €$price)';
}
```

```dart
// lib/repositories/product_repository.dart
import 'package:mongo_dart/mongo_dart.dart';
import '../models/product.dart';

class ProductRepository {
  final DbCollection _collection;

  ProductRepository(Db db) : _collection = db.collection('products');

  Future<List<Product>> findAll() async {
    final docs = await _collection.find().toList();
    return docs.map(Product.fromMap).toList();
  }

  Future<Product?> findById(String id) async {
    try {
      final doc = await _collection.findOne(where.id(ObjectId.parse(id)));
      return doc != null ? Product.fromMap(doc) : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Product>> findByCategory(String category) async {
    final docs = await _collection
        .find(where.eq('category', category))
        .toList();
    return docs.map(Product.fromMap).toList();
  }

  Future<List<Product>> search(String query) async {
    final docs = await _collection
        .find(where.match('name', '.*$query.*', caseInsensitive: true))
        .toList();
    return docs.map(Product.fromMap).toList();
  }

  Future<Product> create(Product product) async {
    final map = product.toMap();
    map['createdAt'] = DateTime.now();
    map.remove('_id');

    final result = await _collection.insertOne(map);
    map['_id'] = result.id;

    return Product.fromMap(map);
  }

  Future<Product?> update(String id, Product product) async {
    try {
      final result = await _collection.findAndModify(
        query: where.id(ObjectId.parse(id)),
        update: modify
            .set('name', product.name)
            .set('description', product.description)
            .set('price', product.price)
            .set('stock', product.stock)
            .set('category', product.category)
            .set('tags', product.tags)
            .set('updatedAt', DateTime.now()),
        returnNew: true,
      );

      return result != null ? Product.fromMap(result) : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> delete(String id) async {
    try {
      final result = await _collection.deleteOne(
        where.id(ObjectId.parse(id)),
      );
      return result.nRemoved > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addTag(String id, String tag) async {
    try {
      final result = await _collection.updateOne(
        where.id(ObjectId.parse(id)),
        modify.addToSet('tags', tag),
      );
      return result.nModified > 0;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeTag(String id, String tag) async {
    try {
      final result = await _collection.updateOne(
        where.id(ObjectId.parse(id)),
        modify.pull('tags', tag),
      );
      return result.nModified > 0;
    } catch (_) {
      return false;
    }
  }
}
```

---

## Indexes

```dart
Future<void> createIndexes(DbCollection products) async {
  // Name Index (für Suche)
  await products.createIndex(keys: {'name': 1});

  // Category + Price (für gefilterte Sortierung)
  await products.createIndex(keys: {'category': 1, 'price': -1});

  // Tags (Multikey Index)
  await products.createIndex(keys: {'tags': 1});

  // Created At (für Sortierung)
  await products.createIndex(keys: {'createdAt': -1});

  print('Indexes created');
}
```

---

## Main

```dart
Future<void> main() async {
  final db = await Database.connect();

  try {
    final repo = ProductRepository(db);

    // Create
    final product = await repo.create(Product(
      name: 'Test Laptop',
      price: 999.99,
      stock: 25,
      category: 'electronics',
      tags: ['new'],
    ));
    print('Created: $product');

    // Read
    final found = await repo.findById(product.id!);
    print('Found: $found');

    // Update
    final updated = await repo.update(
      product.id!,
      Product(
        name: 'Updated Laptop',
        price: 899.99,
        stock: 30,
        category: 'electronics',
        tags: ['sale'],
      ),
    );
    print('Updated: $updated');

    // Search
    final results = await repo.search('Laptop');
    print('Search results: ${results.length}');

    // Delete
    final deleted = await repo.delete(product.id!);
    print('Deleted: $deleted');

  } finally {
    await Database.close();
  }
}
```
