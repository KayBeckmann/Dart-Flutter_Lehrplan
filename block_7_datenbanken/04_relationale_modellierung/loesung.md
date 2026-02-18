# Lösung 7.4: Relationale Modellierung

## SQL-Schema

```sql
-- ==========================================
-- Customers & Addresses
-- ==========================================

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE addresses (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('shipping', 'billing')),
    street VARCHAR(255) NOT NULL,
    city VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(50) NOT NULL DEFAULT 'Germany'
);

CREATE INDEX idx_addresses_customer ON addresses(customer_id);

-- ==========================================
-- Categories (hierarchisch)
-- ==========================================

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_categories_parent ON categories(parent_id);

-- ==========================================
-- Products
-- ==========================================

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category_id);

-- ==========================================
-- Tags (n:m)
-- ==========================================

CREATE TABLE tags (
    id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE product_tags (
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    tag_id INTEGER REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, tag_id)
);

-- ==========================================
-- Orders
-- ==========================================

CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL REFERENCES customers(id),
    shipping_address_id INTEGER REFERENCES addresses(id),
    status VARCHAR(20) DEFAULT 'pending' CHECK (
        status IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')
    ),
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_orders_customer ON orders(customer_id);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
```

---

## Testdaten

```sql
-- Kunden
INSERT INTO customers (name, email) VALUES
    ('Max Müller', 'max@example.com'),
    ('Anna Schmidt', 'anna@example.com'),
    ('Tom Weber', 'tom@example.com');

-- Adressen
INSERT INTO addresses (customer_id, type, street, city, postal_code, country) VALUES
    (1, 'shipping', 'Hauptstr. 1', 'Berlin', '10115', 'Germany'),
    (1, 'billing', 'Nebenstr. 2', 'Berlin', '10115', 'Germany'),
    (2, 'shipping', 'Musterweg 3', 'München', '80331', 'Germany'),
    (3, 'shipping', 'Teststr. 5', 'Hamburg', '20095', 'Germany');

-- Kategorien (hierarchisch)
INSERT INTO categories (name, parent_id) VALUES
    ('Electronics', NULL),       -- 1
    ('Clothing', NULL),          -- 2
    ('Books', NULL),             -- 3
    ('Laptops', 1),              -- 4, Unterkategorie von Electronics
    ('Smartphones', 1),          -- 5, Unterkategorie von Electronics
    ('T-Shirts', 2);             -- 6, Unterkategorie von Clothing

-- Produkte
INSERT INTO products (name, description, price, stock, category_id) VALUES
    ('MacBook Pro', '16" Laptop', 2499.00, 15, 4),
    ('ThinkPad X1', 'Business Laptop', 1499.00, 25, 4),
    ('iPhone 15', 'Latest iPhone', 1199.00, 50, 5),
    ('Galaxy S24', 'Samsung Flagship', 999.00, 40, 5),
    ('Basic T-Shirt', 'Cotton T-Shirt', 19.99, 200, 6),
    ('Clean Code', 'Programming Book', 39.99, 100, 3),
    ('USB-C Hub', '7-in-1 Hub', 49.99, 80, 1);

-- Tags
INSERT INTO tags (name) VALUES
    ('sale'),
    ('new'),
    ('bestseller'),
    ('eco-friendly'),
    ('premium');

-- Product-Tags
INSERT INTO product_tags (product_id, tag_id) VALUES
    (1, 2), (1, 5),           -- MacBook: new, premium
    (3, 2), (3, 3),           -- iPhone: new, bestseller
    (5, 1), (5, 4),           -- T-Shirt: sale, eco-friendly
    (6, 3);                   -- Clean Code: bestseller

-- Bestellungen
INSERT INTO orders (customer_id, shipping_address_id, status, total) VALUES
    (1, 1, 'delivered', 2548.99),
    (1, 1, 'shipped', 1199.00),
    (2, 3, 'pending', 59.98);

-- Bestellpositionen
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 2499.00),
    (1, 7, 1, 49.99),
    (2, 3, 1, 1199.00),
    (3, 5, 2, 19.99),
    (3, 6, 1, 39.99);
```

---

## JOIN-Abfragen

### 4.1 Produkte mit Kategorien

```sql
SELECT
    p.id,
    p.name AS product,
    p.price,
    COALESCE(c.name, 'Keine Kategorie') AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
ORDER BY category, p.name;
```

### 4.2 Kategorien mit Parent

```sql
SELECT
    c.id,
    c.name AS category,
    parent.name AS parent_category
FROM categories c
LEFT JOIN categories parent ON c.parent_id = parent.id
ORDER BY parent.name NULLS FIRST, c.name;
```

### 4.3 Produkte mit Tags

```sql
SELECT
    p.id,
    p.name AS product,
    COALESCE(STRING_AGG(t.name, ', ' ORDER BY t.name), '') AS tags
FROM products p
LEFT JOIN product_tags pt ON p.id = pt.product_id
LEFT JOIN tags t ON pt.tag_id = t.id
GROUP BY p.id, p.name
ORDER BY p.name;
```

### 4.4 Kundenübersicht

```sql
SELECT
    c.id,
    c.name AS customer,
    c.email,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent,
    MAX(o.created_at) AS last_order
FROM customers c
LEFT JOIN orders o ON c.id = o.customer_id
GROUP BY c.id, c.name, c.email
ORDER BY total_spent DESC;
```

### 4.5 Bestelldetails

```sql
SELECT
    o.id AS order_id,
    o.created_at AS order_date,
    c.name AS customer,
    o.status,
    p.name AS product,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id
ORDER BY o.id, p.name;
```

### Bonus: Kategorien mit Produktanzahl (rekursiv)

```sql
WITH RECURSIVE category_tree AS (
    -- Basis: Root-Kategorien
    SELECT id, name, parent_id, ARRAY[id] AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Rekursion: Unterkategorien
    SELECT c.id, c.name, c.parent_id, ct.path || c.id
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT
    ct.id,
    ct.name,
    ARRAY_LENGTH(ct.path, 1) - 1 AS depth,
    COUNT(p.id) AS product_count
FROM category_tree ct
LEFT JOIN products p ON p.category_id = ct.id
GROUP BY ct.id, ct.name, ct.path
ORDER BY ct.path;
```

---

## Dart Models

```dart
// Customer mit Adressen
class Customer {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  final List<Address> addresses;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.addresses = const [],
  });

  factory Customer.fromRow(ResultRow row, [List<Address>? addresses]) {
    final map = row.toColumnMap();
    return Customer(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
      createdAt: map['created_at'] as DateTime,
      addresses: addresses ?? [],
    );
  }
}

class Address {
  final int id;
  final int customerId;
  final String type;
  final String street;
  final String city;
  final String postalCode;
  final String country;

  Address({
    required this.id,
    required this.customerId,
    required this.type,
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  factory Address.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return Address(
      id: map['id'] as int,
      customerId: map['customer_id'] as int,
      type: map['type'] as String,
      street: map['street'] as String,
      city: map['city'] as String,
      postalCode: map['postal_code'] as String,
      country: map['country'] as String,
    );
  }
}

// Product mit Category und Tags
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final int? categoryId;
  final Category? category;
  final List<Tag> tags;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.categoryId,
    this.category,
    this.tags = const [],
  });
}

class Tag {
  final int id;
  final String name;

  Tag({required this.id, required this.name});
}
```

---

## Repository

```dart
class ProductRepository {
  final Pool _pool;

  ProductRepository(this._pool);

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
      description: row['description'] as String?,
      price: (row['price'] as num).toDouble(),
      stock: row['stock'] as int,
      categoryId: row['category_id'] as int?,
      category: category,
    );
  }

  Future<Product?> findByIdWithTags(int id) async {
    final productResult = await _pool.execute(
      Sql.named('SELECT * FROM products WHERE id = @id'),
      parameters: {'id': id},
    );

    if (productResult.isEmpty) return null;

    final tagResult = await _pool.execute(
      Sql.named('''
        SELECT t.id, t.name
        FROM tags t
        JOIN product_tags pt ON t.id = pt.tag_id
        WHERE pt.product_id = @id
        ORDER BY t.name
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
      description: row['description'] as String?,
      price: (row['price'] as num).toDouble(),
      stock: row['stock'] as int,
      tags: tags,
    );
  }

  Future<void> setTags(int productId, List<int> tagIds) async {
    await _pool.execute(
      Sql.named('DELETE FROM product_tags WHERE product_id = @id'),
      parameters: {'id': productId},
    );

    for (final tagId in tagIds) {
      await _pool.execute(
        Sql.named('''
          INSERT INTO product_tags (product_id, tag_id)
          VALUES (@productId, @tagId)
        '''),
        parameters: {'productId': productId, 'tagId': tagId},
      );
    }
  }
}
```
