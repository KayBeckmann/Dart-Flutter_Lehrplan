# Einheit 3.2: Provider Basics

## Lernziele

Nach dieser Einheit kannst du:
- Das `provider` Package einrichten und verwenden
- `ChangeNotifier` für State-Klassen implementieren
- `ChangeNotifierProvider` korrekt einsetzen
- Zwischen `context.watch`, `context.read` und `Consumer` unterscheiden
- Häufige Fehler vermeiden

---

## 1. Provider einrichten

Provider ist das empfohlene State Management Package für Flutter (von Google selbst empfohlen).

### Installation

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1
```

```bash
flutter pub get
```

### Import

```dart
import 'package:provider/provider.dart';
```

---

## 2. ChangeNotifier: Die Basis

`ChangeNotifier` ist eine Klasse aus dem Flutter Framework, die das Observer-Pattern implementiert.

```dart
import 'package:flutter/foundation.dart';

class Counter extends ChangeNotifier {
  int _count = 0;

  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();  // Benachrichtigt alle Listener!
  }

  void decrement() {
    _count--;
    notifyListeners();
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
```

### Wichtige Regeln

```dart
class GoodNotifier extends ChangeNotifier {
  // ✅ Private Felder mit Gettern
  int _value = 0;
  int get value => _value;

  // ✅ notifyListeners() nur wenn sich wirklich etwas ändert
  void setValue(int newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  // ✅ Immutable Listen nach außen geben
  final List<String> _items = [];
  List<String> get items => List.unmodifiable(_items);

  void addItem(String item) {
    _items.add(item);
    notifyListeners();
  }
}

class BadNotifier extends ChangeNotifier {
  // ❌ Öffentliche Felder - können von außen verändert werden
  int value = 0;

  // ❌ Mutable Liste nach außen geben
  List<String> items = [];

  // ❌ notifyListeners() vergessen
  void increment() {
    value++;
    // Forgot notifyListeners()!
  }
}
```

---

## 3. ChangeNotifierProvider

`ChangeNotifierProvider` stellt eine `ChangeNotifier`-Instanz im Widget-Tree bereit.

### Einfaches Setup

```dart
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => Counter(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CounterPage(),
    );
  }
}
```

### Provider um einen Teil der App

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        // Provider nur für diesen Subtree
        create: (_) => ShoppingCart(),
        child: ShoppingPage(),
      ),
    );
  }
}
```

### Lazy vs. Non-Lazy

```dart
// Standard: Lazy (Instanz wird erst bei erstem Zugriff erstellt)
ChangeNotifierProvider(
  create: (_) => ExpensiveNotifier(),
  child: MyApp(),
);

// Non-lazy: Sofort erstellen
ChangeNotifierProvider(
  create: (_) => ExpensiveNotifier(),
  lazy: false,  // Wird sofort instanziiert
  child: MyApp(),
);
```

---

## 4. Auf Provider zugreifen

Es gibt drei Hauptwege, um auf einen Provider zuzugreifen:

### 4.1 context.watch<T>()

**Subscribed** zum Provider und **rebuildet** das Widget bei Änderungen.

```dart
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Widget wird bei jeder Änderung neu gebaut
    final counter = context.watch<Counter>();

    return Text('Count: ${counter.count}');
  }
}
```

### 4.2 context.read<T>()

Einmaliger Zugriff **ohne Subscription**. Widget wird **nicht** neu gebaut.

```dart
class IncrementButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Nur Methode aufrufen, kein Rebuild nötig
        context.read<Counter>().increment();
      },
      child: Text('Increment'),
    );
  }
}
```

### 4.3 Consumer<T>

Widget-basierte Alternative zu `context.watch`. Nützlich wenn nur ein Teil des Widgets rebuilden soll.

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Column(
        children: [
          // Nur dieser Teil rebuildet
          Consumer<Counter>(
            builder: (context, counter, child) {
              return Text('Count: ${counter.count}');
            },
          ),

          // Dieser Teil rebuildet NICHT
          Text('Static content'),
        ],
      ),
    );
  }
}
```

### Vergleich

| Methode | Rebuild bei Änderung | Use Case |
|---------|---------------------|----------|
| `context.watch<T>()` | Ja (gesamtes Widget) | Daten anzeigen |
| `context.read<T>()` | Nein | Methoden aufrufen (onPressed, etc.) |
| `Consumer<T>` | Ja (nur builder) | Teilbereich eines Widgets |

---

## 5. Wichtige Regeln

### watch() nur in build()

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // ✅ Korrekt: watch() in build()
    final counter = context.watch<Counter>();

    return ElevatedButton(
      onPressed: () {
        // ✅ Korrekt: read() in Callback
        context.read<Counter>().increment();
      },
      child: Text('${counter.count}'),
    );
  }
}
```

### Niemals watch() in Callbacks

```dart
// ❌ FALSCH: watch() in onPressed
onPressed: () {
  final counter = context.watch<Counter>();  // FEHLER!
  counter.increment();
}

// ✅ RICHTIG: read() in onPressed
onPressed: () {
  context.read<Counter>().increment();
}
```

### Provider-Scope beachten

```dart
// ❌ Fehler: Provider existiert nicht über diesem Widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Counter(),
      child: ElevatedButton(
        onPressed: () {
          // FEHLER: Counter ist im child, nicht darüber!
          context.read<Counter>().increment();
        },
        child: Text('Click'),
      ),
    );
  }
}

// ✅ Korrekt: Separates Widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Counter(),
      child: CounterButton(),  // Separates Widget
    );
  }
}

class CounterButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Jetzt ist Counter verfügbar
    return ElevatedButton(
      onPressed: () => context.read<Counter>().increment(),
      child: Text('Click'),
    );
  }
}
```

---

## 6. Vollständiges Beispiel

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => TodoList(),
      child: const MyApp(),
    ),
  );
}

// Model
class Todo {
  final String id;
  final String title;
  bool completed;

  Todo({required this.id, required this.title, this.completed = false});
}

// State/Notifier
class TodoList extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);
  int get completedCount => _todos.where((t) => t.completed).length;
  int get totalCount => _todos.length;

  void add(String title) {
    _todos.add(Todo(
      id: DateTime.now().toString(),
      title: title,
    ));
    notifyListeners();
  }

  void toggle(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.completed = !todo.completed;
    notifyListeners();
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}

// App
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TodoPage(),
    );
  }
}

// Page
class TodoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<TodoList>(
          builder: (_, todoList, __) {
            return Text(
              'Todos (${todoList.completedCount}/${todoList.totalCount})',
            );
          },
        ),
      ),
      body: Consumer<TodoList>(
        builder: (_, todoList, __) {
          if (todoList.todos.isEmpty) {
            return const Center(child: Text('Keine Todos'));
          }

          return ListView.builder(
            itemCount: todoList.todos.length,
            itemBuilder: (context, index) {
              final todo = todoList.todos[index];
              return TodoTile(todo: todo);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Neues Todo'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                // read() in Callback!
                context.read<TodoList>().add(controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }
}

// Todo Item
class TodoTile extends StatelessWidget {
  final Todo todo;

  const TodoTile({super.key, required this.todo});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.completed,
        onChanged: (_) => context.read<TodoList>().toggle(todo.id),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () => context.read<TodoList>().remove(todo.id),
      ),
    );
  }
}
```

---

## 7. dispose() nicht vergessen

`ChangeNotifierProvider` ruft automatisch `dispose()` auf dem `ChangeNotifier` auf, wenn der Provider aus dem Widget-Tree entfernt wird.

```dart
class MyNotifier extends ChangeNotifier {
  final StreamSubscription _subscription;

  MyNotifier(Stream stream)
      : _subscription = stream.listen((_) {});

  @override
  void dispose() {
    _subscription.cancel();  // Ressourcen freigeben!
    super.dispose();
  }
}
```

---

## Zusammenfassung

| Konzept | Verwendung |
|---------|-----------|
| `ChangeNotifier` | State-Klasse, ruft `notifyListeners()` bei Änderungen |
| `ChangeNotifierProvider` | Stellt ChangeNotifier im Widget-Tree bereit |
| `context.watch<T>()` | Lesen + Subscription (in `build()`) |
| `context.read<T>()` | Nur lesen, keine Subscription (in Callbacks) |
| `Consumer<T>` | Widget-basierte Alternative zu `watch()` |

**Goldene Regeln:**
1. `watch()` nur in `build()`
2. `read()` für Callbacks (onPressed, etc.)
3. Private Felder + Getter in ChangeNotifier
4. `notifyListeners()` nur bei echten Änderungen
