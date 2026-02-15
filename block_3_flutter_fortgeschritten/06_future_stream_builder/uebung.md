# Übung 3.6: FutureBuilder & StreamBuilder

## Ziel

Loading States und asynchrone Daten elegant in der UI darstellen.

---

## Aufgabe 1: FutureBuilder Basics (20 min)

Erstelle eine `QuotePage`, die ein Zitat von einer API lädt:

API: `https://api.quotable.io/random`

Anforderungen:
1. Loading State: Zeige `CircularProgressIndicator`
2. Error State: Zeige Fehlermeldung mit Retry-Button
3. Success State: Zeige das Zitat mit Autor
4. Refresh-Button in der AppBar

```
┌─────────────────────────────────┐
│ Quote of the Day       [🔄]   │
├─────────────────────────────────┤
│                                 │
│    "The only way to do great   │
│     work is to love what       │
│     you do."                   │
│                                 │
│           - Steve Jobs         │
│                                 │
└─────────────────────────────────┘
```

**Wichtig:** Achte darauf, das Future NICHT in `build()` zu erstellen!

---

## Aufgabe 2: Skeleton Screen (25 min)

Erstelle Skeleton-Komponenten für eine User-Liste:

1. `SkeletonBox` - Einfacher grauer Platzhalter
2. `SkeletonCircle` - Runder Platzhalter (Avatar)
3. `SkeletonUserTile` - Komplettes Skeleton für einen User

```
┌─────────────────────────────────┐
│ ⚪ ████████████████            │
│    ██████████                  │
├─────────────────────────────────┤
│ ⚪ ████████████████            │
│    ██████████                  │
├─────────────────────────────────┤
│ ⚪ ████████████████            │
│    ██████████                  │
└─────────────────────────────────┘
```

Integriere in `FutureBuilder`:
- Zeige 5 Skeleton-Tiles während Loading
- Zeige echte Daten nach dem Laden

---

## Aufgabe 3: StreamBuilder - Live Clock (15 min)

Erstelle eine digitale Uhr, die jede Sekunde aktualisiert:

```dart
Stream<DateTime> _createTimeStream() {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
}
```

Anforderungen:
1. Format: HH:MM:SS
2. Zeige auch das Datum
3. Responsive Schriftgröße

---

## Aufgabe 4: StreamBuilder - Counter mit Buttons (20 min)

Erstelle einen Counter, der über einen `StreamController` gesteuert wird:

```dart
class CounterController {
  final _controller = StreamController<int>.broadcast();
  int _count = 0;

  Stream<int> get stream => _controller.stream;

  void increment() {
    _count++;
    _controller.add(_count);
  }

  void decrement() {
    _count--;
    _controller.add(_count);
  }

  void reset() {
    _count = 0;
    _controller.add(_count);
  }

  void dispose() {
    _controller.close();
  }
}
```

UI:
- Zeige aktuellen Wert
- Buttons: +, -, Reset
- `initialData: 0` für sofortige Anzeige

---

## Aufgabe 5: Kombinierte Futures (25 min)

Erstelle ein Dashboard, das mehrere API-Calls parallel ausführt:

```dart
// Simulierte API-Calls
Future<int> fetchUserCount() async {
  await Future.delayed(Duration(seconds: 1));
  return 1234;
}

Future<int> fetchOrderCount() async {
  await Future.delayed(Duration(seconds: 2));
  return 567;
}

Future<double> fetchRevenue() async {
  await Future.delayed(Duration(seconds: 1, milliseconds: 500));
  return 12345.67;
}
```

Anforderungen:
1. Alle drei Calls parallel starten
2. Dashboard erst anzeigen wenn ALLE fertig sind
3. Einzelne Skeleton-Karten während Loading
4. Refresh lädt alle neu

```
┌─────────────────────────────────┐
│ Dashboard               [🔄]   │
├─────────────────────────────────┤
│ ┌─────────┐ ┌─────────┐        │
│ │  Users  │ │ Orders  │        │
│ │  1,234  │ │   567   │        │
│ └─────────┘ └─────────┘        │
│ ┌───────────────────────┐      │
│ │      Revenue          │      │
│ │    €12,345.67         │      │
│ └───────────────────────┘      │
└─────────────────────────────────┘
```

---

## Aufgabe 6: Pull-to-Refresh mit FutureBuilder (15 min)

Erweitere die QuotePage aus Aufgabe 1:

1. Implementiere Pull-to-Refresh mit `RefreshIndicator`
2. Zeige eine Snackbar bei erfolgreichem Refresh
3. Behalte das alte Zitat während des Ladens sichtbar

---

## Aufgabe 7: Verständnisfragen

1. Warum sollte man das Future nicht direkt in `build()` erstellen?

2. Was ist der Unterschied zwischen `snapshot.hasData` und `snapshot.data != null`?

3. Wann verwendet man `StreamBuilder.initialData`?

4. Wie verhindert man Memory Leaks bei StreamControllern?

5. Was passiert, wenn der Stream einen Fehler emittiert?

---

## Bonus: Shimmer Animation

Installiere das `shimmer` Package und erstelle animierte Skeleton Screens:

```dart
Shimmer.fromColors(
  baseColor: Colors.grey[300]!,
  highlightColor: Colors.grey[100]!,
  child: YourSkeletonWidget(),
);
```

Erstelle ein komplettes Skeleton für eine Produktkarte mit:
- Bild-Platzhalter
- Titel
- Preis
- Rating-Sterne

---

## Abgabe-Checkliste

- [ ] QuotePage mit allen 3 States
- [ ] Skeleton-Komponenten erstellt
- [ ] Skeleton in FutureBuilder integriert
- [ ] Live Clock funktioniert
- [ ] Counter mit StreamController
- [ ] Dashboard mit kombinierten Futures
- [ ] Pull-to-Refresh implementiert
- [ ] Verständnisfragen beantwortet
- [ ] (Bonus) Shimmer Animation
