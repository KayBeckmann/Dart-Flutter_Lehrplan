# Ressourcen: PostgreSQL mit Dart

## Offizielle Dokumentation

- [postgres Package (pub.dev)](https://pub.dev/packages/postgres)
- [postgres API Documentation](https://pub.dev/documentation/postgres/latest/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Cheat Sheet: Verbindung

```dart
import 'package:postgres/postgres.dart';

// Einfache Verbindung
final conn = await Connection.open(
  Endpoint(
    host: 'localhost',
    port: 5432,
    database: 'mydb',
    username: 'postgres',
    password: 'secret',
  ),
  settings: ConnectionSettings(
    sslMode: SslMode.disable,
  ),
);

// Verbindung schließen
await conn.close();
```

## Cheat Sheet: Connection Pool

```dart
// Pool erstellen
final pool = Pool.withEndpoints(
  [
    Endpoint(
      host: 'localhost',
      database: 'mydb',
      username: 'postgres',
      password: 'secret',
    ),
  ],
  settings: PoolSettings(
    maxConnectionCount: 10,
    sslMode: SslMode.disable,
  ),
);

// Query ausführen
final result = await pool.execute('SELECT * FROM users');

// Pool schließen
await pool.close();
```

## Cheat Sheet: Queries

```dart
// Einfache Query
final result = await conn.execute('SELECT * FROM users');

// Mit benannten Parametern
final result = await conn.execute(
  Sql.named('SELECT * FROM users WHERE id = @id'),
  parameters: {'id': 1},
);

// Mehrere Parameter
final result = await conn.execute(
  Sql.named('''
    SELECT * FROM products
    WHERE category = @category
      AND price >= @minPrice
      AND price <= @maxPrice
  '''),
  parameters: {
    'category': 'electronics',
    'minPrice': 50.0,
    'maxPrice': 500.0,
  },
);
```

## Cheat Sheet: Ergebnisse verarbeiten

```dart
// Iteration
for (final row in result) {
  print('ID: ${row[0]}, Name: ${row[1]}');
}

// Als Map
for (final row in result) {
  final map = row.toColumnMap();
  print(map['name']);
}

// Zu Liste konvertieren
final products = result.map((row) => row.toColumnMap()).toList();

// Mit Model
final products = result.map(Product.fromRow).toList();
```

## Cheat Sheet: INSERT

```dart
// INSERT mit RETURNING
final result = await conn.execute(
  Sql.named('''
    INSERT INTO products (name, price)
    VALUES (@name, @price)
    RETURNING id
  '''),
  parameters: {
    'name': 'New Product',
    'price': 99.99,
  },
);

final newId = result.first[0] as int;
```

## Cheat Sheet: UPDATE

```dart
final result = await conn.execute(
  Sql.named('''
    UPDATE products
    SET price = @price
    WHERE id = @id
  '''),
  parameters: {
    'id': 1,
    'price': 89.99,
  },
);

final rowsAffected = result.affectedRows;
```

## Cheat Sheet: DELETE

```dart
final result = await conn.execute(
  Sql.named('DELETE FROM products WHERE id = @id'),
  parameters: {'id': 1},
);

final deleted = result.affectedRows > 0;
```

## Cheat Sheet: Transaktionen

```dart
await conn.runTx((tx) async {
  // Alle Queries in der Transaktion
  await tx.execute(
    Sql.named('UPDATE accounts SET balance = balance - @amount WHERE id = @from'),
    parameters: {'from': 1, 'amount': 100},
  );

  await tx.execute(
    Sql.named('UPDATE accounts SET balance = balance + @amount WHERE id = @to'),
    parameters: {'to': 2, 'amount': 100},
  );

  // Automatischer COMMIT am Ende
  // Automatischer ROLLBACK bei Exception
});
```

## Cheat Sheet: Model Mapping

```dart
class Product {
  final int id;
  final String name;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Product.fromRow(ResultRow row) {
    final map = row.toColumnMap();
    return Product(
      id: map['id'] as int,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
  };
}
```

## Cheat Sheet: Fehlerbehandlung

```dart
try {
  await conn.execute('...');
} on ServerException catch (e) {
  print('PostgreSQL Error: ${e.message}');
  print('Code: ${e.code}');

  switch (e.code) {
    case '23505':
      print('Duplicate entry');
      break;
    case '23503':
      print('Foreign key violation');
      break;
    case '23502':
      print('Not null violation');
      break;
  }
} on SocketException catch (e) {
  print('Connection failed: $e');
} catch (e) {
  print('Unknown error: $e');
}
```

## Cheat Sheet: Datentypen

| PostgreSQL | Dart | Konvertierung |
|------------|------|---------------|
| `INTEGER` | `int` | `row[0] as int` |
| `BIGINT` | `int` | `row[0] as int` |
| `DECIMAL` | `num` | `(row[0] as num).toDouble()` |
| `TEXT` | `String` | `row[0] as String` |
| `VARCHAR` | `String` | `row[0] as String` |
| `BOOLEAN` | `bool` | `row[0] as bool` |
| `TIMESTAMP` | `DateTime` | `row[0] as DateTime` |
| `DATE` | `DateTime` | `row[0] as DateTime` |
| `UUID` | `String` | `row[0] as String` |
| `JSONB` | `Map` | `row[0] as Map` |

## Umgebungsvariablen

```dart
import 'dart:io';

final conn = await Connection.open(
  Endpoint(
    host: Platform.environment['DB_HOST'] ?? 'localhost',
    port: int.parse(Platform.environment['DB_PORT'] ?? '5432'),
    database: Platform.environment['DB_NAME'] ?? 'mydb',
    username: Platform.environment['DB_USER'] ?? 'postgres',
    password: Platform.environment['DB_PASSWORD'] ?? '',
  ),
);
```

```bash
# .env oder Shell
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=shop_db
export DB_USER=postgres
export DB_PASSWORD=secret

dart run
```

## Docker Compose

```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: shop_db
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

```bash
docker-compose up -d
```

## Best Practices

1. **Immer parametrisierte Queries** - Nie Strings konkatenieren
2. **Connection Pool** für Server-Anwendungen
3. **Transaktionen** für zusammengehörige Änderungen
4. **Models** für Typ-Sicherheit
5. **Fehlerbehandlung** mit spezifischen Catches
6. **Umgebungsvariablen** für Credentials
7. **Connection schließen** im finally-Block

## Häufige Fehler

| Problem | Lösung |
|---------|--------|
| Connection refused | PostgreSQL läuft? Port korrekt? |
| Authentication failed | Username/Password prüfen |
| SSL required | `sslMode: SslMode.require` |
| Table not found | Schema/Tabelle existiert? |
| Type mismatch | Typ-Konvertierung prüfen |
