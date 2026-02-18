# Ressourcen: SQL-Grundlagen

## Offizielle Dokumentation

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [PostgreSQL Tutorial](https://www.postgresqltutorial.com/)
- [SQLite Documentation](https://www.sqlite.org/docs.html)
- [MySQL Documentation](https://dev.mysql.com/doc/)

## Online-Tools

- [SQLite Online](https://sqliteonline.com/)
- [DB Fiddle](https://www.db-fiddle.com/)
- [SQL Fiddle](http://sqlfiddle.com/)
- [Explain PostgreSQL](https://explain.depesz.com/) - Query-Analyse

## Cheat Sheet: Datentypen

| SQL-Typ | PostgreSQL | Beschreibung |
|---------|------------|--------------|
| `INTEGER` | `INT4` | 4-Byte Integer |
| `BIGINT` | `INT8` | 8-Byte Integer |
| `SERIAL` | `INT4` + Sequence | Auto-Increment |
| `DECIMAL(p,s)` | `NUMERIC` | Präzise Dezimalzahl |
| `REAL` | `FLOAT4` | 4-Byte Float |
| `VARCHAR(n)` | - | Variable Länge bis n |
| `TEXT` | - | Unbegrenzte Länge |
| `BOOLEAN` | `BOOL` | true/false |
| `DATE` | - | Datum (YYYY-MM-DD) |
| `TIMESTAMP` | - | Datum + Zeit |
| `UUID` | - | 128-bit UUID |

## Cheat Sheet: CREATE TABLE

```sql
CREATE TABLE table_name (
    -- Auto-increment ID
    id SERIAL PRIMARY KEY,

    -- Pflichtfeld
    name VARCHAR(100) NOT NULL,

    -- Eindeutig
    email VARCHAR(255) UNIQUE NOT NULL,

    -- Mit Check
    price DECIMAL(10,2) CHECK (price > 0),

    -- Mit Default
    stock INTEGER DEFAULT 0,

    -- Nullable
    description TEXT,

    -- Foreign Key
    category_id INTEGER REFERENCES categories(id),

    -- Timestamp
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Cheat Sheet: INSERT

```sql
-- Einzeln
INSERT INTO users (name, email)
VALUES ('Max', 'max@example.com');

-- Mehrere
INSERT INTO users (name, email) VALUES
    ('Max', 'max@example.com'),
    ('Anna', 'anna@example.com');

-- Mit Rückgabe
INSERT INTO users (name, email)
VALUES ('Max', 'max@example.com')
RETURNING id;

-- Aus anderer Tabelle
INSERT INTO archive (name, email)
SELECT name, email FROM users WHERE active = false;
```

## Cheat Sheet: SELECT

```sql
-- Grundform
SELECT spalten FROM tabelle WHERE bedingung;

-- Alle Spalten
SELECT * FROM users;

-- Mit Alias
SELECT name AS username FROM users;

-- Distinct
SELECT DISTINCT category FROM products;

-- Limit und Offset
SELECT * FROM products LIMIT 10 OFFSET 20;

-- Sortierung
SELECT * FROM products ORDER BY price DESC;

-- Gruppierung
SELECT category, COUNT(*) FROM products GROUP BY category;
```

## Cheat Sheet: WHERE-Klauseln

```sql
-- Vergleich
WHERE price > 100
WHERE price BETWEEN 50 AND 200
WHERE price IN (10, 20, 30)

-- Text
WHERE name = 'Max'
WHERE name LIKE 'M%'        -- beginnt mit M
WHERE name LIKE '%a'        -- endet mit a
WHERE name LIKE '%ax%'      -- enthält ax
WHERE name ILIKE '%max%'    -- case-insensitive

-- NULL
WHERE description IS NULL
WHERE description IS NOT NULL

-- Logik
WHERE price > 100 AND stock > 0
WHERE category = 'A' OR category = 'B'
WHERE NOT active
```

## Cheat Sheet: JOIN

```sql
-- INNER JOIN (nur Übereinstimmungen)
SELECT p.name, c.name
FROM products p
INNER JOIN categories c ON p.category_id = c.id;

-- LEFT JOIN (alle links + Übereinstimmungen)
SELECT p.name, c.name
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;

-- Mehrere JOINs
SELECT o.id, u.name, p.name
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN products p ON o.product_id = p.id;
```

## Cheat Sheet: Aggregatfunktionen

```sql
COUNT(*)        -- Anzahl Zeilen
COUNT(column)   -- Anzahl nicht-NULL Werte
SUM(column)     -- Summe
AVG(column)     -- Durchschnitt
MIN(column)     -- Minimum
MAX(column)     -- Maximum

-- Beispiel
SELECT
    category,
    COUNT(*) AS total,
    AVG(price) AS avg_price,
    SUM(stock) AS total_stock
FROM products
GROUP BY category
HAVING COUNT(*) > 5;
```

## Cheat Sheet: UPDATE

```sql
-- Einzelnes Feld
UPDATE users SET email = 'new@example.com' WHERE id = 1;

-- Mehrere Felder
UPDATE products
SET price = price * 1.1, updated_at = NOW()
WHERE category = 'electronics';

-- Mit Subquery
UPDATE products
SET category_id = (SELECT id FROM categories WHERE name = 'New')
WHERE category_id IS NULL;

-- Mit RETURNING
UPDATE users SET name = 'Max' WHERE id = 1 RETURNING *;
```

## Cheat Sheet: DELETE

```sql
-- Mit Bedingung
DELETE FROM users WHERE id = 1;

-- Alle löschen
DELETE FROM users;

-- Schneller alle löschen
TRUNCATE TABLE users;

-- Mit RETURNING
DELETE FROM users WHERE id = 1 RETURNING *;
```

## Cheat Sheet: ALTER TABLE

```sql
-- Spalte hinzufügen
ALTER TABLE users ADD COLUMN phone VARCHAR(20);

-- Spalte ändern
ALTER TABLE users ALTER COLUMN name TYPE VARCHAR(200);

-- Spalte löschen
ALTER TABLE users DROP COLUMN phone;

-- NOT NULL setzen
ALTER TABLE users ALTER COLUMN email SET NOT NULL;

-- Default setzen
ALTER TABLE users ALTER COLUMN active SET DEFAULT true;

-- Constraint hinzufügen
ALTER TABLE products ADD CONSTRAINT price_positive CHECK (price > 0);

-- Foreign Key hinzufügen
ALTER TABLE products ADD CONSTRAINT fk_category
    FOREIGN KEY (category_id) REFERENCES categories(id);
```

## Cheat Sheet: Indizes

```sql
-- Einfacher Index
CREATE INDEX idx_name ON table(column);

-- Unique Index
CREATE UNIQUE INDEX idx_email ON users(email);

-- Zusammengesetzter Index
CREATE INDEX idx_cat_price ON products(category_id, price);

-- Index löschen
DROP INDEX idx_name;

-- Indizes anzeigen (PostgreSQL)
SELECT indexname, tablename FROM pg_indexes WHERE schemaname = 'public';
```

## Cheat Sheet: Views

```sql
-- View erstellen
CREATE VIEW active_users AS
SELECT id, name, email FROM users WHERE active = true;

-- View verwenden
SELECT * FROM active_users;

-- View ersetzen
CREATE OR REPLACE VIEW active_users AS ...;

-- View löschen
DROP VIEW active_users;
```

## PostgreSQL CLI (psql)

```bash
# Verbinden
psql -d database_name

# Als User
psql -U username -d database_name

# Remote
psql -h hostname -U username -d database_name
```

### psql-Befehle

| Befehl | Beschreibung |
|--------|--------------|
| `\l` | Datenbanken auflisten |
| `\c dbname` | Zu Datenbank verbinden |
| `\dt` | Tabellen auflisten |
| `\d table` | Tabellenstruktur |
| `\di` | Indizes auflisten |
| `\dv` | Views auflisten |
| `\du` | Benutzer auflisten |
| `\q` | Beenden |
| `\i file.sql` | SQL-Datei ausführen |
| `\timing` | Query-Zeiten anzeigen |

## Docker PostgreSQL

```bash
# Container starten
docker run --name postgres \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=mydb \
  -p 5432:5432 \
  -d postgres:16

# Verbinden
docker exec -it postgres psql -U postgres -d mydb

# Logs
docker logs postgres

# Stoppen
docker stop postgres

# Löschen
docker rm postgres
```

## Best Practices

1. **Immer Primary Key verwenden**
2. **Foreign Keys definieren**
3. **Indizes für häufige Queries**
4. **snake_case für Namen**
5. **Plural für Tabellennamen**
6. **NOT NULL wo möglich**
7. **Transaktionen für zusammengehörige Änderungen**
8. **EXPLAIN für Performance-Analyse**

## Transaktionen

```sql
BEGIN;
    UPDATE accounts SET balance = balance - 100 WHERE id = 1;
    UPDATE accounts SET balance = balance + 100 WHERE id = 2;
COMMIT;

-- Bei Fehler
ROLLBACK;
```
