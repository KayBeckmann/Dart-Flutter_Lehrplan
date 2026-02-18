# Ressourcen: Repository Pattern

## Konzepte

- [Repository Pattern (Martin Fowler)](https://martinfowler.com/eaaCatalog/repository.html)
- [Unit of Work Pattern](https://martinfowler.com/eaaCatalog/unitOfWork.html)
- [Data Transfer Object (DTO)](https://martinfowler.com/eaaCatalog/dataTransferObject.html)

## Cheat Sheet: Repository Interface

```dart
// Generisches Interface
abstract class Repository<T, ID> {
  Future<List<T>> findAll();
  Future<T?> findById(ID id);
  Future<T> create(T entity);
  Future<T?> update(ID id, T entity);
  Future<bool> delete(ID id);
}

// Spezifisches Interface
abstract class ProductRepository {
  Future<List<Product>> findAll();
  Future<Product?> findById(int id);
  Future<List<Product>> findByCategory(int categoryId);
  Future<List<Product>> search(String query);

  Future<Product> create(ProductCreate data);
  Future<Product?> update(int id, ProductUpdate data);
  Future<bool> delete(int id);
}
```

## Cheat Sheet: DTOs

```dart
// Create DTO - required fields
class ProductCreate {
  final String name;
  final double price;
  final int stock;

  ProductCreate({
    required this.name,
    required this.price,
    this.stock = 0,
  });

  factory ProductCreate.fromJson(Map<String, dynamic> json) =>
      ProductCreate(
        name: json['name'],
        price: json['price'],
        stock: json['stock'] ?? 0,
      );
}

// Update DTO - all optional
class ProductUpdate {
  final String? name;
  final double? price;
  final int? stock;

  ProductUpdate({this.name, this.price, this.stock});

  bool get isEmpty => name == null && price == null && stock == null;

  factory ProductUpdate.fromJson(Map<String, dynamic> json) =>
      ProductUpdate(
        name: json['name'],
        price: json['price'],
        stock: json['stock'],
      );
}
```

## Cheat Sheet: PostgreSQL Repository

```dart
class PostgresProductRepository implements ProductRepository {
  final Pool _pool;

  PostgresProductRepository(this._pool);

  @override
  Future<List<Product>> findAll() async {
    final result = await _pool.execute('SELECT * FROM products');
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
  Future<Product> create(ProductCreate data) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO products (name, price, stock)
        VALUES (@name, @price, @stock)
        RETURNING *
      '''),
      parameters: {
        'name': data.name,
        'price': data.price,
        'stock': data.stock,
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
          price = COALESCE(@price, price),
          stock = COALESCE(@stock, stock)
        WHERE id = @id
        RETURNING *
      '''),
      parameters: {
        'id': id,
        'name': data.name,
        'price': data.price,
        'stock': data.stock,
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
}
```

## Cheat Sheet: Mock Repository

```dart
class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];
  int _nextId = 1;

  @override
  Future<List<Product>> findAll() async => List.from(_products);

  @override
  Future<Product?> findById(int id) async {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Product> create(ProductCreate data) async {
    final product = Product(
      id: _nextId++,
      name: data.name,
      price: data.price,
      stock: data.stock,
      createdAt: DateTime.now(),
    );
    _products.add(product);
    return product;
  }

  // Test helpers
  void clear() => _products.clear();
  void seed(List<Product> products) => _products.addAll(products);
}
```

## Cheat Sheet: Service Layer

```dart
class ProductService {
  final ProductRepository _repository;

  ProductService(this._repository);

  Future<Product> createProduct(ProductCreate data) async {
    // 1. Validierung
    if (data.name.length < 2) {
      throw ValidationException('Name too short');
    }
    if (data.price <= 0) {
      throw ValidationException('Price must be positive');
    }

    // 2. Geschäftslogik
    // ...

    // 3. Repository aufrufen
    return _repository.create(data);
  }

  Future<bool> reduceStock(int id, int quantity) async {
    // 1. Produkt laden
    final product = await _repository.findById(id);
    if (product == null) {
      throw NotFoundException('Product not found');
    }

    // 2. Validierung
    if (product.stock < quantity) {
      throw InsufficientStockException('Not enough stock');
    }

    // 3. Repository aufrufen
    return _repository.updateStock(id, -quantity);
  }
}
```

## Cheat Sheet: Exceptions

```dart
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
}

class NotFoundException implements Exception {
  final String message;
  NotFoundException(this.message);
}

class InsufficientStockException implements Exception {
  final String message;
  InsufficientStockException(this.message);
}
```

## Cheat Sheet: Unit Tests

```dart
import 'package:test/test.dart';

void main() {
  late MockProductRepository repository;
  late ProductService service;

  setUp(() {
    repository = MockProductRepository();
    service = ProductService(repository);
  });

  test('createProduct - valid data', () async {
    final data = ProductCreate(name: 'Test', price: 10);

    final product = await service.createProduct(data);

    expect(product.name, equals('Test'));
    expect(product.id, isPositive);
  });

  test('createProduct - invalid price - throws', () async {
    final data = ProductCreate(name: 'Test', price: -10);

    expect(
      () => service.createProduct(data),
      throwsA(isA<ValidationException>()),
    );
  });
}
```

## Cheat Sheet: Dependency Injection

```dart
// Simple Container
class Container {
  static late Pool _pool;
  static late ProductRepository _productRepo;
  static late ProductService _productService;

  static Future<void> init() async {
    _pool = Pool.withEndpoints([...]);
    _productRepo = PostgresProductRepository(_pool);
    _productService = ProductService(_productRepo);
  }

  static ProductService get productService => _productService;

  static Future<void> dispose() async {
    await _pool.close();
  }
}

// Verwendung
await Container.init();
final service = Container.productService;
await Container.dispose();
```

## Vorteile des Repository Patterns

| Vorteil | Beschreibung |
|---------|--------------|
| Testbarkeit | Mock-Repositories für Unit Tests |
| Austauschbarkeit | Einfacher Wechsel der Datenbank |
| Separation | Geschäftslogik getrennt von Datenzugriff |
| Wiederverwendbarkeit | Repositories in mehreren Services nutzbar |
| Wartbarkeit | Änderungen am Schema nur im Repository |

## Best Practices

1. **Interface zuerst** - Repository Interface definieren
2. **DTOs verwenden** - Trennung von Input/Output und Entity
3. **Validierung im Service** - Nicht im Repository
4. **Mock für Tests** - Kein Datenbankzugriff in Unit Tests
5. **Dependency Injection** - Repositories als Abhängigkeiten
6. **Transaktionen** - Unit of Work für mehrere Repositories
