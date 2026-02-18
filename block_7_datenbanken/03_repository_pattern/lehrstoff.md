# Einheit 7.3: Repository Pattern

## Lernziele

Nach dieser Einheit kannst du:
- Das Repository Pattern verstehen und anwenden
- Datenbankzugriffe von der Geschäftslogik trennen
- Testbare Repositories mit Interfaces erstellen
- Unit-of-Work Pattern für Transaktionen nutzen

---

## Was ist das Repository Pattern?

### Problem ohne Repository

```dart
// Direkte Datenbankzugriffe überall im Code
class ProductService {
  final Pool _db;

  Future<Product?> getProduct(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT * FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Product.fromRow(result.first);
  }

  Future<void> updateStock(int id, int quantity) async {
    // SQL direkt im Service - schwer zu testen!
    await _db.execute(
      Sql.named('UPDATE products SET stock = stock - @qty WHERE id = @id'),
      parameters: {'id': id, 'qty': quantity},
    );
  }
}
```

### Probleme

- SQL-Code verstreut in der gesamten Anwendung
- Schwer zu testen (Datenbank-Abhängigkeit)
- Duplizierter Code
- Schwer zu warten bei Schema-Änderungen

---

## Die Lösung: Repository Pattern

Das **Repository Pattern** abstrahiert den Datenzugriff hinter einem Interface.

```
┌─────────────────────────────────────────────────────────┐
│                    Business Logic                        │
│                   (ProductService)                       │
└─────────────────────────┬───────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                  Repository Interface                    │
│              (ProductRepositoryInterface)                │
└─────────────────────────┬───────────────────────────────┘
                          │
            ┌─────────────┴─────────────┐
            ▼                           ▼
┌───────────────────────┐   ┌───────────────────────┐
│  PostgresRepository   │   │   MockRepository      │
│  (Production)         │   │   (Testing)           │
└───────────────────────┘   └───────────────────────┘
```

---

## Repository Interface

### Generisches Interface

```dart
abstract class Repository<T, ID> {
  Future<List<T>> findAll();
  Future<T?> findById(ID id);
  Future<T> create(T entity);
  Future<T?> update(ID id, T entity);
  Future<bool> delete(ID id);
}
```

### Spezifisches Interface

```dart
abstract class ProductRepository {
  Future<List<Product>> findAll();
  Future<Product?> findById(int id);
  Future<List<Product>> findByCategory(String category);
  Future<List<Product>> findByPriceRange(double min, double max);
  Future<List<Product>> search(String query);

  Future<Product> create(ProductCreate data);
  Future<Product?> update(int id, ProductUpdate data);
  Future<bool> delete(int id);

  Future<bool> updateStock(int id, int quantity);
}
```

---

## PostgreSQL Implementation

```dart
import 'package:postgres/postgres.dart';

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
  Future<List<Product>> findByCategory(String category) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT p.* FROM products p
        JOIN categories c ON p.category_id = c.id
        WHERE c.name = @category
        ORDER BY p.name
      '''),
      parameters: {'category': category},
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
        WHERE name ILIKE @query
           OR description ILIKE @query
        ORDER BY name
      '''),
      parameters: {'query': '%$query%'},
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
  Future<bool> updateStock(int id, int quantity) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE products
        SET stock = stock + @quantity
        WHERE id = @id AND stock + @quantity >= 0
      '''),
      parameters: {'id': id, 'quantity': quantity},
    );
    return result.affectedRows > 0;
  }
}
```

---

## DTOs (Data Transfer Objects)

### Create DTO

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
}
```

### Update DTO

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
}
```

---

## Service Layer

Der Service verwendet das Repository für Geschäftslogik.

```dart
class ProductService {
  final ProductRepository _repository;

  ProductService(this._repository);

  Future<List<Product>> getAllProducts() {
    return _repository.findAll();
  }

  Future<Product?> getProduct(int id) {
    return _repository.findById(id);
  }

  Future<Product> createProduct(ProductCreate data) async {
    // Geschäftslogik / Validierung
    if (data.price <= 0) {
      throw ValidationException('Price must be positive');
    }
    if (data.name.length < 2) {
      throw ValidationException('Name must be at least 2 characters');
    }

    return _repository.create(data);
  }

  Future<Product?> updateProduct(int id, ProductUpdate data) async {
    if (data.isEmpty) {
      throw ValidationException('No data to update');
    }

    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Product not found: $id');
    }

    return _repository.update(id, data);
  }

  Future<bool> deleteProduct(int id) async {
    final existing = await _repository.findById(id);
    if (existing == null) {
      throw NotFoundException('Product not found: $id');
    }

    return _repository.delete(id);
  }

  Future<bool> reduceStock(int id, int quantity) async {
    if (quantity <= 0) {
      throw ValidationException('Quantity must be positive');
    }

    final product = await _repository.findById(id);
    if (product == null) {
      throw NotFoundException('Product not found: $id');
    }

    if (product.stock < quantity) {
      throw InsufficientStockException(
        'Not enough stock: need $quantity, have ${product.stock}',
      );
    }

    return _repository.updateStock(id, -quantity);
  }
}
```

---

## Mock Repository für Tests

```dart
class MockProductRepository implements ProductRepository {
  final List<Product> _products = [];
  int _nextId = 1;

  @override
  Future<List<Product>> findAll() async {
    return List.from(_products);
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
  Future<List<Product>> findByCategory(String category) async {
    // Vereinfacht für Tests
    return _products.where((p) => p.categoryId != null).toList();
  }

  @override
  Future<List<Product>> findByPriceRange(double min, double max) async {
    return _products.where((p) => p.price >= min && p.price <= max).toList();
  }

  @override
  Future<List<Product>> search(String query) async {
    final q = query.toLowerCase();
    return _products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false)
    ).toList();
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
    final updated = Product(
      id: existing.id,
      name: data.name ?? existing.name,
      description: data.description ?? existing.description,
      price: data.price ?? existing.price,
      stock: data.stock ?? existing.stock,
      categoryId: data.categoryId ?? existing.categoryId,
      createdAt: existing.createdAt,
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
  Future<bool> updateStock(int id, int quantity) async {
    final product = await findById(id);
    if (product == null) return false;
    if (product.stock + quantity < 0) return false;

    await update(id, ProductUpdate(stock: product.stock + quantity));
    return true;
  }

  // Test-Hilfsmethoden
  void clear() => _products.clear();
  void seed(List<Product> products) {
    _products.addAll(products);
    _nextId = products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
  }
}
```

---

## Unit Tests

```dart
import 'package:test/test.dart';

void main() {
  late MockProductRepository repository;
  late ProductService service;

  setUp(() {
    repository = MockProductRepository();
    service = ProductService(repository);
  });

  group('ProductService', () {
    test('createProduct - valid data - returns product', () async {
      final data = ProductCreate(
        name: 'Test Product',
        price: 99.99,
        stock: 10,
      );

      final product = await service.createProduct(data);

      expect(product.name, equals('Test Product'));
      expect(product.price, equals(99.99));
      expect(product.id, isPositive);
    });

    test('createProduct - negative price - throws', () async {
      final data = ProductCreate(
        name: 'Test',
        price: -10,
      );

      expect(
        () => service.createProduct(data),
        throwsA(isA<ValidationException>()),
      );
    });

    test('reduceStock - sufficient stock - reduces', () async {
      // Arrange
      await repository.create(ProductCreate(
        name: 'Test',
        price: 10,
        stock: 50,
      ));

      // Act
      final success = await service.reduceStock(1, 10);

      // Assert
      expect(success, isTrue);
      final product = await repository.findById(1);
      expect(product?.stock, equals(40));
    });

    test('reduceStock - insufficient stock - throws', () async {
      await repository.create(ProductCreate(
        name: 'Test',
        price: 10,
        stock: 5,
      ));

      expect(
        () => service.reduceStock(1, 10),
        throwsA(isA<InsufficientStockException>()),
      );
    });
  });
}
```

---

## Unit of Work Pattern

Für Transaktionen über mehrere Repositories.

```dart
abstract class UnitOfWork {
  ProductRepository get products;
  OrderRepository get orders;
  CustomerRepository get customers;

  Future<T> transaction<T>(Future<T> Function() action);
}

class PostgresUnitOfWork implements UnitOfWork {
  final Pool _pool;

  late final ProductRepository _products;
  late final OrderRepository _orders;
  late final CustomerRepository _customers;

  PostgresUnitOfWork(this._pool) {
    _products = PostgresProductRepository(_pool);
    _orders = PostgresOrderRepository(_pool);
    _customers = PostgresCustomerRepository(_pool);
  }

  @override
  ProductRepository get products => _products;

  @override
  OrderRepository get orders => _orders;

  @override
  CustomerRepository get customers => _customers;

  @override
  Future<T> transaction<T>(Future<T> Function() action) async {
    // Hier würde die eigentliche Transaktionslogik sein
    // In diesem Fall vereinfacht
    return await action();
  }
}
```

### Verwendung

```dart
class OrderService {
  final UnitOfWork _uow;

  OrderService(this._uow);

  Future<Order> createOrder(int customerId, List<OrderItem> items) async {
    return await _uow.transaction(() async {
      // Kunde prüfen
      final customer = await _uow.customers.findById(customerId);
      if (customer == null) {
        throw NotFoundException('Customer not found');
      }

      // Stock prüfen und reduzieren
      for (final item in items) {
        final product = await _uow.products.findById(item.productId);
        if (product == null) {
          throw NotFoundException('Product not found: ${item.productId}');
        }
        if (product.stock < item.quantity) {
          throw InsufficientStockException('Not enough stock');
        }

        await _uow.products.updateStock(item.productId, -item.quantity);
      }

      // Bestellung erstellen
      return await _uow.orders.create(OrderCreate(
        customerId: customerId,
        items: items,
      ));
    });
  }
}
```

---

## Dependency Injection

```dart
// Container für Dependencies
class Container {
  static late Pool _pool;
  static late ProductRepository _productRepository;
  static late ProductService _productService;

  static Future<void> init() async {
    _pool = Pool.withEndpoints([
      Endpoint(
        host: 'localhost',
        database: 'shop_db',
        username: 'postgres',
        password: 'secret',
      ),
    ]);

    _productRepository = PostgresProductRepository(_pool);
    _productService = ProductService(_productRepository);
  }

  static ProductService get productService => _productService;

  static Future<void> dispose() async {
    await _pool.close();
  }
}

// Verwendung
void main() async {
  await Container.init();

  final products = await Container.productService.getAllProducts();

  await Container.dispose();
}
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| Repository | Abstrahiert Datenzugriff |
| Interface | Ermöglicht Austauschbarkeit |
| DTO | Trennt Input von Entity |
| Service | Enthält Geschäftslogik |
| Mock | Ermöglicht Unit Tests |
| Unit of Work | Koordiniert Transaktionen |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Relationale Modellierung**: Wie du komplexe Beziehungen zwischen Tabellen modellierst und mit JOINs abfragst.
