# Einheit 7.1: SQL-Grundlagen

## Lernziele

Nach dieser Einheit kannst du:
- Die Grundlagen relationaler Datenbanken verstehen
- SQL-Syntax für CRUD-Operationen anwenden
- Tabellen erstellen und verknüpfen
- Einfache Abfragen mit WHERE, ORDER BY und LIMIT schreiben

---

## Relationale Datenbanken

### Was ist eine relationale Datenbank?

Eine **relationale Datenbank** speichert Daten in **Tabellen** (Relations), die aus **Zeilen** (Datensätze) und **Spalten** (Attribute) bestehen.

```
┌─────────────────────────────────────────────┐
│                   users                      │
├─────┬──────────────┬────────────────────────┤
│ id  │ name         │ email                  │
├─────┼──────────────┼────────────────────────┤
│ 1   │ Max Müller   │ max@example.com        │
│ 2   │ Anna Schmidt │ anna@example.com       │
│ 3   │ Tom Weber    │ tom@example.com        │
└─────┴──────────────┴────────────────────────┘
```

### Wichtige Begriffe

| Begriff | Beschreibung |
|---------|--------------|
| **Tabelle** | Sammlung von zusammengehörigen Daten |
| **Zeile (Row)** | Ein einzelner Datensatz |
| **Spalte (Column)** | Ein Attribut/Feld |
| **Primary Key** | Eindeutiger Identifikator für jede Zeile |
| **Foreign Key** | Verweis auf Primary Key einer anderen Tabelle |
| **Schema** | Struktur der Datenbank (Tabellen, Spalten, Typen) |

### Populäre relationale Datenbanken

| Datenbank | Eigenschaften |
|-----------|---------------|
| **PostgreSQL** | Open Source, feature-reich, sehr stabil |
| **MySQL/MariaDB** | Weit verbreitet, performant |
| **SQLite** | Eingebettet, dateibasiert, kein Server nötig |
| **SQL Server** | Microsoft, Enterprise-Fokus |

---

## SQL Syntax Grundlagen

**SQL** (Structured Query Language) ist die Standardsprache für relationale Datenbanken.

### Datentypen

| SQL-Typ | Beschreibung | Beispiel |
|---------|--------------|----------|
| `INTEGER` | Ganzzahlen | `42` |
| `BIGINT` | Große Ganzzahlen | `9223372036854775807` |
| `DECIMAL(p,s)` | Präzise Dezimalzahlen | `DECIMAL(10,2)` für Geld |
| `REAL/FLOAT` | Fließkommazahlen | `3.14159` |
| `VARCHAR(n)` | Text mit max. Länge | `VARCHAR(255)` |
| `TEXT` | Text unbegrenzt | Lange Beschreibungen |
| `BOOLEAN` | Wahrheitswert | `TRUE`, `FALSE` |
| `DATE` | Datum | `'2024-01-15'` |
| `TIMESTAMP` | Datum + Zeit | `'2024-01-15 10:30:00'` |
| `UUID` | Universally Unique ID | `'550e8400-e29b-...'` |

---

## Tabellen erstellen (CREATE)

### Einfache Tabelle

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Mit Constraints

```sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Constraint-Typen

| Constraint | Beschreibung |
|------------|--------------|
| `PRIMARY KEY` | Eindeutiger Identifikator |
| `NOT NULL` | Wert muss vorhanden sein |
| `UNIQUE` | Wert muss einzigartig sein |
| `CHECK` | Bedingung muss erfüllt sein |
| `DEFAULT` | Standardwert wenn nicht angegeben |
| `REFERENCES` | Foreign Key zu anderer Tabelle |

---

## Daten einfügen (INSERT)

### Einzelner Datensatz

```sql
INSERT INTO users (name, email)
VALUES ('Max Müller', 'max@example.com');
```

### Mehrere Datensätze

```sql
INSERT INTO users (name, email)
VALUES
    ('Anna Schmidt', 'anna@example.com'),
    ('Tom Weber', 'tom@example.com'),
    ('Lisa Fischer', 'lisa@example.com');
```

### Mit Rückgabe der ID

```sql
INSERT INTO users (name, email)
VALUES ('Max Müller', 'max@example.com')
RETURNING id;

-- Oder alle Felder
INSERT INTO users (name, email)
VALUES ('Max Müller', 'max@example.com')
RETURNING *;
```

---

## Daten abfragen (SELECT)

### Alle Spalten

```sql
SELECT * FROM users;
```

### Bestimmte Spalten

```sql
SELECT name, email FROM users;
```

### Mit Alias

```sql
SELECT
    name AS username,
    email AS mail_address
FROM users;
```

### Mit Bedingungen (WHERE)

```sql
-- Exakter Vergleich
SELECT * FROM users WHERE id = 1;

-- Textvergleich
SELECT * FROM users WHERE name = 'Max Müller';

-- Größer/Kleiner
SELECT * FROM products WHERE price > 100;
SELECT * FROM products WHERE price BETWEEN 50 AND 150;

-- IN (Liste von Werten)
SELECT * FROM products WHERE category IN ('electronics', 'books');

-- LIKE (Textmuster)
SELECT * FROM users WHERE email LIKE '%@example.com';
SELECT * FROM users WHERE name LIKE 'Max%';  -- Beginnt mit Max

-- NULL-Prüfung
SELECT * FROM products WHERE description IS NULL;
SELECT * FROM products WHERE description IS NOT NULL;

-- Logische Operatoren
SELECT * FROM products
WHERE price > 100 AND stock > 0;

SELECT * FROM users
WHERE name = 'Max' OR name = 'Anna';
```

---

## Sortierung und Limits

### ORDER BY

```sql
-- Aufsteigend (Standard)
SELECT * FROM products ORDER BY price ASC;

-- Absteigend
SELECT * FROM products ORDER BY price DESC;

-- Mehrere Spalten
SELECT * FROM products
ORDER BY category ASC, price DESC;

-- NULL-Handling
SELECT * FROM products
ORDER BY description NULLS LAST;
```

### LIMIT und OFFSET

```sql
-- Erste 10 Datensätze
SELECT * FROM products LIMIT 10;

-- Seite 2 (Datensätze 11-20)
SELECT * FROM products LIMIT 10 OFFSET 10;

-- Top 5 teuerste Produkte
SELECT * FROM products
ORDER BY price DESC
LIMIT 5;
```

---

## Daten aktualisieren (UPDATE)

### Einzelnes Feld

```sql
UPDATE users
SET email = 'newemail@example.com'
WHERE id = 1;
```

### Mehrere Felder

```sql
UPDATE products
SET
    price = 29.99,
    stock = stock + 10,
    updated_at = CURRENT_TIMESTAMP
WHERE id = 42;
```

### Mit Bedingung

```sql
-- Alle Produkte in Kategorie um 10% reduzieren
UPDATE products
SET price = price * 0.9
WHERE category = 'electronics';
```

### Mit RETURNING

```sql
UPDATE users
SET name = 'Max Mustermann'
WHERE id = 1
RETURNING *;
```

---

## Daten löschen (DELETE)

### Einzelner Datensatz

```sql
DELETE FROM users WHERE id = 1;
```

### Mit Bedingung

```sql
-- Alle inaktiven User löschen
DELETE FROM users
WHERE last_login < '2023-01-01';
```

### Alle Datensätze (Vorsicht!)

```sql
DELETE FROM users;  -- Löscht ALLE Zeilen

-- Schneller für große Tabellen:
TRUNCATE TABLE users;
```

### Mit RETURNING

```sql
DELETE FROM users
WHERE id = 1
RETURNING *;
```

---

## Aggregatfunktionen

```sql
-- Anzahl
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM products WHERE stock > 0;

-- Summe
SELECT SUM(price) FROM products;

-- Durchschnitt
SELECT AVG(price) FROM products;

-- Minimum/Maximum
SELECT MIN(price), MAX(price) FROM products;

-- Kombiniert
SELECT
    COUNT(*) AS total_products,
    SUM(price * stock) AS total_value,
    AVG(price) AS avg_price,
    MIN(price) AS cheapest,
    MAX(price) AS most_expensive
FROM products;
```

---

## Gruppierung (GROUP BY)

```sql
-- Anzahl Produkte pro Kategorie
SELECT category, COUNT(*) AS count
FROM products
GROUP BY category;

-- Durchschnittspreis pro Kategorie
SELECT category, AVG(price) AS avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;

-- Mit HAVING (Filter für Gruppen)
SELECT category, COUNT(*) AS count
FROM products
GROUP BY category
HAVING COUNT(*) > 5;
```

---

## Einfache JOINs

### Tabellen verknüpfen

```sql
-- Kategorien-Tabelle
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);

-- Produkte mit category_id (Foreign Key)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES categories(id)
);
```

### INNER JOIN

```sql
-- Produkte mit Kategorienamen
SELECT
    p.id,
    p.name AS product_name,
    c.name AS category_name
FROM products p
INNER JOIN categories c ON p.category_id = c.id;
```

### LEFT JOIN

```sql
-- Alle Produkte, auch ohne Kategorie
SELECT
    p.id,
    p.name AS product_name,
    c.name AS category_name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;
```

### JOIN-Typen Übersicht

| JOIN-Typ | Beschreibung |
|----------|--------------|
| `INNER JOIN` | Nur übereinstimmende Zeilen |
| `LEFT JOIN` | Alle linken + übereinstimmende rechte |
| `RIGHT JOIN` | Alle rechten + übereinstimmende linke |
| `FULL JOIN` | Alle Zeilen aus beiden Tabellen |

---

## Tabellen ändern (ALTER)

### Spalte hinzufügen

```sql
ALTER TABLE users
ADD COLUMN phone VARCHAR(20);
```

### Spalte ändern

```sql
ALTER TABLE users
ALTER COLUMN name TYPE VARCHAR(200);
```

### Spalte löschen

```sql
ALTER TABLE users
DROP COLUMN phone;
```

### Constraint hinzufügen

```sql
ALTER TABLE products
ADD CONSTRAINT positive_price CHECK (price > 0);
```

---

## Tabelle löschen (DROP)

```sql
-- Tabelle löschen (Fehler wenn nicht existiert)
DROP TABLE users;

-- Sicher löschen
DROP TABLE IF EXISTS users;

-- Mit abhängigen Objekten
DROP TABLE users CASCADE;
```

---

## Best Practices

### 1. Namenskonventionen

```sql
-- Tabellen: snake_case, Plural
CREATE TABLE user_profiles (...);
CREATE TABLE order_items (...);

-- Spalten: snake_case
CREATE TABLE users (
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    created_at TIMESTAMP
);
```

### 2. Immer Primary Keys verwenden

```sql
-- Mit SERIAL (auto-increment)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    ...
);

-- Mit UUID
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ...
);
```

### 3. Foreign Keys definieren

```sql
-- Explizite Referenz
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    ...
);
```

### 4. Indizes für häufige Abfragen

```sql
-- Index auf häufig gesuchte Spalte
CREATE INDEX idx_users_email ON users(email);

-- Zusammengesetzter Index
CREATE INDEX idx_products_category_price
ON products(category, price);
```

---

## Zusammenfassung

| Operation | SQL-Befehl |
|-----------|------------|
| Tabelle erstellen | `CREATE TABLE` |
| Daten einfügen | `INSERT INTO ... VALUES` |
| Daten abfragen | `SELECT ... FROM ... WHERE` |
| Daten aktualisieren | `UPDATE ... SET ... WHERE` |
| Daten löschen | `DELETE FROM ... WHERE` |
| Tabelle ändern | `ALTER TABLE` |
| Tabelle löschen | `DROP TABLE` |

---

## Nächste Schritte

In der nächsten Einheit lernst du, wie du **PostgreSQL mit Dart** verwendest: Verbindung herstellen, Queries ausführen und Ergebnisse verarbeiten.
