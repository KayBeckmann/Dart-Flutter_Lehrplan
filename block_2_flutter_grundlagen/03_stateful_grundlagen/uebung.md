# Übung 2.3: StatefulWidget Grundlagen

---

## Aufgabe 1: Einfacher Zähler (15 Min.)

Erstelle einen Zähler mit Plus/Minus-Buttons:

```dart
// Anforderungen:
// - Zähler startet bei 0
// - Plus-Button erhöht um 1
// - Minus-Button verringert um 1
// - Reset-Button setzt auf 0
// - Zähler kann nicht unter 0 fallen
```

---

## Aufgabe 2: Farbwechsler (20 Min.)

Erstelle ein Widget, das bei Tap die Farbe wechselt:

```dart
// Anforderungen:
// - Container mit Farbe
// - Bei Tap: Wechsle zur nächsten Farbe aus einer Liste
// - Zeige den Farbnamen an
// - Bonus: Animation beim Wechsel
```

---

## Aufgabe 3: Todo-Item (20 Min.)

Erstelle ein einzelnes Todo-Item Widget:

```dart
class TodoItem extends StatefulWidget {
  final String text;
  final ValueChanged<bool>? onChanged;

  const TodoItem({super.key, required this.text, this.onChanged});
  // ...
}

// Anforderungen:
// - Checkbox zum Abhaken
// - Text durchgestrichen wenn erledigt
// - Callback bei Änderung
```

---

## Bonusaufgabe: Stoppuhr

```dart
// Anforderungen:
// - Start/Stop Button
// - Anzeige: MM:SS.ms
// - Reset Button
// - Hint: Timer.periodic()
```
