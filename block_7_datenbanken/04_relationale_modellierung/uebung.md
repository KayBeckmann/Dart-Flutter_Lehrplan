# Übung 7.4: Relationale Modellierung

## Ziel

Modelliere ein vollständiges E-Commerce-Datenbankschema mit allen Beziehungstypen.

---

## Aufgabe 1: Schema entwerfen (20 min)

Entwirf ein Schema für einen Online-Shop mit folgenden Entitäten:

### Entitäten

1. **customers** - Kunden
2. **addresses** - Adressen (mehrere pro Kunde)
3. **categories** - Produktkategorien (hierarchisch)
4. **products** - Produkte
5. **tags** - Produkt-Tags (n:m)
6. **orders** - Bestellungen
7. **order_items** - Bestellpositionen

### Beziehungen

- Customer 1:n Addresses
- Category 1:n Products
- Category 1:n Categories (Selbstreferenz für Hierarchie)
- Product n:m Tags
- Customer 1:n Orders
- Order n:m Products (über order_items)

---

## Aufgabe 2: SQL-Schema erstellen (15 min)

Erstelle die CREATE TABLE Statements.

### customers

```sql
CREATE TABLE customers (
    -- TODO: id, name, email, created_at
);
```

### addresses

```sql
CREATE TABLE addresses (
    -- TODO: id, customer_id (FK), type, street, city, postal_code, country
    -- ON DELETE CASCADE
);
```

### categories

```sql
CREATE TABLE categories (
    -- TODO: id, name, parent_id (Selbstreferenz für Hierarchie)
);
```

### products

```sql
CREATE TABLE products (
    -- TODO: id, name, description, price, stock, category_id, created_at
);
```

### tags & product_tags

```sql
CREATE TABLE tags (
    -- TODO: id, name (UNIQUE)
);

CREATE TABLE product_tags (
    -- TODO: product_id, tag_id, composite primary key
    -- ON DELETE CASCADE für beide
);
```

### orders & order_items

```sql
CREATE TABLE orders (
    -- TODO: id, customer_id, status, total, created_at
);

CREATE TABLE order_items (
    -- TODO: id, order_id, product_id, quantity, unit_price
);
```

---

## Aufgabe 3: Testdaten einfügen (10 min)

```sql
-- Kunden
INSERT INTO customers (name, email) VALUES
    ('Max Müller', 'max@example.com'),
    ('Anna Schmidt', 'anna@example.com');

-- Adressen
INSERT INTO addresses (customer_id, type, street, city, postal_code, country)
VALUES
    (1, 'shipping', 'Hauptstr. 1', 'Berlin', '10115', 'Germany'),
    (1, 'billing', 'Nebenstr. 2', 'Berlin', '10115', 'Germany'),
    (2, 'shipping', 'Musterweg 3', 'München', '80331', 'Germany');

-- Kategorien (mit Hierarchie)
INSERT INTO categories (name, parent_id) VALUES
    ('Electronics', NULL),
    ('Clothing', NULL),
    ('Laptops', 1),      -- Unterkategorie von Electronics
    ('Smartphones', 1);  -- Unterkategorie von Electronics

-- Produkte
-- TODO: Mindestens 5 Produkte in verschiedenen Kategorien

-- Tags
INSERT INTO tags (name) VALUES
    ('sale'), ('new'), ('bestseller'), ('eco-friendly');

-- Product-Tags verknüpfen
-- TODO: Einige Produkte mit Tags verknüpfen

-- Bestellungen
-- TODO: 2 Bestellungen mit je 2-3 Positionen
```

---

## Aufgabe 4: JOINs schreiben (20 min)

### 4.1 Produkte mit Kategorien

```sql
-- Alle Produkte mit ihrem Kategorienamen
-- Produkte ohne Kategorie auch anzeigen
SELECT
    p.id,
    p.name AS product,
    -- TODO: Kategoriename
FROM products p
-- TODO: JOIN
```

### 4.2 Kategorien mit Unterkategorien

```sql
-- Kategorien mit ihren Parent-Kategorienamen
SELECT
    c.id,
    c.name AS category,
    -- TODO: parent.name AS parent_category
FROM categories c
-- TODO: Self-JOIN
```

### 4.3 Produkte mit Tags

```sql
-- Alle Produkte mit ihren Tags (als comma-separated list)
SELECT
    p.name AS product,
    STRING_AGG(t.name, ', ') AS tags
FROM products p
-- TODO: JOINs über product_tags
GROUP BY p.id, p.name;
```

### 4.4 Kunden mit Bestellübersicht

```sql
-- Kunden mit Anzahl Bestellungen und Gesamtumsatz
SELECT
    c.name AS customer,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.total), 0) AS total_spent
FROM customers c
-- TODO: LEFT JOIN orders
GROUP BY c.id, c.name;
```

### 4.5 Bestelldetails

```sql
-- Vollständige Bestellübersicht
SELECT
    o.id AS order_id,
    c.name AS customer,
    o.status,
    p.name AS product,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price AS line_total
FROM orders o
-- TODO: JOINs für customer, order_items, products
ORDER BY o.id, p.name;
```

---

## Aufgabe 5: Dart Models (15 min)

### Customer mit Adressen

```dart
class Customer {
  final int id;
  final String name;
  final String email;
  final List<Address> addresses;

  // TODO: Konstruktor, fromRow, toJson
}

class Address {
  final int id;
  final int customerId;
  final String type;
  final String street;
  final String city;
  final String postalCode;
  final String country;

  // TODO: Implementieren
}
```

### Product mit Category und Tags

```dart
class Product {
  final int id;
  final String name;
  final double price;
  final Category? category;
  final List<Tag> tags;

  // TODO: Implementieren
}
```

---

## Aufgabe 6: Repository für Relationen (20 min)

```dart
class ProductRepository {
  final Pool _pool;

  // Produkt mit Kategorie laden
  Future<Product?> findByIdWithCategory(int id) async {
    // TODO: JOIN query
    // TODO: Category aus Ergebnis extrahieren
  }

  // Produkt mit Tags laden
  Future<Product?> findByIdWithTags(int id) async {
    // TODO: Produkt laden
    // TODO: Tags separat laden
    // TODO: Kombinieren
  }

  // Alle Produkte einer Kategorie (inkl. Unterkategorien)
  Future<List<Product>> findByCategoryRecursive(int categoryId) async {
    // TODO: Recursive CTE oder mehrere Queries
  }

  // Tags setzen (alle ersetzen)
  Future<void> setTags(int productId, List<int> tagIds) async {
    // TODO: Alte löschen
    // TODO: Neue einfügen
  }
}
```

---

## Aufgabe 7: Order Repository (Bonus, 15 min)

```dart
class OrderRepository {
  // Bestellung mit allen Details laden
  Future<OrderDetails?> findByIdWithDetails(int id) async {
    // TODO: Order + Customer + Items + Products
  }

  // Bestellung erstellen (Transaktion)
  Future<Order> create({
    required int customerId,
    required List<OrderItemCreate> items,
  }) async {
    // TODO: Transaktion
    // 1. Order erstellen
    // 2. Items einfügen
    // 3. Stock reduzieren
    // 4. Total berechnen und updaten
  }
}

class OrderDetails {
  final Order order;
  final Customer customer;
  final List<OrderItemWithProduct> items;
}
```

---

## Abgabe-Checkliste

- [ ] Vollständiges SQL-Schema mit allen Tabellen
- [ ] Korrekte Foreign Keys mit ON DELETE
- [ ] Testdaten eingefügt
- [ ] JOIN: Produkte mit Kategorien
- [ ] JOIN: Kategorien mit Parent
- [ ] JOIN: Produkte mit Tags (STRING_AGG)
- [ ] JOIN: Kundenübersicht mit Aggregation
- [ ] JOIN: Bestelldetails
- [ ] Dart Models für Customer, Address, Product, Tag
- [ ] ProductRepository mit findByIdWithCategory
- [ ] ProductRepository mit findByIdWithTags
- [ ] (Bonus) OrderRepository mit Transaktion
