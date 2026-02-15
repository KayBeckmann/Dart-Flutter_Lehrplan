# Einheit 3.1: State Management Konzepte

## Lernziele

Nach dieser Einheit kannst du:
- Erklären, warum State Management in Flutter wichtig ist
- Die Grenzen von `setState()` verstehen
- Das "Lifting State Up"-Pattern anwenden
- `InheritedWidget` konzeptionell verstehen
- Verschiedene State Management Lösungen einordnen

---

## 1. Was ist "State" in Flutter?

**State** ist jede Information, die sich während der Laufzeit einer App ändern kann und die UI beeinflusst:

```dart
// Beispiele für State:
int counter = 0;              // UI-State: Zählerstand
bool isLoggedIn = false;      // App-State: Authentifizierung
List<Todo> todos = [];        // Daten-State: Liste von Items
String searchQuery = '';      // Formular-State: Eingaben
ThemeMode themeMode;          // Einstellungen: Dark/Light Mode
```

### Arten von State

| Art | Beschreibung | Beispiel |
|-----|--------------|----------|
| **Ephemeral State** | Lokal, kurzlebig, nur in einem Widget | Animation, Scroll-Position, Tab-Index |
| **App State** | Global, langlebig, widget-übergreifend | User-Session, Warenkorb, Einstellungen |

**Faustregel:** Wenn mehrere Widgets denselben State brauchen, ist es App State.

---

## 2. Das Problem mit `setState()`

`setState()` funktioniert gut für einfachen, lokalen State:

```dart
class CounterWidget extends StatefulWidget {
  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $_count'),
        ElevatedButton(
          onPressed: _increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

### Probleme bei wachsender Komplexität

```
        App
         │
    ┌────┴────┐
    │         │
  Home     Settings
    │
 ┌──┴──┐
 │     │
List  Detail
 │
Item ← Braucht State von App!
```

**Problem:** Wenn `Item` einen State braucht, der in `App` definiert ist, müsste der State durch `Home`, `List` und `Item` durchgereicht werden.

```dart
// ❌ "Prop Drilling" - State durch alle Ebenen durchreichen
class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<Todo> todos = [];

  void addTodo(Todo todo) {
    setState(() => todos.add(todo));
  }

  @override
  Widget build(BuildContext context) {
    return Home(
      todos: todos,           // Durchreichen
      onAddTodo: addTodo,     // Durchreichen
    );
  }
}

class Home extends StatelessWidget {
  final List<Todo> todos;
  final void Function(Todo) onAddTodo;

  Home({required this.todos, required this.onAddTodo});

  @override
  Widget build(BuildContext context) {
    return TodoList(
      todos: todos,           // Wieder durchreichen
      onAddTodo: onAddTodo,   // Wieder durchreichen
    );
  }
}

// ... und so weiter durch jede Ebene
```

**Nachteile:**
1. **Boilerplate:** Jedes Widget dazwischen braucht die Parameter
2. **Wartbarkeit:** Änderungen erfordern Anpassungen in vielen Dateien
3. **Performance:** Alle Widgets werden neu gebaut, auch wenn sie den State nicht nutzen

---

## 3. Lifting State Up

Das einfachste Pattern für geteilten State: Den State zum nächsten gemeinsamen Vorfahren "hochheben".

```dart
// Vorher: Jedes Widget hat eigenen State
class WidgetA extends StatefulWidget { /* eigener counter */ }
class WidgetB extends StatefulWidget { /* eigener counter */ }

// Nachher: Gemeinsamer State im Parent
class ParentWidget extends StatefulWidget {
  @override
  State<ParentWidget> createState() => _ParentWidgetState();
}

class _ParentWidgetState extends State<ParentWidget> {
  int _counter = 0;

  void _increment() {
    setState(() => _counter++);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // State und Callback werden als Props übergeben
        DisplayWidget(counter: _counter),
        ButtonWidget(onIncrement: _increment),
      ],
    );
  }
}

class DisplayWidget extends StatelessWidget {
  final int counter;

  DisplayWidget({required this.counter});

  @override
  Widget build(BuildContext context) {
    return Text('Count: $counter');
  }
}

class ButtonWidget extends StatelessWidget {
  final VoidCallback onIncrement;

  ButtonWidget({required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onIncrement,
      child: Text('Increment'),
    );
  }
}
```

**Wann Lifting State Up verwenden:**
- Wenige Ebenen zwischen State-Owner und State-Consumer
- Einfache State-Strukturen
- Kleine Widget-Bäume

---

## 4. InheritedWidget: Flutters eingebauter Mechanismus

`InheritedWidget` ermöglicht es, Daten effizient im Widget-Tree bereitzustellen, ohne sie durch jeden Konstruktor zu reichen.

### Das Konzept

```
        InheritedWidget (State lebt hier)
              │
         ┌────┴────┐
         │         │
       Child     Child
         │
       Child
         │
    Nachfahre ← Direkter Zugriff auf State!
```

### Einfaches Beispiel

```dart
// 1. InheritedWidget definieren
class CounterInherited extends InheritedWidget {
  final int count;
  final void Function() increment;

  CounterInherited({
    required this.count,
    required this.increment,
    required Widget child,
  }) : super(child: child);

  // Statische Methode für einfachen Zugriff
  static CounterInherited of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CounterInherited>()!;
  }

  @override
  bool updateShouldNotify(CounterInherited oldWidget) {
    return count != oldWidget.count;
  }
}

// 2. StatefulWidget als "Owner" des State
class CounterProvider extends StatefulWidget {
  final Widget child;

  CounterProvider({required this.child});

  @override
  State<CounterProvider> createState() => _CounterProviderState();
}

class _CounterProviderState extends State<CounterProvider> {
  int _count = 0;

  void _increment() {
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    return CounterInherited(
      count: _count,
      increment: _increment,
      child: widget.child,
    );
  }
}

// 3. Verwendung in der App
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CounterProvider(
      child: MaterialApp(
        home: CounterPage(),
      ),
    );
  }
}

// 4. Zugriff von überall im Tree
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Direkter Zugriff - kein Prop Drilling!
    final counter = CounterInherited.of(context);

    return Scaffold(
      body: Center(
        child: Text('Count: ${counter.count}'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: counter.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

### Wie `context.dependOnInheritedWidgetOfExactType` funktioniert

Flutter durchsucht den Widget-Tree nach oben, bis es das passende `InheritedWidget` findet. Zusätzlich registriert sich das Widget als "Dependent" - wenn sich der State ändert, wird nur dieses Widget neu gebaut.

```dart
// Kurzer Zugriff über dependOnInheritedWidgetOfExactType
final counter = context.dependOnInheritedWidgetOfExactType<CounterInherited>()!;

// Dasselbe mit der statischen Hilfsmethode
final counter = CounterInherited.of(context);
```

---

## 5. Warum externe State Management Lösungen?

`InheritedWidget` ist mächtig, aber erfordert viel Boilerplate. Packages wie Provider, Riverpod oder Bloc bauen darauf auf und vereinfachen die Verwendung.

### Vergleich der Ansätze

| Lösung | Komplexität | Lernkurve | Best Use Case |
|--------|-------------|-----------|---------------|
| `setState()` | Niedrig | Flach | Lokaler UI-State |
| Lifting State Up | Niedrig | Flach | Wenige Widgets teilen State |
| `InheritedWidget` | Mittel | Mittel | Verstehen, wie Flutter intern funktioniert |
| **Provider** | Niedrig | Flach | Empfohlen für die meisten Apps |
| **Riverpod** | Mittel | Mittel | Compile-Time Safety, testbar |
| **Bloc** | Hoch | Steil | Große Teams, komplexe Business Logic |
| **GetX** | Niedrig | Flach | Schnelle Prototypen (weniger empfohlen) |

### Provider: Der Quasi-Standard

```dart
// Mit Provider - viel weniger Boilerplate
class Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;

  void increment() {
    _count++;
    notifyListeners();  // Benachrichtigt alle Listener
  }
}

// In der App
ChangeNotifierProvider(
  create: (_) => Counter(),
  child: MyApp(),
);

// Zugriff
final counter = context.watch<Counter>();
Text('Count: ${counter.count}');
```

---

## 6. State Management Entscheidungsbaum

```
Braucht nur ein Widget den State?
├── Ja → setState()
└── Nein → Brauchen mehrere Widgets den State?
    ├── Ja, aber nur 1-2 Ebenen entfernt → Lifting State Up
    └── Ja, weit verteilt → State Management Solution
        ├── Einsteiger / kleine App → Provider
        ├── Testbarkeit wichtig → Riverpod
        └── Große App / Team → Bloc
```

---

## 7. Praktisches Beispiel: Todo-App State

```dart
// Model
class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({
    required this.id,
    required this.title,
    this.completed = false,
  });

  Todo copyWith({String? title, bool? completed}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      completed: completed ?? this.completed,
    );
  }
}

// State Management mit ChangeNotifier (für Provider)
class TodosNotifier extends ChangeNotifier {
  final List<Todo> _todos = [];

  List<Todo> get todos => List.unmodifiable(_todos);

  List<Todo> get completedTodos =>
      _todos.where((t) => t.completed).toList();

  List<Todo> get pendingTodos =>
      _todos.where((t) => !t.completed).toList();

  void add(String title) {
    _todos.add(Todo(
      id: DateTime.now().toString(),
      title: title,
    ));
    notifyListeners();
  }

  void toggle(String id) {
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(
        completed: !_todos[index].completed,
      );
      notifyListeners();
    }
  }

  void remove(String id) {
    _todos.removeWhere((t) => t.id == id);
    notifyListeners();
  }
}
```

---

## Zusammenfassung

| Konzept | Wann verwenden |
|---------|---------------|
| `setState()` | Lokaler State in einem Widget |
| Lifting State Up | State wird von wenigen, nahen Widgets geteilt |
| `InheritedWidget` | Grundverständnis, eigene Lösungen bauen |
| Provider/Riverpod | Empfohlen für App State |

**Wichtig:** Es gibt keine "beste" Lösung - wähle basierend auf:
- Größe und Komplexität der App
- Teamgröße und -erfahrung
- Testbarkeit-Anforderungen

In den nächsten Einheiten lernst du Provider im Detail kennen.
