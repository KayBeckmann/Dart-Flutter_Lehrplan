# Modul 9: Loesung -- Einkaufslisten-App mit Provider

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   └── shopping_item.dart
├── providers/
│   ├── shopping_list_provider.dart
│   └── stats_provider.dart
├── screens/
│   ├── shopping_list_screen.dart
│   ├── add_item_screen.dart
│   └── stats_screen.dart
└── widgets/
    └── shopping_item_tile.dart
```

## pubspec.yaml (relevanter Ausschnitt)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
```

---

## models/shopping_item.dart

```dart
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool isBought;
  final String category;

  const ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.isBought = false,
    required this.category,
  });

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    bool? isBought,
    String? category,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isBought: isBought ?? this.isBought,
      category: category ?? this.category,
    );
  }

  static const List<String> categories = [
    'Obst & Gemuese',
    'Getraenke',
    'Milchprodukte',
    'Fleisch & Fisch',
    'Backwaren',
    'Haushalt',
    'Sonstiges',
  ];
}
```

---

## providers/shopping_list_provider.dart

```dart
import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';

class ShoppingListProvider extends ChangeNotifier {
  final List<ShoppingItem> _items = [];

  // --- Getter ---

  List<ShoppingItem> get items => List.unmodifiable(_items);

  List<ShoppingItem> get boughtItems =>
      _items.where((item) => item.isBought).toList();

  List<ShoppingItem> get unboughtItems =>
      _items.where((item) => !item.isBought).toList();

  /// Gibt die Artikel gruppiert nach Kategorie zurueck.
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in _items) {
      grouped.putIfAbsent(item.category, () => []);
      grouped[item.category]!.add(item);
    }
    return grouped;
  }

  int get totalCount => _items.length;
  int get boughtCount => _items.where((i) => i.isBought).length;
  int get unboughtCount => totalCount - boughtCount;

  // --- Methoden ---

  void addItem({
    required String name,
    required String category,
    int quantity = 1,
  }) {
    final item = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      category: category,
      quantity: quantity,
    );
    _items.add(item);
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Gibt das entfernte Item zurueck (fuer Undo-Funktionalitaet).
  ShoppingItem? removeItemWithUndo(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return null;
    final removed = _items.removeAt(index);
    notifyListeners();
    return removed;
  }

  void reInsertItem(ShoppingItem item, {int? index}) {
    if (index != null && index <= _items.length) {
      _items.insert(index, item);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void toggleBought(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isBought: !_items[index].isBought);
      notifyListeners();
    }
  }

  void updateQuantity(String id, int newQuantity) {
    if (newQuantity < 1) return;
    final index = _items.indexWhere((item) => item.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(quantity: newQuantity);
      notifyListeners();
    }
  }

  void clearBought() {
    _items.removeWhere((item) => item.isBought);
    notifyListeners();
  }
}
```

---

## providers/stats_provider.dart

```dart
import 'package:flutter/foundation.dart';
import 'shopping_list_provider.dart';

class StatsProvider extends ChangeNotifier {
  int _totalCount = 0;
  int _boughtCount = 0;
  int _unboughtCount = 0;
  double _progress = 0.0;
  int _categoryCount = 0;

  int get totalCount => _totalCount;
  int get boughtCount => _boughtCount;
  int get unboughtCount => _unboughtCount;
  double get progress => _progress;
  int get categoryCount => _categoryCount;

  /// Wird vom ProxyProvider aufgerufen, wenn sich der
  /// ShoppingListProvider aendert.
  void update(ShoppingListProvider shoppingList) {
    _totalCount = shoppingList.totalCount;
    _boughtCount = shoppingList.boughtCount;
    _unboughtCount = shoppingList.unboughtCount;
    _progress = _totalCount > 0 ? _boughtCount / _totalCount : 0.0;
    _categoryCount = shoppingList.itemsByCategory.keys.length;
    notifyListeners();
  }
}
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/shopping_list_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/shopping_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ShoppingListProvider(),
        ),
        ChangeNotifierProxyProvider<ShoppingListProvider, StatsProvider>(
          create: (_) => StatsProvider(),
          update: (_, shoppingList, statsProvider) {
            statsProvider!.update(shoppingList);
            return statsProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Einkaufsliste',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        home: const ShoppingListScreen(),
      ),
    );
  }
}
```

---

## screens/shopping_list_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';
import '../widgets/shopping_item_tile.dart';
import 'add_item_screen.dart';
import 'stats_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufsliste'),
        actions: [
          // Selector: Nur die Anzahl der gekauften Artikel beobachten
          Selector<ShoppingListProvider, int>(
            selector: (_, provider) => provider.boughtCount,
            builder: (_, boughtCount, child) {
              return Badge(
                isLabelVisible: boughtCount > 0,
                label: Text('$boughtCount'),
                child: child,
              );
            },
            child: IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Statistiken',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const StatsScreen(),
                  ),
                );
              },
            ),
          ),
          // Consumer mit child-Parameter: Icon bleibt stabil
          Consumer<ShoppingListProvider>(
            child: const Icon(Icons.delete_sweep),
            builder: (context, provider, child) {
              return IconButton(
                icon: child!,
                tooltip: 'Gekaufte entfernen',
                onPressed: provider.boughtCount > 0
                    ? () {
                        _showClearDialog(context);
                      }
                    : null,
              );
            },
          ),
        ],
      ),
      body: Consumer<ShoppingListProvider>(
        builder: (context, provider, _) {
          if (provider.items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Deine Einkaufsliste ist leer',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tippe auf + um Artikel hinzuzufuegen',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final grouped = provider.itemsByCategory;
          final categories = grouped.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final items = grouped[category]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  ...items.map((item) => ShoppingItemTile(item: item)),
                  if (index < categories.length - 1)
                    const Divider(indent: 16, endIndent: 16),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Artikel'),
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gekaufte Artikel entfernen?'),
        content: const Text(
          'Alle als gekauft markierten Artikel werden entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () {
              context.read<ShoppingListProvider>().clearBought();
              Navigator.pop(dialogContext);
            },
            child: const Text('Entfernen'),
          ),
        ],
      ),
    );
  }
}
```

---

## screens/add_item_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item.dart';
import '../providers/shopping_list_provider.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  String _selectedCategory = ShoppingItem.categories.first;
  int _quantity = 1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Namen eingeben')),
      );
      return;
    }

    // context.read -- keine Listener, nur Aktion ausfuehren
    context.read<ShoppingListProvider>().addItem(
          name: name,
          category: _selectedCategory,
          quantity: _quantity,
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artikel hinzufuegen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Artikelname ---
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Artikelname',
                hintText: 'z.B. Aepfel',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.shopping_bag_outlined),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _saveItem(),
            ),
            const SizedBox(height: 16),

            // --- Kategorie ---
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategorie',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ShoppingItem.categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // --- Menge ---
            Row(
              children: [
                const Text('Menge:', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton.filled(
                  onPressed: _quantity > 1
                      ? () => setState(() => _quantity--)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '$_quantity',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton.filled(
                  onPressed: () => setState(() => _quantity++),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- Speichern ---
            FilledButton.icon(
              onPressed: _saveItem,
              icon: const Icon(Icons.check),
              label: const Text('Artikel hinzufuegen'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## screens/stats_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiken'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Fortschrittsanzeige ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Einkaufsfortschritt',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),

                    // context.select: Rebuild nur bei Fortschritts-Aenderung
                    Builder(
                      builder: (context) {
                        final progress = context.select<StatsProvider, double>(
                          (stats) => stats.progress,
                        );
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 20,
                                backgroundColor: Colors.grey[200],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(progress * 100).toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- Detaillierte Statistiken ---
            Consumer<StatsProvider>(
              builder: (context, stats, _) {
                return Column(
                  children: [
                    _StatCard(
                      icon: Icons.list_alt,
                      label: 'Artikel gesamt',
                      value: '${stats.totalCount}',
                      color: Colors.blue,
                    ),
                    _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Gekauft',
                      value: '${stats.boughtCount}',
                      color: Colors.green,
                    ),
                    _StatCard(
                      icon: Icons.radio_button_unchecked,
                      label: 'Offen',
                      value: '${stats.unboughtCount}',
                      color: Colors.orange,
                    ),
                    _StatCard(
                      icon: Icons.category_outlined,
                      label: 'Kategorien',
                      value: '${stats.categoryCount}',
                      color: Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ),
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
import '../providers/shopping_list_provider.dart';

class ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;

  const ShoppingItemTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        // context.read: Aktion ausfuehren, kein Rebuild noetig
        final provider = context.read<ShoppingListProvider>();
        final removedItem = provider.removeItemWithUndo(item.id);

        if (removedItem != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${removedItem.name} entfernt'),
              action: SnackBarAction(
                label: 'Rueckgaengig',
                onPressed: () {
                  provider.reInsertItem(removedItem);
                },
              ),
            ),
          );
        }
      },
      child: ListTile(
        leading: Checkbox(
          value: item.isBought,
          onChanged: (_) {
            context.read<ShoppingListProvider>().toggleBought(item.id);
          },
        ),
        title: Text(
          item.name,
          style: TextStyle(
            decoration: item.isBought ? TextDecoration.lineThrough : null,
            color: item.isBought ? Colors.grey : null,
          ),
        ),
        subtitle: item.quantity > 1 ? Text('Menge: ${item.quantity}') : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: item.quantity > 1
                  ? () {
                      context
                          .read<ShoppingListProvider>()
                          .updateQuantity(item.id, item.quantity - 1);
                    }
                  : null,
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: () {
                context
                    .read<ShoppingListProvider>()
                    .updateQuantity(item.id, item.quantity + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Erklaerung der Loesung

### Provider-Zugriffsmethoden (wie in der Aufgabe gefordert)

| Methode | Wo verwendet | Datei |
|---------|-------------|-------|
| `Consumer<T>` | Artikelliste, Statistiken | shopping_list_screen.dart, stats_screen.dart |
| `Consumer` mit `child` | "Gekaufte entfernen"-Button (Icon bleibt stabil) | shopping_list_screen.dart |
| `context.watch<T>()` | (Alternativ nutzbar statt Consumer) | -- |
| `context.read<T>()` | Alle Button-Callbacks (addItem, toggleBought, removeItem) | add_item_screen.dart, shopping_item_tile.dart |
| `Selector<T,S>` | Badge-Zaehler in der AppBar | shopping_list_screen.dart |
| `context.select<T,S>()` | Fortschrittsbalken (nur progress-Wert) | stats_screen.dart |

### Architektur-Entscheidungen

1. **Zwei separate Provider:** ShoppingListProvider haelt die Daten, StatsProvider berechnet abgeleitete Werte. Der ProxyProvider verbindet beide.

2. **copyWith-Pattern:** ShoppingItem ist im Wesentlichen immutabel. Aenderungen erzeugen neue Instanzen.

3. **Undo-Funktionalitaet:** `removeItemWithUndo()` gibt das entfernte Item zurueck, sodass es mit einer SnackBar-Action wiederhergestellt werden kann.

4. **Gruppierung nach Kategorie:** `itemsByCategory` gibt eine Map zurueck, die in der ListView pro Kategorie dargestellt wird.

5. **Performance:** Selector wird gezielt eingesetzt, damit z.B. das Badge nur bei Aenderung der `boughtCount`-Zahl neu gebaut wird, nicht bei jeder beliebigen Aenderung der Einkaufsliste.
