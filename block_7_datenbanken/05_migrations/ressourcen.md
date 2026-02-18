# Ressourcen: Database Migrations

## Konzepte

- [Database Migrations](https://en.wikipedia.org/wiki/Schema_migration)
- [Flyway](https://flywaydb.org/) - Migration Tool Konzepte
- [Liquibase](https://www.liquibase.org/) - Alternative

## Cheat Sheet: Migration-Struktur

```
migrations/
├── 001_create_users.up.sql
├── 001_create_users.down.sql
├── 002_create_products.up.sql
├── 002_create_products.down.sql
└── ...
```

## Cheat Sheet: Migrations-Tabelle

```sql
CREATE TABLE migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Cheat Sheet: ALTER TABLE

```sql
-- Spalte hinzufügen
ALTER TABLE products ADD COLUMN rating DECIMAL(2,1);

-- Spalte ändern
ALTER TABLE products ALTER COLUMN price TYPE DECIMAL(12,2);

-- Spalte löschen
ALTER TABLE products DROP COLUMN rating;

-- Spalte umbenennen
ALTER TABLE products RENAME COLUMN price TO unit_price;

-- Tabelle umbenennen
ALTER TABLE products RENAME TO items;

-- Constraint hinzufügen
ALTER TABLE products ADD CONSTRAINT chk_price CHECK (price > 0);

-- Constraint entfernen
ALTER TABLE products DROP CONSTRAINT chk_price;

-- NOT NULL hinzufügen
ALTER TABLE products ALTER COLUMN name SET NOT NULL;

-- NOT NULL entfernen
ALTER TABLE products ALTER COLUMN name DROP NOT NULL;

-- Default setzen
ALTER TABLE products ALTER COLUMN stock SET DEFAULT 0;

-- Default entfernen
ALTER TABLE products ALTER COLUMN stock DROP DEFAULT;
```

## Cheat Sheet: Index-Operationen

```sql
-- Index erstellen
CREATE INDEX idx_products_category ON products(category_id);

-- Unique Index
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- Index löschen
DROP INDEX IF EXISTS idx_products_category;
```

## Best Practices

1. **Niemals Migrations ändern** - Neue Migration erstellen
2. **Transaktionen verwenden** - BEGIN/COMMIT
3. **Aussagekräftige Namen** - `003_add_email_to_users`
4. **Down-Migration testen** - Rollback sollte funktionieren
5. **Kleine Schritte** - Eine Änderung pro Migration
6. **Daten-Migrations vorsichtig** - Können irreversibel sein

## Namenskonvention

```
NNN_action_target.up.sql
NNN_action_target.down.sql

Beispiele:
001_create_users.up.sql
002_create_products.up.sql
003_add_rating_to_products.up.sql
004_rename_price_to_unit_price.up.sql
005_add_index_on_email.up.sql
```
