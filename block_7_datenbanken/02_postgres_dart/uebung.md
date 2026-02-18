# Übung 7.2: PostgreSQL mit Dart

## Ziel

Implementiere eine Dart-Anwendung, die mit PostgreSQL kommuniziert und CRUD-Operationen auf einer Produktdatenbank durchführt.

---

## Vorbereitung

### PostgreSQL starten

```bash
# Option A: Docker
docker run --name postgres-shop \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=shop_db \
  -p 5432:5432 \
  -d postgres:16

# Option B: Lokal
sudo systemctl start postgresql
createdb shop_db
```

### Projekt erstellen

```bash
mkdir postgres_dart_demo
cd postgres_dart_demo
dart create -t console .
```

### Dependencies

```yaml
# pubspec.yaml
name: postgres_dart_demo
environment:
  sdk: ^3.0.0

dependencies:
  postgres: ^3.1.0
```

```bash
dart pub get
```

---

## Aufgabe 1: Verbindung herstellen (10 min)

Erstelle `bin/main.dart` mit einer Datenbankverbindung.

### Anforderungen

1. Verbindung zu `localhost:5432`, Datenbank `shop_db`
2. Ausgabe bei erfolgreicher Verbindung
3. Verbindung am Ende schließen

### Vorlage

```dart
import 'package:postgres/postgres.dart';

Future<void> main() async {
  print('Connecting to PostgreSQL...');

  // TODO: Connection erstellen

  print('Connected!');

  // TODO: Connection schließen

  print('Disconnected.');
}
```

### Test

```bash
dart run
# Ausgabe:
# Connecting to PostgreSQL...
# Connected!
# Disconnected.
```

---

## Aufgabe 2: Tabellen erstellen (10 min)

Erstelle die Tabellen `categories` und `products` via Dart.

### SQL für Tabellen

```sql
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Implementierung

```dart
Future<void> createTables(Connection conn) async {
  // TODO: Tabellen erstellen
}
```

---

## Aufgabe 3: Daten einfügen (15 min)

Implementiere Funktionen zum Einfügen von Daten.

### 3.1 Kategorie einfügen

```dart
Future<int> insertCategory(Connection conn, String name) async {
  // TODO: INSERT mit RETURNING id
  // Parametrisierte Query verwenden!
}
```

### 3.2 Produkt einfügen

```dart
Future<int> insertProduct(
  Connection conn, {
  required String name,
  String? description,
  required double price,
  int stock = 0,
  int? categoryId,
}) async {
  // TODO: INSERT mit RETURNING id
}
```

### 3.3 Seed Data

```dart
Future<void> seedData(Connection conn) async {
  // Kategorien
  final electronicsId = await insertCategory(conn, 'Electronics');
  final clothingId = await insertCategory(conn, 'Clothing');

  // Produkte
  await insertProduct(
    conn,
    name: 'Laptop Pro',
    description: 'High-end laptop',
    price: 1299.99,
    stock: 25,
    categoryId: electronicsId,
  );

  // TODO: Weitere Produkte einfügen
}
```

---

## Aufgabe 4: Daten abfragen (15 min)

### 4.1 Alle Produkte

```dart
Future<void> listAllProducts(Connection conn) async {
  // TODO: SELECT * FROM products
  // Ausgabe: ID, Name, Preis
}
```

### 4.2 Produkt nach ID

```dart
Future<Map<String, dynamic>?> getProductById(Connection conn, int id) async {
  // TODO: SELECT mit WHERE id = @id
  // Return null wenn nicht gefunden
}
```

### 4.3 Produkte nach Kategorie

```dart
Future<List<Map<String, dynamic>>> getProductsByCategory(
  Connection conn,
  String categoryName,
) async {
  // TODO: JOIN mit categories
  // Filter nach category name
}
```

### 4.4 Produkte mit Preisspanne

```dart
Future<List<Map<String, dynamic>>> getProductsByPriceRange(
  Connection conn, {
  required double minPrice,
  required double maxPrice,
}) async {
  // TODO: SELECT mit BETWEEN oder >= AND <=
}
```

---

## Aufgabe 5: Daten aktualisieren (10 min)

### 5.1 Preis ändern

```dart
Future<bool> updateProductPrice(
  Connection conn, {
  required int id,
  required double newPrice,
}) async {
  // TODO: UPDATE mit RETURNING oder affectedRows prüfen
}
```

### 5.2 Stock erhöhen

```dart
Future<int> increaseStock(
  Connection conn, {
  required int productId,
  required int amount,
}) async {
  // TODO: UPDATE stock = stock + amount
  // Return neuen Stock-Wert
}
```

---

## Aufgabe 6: Daten löschen (5 min)

```dart
Future<bool> deleteProduct(Connection conn, int id) async {
  // TODO: DELETE mit affectedRows > 0
}
```

---

## Aufgabe 7: Transaktionen (15 min)

Implementiere eine Bestellung mit Transaktion.

### Szenario

1. Neue Bestellung erstellen
2. Stock der bestellten Produkte reduzieren
3. Bei Fehler: Rollback

### Tabelle für Bestellungen

```sql
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id),
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
```

### Implementierung

```dart
class OrderItem {
  final int productId;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.quantity,
    required this.price,
  });
}

Future<int?> createOrder(Connection conn, List<OrderItem> items) async {
  // TODO: Transaktion mit conn.runTx()
  // 1. Order erstellen
  // 2. Order Items einfügen
  // 3. Stock reduzieren
  // Return: Order ID oder null bei Fehler
}
```

---

## Aufgabe 8: Product Model (10 min)

Erstelle ein Product-Model mit fromRow Factory.

### Product Klasse

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

  // TODO: factory Product.fromRow(ResultRow row)

  // TODO: Map<String, dynamic> toJson()
}
```

### Verwendung

```dart
Future<List<Product>> getAllProducts(Connection conn) async {
  final result = await conn.execute('SELECT * FROM products');
  return result.map(Product.fromRow).toList();
}
```

---

## Aufgabe 9: Connection Pool (Bonus, 10 min)

Refactore die Anwendung mit einem Connection Pool.

```dart
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

// Nutzung
Future<List<Product>> getAllProducts() async {
  final result = await dbPool.execute('SELECT * FROM products');
  return result.map(Product.fromRow).toList();
}
```

---

## Testen

### Main-Funktion zum Testen

```dart
Future<void> main() async {
  final conn = await Connection.open(
    Endpoint(
      host: 'localhost',
      database: 'shop_db',
      username: 'postgres',
      password: 'secret',
    ),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  try {
    // Tabellen erstellen
    await createTables(conn);
    print('Tables created');

    // Seed Data
    await seedData(conn);
    print('Data seeded');

    // Alle Produkte
    print('\n--- All Products ---');
    await listAllProducts(conn);

    // Produkt nach ID
    print('\n--- Product by ID ---');
    final product = await getProductById(conn, 1);
    print(product);

    // Preis ändern
    print('\n--- Update Price ---');
    await updateProductPrice(conn, id: 1, newPrice: 1199.99);
    final updated = await getProductById(conn, 1);
    print('New price: ${updated?['price']}');

    // Bestellung erstellen
    print('\n--- Create Order ---');
    final orderId = await createOrder(conn, [
      OrderItem(productId: 1, quantity: 2, price: 1199.99),
    ]);
    print('Order ID: $orderId');

  } finally {
    await conn.close();
  }
}
```

---

## Abgabe-Checkliste

- [ ] Verbindung zu PostgreSQL funktioniert
- [ ] Tabellen werden erstellt (IF NOT EXISTS)
- [ ] Kategorien können eingefügt werden
- [ ] Produkte können eingefügt werden (mit Parametern)
- [ ] Alle Produkte können abgefragt werden
- [ ] Produkt nach ID finden funktioniert
- [ ] Produkte nach Kategorie filtern
- [ ] Produkte nach Preisspanne filtern
- [ ] Preis aktualisieren funktioniert
- [ ] Stock erhöhen funktioniert
- [ ] Produkt löschen funktioniert
- [ ] Transaktion für Bestellung implementiert
- [ ] Product Model mit fromRow erstellt
- [ ] (Bonus) Connection Pool implementiert
