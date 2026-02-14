# Modul 14: Testing in Flutter

## 14.1 Warum testen?

Tests sind kein "Nice-to-have" -- sie sind ein fundamentaler Bestandteil professioneller Softwareentwicklung. Sie geben dir:

- **Sicherheit beim Refactoring:** Du kannst Code ändern und sofort sehen, ob etwas kaputt gegangen ist.
- **Dokumentation:** Tests beschreiben, was der Code tun soll -- sie sind lebende Dokumentation.
- **Schnelleres Debugging:** Wenn ein Test fehlschlägt, weißt du genau, wo das Problem liegt.
- **Besseres Design:** Testbarer Code ist in der Regel besser strukturiert (lose Kopplung, klare Verantwortlichkeiten).

### Die Test-Pyramide

```
        ╱╲
       ╱  ╲          Integration Tests
      ╱    ╲         (wenige, langsam, teuer)
     ╱──────╲        Testen das Zusammenspiel auf echtem Gerät
    ╱        ╲
   ╱  Widget  ╲      Widget Tests
  ╱   Tests    ╲     (mittel, mittelschnell)
 ╱──────────────╲    Testen einzelne Widgets mit Interaktion
╱                ╲
╱   Unit Tests    ╲   Unit Tests
╱──────────────────╲  (viele, schnell, günstig)
                       Testen einzelne Funktionen/Klassen
```

| Testtyp | Geschwindigkeit | Zuverlässigkeit | Wartungsaufwand | Abdeckung |
|---------|----------------|-----------------|-----------------|-----------|
| **Unit Tests** | Sehr schnell (ms) | Hoch | Niedrig | Einzelne Funktionen |
| **Widget Tests** | Schnell (ms-s) | Hoch | Mittel | Widget-Verhalten |
| **Integration Tests** | Langsam (Minuten) | Mittel | Hoch | Ganze App-Flows |

**Faustregel:** 70% Unit Tests, 20% Widget Tests, 10% Integration Tests.

**Vergleich zu anderen Sprachen:**

| Konzept | Flutter/Dart | JavaScript | Python | C++ |
|---------|-------------|------------|--------|-----|
| Test-Framework | `test` / `flutter_test` | Jest / Vitest | pytest / unittest | Google Test / Catch2 |
| Mocking | `mocktail` / `mockito` | jest.mock() | unittest.mock | Google Mock |
| Widget/UI Tests | `testWidgets()` | Testing Library / Cypress | -- | -- |
| Integration | `integration_test` | Cypress / Playwright | Selenium | -- |
| Assertions | `expect(a, matcher)` | `expect(a).toBe(b)` | `assert a == b` | `EXPECT_EQ(a, b)` |

---

## 14.2 Projektstruktur für Tests

```
mein_projekt/
├── lib/
│   ├── models/
│   │   └── shopping_item.dart
│   ├── providers/
│   │   └── shopping_list_provider.dart
│   └── screens/
│       └── shopping_list_screen.dart
├── test/                          ← Unit Tests und Widget Tests
│   ├── models/
│   │   └── shopping_item_test.dart
│   ├── providers/
│   │   └── shopping_list_provider_test.dart
│   └── screens/
│       └── shopping_list_screen_test.dart
└── integration_test/              ← Integration Tests
    └── app_test.dart
```

**Konvention:** Testdateien heißen wie die Quelldatei mit dem Suffix `_test.dart`.

---

## 14.3 Unit Tests

Unit Tests sind die Basis der Test-Pyramide. Sie testen einzelne Funktionen, Methoden und Klassen isoliert.

### Setup

Das `test` Package ist in Flutter-Projekten standardmäßig enthalten.

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  # Für reine Dart-Tests (ohne Flutter)
  # test: ^1.24.0
```

### Grundstruktur

```dart
// test/models/rechner_test.dart
import 'package:test/test.dart';
import 'package:mein_projekt/models/rechner.dart';

void main() {
  // group() fasst zusammengehörige Tests zusammen
  group('Rechner', () {
    late Rechner rechner;

    // setUp() wird VOR JEDEM Test ausgeführt
    setUp(() {
      rechner = Rechner();
    });

    // tearDown() wird NACH JEDEM Test ausgeführt (Aufräumen)
    tearDown(() {
      // z.B. Dateien löschen, Verbindungen schließen
    });

    // setUpAll() / tearDownAll() -- einmal für die ganze Gruppe
    setUpAll(() {
      print('Starte Rechner-Tests...');
    });

    // Einzelner Test
    test('addiere gibt die Summe zurück', () {
      expect(rechner.addiere(2, 3), equals(5));
    });

    test('dividiere wirft Exception bei Division durch Null', () {
      expect(
        () => rechner.dividiere(10, 0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addiere funktioniert mit negativen Zahlen', () {
      expect(rechner.addiere(-1, -2), equals(-3));
      expect(rechner.addiere(-1, 1), equals(0));
    });
  });
}
```

### expect() und Matcher

`expect()` ist die zentrale Assertion-Funktion. Der zweite Parameter ist ein `Matcher`:

```dart
// Gleichheit
expect(ergebnis, equals(42));          // Wert-Gleichheit
expect(ergebnis, 42);                  // Kurzform für equals
expect(ergebnis, isNot(equals(0)));    // Nicht gleich

// Booleans
expect(wert, isTrue);
expect(wert, isFalse);

// Null
expect(wert, isNull);
expect(wert, isNotNull);

// Typen
expect(wert, isA<String>());          // Typprüfung
expect(wert, isA<int>());

// Zahlen
expect(wert, greaterThan(10));
expect(wert, lessThan(100));
expect(wert, greaterThanOrEqualTo(0));
expect(wert, inInclusiveRange(1, 10));
expect(wert, closeTo(3.14, 0.01));    // Für Gleitkommazahlen

// Strings
expect(text, contains('Hallo'));
expect(text, startsWith('H'));
expect(text, endsWith('!'));
expect(text, matches(RegExp(r'\d+')));  // Regex
expect(text, isEmpty);
expect(text, isNotEmpty);

// Listen
expect(liste, contains(42));
expect(liste, containsAll([1, 2, 3]));
expect(liste, hasLength(5));
expect(liste, orderedEquals([1, 2, 3]));
expect(liste, isEmpty);
expect(liste, everyElement(greaterThan(0)));

// Maps
expect(map, containsPair('key', 'value'));
expect(map, contains('key'));  // Hat den Key

// Exceptions
expect(() => fehlerhafteFunktion(), throwsException);
expect(() => fehlerhafteFunktion(), throwsA(isA<FormatException>()));
expect(
  () => fehlerhafteFunktion(),
  throwsA(predicate((e) =>
    e is ArgumentError && e.message == 'Ungültiger Wert'
  )),
);

// Zusammengesetzte Matcher
expect(wert, allOf(isNotNull, greaterThan(0), lessThan(100)));
expect(wert, anyOf(equals(1), equals(2), equals(3)));
```

**Vergleich zu Jest (JavaScript):**
```
Flutter: expect(wert, equals(42));
Jest:    expect(wert).toBe(42);

Flutter: expect(wert, contains('hello'));
Jest:    expect(wert).toContain('hello');

Flutter: expect(() => fn(), throwsA(isA<Error>()));
Jest:    expect(() => fn()).toThrow(Error);
```

**Vergleich zu pytest (Python):**
```
Flutter: expect(wert, equals(42));
pytest:  assert wert == 42

Flutter: expect(() => fn(), throwsA(isA<ValueError>()));
pytest:  with pytest.raises(ValueError): fn()
```

### Testen von Klassen und Funktionen

```dart
// lib/models/shopping_item.dart
class ShoppingItem {
  final String id;
  final String name;
  final int menge;
  final bool gekauft;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.menge = 1,
    this.gekauft = false,
  });

  ShoppingItem copyWith({
    String? name,
    int? menge,
    bool? gekauft,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      menge: menge ?? this.menge,
      gekauft: gekauft ?? this.gekauft,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'menge': menge,
    'gekauft': gekauft,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      menge: json['menge'] as int? ?? 1,
      gekauft: json['gekauft'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          menge == other.menge &&
          gekauft == other.gekauft;

  @override
  int get hashCode => Object.hash(id, name, menge, gekauft);
}
```

```dart
// test/models/shopping_item_test.dart
import 'package:test/test.dart';
import 'package:mein_projekt/models/shopping_item.dart';

void main() {
  group('ShoppingItem', () {
    group('Konstruktor', () {
      test('erstellt Item mit Pflichtfeldern', () {
        final item = ShoppingItem(id: '1', name: 'Milch');

        expect(item.id, '1');
        expect(item.name, 'Milch');
        expect(item.menge, 1);        // Standardwert
        expect(item.gekauft, false);   // Standardwert
      });

      test('erstellt Item mit allen Feldern', () {
        final item = ShoppingItem(
          id: '2',
          name: 'Brot',
          menge: 3,
          gekauft: true,
        );

        expect(item.menge, 3);
        expect(item.gekauft, isTrue);
      });
    });

    group('copyWith', () {
      late ShoppingItem original;

      setUp(() {
        original = ShoppingItem(id: '1', name: 'Milch', menge: 2);
      });

      test('kopiert mit geändertem Namen', () {
        final kopie = original.copyWith(name: 'Butter');
        expect(kopie.name, 'Butter');
        expect(kopie.id, '1');        // ID bleibt gleich
        expect(kopie.menge, 2);       // Menge bleibt gleich
      });

      test('kopiert mit geändertem gekauft-Status', () {
        final kopie = original.copyWith(gekauft: true);
        expect(kopie.gekauft, isTrue);
        expect(kopie.name, 'Milch');   // Name bleibt gleich
      });

      test('ohne Änderungen gibt gleichwertiges Objekt zurück', () {
        final kopie = original.copyWith();
        expect(kopie, equals(original));
        expect(identical(kopie, original), isFalse); // Neues Objekt
      });
    });

    group('JSON-Serialisierung', () {
      test('toJson gibt korrektes Map zurück', () {
        final item = ShoppingItem(
          id: '1',
          name: 'Milch',
          menge: 2,
          gekauft: true,
        );

        final json = item.toJson();

        expect(json, {
          'id': '1',
          'name': 'Milch',
          'menge': 2,
          'gekauft': true,
        });
      });

      test('fromJson erstellt korrektes Objekt', () {
        final json = {
          'id': '1',
          'name': 'Milch',
          'menge': 2,
          'gekauft': true,
        };

        final item = ShoppingItem.fromJson(json);

        expect(item.id, '1');
        expect(item.name, 'Milch');
        expect(item.menge, 2);
        expect(item.gekauft, isTrue);
      });

      test('fromJson verwendet Standardwerte bei fehlenden Feldern', () {
        final json = {'id': '1', 'name': 'Brot'};
        final item = ShoppingItem.fromJson(json);

        expect(item.menge, 1);         // Standardwert
        expect(item.gekauft, isFalse); // Standardwert
      });

      test('toJson und fromJson sind symmetrisch (Roundtrip)', () {
        final original = ShoppingItem(
          id: '1',
          name: 'Milch',
          menge: 3,
          gekauft: true,
        );

        final wiederhergestellt = ShoppingItem.fromJson(original.toJson());
        expect(wiederhergestellt, equals(original));
      });
    });

    group('Gleichheit', () {
      test('gleiche Werte sind gleich', () {
        final a = ShoppingItem(id: '1', name: 'Milch');
        final b = ShoppingItem(id: '1', name: 'Milch');
        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('unterschiedliche IDs sind nicht gleich', () {
        final a = ShoppingItem(id: '1', name: 'Milch');
        final b = ShoppingItem(id: '2', name: 'Milch');
        expect(a, isNot(equals(b)));
      });
    });
  });
}
```

### Asynchrone Tests

```dart
group('Asynchrone Tests', () {
  test('Future-basierte Funktion', () async {
    // async/await in Tests -- genau wie in normalem Code
    final ergebnis = await ladeDaten();
    expect(ergebnis, isNotEmpty);
  });

  test('Future mit Timeout', () async {
    // Test schlägt fehl, wenn er länger als 5 Sekunden dauert
    final ergebnis = await ladeDaten().timeout(
      const Duration(seconds: 5),
    );
    expect(ergebnis, isNotNull);
  }, timeout: Timeout(Duration(seconds: 10)));

  test('Stream gibt erwartete Werte aus', () async {
    final stream = zähleHoch(3); // Stream<int> der 1, 2, 3 ausgibt

    // emitsInOrder prüft die Reihenfolge der Stream-Events
    await expectLater(
      stream,
      emitsInOrder([1, 2, 3, emitsDone]),
    );
  });

  test('Stream mit Fehlern', () async {
    final stream = fehlerhafterStream();

    await expectLater(
      stream,
      emitsInOrder([
        1,
        2,
        emitsError(isA<Exception>()),
      ]),
    );
  });
});
```

---

## 14.4 Mocking mit mocktail

Mocking erlaubt es, Abhängigkeiten durch kontrollierte Attrappen zu ersetzen. So kannst du z.B. API-Calls testen, ohne tatsächlich das Netzwerk zu nutzen.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

### Mock-Klassen erstellen

```dart
import 'package:mocktail/mocktail.dart';

// Die zu mockende Klasse (z.B. ein Repository)
abstract class ShoppingRepository {
  Future<List<ShoppingItem>> ladeAlle();
  Future<void> speichere(ShoppingItem item);
  Future<void> loesche(String id);
}

// Mock-Klasse: Einfach von Mock erben und das Interface implementieren
class MockShoppingRepository extends Mock implements ShoppingRepository {}
```

### when(), verify(), verifyNever()

```dart
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

void main() {
  late MockShoppingRepository mockRepo;
  late ShoppingListProvider provider;

  setUp(() {
    mockRepo = MockShoppingRepository();
    provider = ShoppingListProvider(repository: mockRepo);
  });

  group('ShoppingListProvider', () {
    test('ladeItems ruft Repository auf und gibt Items zurück', () async {
      // ARRANGE: Mock-Verhalten definieren
      final erwarteteItems = [
        ShoppingItem(id: '1', name: 'Milch'),
        ShoppingItem(id: '2', name: 'Brot'),
      ];
      when(() => mockRepo.ladeAlle()).thenAnswer(
        (_) async => erwarteteItems,
      );

      // ACT: Methode aufrufen
      await provider.ladeItems();

      // ASSERT: Ergebnis prüfen
      expect(provider.items, equals(erwarteteItems));
      // Prüfen, dass die Methode genau einmal aufgerufen wurde
      verify(() => mockRepo.ladeAlle()).called(1);
    });

    test('itemHinzufuegen speichert im Repository', () async {
      final neuesItem = ShoppingItem(id: '3', name: 'Käse');
      when(() => mockRepo.speichere(neuesItem)).thenAnswer((_) async {});

      await provider.itemHinzufuegen(neuesItem);

      verify(() => mockRepo.speichere(neuesItem)).called(1);
    });

    test('bei Fehler wird Exception weitergegeben', () async {
      when(() => mockRepo.ladeAlle()).thenThrow(
        Exception('Netzwerkfehler'),
      );

      expect(
        () => provider.ladeItems(),
        throwsA(isA<Exception>()),
      );
    });

    test('loesche wird nicht aufgerufen wenn Item nicht existiert', () async {
      when(() => mockRepo.loesche(any())).thenAnswer((_) async {});

      // Item nicht hinzufügen, aber versuchen zu löschen
      await provider.versucheLoesche('nicht-vorhanden');

      // verifyNever: Prüft, dass die Methode NICHT aufgerufen wurde
      verifyNever(() => mockRepo.loesche(any()));
    });
  });
}

// Für Matcher wie any() mit benutzerdefinierten Typen:
// registerFallbackValue muss in setUpAll aufgerufen werden
void main2() {
  setUpAll(() {
    registerFallbackValue(ShoppingItem(id: '0', name: 'Fallback'));
  });

  test('speichere mit any-Matcher', () async {
    final mockRepo = MockShoppingRepository();
    when(() => mockRepo.speichere(any())).thenAnswer((_) async {});
    // ...
  });
}
```

### API-Calls mocken

```dart
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

// HTTP-Client mocken
class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockClient;

  setUpAll(() {
    // Für any()-Matcher mit Uri muss ein Fallback registriert werden
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
  });

  test('API-Call gibt Produkte zurück', () async {
    // Mock-Antwort definieren
    when(() => mockClient.get(any())).thenAnswer(
      (_) async => http.Response(
        '{"produkte": [{"id": "1", "name": "Milch"}]}',
        200,
      ),
    );

    final apiService = ApiService(client: mockClient);
    final produkte = await apiService.ladeProdukte();

    expect(produkte, hasLength(1));
    expect(produkte.first.name, 'Milch');
    verify(() => mockClient.get(
      Uri.parse('https://api.example.com/produkte'),
    )).called(1);
  });

  test('API-Fehler wird behandelt', () async {
    when(() => mockClient.get(any())).thenAnswer(
      (_) async => http.Response('Server Error', 500),
    );

    final apiService = ApiService(client: mockClient);

    expect(
      () => apiService.ladeProdukte(),
      throwsA(isA<ApiException>()),
    );
  });
}
```

---

## 14.5 Widget Tests

Widget Tests testen einzelne Widgets mit simulierten Interaktionen (Tippen, Text eingeben, Scrollen). Sie laufen schnell, weil sie keinen echten Screen brauchen.

### Grundstruktur

```dart
// test/widgets/mein_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mein_projekt/widgets/mein_widget.dart';

void main() {
  group('MeinWidget', () {
    // testWidgets statt test für Widget-Tests
    testWidgets('zeigt den Titel an', (WidgetTester tester) async {
      // 1. Widget aufbauen
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MeinWidget(titel: 'Hallo Welt'),
          ),
        ),
      );

      // 2. Erwartung prüfen
      expect(find.text('Hallo Welt'), findsOneWidget);
    });
  });
}
```

### pumpWidget(), pump() und pumpAndSettle()

```dart
// pumpWidget: Baut das Widget auf und rendert den ersten Frame
await tester.pumpWidget(const MaterialApp(home: MeinScreen()));

// pump: Rendert einen neuen Frame (nach setState, Animation, etc.)
await tester.pump(); // Ein Frame
await tester.pump(const Duration(milliseconds: 500)); // Frame nach 500ms

// pumpAndSettle: Wartet, bis alle Animationen abgeschlossen sind
// ACHTUNG: Endlose Animationen (repeat) lassen pumpAndSettle nie enden!
await tester.pumpAndSettle();

// Typischer Ablauf:
await tester.pumpWidget(const MaterialApp(home: MeinScreen()));
await tester.tap(find.byType(ElevatedButton));
await tester.pumpAndSettle(); // Warte auf Animationen nach dem Tap
```

### Finder: Widgets im Test finden

```dart
// Nach Text suchen
find.text('Hallo')           // Findet Text-Widget mit 'Hallo'
find.textContaining('Hall')  // Findet Text der 'Hall' enthält

// Nach Widget-Typ suchen
find.byType(ElevatedButton)  // Findet alle ElevatedButton
find.byType(ListView)        // Findet ListView

// Nach Key suchen (empfohlen für eindeutige Identifikation)
find.byKey(const Key('meinButton'))
find.byKey(const ValueKey('artikelListe'))

// Nach Icon suchen
find.byIcon(Icons.add)
find.byIcon(Icons.delete)

// Nach Widget-Instanz suchen
find.byWidget(meinWidget)

// Finder kombinieren
find.descendant(
  of: find.byType(Card),
  matching: find.text('Titel'),
)

find.ancestor(
  of: find.text('Hallo'),
  matching: find.byType(ListTile),
)

// Finder mit Predicate
find.byWidgetPredicate(
  (widget) => widget is Text && widget.data?.contains('Error') == true,
)
```

### Finder-Erwartungen

```dart
expect(find.text('Hallo'), findsOneWidget);     // Genau ein Widget
expect(find.text('Hallo'), findsNothing);        // Kein Widget
expect(find.text('Hallo'), findsWidgets);        // Mindestens ein Widget
expect(find.text('Hallo'), findsNWidgets(3));    // Genau 3 Widgets
expect(find.text('Hallo'), findsAtLeast(2));     // Mindestens 2
```

### Interaktionen: tap(), enterText(), drag()

```dart
testWidgets('Button-Klick erhöht Zähler', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ZaehlerScreen()));

  // Anfangszustand prüfen
  expect(find.text('0'), findsOneWidget);

  // Button tippen
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump(); // Neuen Frame rendern

  // Ergebnis prüfen
  expect(find.text('1'), findsOneWidget);
});

testWidgets('Text eingeben und abschicken', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: FormularScreen()));

  // Text in TextField eingeben
  await tester.enterText(
    find.byType(TextField),
    'Neuer Artikel',
  );
  await tester.pump();

  // Abschicken-Button drücken
  await tester.tap(find.text('Hinzufügen'));
  await tester.pumpAndSettle();

  // Ergebnis prüfen
  expect(find.text('Neuer Artikel'), findsOneWidget);
});

testWidgets('Swipe zum Löschen', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: ListeScreen()));

  // Sicherstellen, dass das Item da ist
  expect(find.text('Milch'), findsOneWidget);

  // Nach links wischen (Dismiss)
  await tester.drag(
    find.text('Milch'),
    const Offset(-500, 0), // Negative X-Richtung = nach links
  );
  await tester.pumpAndSettle();

  // Item sollte verschwunden sein
  expect(find.text('Milch'), findsNothing);
});

testWidgets('Scrollen', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: LangeListeScreen()));

  // Nach unten scrollen
  await tester.drag(
    find.byType(ListView),
    const Offset(0, -500), // Negative Y-Richtung = nach unten
  );
  await tester.pumpAndSettle();

  // Element am Ende der Liste sollte sichtbar sein
  expect(find.text('Item 50'), findsOneWidget);
});

testWidgets('Long Press', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: MeinScreen()));

  await tester.longPress(find.text('Langes Drücken'));
  await tester.pumpAndSettle();

  expect(find.text('Kontextmenü'), findsOneWidget);
});
```

### Widget Test mit Provider

```dart
testWidgets('zeigt Items aus dem Provider an', (tester) async {
  // Provider mit Testdaten erstellen
  final provider = ShoppingListProvider();
  provider.itemHinzufuegen(ShoppingItem(id: '1', name: 'Milch'));
  provider.itemHinzufuegen(ShoppingItem(id: '2', name: 'Brot'));

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: provider,
      child: const MaterialApp(
        home: ShoppingListScreen(),
      ),
    ),
  );

  expect(find.text('Milch'), findsOneWidget);
  expect(find.text('Brot'), findsOneWidget);
});
```

### Widget Test mit Mock-Provider

```dart
import 'package:mocktail/mocktail.dart';

class MockShoppingListProvider extends Mock
    with ChangeNotifier
    implements ShoppingListProvider {}

testWidgets('ruft ladeItems beim Start auf', (tester) async {
  final mockProvider = MockShoppingListProvider();
  when(() => mockProvider.items).thenReturn([]);
  when(() => mockProvider.ladeItems()).thenAnswer((_) async {});

  await tester.pumpWidget(
    ChangeNotifierProvider<ShoppingListProvider>.value(
      value: mockProvider,
      child: const MaterialApp(
        home: ShoppingListScreen(),
      ),
    ),
  );

  verify(() => mockProvider.ladeItems()).called(1);
});
```

---

## 14.6 Integration Tests

Integration Tests testen die gesamte App auf einem echten Gerät oder Emulator. Sie sind die langsamsten, aber realistischsten Tests.

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### Test schreiben

```dart
// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mein_projekt/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App End-to-End Test', () {
    testWidgets('Artikel hinzufügen und löschen', (tester) async {
      // App starten
      app.main();
      await tester.pumpAndSettle();

      // Prüfen, dass die App geladen ist
      expect(find.text('Einkaufsliste'), findsOneWidget);

      // Neuen Artikel hinzufügen
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Formular ausfüllen
      await tester.enterText(
        find.byKey(const Key('artikelNameFeld')),
        'Milch',
      );
      await tester.tap(find.text('Speichern'));
      await tester.pumpAndSettle();

      // Prüfen, dass der Artikel in der Liste ist
      expect(find.text('Milch'), findsOneWidget);

      // Artikel durch Swipe löschen
      await tester.drag(find.text('Milch'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Prüfen, dass der Artikel verschwunden ist
      expect(find.text('Milch'), findsNothing);
    });
  });
}
```

### Test ausführen

```bash
# Integration Test starten (Emulator muss laufen)
flutter test integration_test/app_test.dart

# Auf bestimmtem Gerät
flutter test integration_test/app_test.dart -d emulator-5554
```

### Ausblick: patrol Package

`patrol` ist ein erweitertes Integration-Test-Framework, das native Interaktionen ermöglicht (z.B. Berechtigungsdialoge, Benachrichtigungen).

```dart
// patrol ermöglicht native Interaktionen
patrolTest('Kamera-Berechtigung akzeptieren', ($) async {
  await $.pumpWidgetAndSettle(const MeineApp());
  await $.tap(find.text('Foto aufnehmen'));

  // Native Berechtigungsdialog beantworten
  await $.native.grantPermissionWhenInUse();

  expect(find.byType(KameraVorschau), findsOneWidget);
});
```

---

## 14.7 Code Coverage

Code Coverage zeigt, welcher Anteil deines Codes durch Tests abgedeckt ist.

```bash
# Tests mit Coverage ausführen
flutter test --coverage

# Ergebnis liegt in coverage/lcov.info
# Visuell anzeigen (HTML-Report):
# Zuerst lcov installieren: sudo apt install lcov (Linux)
genhtml coverage/lcov.info -o coverage/html

# HTML-Report öffnen
open coverage/html/index.html   # macOS
xdg-open coverage/html/index.html  # Linux

# In VS Code: Flutter Coverage Extension installieren
# Zeigt Coverage direkt im Editor an
```

**Richtwerte:**
- 80%+ ist ein guter Wert für die meisten Projekte
- 100% ist selten sinnvoll (Getter, Setter, triviale Methoden)
- Fokussiere auf Business-Logik und komplexe Funktionen

---

## 14.8 TDD Grundlagen: Red-Green-Refactor

Test-Driven Development (TDD) bedeutet: **Erst den Test schreiben, dann den Code.**

```
┌─────────────────────────────────────────┐
│           TDD-Zyklus                    │
│                                         │
│   1. RED     → Test schreiben           │
│               (Test schlägt fehl)       │
│                                         │
│   2. GREEN   → Minimalen Code           │
│               schreiben (Test besteht)  │
│                                         │
│   3. REFACTOR → Code verbessern         │
│               (Tests bestehen weiter)   │
│                                         │
│   → Zurück zu 1.                        │
└─────────────────────────────────────────┘
```

### Beispiel: TDD für eine Passwort-Validierung

```dart
// Schritt 1: RED - Test schreiben
test('leeres Passwort ist ungültig', () {
  expect(istStarkesPasswort(''), isFalse);
});

// Schritt 2: GREEN - Minimaler Code
bool istStarkesPasswort(String passwort) {
  if (passwort.isEmpty) return false;
  return true; // Minimal, damit der erste Test besteht
}

// Schritt 1: RED - Nächster Test
test('Passwort muss mindestens 8 Zeichen haben', () {
  expect(istStarkesPasswort('kurz'), isFalse);
  expect(istStarkesPasswort('langgenu8'), isTrue);
});

// Schritt 2: GREEN - Code erweitern
bool istStarkesPasswort(String passwort) {
  if (passwort.isEmpty) return false;
  if (passwort.length < 8) return false;
  return true;
}

// Schritt 1: RED - Noch ein Test
test('Passwort muss Großbuchstaben enthalten', () {
  expect(istStarkesPasswort('nurklein123'), isFalse);
  expect(istStarkesPasswort('MitGross123'), isTrue);
});

// Schritt 2: GREEN
bool istStarkesPasswort(String passwort) {
  if (passwort.isEmpty) return false;
  if (passwort.length < 8) return false;
  if (!passwort.contains(RegExp(r'[A-Z]'))) return false;
  return true;
}

// Schritt 3: REFACTOR
bool istStarkesPasswort(String passwort) {
  return passwort.length >= 8 &&
         passwort.contains(RegExp(r'[A-Z]')) &&
         passwort.contains(RegExp(r'[0-9]'));
}
```

---

## 14.9 Best Practices

### Was testen?

```
Unbedingt testen:
✓ Business-Logik (Berechnungen, Validierungen)
✓ State-Management (Provider-Methoden)
✓ JSON-Serialisierung (fromJson/toJson)
✓ Fehlerbehandlung (Edge Cases, ungültige Eingaben)
✓ Wichtige UI-Interaktionen (Formulare, Navigation)

Nicht unbedingt testen:
✗ Triviale Getter/Setter
✗ Framework-Code (Flutter-Widgets selbst)
✗ Rein visuelles Layout (Pixel-genaue Positionen)
✗ Drittanbieter-Packages
```

### Benennung von Tests

```dart
// GUT: Beschreibt das erwartete Verhalten
test('fromJson erstellt korrektes Objekt bei vollständigem JSON', () { ... });
test('addiere gibt negative Summe bei zwei negativen Zahlen zurück', () { ... });
test('zeigt Fehlermeldung wenn Passwort zu kurz ist', () { ... });

// SCHLECHT: Zu vage oder beschreibt die Implementierung
test('test1', () { ... });
test('es funktioniert', () { ... });
test('ruft die Methode auf', () { ... });
```

### AAA-Pattern (Arrange-Act-Assert)

```dart
test('Rabatt wird korrekt berechnet', () {
  // ARRANGE: Testdaten vorbereiten
  final warenkorb = Warenkorb();
  warenkorb.hinzufuegen(Produkt(name: 'Laptop', preis: 1000));
  final rabatt = Rabatt(prozent: 10);

  // ACT: Die zu testende Aktion ausführen
  final endpreis = warenkorb.berechnePreis(rabatt: rabatt);

  // ASSERT: Ergebnis prüfen
  expect(endpreis, equals(900.0));
});
```

### Tests ausführen

```bash
# Alle Tests
flutter test

# Bestimmte Datei
flutter test test/models/shopping_item_test.dart

# Bestimmter Test (mit --name Filter)
flutter test --name "fromJson erstellt"

# Mit Verbose-Ausgabe
flutter test --reporter expanded

# Im Watch-Modus (bei Dateiänderung neu ausführen)
# Benötigt build_runner oder IDE-Integration
```

---

## 14.10 Zusammenfassung

```
Testing in Flutter:

Unit Tests (test Package):
├── test(), group(), setUp(), tearDown()
├── expect() + Matcher (equals, contains, throwsA, ...)
├── Klassen und Funktionen isoliert testen
└── Asynchrone Tests mit async/await

Mocking (mocktail):
├── Mock-Klassen: class MockX extends Mock implements X {}
├── when() → Verhalten definieren
├── verify() → Aufruf prüfen
└── API-Calls und Repositories mocken

Widget Tests (flutter_test):
├── testWidgets() + WidgetTester
├── pumpWidget(), pump(), pumpAndSettle()
├── find.text(), find.byType(), find.byKey()
├── tester.tap(), tester.enterText(), tester.drag()
└── expect(find.text('X'), findsOneWidget)

Integration Tests:
├── integration_test Package
├── Auf echtem Gerät/Emulator
└── End-to-End App-Flows

Best Practices:
├── Test-Pyramide beachten (viele Unit, wenige Integration)
├── AAA-Pattern (Arrange-Act-Assert)
├── Aussagekräftige Testnamen
└── TDD: Red → Green → Refactor
```
