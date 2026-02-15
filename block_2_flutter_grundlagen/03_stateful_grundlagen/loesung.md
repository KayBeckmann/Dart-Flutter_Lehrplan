# Lösung 2.3: StatefulWidget Grundlagen

---

## Aufgabe 1

```dart
class Zähler extends StatefulWidget {
  const Zähler({super.key});

  @override
  State<Zähler> createState() => _ZählerState();
}

class _ZählerState extends State<Zähler> {
  int _wert = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$_wert', style: TextStyle(fontSize: 48)),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: _wert > 0 ? () => setState(() => _wert--) : null,
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => setState(() => _wert++),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => setState(() => _wert = 0),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Aufgabe 2

```dart
class Farbwechsler extends StatefulWidget {
  const Farbwechsler({super.key});

  @override
  State<Farbwechsler> createState() => _FarbwechslerState();
}

class _FarbwechslerState extends State<Farbwechsler> {
  final _farben = [
    (Colors.red, 'Rot'),
    (Colors.green, 'Grün'),
    (Colors.blue, 'Blau'),
    (Colors.orange, 'Orange'),
  ];
  int _index = 0;

  void _wechsle() {
    setState(() {
      _index = (_index + 1) % _farben.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _wechsle,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 200,
        height: 200,
        color: _farben[_index].$1,
        child: Center(
          child: Text(_farben[_index].$2,
            style: TextStyle(color: Colors.white, fontSize: 24)),
        ),
      ),
    );
  }
}
```

---

## Aufgabe 3

```dart
class TodoItem extends StatefulWidget {
  final String text;
  final ValueChanged<bool>? onChanged;

  const TodoItem({super.key, required this.text, this.onChanged});

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _erledigt = false;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: _erledigt,
        onChanged: (value) {
          setState(() => _erledigt = value ?? false);
          widget.onChanged?.call(_erledigt);
        },
      ),
      title: Text(
        widget.text,
        style: TextStyle(
          decoration: _erledigt ? TextDecoration.lineThrough : null,
          color: _erledigt ? Colors.grey : null,
        ),
      ),
    );
  }
}
```
