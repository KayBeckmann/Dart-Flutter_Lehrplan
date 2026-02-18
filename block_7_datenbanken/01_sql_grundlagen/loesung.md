# Lösung 7.1: SQL-Grundlagen

## Aufgabe 1: Tabellen erstellen

```sql
-- Kategorien-Tabelle
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

-- Produkte-Tabelle
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Kunden-Tabelle
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Aufgabe 2: Daten einfügen

### Kategorien

```sql
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Fashion and apparel'),
    ('Books', 'Books and magazines'),
    ('Home & Garden', 'Home improvement and gardening');
```

### Produkte

```sql
INSERT INTO products (name, description, price, stock, category_id) VALUES
    -- Electronics (category_id = 1)
    ('Laptop Pro 15', 'High-end laptop with 16GB RAM', 1299.99, 25, 1),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 49.99, 100, 1),
    ('USB-C Hub', '7-in-1 USB-C hub', 79.99, 50, 1),
    ('Smartphone X', 'Latest smartphone with 5G', 899.00, 30, 1),

    -- Clothing (category_id = 2)
    ('T-Shirt Basic', '100% cotton t-shirt', 19.99, 200, 2),
    ('Jeans Classic', 'Blue denim jeans', 59.99, 75, 2),
    ('Winter Jacket', 'Warm winter jacket', 149.99, 20, 2),

    -- Books (category_id = 3)
    ('Clean Code', 'Programming best practices', 39.99, 45, 3),
    ('Flutter Complete', 'Learn Flutter development', 49.99, 30, 3),

    -- Home & Garden (category_id = 4)
    ('Garden Tools Set', 'Complete garden tool set', 89.99, 15, 4),
    ('LED Lamp', 'Energy-efficient LED lamp', 29.99, 60, 4),

    -- Ohne Kategorie
    ('Mystery Box', 'Surprise item', 9.99, 0, NULL);
```

### Kunden

```sql
INSERT INTO customers (name, email) VALUES
    ('Max Müller', 'max@example.com'),
    ('Anna Schmidt', 'anna@example.com'),
    ('Tom Weber', 'tom@example.com'),
    ('Lisa Fischer', 'lisa@example.com'),
    ('Jan Becker', 'jan@example.com');
```

---

## Aufgabe 3: Einfache Abfragen

### 3.1 Alle Produkte sortiert nach Name

```sql
SELECT * FROM products
ORDER BY name ASC;
```

### 3.2 Produkte über 100€

```sql
SELECT name, price
FROM products
WHERE price > 100
ORDER BY price DESC;
```

**Ergebnis:**
```
      name       |  price
-----------------+---------
 Laptop Pro 15   | 1299.99
 Smartphone X    |  899.00
 Winter Jacket   |  149.99
```

### 3.3 Produkte auf Lager

```sql
SELECT name, stock
FROM products
WHERE stock > 0
ORDER BY stock DESC;
```

### 3.4 Günstigstes und teuerstes Produkt

```sql
SELECT
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM products;
```

**Ergebnis:**
```
 cheapest | most_expensive
----------+----------------
     9.99 |        1299.99
```

```sql
-- Oder mit Produktnamen:
SELECT name, price FROM products WHERE price = (SELECT MIN(price) FROM products)
UNION
SELECT name, price FROM products WHERE price = (SELECT MAX(price) FROM products);
```

### 3.5 Anzahl Produkte pro Kategorie

```sql
SELECT
    c.name AS category,
    COUNT(p.id) AS product_count
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY product_count DESC;
```

**Ergebnis:**
```
   category    | product_count
---------------+---------------
 Electronics   |             4
 Clothing      |             3
 Books         |             2
 Home & Garden |             2
```

---

## Aufgabe 4: Komplexere Abfragen

### 4.1 Filter kombinieren

```sql
SELECT p.name, p.price, p.stock
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE c.name = 'Electronics'
  AND p.price > 50
  AND p.stock > 0
ORDER BY p.price DESC;
```

**Ergebnis:**
```
     name      |  price  | stock
---------------+---------+-------
 Laptop Pro 15 | 1299.99 |    25
 Smartphone X  |  899.00 |    30
 USB-C Hub     |   79.99 |    50
```

### 4.2 Textsuche

```sql
SELECT name, description
FROM products
WHERE name ILIKE '%pro%'
   OR description ILIKE '%pro%';
```

**Ergebnis:**
```
     name      |          description
---------------+--------------------------------
 Laptop Pro 15 | High-end laptop with 16GB RAM
```

### 4.3 Preisbereiche

```sql
SELECT
    name,
    price,
    CASE
        WHEN price < 50 THEN 'Günstig'
        WHEN price <= 200 THEN 'Mittel'
        ELSE 'Premium'
    END AS price_category
FROM products
ORDER BY price;
```

**Ergebnis:**
```
      name       |  price  | price_category
-----------------+---------+----------------
 Mystery Box     |    9.99 | Günstig
 T-Shirt Basic   |   19.99 | Günstig
 LED Lamp        |   29.99 | Günstig
 Clean Code      |   39.99 | Günstig
 Wireless Mouse  |   49.99 | Günstig
 Flutter Complete|   49.99 | Günstig
 Jeans Classic   |   59.99 | Mittel
 USB-C Hub       |   79.99 | Mittel
 Garden Tools Set|   89.99 | Mittel
 Winter Jacket   |  149.99 | Mittel
 Smartphone X    |  899.00 | Premium
 Laptop Pro 15   | 1299.99 | Premium
```

### 4.4 Top 5 teuerste Produkte mit Kategorie

```sql
SELECT
    p.name AS product,
    p.price,
    COALESCE(c.name, 'Keine Kategorie') AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
ORDER BY p.price DESC
LIMIT 5;
```

**Ergebnis:**
```
    product     |  price  |   category
----------------+---------+-------------
 Laptop Pro 15  | 1299.99 | Electronics
 Smartphone X   |  899.00 | Electronics
 Winter Jacket  |  149.99 | Clothing
 Garden Tools   |   89.99 | Home & Garden
 USB-C Hub      |   79.99 | Electronics
```

---

## Aufgabe 5: JOINs

### 5.1 Produkte mit Kategorienamen

```sql
SELECT
    p.id,
    p.name AS product_name,
    p.price,
    p.stock,
    COALESCE(c.name, 'Keine Kategorie') AS category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
ORDER BY category_name, p.name;
```

### 5.2 Kategorien mit Statistiken

```sql
SELECT
    c.name AS category,
    COUNT(p.id) AS product_count,
    ROUND(AVG(p.price), 2) AS avg_price,
    SUM(p.price * p.stock) AS total_value
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name
ORDER BY total_value DESC NULLS LAST;
```

**Ergebnis:**
```
   category    | product_count | avg_price | total_value
---------------+---------------+-----------+-------------
 Electronics   |             4 |    582.24 |    68747.00
 Clothing      |             3 |     76.66 |    11498.50
 Books         |             2 |     44.99 |     3299.25
 Home & Garden |             2 |     59.99 |     3149.25
```

### 5.3 Leere Kategorien

```sql
SELECT c.name AS empty_category
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
WHERE p.id IS NULL;
```

**Ergebnis (falls vorhanden):**
```
 empty_category
----------------
 (keine Ergebnisse wenn alle Kategorien Produkte haben)
```

Zum Testen, füge eine leere Kategorie hinzu:

```sql
INSERT INTO categories (name) VALUES ('Sports');

-- Jetzt nochmal:
SELECT c.name AS empty_category
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
WHERE p.id IS NULL;

-- Ergebnis:
--  empty_category
-- ----------------
--  Sports
```

---

## Aufgabe 6: UPDATE und DELETE

### 6.1 Preis erhöhen (Electronics +10%)

```sql
UPDATE products
SET price = price * 1.10
WHERE category_id = (SELECT id FROM categories WHERE name = 'Electronics')
RETURNING name, price;
```

**Ergebnis:**
```
     name      |  price
---------------+---------
 Laptop Pro 15 | 1429.99
 Wireless Mouse|   54.99
 USB-C Hub     |   87.99
 Smartphone X  |  988.90
```

### 6.2 Stock auffüllen

```sql
UPDATE products
SET stock = 10
WHERE stock = 0
RETURNING name, stock;
```

### 6.3 Produkt umbenennen

```sql
UPDATE products
SET name = 'Laptop Pro 15 (2024 Edition)'
WHERE name = 'Laptop Pro 15'
RETURNING *;
```

### 6.4 Produkt löschen

```sql
-- Mystery Box löschen
DELETE FROM products
WHERE name = 'Mystery Box'
RETURNING *;
```

---

## Aufgabe 7: Views (Bonus)

### 7.1 Produktübersicht View

```sql
CREATE VIEW product_overview AS
SELECT
    p.id,
    p.name AS product_name,
    p.price,
    p.stock,
    COALESCE(c.name, 'Keine Kategorie') AS category_name,
    p.price * p.stock AS total_value,
    CASE
        WHEN p.stock = 0 THEN 'Ausverkauft'
        WHEN p.stock < 10 THEN 'Wenig auf Lager'
        ELSE 'Auf Lager'
    END AS stock_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;
```

### 7.2 View verwenden

```sql
-- Alle Produkte
SELECT * FROM product_overview;

-- Nur Electronics
SELECT * FROM product_overview
WHERE category_name = 'Electronics'
ORDER BY price DESC;

-- Ausverkaufte Produkte
SELECT product_name, price
FROM product_overview
WHERE stock_status = 'Ausverkauft';
```

### 7.3 Low Stock View

```sql
CREATE VIEW low_stock_products AS
SELECT
    p.name,
    p.stock,
    c.name AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.stock < 5
ORDER BY p.stock ASC;

-- Verwenden
SELECT * FROM low_stock_products;
```

---

## Aufgabe 8: Indizes (Bonus)

```sql
-- Index auf Produktname (für Suche)
CREATE INDEX idx_products_name ON products(name);

-- Index auf Foreign Key (für JOINs)
CREATE INDEX idx_products_category ON products(category_id);

-- Zusammengesetzter Index (für Filter + Sort)
CREATE INDEX idx_products_category_price ON products(category_id, price);

-- Index auf Email (für Login)
CREATE INDEX idx_customers_email ON customers(email);

-- Indizes anzeigen
SELECT
    indexname,
    tablename,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
```

---

## Vollständiges Setup-Skript

```sql
-- shop_setup.sql
-- Vollständiges Setup für die Shop-Datenbank

-- Alte Tabellen löschen (falls vorhanden)
DROP VIEW IF EXISTS product_overview CASCADE;
DROP VIEW IF EXISTS low_stock_products CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- ==========================================
-- Tabellen erstellen
-- ==========================================

CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================
-- Indizes erstellen
-- ==========================================

CREATE INDEX idx_products_name ON products(name);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_category_price ON products(category_id, price);
CREATE INDEX idx_customers_email ON customers(email);

-- ==========================================
-- Daten einfügen
-- ==========================================

INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Fashion and apparel'),
    ('Books', 'Books and magazines'),
    ('Home & Garden', 'Home improvement and gardening');

INSERT INTO products (name, description, price, stock, category_id) VALUES
    ('Laptop Pro 15', 'High-end laptop with 16GB RAM', 1299.99, 25, 1),
    ('Wireless Mouse', 'Ergonomic wireless mouse', 49.99, 100, 1),
    ('USB-C Hub', '7-in-1 USB-C hub', 79.99, 50, 1),
    ('Smartphone X', 'Latest smartphone with 5G', 899.00, 30, 1),
    ('T-Shirt Basic', '100% cotton t-shirt', 19.99, 200, 2),
    ('Jeans Classic', 'Blue denim jeans', 59.99, 75, 2),
    ('Winter Jacket', 'Warm winter jacket', 149.99, 20, 2),
    ('Clean Code', 'Programming best practices', 39.99, 45, 3),
    ('Flutter Complete', 'Learn Flutter development', 49.99, 30, 3),
    ('Garden Tools Set', 'Complete garden tool set', 89.99, 15, 4),
    ('LED Lamp', 'Energy-efficient LED lamp', 29.99, 60, 4),
    ('Mystery Box', 'Surprise item', 9.99, 0, NULL);

INSERT INTO customers (name, email) VALUES
    ('Max Müller', 'max@example.com'),
    ('Anna Schmidt', 'anna@example.com'),
    ('Tom Weber', 'tom@example.com'),
    ('Lisa Fischer', 'lisa@example.com'),
    ('Jan Becker', 'jan@example.com');

-- ==========================================
-- Views erstellen
-- ==========================================

CREATE VIEW product_overview AS
SELECT
    p.id,
    p.name AS product_name,
    p.price,
    p.stock,
    COALESCE(c.name, 'Keine Kategorie') AS category_name,
    p.price * p.stock AS total_value,
    CASE
        WHEN p.stock = 0 THEN 'Ausverkauft'
        WHEN p.stock < 10 THEN 'Wenig auf Lager'
        ELSE 'Auf Lager'
    END AS stock_status
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;

CREATE VIEW low_stock_products AS
SELECT
    p.name,
    p.stock,
    c.name AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id
WHERE p.stock < 5
ORDER BY p.stock ASC;

-- ==========================================
-- Überprüfung
-- ==========================================

SELECT 'Kategorien:' AS info, COUNT(*) AS count FROM categories
UNION ALL
SELECT 'Produkte:', COUNT(*) FROM products
UNION ALL
SELECT 'Kunden:', COUNT(*) FROM customers;
```

### Ausführen

```bash
psql -d shop_db -f shop_setup.sql
```
