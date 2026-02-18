# Übung 7.1: SQL-Grundlagen

## Ziel

Übe die grundlegenden SQL-Befehle mit einer kleinen Produktdatenbank.

---

## Vorbereitung

### Option A: PostgreSQL lokal

```bash
# PostgreSQL installieren (Arch Linux)
sudo pacman -S postgresql

# Datenbank initialisieren
sudo -u postgres initdb -D /var/lib/postgres/data

# Service starten
sudo systemctl start postgresql

# Benutzer und Datenbank erstellen
sudo -u postgres createuser -s $USER
createdb shop_db
```

### Option B: Docker

```bash
# PostgreSQL Container starten
docker run --name postgres-shop \
  -e POSTGRES_PASSWORD=secret \
  -e POSTGRES_DB=shop_db \
  -p 5432:5432 \
  -d postgres:16

# Verbinden
docker exec -it postgres-shop psql -U postgres -d shop_db
```

### Option C: Online SQL Editor

- [SQLite Online](https://sqliteonline.com/)
- [DB Fiddle](https://www.db-fiddle.com/) (PostgreSQL wählen)

---

## Aufgabe 1: Tabellen erstellen (15 min)

Erstelle die folgenden Tabellen für einen Online-Shop.

### categories

| Spalte | Typ | Constraints |
|--------|-----|-------------|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR(50) | NOT NULL, UNIQUE |
| description | TEXT | - |

### products

| Spalte | Typ | Constraints |
|--------|-----|-------------|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR(100) | NOT NULL |
| description | TEXT | - |
| price | DECIMAL(10,2) | NOT NULL, CHECK > 0 |
| stock | INTEGER | NOT NULL, DEFAULT 0, CHECK >= 0 |
| category_id | INTEGER | REFERENCES categories(id) |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

### customers

| Spalte | Typ | Constraints |
|--------|-----|-------------|
| id | SERIAL | PRIMARY KEY |
| name | VARCHAR(100) | NOT NULL |
| email | VARCHAR(255) | NOT NULL, UNIQUE |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP |

---

## Aufgabe 2: Daten einfügen (10 min)

### Kategorien einfügen

Füge mindestens 4 Kategorien ein:
- Electronics
- Clothing
- Books
- Home & Garden

### Produkte einfügen

Füge mindestens 10 Produkte ein, verteilt auf die Kategorien:

```sql
-- Beispiel
INSERT INTO products (name, description, price, stock, category_id)
VALUES ('Laptop Pro 15', 'High-end laptop with 16GB RAM', 1299.99, 25, 1);
```

Achte auf:
- Verschiedene Preisklassen (10€ - 2000€)
- Verschiedene Lagerbestände (0 - 100)
- Mindestens ein Produkt ohne Kategorie (NULL)

### Kunden einfügen

Füge 5 Kunden ein.

---

## Aufgabe 3: Einfache Abfragen (10 min)

Schreibe SQL-Queries für:

1. **Alle Produkte anzeigen**
   - Sortiert nach Name

2. **Produkte über 100€**
   - Nur Name und Preis anzeigen

3. **Produkte auf Lager**
   - Nur Produkte mit stock > 0

4. **Günstigstes und teuerstes Produkt**
   - Verwende MIN/MAX

5. **Anzahl Produkte pro Kategorie**
   - Mit GROUP BY

---

## Aufgabe 4: Komplexere Abfragen (15 min)

### 4.1 Filter kombinieren

Finde alle Produkte die:
- Zur Kategorie "Electronics" gehören
- Mehr als 50€ kosten
- Auf Lager sind (stock > 0)

### 4.2 Textsuche

Finde alle Produkte deren Name oder Beschreibung "Pro" enthält.

### 4.3 Preisbereiche

Kategorisiere Produkte nach Preis:
- Günstig: < 50€
- Mittel: 50€ - 200€
- Premium: > 200€

Hint: Verwende CASE WHEN

```sql
SELECT
    name,
    price,
    CASE
        WHEN price < 50 THEN 'Günstig'
        WHEN price <= 200 THEN 'Mittel'
        ELSE 'Premium'
    END AS price_category
FROM products;
```

### 4.4 Top 5 teuerste Produkte

Mit Kategoriename (JOIN erforderlich).

---

## Aufgabe 5: JOINs (15 min)

### 5.1 Produkte mit Kategorienamen

Zeige alle Produkte mit ihrem Kategorienamen an.
Produkte ohne Kategorie sollen auch erscheinen (LEFT JOIN).

### 5.2 Kategorien mit Produktanzahl

Zeige für jede Kategorie:
- Kategoriename
- Anzahl Produkte
- Durchschnittspreis
- Gesamtwert (Summe: price * stock)

### 5.3 Leere Kategorien finden

Finde Kategorien, die keine Produkte haben.

Hint: LEFT JOIN + WHERE ... IS NULL

---

## Aufgabe 6: UPDATE und DELETE (10 min)

### 6.1 Preis erhöhen

Erhöhe den Preis aller Electronics-Produkte um 10%.

```sql
UPDATE products
SET price = price * 1.10
WHERE category_id = (SELECT id FROM categories WHERE name = 'Electronics');
```

### 6.2 Stock auffüllen

Setze den Stock aller Produkte mit Stock = 0 auf 10.

### 6.3 Produkt umbenennen

Ändere den Namen eines Produkts deiner Wahl.

### 6.4 Produkt löschen

Lösche ein Produkt (aber behalte die Query als Kommentar).

---

## Aufgabe 7: Views erstellen (Bonus, 10 min)

### 7.1 Produktübersicht View

Erstelle eine View `product_overview`:

```sql
CREATE VIEW product_overview AS
SELECT
    p.id,
    p.name AS product_name,
    p.price,
    p.stock,
    c.name AS category_name,
    p.price * p.stock AS total_value
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;
```

### 7.2 View verwenden

```sql
-- View abfragen
SELECT * FROM product_overview;

-- Filtern
SELECT * FROM product_overview
WHERE category_name = 'Electronics';
```

### 7.3 Low Stock View

Erstelle eine View `low_stock_products` für Produkte mit stock < 5.

---

## Aufgabe 8: Indizes (Bonus, 5 min)

### 8.1 Index erstellen

```sql
-- Index auf häufig gesuchte Spalte
CREATE INDEX idx_products_name ON products(name);

-- Index auf Foreign Key
CREATE INDEX idx_products_category ON products(category_id);

-- Zusammengesetzter Index
CREATE INDEX idx_products_category_price ON products(category_id, price);
```

### 8.2 Indizes anzeigen

```sql
-- PostgreSQL
SELECT indexname, tablename
FROM pg_indexes
WHERE schemaname = 'public';
```

---

## Testen

```sql
-- Tabellen auflisten
\dt

-- Tabellenstruktur anzeigen
\d products

-- Alle Produkte
SELECT * FROM products;

-- Produkte mit Kategorie
SELECT p.name, c.name AS category
FROM products p
LEFT JOIN categories c ON p.category_id = c.id;
```

---

## Abgabe-Checkliste

- [ ] 3 Tabellen erstellt (categories, products, customers)
- [ ] Mindestens 4 Kategorien eingefügt
- [ ] Mindestens 10 Produkte eingefügt
- [ ] 5 Kunden eingefügt
- [ ] Alle einfachen Abfragen (Aufgabe 3) funktionieren
- [ ] Komplexere Abfragen mit CASE WHEN
- [ ] JOINs funktionieren
- [ ] UPDATE und DELETE getestet
- [ ] (Bonus) Views erstellt
- [ ] (Bonus) Indizes erstellt

---

## SQL-Datei speichern

Speichere alle deine SQL-Befehle in einer Datei `shop_setup.sql`:

```sql
-- shop_setup.sql

-- Tabellen erstellen
CREATE TABLE categories (...);
CREATE TABLE products (...);
CREATE TABLE customers (...);

-- Daten einfügen
INSERT INTO categories ...
INSERT INTO products ...
INSERT INTO customers ...

-- Abfragen
SELECT ...
```

So kannst du die Datenbank jederzeit neu aufsetzen:

```bash
psql -d shop_db -f shop_setup.sql
```
