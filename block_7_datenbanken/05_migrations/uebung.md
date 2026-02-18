# Übung 7.5: Database Migrations

## Ziel

Implementiere ein vollständiges Migrations-System für einen Online-Shop.

---

## Aufgabe 1: Migrations-Ordner erstellen (5 min)

```bash
mkdir -p migrations
```

Struktur:
```
project/
├── bin/
│   └── migrate.dart
├── lib/
│   └── migration_runner.dart
└── migrations/
    ├── 001_create_users.up.sql
    ├── 001_create_users.down.sql
    └── ...
```

---

## Aufgabe 2: Basis-Migrations erstellen (20 min)

### 001_create_users

```sql
-- migrations/001_create_users.up.sql
-- TODO: users Tabelle mit id, email, password_hash, name, created_at

-- migrations/001_create_users.down.sql
-- TODO: DROP TABLE
```

### 002_create_categories

```sql
-- TODO: categories mit id, name, parent_id (Hierarchie)
```

### 003_create_products

```sql
-- TODO: products mit id, name, description, price, stock, category_id, created_at
-- TODO: Index auf category_id
```

### 004_create_orders

```sql
-- TODO: orders mit id, user_id, status, total, created_at
-- TODO: order_items mit id, order_id, product_id, quantity, unit_price
```

---

## Aufgabe 3: Migration Runner implementieren (25 min)

```dart
// lib/migration_runner.dart

class MigrationRunner {
  final Pool _pool;
  final String _migrationsPath;

  MigrationRunner(this._pool, this._migrationsPath);

  /// Erstellt migrations-Tabelle
  Future<void> init() async {
    // TODO
  }

  /// Gibt alle angewandten Migrations zurück
  Future<List<String>> getApplied() async {
    // TODO
  }

  /// Gibt alle ausstehenden Migrations zurück
  Future<List<String>> getPending() async {
    // TODO: Dateien lesen und mit applied vergleichen
  }

  /// Führt alle ausstehenden Migrations aus
  Future<void> migrate() async {
    // TODO
  }

  /// Rollback der letzten n Migrations
  Future<void> rollback([int steps = 1]) async {
    // TODO
  }

  /// Status ausgeben
  Future<void> status() async {
    // TODO: Applied und Pending anzeigen
  }
}
```

---

## Aufgabe 4: CLI-Tool erstellen (15 min)

```dart
// bin/migrate.dart

Future<void> main(List<String> args) async {
  // TODO: Pool erstellen
  // TODO: MigrationRunner erstellen

  try {
    switch (args.firstOrNull) {
      case 'up':
      case null:
        // TODO: migrate()
        break;
      case 'down':
        // TODO: rollback mit optionalem steps-Argument
        break;
      case 'status':
        // TODO: status()
        break;
      default:
        print('Usage: dart run bin/migrate.dart [up|down|status]');
    }
  } finally {
    // TODO: Pool schließen
  }
}
```

---

## Aufgabe 5: Änderungs-Migrations (15 min)

Erstelle Migrations für Schema-Änderungen:

### 005_add_rating_to_products

```sql
-- TODO: rating Spalte hinzufügen (DECIMAL 2,1)
```

### 006_add_user_role

```sql
-- TODO: role Spalte zu users (VARCHAR, Default 'customer')
```

### 007_create_reviews

```sql
-- TODO: reviews Tabelle (user_id, product_id, rating, comment, created_at)
-- TODO: Unique constraint auf (user_id, product_id)
```

---

## Aufgabe 6: Daten-Migration (Bonus, 10 min)

```sql
-- 008_populate_categories.up.sql
INSERT INTO categories (name, parent_id) VALUES
    ('Electronics', NULL),
    ('Clothing', NULL),
    ('Laptops', 1),
    ('Smartphones', 1)
ON CONFLICT DO NOTHING;

-- 008_populate_categories.down.sql
DELETE FROM categories WHERE name IN ('Electronics', 'Clothing', 'Laptops', 'Smartphones');
```

---

## Testen

```bash
# Alle Migrations ausführen
dart run bin/migrate.dart up

# Status prüfen
dart run bin/migrate.dart status

# Rollback
dart run bin/migrate.dart down
dart run bin/migrate.dart down 3

# Datenbank prüfen
psql -d shop_db -c "\dt"
psql -d shop_db -c "SELECT * FROM migrations"
```

---

## Abgabe-Checkliste

- [ ] migrations-Ordner mit mindestens 7 Migrations
- [ ] Jede Migration hat up.sql und down.sql
- [ ] MigrationRunner mit init, migrate, rollback
- [ ] CLI-Tool bin/migrate.dart
- [ ] Status-Befehl zeigt applied und pending
- [ ] Rollback funktioniert korrekt
- [ ] (Bonus) Daten-Migration
