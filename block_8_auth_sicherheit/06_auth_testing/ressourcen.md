# Ressourcen: Testing der Auth-Schicht

## Offizielle Dokumentation

- [Dart test Package](https://pub.dev/packages/test)
- [mocktail Package](https://pub.dev/packages/mocktail)
- [shelf Testing](https://pub.dev/packages/shelf#testing)

## Cheat Sheet: Test Struktur

```dart
void main() {
  group('ComponentName', () {
    late ComponentType component;

    // Einmalig vor allen Tests
    setUpAll(() async {
      // DB-Connection, etc.
    });

    // Vor jedem Test
    setUp(() {
      component = ComponentType();
    });

    // Nach jedem Test
    tearDown(() {
      // Cleanup
    });

    // Einmalig nach allen Tests
    tearDownAll(() async {
      // DB schließen, etc.
    });

    group('methodName', () {
      test('does something specific', () {
        // Arrange
        // Act
        // Assert
      });
    });
  });
}
```

## Cheat Sheet: Matchers

```dart
// Gleichheit
expect(value, equals(expected));
expect(value, isNot(equals(other)));

// Typen
expect(value, isA<String>());
expect(value, isNotNull);
expect(value, isNull);

// Strings
expect(str, startsWith('prefix'));
expect(str, endsWith('suffix'));
expect(str, contains('substring'));

// Listen
expect(list, isEmpty);
expect(list, isNotEmpty);
expect(list, hasLength(3));
expect(list, contains(item));

// Zahlen
expect(num, greaterThan(5));
expect(num, lessThan(10));
expect(num, inInclusiveRange(5, 10));

// Exceptions
expect(() => fn(), throwsA(isA<MyException>()));
expect(() => fn(), throwsException);
expect(() => fn(), returnsNormally);

// Async
expect(future, completion(equals(value)));
expect(future, throwsA(isA<Exception>()));
```

## Cheat Sheet: Mocktail

```dart
// Mock erstellen
class MockService extends Mock implements Service {}

// Fallback registrieren (für any())
setUpAll(() {
  registerFallbackValue(FakeUser());
});

// Verhalten definieren
when(() => mock.method(any())).thenReturn(value);
when(() => mock.asyncMethod(any())).thenAnswer((_) async => value);
when(() => mock.method(any())).thenThrow(Exception());

// Aufrufe verifizieren
verify(() => mock.method(any())).called(1);
verify(() => mock.method('specific')).called(1);
verifyNever(() => mock.method(any()));

// Argument Capture
final captured = verify(() => mock.method(captureAny())).captured;

// Reset
reset(mock);
```

## Cheat Sheet: Shelf Request Testing

```dart
// Request erstellen
final request = Request(
  'POST',
  Uri.parse('http://localhost/api/resource'),
  headers: {
    'content-type': 'application/json',
    'authorization': 'Bearer token',
  },
  body: jsonEncode({'key': 'value'}),
);

// Response prüfen
final response = await handler(request);
expect(response.statusCode, equals(200));

final body = await response.readAsString();
final json = jsonDecode(body);
expect(json['key'], equals('value'));

// Headers prüfen
expect(response.headers['content-type'], contains('application/json'));
```

## Cheat Sheet: Test Database

```dart
class TestDatabase {
  late Connection connection;

  Future<void> setUp() async {
    connection = await Connection.open(
      Endpoint(
        host: 'localhost',
        database: 'test_db',
        username: 'test',
        password: 'test',
      ),
    );
  }

  Future<void> migrate() async {
    await connection.execute('''
      CREATE TABLE IF NOT EXISTS ...
    ''');
  }

  Future<void> truncate(List<String> tables) async {
    for (final table in tables.reversed) {
      await connection.execute('TRUNCATE $table CASCADE');
    }
  }

  Future<void> tearDown() async {
    await connection.close();
  }
}
```

## Cheat Sheet: Auth Test Helpers

```dart
// Token für Tests generieren
String createTestToken(JwtService jwt, {int userId = 1, String role = 'user'}) {
  final user = User(id: userId, email: 'test@test.com', passwordHash: '', role: role);
  return jwt.generateAccessToken(user);
}

// Authenticated Request
Request authRequest(String method, String path, String token, {Map<String, dynamic>? body}) {
  return Request(
    method,
    Uri.parse('http://localhost$path'),
    headers: {
      'authorization': 'Bearer $token',
      if (body != null) 'content-type': 'application/json',
    },
    body: body != null ? jsonEncode(body) : null,
  );
}

// Response Body parsen
Future<Map<String, dynamic>> parseJson(Response response) async {
  return jsonDecode(await response.readAsString());
}
```

## Best Practices

### DO

1. **Isolierte Tests** - Jeder Test unabhängig
2. **Schnelle Unit Tests** - Niedrige Cost Factors
3. **Mocks für externe Dependencies**
4. **Fixtures für Testdaten**
5. **Descriptive Test Names**
6. **Test-Datenbank für Integration Tests**
7. **Cleanup nach Tests**

### DON'T

1. **Tests abhängig voneinander**
2. **Produktions-Datenbank in Tests**
3. **Hardcoded Delays** (außer für Expiry-Tests)
4. **Secrets in Test-Code**
5. **Zu viele Integration Tests**

## Test-Pyramide für Auth

```
         /\
        /E2E\         Login → API Call → Logout
       /------\
      /Integr.\       Handler + Service + DB
     /----------\
    / Unit Tests \    PasswordService, JwtService, etc.
   /--------------\
```

## Coverage

```bash
# Tests mit Coverage
dart test --coverage=coverage

# HTML-Report generieren
dart pub global activate coverage
format_coverage --lcov --in=coverage --out=coverage/lcov.info
genhtml coverage/lcov.info -o coverage/html

# Report öffnen
open coverage/html/index.html
```

