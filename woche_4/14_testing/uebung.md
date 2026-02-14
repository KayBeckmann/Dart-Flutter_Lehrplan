# Modul 14: Testing -- Übung

## Tests für die Einkaufslisten-App (Modul 9)

In dieser Übung schreibst du Tests für eine Einkaufslisten-App. Falls du die App aus Modul 9 nicht vorliegen hast, findest du die zu testenden Klassen weiter unten.

---

### Voraussetzung: Zu testender Code

Falls du die App aus Modul 9 nicht zur Hand hast, erstelle folgende Dateien:

#### lib/models/shopping_item.dart

```dart
class ShoppingItem {
  final String id;
  final String name;
  final int menge;
  final String kategorie;
  final bool gekauft;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.menge = 1,
    this.kategorie = 'Sonstiges',
    this.gekauft = false,
  });

  ShoppingItem copyWith({
    String? name,
    int? menge,
    String? kategorie,
    bool? gekauft,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      menge: menge ?? this.menge,
      kategorie: kategorie ?? this.kategorie,
      gekauft: gekauft ?? this.gekauft,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'menge': menge,
    'kategorie': kategorie,
    'gekauft': gekauft,
  };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      menge: json['menge'] as int? ?? 1,
      kategorie: json['kategorie'] as String? ?? 'Sonstiges',
      gekauft: json['gekauft'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          id == other.id &&
          name == other.name &&
          menge == other.menge &&
          kategorie == other.kategorie &&
          gekauft == other.gekauft;

  @override
  int get hashCode => Object.hash(id, name, menge, kategorie, gekauft);

  @override
  String toString() => 'ShoppingItem(id: $id, name: $name, menge: $menge)';
}
```

#### lib/repositories/shopping_repository.dart

```dart
abstract class ShoppingRepository {
  Future<List<ShoppingItem>> ladeAlle();
  Future<void> speichere(ShoppingItem item);
  Future<void> aktualisiere(ShoppingItem item);
  Future<void> loesche(String id);
}
```

#### lib/providers/shopping_list_provider.dart

```dart
import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';
import '../repositories/shopping_repository.dart';

class ShoppingListProvider extends ChangeNotifier {
  final ShoppingRepository repository;
  List<ShoppingItem> _items = [];
  bool _isLoading = false;
  String? _fehler;

  ShoppingListProvider({required this.repository});

  List<ShoppingItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  String? get fehler => _fehler;

  List<ShoppingItem> get offeneItems =>
      _items.where((item) => !item.gekauft).toList();

  List<ShoppingItem> get gekaufteItems =>
      _items.where((item) => item.gekauft).toList();

  Future<void> ladeItems() async {
    _isLoading = true;
    _fehler = null;
    notifyListeners();

    try {
      _items = await repository.ladeAlle();
    } catch (e) {
      _fehler = 'Fehler beim Laden: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> itemHinzufuegen(ShoppingItem item) async {
    await repository.speichere(item);
    _items.add(item);
    notifyListeners();
  }

  Future<void> itemEntfernen(String id) async {
    await repository.loesche(id);
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  Future<void> toggleGekauft(String id) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final aktualisiert = _items[index].copyWith(
      gekauft: !_items[index].gekauft,
    );
    await repository.aktualisiere(aktualisiert);
    _items[index] = aktualisiert;
    notifyListeners();
  }
}
```

---

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

---

### Aufgabe 1: Unit Tests für ShoppingItem Model

Erstelle die Datei `test/models/shopping_item_test.dart` und schreibe Tests für:

**fromJson:**
- Erstellt korrektes Objekt bei vollständigem JSON
- Verwendet Standardwerte wenn `menge`, `kategorie` oder `gekauft` fehlen
- Test für verschiedene Kategorien

**toJson:**
- Gibt ein korrektes Map zurück
- Alle Felder sind enthalten

**copyWith:**
- Kopiert mit geändertem Namen
- Kopiert mit geändertem `gekauft`-Status
- Ohne Änderungen gibt gleichwertiges (aber nicht identisches) Objekt zurück
- Ändere mehrere Felder gleichzeitig

**Gleichheit:**
- Zwei Items mit gleichen Werten sind gleich (`==`)
- Zwei Items mit gleichen Werten haben gleichen hashCode
- Items mit unterschiedlichen IDs sind nicht gleich

**Roundtrip-Test:**
- `fromJson(item.toJson())` ergibt gleichwertiges Objekt

**Ziel:** Mindestens 10 Tests für das Model.

---

### Aufgabe 2: Unit Tests für ShoppingListProvider

Erstelle die Datei `test/providers/shopping_list_provider_test.dart` und schreibe Tests für:

**Mocking:**
- Erstelle eine `MockShoppingRepository` Klasse mit `mocktail`
- Registriere `registerFallbackValue` für `ShoppingItem` in `setUpAll`

**ladeItems:**
- Setzt `isLoading` während des Ladens
- Gibt geladene Items zurück
- Setzt `fehler` bei einer Exception
- Setzt `isLoading` zurück nach dem Laden (auch bei Fehler)

**itemHinzufuegen:**
- Fügt das Item zur Liste hinzu
- Ruft `repository.speichere()` auf
- `notifyListeners()` wird aufgerufen (Items-Liste ändert sich)

**itemEntfernen:**
- Entfernt das Item aus der Liste
- Ruft `repository.loesche()` mit der korrekten ID auf
- Item ist nach dem Entfernen nicht mehr in der Liste

**toggleGekauft:**
- Wechselt den `gekauft`-Status
- Ruft `repository.aktualisiere()` auf
- Ignoriert IDs, die nicht existieren

**offeneItems / gekaufteItems:**
- Filtert korrekt nach `gekauft`-Status

**Ziel:** Mindestens 10 Tests für den Provider.

---

### Aufgabe 3: Repository mocken

In den Provider-Tests hast du bereits ein Mock-Repository erstellt. Vertiefe das Mocking:

- Simuliere eine Netzwerk-Verzögerung mit `Future.delayed` in `thenAnswer`
- Simuliere einen Fehler mit `thenThrow`
- Verwende `verify()` um sicherzustellen, dass Methoden korrekt aufgerufen werden
- Verwende `verifyNever()` um sicherzustellen, dass Methoden NICHT aufgerufen werden
- Verwende `verifyNoMoreInteractions()` am Ende eines Tests

---

### Aufgabe 4: Widget Tests -- Artikelliste wird korrekt angezeigt

Erstelle die Datei `test/screens/shopping_list_screen_test.dart`.

Schreibe Widget Tests, die prüfen, ob die Einkaufsliste korrekt angezeigt wird:

- Zeigt eine Ladeanzeige (`CircularProgressIndicator`) wenn `isLoading == true`
- Zeigt eine Fehlermeldung wenn `fehler != null`
- Zeigt "Keine Artikel" Text bei leerer Liste
- Zeigt die korrekten Artikelnamen an
- Zeigt die Menge bei jedem Artikel
- Gekaufte Artikel haben ein anderes Aussehen (z.B. durchgestrichen)
- Checkbox ist angehakt bei gekauften Artikeln

**Hinweise:**
- Erstelle ein vereinfachtes `ShoppingListScreen`-Widget für die Tests oder mocke den Provider
- Verwende `ChangeNotifierProvider.value()` um den Provider bereitzustellen
- Du brauchst kein vollständiges Screen-Widget -- du kannst ein minimales Widget für die Tests erstellen

---

### Aufgabe 5: Widget Tests -- Artikel hinzufügen über Formular

Schreibe Widget Tests für das Hinzufügen-Formular:

- Formular wird angezeigt nach Tap auf FAB (FloatingActionButton)
- Validierung: Leerer Name zeigt Fehlermeldung
- Text-Eingabe in das Namensfeld
- Menge-Eingabe (Zahl)
- Kategorie-Auswahl (DropdownButton oder ähnlich)
- "Speichern"-Button ruft `itemHinzufuegen` auf dem Provider auf
- Nach dem Speichern wird das Formular geschlossen oder zurückgesetzt

**Hinweise:**
- Verwende `tester.enterText()` für Texteingaben
- Verwende `find.byType(TextFormField)` oder `find.byKey()` um die Felder zu finden
- Wenn du mehrere TextFormField hast, nutze `find.byKey()` mit unterschiedlichen Keys

---

### Aufgabe 6: Widget Tests -- Swipe zum Löschen

Schreibe Widget Tests für die Swipe-to-Delete-Funktionalität:

- Artikel kann nach links gewischt werden (Dismissible)
- Nach dem Wischen verschwindet der Artikel
- `itemEntfernen()` wird auf dem Provider aufgerufen
- Swipe zeigt einen roten Hintergrund mit Lösch-Icon
- Optional: Bestätigungsdialog vor dem Löschen

**Hinweise:**
- Verwende `tester.drag()` mit einem negativen X-Offset
- `pumpAndSettle()` nach dem Drag, um die Dismiss-Animation abzuschließen
- Prüfe mit `verify()` ob die Provider-Methode aufgerufen wurde

---

### Bonus-Aufgaben

**Bonus 1: TDD-Übung**
Schreibe zuerst die Tests für eine neue Funktion `sortiereNachKategorie()` im Provider, dann implementiere die Funktion.

**Bonus 2: Coverage messen**
```bash
flutter test --coverage
# Analysiere welche Zeilen nicht abgedeckt sind
```

**Bonus 3: Snapshot-Testing**
Erstelle einen Golden Test (visueller Snapshot-Test):
```dart
testWidgets('Produktkarte sieht korrekt aus', (tester) async {
  await tester.pumpWidget(/* ... */);
  await expectLater(
    find.byType(ProduktKarte),
    matchesGoldenFile('goldens/produkt_karte.png'),
  );
});
```

---

### Abgabekriterien

- [ ] Mindestens 10 Unit Tests für das ShoppingItem-Model
- [ ] Mindestens 10 Unit Tests für den ShoppingListProvider
- [ ] Mock-Repository wird korrekt eingesetzt
- [ ] Mindestens 3 Widget Tests für die Artikelliste
- [ ] Mindestens 2 Widget Tests für das Hinzufügen-Formular
- [ ] Mindestens 2 Widget Tests für Swipe-to-Delete
- [ ] Alle Tests sind grün (`flutter test` ohne Fehler)
- [ ] Tests folgen dem AAA-Pattern (Arrange-Act-Assert)
- [ ] Aussagekräftige Testnamen auf Deutsch
