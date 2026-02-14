# Modul 9: State Management mit Provider

## Lernziele

Nach diesem Modul kannst du:
- Erklaren, warum State Management in Flutter notwendig ist
- Das `provider` Package installieren und konfigurieren
- `ChangeNotifier` Klassen erstellen und nutzen
- `Consumer`, `Selector` und `Provider.of` gezielt einsetzen
- Mehrere Provider mit `MultiProvider` kombinieren
- Das MVVM-Architekturmuster mit Provider umsetzen

---

## 1. Das Problem: Warum braucht man State Management?

### setState() skaliert nicht

In Woche 2 hast du `setState()` kennengelernt. Das funktioniert prima fuer einfache Widgets:

```dart
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('$_counter')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => setState(() => _counter++),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

Aber was passiert, wenn mehrere Widgets auf denselben State zugreifen muessen?

```
        App
       /   \
    NavBar   Body
      |      /   \
   CartIcon  ProductList  CartPage
```

Das `CartIcon` in der NavBar muss die Anzahl der Artikel anzeigen. Die `ProductList` muss Artikel zum Warenkorb hinzufuegen koennen. Die `CartPage` muss alle Artikel anzeigen.

**Mit setState() muesste der State ganz oben in `App` leben.** Bei jeder Aenderung wuerde der gesamte Widget-Tree neu gebaut. Ausserdem muesstest du den State ueber Konstruktor-Parameter durch alle Ebenen hindurchreichen -- das sogenannte **"Prop Drilling"**.

```dart
// Prop Drilling -- schlecht bei tiefer Verschachtelung
class App extends StatefulWidget { ... }

class _AppState extends State<App> {
  List<Product> cart = [];

  void addToCart(Product p) {
    setState(() => cart.add(p));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: NavBar(cartCount: cart.length),  // durchreichen
        body: Body(
          cart: cart,                              // durchreichen
          onAddToCart: addToCart,                   // durchreichen
        ),
      ),
    );
  }
}
```

Das wird schnell unuebersichtlich. **State Management loest dieses Problem.**

### Die drei Kernprobleme

1. **Wo lebt der State?** -- Er soll nicht in einem einzelnen Widget gefangen sein
2. **Wie greife ich darauf zu?** -- Ohne endloses Parameter-Durchreichen
3. **Wie benachrichtige ich Widgets?** -- Wenn sich der State aendert, sollen nur die betroffenen Widgets neu gebaut werden

> **Vergleich mit JavaScript:** Das ist dasselbe Problem wie in React. Dort loest man es mit Context API, Redux, Zustand oder MobX. In Flutter ist `Provider` die offizielle Empfehlung fuer den Einstieg -- vergleichbar mit React Context + useReducer.

---

## 2. Uebersicht State-Management-Loesungen

| Loesung | Komplexitaet | Besonderheit |
|---------|-------------|--------------|
| **Provider** | Niedrig | Offizielle Empfehlung, leicht zu lernen |
| **Riverpod** | Mittel | Nachfolger von Provider, compile-safe |
| **Bloc/Cubit** | Mittel-Hoch | Event-basiert, gut fuer grosse Apps |
| **GetX** | Niedrig | All-in-one, aber kontrovers |
| **Redux** | Hoch | Bekannt aus React, viel Boilerplate |
| **MobX** | Mittel | Reaktiv, Code-Generierung |

In diesem Modul konzentrieren wir uns auf **Provider**, weil es:
- Die offizielle Empfehlung von Flutter ist
- Auf `InheritedWidget` aufbaut (Flutters eigener Mechanismus)
- Leicht zu verstehen und trotzdem maechtig ist
- Den Einstieg in andere Loesungen erleichtert

---

## 3. InheritedWidget: Das Fundament

Bevor wir Provider nutzen, solltest du verstehen, worauf es aufbaut.

`InheritedWidget` ist ein eingebauter Flutter-Mechanismus, um Daten im Widget-Tree nach unten weiterzugeben -- **ohne Prop Drilling**.

```dart
// So sieht ein InheritedWidget aus (vereinfacht)
class CartData extends InheritedWidget {
  final List<String> items;

  const CartData({
    super.key,
    required this.items,
    required super.child,
  });

  // Statische Methode zum einfachen Zugriff
  static CartData of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartData>()!;
  }

  @override
  bool updateShouldNotify(CartData oldWidget) {
    return items != oldWidget.items;
  }
}

// Verwendung: Irgendwo im Widget-Tree
class CartIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cartData = CartData.of(context);
    return Badge(
      label: Text('${cartData.items.length}'),
      child: const Icon(Icons.shopping_cart),
    );
  }
}
```

**Das Problem:** InheritedWidget direkt zu verwenden ist umstaendlich. Du musst:
- Die Klasse schreiben
- `updateShouldNotify` implementieren
- Einen StatefulWidget drum herum bauen, um den State zu aendern
- `of(context)` Pattern manuell implementieren

**Provider** nimmt dir all das ab.

---

## 4. Provider installieren und einrichten

### Installation

In deiner `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2
```

Dann im Terminal:

```bash
flutter pub get
```

### Import

```dart
import 'package:provider/provider.dart';
```

---

## 5. ChangeNotifier: Die Basis

Ein `ChangeNotifier` ist eine Klasse, die:
1. Deinen State haelt
2. Methoden bereitstellt, um den State zu aendern
3. Listener benachrichtigt, wenn sich etwas aendert

```dart
import 'package:flutter/foundation.dart';

class CounterNotifier extends ChangeNotifier {
  int _count = 0;

  // Getter: State nach aussen lesbar machen
  int get count => _count;

  // Methoden: State aendern und benachrichtigen
  void increment() {
    _count++;
    notifyListeners(); // <-- DAS ist der entscheidende Aufruf!
  }

  void decrement() {
    if (_count > 0) {
      _count--;
      notifyListeners();
    }
  }

  void reset() {
    _count = 0;
    notifyListeners();
  }
}
```

**Wichtige Regeln:**
- Felder sind `_privat` (Unterstrich)
- Zugriff nur ueber **Getter** (damit niemand den State direkt aendert)
- Nach jeder State-Aenderung: **`notifyListeners()`** aufrufen
- Vergisst du `notifyListeners()`, passiert im UI nichts!

### Ein komplexeres Beispiel: Todo-Liste

```dart
class Todo {
  final String id;
  final String title;
  bool isDone;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });
}

class TodoNotifier extends ChangeNotifier {
  final List<Todo> _todos = [];

  // Unveraenderliche Kopie nach aussen geben
  List<Todo> get todos => List.unmodifiable(_todos);

  int get totalCount => _todos.length;
  int get doneCount => _todos.where((t) => t.isDone).length;
  int get openCount => totalCount - doneCount;

  void add(String title) {
    _todos.add(Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    ));
    notifyListeners();
  }

  void toggleDone(String id) {
    final todo = _todos.firstWhere((t) => t.id == id);
    todo.isDone = !todo.isDone;
    notifyListeners();
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  void clearCompleted() {
    _todos.removeWhere((t) => t.isDone);
    notifyListeners();
  }
}
```

> **Vergleich mit Python:** Ein `ChangeNotifier` ist wie eine Python-Klasse mit dem Observer Pattern. Stell dir vor, du hast eine Klasse mit `@property` Gettern und einer `notify()` Methode, die alle registrierten Callbacks aufruft.

---

## 6. ChangeNotifierProvider: Widget-Tree wrappen

Jetzt muessen wir den `ChangeNotifier` im Widget-Tree bereitstellen:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    // Provider um die gesamte App wrappen
    ChangeNotifierProvider(
      create: (context) => CounterNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Provider Demo',
      home: const CounterPage(),
    );
  }
}
```

**Wichtig:**
- `create` erhaelt eine Funktion, die den Provider erzeugt
- Der Provider wird **lazy** erstellt (erst beim ersten Zugriff)
- Der Provider wird **automatisch disposed**, wenn er aus dem Tree entfernt wird
- Alles unterhalb von `ChangeNotifierProvider` kann auf den State zugreifen

---

## 7. Auf den State zugreifen: Drei Wege

### 7.1 Consumer\<T\> (empfohlen fuer UI)

`Consumer` ist ein Widget, das seinen Builder-Callback aufruft, wenn sich der State aendert:

```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counter')),
      body: Center(
        // Consumer baut nur diesen Teil neu
        child: Consumer<CounterNotifier>(
          builder: (context, counter, child) {
            return Text(
              '${counter.count}',
              style: Theme.of(context).textTheme.headlineLarge,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fuer Aktionen: read statt watch
          context.read<CounterNotifier>().increment();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Der `child` Parameter von Consumer:**

Wenn ein Teil des Subtrees sich nicht aendert, kannst du ihn als `child` uebergeben. Er wird dann **nicht** neu gebaut:

```dart
Consumer<CounterNotifier>(
  // child wird nur EINMAL gebaut
  child: const Text('Aktueller Stand:'),
  builder: (context, counter, child) {
    return Column(
      children: [
        child!,  // wird wiederverwendet
        Text('${counter.count}'),  // wird neu gebaut
      ],
    );
  },
)
```

### 7.2 Provider.of\<T\>(context)

Der klassische Weg:

```dart
// MIT Listening (rebuild bei Aenderung) -- wie context.watch
final counter = Provider.of<CounterNotifier>(context);

// OHNE Listening (kein rebuild) -- wie context.read
final counter = Provider.of<CounterNotifier>(context, listen: false);
```

### 7.3 context.watch\<T\>() und context.read\<T\>()

Die modernste und kuerzeste Variante (Extension Methods auf BuildContext):

```dart
// watch: Lauscht auf Aenderungen, rebuild bei Aenderung
// Verwende in build()
final counter = context.watch<CounterNotifier>();
Text('${counter.count}');

// read: Liest einmalig, KEIN rebuild
// Verwende in Callbacks (onPressed, onTap, etc.)
context.read<CounterNotifier>().increment();
```

### Wann welchen Weg?

| Situation | Methode | Grund |
|-----------|---------|-------|
| UI anzeigen | `Consumer<T>` oder `context.watch<T>()` | Braucht Rebuild |
| Button-Callback | `context.read<T>()` | Kein Rebuild noetig |
| Performance-kritisch | `Consumer<T>` mit `child` | Minimiert Rebuilds |
| Ausserhalb von `build()` | `context.read<T>()` | `watch` nur in `build()` erlaubt |

**Goldene Regel:** `watch` zum Lesen im UI, `read` zum Ausfuehren von Aktionen.

```dart
class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // watch im build -- Widget wird bei Aenderung neu gebaut
    final count = context.watch<CounterNotifier>().count;

    return Scaffold(
      body: Center(child: Text('$count')),
      floatingActionButton: FloatingActionButton(
        // read im Callback -- kein Rebuild noetig
        onPressed: () => context.read<CounterNotifier>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 8. Selector: Performance-Optimierung

`Selector` ist wie `Consumer`, aber es rebuildet nur, wenn sich ein **bestimmter Wert** aendert:

```dart
class TodoNotifier extends ChangeNotifier {
  List<Todo> _todos = [];
  String _filter = 'all';

  List<Todo> get todos => _todos;
  String get filter => _filter;
  int get doneCount => _todos.where((t) => t.isDone).length;

  // ... Methoden
}
```

```dart
// Ohne Selector: Rebuild bei JEDER Aenderung im TodoNotifier
Consumer<TodoNotifier>(
  builder: (context, notifier, _) {
    return Text('Erledigt: ${notifier.doneCount}');
  },
)

// Mit Selector: Rebuild NUR wenn sich doneCount aendert
Selector<TodoNotifier, int>(
  selector: (context, notifier) => notifier.doneCount,
  builder: (context, doneCount, child) {
    return Text('Erledigt: $doneCount');
  },
)
```

**Wann Selector verwenden?**
- Wenn der ChangeNotifier viele Felder hat
- Wenn dein Widget nur auf einen kleinen Teil des States reagieren soll
- Bei Listen: Selector kann verhindern, dass sich Widgets neu bauen, die nur die Laenge der Liste anzeigen (nicht den Inhalt)

### context.select() -- Die Extension-Variante

```dart
@override
Widget build(BuildContext context) {
  // Rebuild nur wenn sich doneCount aendert
  final doneCount = context.select<TodoNotifier, int>(
    (notifier) => notifier.doneCount,
  );

  return Text('Erledigt: $doneCount');
}
```

---

## 9. MultiProvider: Mehrere Provider

Echte Apps haben mehrere Provider. Statt sie zu verschachteln:

```dart
// SCHLECHT: Verschachtelte Provider
ChangeNotifierProvider(
  create: (_) => AuthNotifier(),
  child: ChangeNotifierProvider(
    create: (_) => CartNotifier(),
    child: ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  ),
)
```

Verwende **MultiProvider**:

```dart
// GUT: MultiProvider
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthNotifier()),
        ChangeNotifierProvider(create: (_) => CartNotifier()),
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => TodoNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}
```

Im Widget greifst du dann einfach auf den gewuenschten Provider zu:

```dart
@override
Widget build(BuildContext context) {
  final user = context.watch<AuthNotifier>().currentUser;
  final cartCount = context.select<CartNotifier, int>((c) => c.itemCount);
  final isDark = context.watch<ThemeNotifier>().isDarkMode;

  return Text('Hallo $user, $cartCount Artikel im Warenkorb');
}
```

---

## 10. ProxyProvider: Abhaengige Provider

Manchmal haengt ein Provider von einem anderen ab. Beispiel: Der `CartNotifier` braucht den aktuell eingeloggten User vom `AuthNotifier`.

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthNotifier()),

    // CartNotifier haengt von AuthNotifier ab
    ChangeNotifierProxyProvider<AuthNotifier, CartNotifier>(
      create: (_) => CartNotifier(),
      update: (context, auth, previousCart) {
        // previousCart ist der vorherige CartNotifier (oder null)
        return previousCart!..updateUserId(auth.userId);
      },
    ),
  ],
  child: const MyApp(),
)
```

Die `CartNotifier`-Klasse dazu:

```dart
class CartNotifier extends ChangeNotifier {
  String? _userId;
  List<CartItem> _items = [];

  void updateUserId(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      _items = []; // Warenkorb leeren bei User-Wechsel
      notifyListeners();
    }
  }

  // ... weitere Methoden
}
```

### ProxyProvider (nicht ChangeNotifier)

Fuer abgeleitete Werte, die kein ChangeNotifier sind:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => CartNotifier()),

    // Berechnet den Gesamtpreis basierend auf dem Warenkorb
    ProxyProvider<CartNotifier, double>(
      update: (context, cart, _) {
        return cart.items.fold(0.0, (sum, item) => sum + item.price);
      },
    ),
  ],
  child: const MyApp(),
)

// Verwendung:
final totalPrice = context.watch<double>();
```

---

## 11. Architekturmuster: MVVM mit Provider

MVVM (Model-View-ViewModel) ist ein bewaehrtes Architekturmuster, das perfekt zu Provider passt.

### Die drei Schichten

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────┐
│   Model     │     │   ViewModel      │     │    View      │
│ (Daten)     │◄────│ (ChangeNotifier)  │◄────│  (Widget)   │
│             │     │                  │     │             │
│ - User      │     │ - state          │     │ - build()   │
│ - Todo      │     │ - loadUsers()    │     │ - Consumer  │
│ - fromJson  │     │ - addTodo()      │     │ - Buttons   │
└─────────────┘     │ - notifyListeners│     └─────────────┘
                    └──────────────────┘
```

**Model:** Reine Datenklassen (kein Flutter-Code)
```dart
// models/todo.dart
class Todo {
  final String id;
  final String title;
  final bool isDone;
  final DateTime createdAt;

  const Todo({
    required this.id,
    required this.title,
    this.isDone = false,
    required this.createdAt,
  });

  Todo copyWith({
    String? title,
    bool? isDone,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
    );
  }
}
```

**ViewModel:** Geschaeftslogik + State (ChangeNotifier)
```dart
// viewmodels/todo_viewmodel.dart
import 'package:flutter/foundation.dart';

class TodoViewModel extends ChangeNotifier {
  List<Todo> _todos = [];
  bool _isLoading = false;
  String? _error;

  List<Todo> get todos => List.unmodifiable(_todos);
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalCount => _todos.length;
  int get doneCount => _todos.where((t) => t.isDone).length;

  List<Todo> get openTodos => _todos.where((t) => !t.isDone).toList();
  List<Todo> get doneTodos => _todos.where((t) => t.isDone).toList();

  Future<void> loadTodos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Hier koennten die Daten aus einer Datenbank oder API kommen
      await Future.delayed(const Duration(seconds: 1));
      _todos = [
        Todo(id: '1', title: 'Flutter lernen', createdAt: DateTime.now()),
        Todo(id: '2', title: 'Provider verstehen', createdAt: DateTime.now()),
      ];
    } catch (e) {
      _error = 'Fehler beim Laden: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addTodo(String title) {
    _todos.add(Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }

  void toggleTodo(String id) {
    _todos = _todos.map((todo) {
      if (todo.id == id) {
        return todo.copyWith(isDone: !todo.isDone);
      }
      return todo;
    }).toList();
    notifyListeners();
  }

  void removeTodo(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
```

**View:** Nur UI, keine Logik (Widget)
```dart
// views/todo_page.dart
class TodoPage extends StatelessWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Todos'),
        actions: [
          // Selector: Nur Zaehler updaten
          Selector<TodoViewModel, int>(
            selector: (_, vm) => vm.doneCount,
            builder: (_, doneCount, __) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text('$doneCount erledigt'),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<TodoViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!));
          }

          if (viewModel.todos.isEmpty) {
            return const Center(child: Text('Keine Todos vorhanden'));
          }

          return ListView.builder(
            itemCount: viewModel.todos.length,
            itemBuilder: (context, index) {
              final todo = viewModel.todos[index];
              return ListTile(
                leading: Checkbox(
                  value: todo.isDone,
                  onChanged: (_) {
                    context.read<TodoViewModel>().toggleTodo(todo.id);
                  },
                ),
                title: Text(
                  todo.title,
                  style: TextStyle(
                    decoration: todo.isDone
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    context.read<TodoViewModel>().removeTodo(todo.id);
                  },
                ),
              );
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
          decoration: const InputDecoration(hintText: 'Was ist zu tun?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                context.read<TodoViewModel>().addTodo(controller.text);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Hinzufuegen'),
          ),
        ],
      ),
    );
  }
}
```

### Projektstruktur bei MVVM

```
lib/
├── main.dart
├── models/
│   ├── todo.dart
│   └── user.dart
├── viewmodels/
│   ├── todo_viewmodel.dart
│   └── auth_viewmodel.dart
├── views/
│   ├── todo_page.dart
│   └── login_page.dart
└── widgets/
    ├── todo_tile.dart
    └── loading_indicator.dart
```

---

## 12. Vergleich mit JavaScript-Konzepten

Da du JavaScript/React kennst, hier die Parallelen:

| Flutter (Provider) | React | Beschreibung |
|-------------------|-------|-------------|
| `ChangeNotifier` | `useReducer` / Redux Store | Haelt den State und die Logik |
| `ChangeNotifierProvider` | `<Context.Provider>` | Stellt den State bereit |
| `Consumer<T>` | `<Context.Consumer>` | Konsumiert den State |
| `context.watch<T>()` | `useContext()` | Liest + lauscht |
| `context.read<T>()` | `useRef` auf Context | Liest ohne zu lauschen |
| `Selector` | `useMemo` + Selector (Redux) | Liest nur einen Teil |
| `MultiProvider` | Verschachtelte Provider | Mehrere Quellen |
| `notifyListeners()` | `dispatch()` / `setState()` | Loest Rebuild aus |

### Context API vs Provider -- Codebeispiel

**React (Context API):**
```jsx
// Context erstellen
const CounterContext = createContext();

// Provider
function App() {
  const [count, setCount] = useState(0);
  return (
    <CounterContext.Provider value={{ count, setCount }}>
      <CounterDisplay />
      <IncrementButton />
    </CounterContext.Provider>
  );
}

// Consumer
function CounterDisplay() {
  const { count } = useContext(CounterContext);
  return <p>{count}</p>;
}

function IncrementButton() {
  const { setCount } = useContext(CounterContext);
  return <button onClick={() => setCount(c => c + 1)}>+</button>;
}
```

**Flutter (Provider) -- Aequivalent:**
```dart
// ChangeNotifier (State + Logik)
class CounterNotifier extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  void increment() { _count++; notifyListeners(); }
}

// Provider + App
void main() => runApp(
  ChangeNotifierProvider(
    create: (_) => CounterNotifier(),
    child: const MyApp(),
  ),
);

// Consumer
class CounterDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final count = context.watch<CounterNotifier>().count;
    return Text('$count');
  }
}

class IncrementButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => context.read<CounterNotifier>().increment(),
      child: const Text('+'),
    );
  }
}
```

---

## 13. Haeufige Fehler und Best Practices

### Fehler 1: Provider nicht gefunden

```
Error: Could not find the correct Provider<CounterNotifier>
```

**Ursache:** Du versuchst auf einen Provider zuzugreifen, der nicht oberhalb im Widget-Tree existiert.

**Loesung:** Stelle sicher, dass `ChangeNotifierProvider` **ueber** dem Widget liegt, das darauf zugreift:

```dart
// FALSCH: Provider auf gleicher Ebene wie Consumer
MaterialApp(
  home: ChangeNotifierProvider(
    create: (_) => CounterNotifier(),
    child: const Scaffold(body: ...),
  ),
)

// RICHTIG: Provider ueber dem MaterialApp oder ueber dem Screen
ChangeNotifierProvider(
  create: (_) => CounterNotifier(),
  child: MaterialApp(home: const CounterPage()),
)
```

### Fehler 2: context.watch() ausserhalb von build()

```dart
// FALSCH: watch in initState
@override
void initState() {
  super.initState();
  final counter = context.watch<CounterNotifier>(); // CRASH!
}

// RICHTIG: read in initState, watch nur in build()
@override
void initState() {
  super.initState();
  // Fuer einmalige Aufrufe nach dem Build:
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<TodoViewModel>().loadTodos();
  });
}
```

### Fehler 3: notifyListeners() vergessen

```dart
void addItem(String item) {
  _items.add(item);
  // notifyListeners(); <-- VERGESSEN! UI aktualisiert sich nicht.
}
```

### Fehler 4: notifyListeners() nach dispose()

```dart
Future<void> loadData() async {
  _isLoading = true;
  notifyListeners();

  final data = await api.fetchData();
  _data = data;
  _isLoading = false;
  notifyListeners(); // CRASH wenn Widget bereits disposed!
}
```

**Loesung:**
```dart
@override
void dispose() {
  _isDisposed = true;
  super.dispose();
}

bool _isDisposed = false;

void _safeNotify() {
  if (!_isDisposed) {
    notifyListeners();
  }
}
```

### Fehler 5: Zu grosse Provider

```dart
// SCHLECHT: Ein Provider fuer alles
class AppState extends ChangeNotifier {
  User? user;
  List<Todo> todos;
  ThemeMode themeMode;
  List<CartItem> cart;
  String locale;
  // ... 50 weitere Felder
}

// GUT: Aufteilen in einzelne Provider
class AuthNotifier extends ChangeNotifier { ... }
class TodoNotifier extends ChangeNotifier { ... }
class ThemeNotifier extends ChangeNotifier { ... }
class CartNotifier extends ChangeNotifier { ... }
```

### Best Practices Zusammenfassung

1. **Ein Provider pro Fachbereich** (Auth, Cart, Settings, etc.)
2. **State immer privat**, Zugriff nur ueber Getter
3. **`notifyListeners()` nicht vergessen** nach State-Aenderungen
4. **`context.read<T>()`** in Callbacks, **`context.watch<T>()`** in `build()`
5. **`Selector`** verwenden, wenn nur ein Teil des States relevant ist
6. **Geschaeftslogik im ChangeNotifier**, nicht im Widget
7. **Immutable State bevorzugen** (copyWith-Pattern)
8. **Provider so hoch wie noetig, so tief wie moeglich** im Widget-Tree

---

## 14. Ausblick: Riverpod als naechste Evolution

Riverpod (ein Anagramm von "Provider") wurde vom selben Autor entwickelt und loest einige Einschraenkungen von Provider:

| Provider | Riverpod |
|----------|----------|
| Braucht BuildContext | Kein BuildContext noetig |
| Laufzeit-Fehler bei fehlendem Provider | Compile-Time Safety |
| InheritedWidget-basiert | Eigenstaendig |
| Einfacher zu lernen | Maechtigere Features |

**Riverpod Beispiel (zum Vergleich):**

```dart
// Provider definieren (global, ausserhalb von Widgets)
final counterProvider = StateNotifierProvider<CounterNotifier, int>((ref) {
  return CounterNotifier();
});

class CounterNotifier extends StateNotifier<int> {
  CounterNotifier() : super(0);

  void increment() => state++;
}

// Widget (ConsumerWidget statt StatelessWidget)
class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    return Text('$count');
  }
}
```

Fuer den Einstieg ist Provider ideal. Wenn du dich damit sicher fuehlst, lohnt sich der Umstieg auf Riverpod -- besonders fuer groessere Projekte.

---

## Zusammenfassung

```
setState()           -->  Nur fuer lokalen Widget-State
InheritedWidget      -->  Flutters eingebauter Mechanismus (zu aufwendig direkt)
Provider             -->  Wrapper um InheritedWidget, einfach zu nutzen
  ChangeNotifier     -->  Haelt State + Logik, ruft notifyListeners() auf
  ChangeNotifierProvider -->  Stellt den ChangeNotifier bereit
  Consumer/watch     -->  Liest State, rebuild bei Aenderung
  read               -->  Liest State, KEIN rebuild (fuer Aktionen)
  Selector/select    -->  Liest nur einen Teil, rebuild nur bei Aenderung davon
  MultiProvider      -->  Mehrere Provider kombinieren
  ProxyProvider      -->  Abhaengige Provider
```

Im naechsten Modul nutzen wir Provider zusammen mit HTTP-Requests, um Daten von einer API zu laden und im State zu verwalten.
