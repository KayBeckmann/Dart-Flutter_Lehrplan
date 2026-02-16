# Übung 4.3: Unit Tests

## Ziel

Unit Tests für verschiedene Szenarien schreiben und TDD anwenden.

---

## Aufgabe 1: Calculator Tests (20 min)

Schreibe Tests für eine Calculator-Klasse:

```dart
class Calculator {
  double add(double a, double b) => a + b;
  double subtract(double a, double b) => a - b;
  double multiply(double a, double b) => a * b;
  double divide(double a, double b) {
    if (b == 0) throw ArgumentError('Cannot divide by zero');
    return a / b;
  }
  double power(double base, int exponent) {
    if (exponent < 0) throw ArgumentError('Negative exponent not supported');
    return pow(base, exponent).toDouble();
  }
}
```

Teste:
- Alle Operationen mit positiven Zahlen
- Operationen mit negativen Zahlen
- Division durch Null
- Negativer Exponent
- Edge Cases (0, sehr große Zahlen)

---

## Aufgabe 2: Validator Tests (20 min)

Erstelle Tests für Validatoren:

```dart
class Validators {
  static bool isValidEmail(String email);
  static bool isValidPassword(String password);  // min 8 chars, 1 upper, 1 digit
  static bool isValidPhone(String phone);  // +49...
  static bool isValidIBAN(String iban);
}
```

Teste verschiedene Szenarien:
- Gültige Eingaben
- Ungültige Eingaben
- Edge Cases (leer, nur Leerzeichen, Unicode)
- Grenzfälle (genau 8 Zeichen, etc.)

---

## Aufgabe 3: TDD - ShoppingCart (30 min)

Entwickle mit TDD einen Warenkorb:

```dart
// Schreibe ZUERST die Tests, dann die Implementierung!

// Anforderungen:
// - Produkte hinzufügen/entfernen
// - Menge ändern
// - Gesamtpreis berechnen
// - Rabatt anwenden (prozentual)
// - Mindestbestellwert prüfen
// - Versandkosten berechnen (frei ab 50€)
```

Folge dem TDD-Zyklus:
1. Schreibe einen fehlschlagenden Test
2. Implementiere minimal
3. Refactore

---

## Aufgabe 4: Async Tests (20 min)

Teste asynchrone Operationen:

```dart
class WeatherService {
  final HttpClient _client;

  WeatherService(this._client);

  Future<Weather> fetchWeather(String city) async {
    final response = await _client.get('api/weather/$city');
    if (response.statusCode != 200) {
      throw ApiException('Failed to fetch weather');
    }
    return Weather.fromJson(response.body);
  }

  Stream<Weather> watchWeather(String city, Duration interval) async* {
    while (true) {
      yield await fetchWeather(city);
      await Future.delayed(interval);
    }
  }
}
```

Teste:
- Erfolgreicher API-Call
- Fehler-Handling
- Stream emittiert korrekte Werte

---

## Aufgabe 5: Mocking (25 min)

Schreibe Tests mit Mocks für einen AuthService:

```dart
abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
  Future<User?> getCurrentUser();
  Future<void> resetPassword(String email);
}

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class AuthService {
  final AuthRepository _repository;
  final TokenStorage _storage;

  AuthService(this._repository, this._storage);

  Future<User> login(String email, String password) async {
    final user = await _repository.signIn(email, password);
    if (user == null) throw AuthException('Invalid credentials');
    await _storage.saveToken(user.token);
    return user;
  }

  Future<void> logout() async {
    await _repository.signOut();
    await _storage.deleteToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    return token != null;
  }
}
```

Teste mit mocktail:
- Login speichert Token
- Login wirft Exception bei ungültigen Credentials
- Logout löscht Token
- isLoggedIn prüft Token

---

## Aufgabe 6: Exception Tests (15 min)

Teste verschiedene Exception-Szenarien:

```dart
class UserService {
  void validateUser(User user) {
    if (user.name.isEmpty) {
      throw ValidationException('Name required', field: 'name');
    }
    if (user.age < 0) {
      throw ValidationException('Invalid age', field: 'age');
    }
    if (user.age < 18) {
      throw UnderageException(user.age);
    }
  }
}

class ValidationException implements Exception {
  final String message;
  final String field;
  ValidationException(this.message, {required this.field});
}

class UnderageException implements Exception {
  final int age;
  UnderageException(this.age);
}
```

Teste:
- Korrekte Exception-Typen
- Exception-Properties
- Kein Fehler bei gültigen Daten

---

## Aufgabe 7: Collection Tests (15 min)

Teste eine TaskList-Klasse:

```dart
class TaskList {
  List<Task> getAll();
  List<Task> getByStatus(TaskStatus status);
  List<Task> getOverdue();
  List<Task> getSortedByPriority();
  Map<TaskStatus, int> getStatistics();
}
```

Verwende Collection-Matchers:
- `hasLength`
- `contains`
- `everyElement`
- `orderedEquals`

---

## Aufgabe 8: Test Coverage (20 min)

Erreiche 100% Coverage für diese Klasse:

```dart
class PriceCalculator {
  double calculatePrice({
    required double basePrice,
    int quantity = 1,
    double? discountPercent,
    bool isMember = false,
    String? couponCode,
  }) {
    var price = basePrice * quantity;

    if (discountPercent != null && discountPercent > 0) {
      price -= price * (discountPercent / 100);
    }

    if (isMember) {
      price *= 0.95;  // 5% Mitgliederrabatt
    }

    if (couponCode != null) {
      switch (couponCode) {
        case 'SAVE10':
          price -= 10;
          break;
        case 'HALF':
          price *= 0.5;
          break;
        case 'FREE':
          price = 0;
          break;
      }
    }

    return price < 0 ? 0 : price;
  }
}
```

Führe aus:
```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Bonus: Parameterized Tests

Schreibe parametrisierte Tests:

```dart
// Teste mehrere Eingabe/Ausgabe-Kombinationen elegant

void main() {
  final testCases = [
    ('test@example.com', true),
    ('invalid', false),
    ('test@test', false),
    ('a@b.c', true),
    ('', false),
  ];

  for (final (input, expected) in testCases) {
    test('isValidEmail("$input") should be $expected', () {
      expect(Validators.isValidEmail(input), equals(expected));
    });
  }
}
```

---

## Abgabe-Checkliste

- [ ] Calculator mit allen Edge Cases getestet
- [ ] Validator-Tests für alle Szenarien
- [ ] ShoppingCart mit TDD entwickelt
- [ ] Async-Tests für Futures und Streams
- [ ] AuthService mit Mocks getestet
- [ ] Exception-Tests mit having()
- [ ] Collection-Tests mit Matchers
- [ ] 100% Coverage für PriceCalculator
- [ ] Alle Tests sind grün
- [ ] Code ist gut strukturiert
