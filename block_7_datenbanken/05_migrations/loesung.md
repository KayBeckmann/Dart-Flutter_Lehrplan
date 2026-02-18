# Lösung 7.5: Database Migrations

## Migration Runner

```dart
// lib/migration_runner.dart
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

  Future<List<String>> getApplied() async {
    await init();
    final result = await _pool.execute(
      'SELECT name FROM migrations ORDER BY name',
    );
    return result.map((r) => r[0] as String).toList();
  }

  Future<List<String>> getPending() async {
    final applied = await getApplied();
    final dir = Directory(_migrationsPath);

    if (!await dir.exists()) {
      throw Exception('Migrations directory not found: $_migrationsPath');
    }

    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.up.sql'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.up.sql', ''))
        .toList()
      ..sort();

    return files.where((f) => !applied.contains(f)).toList();
  }

  Future<void> migrate() async {
    final pending = await getPending();

    if (pending.isEmpty) {
      print('✓ No pending migrations');
      return;
    }

    print('Running ${pending.length} migration(s)...\n');

    for (final name in pending) {
      await _applyMigration(name);
    }

    print('\n✓ All migrations applied');
  }

  Future<void> _applyMigration(String name) async {
    final file = File('$_migrationsPath/$name.up.sql');
    if (!await file.exists()) {
      throw Exception('Migration file not found: $name.up.sql');
    }

    final sql = await file.readAsString();

    print('  ↑ $name');

    try {
      await _pool.execute(sql);
      await _pool.execute(
        Sql.named('INSERT INTO migrations (name) VALUES (@name)'),
        parameters: {'name': name},
      );
    } catch (e) {
      print('  ✗ Failed: $e');
      rethrow;
    }
  }

  Future<void> rollback([int steps = 1]) async {
    final applied = await getApplied();

    if (applied.isEmpty) {
      print('✓ No migrations to rollback');
      return;
    }

    final toRollback = applied.reversed.take(steps).toList();

    print('Rolling back ${toRollback.length} migration(s)...\n');

    for (final name in toRollback) {
      await _rollbackMigration(name);
    }

    print('\n✓ Rollback complete');
  }

  Future<void> _rollbackMigration(String name) async {
    final file = File('$_migrationsPath/$name.down.sql');
    if (!await file.exists()) {
      throw Exception('Rollback file not found: $name.down.sql');
    }

    final sql = await file.readAsString();

    print('  ↓ $name');

    try {
      await _pool.execute(sql);
      await _pool.execute(
        Sql.named('DELETE FROM migrations WHERE name = @name'),
        parameters: {'name': name},
      );
    } catch (e) {
      print('  ✗ Failed: $e');
      rethrow;
    }
  }

  Future<void> status() async {
    final applied = await getApplied();
    final pending = await getPending();

    print('Migration Status\n');

    print('Applied (${applied.length}):');
    if (applied.isEmpty) {
      print('  (none)');
    } else {
      for (final m in applied) {
        print('  ✓ $m');
      }
    }

    print('\nPending (${pending.length}):');
    if (pending.isEmpty) {
      print('  (none)');
    } else {
      for (final m in pending) {
        print('  ○ $m');
      }
    }
  }
}
```

---

## CLI-Tool

```dart
// bin/migrate.dart
import 'dart:io';
import 'package:postgres/postgres.dart';
import '../lib/migration_runner.dart';

Future<void> main(List<String> args) async {
  final pool = Pool.withEndpoints(
    [
      Endpoint(
        host: Platform.environment['DB_HOST'] ?? 'localhost',
        port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
        database: Platform.environment['DB_NAME'] ?? 'shop_db',
        username: Platform.environment['DB_USER'] ?? 'postgres',
        password: Platform.environment['DB_PASSWORD'] ?? 'secret',
      ),
    ],
    settings: PoolSettings(sslMode: SslMode.disable),
  );

  final runner = MigrationRunner(pool, 'migrations');

  try {
    final command = args.isNotEmpty ? args[0] : 'up';

    switch (command) {
      case 'up':
        await runner.migrate();
        break;

      case 'down':
        final steps = args.length > 1 ? int.parse(args[1]) : 1;
        await runner.rollback(steps);
        break;

      case 'status':
        await runner.status();
        break;

      case 'reset':
        print('Resetting database...');
        final applied = await runner.getApplied();
        await runner.rollback(applied.length);
        await runner.migrate();
        break;

      default:
        print('''
Usage: dart run bin/migrate.dart <command>

Commands:
  up          Run all pending migrations (default)
  down [n]    Rollback last n migrations (default: 1)
  status      Show migration status
  reset       Rollback all and re-migrate
''');
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  } finally {
    await pool.close();
  }
}
```

---

## Migration-Dateien

### 001_create_users

```sql
-- migrations/001_create_users.up.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

```sql
-- migrations/001_create_users.down.sql
DROP TABLE IF EXISTS users CASCADE;
```

### 002_create_categories

```sql
-- migrations/002_create_categories.up.sql
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    parent_id INTEGER REFERENCES categories(id) ON DELETE SET NULL
);

CREATE INDEX idx_categories_parent ON categories(parent_id);
```

```sql
-- migrations/002_create_categories.down.sql
DROP TABLE IF EXISTS categories CASCADE;
```

### 003_create_products

```sql
-- migrations/003_create_products.up.sql
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
CREATE INDEX idx_products_price ON products(price);
```

```sql
-- migrations/003_create_products.down.sql
DROP TABLE IF EXISTS products CASCADE;
```

### 004_create_orders

```sql
-- migrations/004_create_orders.up.sql
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    status VARCHAR(20) DEFAULT 'pending',
    total DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE order_items (
    id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_order_items_order ON order_items(order_id);
```

```sql
-- migrations/004_create_orders.down.sql
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
```

### 005_add_rating_to_products

```sql
-- migrations/005_add_rating_to_products.up.sql
ALTER TABLE products
ADD COLUMN rating DECIMAL(2, 1) DEFAULT 0
CHECK (rating >= 0 AND rating <= 5);
```

```sql
-- migrations/005_add_rating_to_products.down.sql
ALTER TABLE products DROP COLUMN IF EXISTS rating;
```

### 006_add_user_role

```sql
-- migrations/006_add_user_role.up.sql
ALTER TABLE users
ADD COLUMN role VARCHAR(20) DEFAULT 'customer'
CHECK (role IN ('customer', 'admin', 'moderator'));
```

```sql
-- migrations/006_add_user_role.down.sql
ALTER TABLE users DROP COLUMN IF EXISTS role;
```

### 007_create_reviews

```sql
-- migrations/007_create_reviews.up.sql
CREATE TABLE reviews (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (user_id, product_id)
);

CREATE INDEX idx_reviews_product ON reviews(product_id);
```

```sql
-- migrations/007_create_reviews.down.sql
DROP TABLE IF EXISTS reviews CASCADE;
```

---

## Test-Ausgabe

```bash
$ dart run bin/migrate.dart status
Migration Status

Applied (0):
  (none)

Pending (7):
  ○ 001_create_users
  ○ 002_create_categories
  ○ 003_create_products
  ○ 004_create_orders
  ○ 005_add_rating_to_products
  ○ 006_add_user_role
  ○ 007_create_reviews

$ dart run bin/migrate.dart up
Running 7 migration(s)...

  ↑ 001_create_users
  ↑ 002_create_categories
  ↑ 003_create_products
  ↑ 004_create_orders
  ↑ 005_add_rating_to_products
  ↑ 006_add_user_role
  ↑ 007_create_reviews

✓ All migrations applied

$ dart run bin/migrate.dart down 2
Rolling back 2 migration(s)...

  ↓ 007_create_reviews
  ↓ 006_add_user_role

✓ Rollback complete
```
