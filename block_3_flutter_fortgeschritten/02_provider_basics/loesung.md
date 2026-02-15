# Lösung 3.2: Provider Basics

## Projektstruktur

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

---

## models/shopping_item.dart

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
```

---

## providers/shopping_list_notifier.dart

```dart
import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';

class ShoppingListNotifier extends ChangeNotifier {
  final List<ShoppingItem> _items = [
    // Initiale Testdaten
    ShoppingItem(id: '1', name: 'Milch', quantity: 2, purchased: true),
    ShoppingItem(id: '2', name: 'Brot', quantity: 1),
    ShoppingItem(id: '3', name: 'Eier', quantity: 6),
  ];

  // Unmodifizierbare Liste nach außen
  List<ShoppingItem> get items => List.unmodifiable(_items);

  // Computed Properties
  int get totalCount => _items.length;

  int get purchasedCount => _items.where((i) => i.purchased).length;

  double get progress =>
      totalCount == 0 ? 0.0 : purchasedCount / totalCount;

  List<ShoppingItem> get pendingItems =>
      _items.where((i) => !i.purchased).toList();

  List<ShoppingItem> get purchasedItems =>
      _items.where((i) => i.purchased).toList();

  int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  // Mutationen
  void addItem(String name) {
    if (name.trim().isEmpty) return;

    _items.add(ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
    ));
    notifyListeners();
  }

  void togglePurchased(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    _items[index] = _items[index].copyWith(
      purchased: !_items[index].purchased,
    );
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final newQuantity = _items[index].quantity + delta;
    if (newQuantity < 1) return;

    _items[index] = _items[index].copyWith(quantity: newQuantity);
    notifyListeners();
  }

  void removeItem(String id) {
    final removed = _items.removeWhere((item) => item.id == id);
    // Nur benachrichtigen wenn etwas entfernt wurde
    notifyListeners();
  }

  void clearPurchased() {
    _items.removeWhere((item) => item.purchased);
    notifyListeners();
  }
}
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shopping_list_notifier.dart';
import 'widgets/shopping_app_bar.dart';
import 'widgets/shopping_list_view.dart';
import 'widgets/add_item_dialog.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ShoppingListNotifier(),
      child: const MyApp(),
    ),
  );
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
      home: const ShoppingPage(),
    );
  }
}

class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ShoppingAppBar(),
      body: const ShoppingListView(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Hinzufügen'),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const AddItemDialog(),
    );
  }
}
```

---

## widgets/shopping_app_bar.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_notifier.dart';

class ShoppingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShoppingAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    // Consumer für feingranulare Rebuilds
    return Consumer<ShoppingListNotifier>(
      builder: (context, notifier, _) {
        return AppBar(
          title: Text(
            'Einkaufsliste (${notifier.purchasedCount} von ${notifier.totalCount})',
          ),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(
              value: notifier.progress,
              backgroundColor: Colors.white24,
            ),
          ),
          actions: [
            if (notifier.purchasedCount > 0)
              IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Erledigte löschen',
                onPressed: () {
                  context.read<ShoppingListNotifier>().clearPurchased();
                },
              ),
          ],
        );
      },
    );
  }
}
```

---

## widgets/shopping_list_view.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_notifier.dart';
import 'shopping_item_tile.dart';

class ShoppingListView extends StatelessWidget {
  const ShoppingListView({super.key});

  @override
  Widget build(BuildContext context) {
    // watch() subscribes to changes
    final notifier = context.watch<ShoppingListNotifier>();

    if (notifier.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Keine Items vorhanden',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: notifier.items.length,
      itemBuilder: (context, index) {
        final item = notifier.items[index];
        return ShoppingItemTile(
          key: ValueKey(item.id),
          item: item,
        );
      },
    );
  }
}
```

---

## widgets/shopping_item_tile.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_notifier.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;

  const ShoppingItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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
        // read() in Callback!
        context.read<ShoppingListNotifier>().removeItem(item.id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Checkbox(
            value: item.purchased,
            onChanged: (_) {
              // read() in Callback!
              context.read<ShoppingListNotifier>().togglePurchased(item.id);
            },
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.purchased
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
              color: item.purchased ? Colors.grey : null,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove),
                onPressed: item.quantity > 1
                    ? () {
                        context
                            .read<ShoppingListNotifier>()
                            .updateQuantity(item.id, -1);
                      }
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
                onPressed: () {
                  context
                      .read<ShoppingListNotifier>()
                      .updateQuantity(item.id, 1);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## widgets/add_item_dialog.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shopping_list_notifier.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

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
    if (_controller.text.trim().isNotEmpty) {
      // read() in Callback!
      context.read<ShoppingListNotifier>().addItem(_controller.text);
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
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.sentences,
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

## Verständnisfragen - Antworten

### 1. Warum `read()` in `onPressed`?

`watch()` registriert das Widget als Listener und triggert Rebuilds bei Änderungen. In einem `onPressed`-Handler wollen wir nur eine Methode aufrufen, ohne das Widget zu subscriben. `read()` gibt einmaligen Zugriff ohne Subscription.

### 2. Was passiert bei `watch()` in `onPressed`?

Flutter wirft einen Fehler: "Tried to listen to a value exposed with provider, from outside of the widget tree." Das liegt daran, dass `watch()` im Kontext einer Build-Phase aufgerufen werden muss, nicht in einem Callback.

### 3. Wo wird `dispose()` aufgerufen?

`ChangeNotifierProvider` ruft automatisch `dispose()` auf dem `ChangeNotifier` auf, wenn der Provider aus dem Widget-Tree entfernt wird. Das passiert z.B. wenn die Seite geschlossen wird oder die App beendet wird.

### 4. Warum `List.unmodifiable()`?

Ohne `List.unmodifiable()` könnte ein Consumer die Liste direkt modifizieren:
```dart
notifier.items.add(newItem);  // Funktioniert ohne unmodifiable!
```
Das würde den State ändern, ohne `notifyListeners()` aufzurufen. Mit `List.unmodifiable()` wirft die Zeile einen Fehler.

### 5. Unterschied `watch()` vs `Consumer`

**Variante A mit `watch()`:**
- Das gesamte Widget subscribed zum Provider
- Bei Änderung wird das komplette Widget neu gebaut

**Variante B mit `Consumer`:**
- Nur der `builder`-Teil subscribed
- Bei Änderung wird nur der `builder` neu gebaut
- Der Rest des Widgets bleibt unverändert

`Consumer` ist effizienter wenn nur ein Teil des Widgets die Daten braucht. In diesem einfachen Beispiel macht es keinen großen Unterschied, aber bei komplexeren Widgets mit teuren Berechnungen oder Animationen ist `Consumer` vorzuziehen.
