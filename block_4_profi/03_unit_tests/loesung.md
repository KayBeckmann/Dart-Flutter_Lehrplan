# Lösung 4.3: Unit Tests

## Aufgabe 1: Calculator Tests

```dart
import 'dart:math';
import 'package:test/test.dart';

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

void main() {
  late Calculator calculator;

  setUp(() {
    calculator = Calculator();
  });

  group('Calculator', () {
    group('add', () {
      test('adds two positive numbers', () {
        expect(calculator.add(2, 3), equals(5));
      });

      test('adds negative numbers', () {
        expect(calculator.add(-2, -3), equals(-5));
      });

      test('adds positive and negative', () {
        expect(calculator.add(5, -3), equals(2));
      });

      test('adds zero', () {
        expect(calculator.add(5, 0), equals(5));
      });

      test('handles large numbers', () {
        expect(calculator.add(1e10, 1e10), equals(2e10));
      });
    });

    group('subtract', () {
      test('subtracts two positive numbers', () {
        expect(calculator.subtract(5, 3), equals(2));
      });

      test('subtracts resulting in negative', () {
        expect(calculator.subtract(3, 5), equals(-2));
      });
    });

    group('multiply', () {
      test('multiplies two positive numbers', () {
        expect(calculator.multiply(4, 3), equals(12));
      });

      test('multiplies with zero', () {
        expect(calculator.multiply(5, 0), equals(0));
      });

      test('multiplies negative numbers', () {
        expect(calculator.multiply(-2, -3), equals(6));
      });
    });

    group('divide', () {
      test('divides two numbers', () {
        expect(calculator.divide(6, 2), equals(3));
      });

      test('divides with decimal result', () {
        expect(calculator.divide(5, 2), equals(2.5));
      });

      test('throws when dividing by zero', () {
        expect(
          () => calculator.divide(5, 0),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            'Cannot divide by zero',
          )),
        );
      });
    });

    group('power', () {
      test('calculates power', () {
        expect(calculator.power(2, 3), equals(8));
      });

      test('power of zero', () {
        expect(calculator.power(5, 0), equals(1));
      });

      test('throws for negative exponent', () {
        expect(
          () => calculator.power(2, -1),
          throwsArgumentError,
        );
      });
    });
  });
}
```

---

## Aufgabe 2: Validator Tests

```dart
import 'package:test/test.dart';

class Validators {
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  static bool isValidPhone(String phone) {
    final regex = RegExp(r'^\+49\d{10,11}$');
    return regex.hasMatch(phone);
  }

  static bool isValidIBAN(String iban) {
    final cleaned = iban.replaceAll(' ', '').toUpperCase();
    if (cleaned.length < 15 || cleaned.length > 34) return false;
    if (!cleaned.startsWith(RegExp(r'^[A-Z]{2}'))) return false;
    return true;
  }
}

void main() {
  group('Validators', () {
    group('isValidEmail', () {
      test('accepts valid email', () {
        expect(Validators.isValidEmail('test@example.com'), isTrue);
        expect(Validators.isValidEmail('user.name@domain.co.uk'), isTrue);
      });

      test('rejects invalid email', () {
        expect(Validators.isValidEmail('invalid'), isFalse);
        expect(Validators.isValidEmail('test@'), isFalse);
        expect(Validators.isValidEmail('@domain.com'), isFalse);
      });

      test('rejects empty string', () {
        expect(Validators.isValidEmail(''), isFalse);
      });

      test('rejects whitespace only', () {
        expect(Validators.isValidEmail('   '), isFalse);
      });
    });

    group('isValidPassword', () {
      test('accepts valid password', () {
        expect(Validators.isValidPassword('Password1'), isTrue);
        expect(Validators.isValidPassword('MyP@ssw0rd'), isTrue);
      });

      test('rejects too short password', () {
        expect(Validators.isValidPassword('Pass1'), isFalse);
      });

      test('rejects password without uppercase', () {
        expect(Validators.isValidPassword('password1'), isFalse);
      });

      test('rejects password without digit', () {
        expect(Validators.isValidPassword('Password'), isFalse);
      });

      test('accepts exactly 8 characters', () {
        expect(Validators.isValidPassword('Passw0rd'), isTrue);
      });
    });

    group('isValidPhone', () {
      test('accepts valid German phone', () {
        expect(Validators.isValidPhone('+4917612345678'), isTrue);
      });

      test('rejects without country code', () {
        expect(Validators.isValidPhone('017612345678'), isFalse);
      });

      test('rejects wrong country code', () {
        expect(Validators.isValidPhone('+1234567890123'), isFalse);
      });
    });

    group('isValidIBAN', () {
      test('accepts valid IBAN', () {
        expect(Validators.isValidIBAN('DE89370400440532013000'), isTrue);
      });

      test('accepts IBAN with spaces', () {
        expect(Validators.isValidIBAN('DE89 3704 0044 0532 0130 00'), isTrue);
      });

      test('rejects too short IBAN', () {
        expect(Validators.isValidIBAN('DE8937040044'), isFalse);
      });
    });
  });
}
```

---

## Aufgabe 3: TDD - ShoppingCart

```dart
import 'package:test/test.dart';

// Model
class Product {
  final String id;
  final String name;
  final double price;

  Product({required this.id, required this.name, required this.price});
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

// Implementation (nach TDD entwickelt)
class ShoppingCart {
  final List<CartItem> _items = [];
  double _discountPercent = 0;

  List<CartItem> get items => List.unmodifiable(_items);

  void addProduct(Product product, [int quantity = 1]) {
    final existing = _items.where((i) => i.product.id == product.id).firstOrNull;
    if (existing != null) {
      existing.quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
  }

  void removeProduct(String productId) {
    _items.removeWhere((i) => i.product.id == productId);
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final item = _items.where((i) => i.product.id == productId).firstOrNull;
    item?.quantity = quantity;
  }

  void applyDiscount(double percent) {
    _discountPercent = percent.clamp(0, 100);
  }

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);

  double get discount => subtotal * (_discountPercent / 100);

  double get total => subtotal - discount;

  bool get meetsMinimumOrder => subtotal >= 10;

  double get shippingCost => subtotal >= 50 ? 0 : 4.99;

  double get grandTotal => total + shippingCost;
}

void main() {
  late ShoppingCart cart;
  late Product book;
  late Product pen;

  setUp(() {
    cart = ShoppingCart();
    book = Product(id: '1', name: 'Book', price: 20.0);
    pen = Product(id: '2', name: 'Pen', price: 5.0);
  });

  group('ShoppingCart', () {
    test('starts empty', () {
      expect(cart.items, isEmpty);
      expect(cart.subtotal, equals(0));
    });

    group('addProduct', () {
      test('adds product to cart', () {
        cart.addProduct(book);

        expect(cart.items, hasLength(1));
        expect(cart.items.first.product.name, equals('Book'));
      });

      test('increases quantity for existing product', () {
        cart.addProduct(book);
        cart.addProduct(book);

        expect(cart.items, hasLength(1));
        expect(cart.items.first.quantity, equals(2));
      });

      test('adds with custom quantity', () {
        cart.addProduct(book, 3);

        expect(cart.items.first.quantity, equals(3));
      });
    });

    group('removeProduct', () {
      test('removes product from cart', () {
        cart.addProduct(book);
        cart.removeProduct('1');

        expect(cart.items, isEmpty);
      });

      test('does nothing for non-existent product', () {
        cart.addProduct(book);
        cart.removeProduct('999');

        expect(cart.items, hasLength(1));
      });
    });

    group('updateQuantity', () {
      test('updates quantity', () {
        cart.addProduct(book);
        cart.updateQuantity('1', 5);

        expect(cart.items.first.quantity, equals(5));
      });

      test('removes product when quantity is 0', () {
        cart.addProduct(book);
        cart.updateQuantity('1', 0);

        expect(cart.items, isEmpty);
      });
    });

    group('pricing', () {
      test('calculates subtotal', () {
        cart.addProduct(book);
        cart.addProduct(pen, 2);

        expect(cart.subtotal, equals(30.0));  // 20 + 2*5
      });

      test('applies discount', () {
        cart.addProduct(book);  // 20.0
        cart.applyDiscount(10);  // 10%

        expect(cart.discount, equals(2.0));
        expect(cart.total, equals(18.0));
      });

      test('clamps discount to valid range', () {
        cart.addProduct(book);
        cart.applyDiscount(150);  // Over 100%

        expect(cart.total, equals(0));  // Clamped to 100%
      });
    });

    group('minimumOrder', () {
      test('returns false below minimum', () {
        cart.addProduct(pen);  // 5.0

        expect(cart.meetsMinimumOrder, isFalse);
      });

      test('returns true at minimum', () {
        cart.addProduct(pen, 2);  // 10.0

        expect(cart.meetsMinimumOrder, isTrue);
      });
    });

    group('shipping', () {
      test('charges shipping below 50', () {
        cart.addProduct(book);  // 20.0

        expect(cart.shippingCost, equals(4.99));
      });

      test('free shipping at 50 or above', () {
        cart.addProduct(book, 3);  // 60.0

        expect(cart.shippingCost, equals(0));
      });

      test('calculates grand total', () {
        cart.addProduct(book);  // 20.0

        expect(cart.grandTotal, equals(24.99));  // 20 + 4.99
      });
    });
  });
}
```

---

## Aufgabe 4: Async Tests

```dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class HttpResponse {
  final int statusCode;
  final String body;
  HttpResponse(this.statusCode, this.body);
}

abstract class HttpClient {
  Future<HttpResponse> get(String url);
}

class Weather {
  final String city;
  final double temperature;

  Weather({required this.city, required this.temperature});

  factory Weather.fromJson(String json) {
    return Weather(city: 'Berlin', temperature: 20.0);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
}

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
}

class MockHttpClient extends Mock implements HttpClient {}

void main() {
  late MockHttpClient mockClient;
  late WeatherService service;

  setUp(() {
    mockClient = MockHttpClient();
    service = WeatherService(mockClient);
  });

  group('WeatherService', () {
    group('fetchWeather', () {
      test('returns weather on success', () async {
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => HttpResponse(200, '{"city":"Berlin","temp":20}'),
        );

        final weather = await service.fetchWeather('Berlin');

        expect(weather.city, equals('Berlin'));
        verify(() => mockClient.get('api/weather/Berlin')).called(1);
      });

      test('throws ApiException on error', () async {
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => HttpResponse(500, 'Server Error'),
        );

        expect(
          () => service.fetchWeather('Berlin'),
          throwsA(isA<ApiException>()),
        );
      });

      test('completes successfully', () {
        when(() => mockClient.get(any())).thenAnswer(
          (_) async => HttpResponse(200, '{}'),
        );

        expect(service.fetchWeather('Berlin'), completes);
      });
    });
  });
}
```

---

## Aufgabe 5: Mocking AuthService

```dart
import 'package:test/test.dart';
import 'package:mocktail/mocktail.dart';

class User {
  final String id;
  final String email;
  final String token;

  User({required this.id, required this.email, required this.token});
}

abstract class AuthRepository {
  Future<User?> signIn(String email, String password);
  Future<void> signOut();
}

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
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

class MockAuthRepository extends Mock implements AuthRepository {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late MockAuthRepository mockRepository;
  late MockTokenStorage mockStorage;
  late AuthService authService;

  setUp(() {
    mockRepository = MockAuthRepository();
    mockStorage = MockTokenStorage();
    authService = AuthService(mockRepository, mockStorage);
  });

  group('AuthService', () {
    group('login', () {
      test('saves token on successful login', () async {
        final user = User(id: '1', email: 'test@test.com', token: 'abc123');
        when(() => mockRepository.signIn(any(), any()))
            .thenAnswer((_) async => user);
        when(() => mockStorage.saveToken(any()))
            .thenAnswer((_) async {});

        final result = await authService.login('test@test.com', 'password');

        expect(result.email, equals('test@test.com'));
        verify(() => mockStorage.saveToken('abc123')).called(1);
      });

      test('throws AuthException on invalid credentials', () async {
        when(() => mockRepository.signIn(any(), any()))
            .thenAnswer((_) async => null);

        expect(
          () => authService.login('test@test.com', 'wrong'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          )),
        );

        verifyNever(() => mockStorage.saveToken(any()));
      });
    });

    group('logout', () {
      test('signs out and deletes token', () async {
        when(() => mockRepository.signOut()).thenAnswer((_) async {});
        when(() => mockStorage.deleteToken()).thenAnswer((_) async {});

        await authService.logout();

        verifyInOrder([
          () => mockRepository.signOut(),
          () => mockStorage.deleteToken(),
        ]);
      });
    });

    group('isLoggedIn', () {
      test('returns true when token exists', () async {
        when(() => mockStorage.getToken()).thenAnswer((_) async => 'token');

        final result = await authService.isLoggedIn();

        expect(result, isTrue);
      });

      test('returns false when no token', () async {
        when(() => mockStorage.getToken()).thenAnswer((_) async => null);

        final result = await authService.isLoggedIn();

        expect(result, isFalse);
      });
    });
  });
}
```

---

## Aufgabe 6: Exception Tests

```dart
import 'package:test/test.dart';

class User {
  final String name;
  final int age;

  User({required this.name, required this.age});
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

void main() {
  late UserService service;

  setUp(() {
    service = UserService();
  });

  group('UserService.validateUser', () {
    test('throws ValidationException for empty name', () {
      final user = User(name: '', age: 25);

      expect(
        () => service.validateUser(user),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.message, 'message', 'Name required')
              .having((e) => e.field, 'field', 'name'),
        ),
      );
    });

    test('throws ValidationException for negative age', () {
      final user = User(name: 'John', age: -1);

      expect(
        () => service.validateUser(user),
        throwsA(
          isA<ValidationException>()
              .having((e) => e.field, 'field', 'age'),
        ),
      );
    });

    test('throws UnderageException for age under 18', () {
      final user = User(name: 'John', age: 16);

      expect(
        () => service.validateUser(user),
        throwsA(
          isA<UnderageException>()
              .having((e) => e.age, 'age', 16),
        ),
      );
    });

    test('does not throw for valid user', () {
      final user = User(name: 'John', age: 25);

      expect(() => service.validateUser(user), returnsNormally);
    });

    test('validates exactly 18 years old', () {
      final user = User(name: 'John', age: 18);

      expect(() => service.validateUser(user), returnsNormally);
    });
  });
}
```

---

## Aufgabe 8: 100% Coverage

```dart
import 'package:test/test.dart';

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
      price *= 0.95;
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

void main() {
  late PriceCalculator calculator;

  setUp(() {
    calculator = PriceCalculator();
  });

  group('PriceCalculator', () {
    test('calculates base price', () {
      final price = calculator.calculatePrice(basePrice: 100);
      expect(price, equals(100));
    });

    test('multiplies by quantity', () {
      final price = calculator.calculatePrice(basePrice: 10, quantity: 5);
      expect(price, equals(50));
    });

    test('applies discount percent', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        discountPercent: 20,
      );
      expect(price, equals(80));
    });

    test('ignores null discount', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        discountPercent: null,
      );
      expect(price, equals(100));
    });

    test('ignores zero discount', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        discountPercent: 0,
      );
      expect(price, equals(100));
    });

    test('applies member discount', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        isMember: true,
      );
      expect(price, equals(95));
    });

    test('applies SAVE10 coupon', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        couponCode: 'SAVE10',
      );
      expect(price, equals(90));
    });

    test('applies HALF coupon', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        couponCode: 'HALF',
      );
      expect(price, equals(50));
    });

    test('applies FREE coupon', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        couponCode: 'FREE',
      );
      expect(price, equals(0));
    });

    test('ignores unknown coupon', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        couponCode: 'INVALID',
      );
      expect(price, equals(100));
    });

    test('returns 0 for negative result', () {
      final price = calculator.calculatePrice(
        basePrice: 5,
        couponCode: 'SAVE10',
      );
      expect(price, equals(0));
    });

    test('combines all discounts', () {
      final price = calculator.calculatePrice(
        basePrice: 100,
        quantity: 2,
        discountPercent: 10,
        isMember: true,
        couponCode: 'SAVE10',
      );
      // 200 - 20 (10%) = 180
      // 180 * 0.95 (member) = 171
      // 171 - 10 (coupon) = 161
      expect(price, equals(161));
    });
  });
}
```
