# Einheit 7.5: Database Migrations

## Lernziele

Nach dieser Einheit kannst du:
- Das Konzept von Migrations verstehen
- Schema-Änderungen versioniert durchführen
- Migrations in Dart implementieren
- Rollbacks sicher handhaben

---

## Was sind Migrations?

**Migrations** sind versionierte Änderungen am Datenbankschema, die nachvollziehbar und wiederholbar sind.

### Ohne Migrations

```
Entwickler A: "Ich habe eine neue Spalte hinzugefügt"
Entwickler B: "Welche? Auf welcher Tabelle?"
Entwickler A: "products.rating, aber auf Prod ist sie schon drin"
Entwickler B: "Bei mir fehlt sie noch..."
```

### Mit Migrations

```
├── migrations/
│   ├── 001_create_users.sql
│   ├── 002_create_products.sql
│   ├── 003_add_rating_to_products.sql
│   └── 004_create_orders.sql
```

---

## Migrations-Tabelle

```sql
CREATE TABLE IF NOT EXISTS migrations (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Diese Tabelle trackt, welche Migrations bereits ausgeführt wurden.

---

## Migration-Dateien

### Struktur

```
migrations/
├── 001_create_users.up.sql
├── 001_create_users.down.sql
├── 002_create_products.up.sql
├── 002_create_products.down.sql
└── ...
```

### Up-Migration (Vorwärts)

```sql
-- 001_create_users.up.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### Down-Migration (Rollback)

```sql
-- 001_create_users.down.sql
DROP TABLE IF EXISTS users;
```

---

## Migration Runner in Dart

```dart
import 'dart:io';
import 'package:postgres/postgres.dart';

class MigrationRunner {
  final Pool _pool;
  final String _migrationsPath;

  MigrationRunner(this._pool, this._migrationsPath);

  Future<void> init() async {
    await _pool.execute('''
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<List<String>> getAppliedMigrations() async {
    final result = await _pool.execute(
      'SELECT name FROM migrations ORDER BY name',
    );
    return result.map((r) => r[0] as String).toList();
  }

  Future<List<String>> getPendingMigrations() async {
    final applied = await getAppliedMigrations();
    final files = Directory(_migrationsPath)
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.up.sql'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.up.sql', ''))
        .toList()
      ..sort();

    return files.where((f) => !applied.contains(f)).toList();
  }

  Future<void> migrate() async {
    await init();
    final pending = await getPendingMigrations();

    if (pending.isEmpty) {
      print('No pending migrations.');
      return;
    }

    for (final name in pending) {
      print('Applying: $name');
      final sql = await File('$_migrationsPath/$name.up.sql').readAsString();

      await _pool.execute(sql);
      await _pool.execute(
        Sql.named('INSERT INTO migrations (name) VALUES (@name)'),
        parameters: {'name': name},
      );

      print('Applied: $name');
    }
  }

  Future<void> rollback([int steps = 1]) async {
    final applied = await getAppliedMigrations();
    if (applied.isEmpty) {
      print('No migrations to rollback.');
      return;
    }

    final toRollback = applied.reversed.take(steps).toList();

    for (final name in toRollback) {
      print('Rolling back: $name');
      final sql = await File('$_migrationsPath/$name.down.sql').readAsString();

      await _pool.execute(sql);
      await _pool.execute(
        Sql.named('DELETE FROM migrations WHERE name = @name'),
        parameters: {'name': name},
      );

      print('Rolled back: $name');
    }
  }
}
```

---

## Beispiel-Migrations

### 001_create_users

```sql
-- 001_create_users.up.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 001_create_users.down.sql
DROP TABLE IF EXISTS users CASCADE;
```

### 002_create_categories

```sql
-- 002_create_categories.up.sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(id)
);

-- 002_create_categories.down.sql
DROP TABLE IF EXISTS categories CASCADE;
```

### 003_create_products

```sql
-- 003_create_products.up.sql
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL CHECK (price > 0),
    stock INTEGER NOT NULL DEFAULT 0,
    category_id INTEGER REFERENCES categories(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category_id);

-- 003_create_products.down.sql
DROP TABLE IF EXISTS products CASCADE;
```

### 004_add_rating_to_products

```sql
-- 004_add_rating_to_products.up.sql
ALTER TABLE products
ADD COLUMN rating DECIMAL(2, 1) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5);

-- 004_add_rating_to_products.down.sql
ALTER TABLE products
DROP COLUMN IF EXISTS rating;
```

---

## CLI-Tool

```dart
// bin/migrate.dart
import 'dart:io';
import 'package:postgres/postgres.dart';

Future<void> main(List<String> args) async {
  final pool = Pool.withEndpoints([
    Endpoint(
      host: Platform.environment['DB_HOST'] ?? 'localhost',
      database: Platform.environment['DB_NAME'] ?? 'shop_db',
      username: Platform.environment['DB_USER'] ?? 'postgres',
      password: Platform.environment['DB_PASSWORD'] ?? 'secret',
    ),
  ]);

  final runner = MigrationRunner(pool, 'migrations');

  try {
    if (args.isEmpty || args[0] == 'up') {
      await runner.migrate();
    } else if (args[0] == 'down') {
      final steps = args.length > 1 ? int.parse(args[1]) : 1;
      await runner.rollback(steps);
    } else if (args[0] == 'status') {
      final applied = await runner.getAppliedMigrations();
      final pending = await runner.getPendingMigrations();

      print('Applied migrations:');
      for (final m in applied) print('  ✓ $m');

      print('\nPending migrations:');
      for (final m in pending) print('  ○ $m');
    } else {
      print('Usage: dart run bin/migrate.dart [up|down|status]');
    }
  } finally {
    await pool.close();
  }
}
```

### Verwendung

```bash
# Migrations ausführen
dart run bin/migrate.dart up

# Status anzeigen
dart run bin/migrate.dart status

# Rollback (1 Migration)
dart run bin/migrate.dart down

# Rollback (3 Migrations)
dart run bin/migrate.dart down 3
```

---

## Best Practices

### 1. Migrations sind unveränderlich

```sql
-- FALSCH: Bestehende Migration ändern
-- 001_create_users.up.sql (geändert)

-- RICHTIG: Neue Migration erstellen
-- 005_add_phone_to_users.up.sql
ALTER TABLE users ADD COLUMN phone VARCHAR(20);
```

### 2. Transaktionen verwenden

```sql
-- 006_add_columns.up.sql
BEGIN;

ALTER TABLE products ADD COLUMN weight DECIMAL(10, 2);
ALTER TABLE products ADD COLUMN dimensions VARCHAR(50);

COMMIT;
```

### 3. Daten-Migrations vorsichtig

```sql
-- 007_normalize_emails.up.sql
UPDATE users SET email = LOWER(email);

-- 007_normalize_emails.down.sql
-- Nicht rückgängig machbar!
-- Leere Datei oder Hinweis
```

### 4. Aussagekräftige Namen

```
✓ 001_create_users
✓ 002_add_email_index_to_users
✓ 003_create_orders_table

✗ 001_update
✗ 002_fix
✗ 003_changes
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| Migration | Versionierte Schema-Änderung |
| Up | Vorwärts-Migration |
| Down | Rollback-Migration |
| migrations-Tabelle | Tracking der angewandten Migrations |

---

## Nächste Schritte

In der nächsten Einheit lernst du **MongoDB**: Eine dokumentenorientierte NoSQL-Datenbank für flexible Datenstrukturen.
