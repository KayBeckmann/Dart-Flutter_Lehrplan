# Einheit 2.3: StatefulWidget Grundlagen

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.2

---

## 3.1 StatefulWidget vs. StatelessWidget

| StatelessWidget | StatefulWidget |
|-----------------|----------------|
| Unveränderlich | Hat veränderlichen State |
| `build()` nur bei Parent-Änderung | `build()` auch bei State-Änderung |
| Für statische UI | Für interaktive UI |

---

## 3.2 Struktur eines StatefulWidget

```dart
class Zähler extends StatefulWidget {
  const Zähler({super.key});

  @override
  State<Zähler> createState() => _ZählerState();
}

class _ZählerState extends State<Zähler> {
  int _anzahl = 0;

  void _erhöhen() {
    setState(() {
      _anzahl++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Zähler: $_anzahl'),
        ElevatedButton(
          onPressed: _erhöhen,
          child: Text('Erhöhen'),
        ),
      ],
    );
  }
}
```

---

## 3.3 setState() verstehen

**Wichtig:** `setState()` signalisiert Flutter, dass sich der State geändert hat und `build()` neu aufgerufen werden soll.

```dart
// RICHTIG:
void _erhöhen() {
  setState(() {
    _anzahl++;
  });
}

// AUCH RICHTIG:
void _erhöhen() {
  _anzahl++;
  setState(() {});
}

// FALSCH — UI wird nicht aktualisiert:
void _erhöhen() {
  _anzahl++;  // Kein setState!
}
```

---

## 3.4 Wann StatefulWidget verwenden?

**StatefulWidget wenn:**
- Benutzerinteraktion den UI ändert
- Animationen
- Timer / Streams
- Formularfelder

**StatelessWidget wenn:**
- UI hängt nur von Parametern ab
- Keine Benutzerinteraktion

---

## 3.5 Beispiel: Toggle-Button

```dart
class ToggleButton extends StatefulWidget {
  final String label;
  final ValueChanged<bool>? onChanged;

  const ToggleButton({super.key, required this.label, this.onChanged});

  @override
  State<ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  bool _aktiv = false;

  void _toggle() {
    setState(() {
      _aktiv = !_aktiv;
    });
    widget.onChanged?.call(_aktiv);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _aktiv ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _aktiv ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
```

---

## 3.6 Zugriff auf Widget-Properties

In der State-Klasse über `widget.propertyName`:

```dart
class Begrüßung extends StatefulWidget {
  final String name;  // Widget-Property
  const Begrüßung({super.key, required this.name});

  @override
  State<Begrüßung> createState() => _BegrüßungState();
}

class _BegrüßungState extends State<Begrüßung> {
  int _klicks = 0;  // State-Variable

  @override
  Widget build(BuildContext context) {
    return Text('Hallo ${widget.name}! Klicks: $_klicks');
    //                  ^^^^^^^^^^^ Widget-Property
  }
}
```

---

## 3.7 Beispiel: Counter-App

```dart
class CounterApp extends StatefulWidget {
  const CounterApp({super.key});

  @override
  State<CounterApp> createState() => _CounterAppState();
}

class _CounterAppState extends State<CounterApp> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: Center(
        child: Text(
          '$_counter',
          style: Theme.of(context).textTheme.displayLarge,
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: () => setState(() => _counter++),
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => setState(() => _counter--),
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```
