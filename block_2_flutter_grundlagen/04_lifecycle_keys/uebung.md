# Übung 2.4: Widget-Lifecycle & Keys

---

## Aufgabe 1: Lifecycle-Logger (15 Min.)

Erstelle ein Widget das alle Lifecycle-Events loggt:

```dart
class LifecycleLogger extends StatefulWidget {
  final String name;
  const LifecycleLogger({super.key, required this.name});
  // TODO: Implementiere alle Lifecycle-Methoden mit print()
}

// Test: Füge mehrere LifecycleLogger in ein Widget ein
// und beobachte die Reihenfolge der Logs
```

---

## Aufgabe 2: Timer mit Cleanup (20 Min.)

```dart
class CountdownTimer extends StatefulWidget {
  final int sekunden;
  final VoidCallback? onFinished;

  const CountdownTimer({super.key, required this.sekunden, this.onFinished});
  // TODO:
  // - Starte Timer in initState
  // - Cancele Timer in dispose
  // - Zeige verbleibende Zeit an
}
```

---

## Aufgabe 3: Keys verstehen (20 Min.)

Erstelle zwei Listen — eine mit Keys, eine ohne:

```dart
// Jedes Item hat einen internen Counter
// Bei Shuffle: Beobachte den Unterschied!

class CounterItem extends StatefulWidget {
  final String label;
  const CounterItem({super.key, required this.label});
  // Interner State: _count
}
```

---

## Bonusaufgabe: GlobalKey

```dart
// Erstelle ein Widget das von außen zurückgesetzt werden kann
// Hint: GlobalKey<_MeinWidgetState>
```
