# Einheit 7.2: PostgreSQL mit Dart

## Lernziele

Nach dieser Einheit kannst du:
- PostgreSQL-Verbindungen in Dart herstellen
- SQL-Queries ausführen und Ergebnisse verarbeiten
- Prepared Statements und Parametrisierung nutzen
- Connection Pools für bessere Performance verwenden

---

## Das postgres Package

### Installation

```yaml
# pubspec.yaml
dependencies:
  postgres: ^3.1.0
```

```bash
dart pub get
```

### Warum postgres?

- Offizielles PostgreSQL-Package für Dart
- Asynchron mit Futures
- Connection Pooling
- Prepared Statements
- Typ-sichere Parameter

---

## Verbindung herstellen

### Einfache Verbindung

```dart
import 'package:postgres/postgres.dart';

Future<void> main() async {
  // Verbindung konfigurieren
  final connection = await Connection.open(
    Endpoint(
      host: 'localhost',
      port: 5432,
      database: 'shop_db',
      username: 'postgres',
      password: 'secret',
    ),
    settings: ConnectionSettings(
      sslMode: SslMode.disable, // Für lokale Entwicklung
    ),
  );

  print('Connected to PostgreSQL!');

  // Verbindung nutzen...

  // Verbindung schließen
  await connection.close();
}
```

### Mit Connection String

```dart
final connection = await Connection.open(
  Endpoint(
    host: 'localhost',
    database: 'shop_db',
    username: 'postgres',
    password: 'secret',
  ),
);
```

### Umgebungsvariablen nutzen

```dart
import 'dart:io';

final connection = await Connection.open(
  Endpoint(
    host: Platform.environment['DB_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    database: Platform.environment['DB_NAME'] ?? 'shop_db',
    username: Platform.environment['DB_USER'] ?? 'postgres',
    password: Platform.environment['DB_PASSWORD'] ?? 'secret',
  ),
);
```

---

## Queries ausführen

### SELECT - Daten abfragen

```dart
Future<void> listProducts(Connection conn) async {
  final result = await conn.execute('SELECT * FROM products');

  for (final row in result) {
    print('ID: ${row[0]}, Name: ${row[1]}, Price: ${row[2]}');
  }
}
```

### Mit benannten Spalten

```dart
Future<void> listProducts(Connection conn) async {
  final result = await conn.execute('SELECT id, name, price FROM products');

  for (final row in result) {
    // Zugriff über Index
    final id = row[0] as int;
    final name = row[1] as String;
    final price = row[2] as double;

    print('$id: $name - €$price');
  }
}
```

### Result als Map

```dart
Future<void> listProducts(Connection conn) async {
  final result = await conn.execute(
    Sql.named('SELECT id, name, price FROM products'),
  );

  for (final row in result) {
    print(row.toColumnMap());
    // {id: 1, name: 'Laptop', price: 1299.99}
  }
}
```

---

## Parametrisierte Queries

**WICHTIG**: Niemals Strings direkt in SQL einbauen (SQL Injection!)

### Falsch (SQL Injection Gefahr!)

```dart
// NIEMALS SO MACHEN!
final name = "'; DROP TABLE products; --";
await conn.execute("SELECT * FROM products WHERE name = '$name'");
```

### Richtig: Positionale Parameter

```dart
Future<List<Map<String, dynamic>>> findByCategory(
  Connection conn,
  String category,
) async {
  final result = await conn.execute(
    Sql.named('SELECT * FROM products WHERE category = @category'),
    parameters: {'category': category},
  );

  return result.map((row) => row.toColumnMap()).toList();
}
```

### Mehrere Parameter

```dart
Future<List<Map<String, dynamic>>> findProducts(
  Connection conn, {
  required String category,
  required double minPrice,
  required double maxPrice,
}) async {
  final result = await conn.execute(
    Sql.named('''
      SELECT * FROM products
      WHERE category = @category
        AND price >= @minPrice
        AND price <= @maxPrice
      ORDER BY price
    '''),
    parameters: {
      'category': category,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    },
  );

  return result.map((row) => row.toColumnMap()).toList();
}
```

---

## INSERT, UPDATE, DELETE

### INSERT mit RETURNING

```dart
Future<int> createProduct(
  Connection conn, {
  required String name,
  required double price,
  required int categoryId,
}) async {
  final result = await conn.execute(
    Sql.named('''
      INSERT INTO products (name, price, category_id)
      VALUES (@name, @price, @categoryId)
      RETURNING id
    '''),
    parameters: {
      'name': name,
      'price': price,
      'categoryId': categoryId,
    },
  );

  // ID der neuen Zeile
  return result.first[0] as int;
}
```

### UPDATE

```dart
Future<int> updatePrice(
  Connection conn, {
  required int id,
  required double newPrice,
}) async {
  final result = await conn.execute(
    Sql.named('''
      UPDATE products
      SET price = @price, updated_at = NOW()
      WHERE id = @id
    '''),
    parameters: {
      'id': id,
      'price': newPrice,
    },
  );

  // Anzahl betroffener Zeilen
  return result.affectedRows;
}
```

### DELETE

```dart
Future<bool> deleteProduct(Connection conn, int id) async {
  final result = await conn.execute(
    Sql.named('DELETE FROM products WHERE id = @id'),
    parameters: {'id': id},
  );

  return result.affectedRows > 0;
}
```

---

## Transaktionen

### Einfache Transaktion

```dart
Future<void> transferMoney(
  Connection conn, {
  required int fromId,
  required int toId,
  required double amount,
}) async {
  await conn.runTx((tx) async {
    // Vom Sender abziehen
    await tx.execute(
      Sql.named('UPDATE accounts SET balance = balance - @amount WHERE id = @id'),
      parameters: {'id': fromId, 'amount': amount},
    );

    // Zum Empfänger hinzufügen
    await tx.execute(
      Sql.named('UPDATE accounts SET balance = balance + @amount WHERE id = @id'),
      parameters: {'id': toId, 'amount': amount},
    );
  });

  print('Transfer completed');
}
```

### Mit Fehlerbehandlung

```dart
Future<bool> createOrder(
  Connection conn, {
  required int userId,
  required List<OrderItem> items,
}) async {
  try {
    await conn.runTx((tx) async {
      // Bestellung erstellen
      final orderResult = await tx.execute(
        Sql.named('''
          INSERT INTO orders (user_id, total)
          VALUES (@userId, @total)
          RETURNING id
        '''),
        parameters: {
          'userId': userId,
          'total': items.fold(0.0, (sum, i) => sum + i.price * i.quantity),
        },
      );

      final orderId = orderResult.first[0] as int;

      // Bestellpositionen einfügen
      for (final item in items) {
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
    });

    return true;
  } catch (e) {
    print('Order failed: $e');
    return false;
  }
}
```

---

## Connection Pool

Für bessere Performance bei vielen gleichzeitigen Anfragen.

### Pool erstellen

```dart
import 'package:postgres/postgres.dart';

Future<Pool> createPool() async {
  final pool = Pool.withEndpoints(
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

  return pool;
}
```

### Pool verwenden

```dart
Future<void> main() async {
  final pool = await createPool();

  // Pool-Verbindung nutzen
  final products = await pool.execute('SELECT * FROM products');
  print('Found ${products.length} products');

  // Oder mit Callback
  await pool.run((conn) async {
    final result = await conn.execute('SELECT COUNT(*) FROM products');
    print('Total: ${result.first[0]}');
  });

  // Pool schließen
  await pool.close();
}
```

### In einer Server-Anwendung

```dart
late Pool dbPool;

Future<void> initDatabase() async {
  dbPool = Pool.withEndpoints(
    [
      Endpoint(
        host: 'localhost',
        database: 'shop_db',
        username: 'postgres',
        password: 'secret',
      ),
    ],
    settings: PoolSettings(maxConnectionCount: 10),
  );
}

// In Request-Handler
Future<Response> handleGetProducts(Request request) async {
  final result = await dbPool.execute('SELECT * FROM products');
  final products = result.map((row) => row.toColumnMap()).toList();
  return jsonResponse(products);
}
```

---

## Ergebnisse auf Models mappen

### Product Model

```dart
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
}
```

### Repository Pattern

```dart
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

  Future<int> create(ProductCreate data) async {
    final result = await _pool.execute(
      Sql.named('''
        INSERT INTO products (name, description, price, stock, category_id)
        VALUES (@name, @description, @price, @stock, @categoryId)
        RETURNING id
      '''),
      parameters: {
        'name': data.name,
        'description': data.description,
        'price': data.price,
        'stock': data.stock,
        'categoryId': data.categoryId,
      },
    );
    return result.first[0] as int;
  }

  Future<bool> update(int id, ProductUpdate data) async {
    final result = await _pool.execute(
      Sql.named('''
        UPDATE products
        SET name = COALESCE(@name, name),
            description = COALESCE(@description, description),
            price = COALESCE(@price, price),
            stock = COALESCE(@stock, stock)
        WHERE id = @id
      '''),
      parameters: {
        'id': id,
        'name': data.name,
        'description': data.description,
        'price': data.price,
        'stock': data.stock,
      },
    );
    return result.affectedRows > 0;
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

---

## Fehlerbehandlung

```dart
import 'package:postgres/postgres.dart';

Future<void> safeQuery(Pool pool) async {
  try {
    await pool.execute('SELECT * FROM nonexistent_table');
  } on ServerException catch (e) {
    print('PostgreSQL Error: ${e.message}');
    print('Code: ${e.code}');
    // z.B. 42P01 = undefined_table
  } on SocketException catch (e) {
    print('Connection Error: $e');
  } catch (e) {
    print('Unknown Error: $e');
  }
}
```

### Häufige Fehlercodes

| Code | Bedeutung |
|------|-----------|
| 23505 | unique_violation (Duplikat) |
| 23503 | foreign_key_violation |
| 23502 | not_null_violation |
| 42P01 | undefined_table |
| 42703 | undefined_column |

---

## Zusammenfassung

| Operation | Methode |
|-----------|---------|
| Verbindung | `Connection.open()` |
| Query | `conn.execute(Sql.named(...))` |
| Parameter | `parameters: {'key': value}` |
| Transaktion | `conn.runTx((tx) async {...})` |
| Pool | `Pool.withEndpoints([...])` |

---

## Nächste Schritte

In der nächsten Einheit lernst du das **Repository Pattern**: Wie du Datenbankzugriffe sauber von der Geschäftslogik trennst.
