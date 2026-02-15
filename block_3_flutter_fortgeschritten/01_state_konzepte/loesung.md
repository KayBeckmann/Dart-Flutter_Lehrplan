# Lösung 3.1: State Management Konzepte

## Aufgabe 1: Prop Drilling Analyse

1. **Wo lebt der State?**
   - In `ShoppingApp` (oberste Ebene), da mehrere Kinder Zugriff brauchen

2. **Welche Widgets brauchen State-Zugriff?**
   - `AppBar`: Lesend (Anzahl Items)
   - `ShoppingList`: Lesend (alle Items)
   - `ShoppingItem`: Lesend (einzelnes Item)

3. **Welche Widgets brauchen Callbacks?**
   - `DeleteButton`: `onDelete`
   - `AddItemButton`: `onAdd`
   - `ItemQuantity`: `onQuantityChanged`
   - Checkbox: `onToggle`

4. **Prop Drilling Pfade:**
   - `ShoppingApp` → `ShoppingList` → `ShoppingItem` → `DeleteButton`
   - Jedes Widget dazwischen muss Parameter durchreichen

---

## Aufgabe 2: Einkaufslisten-App

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Einkaufsliste',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ShoppingApp(),
    );
  }
}

// Datenmodell
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

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    bool? purchased,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      purchased: purchased ?? this.purchased,
    );
  }
}

// Haupt-Widget mit State
class ShoppingApp extends StatefulWidget {
  const ShoppingApp({super.key});

  @override
  State<ShoppingApp> createState() => _ShoppingAppState();
}

class _ShoppingAppState extends State<ShoppingApp> {
  final List<ShoppingItem> _items = [
    ShoppingItem(id: '1', name: 'Milch', quantity: 2, purchased: true),
    ShoppingItem(id: '2', name: 'Brot', quantity: 1, purchased: true),
    ShoppingItem(id: '3', name: 'Eier', quantity: 6),
    ShoppingItem(id: '4', name: 'Butter', quantity: 1),
  ];

  void _addItem(String name) {
    setState(() {
      _items.add(ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
      ));
    });
  }

  void _togglePurchased(String id) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        _items[index] = _items[index].copyWith(
          purchased: !_items[index].purchased,
        );
      }
    });
  }

  void _updateQuantity(String id, int delta) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index != -1) {
        final newQuantity = _items[index].quantity + delta;
        if (newQuantity > 0) {
          _items[index] = _items[index].copyWith(quantity: newQuantity);
        }
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      _items.removeWhere((item) => item.id == id);
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(onAdd: _addItem),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ShoppingAppBar(items: _items),
      body: ShoppingListView(
        items: _items,
        onToggle: _togglePurchased,
        onQuantityChanged: _updateQuantity,
        onRemove: _removeItem,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Hinzufügen'),
      ),
    );
  }
}

// AppBar mit Item-Zähler
class ShoppingAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<ShoppingItem> items;

  const ShoppingAppBar({super.key, required this.items});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final purchasedCount = items.where((item) => item.purchased).length;
    final totalCount = items.length;

    return AppBar(
      title: Text('Einkaufsliste ($purchasedCount von $totalCount erledigt)'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    );
  }
}

// Liste der Items
class ShoppingListView extends StatelessWidget {
  final List<ShoppingItem> items;
  final void Function(String id) onToggle;
  final void Function(String id, int delta) onQuantityChanged;
  final void Function(String id) onRemove;

  const ShoppingListView({
    super.key,
    required this.items,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Keine Items vorhanden'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return ShoppingItemTile(
          item: item,
          onToggle: () => onToggle(item.id),
          onQuantityChanged: (delta) => onQuantityChanged(item.id, delta),
          onRemove: () => onRemove(item.id),
        );
      },
    );
  }
}

// Einzelnes Item
class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggle;
  final void Function(int delta) onQuantityChanged;
  final VoidCallback onRemove;

  const ShoppingItemTile({
    super.key,
    required this.item,
    required this.onToggle,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.purchased,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.purchased
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            color: item.purchased
                ? Colors.grey
                : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: item.quantity > 1
                  ? () => onQuantityChanged(-1)
                  : null,
            ),
            SizedBox(
              width: 30,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => onQuantityChanged(1),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// Dialog zum Hinzufügen
class AddItemDialog extends StatefulWidget {
  final void Function(String name) onAdd;

  const AddItemDialog({super.key, required this.onAdd});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) {
      widget.onAdd(name);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neues Item'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Name eingeben',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 3: InheritedWidget Theorie

1. **dependOnInheritedWidgetOfExactType vs. getInheritedWidgetOfExactType:**
   - `dependOn...`: Registriert das Widget als Dependent. Wenn sich `InheritedWidget` ändert, wird das Widget neu gebaut.
   - `get...`: Nur Lesezugriff ohne Subscription. Widget wird NICHT neu gebaut bei Änderungen.

2. **updateShouldNotify:**
   - Bestimmt, ob Dependents benachrichtigt werden sollen
   - `true`: Wenn sich relevante Daten geändert haben → Rebuild der Dependents
   - `false`: Keine Änderung → kein Rebuild
   - Typisch: `return oldWidget.value != value;`

3. **Warum StatefulWidget zusätzlich?**
   - `InheritedWidget` selbst ist immutable
   - Das `StatefulWidget` hält den mutablen State und ruft `setState()` auf
   - Bei `setState()` wird ein neues `InheritedWidget` mit neuen Werten erstellt

4. **Wenn kein InheritedWidget im Tree:**
   - `dependOnInheritedWidgetOfExactType` gibt `null` zurück
   - Typischerweise wirft man dann eine Exception oder verwendet einen Default
   - Darum: `context.dependOn...()!` oder null-check

---

## Aufgabe 4: State-Kategorisierung

| State | Kategorie | Begründung |
|-------|-----------|------------|
| Aktueller Tab-Index | **Ephemeral** | Lokal in TabBar, kein anderes Widget braucht ihn |
| Eingeloggter User | **App State** | Global, viele Widgets brauchen die Info |
| Scroll-Position | **Ephemeral** | Lokal im ScrollController |
| Dark/Light Mode | **App State** | Global, beeinflusst gesamte App |
| Formular-Eingaben | **Ephemeral** | Lokal während Eingabe (wird App State bei Submit) |
| Warenkorb-Inhalt | **App State** | Wird auf mehreren Screens gebraucht |
| Animation-Progress | **Ephemeral** | Lokal im AnimationController |
| Ausgewähltes Element | **Kommt drauf an** | Ephemeral wenn lokal, App State wenn andere Screens es brauchen |
| Offline-Cache | **App State** | Global, persistiert |
| Dropdown offen/zu | **Ephemeral** | Lokaler UI-State |

---

## Bonus: ChangeNotifier

```dart
class ShoppingListNotifier extends ChangeNotifier {
  final List<ShoppingItem> _items = [];

  // Unmodifizierbare Kopie nach außen geben
  List<ShoppingItem> get items => List.unmodifiable(_items);

  int get purchasedCount => _items.where((i) => i.purchased).length;
  int get totalCount => _items.length;

  // Computed Property für Fortschritt
  double get progress =>
      totalCount == 0 ? 0 : purchasedCount / totalCount;

  void addItem(String name) {
    _items.add(ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    ));
    notifyListeners();
  }

  void togglePurchased(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        purchased: !_items[index].purchased,
      );
      notifyListeners();
    }
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final newQuantity = _items[index].quantity + delta;
      if (newQuantity > 0) {
        _items[index] = _items[index].copyWith(quantity: newQuantity);
        notifyListeners();
      }
    }
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Optional: Alle als erledigt markieren
  void markAllPurchased() {
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].purchased) {
        _items[i] = _items[i].copyWith(purchased: true);
      }
    }
    notifyListeners();
  }

  // Optional: Erledigte entfernen
  void clearPurchased() {
    _items.removeWhere((item) => item.purchased);
    notifyListeners();
  }
}
```

Dieser `ChangeNotifier` kann in der nächsten Einheit direkt mit Provider verwendet werden.
