# Übung 7.3: Repository Pattern

## Ziel

Implementiere ein vollständiges Repository-System für einen Online-Shop mit Products, Categories und Customers.

---

## Aufgabe 1: Models erstellen (15 min)

Erstelle die Model-Klassen im Ordner `lib/models/`.

### Product

```dart
// lib/models/product.dart
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // TODO: Konstruktor
  // TODO: factory Product.fromRow(ResultRow row)
  // TODO: Map<String, dynamic> toJson()
  // TODO: copyWith method
}
```

### Category

```dart
// lib/models/category.dart
class Category {
  final int id;
  final String name;
  final String? description;

  // TODO: Implementieren
}
```

### Customer

```dart
// lib/models/customer.dart
class Customer {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;

  // TODO: Implementieren
}
```

---

## Aufgabe 2: DTOs erstellen (10 min)

### ProductCreate

```dart
// lib/dtos/product_create.dart
class ProductCreate {
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;

  // TODO: Konstruktor mit required fields
  // TODO: factory fromJson(Map<String, dynamic> json)
  // TODO: Validierung in einem validate() method
}
```

### ProductUpdate

```dart
// lib/dtos/product_update.dart
class ProductUpdate {
  final String? name;
  final String? description;
  final double? price;
  final int? stock;
  final int? categoryId;

  // TODO: Alle Felder optional
  // TODO: bool get isEmpty
  // TODO: factory fromJson
}
```

---

## Aufgabe 3: Repository Interfaces (10 min)

### Base Repository

```dart
// lib/repositories/base_repository.dart
abstract class BaseRepository<T, ID> {
  Future<List<T>> findAll();
  Future<T?> findById(ID id);
  Future<bool> delete(ID id);
}
```

### Product Repository

```dart
// lib/repositories/product_repository.dart
abstract class ProductRepository extends BaseRepository<Product, int> {
  Future<List<Product>> findByCategory(int categoryId);
  Future<List<Product>> findByPriceRange(double min, double max);
  Future<List<Product>> search(String query);
  Future<List<Product>> findLowStock(int threshold);

  Future<Product> create(ProductCreate data);
  Future<Product?> update(int id, ProductUpdate data);
  Future<bool> updateStock(int id, int delta);
}
```

### Category Repository

```dart
// lib/repositories/category_repository.dart
abstract class CategoryRepository extends BaseRepository<Category, int> {
  Future<Category?> findByName(String name);
  Future<Category> create(String name, String? description);
  Future<Category?> update(int id, String? name, String? description);
}
```

---

## Aufgabe 4: PostgreSQL Implementation (25 min)

### PostgresProductRepository

```dart
// lib/repositories/postgres/postgres_product_repository.dart
class PostgresProductRepository implements ProductRepository {
  final Pool _pool;

  PostgresProductRepository(this._pool);

  @override
  Future<List<Product>> findAll() async {
    // TODO: SELECT * FROM products ORDER BY created_at DESC
  }

  @override
  Future<Product?> findById(int id) async {
    // TODO: SELECT mit WHERE id = @id
  }

  @override
  Future<List<Product>> findByCategory(int categoryId) async {
    // TODO: SELECT mit WHERE category_id = @categoryId
  }

  @override
  Future<List<Product>> findByPriceRange(double min, double max) async {
    // TODO: SELECT mit BETWEEN oder >= AND <=
  }

  @override
  Future<List<Product>> search(String query) async {
    // TODO: ILIKE Suche in name und description
  }

  @override
  Future<List<Product>> findLowStock(int threshold) async {
    // TODO: SELECT WHERE stock < @threshold
  }

  @override
  Future<Product> create(ProductCreate data) async {
    // TODO: INSERT ... RETURNING *
  }

  @override
  Future<Product?> update(int id, ProductUpdate data) async {
    // TODO: UPDATE mit COALESCE für optionale Felder
  }

  @override
  Future<bool> delete(int id) async {
    // TODO: DELETE ... affectedRows > 0
  }

  @override
  Future<bool> updateStock(int id, int delta) async {
    // TODO: UPDATE stock = stock + @delta WHERE stock + @delta >= 0
  }
}
```

---

## Aufgabe 5: Mock Repository (15 min)

```dart
// lib/repositories/mock/mock_product_repository.dart
class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];
  int _nextId = 1;

  // TODO: Alle Methoden implementieren
  // Verwende _products als In-Memory-Speicher

  // Test-Hilfsmethoden
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

## Aufgabe 6: Service Layer (20 min)

```dart
// lib/services/product_service.dart
class ProductService {
  final ProductRepository _repository;
  final CategoryRepository _categoryRepository;

  ProductService(this._repository, this._categoryRepository);

  Future<List<Product>> getAllProducts() {
    return _repository.findAll();
  }

  Future<Product?> getProduct(int id) {
    return _repository.findById(id);
  }

  Future<Product> createProduct(ProductCreate data) async {
    // TODO: Validierung
    // - Name mindestens 2 Zeichen
    // - Price > 0
    // - Stock >= 0
    // - Wenn categoryId angegeben, muss Kategorie existieren

    // TODO: Repository aufrufen
  }

  Future<Product?> updateProduct(int id, ProductUpdate data) async {
    // TODO: Prüfen ob Produkt existiert
    // TODO: Validierung der neuen Werte
    // TODO: Repository aufrufen
  }

  Future<bool> deleteProduct(int id) async {
    // TODO: Prüfen ob Produkt existiert
    // TODO: Repository aufrufen
  }

  Future<bool> adjustStock(int id, int delta) async {
    // TODO: Produkt laden
    // TODO: Prüfen ob neuer Stock >= 0
    // TODO: Repository aufrufen
  }

  Future<List<Product>> searchProducts(String query) {
    if (query.length < 2) {
      throw ValidationException('Search query must be at least 2 characters');
    }
    return _repository.search(query);
  }
}
```

### Exceptions

```dart
// lib/exceptions.dart
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
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

## Aufgabe 7: Unit Tests (20 min)

```dart
// test/product_service_test.dart
import 'package:test/test.dart';

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
      // TODO: Arrange, Act, Assert
    });

    test('empty name throws ValidationException', () async {
      // TODO
    });

    test('negative price throws ValidationException', () async {
      // TODO
    });

    test('invalid categoryId throws ValidationException', () async {
      // TODO: categoryRepo.findById returns null
    });
  });

  group('adjustStock', () {
    test('positive delta increases stock', () async {
      // TODO
    });

    test('negative delta decreases stock', () async {
      // TODO
    });

    test('delta causing negative stock throws', () async {
      // TODO
    });

    test('non-existent product throws NotFoundException', () async {
      // TODO
    });
  });

  group('searchProducts', () {
    test('short query throws ValidationException', () async {
      // TODO: query.length < 2
    });

    test('valid query returns results', () async {
      // TODO
    });
  });
}
```

---

## Aufgabe 8: Dependency Injection (10 min)

```dart
// lib/container.dart
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
    // TODO: Pool erstellen
    // TODO: Repositories erstellen
    // TODO: Services erstellen
  }

  static ProductService get productService {
    if (_productService == null) {
      throw StateError('Container not initialized');
    }
    return _productService!;
  }

  // TODO: Getter für andere Services

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

## Aufgabe 9: Integration Test (Bonus, 15 min)

```dart
// test/integration/product_repository_test.dart
import 'package:test/test.dart';

void main() {
  late Pool pool;
  late PostgresProductRepository repository;

  setUpAll(() async {
    pool = Pool.withEndpoints([
      Endpoint(
        host: 'localhost',
        database: 'shop_test_db',
        username: 'postgres',
        password: 'secret',
      ),
    ]);

    repository = PostgresProductRepository(pool);

    // Tabellen erstellen
    await pool.execute('''
      CREATE TABLE IF NOT EXISTS products (...)
    ''');
  });

  setUp(() async {
    // Daten vor jedem Test löschen
    await pool.execute('DELETE FROM products');
  });

  tearDownAll(() async {
    await pool.close();
  });

  test('create and findById', () async {
    final created = await repository.create(ProductCreate(
      name: 'Test Product',
      price: 99.99,
    ));

    final found = await repository.findById(created.id);

    expect(found, isNotNull);
    expect(found!.name, equals('Test Product'));
  });

  // TODO: Weitere Tests
}
```

---

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
│   ├── base_repository.dart
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

test/
├── product_service_test.dart
└── integration/
    └── product_repository_test.dart
```

---

## Abgabe-Checkliste

- [ ] Product, Category, Customer Models mit fromRow
- [ ] ProductCreate und ProductUpdate DTOs
- [ ] ProductRepository Interface
- [ ] CategoryRepository Interface
- [ ] PostgresProductRepository Implementierung
- [ ] MockProductRepository Implementierung
- [ ] ProductService mit Validierung
- [ ] Custom Exceptions (Validation, NotFound, InsufficientStock)
- [ ] Mindestens 5 Unit Tests für ProductService
- [ ] Container für Dependency Injection
- [ ] (Bonus) Integration Tests für Repository
