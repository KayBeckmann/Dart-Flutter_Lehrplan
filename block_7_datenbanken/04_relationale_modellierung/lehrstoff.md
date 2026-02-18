# Einheit 7.4: Relationale Modellierung

## Lernziele

Nach dieser Einheit kannst du:
- Beziehungen zwischen Tabellen modellieren (1:1, 1:n, n:m)
- Foreign Keys und Constraints korrekt einsetzen
- Komplexe JOINs für verknüpfte Daten schreiben
- Normalisierung verstehen und anwenden

---

## Beziehungstypen

### 1:1 (One-to-One)

Ein Datensatz in Tabelle A gehört zu genau einem Datensatz in Tabelle B.

```sql
-- Beispiel: User und UserProfile
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id),
    bio TEXT,
    avatar_url VARCHAR(255)
);
```

### 1:n (One-to-Many)

Ein Datensatz in Tabelle A gehört zu vielen Datensätzen in Tabelle B.

```sql
-- Beispiel: Category und Products
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES categories(id)
);

-- Eine Kategorie hat viele Produkte
-- Ein Produkt gehört zu einer Kategorie
```

### n:m (Many-to-Many)

Viele Datensätze in A gehören zu vielen Datensätzen in B.

```sql
-- Beispiel: Products und Tags
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);

-- Zwischentabelle (Junction Table)
CREATE TABLE product_tags (
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, tag_id)
);
```

---

## Foreign Key Constraints

### ON DELETE Optionen

```sql
-- CASCADE: Verknüpfte Datensätze auch löschen
REFERENCES users(id) ON DELETE CASCADE

-- SET NULL: Foreign Key auf NULL setzen
REFERENCES category(id) ON DELETE SET NULL

-- RESTRICT: Löschen verhindern (Default)
REFERENCES category(id) ON DELETE RESTRICT

-- SET DEFAULT: Auf Default-Wert setzen
REFERENCES category(id) ON DELETE SET DEFAULT
```

### ON UPDATE Optionen

```sql
-- CASCADE: ID-Änderung übernehmen
REFERENCES users(id) ON UPDATE CASCADE

-- RESTRICT: ID-Änderung verhindern
REFERENCES users(id) ON UPDATE RESTRICT
```

---

## JOINs für verknüpfte Daten

### INNER JOIN

```sql
-- Produkte mit Kategorienamen
SELECT p.id, p.name, c.name AS category
FROM products p
INNER JOIN categories c ON p.category_id = c.id;
```

### LEFT JOIN

```sql
-- Alle Produkte, auch ohne Kategorie
SELECT p.id, p.name, c.name AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;
```

### Multiple JOINs

```sql
-- Bestellungen mit Kunde und Produkten
SELECT
    o.id AS order_id,
    c.name AS customer,
    p.name AS product,
    oi.quantity,
    oi.price
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON oi.order_id = o.id
JOIN products p ON oi.product_id = p.id;
```

### n:m JOIN

```sql
-- Produkte mit ihren Tags
SELECT p.name AS product, t.name AS tag
FROM products p
JOIN product_tags pt ON p.id = pt.product_id
JOIN tags t ON pt.tag_id = t.id
ORDER BY p.name, t.name;
```

---

## Komplexes Schema: E-Commerce

```sql
-- Kunden
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Adressen (1:n mit Customer)
CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL, -- 'shipping', 'billing'
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL
);

-- Kategorien
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INTEGER REFERENCES categories(id) -- Selbstreferenz für Hierarchie
);

-- Produkte
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    stock INTEGER NOT NULL DEFAULT 0,
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bestellungen
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES customers(id),
    shipping_address_id INTEGER REFERENCES addresses(id),
    billing_address_id INTEGER REFERENCES addresses(id),
    status VARCHAR(20) DEFAULT 'pending',
    total DECIMAL(10, 2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bestellpositionen (n:m zwischen Order und Product)
CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id),
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL
);
```

---

## Dart Models für Relationen

### One-to-Many

```dart
class Category {
  final int id;
  final String name;
  final List<Product> products; // Lazy loading oder eager

  Category({required this.id, required this.name, this.products = const []});
}

class Product {
  final int id;
  final String name;
  final int? categoryId;
  final Category? category; // Optionale Referenz

  Product({
    required this.id,
    required this.name,
    this.categoryId,
    this.category,
  });
}
```

### Many-to-Many

```dart
class Product {
  final int id;
  final String name;
  final List<Tag> tags;

  Product({required this.id, required this.name, this.tags = const []});
}

class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});
}
```

---

## Repository für Relationen

```dart
class ProductRepository {
  final Pool _pool;

  // Produkt mit Kategorie laden
  Future<Product?> findByIdWithCategory(int id) async {
    final result = await _pool.execute(
      Sql.named('''
        SELECT
          p.*,
          c.id AS cat_id,
          c.name AS cat_name
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE p.id = @id
      '''),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;

    final row = result.first.toColumnMap();
    Category? category;
    if (row['cat_id'] != null) {
      category = Category(
        id: row['cat_id'] as int,
        name: row['cat_name'] as String,
      );
    }

    return Product(
      id: row['id'] as int,
      name: row['name'] as String,
      categoryId: row['category_id'] as int?,
      category: category,
    );
  }

  // Produkt mit Tags laden
  Future<Product?> findByIdWithTags(int id) async {
    final productResult = await _pool.execute(
      Sql.named('SELECT * FROM products WHERE id = @id'),
      parameters: {'id': id},
    );

    if (productResult.isEmpty) return null;

    final tagResult = await _pool.execute(
      Sql.named('''
        SELECT t.*
        FROM tags t
        JOIN product_tags pt ON t.id = pt.tag_id
        WHERE pt.product_id = @id
      '''),
      parameters: {'id': id},
    );

    final tags = tagResult.map((r) {
      final m = r.toColumnMap();
      return Tag(id: m['id'] as int, name: m['name'] as String);
    }).toList();

    final row = productResult.first.toColumnMap();
    return Product(
      id: row['id'] as int,
      name: row['name'] as String,
      tags: tags,
    );
  }

  // Tags zu Produkt hinzufügen
  Future<void> addTags(int productId, List<int> tagIds) async {
    for (final tagId in tagIds) {
      await _pool.execute(
        Sql.named('''
          INSERT INTO product_tags (product_id, tag_id)
          VALUES (@productId, @tagId)
          ON CONFLICT DO NOTHING
        '''),
        parameters: {'productId': productId, 'tagId': tagId},
      );
    }
  }
}
```

---

## Normalisierung

### 1. Normalform (1NF)

- Keine Wiederholungsgruppen
- Atomare Werte

```sql
-- Schlecht
CREATE TABLE orders (
    id SERIAL,
    products TEXT  -- "Product1, Product2, Product3"
);

-- Gut (1NF)
CREATE TABLE order_items (
    order_id INTEGER,
    product_id INTEGER
);
```

### 2. Normalform (2NF)

- 1NF + alle Nicht-Schlüssel-Attribute voll funktional abhängig vom Primärschlüssel

### 3. Normalform (3NF)

- 2NF + keine transitiven Abhängigkeiten

```sql
-- Schlecht (Kunde-Stadt impliziert Land)
CREATE TABLE customers (
    id SERIAL,
    name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50)  -- Abhängig von city
);

-- Gut (3NF)
CREATE TABLE cities (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    country VARCHAR(50)
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    city_id INTEGER REFERENCES cities(id)
);
```

---

## Zusammenfassung

| Beziehung | Implementierung |
|-----------|-----------------|
| 1:1 | Foreign Key mit UNIQUE |
| 1:n | Foreign Key |
| n:m | Zwischentabelle mit zwei Foreign Keys |

| JOIN | Verwendung |
|------|------------|
| INNER | Nur übereinstimmende |
| LEFT | Alle links + matches |
| RIGHT | Alle rechts + matches |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Migrations**: Wie du Datenbankänderungen versioniert und sicher durchführst.
