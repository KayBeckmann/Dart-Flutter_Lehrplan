# Übung 3.2: Provider Basics

## Ziel

Die Einkaufslisten-App aus Einheit 3.1 auf Provider umstellen.

---

## Aufgabe 1: Setup (10 min)

1. Erstelle ein neues Flutter-Projekt oder verwende das bestehende
2. Füge `provider: ^6.1.1` zur `pubspec.yaml` hinzu
3. Führe `flutter pub get` aus
4. Importiere Provider in deiner `main.dart`

---

## Aufgabe 2: ChangeNotifier erstellen (20 min)

Erstelle eine `ShoppingListNotifier`-Klasse:

```dart
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool purchased;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.purchased = false,
  });

  ShoppingItem copyWith({String? name, int? quantity, bool? purchased}) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchased: purchased ?? this.purchased,
    );
  }
}
```

Der `ShoppingListNotifier` soll implementieren:

- `List<ShoppingItem> get items` - Unmodifizierbare Liste
- `int get totalCount` - Gesamtzahl
- `int get purchasedCount` - Anzahl erledigter Items
- `void addItem(String name)` - Neues Item hinzufügen
- `void togglePurchased(String id)` - Purchased-Status umschalten
- `void updateQuantity(String id, int delta)` - Menge ändern (+1 oder -1)
- `void removeItem(String id)` - Item entfernen

---

## Aufgabe 3: Provider einrichten (10 min)

1. Wrape deine `MaterialApp` mit einem `ChangeNotifierProvider`
2. Stelle sicher, dass der Provider über der gesamten App liegt

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ShoppingListNotifier(),
      child: const MyApp(),
    ),
  );
}
```

---

## Aufgabe 4: Widgets umbauen (30 min)

Baue die Widgets um, sodass sie Provider verwenden:

### 4.1 ShoppingAppBar

- Verwende `Consumer<ShoppingListNotifier>` oder `context.watch`
- Zeige "Einkaufsliste (X von Y erledigt)"

### 4.2 ShoppingListView

- Entferne alle Callback-Parameter
- Greife direkt auf den Provider zu

### 4.3 ShoppingItemTile

- Verwende `context.read` für die Callbacks (onPressed)
- Das Item selbst kommt weiterhin als Parameter

### Beispiel für ein Item:

```dart
class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;

  const ShoppingItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: item.purchased,
        onChanged: (_) {
          // read() für Callbacks!
          context.read<ShoppingListNotifier>().togglePurchased(item.id);
        },
      ),
      // ... rest des Widgets
    );
  }
}
```

---

## Aufgabe 5: Verständnisfragen

Beantworte folgende Fragen:

1. Warum verwenden wir `context.read()` in `onPressed` und nicht `context.watch()`?

2. Was passiert, wenn du `context.watch()` in einem `onPressed`-Handler verwendest?

3. Wo genau wird `dispose()` auf dem `ChangeNotifier` aufgerufen?

4. Warum geben wir `List.unmodifiable(_items)` zurück statt `_items` direkt?

5. Was ist der Unterschied zwischen:
   ```dart
   // Variante A
   final notifier = context.watch<ShoppingListNotifier>();
   return Text('${notifier.totalCount}');

   // Variante B
   return Consumer<ShoppingListNotifier>(
     builder: (_, notifier, __) => Text('${notifier.totalCount}'),
   );
   ```

---

## Aufgabe 6: Bonus - Computed Properties

Füge dem `ShoppingListNotifier` hinzu:

1. `double get progress` - Fortschritt als Wert zwischen 0.0 und 1.0
2. `List<ShoppingItem> get pendingItems` - Nur nicht-erledigte Items
3. `List<ShoppingItem> get purchasedItems` - Nur erledigte Items
4. `int get totalQuantity` - Summe aller Mengen

Zeige den Fortschritt als `LinearProgressIndicator` in der AppBar an:

```
┌─────────────────────────────────┐
│ Einkaufsliste (2 von 4)        │
│ ████████░░░░░░░░░░ 50%         │
├─────────────────────────────────┤
```

---

## Abgabe-Checkliste

- [ ] Provider Package installiert
- [ ] `ShoppingListNotifier` implementiert mit allen Methoden
- [ ] Provider korrekt in `main()` eingerichtet
- [ ] `context.watch()` nur in `build()` verwendet
- [ ] `context.read()` in Callbacks verwendet
- [ ] App funktioniert wie zuvor
- [ ] Kein Prop Drilling mehr nötig
- [ ] Verständnisfragen beantwortet

---

## Erwartete Projektstruktur

```
lib/
├── main.dart
├── models/
│   └── shopping_item.dart
├── providers/
│   └── shopping_list_notifier.dart
└── widgets/
    ├── shopping_app_bar.dart
    ├── shopping_list_view.dart
    ├── shopping_item_tile.dart
    └── add_item_dialog.dart
```
