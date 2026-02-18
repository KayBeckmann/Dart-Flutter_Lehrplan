# Lösung 7.3: Repository Pattern

## Projektstruktur

```
lib/
├── models/
│   ├── product.dart
│   ├── category.dart
│   └── customer.dart
├── dtos/
│   ├── product_create.dart
│   └── product_update.dart
├── repositories/
│   ├── product_repository.dart
│   ├── category_repository.dart
│   ├── postgres/
│   │   ├── postgres_product_repository.dart
│   │   └── postgres_category_repository.dart
│   └── mock/
│       ├── mock_product_repository.dart
│       └── mock_category_repository.dart
├── services/
│   └── product_service.dart
├── exceptions.dart
└── container.dart
```

---

## Models

### lib/models/product.dart

```dart
import 'package:postgres/postgres.dart';

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Product.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      price: (map['price'] as num).toDouble(),
      stock: map['stock'] as int,
      categoryId: map['category_id'] as int?,
      createdAt: map['created_at'] as DateTime,
      updatedAt: map['updated_at'] as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'categoryId': categoryId,
    'inStock': stock > 0,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    int? stock,
    int? categoryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Product($id: $name, €$price, stock: $stock)';
}
```

### lib/models/category.dart

```dart
import 'package:postgres/postgres.dart';

class Category {
  final int id;
  final String name;
  final String? description;

  Category({
    required this.id,
    required this.name,
    this.description,
  });

  factory Category.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}
```

---

## DTOs

### lib/dtos/product_create.dart

```dart
class ProductCreate {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;

  ProductCreate({
    required this.name,
    this.description,
    required this.price,
    this.stock = 0,
    this.categoryId,
  });

  factory ProductCreate.fromJson(Map<String, dynamic> json) {
    return ProductCreate(
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      categoryId: json['categoryId'] as int?,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (name.trim().length < 2) {
      errors.add('Name must be at least 2 characters');
    }
    if (name.length > 100) {
      errors.add('Name must be at most 100 characters');
    }
    if (price <= 0) {
      errors.add('Price must be positive');
    }
    if (stock < 0) {
      errors.add('Stock cannot be negative');
    }

    return errors;
  }
}
```

### lib/dtos/product_update.dart

```dart
class ProductUpdate {
  final String? name;
  final String? description;
  final double? price;
  final int? stock;
  final int? categoryId;

  ProductUpdate({
    this.name,
    this.description,
    this.price,
    this.stock,
    this.categoryId,
  });

  factory ProductUpdate.fromJson(Map<String, dynamic> json) {
    return ProductUpdate(
      name: json['name'] as String?,
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      stock: json['stock'] as int?,
      categoryId: json['categoryId'] as int?,
    );
  }

  bool get isEmpty =>
      name == null &&
      description == null &&
      price == null &&
      stock == null &&
      categoryId == null;

  List<String> validate() {
    final errors = <String>[];

    if (name != null && name!.trim().length < 2) {
      errors.add('Name must be at least 2 characters');
    }
    if (price != null && price! <= 0) {
      errors.add('Price must be positive');
    }
    if (stock != null && stock! < 0) {
      errors.add('Stock cannot be negative');
    }

    return errors;
  }
}
```

---

## Repository Interfaces

### lib/repositories/product_repository.dart

```dart
import '../models/product.dart';
import '../dtos/product_create.dart';
import '../dtos/product_update.dart';

abstract class ProductRepository {
  Future<List<Product>> findAll();
  Future<Product?> findById(int id);
  Future<List<Product>> findByCategory(int categoryId);
  Future<List<Product>> findByPriceRange(double min, double max);
  Future<List<Product>> search(String query);
  Future<List<Product>> findLowStock(int threshold);

  Future<Product> create(ProductCreate data);
  Future<Product?> update(int id, ProductUpdate data);
  Future<bool> delete(int id);
  Future<bool> updateStock(int id, int delta);
}
```

### lib/repositories/category_repository.dart

```dart
import '../models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> findAll();
  Future<Category?> findById(int id);
  Future<Category?> findByName(String name);
  Future<Category> create(String name, String? description);
  Future<Category?> update(int id, String? name, String? description);
  Future<bool> delete(int id);
}
```

---

## PostgreSQL Implementations

### lib/repositories/postgres/postgres_product_repository.dart

```dart
import 'package:postgres/postgres.dart';
import '../../models/product.dart';
import '../../dtos/product_create.dart';
import '../../dtos/product_update.dart';
import '../product_repository.dart';

class PostgresProductRepository implements ProductRepository {
  final Pool _pool;

  PostgresProductRepository(this._pool);

  @override
  Future<List<Product>> findAll() async {
    final result = await _pool.execute(
      'SELECT * FROM products ORDER BY created_at DESC',
    );
    return result.map(Product.fromRow).toList();
  }

  @override
  Future<Product?> findById(int id) async {
    final result = await _pool.execute(
      Sql.named('SELECT * FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Product.fromRow(result.first);
  }

  @override
  Future<List<Product>> findByCategory(int categoryId) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT * FROM products
        WHERE category_id = @categoryId
        ORDER BY name
      '''),
      parameters: {'categoryId': categoryId},
    );
    return result.map(Product.fromRow).toList();
  }

  @override
  Future<List<Product>> findByPriceRange(double min, double max) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT * FROM products
        WHERE price >= @min AND price <= @max
        ORDER BY price
      '''),
      parameters: {'min': min, 'max': max},
    );
    return result.map(Product.fromRow).toList();
  }

  @override
  Future<List<Product>> search(String query) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT * FROM products
        WHERE name ILIKE @query OR description ILIKE @query
        ORDER BY name
      '''),
      parameters: {'query': '%$query%'},
    );
    return result.map(Product.fromRow).toList();
  }

  @override
  Future<List<Product>> findLowStock(int threshold) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT * FROM products
        WHERE stock < @threshold
        ORDER BY stock ASC
      '''),
      parameters: {'threshold': threshold},
    );
    return result.map(Product.fromRow).toList();
  }

  @override
  Future<Product> create(ProductCreate data) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO products (name, description, price, stock, category_id)
        VALUES (@name, @description, @price, @stock, @categoryId)
        RETURNING *
      '''),
      parameters: {
        'name': data.name,
        'description': data.description,
        'price': data.price,
        'stock': data.stock,
        'categoryId': data.categoryId,
      },
    );
    return Product.fromRow(result.first);
  }

  @override
  Future<Product?> update(int id, ProductUpdate data) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE products SET
          name = COALESCE(@name, name),
          description = COALESCE(@description, description),
          price = COALESCE(@price, price),
          stock = COALESCE(@stock, stock),
          category_id = COALESCE(@categoryId, category_id),
          updated_at = NOW()
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'name': data.name,
        'description': data.description,
        'price': data.price,
        'stock': data.stock,
        'categoryId': data.categoryId,
      },
    );
    if (result.isEmpty) return null;
    return Product.fromRow(result.first);
  }

  @override
  Future<bool> delete(int id) async {
    final result = await _pool.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  @override
  Future<bool> updateStock(int id, int delta) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE products
        SET stock = stock + @delta, updated_at = NOW()
        WHERE id = @id AND stock + @delta >= 0
      '''),
      parameters: {'id': id, 'delta': delta},
    );
    return result.affectedRows > 0;
  }
}
```

---

## Mock Implementations

### lib/repositories/mock/mock_product_repository.dart

```dart
import '../../models/product.dart';
import '../../dtos/product_create.dart';
import '../../dtos/product_update.dart';
import '../product_repository.dart';

class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];
  int _nextId = 1;

  @override
  Future<List<Product>> findAll() async {
    return List.from(_products)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Product?> findById(int id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Product>> findByCategory(int categoryId) async {
    return _products
        .where((p) => p.categoryId == categoryId)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Product>> findByPriceRange(double min, double max) async {
    return _products
        .where((p) => p.price >= min && p.price <= max)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  @override
  Future<List<Product>> search(String query) async {
    final q = query.toLowerCase();
    return _products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            (p.description?.toLowerCase().contains(q) ?? false))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<List<Product>> findLowStock(int threshold) async {
    return _products.where((p) => p.stock < threshold).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
  }

  @override
  Future<Product> create(ProductCreate data) async {
    final product = Product(
      id: _nextId++,
      name: data.name,
      description: data.description,
      price: data.price,
      stock: data.stock,
      categoryId: data.categoryId,
      createdAt: DateTime.now(),
    );
    _products.add(product);
    return product;
  }

  @override
  Future<Product?> update(int id, ProductUpdate data) async {
    final index = _products.indexWhere((p) => p.id == id);
    if (index == -1) return null;

    final existing = _products[index];
    final updated = existing.copyWith(
      name: data.name ?? existing.name,
      description: data.description ?? existing.description,
      price: data.price ?? existing.price,
      stock: data.stock ?? existing.stock,
      categoryId: data.categoryId ?? existing.categoryId,
      updatedAt: DateTime.now(),
    );

    _products[index] = updated;
    return updated;
  }

  @override
  Future<bool> delete(int id) async {
    final lengthBefore = _products.length;
    _products.removeWhere((p) => p.id == id);
    return _products.length < lengthBefore;
  }

  @override
  Future<bool> updateStock(int id, int delta) async {
    final product = await findById(id);
    if (product == null) return false;

    final newStock = product.stock + delta;
    if (newStock < 0) return false;

    await update(id, ProductUpdate(stock: newStock));
    return true;
  }

  // Test helpers
  void clear() {
    _products.clear();
    _nextId = 1;
  }

  void seed(List<Product> products) {
    _products.addAll(products);
    if (products.isNotEmpty) {
      _nextId = products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    }
  }

  int get count => _products.length;
}
```

---

## Exceptions

### lib/exceptions.dart

```dart
class ValidationException implements Exception {
  final String message;
  final List<String> errors;

  ValidationException(this.message, [this.errors = const []]);

  @override
  String toString() => 'ValidationException: $message';
}

class NotFoundException implements Exception {
  final String message;

  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}

class InsufficientStockException implements Exception {
  final String message;

  InsufficientStockException(this.message);

  @override
  String toString() => 'InsufficientStockException: $message';
}
```

---

## Service Layer

### lib/services/product_service.dart

```dart
import '../models/product.dart';
import '../dtos/product_create.dart';
import '../dtos/product_update.dart';
import '../repositories/product_repository.dart';
import '../repositories/category_repository.dart';
import '../exceptions.dart';

class ProductService {
  final ProductRepository _productRepository;
  final CategoryRepository _categoryRepository;

  ProductService(this._productRepository, this._categoryRepository);

  Future<List<Product>> getAllProducts() {
    return _productRepository.findAll();
  }

  Future<Product?> getProduct(int id) {
    return _productRepository.findById(id);
  }

  Future<Product> createProduct(ProductCreate data) async {
    // Validate
    final errors = data.validate();
    if (errors.isNotEmpty) {
      throw ValidationException('Invalid product data', errors);
    }

    // Check category exists if specified
    if (data.categoryId != null) {
      final category = await _categoryRepository.findById(data.categoryId!);
      if (category == null) {
        throw ValidationException('Category not found: ${data.categoryId}');
      }
    }

    return _productRepository.create(data);
  }

  Future<Product?> updateProduct(int id, ProductUpdate data) async {
    if (data.isEmpty) {
      throw ValidationException('No data to update');
    }

    // Check product exists
    final existing = await _productRepository.findById(id);
    if (existing == null) {
      throw NotFoundException('Product not found: $id');
    }

    // Validate update data
    final errors = data.validate();
    if (errors.isNotEmpty) {
      throw ValidationException('Invalid update data', errors);
    }

    // Check category if changing
    if (data.categoryId != null) {
      final category = await _categoryRepository.findById(data.categoryId!);
      if (category == null) {
        throw ValidationException('Category not found: ${data.categoryId}');
      }
    }

    return _productRepository.update(id, data);
  }

  Future<bool> deleteProduct(int id) async {
    final existing = await _productRepository.findById(id);
    if (existing == null) {
      throw NotFoundException('Product not found: $id');
    }

    return _productRepository.delete(id);
  }

  Future<bool> adjustStock(int id, int delta) async {
    final product = await _productRepository.findById(id);
    if (product == null) {
      throw NotFoundException('Product not found: $id');
    }

    final newStock = product.stock + delta;
    if (newStock < 0) {
      throw InsufficientStockException(
        'Insufficient stock: have ${product.stock}, need ${-delta}',
      );
    }

    return _productRepository.updateStock(id, delta);
  }

  Future<List<Product>> searchProducts(String query) {
    if (query.trim().length < 2) {
      throw ValidationException('Search query must be at least 2 characters');
    }
    return _productRepository.search(query.trim());
  }

  Future<List<Product>> getLowStockProducts({int threshold = 10}) {
    return _productRepository.findLowStock(threshold);
  }
}
```

---

## Unit Tests

### test/product_service_test.dart

```dart
import 'package:test/test.dart';
import 'package:shop/models/product.dart';
import 'package:shop/dtos/product_create.dart';
import 'package:shop/dtos/product_update.dart';
import 'package:shop/repositories/mock/mock_product_repository.dart';
import 'package:shop/repositories/mock/mock_category_repository.dart';
import 'package:shop/services/product_service.dart';
import 'package:shop/exceptions.dart';

void main() {
  late MockProductRepository productRepo;
  late MockCategoryRepository categoryRepo;
  late ProductService service;

  setUp(() {
    productRepo = MockProductRepository();
    categoryRepo = MockCategoryRepository();
    service = ProductService(productRepo, categoryRepo);
  });

  group('createProduct', () {
    test('valid data creates product', () async {
      final data = ProductCreate(
        name: 'Test Product',
        price: 99.99,
        stock: 10,
      );

      final product = await service.createProduct(data);

      expect(product.name, equals('Test Product'));
      expect(product.price, equals(99.99));
      expect(product.stock, equals(10));
      expect(product.id, isPositive);
    });

    test('short name throws ValidationException', () async {
      final data = ProductCreate(name: 'A', price: 10);

      expect(
        () => service.createProduct(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('negative price throws ValidationException', () async {
      final data = ProductCreate(name: 'Test', price: -10);

      expect(
        () => service.createProduct(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('invalid categoryId throws ValidationException', () async {
      final data = ProductCreate(
        name: 'Test',
        price: 10,
        categoryId: 999,
      );

      expect(
        () => service.createProduct(data),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('updateProduct', () {
    test('valid update succeeds', () async {
      // Arrange
      await productRepo.create(ProductCreate(name: 'Test', price: 10));

      // Act
      final updated = await service.updateProduct(
        1,
        ProductUpdate(price: 20),
      );

      // Assert
      expect(updated?.price, equals(20));
    });

    test('empty update throws ValidationException', () async {
      await productRepo.create(ProductCreate(name: 'Test', price: 10));

      expect(
        () => service.updateProduct(1, ProductUpdate()),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non-existent product throws NotFoundException', () async {
      expect(
        () => service.updateProduct(999, ProductUpdate(price: 20)),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('adjustStock', () {
    test('positive delta increases stock', () async {
      await productRepo.create(ProductCreate(name: 'Test', price: 10, stock: 50));

      final success = await service.adjustStock(1, 10);

      expect(success, isTrue);
      final product = await productRepo.findById(1);
      expect(product?.stock, equals(60));
    });

    test('negative delta decreases stock', () async {
      await productRepo.create(ProductCreate(name: 'Test', price: 10, stock: 50));

      final success = await service.adjustStock(1, -10);

      expect(success, isTrue);
      final product = await productRepo.findById(1);
      expect(product?.stock, equals(40));
    });

    test('delta causing negative stock throws', () async {
      await productRepo.create(ProductCreate(name: 'Test', price: 10, stock: 5));

      expect(
        () => service.adjustStock(1, -10),
        throwsA(isA<InsufficientStockException>()),
      );
    });

    test('non-existent product throws NotFoundException', () async {
      expect(
        () => service.adjustStock(999, 10),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('searchProducts', () {
    test('short query throws ValidationException', () async {
      expect(
        () => service.searchProducts('a'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('valid query returns matching products', () async {
      await productRepo.create(ProductCreate(name: 'Laptop Pro', price: 1000));
      await productRepo.create(ProductCreate(name: 'Mouse', price: 50));

      final results = await service.searchProducts('Laptop');

      expect(results, hasLength(1));
      expect(results.first.name, equals('Laptop Pro'));
    });
  });

  group('deleteProduct', () {
    test('existing product is deleted', () async {
      await productRepo.create(ProductCreate(name: 'Test', price: 10));

      final success = await service.deleteProduct(1);

      expect(success, isTrue);
      expect(productRepo.count, equals(0));
    });

    test('non-existent product throws NotFoundException', () async {
      expect(
        () => service.deleteProduct(999),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
```

---

## Container

### lib/container.dart

```dart
import 'package:postgres/postgres.dart';
import 'repositories/product_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/postgres/postgres_product_repository.dart';
import 'repositories/postgres/postgres_category_repository.dart';
import 'services/product_service.dart';

class Container {
  static Pool? _pool;
  static ProductRepository? _productRepository;
  static CategoryRepository? _categoryRepository;
  static ProductService? _productService;

  static Future<void> init({
    required String host,
    required String database,
    required String username,
    required String password,
    int port = 5432,
  }) async {
    _pool = Pool.withEndpoints(
      [
        Endpoint(
          host: host,
          port: port,
          database: database,
          username: username,
          password: password,
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
      ),
    );

    _productRepository = PostgresProductRepository(_pool!);
    _categoryRepository = PostgresCategoryRepository(_pool!);
    _productService = ProductService(_productRepository!, _categoryRepository!);
  }

  static ProductRepository get productRepository {
    if (_productRepository == null) {
      throw StateError('Container not initialized');
    }
    return _productRepository!;
  }

  static CategoryRepository get categoryRepository {
    if (_categoryRepository == null) {
      throw StateError('Container not initialized');
    }
    return _categoryRepository!;
  }

  static ProductService get productService {
    if (_productService == null) {
      throw StateError('Container not initialized');
    }
    return _productService!;
  }

  static Future<void> dispose() async {
    await _pool?.close();
    _pool = null;
    _productRepository = null;
    _categoryRepository = null;
    _productService = null;
  }
}
```

---

## Verwendung

```dart
import 'package:shop/container.dart';
import 'package:shop/dtos/product_create.dart';

Future<void> main() async {
  await Container.init(
    host: 'localhost',
    database: 'shop_db',
    username: 'postgres',
    password: 'secret',
  );

  try {
    final service = Container.productService;

    // Produkt erstellen
    final product = await service.createProduct(ProductCreate(
      name: 'New Laptop',
      price: 1299.99,
      stock: 25,
    ));
    print('Created: $product');

    // Alle Produkte
    final products = await service.getAllProducts();
    print('Total products: ${products.length}');

    // Suchen
    final results = await service.searchProducts('Laptop');
    print('Search results: ${results.length}');

  } finally {
    await Container.dispose();
  }
}
```
