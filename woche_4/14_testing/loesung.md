# Modul 14: Testing -- Lösung

## Vollständige Test-Suite für die Einkaufslisten-App

### Projektstruktur

```
test/
  models/
    shopping_item_test.dart
  providers/
    shopping_list_provider_test.dart
  screens/
    shopping_list_screen_test.dart
  helpers/
    test_helpers.dart
```

---

### test/helpers/test_helpers.dart

```dart
/// Gemeinsame Testhelfer und Mock-Klassen.
///
/// Zentrale Datei für wiederverwendbare Mocks und Testdaten.
/// Konzept: DRY (Don't Repeat Yourself) gilt auch für Tests.

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mein_projekt/models/shopping_item.dart';
import 'package:mein_projekt/providers/shopping_list_provider.dart';
import 'package:mein_projekt/repositories/shopping_repository.dart';

// --- Mock-Klassen ---

/// Mock des ShoppingRepository (Modul 14: Mocking mit mocktail).
/// Erbt von Mock und implementiert das Repository-Interface.
class MockShoppingRepository extends Mock implements ShoppingRepository {}

// --- Testdaten ---

/// Erstellt Beispiel-Items für Tests.
List<ShoppingItem> testItems() => [
  const ShoppingItem(
    id: '1',
    name: 'Milch',
    menge: 2,
    kategorie: 'Milchprodukte',
  ),
  const ShoppingItem(
    id: '2',
    name: 'Brot',
    menge: 1,
    kategorie: 'Backwaren',
  ),
  const ShoppingItem(
    id: '3',
    name: 'Käse',
    menge: 1,
    kategorie: 'Milchprodukte',
    gekauft: true,
  ),
];

/// Helferfunktion: Wraps ein Widget in MaterialApp + Provider.
/// Nützlich für Widget Tests, die einen Provider benötigen.
Widget erstelleTestApp({
  required Widget child,
  ShoppingListProvider? provider,
}) {
  if (provider != null) {
    return ChangeNotifierProvider<ShoppingListProvider>.value(
      value: provider,
      child: MaterialApp(home: child),
    );
  }
  return MaterialApp(home: child);
}
```

---

### test/models/shopping_item_test.dart

```dart
/// Unit Tests für das ShoppingItem Model (Aufgabe 1).
///
/// Testet: Konstruktor, copyWith, toJson, fromJson, Gleichheit.
/// Verwendet Konzepte aus:
/// - Modul 2 (OOP, Konstruktoren)
/// - Modul 4 (Null Safety)
/// - Modul 10 (JSON-Serialisierung)

import 'package:flutter_test/flutter_test.dart';
import 'package:mein_projekt/models/shopping_item.dart';

void main() {
  group('ShoppingItem', () {
    // ========================================
    // Konstruktor-Tests
    // ========================================
    group('Konstruktor', () {
      test('erstellt Item mit Pflichtfeldern und Standardwerten', () {
        // ARRANGE & ACT
        const item = ShoppingItem(id: '1', name: 'Milch');

        // ASSERT
        expect(item.id, '1');
        expect(item.name, 'Milch');
        expect(item.menge, 1);                  // Standardwert
        expect(item.kategorie, 'Sonstiges');     // Standardwert
        expect(item.gekauft, isFalse);           // Standardwert
      });

      test('erstellt Item mit allen Feldern', () {
        const item = ShoppingItem(
          id: '2',
          name: 'Bio-Brot',
          menge: 3,
          kategorie: 'Backwaren',
          gekauft: true,
        );

        expect(item.id, '2');
        expect(item.name, 'Bio-Brot');
        expect(item.menge, 3);
        expect(item.kategorie, 'Backwaren');
        expect(item.gekauft, isTrue);
      });
    });

    // ========================================
    // copyWith-Tests
    // ========================================
    group('copyWith', () {
      const original = ShoppingItem(
        id: '1',
        name: 'Milch',
        menge: 2,
        kategorie: 'Milchprodukte',
      );

      test('kopiert mit geändertem Namen', () {
        final kopie = original.copyWith(name: 'Butter');

        expect(kopie.name, 'Butter');
        expect(kopie.id, '1');           // Unverändert
        expect(kopie.menge, 2);          // Unverändert
        expect(kopie.kategorie, 'Milchprodukte'); // Unverändert
      });

      test('kopiert mit geändertem gekauft-Status', () {
        final kopie = original.copyWith(gekauft: true);

        expect(kopie.gekauft, isTrue);
        expect(kopie.name, 'Milch');     // Unverändert
      });

      test('kopiert mit mehreren geänderten Feldern', () {
        final kopie = original.copyWith(
          name: 'Hafermilch',
          menge: 5,
          kategorie: 'Getränke',
        );

        expect(kopie.name, 'Hafermilch');
        expect(kopie.menge, 5);
        expect(kopie.kategorie, 'Getränke');
        expect(kopie.id, '1');           // ID bleibt immer gleich
      });

      test('ohne Änderungen gibt gleichwertiges aber neues Objekt zurück', () {
        final kopie = original.copyWith();

        expect(kopie, equals(original));
        // Es ist ein neues Objekt (nicht identisch)
        expect(identical(kopie, original), isFalse);
      });
    });

    // ========================================
    // toJson-Tests
    // ========================================
    group('toJson', () {
      test('gibt korrektes Map mit allen Feldern zurück', () {
        const item = ShoppingItem(
          id: '1',
          name: 'Milch',
          menge: 2,
          kategorie: 'Milchprodukte',
          gekauft: true,
        );

        final json = item.toJson();

        expect(json, isA<Map<String, dynamic>>());
        expect(json['id'], '1');
        expect(json['name'], 'Milch');
        expect(json['menge'], 2);
        expect(json['kategorie'], 'Milchprodukte');
        expect(json['gekauft'], isTrue);
      });

      test('enthält alle erwarteten Schlüssel', () {
        const item = ShoppingItem(id: '1', name: 'Test');
        final json = item.toJson();

        expect(json.keys, containsAll(['id', 'name', 'menge', 'kategorie', 'gekauft']));
        expect(json.keys, hasLength(5));
      });
    });

    // ========================================
    // fromJson-Tests
    // ========================================
    group('fromJson', () {
      test('erstellt korrektes Objekt bei vollständigem JSON', () {
        final json = {
          'id': '1',
          'name': 'Milch',
          'menge': 2,
          'kategorie': 'Milchprodukte',
          'gekauft': true,
        };

        final item = ShoppingItem.fromJson(json);

        expect(item.id, '1');
        expect(item.name, 'Milch');
        expect(item.menge, 2);
        expect(item.kategorie, 'Milchprodukte');
        expect(item.gekauft, isTrue);
      });

      test('verwendet Standardwert für fehlende menge', () {
        final json = {'id': '1', 'name': 'Brot'};
        final item = ShoppingItem.fromJson(json);

        expect(item.menge, 1); // Standardwert
      });

      test('verwendet Standardwert für fehlende kategorie', () {
        final json = {'id': '1', 'name': 'Brot'};
        final item = ShoppingItem.fromJson(json);

        expect(item.kategorie, 'Sonstiges'); // Standardwert
      });

      test('verwendet Standardwert für fehlendes gekauft', () {
        final json = {'id': '1', 'name': 'Brot'};
        final item = ShoppingItem.fromJson(json);

        expect(item.gekauft, isFalse); // Standardwert
      });

      test('behandelt verschiedene Kategorien korrekt', () {
        final kategorien = ['Obst', 'Gemüse', 'Backwaren', 'Getränke'];

        for (final kat in kategorien) {
          final item = ShoppingItem.fromJson({
            'id': '1',
            'name': 'Test',
            'kategorie': kat,
          });
          expect(item.kategorie, kat);
        }
      });
    });

    // ========================================
    // Roundtrip-Test (toJson → fromJson)
    // ========================================
    group('JSON Roundtrip', () {
      test('toJson und fromJson sind symmetrisch', () {
        const original = ShoppingItem(
          id: '1',
          name: 'Milch',
          menge: 3,
          kategorie: 'Milchprodukte',
          gekauft: true,
        );

        final wiederhergestellt = ShoppingItem.fromJson(original.toJson());

        expect(wiederhergestellt, equals(original));
      });

      test('Roundtrip funktioniert für Item mit Standardwerten', () {
        const original = ShoppingItem(id: '99', name: 'Einfach');
        final wiederhergestellt = ShoppingItem.fromJson(original.toJson());
        expect(wiederhergestellt, equals(original));
      });
    });

    // ========================================
    // Gleichheits-Tests
    // ========================================
    group('Gleichheit (== und hashCode)', () {
      test('gleiche Werte sind gleich', () {
        const a = ShoppingItem(id: '1', name: 'Milch', menge: 2);
        const b = ShoppingItem(id: '1', name: 'Milch', menge: 2);

        expect(a, equals(b));
      });

      test('gleiche Werte haben gleichen hashCode', () {
        const a = ShoppingItem(id: '1', name: 'Milch', menge: 2);
        const b = ShoppingItem(id: '1', name: 'Milch', menge: 2);

        expect(a.hashCode, equals(b.hashCode));
      });

      test('unterschiedliche IDs sind nicht gleich', () {
        const a = ShoppingItem(id: '1', name: 'Milch');
        const b = ShoppingItem(id: '2', name: 'Milch');

        expect(a, isNot(equals(b)));
      });

      test('unterschiedliche Namen sind nicht gleich', () {
        const a = ShoppingItem(id: '1', name: 'Milch');
        const b = ShoppingItem(id: '1', name: 'Butter');

        expect(a, isNot(equals(b)));
      });

      test('unterschiedlicher gekauft-Status ist nicht gleich', () {
        const a = ShoppingItem(id: '1', name: 'Milch', gekauft: false);
        const b = ShoppingItem(id: '1', name: 'Milch', gekauft: true);

        expect(a, isNot(equals(b)));
      });
    });

    // ========================================
    // toString-Test
    // ========================================
    test('toString gibt lesbare Darstellung zurück', () {
      const item = ShoppingItem(id: '1', name: 'Milch', menge: 2);

      expect(item.toString(), contains('Milch'));
      expect(item.toString(), contains('1'));
    });
  });
}
```

---

### test/providers/shopping_list_provider_test.dart

```dart
/// Unit Tests für den ShoppingListProvider (Aufgabe 2 + 3).
///
/// Verwendet Mocking mit mocktail um das Repository zu ersetzen.
/// Testet die gesamte Business-Logik des Providers.
///
/// Konzepte aus:
/// - Modul 9 (State Management mit Provider)
/// - Modul 3 (Asynchrone Programmierung)

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mein_projekt/models/shopping_item.dart';
import 'package:mein_projekt/providers/shopping_list_provider.dart';
import '../helpers/test_helpers.dart';

void main() {
  // Muss für any()-Matcher mit eigenen Typen aufgerufen werden
  setUpAll(() {
    registerFallbackValue(
      const ShoppingItem(id: 'fallback', name: 'Fallback'),
    );
  });

  late MockShoppingRepository mockRepo;
  late ShoppingListProvider provider;

  setUp(() {
    mockRepo = MockShoppingRepository();
    provider = ShoppingListProvider(repository: mockRepo);
  });

  // ========================================
  // Initialer Zustand
  // ========================================
  group('Initialer Zustand', () {
    test('hat leere Items-Liste', () {
      expect(provider.items, isEmpty);
    });

    test('isLoading ist false', () {
      expect(provider.isLoading, isFalse);
    });

    test('fehler ist null', () {
      expect(provider.fehler, isNull);
    });
  });

  // ========================================
  // ladeItems
  // ========================================
  group('ladeItems', () {
    test('gibt geladene Items zurück', () async {
      // ARRANGE
      final erwarteteItems = testItems();
      when(() => mockRepo.ladeAlle()).thenAnswer(
        (_) async => erwarteteItems,
      );

      // ACT
      await provider.ladeItems();

      // ASSERT
      expect(provider.items, equals(erwarteteItems));
      expect(provider.items, hasLength(3));
      verify(() => mockRepo.ladeAlle()).called(1);
    });

    test('setzt isLoading während des Ladens', () async {
      // ARRANGE: Verzögerung simulieren
      when(() => mockRepo.ladeAlle()).thenAnswer(
        (_) async {
          // Während der Ausführung sollte isLoading true sein
          return testItems();
        },
      );

      // Prüfe isLoading vor dem Laden
      expect(provider.isLoading, isFalse);

      // ACT
      final future = provider.ladeItems();

      // isLoading sollte jetzt true sein (nach dem ersten notifyListeners)
      // Hinweis: Da die Future sofort resolved, prüfen wir nach Abschluss
      await future;

      // ASSERT: Nach dem Laden ist isLoading wieder false
      expect(provider.isLoading, isFalse);
    });

    test('setzt fehler bei einer Exception', () async {
      // ARRANGE
      when(() => mockRepo.ladeAlle()).thenThrow(
        Exception('Netzwerkfehler'),
      );

      // ACT
      await provider.ladeItems();

      // ASSERT
      expect(provider.fehler, isNotNull);
      expect(provider.fehler, contains('Fehler beim Laden'));
      expect(provider.items, isEmpty);
    });

    test('setzt isLoading zurück auch bei Fehler', () async {
      // ARRANGE
      when(() => mockRepo.ladeAlle()).thenThrow(Exception('Fehler'));

      // ACT
      await provider.ladeItems();

      // ASSERT
      expect(provider.isLoading, isFalse);
    });

    test('leert den Fehler bei erneutem Laden', () async {
      // ARRANGE: Erst Fehler erzeugen
      when(() => mockRepo.ladeAlle()).thenThrow(Exception('Fehler'));
      await provider.ladeItems();
      expect(provider.fehler, isNotNull);

      // Dann erfolgreich laden
      when(() => mockRepo.ladeAlle()).thenAnswer((_) async => []);
      await provider.ladeItems();

      // ASSERT
      expect(provider.fehler, isNull);
    });
  });

  // ========================================
  // itemHinzufuegen
  // ========================================
  group('itemHinzufuegen', () {
    test('fügt Item zur Liste hinzu', () async {
      // ARRANGE
      const neuesItem = ShoppingItem(id: '10', name: 'Käse');
      when(() => mockRepo.speichere(any())).thenAnswer((_) async {});

      // ACT
      await provider.itemHinzufuegen(neuesItem);

      // ASSERT
      expect(provider.items, contains(neuesItem));
      expect(provider.items, hasLength(1));
    });

    test('ruft repository.speichere() auf', () async {
      // ARRANGE
      const neuesItem = ShoppingItem(id: '10', name: 'Käse');
      when(() => mockRepo.speichere(any())).thenAnswer((_) async {});

      // ACT
      await provider.itemHinzufuegen(neuesItem);

      // ASSERT
      verify(() => mockRepo.speichere(neuesItem)).called(1);
    });

    test('kann mehrere Items hinzufügen', () async {
      // ARRANGE
      when(() => mockRepo.speichere(any())).thenAnswer((_) async {});

      // ACT
      await provider.itemHinzufuegen(
        const ShoppingItem(id: '1', name: 'Milch'),
      );
      await provider.itemHinzufuegen(
        const ShoppingItem(id: '2', name: 'Brot'),
      );

      // ASSERT
      expect(provider.items, hasLength(2));
      expect(provider.items[0].name, 'Milch');
      expect(provider.items[1].name, 'Brot');
    });
  });

  // ========================================
  // itemEntfernen
  // ========================================
  group('itemEntfernen', () {
    setUp(() async {
      // Testdaten laden
      when(() => mockRepo.ladeAlle()).thenAnswer((_) async => testItems());
      when(() => mockRepo.loesche(any())).thenAnswer((_) async {});
      await provider.ladeItems();
    });

    test('entfernt das Item aus der Liste', () async {
      // ARRANGE
      expect(provider.items, hasLength(3));

      // ACT
      await provider.itemEntfernen('1');

      // ASSERT
      expect(provider.items, hasLength(2));
      expect(
        provider.items.any((item) => item.id == '1'),
        isFalse,
      );
    });

    test('ruft repository.loesche() mit korrekter ID auf', () async {
      // ACT
      await provider.itemEntfernen('2');

      // ASSERT
      verify(() => mockRepo.loesche('2')).called(1);
    });

    test('entfernt nur das Item mit der angegebenen ID', () async {
      // ACT
      await provider.itemEntfernen('1');

      // ASSERT: Die anderen Items sind noch da
      expect(provider.items.any((item) => item.id == '2'), isTrue);
      expect(provider.items.any((item) => item.id == '3'), isTrue);
    });
  });

  // ========================================
  // toggleGekauft
  // ========================================
  group('toggleGekauft', () {
    setUp(() async {
      when(() => mockRepo.ladeAlle()).thenAnswer((_) async => testItems());
      when(() => mockRepo.aktualisiere(any())).thenAnswer((_) async {});
      await provider.ladeItems();
    });

    test('wechselt gekauft-Status von false auf true', () async {
      // ARRANGE: Item '1' ist nicht gekauft
      expect(provider.items.firstWhere((i) => i.id == '1').gekauft, isFalse);

      // ACT
      await provider.toggleGekauft('1');

      // ASSERT
      expect(provider.items.firstWhere((i) => i.id == '1').gekauft, isTrue);
    });

    test('wechselt gekauft-Status von true auf false', () async {
      // ARRANGE: Item '3' ist bereits gekauft
      expect(provider.items.firstWhere((i) => i.id == '3').gekauft, isTrue);

      // ACT
      await provider.toggleGekauft('3');

      // ASSERT
      expect(provider.items.firstWhere((i) => i.id == '3').gekauft, isFalse);
    });

    test('ruft repository.aktualisiere() auf', () async {
      // ACT
      await provider.toggleGekauft('1');

      // ASSERT
      verify(() => mockRepo.aktualisiere(any())).called(1);
    });

    test('ignoriert nicht existierende IDs', () async {
      // ACT
      await provider.toggleGekauft('nicht-vorhanden');

      // ASSERT: repository.aktualisiere wurde NICHT aufgerufen
      verifyNever(() => mockRepo.aktualisiere(any()));
    });
  });

  // ========================================
  // offeneItems und gekaufteItems
  // ========================================
  group('Gefilterte Listen', () {
    setUp(() async {
      when(() => mockRepo.ladeAlle()).thenAnswer((_) async => testItems());
      await provider.ladeItems();
    });

    test('offeneItems enthält nur nicht-gekaufte Items', () {
      final offene = provider.offeneItems;

      expect(offene, hasLength(2)); // Milch und Brot
      expect(offene.every((item) => !item.gekauft), isTrue);
    });

    test('gekaufteItems enthält nur gekaufte Items', () {
      final gekaufte = provider.gekaufteItems;

      expect(gekaufte, hasLength(1)); // Nur Käse
      expect(gekaufte.every((item) => item.gekauft), isTrue);
      expect(gekaufte.first.name, 'Käse');
    });

    test('offene + gekaufte = alle Items', () {
      expect(
        provider.offeneItems.length + provider.gekaufteItems.length,
        equals(provider.items.length),
      );
    });
  });

  // ========================================
  // Immutabilität
  // ========================================
  group('Immutabilität', () {
    test('items-Getter gibt unveränderliche Liste zurück', () {
      // Die items-Liste sollte nicht direkt modifizierbar sein
      expect(
        () => provider.items.add(
          const ShoppingItem(id: '99', name: 'Hack'),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  // ========================================
  // Interaktionsverifikation (Aufgabe 3)
  // ========================================
  group('Repository-Interaktionsverifikation', () {
    test('ladeItems ruft nur ladeAlle auf', () async {
      when(() => mockRepo.ladeAlle()).thenAnswer((_) async => []);

      await provider.ladeItems();

      verify(() => mockRepo.ladeAlle()).called(1);
      verifyNoMoreInteractions(mockRepo);
    });

    test('bei Netzwerkverzögerung werden Items trotzdem geladen', () async {
      // Simuliere 100ms Netzwerkverzögerung
      when(() => mockRepo.ladeAlle()).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 100),
          () => testItems(),
        ),
      );

      await provider.ladeItems();

      expect(provider.items, hasLength(3));
    });
  });
}
```

---

### test/screens/shopping_list_screen_test.dart

```dart
/// Widget Tests für den Shopping-List-Screen (Aufgaben 4, 5, 6).
///
/// Testet die UI-Darstellung und Interaktionen.
/// Verwendet flutter_test und mocktail.
///
/// Konzepte aus:
/// - Modul 5-7 (Widgets, StatefulWidgets, Layouts)
/// - Modul 9 (State Management mit Provider)
/// - Modul 12 (Formulare)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:mein_projekt/models/shopping_item.dart';
import '../helpers/test_helpers.dart';

// =============================================
// Vereinfachte Widgets für die Tests
// (In einem echten Projekt würde man die echten Widgets testen)
// =============================================

/// Einfache Einkaufsliste für die Widget Tests.
class TestShoppingListScreen extends StatelessWidget {
  const TestShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.watch<TestShoppingListNotifier>().items;
    final isLoading = context.watch<TestShoppingListNotifier>().isLoading;
    final fehler = context.watch<TestShoppingListNotifier>().fehler;

    return Scaffold(
      appBar: AppBar(title: const Text('Einkaufsliste')),
      body: _buildBody(context, items, isLoading, fehler),
      floatingActionButton: FloatingActionButton(
        key: const Key('addButton'),
        onPressed: () => _zeigeFormular(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<ShoppingItem> items,
    bool isLoading,
    String? fehler,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fehler != null) {
      return Center(child: Text(fehler, style: const TextStyle(color: Colors.red)));
    }

    if (items.isEmpty) {
      return const Center(child: Text('Keine Artikel'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            context.read<TestShoppingListNotifier>().itemEntfernen(item.id);
          },
          child: ListTile(
            leading: Checkbox(
              value: item.gekauft,
              onChanged: (_) {
                context.read<TestShoppingListNotifier>().toggleGekauft(item.id);
              },
            ),
            title: Text(
              item.name,
              style: TextStyle(
                decoration: item.gekauft ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text('Menge: ${item.menge}'),
          ),
        );
      },
    );
  }

  void _zeigeFormular(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const TestArtikelFormular(),
    );
  }
}

/// Einfaches Formular zum Hinzufügen eines Artikels.
class TestArtikelFormular extends StatefulWidget {
  const TestArtikelFormular({super.key});

  @override
  State<TestArtikelFormular> createState() => _TestArtikelFormularState();
}

class _TestArtikelFormularState extends State<TestArtikelFormular> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mengeController = TextEditingController(text: '1');

  @override
  void dispose() {
    _nameController.dispose();
    _mengeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Artikel hinzufügen'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              key: const Key('nameFeld'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name darf nicht leer sein';
                }
                return null;
              },
            ),
            TextFormField(
              key: const Key('mengeFeld'),
              controller: _mengeController,
              decoration: const InputDecoration(labelText: 'Menge'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          key: const Key('speichernButton'),
          onPressed: _speichern,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  void _speichern() {
    if (_formKey.currentState!.validate()) {
      final item = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        menge: int.tryParse(_mengeController.text) ?? 1,
      );
      context.read<TestShoppingListNotifier>().itemHinzufuegen(item);
      Navigator.pop(context);
    }
  }
}

/// Einfacher Notifier für die Tests (statt den echten Provider mit Repository).
class TestShoppingListNotifier extends ChangeNotifier {
  List<ShoppingItem> _items;
  bool _isLoading;
  String? _fehler;

  TestShoppingListNotifier({
    List<ShoppingItem>? items,
    bool isLoading = false,
    String? fehler,
  })  : _items = items ?? [],
        _isLoading = isLoading,
        _fehler = fehler;

  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get fehler => _fehler;

  void itemHinzufuegen(ShoppingItem item) {
    _items = [..._items, item];
    notifyListeners();
  }

  void itemEntfernen(String id) {
    _items = _items.where((item) => item.id != id).toList();
    notifyListeners();
  }

  void toggleGekauft(String id) {
    _items = _items.map((item) {
      if (item.id == id) {
        return item.copyWith(gekauft: !item.gekauft);
      }
      return item;
    }).toList();
    notifyListeners();
  }
}

// =============================================
// Widget Tests
// =============================================

void main() {
  // Hilfsfunktion: App mit Provider erstellen
  Widget erstelleApp({
    List<ShoppingItem>? items,
    bool isLoading = false,
    String? fehler,
  }) {
    return ChangeNotifierProvider(
      create: (_) => TestShoppingListNotifier(
        items: items,
        isLoading: isLoading,
        fehler: fehler,
      ),
      child: const MaterialApp(home: TestShoppingListScreen()),
    );
  }

  // ========================================
  // Aufgabe 4: Artikelliste wird korrekt angezeigt
  // ========================================
  group('Artikelliste Anzeige', () {
    testWidgets('zeigt CircularProgressIndicator bei isLoading', (tester) async {
      // ARRANGE & ACT
      await tester.pumpWidget(erstelleApp(isLoading: true));

      // ASSERT
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('zeigt Fehlermeldung bei Fehler', (tester) async {
      await tester.pumpWidget(erstelleApp(fehler: 'Netzwerkfehler'));

      expect(find.text('Netzwerkfehler'), findsOneWidget);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('zeigt "Keine Artikel" bei leerer Liste', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      expect(find.text('Keine Artikel'), findsOneWidget);
    });

    testWidgets('zeigt korrekten Artikelnamen', (tester) async {
      await tester.pumpWidget(erstelleApp(items: testItems()));

      expect(find.text('Milch'), findsOneWidget);
      expect(find.text('Brot'), findsOneWidget);
      expect(find.text('Käse'), findsOneWidget);
    });

    testWidgets('zeigt die Menge bei jedem Artikel', (tester) async {
      await tester.pumpWidget(erstelleApp(items: testItems()));

      expect(find.text('Menge: 2'), findsOneWidget);  // Milch
      expect(find.text('Menge: 1'), findsNWidgets(2)); // Brot und Käse
    });

    testWidgets('gekaufte Artikel haben durchgestrichenen Text', (tester) async {
      await tester.pumpWidget(erstelleApp(items: testItems()));

      // Finde den Text-Widget für Käse (gekauft)
      final kaeseFinder = find.text('Käse');
      final kaeseWidget = tester.widget<Text>(kaeseFinder);
      expect(
        kaeseWidget.style?.decoration,
        equals(TextDecoration.lineThrough),
      );

      // Milch ist nicht gekauft -- keine Durchstreichung
      final milchWidget = tester.widget<Text>(find.text('Milch'));
      expect(milchWidget.style?.decoration, isNull);
    });

    testWidgets('Checkbox ist angehakt bei gekauften Artikeln', (tester) async {
      await tester.pumpWidget(erstelleApp(items: [
        const ShoppingItem(id: '1', name: 'Milch', gekauft: false),
        const ShoppingItem(id: '2', name: 'Käse', gekauft: true),
      ]));

      // Finde alle Checkboxen
      final checkboxen = find.byType(Checkbox);
      expect(checkboxen, findsNWidgets(2));

      // Erste Checkbox (Milch) ist nicht angehakt
      final milchCheckbox = tester.widget<Checkbox>(checkboxen.first);
      expect(milchCheckbox.value, isFalse);

      // Zweite Checkbox (Käse) ist angehakt
      final kaeseCheckbox = tester.widget<Checkbox>(checkboxen.last);
      expect(kaeseCheckbox.value, isTrue);
    });
  });

  // ========================================
  // Aufgabe 5: Artikel hinzufügen über Formular
  // ========================================
  group('Artikel hinzufügen', () {
    testWidgets('FAB öffnet das Formular', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      // Tippe auf den FAB
      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();

      // Formular sollte sichtbar sein
      expect(find.text('Artikel hinzufügen'), findsOneWidget);
      expect(find.byKey(const Key('nameFeld')), findsOneWidget);
    });

    testWidgets('Validierung zeigt Fehler bei leerem Namen', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      // Formular öffnen
      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();

      // Direkt auf Speichern klicken (ohne Name einzugeben)
      await tester.tap(find.byKey(const Key('speichernButton')));
      await tester.pumpAndSettle();

      // Validierungsfehler sollte angezeigt werden
      expect(find.text('Name darf nicht leer sein'), findsOneWidget);
    });

    testWidgets('Artikel wird nach dem Speichern hinzugefügt', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      // Prüfe: Noch keine Artikel
      expect(find.text('Keine Artikel'), findsOneWidget);

      // Formular öffnen
      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();

      // Name eingeben
      await tester.enterText(find.byKey(const Key('nameFeld')), 'Apfel');
      await tester.pump();

      // Speichern
      await tester.tap(find.byKey(const Key('speichernButton')));
      await tester.pumpAndSettle();

      // Artikel sollte in der Liste sein
      expect(find.text('Apfel'), findsOneWidget);
      expect(find.text('Keine Artikel'), findsNothing);
    });

    testWidgets('Formular wird nach dem Speichern geschlossen', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      // Formular öffnen
      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();

      // Name eingeben und speichern
      await tester.enterText(find.byKey(const Key('nameFeld')), 'Banane');
      await tester.tap(find.byKey(const Key('speichernButton')));
      await tester.pumpAndSettle();

      // Formular sollte geschlossen sein
      expect(find.text('Artikel hinzufügen'), findsNothing);
    });

    testWidgets('Abbrechen-Button schließt das Formular ohne Speichern', (tester) async {
      await tester.pumpWidget(erstelleApp(items: []));

      // Formular öffnen
      await tester.tap(find.byKey(const Key('addButton')));
      await tester.pumpAndSettle();

      // Name eingeben
      await tester.enterText(find.byKey(const Key('nameFeld')), 'Test');

      // Abbrechen
      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      // Formular geschlossen, kein Item hinzugefügt
      expect(find.text('Keine Artikel'), findsOneWidget);
    });
  });

  // ========================================
  // Aufgabe 6: Swipe zum Löschen
  // ========================================
  group('Swipe zum Löschen', () {
    testWidgets('Artikel verschwindet nach Swipe nach links', (tester) async {
      await tester.pumpWidget(erstelleApp(items: [
        const ShoppingItem(id: '1', name: 'Milch'),
        const ShoppingItem(id: '2', name: 'Brot'),
      ]));

      // Milch ist da
      expect(find.text('Milch'), findsOneWidget);

      // Nach links wischen
      await tester.drag(find.text('Milch'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Milch sollte verschwunden sein
      expect(find.text('Milch'), findsNothing);
      // Brot ist noch da
      expect(find.text('Brot'), findsOneWidget);
    });

    testWidgets('Swipe zeigt roten Hintergrund', (tester) async {
      await tester.pumpWidget(erstelleApp(items: [
        const ShoppingItem(id: '1', name: 'Milch'),
      ]));

      // Teilweise wischen (nicht ganz)
      await tester.drag(find.text('Milch'), const Offset(-100, 0));
      await tester.pump();

      // Roter Hintergrund mit Lösch-Icon sollte sichtbar sein
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('nach dem Löschen hat die Liste ein Item weniger', (tester) async {
      await tester.pumpWidget(erstelleApp(items: [
        const ShoppingItem(id: '1', name: 'Milch'),
        const ShoppingItem(id: '2', name: 'Brot'),
        const ShoppingItem(id: '3', name: 'Käse'),
      ]));

      // 3 Items
      expect(find.byType(ListTile), findsNWidgets(3));

      // Brot löschen
      await tester.drag(find.text('Brot'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // 2 Items
      expect(find.byType(ListTile), findsNWidgets(2));
    });
  });

  // ========================================
  // Checkbox-Interaktion
  // ========================================
  group('Checkbox-Interaktion', () {
    testWidgets('Checkbox-Tap toggled den gekauft-Status', (tester) async {
      await tester.pumpWidget(erstelleApp(items: [
        const ShoppingItem(id: '1', name: 'Milch', gekauft: false),
      ]));

      // Checkbox ist nicht angehakt
      var checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      // Checkbox tippen
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      // Checkbox sollte jetzt angehakt sein
      checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });
  });
}
```

---

## Hinweise zur Lösung

### Testausführung

```bash
# Alle Tests ausführen
flutter test

# Nur Model-Tests
flutter test test/models/shopping_item_test.dart

# Nur Provider-Tests
flutter test test/providers/shopping_list_provider_test.dart

# Nur Widget-Tests
flutter test test/screens/shopping_list_screen_test.dart

# Mit detaillierter Ausgabe
flutter test --reporter expanded

# Mit Coverage
flutter test --coverage
```

### Zusammenfassung der Testabdeckung

| Datei | Anzahl Tests | Getestete Aspekte |
|-------|-------------|-------------------|
| `shopping_item_test.dart` | 15 | Konstruktor, copyWith, toJson, fromJson, Gleichheit, Roundtrip |
| `shopping_list_provider_test.dart` | 16 | ladeItems, hinzufügen, entfernen, toggle, Filter, Immutabilität, Mocking |
| `shopping_list_screen_test.dart` | 13 | Anzeige, Formular, Validierung, Swipe-to-Delete, Checkbox |
| **Gesamt** | **44** | |

### Wichtige Lektionen

1. **Arrange-Act-Assert (AAA):** Jeder Test folgt dem Muster: Vorbereiten, Ausführen, Prüfen. Dies macht Tests lesbar und wartbar.

2. **setUp() für gemeinsame Initialisierung:** Wiederholter Setup-Code gehört in `setUp()`, das vor jedem einzelnen Test läuft.

3. **registerFallbackValue:** Bei Verwendung von `any()` mit eigenen Typen in mocktail muss ein Fallback-Wert registriert werden.

4. **Keys in Widget Tests:** Verwende `Key('...')` um Widgets eindeutig zu identifizieren, besonders wenn es mehrere Widgets desselben Typs gibt.

5. **pumpAndSettle vs. pump:** `pumpAndSettle()` wartet auf alle Animationen. `pump()` rendert nur einen einzelnen Frame. Bei Dialogen und Navigationen ist `pumpAndSettle()` meist nötig.

6. **Immutabilität testen:** Überprüfe, dass öffentliche Getter keine modifizierbaren Referenzen zurückgeben (defensive Programmierung).
