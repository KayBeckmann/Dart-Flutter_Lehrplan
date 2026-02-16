# Einheit 4.4: Widget & Integration Tests

## Lernziele

Nach dieser Einheit kannst du:
- Widget Tests mit `flutter_test` schreiben
- `WidgetTester` und Finder verwenden
- Integration Tests erstellen
- Code Coverage analysieren

---

## 1. Widget Test Grundlagen

### Setup

```yaml
# pubspec.yaml (bereits enthalten)
dev_dependencies:
  flutter_test:
    sdk: flutter
```

### Erster Widget Test

```dart
// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/counter_widget.dart';

void main() {
  testWidgets('Counter increments', (WidgetTester tester) async {
    // Widget aufbauen
    await tester.pumpWidget(const MaterialApp(
      home: CounterWidget(),
    ));

    // Initialen Zustand prüfen
    expect(find.text('0'), findsOneWidget);

    // Button drücken
    await tester.tap(find.byIcon(Icons.add));

    // Frame rebuilden
    await tester.pump();

    // Neuen Zustand prüfen
    expect(find.text('1'), findsOneWidget);
  });
}
```

### pump vs pumpAndSettle

```dart
// pump() - Ein einzelner Frame
await tester.pump();

// pump(duration) - Ein Frame nach Duration
await tester.pump(const Duration(milliseconds: 100));

// pumpAndSettle() - Alle Frames bis keine Animationen mehr laufen
await tester.pumpAndSettle();

// pumpAndSettle mit Timeout
await tester.pumpAndSettle(const Duration(seconds: 5));
```

---

## 2. Finder

### Text finden

```dart
// Exakter Text
find.text('Hello')

// Text enthält
find.textContaining('Hello')

// Mit Regex
find.textContaining(RegExp(r'Hello \w+'))

// Rich Text
find.richText('Hello')
```

### Widget-Typen finden

```dart
// Nach Typ
find.byType(ElevatedButton)
find.byType(TextField)
find.byType(CircularProgressIndicator)

// Nach Subtyp
find.bySubtype<StatelessWidget>()
```

### Icons und Keys finden

```dart
// Icon
find.byIcon(Icons.add)
find.byIcon(Icons.delete)

// Key
find.byKey(const Key('submit_button'))
find.byKey(const ValueKey('item_1'))
```

### Widgets finden

```dart
// Nach Widget-Instanz
find.byWidget(myWidget)

// Nach Semantics Label
find.bySemanticsLabel('Add item')

// Nach Tooltip
find.byTooltip('Delete')
```

### Kombinierte Finder

```dart
// Descendant (Kind von)
find.descendant(
  of: find.byType(Card),
  matching: find.text('Title'),
)

// Ancestor (Eltern von)
find.ancestor(
  of: find.text('Title'),
  matching: find.byType(ListTile),
)

// Erstes/Letztes von mehreren
find.byType(ListTile).first
find.byType(ListTile).last
find.byType(ListTile).at(2)
```

### Finder Matchers

```dart
// Genau ein Widget
expect(find.text('Hello'), findsOneWidget);

// Kein Widget
expect(find.text('Error'), findsNothing);

// Mindestens ein Widget
expect(find.byType(ListTile), findsWidgets);

// Genau N Widgets
expect(find.byType(ListTile), findsNWidgets(3));

// Mindestens N Widgets
expect(find.byType(ListTile), findsAtLeastNWidgets(2));
```

---

## 3. Interaktionen

### Tap

```dart
// Einfacher Tap
await tester.tap(find.byType(ElevatedButton));
await tester.pump();

// Tap an Position
await tester.tapAt(const Offset(100, 200));

// Double Tap
await tester.tap(find.text('Item'));
await tester.pump(const Duration(milliseconds: 100));
await tester.tap(find.text('Item'));

// Long Press
await tester.longPress(find.text('Item'));
await tester.pump();
```

### Text eingeben

```dart
// Text eingeben
await tester.enterText(find.byType(TextField), 'Hello World');
await tester.pump();

// Text in bestimmtes Feld
await tester.enterText(
  find.byKey(const Key('email_field')),
  'test@example.com',
);
```

### Scrollen

```dart
// Drag/Scroll
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.pumpAndSettle();

// Fling (schnelles Scrollen)
await tester.fling(find.byType(ListView), const Offset(0, -500), 1000);
await tester.pumpAndSettle();

// Zu Widget scrollen
await tester.scrollUntilVisible(
  find.text('Item 50'),
  500.0,
  scrollable: find.byType(Scrollable),
);
```

### Gesten

```dart
// Swipe
await tester.drag(find.byType(Dismissible), const Offset(500, 0));
await tester.pumpAndSettle();

// Pinch/Zoom (zwei Finger)
final center = tester.getCenter(find.byType(InteractiveViewer));
await tester.startGesture(center - const Offset(50, 0));
final gesture2 = await tester.startGesture(center + const Offset(50, 0));
await gesture2.moveBy(const Offset(50, 0));
await tester.pumpAndSettle();
```

---

## 4. Widget-State prüfen

### State auslesen

```dart
// State eines StatefulWidget
final state = tester.state<CounterWidgetState>(find.byType(CounterWidget));
expect(state.counter, equals(5));

// Widget-Properties
final widget = tester.widget<Text>(find.text('Hello'));
expect(widget.style?.color, equals(Colors.red));

// Element
final element = tester.element(find.byType(MyWidget));
```

### Form-Werte prüfen

```dart
testWidgets('form validation', (tester) async {
  await tester.pumpWidget(MaterialApp(home: MyForm()));

  // Leeres Feld submitten
  await tester.tap(find.text('Submit'));
  await tester.pump();

  // Fehlermeldung prüfen
  expect(find.text('Required field'), findsOneWidget);

  // Wert eingeben
  await tester.enterText(find.byType(TextField), 'test@email.com');
  await tester.tap(find.text('Submit'));
  await tester.pump();

  // Keine Fehlermeldung mehr
  expect(find.text('Required field'), findsNothing);
});
```

### Checkbox/Switch prüfen

```dart
// Checkbox-Wert
final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
expect(checkbox.value, isTrue);

// Switch-Wert
final switchWidget = tester.widget<Switch>(find.byType(Switch));
expect(switchWidget.value, isFalse);
```

---

## 5. Async und Loading States

### FutureBuilder testen

```dart
testWidgets('shows loading then data', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: FutureBuilder<String>(
      future: Future.delayed(
        const Duration(seconds: 1),
        () => 'Data loaded',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        return Text(snapshot.data ?? '');
      },
    ),
  ));

  // Loading State
  expect(find.byType(CircularProgressIndicator), findsOneWidget);

  // Zeit vorspulen
  await tester.pump(const Duration(seconds: 1));

  // Daten angezeigt
  expect(find.text('Data loaded'), findsOneWidget);
  expect(find.byType(CircularProgressIndicator), findsNothing);
});
```

### Mit Mocks

```dart
class MockApiService extends Mock implements ApiService {}

testWidgets('displays user list', (tester) async {
  final mockService = MockApiService();
  when(() => mockService.getUsers()).thenAnswer(
    (_) async => [User(name: 'John'), User(name: 'Jane')],
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Provider<ApiService>.value(
        value: mockService,
        child: const UserListScreen(),
      ),
    ),
  );

  // Warte auf Future
  await tester.pumpAndSettle();

  expect(find.text('John'), findsOneWidget);
  expect(find.text('Jane'), findsOneWidget);
});
```

---

## 6. Navigation testen

### Navigator.push

```dart
testWidgets('navigates to detail screen', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: const HomeScreen(),
    routes: {
      '/detail': (context) => const DetailScreen(),
    },
  ));

  // Tap auf Item
  await tester.tap(find.text('View Details'));
  await tester.pumpAndSettle();

  // Prüfe Navigation
  expect(find.byType(DetailScreen), findsOneWidget);
  expect(find.byType(HomeScreen), findsNothing);
});
```

### Navigator.pop mit Ergebnis

```dart
testWidgets('returns result from dialog', (tester) async {
  String? result;

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => SelectionScreen(),
            ),
          );
        },
        child: const Text('Open'),
      ),
    ),
  ));

  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  await tester.tap(find.text('Option A'));
  await tester.pumpAndSettle();

  expect(result, equals('Option A'));
});
```

---

## 7. Golden Tests

### Snapshot-Vergleiche

```dart
testWidgets('matches golden file', (tester) async {
  await tester.pumpWidget(const MaterialApp(
    home: MyWidget(),
  ));

  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget.png'),
  );
});
```

### Golden Tests ausführen

```bash
# Goldens erstellen/aktualisieren
flutter test --update-goldens

# Goldens prüfen
flutter test
```

### Best Practices für Goldens

```dart
testWidgets('card golden test', (tester) async {
  // Feste Größe für konsistente Screenshots
  tester.binding.window.physicalSizeTestValue = const Size(400, 300);
  tester.binding.window.devicePixelRatioTestValue = 1.0;

  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(
      body: Center(child: ProductCard()),
    ),
  ));

  await expectLater(
    find.byType(ProductCard),
    matchesGoldenFile('goldens/product_card.png'),
  );

  // Cleanup
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
});
```

---

## 8. Integration Tests

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

### Test erstellen

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('complete user flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(
        find.byKey(const Key('email')),
        'test@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('password')),
        'password123',
      );
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Verify home screen
      expect(find.text('Welcome'), findsOneWidget);

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text('test@example.com'), findsOneWidget);
    });
  });
}
```

### Integration Tests ausführen

```bash
# Auf verbundenem Gerät/Emulator
flutter test integration_test/app_test.dart

# Auf spezifischem Gerät
flutter test integration_test/app_test.dart -d <device_id>

# Mit Screenshot bei Fehler
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

---

## 9. Code Coverage

### Coverage generieren

```bash
# Tests mit Coverage
flutter test --coverage

# HTML-Report erstellen (benötigt lcov)
genhtml coverage/lcov.info -o coverage/html

# Report öffnen
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### Coverage in CI

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
      - uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

### Minimum Coverage erzwingen

```dart
// test/coverage_test.dart
import 'dart:io';

void main() {
  test('coverage is above threshold', () {
    final lcov = File('coverage/lcov.info').readAsStringSync();
    final lines = lcov.split('\n');

    int linesFound = 0;
    int linesHit = 0;

    for (final line in lines) {
      if (line.startsWith('LF:')) {
        linesFound += int.parse(line.substring(3));
      }
      if (line.startsWith('LH:')) {
        linesHit += int.parse(line.substring(3));
      }
    }

    final coverage = linesHit / linesFound * 100;
    expect(coverage, greaterThanOrEqualTo(80));
  });
}
```

---

## 10. Praktisches Beispiel: Login Screen Tests

```dart
// lib/screens/login_screen.dart
class LoginScreen extends StatefulWidget {
  final AuthService authService;

  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.authService.login(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                key: const Key('email_field'),
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    v?.contains('@') == true ? null : 'Invalid email',
              ),
              TextFormField(
                key: const Key('password_field'),
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      key: const Key('login_button'),
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// test/screens/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthService extends Mock implements AuthService {}
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  late MockAuthService mockAuthService;
  late MockNavigatorObserver mockObserver;

  setUp(() {
    mockAuthService = MockAuthService();
    mockObserver = MockNavigatorObserver();
  });

  Widget createWidget() {
    return MaterialApp(
      home: LoginScreen(authService: mockAuthService),
      routes: {
        '/home': (context) => const Scaffold(body: Text('Home')),
      },
      navigatorObservers: [mockObserver],
    );
  }

  group('LoginScreen', () {
    testWidgets('renders login form', (tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('shows validation errors', (tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.text('Invalid email'), findsOneWidget);
      expect(find.text('Min 6 characters'), findsOneWidget);
    });

    testWidgets('shows loading indicator during login', (tester) async {
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) => Future.delayed(const Duration(seconds: 1)));

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('navigates to home on success', (tester) async {
      when(() => mockAuthService.login(any(), any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'password123',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('shows error on failed login', (tester) async {
      when(() => mockAuthService.login(any(), any()))
          .thenThrow(Exception('Invalid credentials'));

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.byKey(const Key('email_field')),
        'test@test.com',
      );
      await tester.enterText(
        find.byKey(const Key('password_field')),
        'wrongpassword',
      );
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });
  });
}
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| `testWidgets` | Widget Test definieren |
| `pumpWidget` | Widget aufbauen |
| `pump` | Einen Frame rendern |
| `pumpAndSettle` | Alle Animationen abwarten |
| `find.text()` | Text-Finder |
| `find.byType()` | Typ-Finder |
| `find.byKey()` | Key-Finder |
| `findsOneWidget` | Genau ein Match |
| `tester.tap()` | Tap simulieren |
| `tester.enterText()` | Text eingeben |
| `matchesGoldenFile` | Screenshot-Vergleich |
| Integration Tests | End-to-End Tests |

**Best Practices:**
- Keys für wichtige Widgets verwenden
- Mocks für externe Abhängigkeiten
- `pumpAndSettle` für Animationen
- Golden Tests für UI-Regression
- CI-Integration für automatische Tests
