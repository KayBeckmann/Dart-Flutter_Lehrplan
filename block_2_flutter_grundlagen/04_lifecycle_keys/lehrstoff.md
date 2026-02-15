# Einheit 2.4: Widget-Lifecycle & Keys

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.3

---

## 4.1 State Lifecycle

```dart
class MeinWidget extends StatefulWidget {
  @override
  State<MeinWidget> createState() => _MeinWidgetState();
}

class _MeinWidgetState extends State<MeinWidget> {
  @override
  void initState() {
    super.initState();
    // 1. Einmalig beim Erstellen — Initialisierungen
    print('initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 2. Nach initState und wenn InheritedWidget sich ändert
    print('didChangeDependencies');
  }

  @override
  void didUpdateWidget(MeinWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 3. Wenn Parent das Widget mit neuen Properties rebuildet
    print('didUpdateWidget');
  }

  @override
  Widget build(BuildContext context) {
    // 4. Bei jedem Rebuild
    print('build');
    return Container();
  }

  @override
  void dispose() {
    // 5. Beim Entfernen — Cleanup
    print('dispose');
    super.dispose();
  }
}
```

---

## 4.2 Typische Verwendung

```dart
class DatenLader extends StatefulWidget {
  final int userId;
  const DatenLader({super.key, required this.userId});

  @override
  State<DatenLader> createState() => _DatenLaderState();
}

class _DatenLaderState extends State<DatenLader> {
  String? _daten;
  late final StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _ladeDaten();
    _subscription = eventBus.listen(_onEvent);
  }

  @override
  void didUpdateWidget(DatenLader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _ladeDaten();  // Neu laden wenn userId sich ändert
    }
  }

  @override
  void dispose() {
    _subscription.cancel();  // Wichtig: Subscription beenden!
    super.dispose();
  }

  void _ladeDaten() async {
    var daten = await api.lade(widget.userId);
    setState(() => _daten = daten);
  }

  @override
  Widget build(BuildContext context) {
    return Text(_daten ?? 'Lädt...');
  }
}
```

---

## 4.3 Keys verstehen

Keys helfen Flutter, Widgets zu identifizieren:

```dart
// OHNE Key — Flutter kann Widgets verwechseln
ListView(
  children: [
    TodoItem(text: 'A'),  // Position 0
    TodoItem(text: 'B'),  // Position 1
  ],
)

// MIT Key — Flutter erkennt welches Widget welches ist
ListView(
  children: [
    TodoItem(key: ValueKey('a'), text: 'A'),
    TodoItem(key: ValueKey('b'), text: 'B'),
  ],
)
```

---

## 4.4 Key-Typen

```dart
// ValueKey — basierend auf einem Wert
TodoItem(key: ValueKey(todo.id), ...)

// ObjectKey — basierend auf Objekt-Identität
TodoItem(key: ObjectKey(todo), ...)

// UniqueKey — immer einzigartig (neu bei jedem Build)
TodoItem(key: UniqueKey(), ...)

// GlobalKey — zugriff auf State von außen
final _formKey = GlobalKey<FormState>();
Form(key: _formKey, ...)
_formKey.currentState?.validate();
```

---

## 4.5 Wann Keys verwenden?

**Keys sind wichtig bei:**
- Listen mit StatefulWidgets
- Widgets die umsortiert werden
- Widgets mit Animationen
- Formularen (`GlobalKey<FormState>`)

```dart
// Beispiel: Sortierbare Liste
class TodoList extends StatefulWidget {
  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  var _todos = ['A', 'B', 'C'];

  void _shuffle() {
    setState(() => _todos.shuffle());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _shuffle, child: Text('Mischen')),
        for (var todo in _todos)
          TodoItem(
            key: ValueKey(todo),  // Wichtig für korrektes Verhalten!
            text: todo,
          ),
      ],
    );
  }
}
```

---

## 4.6 GlobalKey Beispiel

```dart
class FormularSeite extends StatefulWidget {
  @override
  State<FormularSeite> createState() => _FormularSeiteState();
}

class _FormularSeiteState extends State<FormularSeite> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();
      print('Formular gültig!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null),
          ElevatedButton(onPressed: _submit, child: Text('Absenden')),
        ],
      ),
    );
  }
}
```
