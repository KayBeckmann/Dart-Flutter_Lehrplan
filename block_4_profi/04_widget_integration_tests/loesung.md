# Lösung 4.4: Widget & Integration Tests

## Aufgabe 1: Counter Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class CounterWidget extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final void Function(int)? onChanged;

  const CounterWidget({
    super.key,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue = 100,
    this.onChanged,
  });

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  late int _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _increment() {
    if (_value < widget.maxValue) {
      setState(() => _value++);
      widget.onChanged?.call(_value);
    }
  }

  void _decrement() {
    if (_value > widget.minValue) {
      setState(() => _value--);
      widget.onChanged?.call(_value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('decrement'),
          icon: const Icon(Icons.remove),
          onPressed: _value > widget.minValue ? _decrement : null,
        ),
        Text('$_value', key: const Key('value')),
        IconButton(
          key: const Key('increment'),
          icon: const Icon(Icons.add),
          onPressed: _value < widget.maxValue ? _increment : null,
        ),
      ],
    );
  }
}

void main() {
  group('CounterWidget', () {
    testWidgets('displays initial value', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CounterWidget(initialValue: 5),
      ));

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('increments value on tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CounterWidget(),
      ));

      expect(find.text('0'), findsOneWidget);

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('decrements value on tap', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CounterWidget(initialValue: 5),
      ));

      await tester.tap(find.byKey(const Key('decrement')));
      await tester.pump();

      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('respects maxValue', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CounterWidget(initialValue: 10, maxValue: 10),
      ));

      // Increment button sollte deaktiviert sein
      final incrementButton = tester.widget<IconButton>(
        find.byKey(const Key('increment')),
      );
      expect(incrementButton.onPressed, isNull);
    });

    testWidgets('respects minValue', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CounterWidget(initialValue: 0, minValue: 0),
      ));

      final decrementButton = tester.widget<IconButton>(
        find.byKey(const Key('decrement')),
      );
      expect(decrementButton.onPressed, isNull);
    });

    testWidgets('calls onChanged callback', (tester) async {
      int? changedValue;
      await tester.pumpWidget(MaterialApp(
        home: CounterWidget(
          onChanged: (value) => changedValue = value,
        ),
      ));

      await tester.tap(find.byKey(const Key('increment')));
      await tester.pump();

      expect(changedValue, equals(1));
    });
  });
}
```

---

## Aufgabe 2: Form Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegistrationForm', () {
    Widget createWidget({VoidCallback? onSubmit}) {
      return MaterialApp(
        home: Scaffold(
          body: RegistrationForm(onSubmit: onSubmit ?? () {}),
        ),
      );
    }

    testWidgets('renders all fields', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.byKey(const Key('name_field')), findsOneWidget);
      expect(find.byKey(const Key('email_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
      expect(find.byKey(const Key('confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('terms_checkbox')), findsOneWidget);
      expect(find.text('Registrieren'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Registrieren'));
      await tester.pump();

      expect(find.text('Name ist erforderlich'), findsOneWidget);
      expect(find.text('Email ist erforderlich'), findsOneWidget);
      expect(find.text('Passwort ist erforderlich'), findsOneWidget);
    });

    testWidgets('validates email format', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'invalid-email',
      );
      await tester.tap(find.text('Registrieren'));
      await tester.pump();

      expect(find.text('Ungültige Email'), findsOneWidget);
    });

    testWidgets('validates password match', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'different',
      );
      await tester.tap(find.text('Registrieren'));
      await tester.pump();

      expect(find.text('Passwörter stimmen nicht überein'), findsOneWidget);
    });

    testWidgets('requires terms acceptance', (tester) async {
      await tester.pumpWidget(createWidget());

      // Fülle alle Felder korrekt aus
      await tester.enterText(find.byKey(const Key('name_field')), 'John');
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'john@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'password123',
      );

      await tester.tap(find.text('Registrieren'));
      await tester.pump();

      expect(find.text('AGB müssen akzeptiert werden'), findsOneWidget);
    });

    testWidgets('submits valid form', (tester) async {
      bool submitted = false;
      await tester.pumpWidget(createWidget(onSubmit: () => submitted = true));

      await tester.enterText(find.byKey(const Key('name_field')), 'John');
      await tester.enterText(
        find.byKey(const Key('email_field')),
        'john@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.enterText(
        find.byKey(const Key('confirm_password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('terms_checkbox')));
      await tester.pump();

      await tester.tap(find.text('Registrieren'));
      await tester.pumpAndSettle();

      expect(submitted, isTrue);
    });
  });
}
```

---

## Aufgabe 3: Todo-Liste Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TodoList', () {
    testWidgets('displays todos', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TodoListScreen(
          initialTodos: [
            Todo(id: '1', title: 'Task 1'),
            Todo(id: '2', title: 'Task 2'),
          ],
        ),
      ));

      expect(find.text('Task 1'), findsOneWidget);
      expect(find.text('Task 2'), findsOneWidget);
    });

    testWidgets('toggles checkbox', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TodoListScreen(
          initialTodos: [Todo(id: '1', title: 'Task 1')],
        ),
      ));

      // Initial unchecked
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      // Toggle
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Now checked
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('deletes todo on swipe', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TodoListScreen(
          initialTodos: [Todo(id: '1', title: 'Task 1')],
        ),
      ));

      expect(find.text('Task 1'), findsOneWidget);

      // Swipe to delete
      await tester.drag(find.text('Task 1'), const Offset(500, 0));
      await tester.pumpAndSettle();

      expect(find.text('Task 1'), findsNothing);
    });

    testWidgets('adds new todo via dialog', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TodoListScreen(initialTodos: []),
      ));

      // Open dialog
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Enter todo
      await tester.enterText(find.byType(TextField), 'New Task');
      await tester.tap(find.text('Hinzufügen'));
      await tester.pumpAndSettle();

      expect(find.text('New Task'), findsOneWidget);
    });

    testWidgets('filters todos', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: TodoListScreen(
          initialTodos: [
            Todo(id: '1', title: 'Open Task', isDone: false),
            Todo(id: '2', title: 'Done Task', isDone: true),
          ],
        ),
      ));

      // Default: All
      expect(find.text('Open Task'), findsOneWidget);
      expect(find.text('Done Task'), findsOneWidget);

      // Filter: Open
      await tester.tap(find.text('Offen'));
      await tester.pump();

      expect(find.text('Open Task'), findsOneWidget);
      expect(find.text('Done Task'), findsNothing);

      // Filter: Done
      await tester.tap(find.text('Erledigt'));
      await tester.pump();

      expect(find.text('Open Task'), findsNothing);
      expect(find.text('Done Task'), findsOneWidget);
    });
  });
}
```

---

## Aufgabe 4: Navigation Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Navigation', () {
    Widget createApp() {
      return MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/detail': (context) => const DetailScreen(),
          '/edit': (context) => const EditScreen(),
          '/settings': (context) => const SettingsScreen(),
        },
      );
    }

    testWidgets('navigates to detail on item tap', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      expect(find.byType(DetailScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('navigates back from detail', (tester) async {
      await tester.pumpWidget(createApp());

      // Go to detail
      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      // Go back
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('navigates to edit with data', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      expect(find.byType(EditScreen), findsOneWidget);
      // Verify data was passed
      expect(find.text('Editing: Item 1'), findsOneWidget);
    });

    testWidgets('receives result from edit screen', (tester) async {
      await tester.pumpWidget(createApp());

      await tester.tap(find.text('Item 1'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Edit and save
      await tester.enterText(find.byType(TextField), 'Updated Item');
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Back on detail with updated data
      expect(find.byType(DetailScreen), findsOneWidget);
      expect(find.text('Updated Item'), findsOneWidget);
    });

    testWidgets('opens drawer and navigates to settings', (tester) async {
      await tester.pumpWidget(createApp());

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(Drawer), findsOneWidget);

      // Navigate to settings
      await tester.tap(find.text('Einstellungen'));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
```

---

## Aufgabe 5: Async Widget Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class User {
  final String name;
  final String email;
  User({required this.name, required this.email});
}

abstract class UserRepository {
  Future<User> getCurrentUser();
}

class MockUserRepository extends Mock implements UserRepository {}

void main() {
  late MockUserRepository mockRepository;

  setUp(() {
    mockRepository = MockUserRepository();
  });

  group('UserProfile', () {
    testWidgets('shows loading state', (tester) async {
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) => Future.delayed(
          const Duration(seconds: 1),
          () => User(name: 'John', email: 'john@test.com'),
        ),
      );

      await tester.pumpWidget(MaterialApp(
        home: UserProfile(repository: mockRepository),
      ));

      // Loading indicator visible
      expect(find.byKey(const Key('loading')), findsOneWidget);
    });

    testWidgets('shows user data after loading', (tester) async {
      when(() => mockRepository.getCurrentUser()).thenAnswer(
        (_) async => User(name: 'John Doe', email: 'john@example.com'),
      );

      await tester.pumpWidget(MaterialApp(
        home: UserProfile(repository: mockRepository),
      ));

      // Wait for future
      await tester.pumpAndSettle();

      // Data displayed
      expect(find.byKey(const Key('name')), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.byKey(const Key('loading')), findsNothing);
    });

    testWidgets('shows error on exception', (tester) async {
      when(() => mockRepository.getCurrentUser())
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(MaterialApp(
        home: UserProfile(repository: mockRepository),
      ));

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error')), findsOneWidget);
      expect(find.textContaining('Network error'), findsOneWidget);
    });
  });
}
```

---

## Aufgabe 6: Golden Tests

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Golden Tests', () {
    testWidgets('ProductCard matches golden', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(400, 250);
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProductCard(
              title: 'Flutter Book',
              price: 29.99,
              imageUrl: 'assets/book.png',
            ),
          ),
        ),
      ));

      await expectLater(
        find.byType(ProductCard),
        matchesGoldenFile('goldens/product_card.png'),
      );

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('RatingStars matches golden for each rating', (tester) async {
      for (int rating = 0; rating <= 5; rating++) {
        tester.binding.window.physicalSizeTestValue = const Size(200, 50);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: RatingStars(rating: rating),
            ),
          ),
        ));

        await expectLater(
          find.byType(RatingStars),
          matchesGoldenFile('goldens/rating_stars_$rating.png'),
        );
      }

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });

    testWidgets('StatusBadge matches golden for each status', (tester) async {
      final statuses = ['success', 'warning', 'error'];

      for (final status in statuses) {
        tester.binding.window.physicalSizeTestValue = const Size(150, 50);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatusBadge(status: status),
            ),
          ),
        ));

        await expectLater(
          find.byType(StatusBadge),
          matchesGoldenFile('goldens/status_badge_$status.png'),
        );
      }

      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
    });
  });
}
```

---

## Aufgabe 7: Integration Test

```dart
// integration_test/shopping_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Shopping Flow', () {
    testWidgets('add product to cart', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. Verify Home Screen
      expect(find.text('Home'), findsOneWidget);

      // 2. Search for product
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        'Flutter Book',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // 3. Verify search results
      expect(find.text('Flutter Book'), findsOneWidget);

      // 4. Navigate to detail
      await tester.tap(find.text('Flutter Book'));
      await tester.pumpAndSettle();

      expect(find.text('Produktdetails'), findsOneWidget);

      // 5. Select quantity
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      // 6. Add to cart
      await tester.tap(find.text('In den Warenkorb'));
      await tester.pump();

      // 7. Verify snackbar
      expect(find.text('Zum Warenkorb hinzugefügt'), findsOneWidget);

      // 8. Navigate to cart
      await tester.tap(find.byIcon(Icons.shopping_cart));
      await tester.pumpAndSettle();

      // 9. Verify product in cart
      expect(find.text('Warenkorb'), findsOneWidget);
      expect(find.text('Flutter Book'), findsOneWidget);
      expect(find.text('Menge: 2'), findsOneWidget);
    });
  });
}
```

---

## Aufgabe 8: Bonus - Custom Finder

```dart
// test/helpers/custom_finders.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension CustomFinders on CommonFinders {
  /// Findet ein Formularfeld anhand seines Labels
  Finder fieldByLabel(String label) {
    return find.ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (widget) => widget is TextField || widget is TextFormField,
      ),
    );
  }

  /// Findet eine Card mit einem bestimmten Titel
  Finder cardWithTitle(String title) {
    return find.ancestor(
      of: find.text(title),
      matching: find.byType(Card),
    );
  }

  /// Findet einen Button mit Icon und Text
  Finder buttonWithIconAndText(IconData icon, String text) {
    return find.byWidgetPredicate((widget) {
      if (widget is ElevatedButton || widget is TextButton) {
        final buttonChild = (widget as dynamic).child;
        if (buttonChild is Row) {
          final hasIcon = buttonChild.children.any(
            (child) => child is Icon && child.icon == icon,
          );
          final hasText = buttonChild.children.any(
            (child) => child is Text && child.data == text,
          );
          return hasIcon && hasText;
        }
      }
      return false;
    });
  }

  /// Findet ein ListTile mit einem bestimmten Subtitle
  Finder listTileWithSubtitle(String subtitle) {
    return find.byWidgetPredicate((widget) {
      if (widget is ListTile && widget.subtitle is Text) {
        return (widget.subtitle as Text).data == subtitle;
      }
      return false;
    });
  }
}

// Verwendung in Tests
void main() {
  testWidgets('uses custom finders', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MyWidget()));

    // Formularfeld finden
    await tester.enterText(find.fieldByLabel('Email'), 'test@test.com');

    // Card mit Titel finden
    expect(find.cardWithTitle('Produkt A'), findsOneWidget);

    // Button mit Icon und Text
    await tester.tap(find.buttonWithIconAndText(Icons.save, 'Speichern'));

    // ListTile mit Subtitle
    expect(find.listTileWithSubtitle('Details'), findsOneWidget);
  });
}
```
