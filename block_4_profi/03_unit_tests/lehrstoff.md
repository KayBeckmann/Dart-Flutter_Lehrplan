# Einheit 4.3: Unit Tests

## Lernziele

Nach dieser Einheit kannst du:
- Unit Tests für Dart-Code schreiben
- Assertions und Matchers richtig einsetzen
- Mit `mocktail` Mocks erstellen
- Test-Driven Development (TDD) anwenden

---

## 1. Test-Grundlagen

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

### Erster Test

```dart
// test/calculator_test.dart
import 'package:test/test.dart';
import 'package:my_app/calculator.dart';

void main() {
  test('adds two numbers', () {
    final calculator = Calculator();

    final result = calculator.add(2, 3);

    expect(result, equals(5));
  });
}
```

### Tests ausführen

```bash
# Alle Tests
flutter test

# Bestimmte Datei
flutter test test/calculator_test.dart

# Mit Coverage
flutter test --coverage
```

---

## 2. Test-Struktur

### Gruppierung mit `group`

```dart
void main() {
  group('Calculator', () {
    late Calculator calculator;

    setUp(() {
      calculator = Calculator();
    });

    group('add', () {
      test('returns sum of two positive numbers', () {
        expect(calculator.add(2, 3), equals(5));
      });

      test('returns sum with negative numbers', () {
        expect(calculator.add(-2, 3), equals(1));
      });

      test('returns 0 when both are 0', () {
        expect(calculator.add(0, 0), equals(0));
      });
    });

    group('divide', () {
      test('returns quotient of two numbers', () {
        expect(calculator.divide(6, 2), equals(3));
      });

      test('throws when dividing by zero', () {
        expect(
          () => calculator.divide(6, 0),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
```

### setUp und tearDown

```dart
void main() {
  late Database db;
  late UserRepository repository;

  // Einmal vor allen Tests
  setUpAll(() async {
    db = await Database.open(':memory:');
  });

  // Vor jedem Test
  setUp(() {
    repository = UserRepository(db);
  });

  // Nach jedem Test
  tearDown(() async {
    await db.clear();
  });

  // Einmal nach allen Tests
  tearDownAll(() async {
    await db.close();
  });

  test('creates a user', () async {
    await repository.createUser('John');
    final users = await repository.getAllUsers();
    expect(users, hasLength(1));
  });
}
```

---

## 3. Assertions & Matchers

### Basis-Matchers

```dart
// Gleichheit
expect(result, equals(5));
expect(result, 5);  // Kurzform

// Ungleichheit
expect(result, isNot(equals(3)));

// Null-Checks
expect(value, isNull);
expect(value, isNotNull);

// Boolean
expect(flag, isTrue);
expect(flag, isFalse);

// Typen
expect(value, isA<String>());
expect(value, isA<int>());
```

### Numerische Matchers

```dart
// Vergleiche
expect(value, greaterThan(5));
expect(value, lessThan(10));
expect(value, greaterThanOrEqualTo(5));
expect(value, lessThanOrEqualTo(10));

// Bereich
expect(value, inInclusiveRange(1, 10));
expect(value, inExclusiveRange(0, 11));

// Ungefähr gleich (für Floats)
expect(3.14159, closeTo(3.14, 0.01));
```

### Collection-Matchers

```dart
final list = [1, 2, 3, 4, 5];

// Länge
expect(list, hasLength(5));
expect(list, isEmpty);
expect(list, isNotEmpty);

// Enthält
expect(list, contains(3));
expect(list, containsAll([1, 2, 3]));
expect(list, containsAllInOrder([1, 2, 3]));

// Jedes Element
expect(list, everyElement(greaterThan(0)));
expect(list, everyElement(isA<int>()));

// Mindestens ein Element
expect(list, anyElement(equals(3)));

// Reihenfolge
expect(list, orderedEquals([1, 2, 3, 4, 5]));
expect([1, 2, 3], unorderedEquals([3, 1, 2]));
```

### String-Matchers

```dart
final text = 'Hello World';

expect(text, startsWith('Hello'));
expect(text, endsWith('World'));
expect(text, contains('lo Wo'));
expect(text, matches(RegExp(r'Hello \w+')));

// Case-insensitive
expect(text, equalsIgnoringCase('hello world'));
expect(text, equalsIgnoringWhitespace('Hello  World'));
```

### Exception-Matchers

```dart
// Wirft irgendeine Exception
expect(() => throw Exception(), throwsException);

// Wirft bestimmten Typ
expect(() => throw ArgumentError(), throwsArgumentError);
expect(() => throw StateError(''), throwsStateError);
expect(() => throw FormatException(), throwsFormatException);

// Custom Exception
expect(
  () => throw CustomException('message'),
  throwsA(isA<CustomException>()),
);

// Exception mit bestimmter Message
expect(
  () => throw Exception('invalid input'),
  throwsA(
    predicate<Exception>(
      (e) => e.toString().contains('invalid input'),
    ),
  ),
);

// Präziser mit having
expect(
  () => throw CustomException('error', code: 404),
  throwsA(
    isA<CustomException>()
        .having((e) => e.message, 'message', 'error')
        .having((e) => e.code, 'code', 404),
  ),
);
```

### Custom Matchers

```dart
// Mit predicate
expect(
  user,
  predicate<User>(
    (u) => u.age >= 18 && u.isVerified,
    'is an adult and verified',
  ),
);

// Mit having (für bessere Fehlermeldungen)
expect(
  user,
  isA<User>()
      .having((u) => u.name, 'name', 'John')
      .having((u) => u.age, 'age', greaterThan(18))
      .having((u) => u.email, 'email', contains('@')),
);
```

---

## 4. Async Tests

### Futures testen

```dart
test('fetches data from API', () async {
  final service = ApiService();

  final result = await service.fetchData();

  expect(result, isNotEmpty);
});

// Oder mit completion Matcher
test('completes successfully', () {
  final future = service.fetchData();
  expect(future, completes);
});

// Future wirft Exception
test('throws on invalid input', () {
  final future = service.fetchData('invalid');
  expect(future, throwsA(isA<ApiException>()));
});
```

### Streams testen

```dart
test('emits values', () {
  final stream = Stream.fromIterable([1, 2, 3]);

  expect(stream, emitsInOrder([1, 2, 3]));
});

test('emits error', () {
  final stream = Stream.error(Exception('error'));

  expect(stream, emitsError(isA<Exception>()));
});

test('completes after values', () {
  final stream = Stream.fromIterable([1, 2, 3]);

  expect(
    stream,
    emitsInOrder([1, 2, 3, emitsDone]),
  );
});

// Komplexere Patterns
test('emits values matching pattern', () {
  final stream = controller.stream;

  expect(
    stream,
    emitsInOrder([
      emits(equals(1)),
      emits(greaterThan(5)),
      emitsAnyOf([equals(10), equals(20)]),
      mayEmit(anything),
      emitsDone,
    ]),
  );
});
```

---

## 5. Mocking mit mocktail

### Setup

```dart
import 'package:mocktail/mocktail.dart';

// Mock-Klasse erstellen
class MockUserRepository extends Mock implements UserRepository {}

class MockHttpClient extends Mock implements HttpClient {}
```

### Basis-Mocking

```dart
void main() {
  late MockUserRepository mockRepository;
  late UserService userService;

  setUp(() {
    mockRepository = MockUserRepository();
    userService = UserService(mockRepository);
  });

  test('returns user by id', () async {
    // Arrange: Mock-Verhalten definieren
    when(() => mockRepository.findById(1))
        .thenAnswer((_) async => User(id: 1, name: 'John'));

    // Act
    final user = await userService.getUser(1);

    // Assert
    expect(user.name, equals('John'));
    verify(() => mockRepository.findById(1)).called(1);
  });
}
```

### when() Patterns

```dart
// Synchroner Return
when(() => mock.getValue()).thenReturn(42);

// Async Return
when(() => mock.fetchData()).thenAnswer((_) async => 'data');

// Exception werfen
when(() => mock.riskyOperation()).thenThrow(Exception());

// Async Exception
when(() => mock.fetchData()).thenAnswer((_) async => throw ApiException());

// Mehrere Aufrufe unterschiedlich
when(() => mock.getValue())
    .thenReturn(1)
    .thenReturn(2)
    .thenReturn(3);

// Mit Argumenten
when(() => mock.findById(any())).thenAnswer(
  (invocation) async {
    final id = invocation.positionalArguments[0] as int;
    return User(id: id, name: 'User $id');
  },
);
```

### verify() Patterns

```dart
// Wurde aufgerufen
verify(() => mock.save(any())).called(1);

// Mehrfach aufgerufen
verify(() => mock.log(any())).called(3);

// Mindestens einmal
verify(() => mock.connect()).called(greaterThan(0));

// Nie aufgerufen
verifyNever(() => mock.delete(any()));

// Reihenfolge prüfen
verifyInOrder([
  () => mock.open(),
  () => mock.write(any()),
  () => mock.close(),
]);

// Keine weiteren Aufrufe
verifyNoMoreInteractions(mock);
```

### Argument Matchers

```dart
// any() - beliebiger Wert
when(() => mock.findById(any())).thenReturn(user);

// any() mit Typ
when(() => mock.findById(any<int>())).thenReturn(user);

// captureAny() - Wert erfassen
verify(() => mock.save(captureAny())).captured;

// Komplexe Bedingungen
when(() => mock.findByAge(any(that: greaterThan(18))))
    .thenReturn([adult1, adult2]);
```

### Argument Capturing

```dart
test('saves user with correct data', () async {
  when(() => mockRepository.save(any())).thenAnswer((_) async {});

  await userService.createUser('John', 25);

  final captured = verify(() => mockRepository.save(captureAny())).captured;
  final savedUser = captured.first as User;

  expect(savedUser.name, equals('John'));
  expect(savedUser.age, equals(25));
});
```

### Fallback Values registrieren

```dart
// Für Custom-Typen bei any()
setUpAll(() {
  registerFallbackValue(User(id: 0, name: ''));
  registerFallbackValue(Uri.parse('https://example.com'));
});
```

---

## 6. Test-Driven Development (TDD)

### Der TDD-Zyklus

```
1. RED:   Schreibe einen fehlschlagenden Test
2. GREEN: Schreibe minimalen Code um den Test zu bestehen
3. REFACTOR: Verbessere den Code ohne die Tests zu brechen
```

### TDD Beispiel

```dart
// 1. RED - Test schreiben (wird fehlschlagen)
test('validates email format', () {
  final validator = EmailValidator();

  expect(validator.isValid('test@example.com'), isTrue);
  expect(validator.isValid('invalid'), isFalse);
  expect(validator.isValid(''), isFalse);
});

// 2. GREEN - Minimale Implementierung
class EmailValidator {
  bool isValid(String email) {
    if (email.isEmpty) return false;
    return email.contains('@');
  }
}

// 3. REFACTOR - Verbessern
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$',
  );

  bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email);
  }
}
```

### TDD für eine TodoList

```dart
// Schritt 1: Test für leere Liste
test('starts with empty list', () {
  final todoList = TodoList();
  expect(todoList.items, isEmpty);
});

// Schritt 2: Test für Hinzufügen
test('adds item to list', () {
  final todoList = TodoList();

  todoList.add('Buy milk');

  expect(todoList.items, hasLength(1));
  expect(todoList.items.first.text, equals('Buy milk'));
});

// Schritt 3: Test für Abhaken
test('marks item as done', () {
  final todoList = TodoList();
  todoList.add('Buy milk');

  todoList.markDone(0);

  expect(todoList.items.first.isDone, isTrue);
});

// Schritt 4: Test für Löschen
test('removes item from list', () {
  final todoList = TodoList();
  todoList.add('Buy milk');

  todoList.remove(0);

  expect(todoList.items, isEmpty);
});

// Schritt 5: Test für Filtern
test('filters completed items', () {
  final todoList = TodoList();
  todoList.add('Task 1');
  todoList.add('Task 2');
  todoList.markDone(0);

  final pending = todoList.pending;

  expect(pending, hasLength(1));
  expect(pending.first.text, equals('Task 2'));
});
```

---

## 7. Best Practices

### Test-Benennung

```dart
// Muster: should_expectedBehavior_when_condition

test('should return null when user not found', () {});
test('should throw exception when input is invalid', () {});
test('should emit loading state when fetch starts', () {});

// Oder: Given-When-Then
test('given valid email, when validate, then returns true', () {});
```

### AAA-Pattern (Arrange-Act-Assert)

```dart
test('calculates total with discount', () {
  // Arrange
  final cart = ShoppingCart();
  cart.add(Product('Book', 20.0));
  cart.add(Product('Pen', 5.0));
  cart.applyDiscount(0.1);  // 10%

  // Act
  final total = cart.calculateTotal();

  // Assert
  expect(total, equals(22.5));
});
```

### Ein Konzept pro Test

```dart
// SCHLECHT: Mehrere Konzepte
test('user operations', () {
  final user = User.create('John');
  expect(user.name, equals('John'));

  user.updateAge(25);
  expect(user.age, equals(25));

  user.delete();
  expect(user.isDeleted, isTrue);
});

// GUT: Einzelne Konzepte
test('creates user with name', () {
  final user = User.create('John');
  expect(user.name, equals('John'));
});

test('updates user age', () {
  final user = User.create('John');
  user.updateAge(25);
  expect(user.age, equals(25));
});

test('deletes user', () {
  final user = User.create('John');
  user.delete();
  expect(user.isDeleted, isTrue);
});
```

### Test-Doubles

| Typ | Beschreibung |
|-----|--------------|
| **Dummy** | Wird übergeben, aber nicht benutzt |
| **Stub** | Gibt vordefinierten Wert zurück |
| **Mock** | Prüft Interaktionen |
| **Fake** | Funktionierende Implementierung (z.B. InMemory-DB) |
| **Spy** | Echter Aufruf + Aufzeichnung |

```dart
// Dummy
final dummyLogger = DummyLogger();
final service = Service(logger: dummyLogger);

// Stub
when(() => mockRepo.getAll()).thenReturn([user1, user2]);

// Mock
verify(() => mockRepo.save(any())).called(1);

// Fake
class FakeUserRepository implements UserRepository {
  final _users = <User>[];

  @override
  Future<List<User>> getAll() async => _users;

  @override
  Future<void> save(User user) async => _users.add(user);
}
```

---

## 8. Praktisches Beispiel: UserService Tests

```dart
// lib/services/user_service.dart
class UserService {
  final UserRepository _repository;
  final EmailService _emailService;

  UserService(this._repository, this._emailService);

  Future<User> createUser(String name, String email) async {
    if (name.isEmpty) throw ArgumentError('Name cannot be empty');
    if (!email.contains('@')) throw ArgumentError('Invalid email');

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      email: email,
    );

    await _repository.save(user);
    await _emailService.sendWelcome(email);

    return user;
  }

  Future<User?> findByEmail(String email) async {
    return _repository.findByEmail(email);
  }
}

// test/services/user_service_test.dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class MockUserRepository extends Mock implements UserRepository {}
class MockEmailService extends Mock implements EmailService {}

void main() {
  late MockUserRepository mockRepository;
  late MockEmailService mockEmailService;
  late UserService userService;

  setUpAll(() {
    registerFallbackValue(User(id: 0, name: '', email: ''));
  });

  setUp(() {
    mockRepository = MockUserRepository();
    mockEmailService = MockEmailService();
    userService = UserService(mockRepository, mockEmailService);
  });

  group('createUser', () {
    test('creates user and sends welcome email', () async {
      // Arrange
      when(() => mockRepository.save(any())).thenAnswer((_) async {});
      when(() => mockEmailService.sendWelcome(any())).thenAnswer((_) async {});

      // Act
      final user = await userService.createUser('John', 'john@example.com');

      // Assert
      expect(user.name, equals('John'));
      expect(user.email, equals('john@example.com'));
      verify(() => mockRepository.save(any())).called(1);
      verify(() => mockEmailService.sendWelcome('john@example.com')).called(1);
    });

    test('throws when name is empty', () {
      expect(
        () => userService.createUser('', 'test@example.com'),
        throwsArgumentError,
      );
      verifyNever(() => mockRepository.save(any()));
    });

    test('throws when email is invalid', () {
      expect(
        () => userService.createUser('John', 'invalid'),
        throwsArgumentError,
      );
    });
  });

  group('findByEmail', () {
    test('returns user when found', () async {
      final expectedUser = User(id: 1, name: 'John', email: 'john@example.com');
      when(() => mockRepository.findByEmail('john@example.com'))
          .thenAnswer((_) async => expectedUser);

      final result = await userService.findByEmail('john@example.com');

      expect(result, equals(expectedUser));
    });

    test('returns null when not found', () async {
      when(() => mockRepository.findByEmail(any()))
          .thenAnswer((_) async => null);

      final result = await userService.findByEmail('unknown@example.com');

      expect(result, isNull);
    });
  });
}
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| `test()` | Einzelner Testfall |
| `group()` | Tests gruppieren |
| `setUp()` / `tearDown()` | Vor/Nach jedem Test |
| `expect()` | Assertion |
| Matchers | `equals`, `isA`, `throwsA`, etc. |
| `Mock` | Fake-Objekt mit mocktail |
| `when()` | Mock-Verhalten definieren |
| `verify()` | Aufrufe prüfen |

**Best Practices:**
- Ein Konzept pro Test
- AAA-Pattern (Arrange-Act-Assert)
- Aussagekräftige Testnamen
- Tests sollten isoliert und wiederholbar sein
- TDD für robusteren Code
