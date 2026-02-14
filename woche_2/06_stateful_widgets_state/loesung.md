# Modul 6: Loesung -- Stoppuhr-App

## Vollstaendige Loesung (lib/main.dart)

```dart
import 'dart:async';

import 'package:flutter/material.dart';

void main() {
  runApp(const StoppuhrApp());
}

// ============================================================
// 1. Root-Widget
// ============================================================
class StoppuhrApp extends StatelessWidget {
  const StoppuhrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stoppuhr',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const StoppuhrSeite(),
    );
  }
}

// ============================================================
// 2. StoppuhrSeite -- haelt den gesamten State
// ============================================================
class StoppuhrSeite extends StatefulWidget {
  const StoppuhrSeite({super.key});

  @override
  State<StoppuhrSeite> createState() => _StoppuhrSeiteState();
}

class _StoppuhrSeiteState extends State<StoppuhrSeite> {
  // State-Variablen
  Timer? _timer;
  Duration _verstricheneZeit = Duration.zero;
  DateTime? _startZeitpunkt;
  Duration _zuvorVerstricheneZeit = Duration.zero;
  bool _laeuft = false;
  final List<Duration> _rundenZeiten = [];

  // Timer starten
  void _starten() {
    _startZeitpunkt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (mounted) {
        setState(() {
          _verstricheneZeit = _zuvorVerstricheneZeit +
              DateTime.now().difference(_startZeitpunkt!);
        });
      }
    });
    setState(() {
      _laeuft = true;
    });
  }

  // Timer stoppen
  void _stoppen() {
    _timer?.cancel();
    _zuvorVerstricheneZeit = _verstricheneZeit;
    setState(() {
      _laeuft = false;
    });
  }

  // Alles zuruecksetzen
  void _zuruecksetzen() {
    _timer?.cancel();
    setState(() {
      _verstricheneZeit = Duration.zero;
      _zuvorVerstricheneZeit = Duration.zero;
      _startZeitpunkt = null;
      _laeuft = false;
      _rundenZeiten.clear();
    });
  }

  // Rundenzeit speichern
  void _rundeSpeichern() {
    setState(() {
      _rundenZeiten.insert(0, _verstricheneZeit);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Timer immer abbrechen!
    super.dispose();
  }

  // Hilfsfunktion: Hat die Uhr jemals gelaufen?
  bool get _hatZeit => _verstricheneZeit > Duration.zero;

  // Schnellste und langsamste Runde finden
  int? get _schnellsteRundeIndex {
    if (_rundenZeiten.length < 2) return null;
    final einzelZeiten = _berechneEinzelZeiten();
    Duration min = einzelZeiten[0];
    int minIndex = 0;
    for (int i = 1; i < einzelZeiten.length; i++) {
      if (einzelZeiten[i] < min) {
        min = einzelZeiten[i];
        minIndex = i;
      }
    }
    return minIndex;
  }

  int? get _langsamsteRundeIndex {
    if (_rundenZeiten.length < 2) return null;
    final einzelZeiten = _berechneEinzelZeiten();
    Duration max = einzelZeiten[0];
    int maxIndex = 0;
    for (int i = 1; i < einzelZeiten.length; i++) {
      if (einzelZeiten[i] > max) {
        max = einzelZeiten[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  List<Duration> _berechneEinzelZeiten() {
    final einzelZeiten = <Duration>[];
    // _rundenZeiten ist umgekehrt sortiert (neueste zuerst)
    for (int i = 0; i < _rundenZeiten.length; i++) {
      if (i == _rundenZeiten.length - 1) {
        // Letzte Runde (= erste chronologisch)
        einzelZeiten.add(_rundenZeiten[i]);
      } else {
        // Differenz zur naechsten (chronologisch vorherigen) Runde
        einzelZeiten.add(_rundenZeiten[i] - _rundenZeiten[i + 1]);
      }
    }
    return einzelZeiten;
  }

  @override
  Widget build(BuildContext context) {
    final einzelZeiten = _rundenZeiten.isNotEmpty
        ? _berechneEinzelZeiten()
        : <Duration>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stoppuhr'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          const SizedBox(height: 48),

          // Zeitanzeige
          ZeitAnzeige(dauer: _verstricheneZeit),
          const SizedBox(height: 32),

          // Steuerungsbuttons
          SteuerungsButtons(
            laeuft: _laeuft,
            hatZeit: _hatZeit,
            onStarten: _starten,
            onStoppen: _stoppen,
            onZuruecksetzen: _zuruecksetzen,
            onRunde: _rundeSpeichern,
          ),
          const SizedBox(height: 24),

          // Trennlinie
          if (_rundenZeiten.isNotEmpty)
            const Divider(thickness: 1),

          // Rundenliste
          Expanded(
            child: RundenListe(
              gesamtZeiten: _rundenZeiten,
              einzelZeiten: einzelZeiten,
              schnellsteIndex: _schnellsteRundeIndex,
              langsamsteIndex: _langsamsteRundeIndex,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 3. ZeitAnzeige -- zeigt die formatierte Zeit an
// ============================================================
class ZeitAnzeige extends StatelessWidget {
  const ZeitAnzeige({super.key, required this.dauer});

  final Duration dauer;

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatiereDauer(dauer),
      style: const TextStyle(
        fontSize: 72,
        fontWeight: FontWeight.w200,
        fontFeatures: [FontFeature.tabularFigures()],
        letterSpacing: 2,
      ),
    );
  }

  static String _formatiereDauer(Duration dauer) {
    final minuten = dauer.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sekunden =
        dauer.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hundertstel = (dauer.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$minuten:$sekunden.$hundertstel';
  }
}

// ============================================================
// 4. SteuerungsButtons -- Start/Stop/Reset/Runde
// ============================================================
class SteuerungsButtons extends StatelessWidget {
  const SteuerungsButtons({
    super.key,
    required this.laeuft,
    required this.hatZeit,
    required this.onStarten,
    required this.onStoppen,
    required this.onZuruecksetzen,
    required this.onRunde,
  });

  final bool laeuft;
  final bool hatZeit;
  final VoidCallback onStarten;
  final VoidCallback onStoppen;
  final VoidCallback onZuruecksetzen;
  final VoidCallback onRunde;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Linker Button: Reset oder Runde
          _RundeResetButton(
            laeuft: laeuft,
            hatZeit: hatZeit,
            onZuruecksetzen: onZuruecksetzen,
            onRunde: onRunde,
          ),
          // Rechter Button: Start oder Stopp
          _StartStoppButton(
            laeuft: laeuft,
            onStarten: onStarten,
            onStoppen: onStoppen,
          ),
        ],
      ),
    );
  }
}

class _StartStoppButton extends StatelessWidget {
  const _StartStoppButton({
    required this.laeuft,
    required this.onStarten,
    required this.onStoppen,
  });

  final bool laeuft;
  final VoidCallback onStarten;
  final VoidCallback onStoppen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 56,
      child: ElevatedButton(
        onPressed: laeuft ? onStoppen : onStarten,
        style: ElevatedButton.styleFrom(
          backgroundColor: laeuft
              ? Colors.red.shade700
              : Colors.green.shade700,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Text(
          laeuft ? 'Stopp' : 'Start',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _RundeResetButton extends StatelessWidget {
  const _RundeResetButton({
    required this.laeuft,
    required this.hatZeit,
    required this.onZuruecksetzen,
    required this.onRunde,
  });

  final bool laeuft;
  final bool hatZeit;
  final VoidCallback onZuruecksetzen;
  final VoidCallback onRunde;

  @override
  Widget build(BuildContext context) {
    final String label;
    final VoidCallback? aktion;

    if (laeuft) {
      label = 'Runde';
      aktion = onRunde;
    } else if (hatZeit) {
      label = 'Reset';
      aktion = onZuruecksetzen;
    } else {
      label = 'Reset';
      aktion = null; // Deaktiviert
    }

    return SizedBox(
      width: 140,
      height: 56,
      child: OutlinedButton(
        onPressed: aktion,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          side: BorderSide(
            color: aktion != null
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

// ============================================================
// 5. RundenListe -- zeigt alle Rundenzeiten an
// ============================================================
class RundenListe extends StatelessWidget {
  const RundenListe({
    super.key,
    required this.gesamtZeiten,
    required this.einzelZeiten,
    this.schnellsteIndex,
    this.langsamsteIndex,
  });

  final List<Duration> gesamtZeiten;
  final List<Duration> einzelZeiten;
  final int? schnellsteIndex;
  final int? langsamsteIndex;

  @override
  Widget build(BuildContext context) {
    if (gesamtZeiten.isEmpty) {
      return const Center(
        child: Text(
          'Druecke "Runde" um Zwischenzeiten zu speichern',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: gesamtZeiten.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        // Rundennummer (umgekehrt, da neueste oben)
        final rundenNummer = gesamtZeiten.length - index;
        final gesamtZeit = gesamtZeiten[index];
        final einzelZeit = einzelZeiten[index];

        // Farbe bestimmen
        Color? textFarbe;
        if (index == schnellsteIndex) {
          textFarbe = Colors.green;
        } else if (index == langsamsteIndex) {
          textFarbe = Colors.red;
        }

        return RundenEintrag(
          rundenNummer: rundenNummer,
          einzelZeit: einzelZeit,
          gesamtZeit: gesamtZeit,
          textFarbe: textFarbe,
        );
      },
    );
  }
}

// ============================================================
// 6. RundenEintrag -- einzelne Zeile in der Rundenliste
// ============================================================
class RundenEintrag extends StatelessWidget {
  const RundenEintrag({
    super.key,
    required this.rundenNummer,
    required this.einzelZeit,
    required this.gesamtZeit,
    this.textFarbe,
  });

  final int rundenNummer;
  final Duration einzelZeit;
  final Duration gesamtZeit;
  final Color? textFarbe;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 16,
      color: textFarbe,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Rundennummer
          SizedBox(
            width: 80,
            child: Text(
              'Runde $rundenNummer',
              style: style.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Einzelzeit
          Expanded(
            child: Text(
              ZeitAnzeige._formatiereDauer(einzelZeit),
              style: style,
              textAlign: TextAlign.center,
            ),
          ),

          // Gesamtzeit
          SizedBox(
            width: 120,
            child: Text(
              'Gesamt: ${ZeitAnzeige._formatiereDauer(gesamtZeit)}',
              style: style.copyWith(
                fontSize: 14,
                color: textFarbe?.withValues(alpha: 0.7) ??
                    Colors.grey,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Erklaerung der Loesung

### State-Verwaltung

Der gesamte State liegt in `_StoppuhrSeiteState`:

| State-Variable | Typ | Beschreibung |
|----------------|-----|-------------|
| `_timer` | `Timer?` | Der periodische Timer |
| `_verstricheneZeit` | `Duration` | Aktuell angezeigte Zeit |
| `_startZeitpunkt` | `DateTime?` | Zeitpunkt des letzten Starts |
| `_zuvorVerstricheneZeit` | `Duration` | Zeit vor dem letzten Stopp (fuer Weiter) |
| `_laeuft` | `bool` | Ob die Stoppuhr gerade laeuft |
| `_rundenZeiten` | `List<Duration>` | Gespeicherte Gesamtzeiten bei Runde |

### Zeitmessung

Die Zeitmessung basiert auf `DateTime.now().difference()` statt auf Timer-Inkrementen. Das ist praeziser, weil Timer-Callbacks nicht garantiert exakt alle X Millisekunden aufgerufen werden.

```
Verstrichene Zeit = zuvor verstrichene Zeit + (jetzt - Startzeitpunkt)
```

### Widget-Baum

```
StoppuhrApp (MaterialApp)
  └── StoppuhrSeite (StatefulWidget -- haelt allen State)
       ├── ZeitAnzeige (StatelessWidget -- bekommt Duration)
       ├── SteuerungsButtons (StatelessWidget -- bekommt Callbacks)
       │    ├── _RundeResetButton
       │    └── _StartStoppButton
       └── RundenListe (StatelessWidget -- bekommt Listen)
            └── RundenEintrag (StatelessWidget -- einzelne Zeile)
```

### Korrekte dispose()-Implementierung

```dart
@override
void dispose() {
  _timer?.cancel();  // Timer MUSS abgebrochen werden!
  super.dispose();
}
```

Ohne `dispose()` wuerde der Timer weiterlaufen, auch wenn das Widget nicht mehr angezeigt wird. Das fuehrt zu Memory Leaks und Fehlern (setState auf unmounted Widget).

### So fuehrst du die App aus

```bash
flutter create stoppuhr
cd stoppuhr
# Ersetze den Inhalt von lib/main.dart mit dem Code oben
flutter run
```
