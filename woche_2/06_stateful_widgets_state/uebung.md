# Modul 6: Uebung -- Stoppuhr-App

## Aufgabenstellung

Erstelle eine voll funktionsfaehige **Stoppuhr-App** mit Rundenzeiten-Funktion. Diese Uebung trainiert den Umgang mit StatefulWidgets, Lifecycle-Methoden, Timer und State Lifting.

---

## Anforderungen

### 1. Zeitanzeige

- Zeige die laufende Zeit im Format `MM:SS.hh` an (Minuten:Sekunden.Hundertstel)
- Die Anzeige soll gross und gut lesbar sein (z.B. `TextStyle` mit `fontSize: 64`)
- Verwende eine Monospace-Schriftart oder `tabularFigures`, damit die Ziffern nicht springen
- Die Zeit soll sich alle 10 Millisekunden aktualisieren (oder alle 30ms fuer weniger CPU-Last)

### 2. Steuerungsbuttons

Implementiere drei Buttons mit folgender Logik:

| Zustand | Button 1 | Button 2 |
|---------|----------|----------|
| Gestoppt (Anfang) | Start (gruen) | Reset (deaktiviert) |
| Laeuft | Stopp (rot) | Runde |
| Gestoppt (mit Zeit) | Weiter (gruen) | Reset |

- **Start/Weiter:** Startet die Stoppuhr oder setzt sie fort
- **Stopp:** Haelt die Stoppuhr an (Zeit bleibt stehen)
- **Runde:** Speichert die aktuelle Zeit als Rundenzeit
- **Reset:** Setzt alles auf 0 zurueck und loescht alle Rundenzeiten

### 3. Rundenzeiten

- Beim Druecken von "Runde" wird die aktuelle Gesamtzeit gespeichert
- Zeige alle Rundenzeiten in einer **ListView** unterhalb der Stoppuhr an
- Jede Rundenzeit zeigt: Rundennummer und Gesamtzeit
- Berechne und zeige auch die **Einzelrundenzeit** (Differenz zur vorherigen Runde)
- Markiere die schnellste Runde gruen und die langsamste rot (Bonus)

### 4. Timer und dispose()

- Verwende `Timer.periodic` aus `dart:async` fuer die Zeitaktualisierung
- Implementiere `dispose()` korrekt: Timer muss abgebrochen werden, wenn das Widget aus dem Baum entfernt wird
- Verwende `mounted`-Pruefung wo noetig

### 5. Widget-Extraktion und State Lifting

Extrahiere mindestens diese eigenen Widgets:

1. **StoppuhrApp** -- Root-Widget mit MaterialApp
2. **StoppuhrSeite** -- Hauptseite (haelt den gesamten State)
3. **ZeitAnzeige** -- Zeigt die formatierte Zeit an (StatelessWidget, bekommt Duration als Parameter)
4. **SteuerungsButtons** -- Die Start/Stop/Reset/Runde-Buttons (StatelessWidget, bekommt Callbacks)
5. **RundenListe** -- ListView mit den Rundenzeiten (StatelessWidget, bekommt Liste als Parameter)

Der State (laufende Zeit, Rundenzeiten, ob die Uhr laeuft) soll in `StoppuhrSeite` liegen und ueber Parameter/Callbacks an die Kind-Widgets weitergegeben werden.

---

## Technische Hinweise

### Timer verwenden

```dart
import 'dart:async';

Timer? _timer;

void _starten() {
  _timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
    setState(() {
      // Zeit aktualisieren
    });
  });
}

void _stoppen() {
  _timer?.cancel();
}

@override
void dispose() {
  _timer?.cancel();
  super.dispose();
}
```

### Zeit formatieren

```dart
String _formatiereDauer(Duration dauer) {
  final minuten = dauer.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sekunden = dauer.inSeconds.remainder(60).toString().padLeft(2, '0');
  final hundertstel = (dauer.inMilliseconds.remainder(1000) ~/ 10)
      .toString()
      .padLeft(2, '0');
  return '$minuten:$sekunden.$hundertstel';
}
```

### Duration verwenden

```dart
// Verstrichene Zeit berechnen
final _startZeit = DateTime.now();
final verstricheneZeit = DateTime.now().difference(_startZeit);

// Oder mit Stopwatch
final _stopwatch = Stopwatch();
_stopwatch.start();
_stopwatch.stop();
_stopwatch.elapsed; // Duration
_stopwatch.reset();
```

---

## Bonus-Aufgaben (optional)

1. **Beste/Schlechteste Runde markieren:** Die schnellste Einzelrunde gruen, die langsamste rot markieren
2. **Haptic Feedback:** Beim Druecken der Buttons eine kurze Vibration ausloesen (`HapticFeedback.mediumImpact()`)
3. **Design:** Gestalte die App im Stil einer echten Stoppuhr (dunkler Hintergrund, Neon-Zahlen)
4. **Landscape-Modus:** Passe das Layout fuer den Querformat-Modus an (Buttons neben der Zeitanzeige statt darunter)

---

## Erwartetes Ergebnis

```
┌──────────────────────────────┐
│          Stoppuhr            │
├──────────────────────────────┤
│                              │
│        01:23.45              │
│                              │
│    [ Stopp ]    [ Runde ]    │
│                              │
├──────────────────────────────┤
│ Runde 3     00:28.12  Total: 01:23.45 │
│ Runde 2     00:31.55  Total: 00:55.33 │
│ Runde 1     00:23.78  Total: 00:23.78 │
└──────────────────────────────┘
```
