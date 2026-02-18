# Lösung 7.2: PostgreSQL mit Dart

## Vollständige Lösung

```dart
import 'package:postgres/postgres.dart';

// ============================================
// Models
// ============================================

class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    required this.createdAt,
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
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'stock': stock,
    'categoryId': categoryId,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  String toString() => 'Product($id: $name, €$price, stock: $stock)';
}

class OrderItem {
  final int productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  double get total => price * quantity;
}

// ============================================
// Aufgabe 1: Verbindung herstellen
// ============================================

Future<Connection> connect() async {
  return await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'shop_db',
      username: 'postgres',
      password: 'secret',
    ),
    settings: ConnectionSettings(
      sslMode: SslMode.disable,
    ),
  );
}

// ============================================
// Aufgabe 2: Tabellen erstellen
// ============================================

Future<void> createTables(Connection conn) async {
  await conn.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id SERIAL PRIMARY KEY,
      name VARCHAR(50) NOT NULL UNIQUE
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS products (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      description TEXT,
      price DECIMAL(10, 2) NOT NULL,
      stock INTEGER NOT NULL DEFAULT 0,
      category_id INTEGER REFERENCES categories(id),
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS orders (
      id SERIAL PRIMARY KEY,
      total DECIMAL(10, 2) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
  ''');

  await conn.execute('''
    CREATE TABLE IF NOT EXISTS order_items (
      id SERIAL PRIMARY KEY,
      order_id INTEGER REFERENCES orders(id),
      product_id INTEGER REFERENCES products(id),
      quantity INTEGER NOT NULL,
      price DECIMAL(10, 2) NOT NULL
    )
  ''');
}

// ============================================
// Aufgabe 3: Daten einfügen
// ============================================

Future<int> insertCategory(Connection conn, String name) async {
  final result = await conn.execute(
    Sql.named('''
      INSERT INTO categories (name)
      VALUES (@name)
      ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
      RETURNING id
    '''),
    parameters: {'name': name},
  );
  return result.first[0] as int;
}

Future<int> insertProduct(
  Connection conn, {
  required String name,
  String? description,
  required double price,
  int stock = 0,
  int? categoryId,
}) async {
  final result = await conn.execute(
    Sql.named('''
      INSERT INTO products (name, description, price, stock, category_id)
      VALUES (@name, @description, @price, @stock, @categoryId)
      RETURNING id
    '''),
    parameters: {
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
    },
  );
  return result.first[0] as int;
}

Future<void> seedData(Connection conn) async {
  // Alte Daten löschen
  await conn.execute('DELETE FROM order_items');
  await conn.execute('DELETE FROM orders');
  await conn.execute('DELETE FROM products');
  await conn.execute('DELETE FROM categories');

  // Kategorien
  final electronicsId = await insertCategory(conn, 'Electronics');
  final clothingId = await insertCategory(conn, 'Clothing');
  final booksId = await insertCategory(conn, 'Books');

  // Produkte
  await insertProduct(
    conn,
    name: 'Laptop Pro 15',
    description: 'High-end laptop with 16GB RAM',
    price: 1299.99,
    stock: 25,
    categoryId: electronicsId,
  );

  await insertProduct(
    conn,
    name: 'Wireless Mouse',
    description: 'Ergonomic wireless mouse',
    price: 49.99,
    stock: 100,
    categoryId: electronicsId,
  );

  await insertProduct(
    conn,
    name: 'USB-C Hub',
    description: '7-in-1 USB-C hub',
    price: 79.99,
    stock: 50,
    categoryId: electronicsId,
  );

  await insertProduct(
    conn,
    name: 'T-Shirt Basic',
    description: '100% cotton t-shirt',
    price: 19.99,
    stock: 200,
    categoryId: clothingId,
  );

  await insertProduct(
    conn,
    name: 'Clean Code',
    description: 'Programming best practices by Robert C. Martin',
    price: 39.99,
    stock: 45,
    categoryId: booksId,
  );

  await insertProduct(
    conn,
    name: 'Mystery Box',
    description: 'Surprise item!',
    price: 9.99,
    stock: 5,
    categoryId: null,
  );
}

// ============================================
// Aufgabe 4: Daten abfragen
// ============================================

Future<void> listAllProducts(Connection conn) async {
  final result = await conn.execute('''
    SELECT id, name, price, stock
    FROM products
    ORDER BY name
  ''');

  for (final row in result) {
    print('${row[0]}: ${row[1]} - €${row[2]} (Stock: ${row[3]})');
  }
}

Future<Map<String, dynamic>?> getProductById(Connection conn, int id) async {
  final result = await conn.execute(
    Sql.named('SELECT * FROM products WHERE id = @id'),
    parameters: {'id': id},
  );

  if (result.isEmpty) return null;
  return result.first.toColumnMap();
}

Future<List<Map<String, dynamic>>> getProductsByCategory(
  Connection conn,
  String categoryName,
) async {
  final result = await conn.execute(
    Sql.named('''
      SELECT p.*, c.name AS category_name
      FROM products p
      JOIN categories c ON p.category_id = c.id
      WHERE c.name = @categoryName
      ORDER BY p.name
    '''),
    parameters: {'categoryName': categoryName},
  );

  return result.map((row) => row.toColumnMap()).toList();
}

Future<List<Map<String, dynamic>>> getProductsByPriceRange(
  Connection conn, {
  required double minPrice,
  required double maxPrice,
}) async {
  final result = await conn.execute(
    Sql.named('''
      SELECT * FROM products
      WHERE price >= @minPrice AND price <= @maxPrice
      ORDER BY price
    '''),
    parameters: {
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    },
  );

  return result.map((row) => row.toColumnMap()).toList();
}

// Mit Product Model
Future<List<Product>> getAllProducts(Connection conn) async {
  final result = await conn.execute(
    'SELECT * FROM products ORDER BY created_at DESC',
  );
  return result.map(Product.fromRow).toList();
}

// ============================================
// Aufgabe 5: Daten aktualisieren
// ============================================

Future<bool> updateProductPrice(
  Connection conn, {
  required int id,
  required double newPrice,
}) async {
  final result = await conn.execute(
    Sql.named('''
      UPDATE products
      SET price = @price
      WHERE id = @id
    '''),
    parameters: {
      'id': id,
      'price': newPrice,
    },
  );
  return result.affectedRows > 0;
}

Future<int> increaseStock(
  Connection conn, {
  required int productId,
  required int amount,
}) async {
  final result = await conn.execute(
    Sql.named('''
      UPDATE products
      SET stock = stock + @amount
      WHERE id = @productId
      RETURNING stock
    '''),
    parameters: {
      'productId': productId,
      'amount': amount,
    },
  );

  if (result.isEmpty) {
    throw Exception('Product not found: $productId');
  }

  return result.first[0] as int;
}

// ============================================
// Aufgabe 6: Daten löschen
// ============================================

Future<bool> deleteProduct(Connection conn, int id) async {
  final result = await conn.execute(
    Sql.named('DELETE FROM products WHERE id = @id'),
    parameters: {'id': id},
  );
  return result.affectedRows > 0;
}

// ============================================
// Aufgabe 7: Transaktionen
// ============================================

Future<int?> createOrder(Connection conn, List<OrderItem> items) async {
  if (items.isEmpty) {
    throw ArgumentError('Order must have at least one item');
  }

  try {
    return await conn.runTx((tx) async {
      // Gesamtsumme berechnen
      final total = items.fold(0.0, (sum, item) => sum + item.total);

      // 1. Order erstellen
      final orderResult = await tx.execute(
        Sql.named('''
          INSERT INTO orders (total)
          VALUES (@total)
          RETURNING id
        '''),
        parameters: {'total': total},
      );

      final orderId = orderResult.first[0] as int;

      // 2. Für jedes Item
      for (final item in items) {
        // Stock prüfen
        final stockResult = await tx.execute(
          Sql.named('SELECT stock FROM products WHERE id = @id'),
          parameters: {'id': item.productId},
        );

        if (stockResult.isEmpty) {
          throw Exception('Product not found: ${item.productId}');
        }

        final currentStock = stockResult.first[0] as int;
        if (currentStock < item.quantity) {
          throw Exception(
            'Not enough stock for product ${item.productId}: '
            'need ${item.quantity}, have $currentStock',
          );
        }

        // Order Item einfügen
        await tx.execute(
          Sql.named('''
            INSERT INTO order_items (order_id, product_id, quantity, price)
            VALUES (@orderId, @productId, @quantity, @price)
          '''),
          parameters: {
            'orderId': orderId,
            'productId': item.productId,
            'quantity': item.quantity,
            'price': item.price,
          },
        );

        // Stock reduzieren
        await tx.execute(
          Sql.named('''
            UPDATE products
            SET stock = stock - @quantity
            WHERE id = @productId
          '''),
          parameters: {
            'productId': item.productId,
            'quantity': item.quantity,
          },
        );
      }

      return orderId;
    });
  } catch (e) {
    print('Order failed: $e');
    return null;
  }
}

// ============================================
// Aufgabe 9: Connection Pool
// ============================================

late Pool dbPool;

Future<void> initPool() async {
  dbPool = Pool.withEndpoints(
    [
      Endpoint(
        host: 'localhost',
        database: 'shop_db',
        username: 'postgres',
        password: 'secret',
      ),
    ],
    settings: PoolSettings(
      maxConnectionCount: 5,
      sslMode: SslMode.disable,
    ),
  );
}

Future<void> closePool() async {
  await dbPool.close();
}

Future<List<Product>> getAllProductsFromPool() async {
  final result = await dbPool.execute('SELECT * FROM products');
  return result.map(Product.fromRow).toList();
}

// ============================================
// Main
// ============================================

Future<void> main() async {
  print('Connecting to PostgreSQL...');
  final conn = await connect();
  print('Connected!\n');

  try {
    // Tabellen erstellen
    print('Creating tables...');
    await createTables(conn);
    print('Tables created.\n');

    // Seed Data
    print('Seeding data...');
    await seedData(conn);
    print('Data seeded.\n');

    // ===== Aufgabe 4: Abfragen =====

    print('=== All Products ===');
    await listAllProducts(conn);

    print('\n=== Product by ID (1) ===');
    final product = await getProductById(conn, 1);
    if (product != null) {
      print('Found: ${product['name']} - €${product['price']}');
    }

    print('\n=== Products in Electronics ===');
    final electronics = await getProductsByCategory(conn, 'Electronics');
    for (final p in electronics) {
      print('  ${p['name']}: €${p['price']}');
    }

    print('\n=== Products €10-€50 ===');
    final affordable = await getProductsByPriceRange(
      conn,
      minPrice: 10,
      maxPrice: 50,
    );
    for (final p in affordable) {
      print('  ${p['name']}: €${p['price']}');
    }

    // ===== Aufgabe 5: Update =====

    print('\n=== Update Price ===');
    final updated = await updateProductPrice(conn, id: 1, newPrice: 1199.99);
    print('Updated: $updated');
    final updatedProduct = await getProductById(conn, 1);
    print('New price: €${updatedProduct?['price']}');

    print('\n=== Increase Stock ===');
    final newStock = await increaseStock(conn, productId: 1, amount: 5);
    print('New stock for product 1: $newStock');

    // ===== Aufgabe 7: Transaktion =====

    print('\n=== Create Order ===');
    // Produkt-Info für Bestellung holen
    final productForOrder = await getProductById(conn, 1);
    if (productForOrder != null) {
      print('Before order - Stock: ${productForOrder['stock']}');

      final orderId = await createOrder(conn, [
        OrderItem(
          productId: 1,
          quantity: 2,
          price: (productForOrder['price'] as num).toDouble(),
        ),
      ]);

      if (orderId != null) {
        print('Order created with ID: $orderId');

        final afterOrder = await getProductById(conn, 1);
        print('After order - Stock: ${afterOrder?['stock']}');
      }
    }

    // ===== Mit Product Model =====

    print('\n=== All Products (as Models) ===');
    final allProducts = await getAllProducts(conn);
    for (final p in allProducts) {
      print(p);
    }

    // ===== Aufgabe 6: Delete =====

    print('\n=== Delete Product ===');
    // Produkt ohne Kategorie löschen
    final result = await conn.execute(
      Sql.named('SELECT id FROM products WHERE category_id IS NULL LIMIT 1'),
    );
    if (result.isNotEmpty) {
      final idToDelete = result.first[0] as int;
      final deleted = await deleteProduct(conn, idToDelete);
      print('Deleted product $idToDelete: $deleted');
    }

    // ===== Pool Demo =====

    print('\n=== Pool Demo ===');
    await initPool();
    final poolProducts = await getAllProductsFromPool();
    print('Products from pool: ${poolProducts.length}');
    await closePool();
    print('Pool closed.');

  } catch (e, stackTrace) {
    print('Error: $e');
    print(stackTrace);
  } finally {
    await conn.close();
    print('\nDisconnected.');
  }
}
```

---

## Ausgabe

```
Connecting to PostgreSQL...
Connected!

Creating tables...
Tables created.

Seeding data...
Data seeded.

=== All Products ===
5: Clean Code - €39.99 (Stock: 45)
1: Laptop Pro 15 - €1299.99 (Stock: 25)
6: Mystery Box - €9.99 (Stock: 5)
4: T-Shirt Basic - €19.99 (Stock: 200)
3: USB-C Hub - €79.99 (Stock: 50)
2: Wireless Mouse - €49.99 (Stock: 100)

=== Product by ID (1) ===
Found: Laptop Pro 15 - €1299.99

=== Products in Electronics ===
  Laptop Pro 15: €1299.99
  USB-C Hub: €79.99
  Wireless Mouse: €49.99

=== Products €10-€50 ===
  T-Shirt Basic: €19.99
  Clean Code: €39.99
  Wireless Mouse: €49.99

=== Update Price ===
Updated: true
New price: €1199.99

=== Increase Stock ===
New stock for product 1: 30

=== Create Order ===
Before order - Stock: 30
Order created with ID: 1
After order - Stock: 28

=== All Products (as Models) ===
Product(6: Mystery Box, €9.99, stock: 5)
Product(5: Clean Code, €39.99, stock: 45)
Product(4: T-Shirt Basic, €19.99, stock: 200)
Product(3: USB-C Hub, €79.99, stock: 50)
Product(2: Wireless Mouse, €49.99, stock: 100)
Product(1: Laptop Pro 15, €1199.99, stock: 28)

=== Delete Product ===
Deleted product 6: true

=== Pool Demo ===
Products from pool: 5
Pool closed.

Disconnected.
```

---

## Projektstruktur

```
postgres_dart_demo/
├── bin/
│   └── main.dart
├── lib/
│   ├── models/
│   │   └── product.dart
│   ├── repositories/
│   │   └── product_repository.dart
│   └── database.dart
└── pubspec.yaml
```

### lib/database.dart

```dart
import 'package:postgres/postgres.dart';

class Database {
  static Pool? _pool;

  static Future<Pool> get pool async {
    _pool ??= Pool.withEndpoints(
      [
        Endpoint(
          host: 'localhost',
          database: 'shop_db',
          username: 'postgres',
          password: 'secret',
        ),
      ],
      settings: PoolSettings(
        maxConnectionCount: 10,
        sslMode: SslMode.disable,
      ),
    );
    return _pool!;
  }

  static Future<void> close() async {
    await _pool?.close();
    _pool = null;
  }
}
```

### lib/repositories/product_repository.dart

```dart
import 'package:postgres/postgres.dart';
import '../models/product.dart';

class ProductRepository {
  final Pool _pool;

  ProductRepository(this._pool);

  Future<List<Product>> findAll() async {
    final result = await _pool.execute(
      'SELECT * FROM products ORDER BY created_at DESC',
    );
    return result.map(Product.fromRow).toList();
  }

  Future<Product?> findById(int id) async {
    final result = await _pool.execute(
      Sql.named('SELECT * FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return Product.fromRow(result.first);
  }

  Future<int> create({
    required String name,
    String? description,
    required double price,
    int stock = 0,
    int? categoryId,
  }) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO products (name, description, price, stock, category_id)
        VALUES (@name, @description, @price, @stock, @categoryId)
        RETURNING id
      '''),
      parameters: {
        'name': name,
        'description': description,
        'price': price,
        'stock': stock,
        'categoryId': categoryId,
      },
    );
    return result.first[0] as int;
  }

  Future<bool> delete(int id) async {
    final result = await _pool.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }
}
```
