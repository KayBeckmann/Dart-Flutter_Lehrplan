# Modul 3: Lösung — Asynchroner Datei-Prozessor (Simulation)

```dart
import 'dart:async';

// ============================================================
// 1. DATENMODELLE
// ============================================================

/// Repräsentiert eine Datei mit Name, Größe und Typ.
class DateiInfo {
  final String name;
  final int größeKb;
  final String typ;

  const DateiInfo({
    required this.name,
    required this.größeKb,
    required this.typ,
  });

  @override
  String toString() => '$name ($größeKb KB, .$typ)';
}

/// Ergebnis einer einzelnen Dateiverarbeitung.
class VerarbeitungsErgebnis {
  final DateiInfo datei;
  final Duration dauer;
  final bool erfolgreich;
  final String nachricht;

  const VerarbeitungsErgebnis({
    required this.datei,
    required this.dauer,
    required this.erfolgreich,
    required this.nachricht,
  });

  @override
  String toString() {
    var status = erfolgreich ? 'OK' : 'FEHLER';
    var zeit = (dauer.inMilliseconds / 1000).toStringAsFixed(1);
    return '[$status] ${datei.name} — ${zeit}s: $nachricht';
  }
}

/// Fortschrittsinformation für den Stream.
class FortschrittsInfo {
  final int aktuellerIndex;
  final int gesamt;
  final String dateiName;
  final String status; // 'gestartet', 'abgeschlossen', 'fehler'

  const FortschrittsInfo({
    required this.aktuellerIndex,
    required this.gesamt,
    required this.dateiName,
    required this.status,
  });

  /// Berechnet den Fortschritt als Prozentwert (0.0 bis 1.0).
  double get prozent => gesamt > 0 ? aktuellerIndex / gesamt : 0.0;

  /// Formatierter Fortschrittsbalken.
  String get balken {
    var p = (prozent * 100).round();
    return '[${p.toString().padLeft(3)}%]';
  }

  @override
  String toString() => '$balken $status: $dateiName';
}

// ============================================================
// 2. SIMULIERTE I/O-FUNKTIONEN
// ============================================================

/// Simuliert das Laden einer Datei.
///
/// Die Wartezeit ist proportional zur Dateigröße.
/// Future.delayed simuliert die asynchrone I/O-Operation.
/// Wirft eine Exception wenn der Dateiname mit 'fehler' beginnt.
Future<String> ladeDatei(DateiInfo datei) async {
  // Wartezeit proportional zur Größe, max 2000ms
  final wartezeit = (datei.größeKb * 2).clamp(100, 2000);
  await Future.delayed(Duration(milliseconds: wartezeit));

  // Fehlersimulation — Dateien die mit 'fehler' beginnen schlagen fehl
  if (datei.name.toLowerCase().startsWith('fehler')) {
    throw Exception('Datei "${datei.name}" konnte nicht geladen werden');
  }

  return 'Inhalt von ${datei.name} (${datei.größeKb} KB)';
}

/// Simuliert die Verarbeitung des Dateiinhalts.
///
/// Verschiedene Verarbeitungslogik je nach Dateityp.
Future<String> verarbeiteDatei(String inhalt, String typ) async {
  await Future.delayed(Duration(milliseconds: 500));

  // Switch-Expression (Dart 3) für verschiedene Verarbeitungsarten
  return switch (typ) {
    'txt' => inhalt.toUpperCase(),
    'csv' => 'CSV verarbeitet: ${inhalt.split(' ').length} Felder gefunden',
    'json' => 'JSON geparst: ${inhalt.length} Zeichen verarbeitet',
    'xml' => 'XML transformiert: $inhalt',
    _ => 'Generisch verarbeitet: $inhalt',
  };
}

// ============================================================
// 3. EINZELDATEI-VERARBEITUNG MIT FEHLERBEHANDLUNG
// ============================================================

/// Verarbeitet eine einzelne Datei und gibt ein Ergebnis zurück.
///
/// Verwendet try/catch, um Fehler abzufangen und als Ergebnis zurückzugeben.
/// Die Funktion crasht NICHT — sie gibt immer ein VerarbeitungsErgebnis zurück.
/// Stopwatch misst die tatsächlich verstrichene Zeit.
Future<VerarbeitungsErgebnis> verarbeiteEineDatei(DateiInfo datei) async {
  // Stopwatch starten — misst die Wanduhrzeit (wall clock time)
  final stopwatch = Stopwatch()..start();

  try {
    // Schritt 1: Datei laden (asynchron)
    final inhalt = await ladeDatei(datei);

    // Schritt 2: Inhalt verarbeiten (asynchron)
    final ergebnis = await verarbeiteDatei(inhalt, datei.typ);

    stopwatch.stop();

    return VerarbeitungsErgebnis(
      datei: datei,
      dauer: stopwatch.elapsed,
      erfolgreich: true,
      nachricht: ergebnis,
    );
  } catch (e) {
    // Fehler fangen — nicht weiterwerfen!
    stopwatch.stop();

    return VerarbeitungsErgebnis(
      datei: datei,
      dauer: stopwatch.elapsed,
      erfolgreich: false,
      nachricht: '$e',
    );
  }
}

// ============================================================
// 4. PARALLELE VERARBEITUNG MIT Future.wait
// ============================================================

/// Verarbeitet alle Dateien gleichzeitig (parallel).
///
/// Future.wait wartet, bis ALLE Futures abgeschlossen sind.
/// Da verarbeiteEineDatei() intern Fehler fängt, schlägt Future.wait
/// hier nie fehl — jedes Ergebnis enthält den Erfolgsstatus.
Future<List<VerarbeitungsErgebnis>> verarbeiteParallel(
  List<DateiInfo> dateien,
) async {
  // map() erstellt für jede Datei ein Future
  // Future.wait startet sie alle gleichzeitig und wartet auf alle
  return Future.wait(
    dateien.map((datei) => verarbeiteEineDatei(datei)),
  );
}

// ============================================================
// 5. FORTSCHRITTS-STREAM MIT async* GENERATOR
// ============================================================

/// Verarbeitet Dateien sequentiell und gibt Fortschrittsupdates als Stream aus.
///
/// async* markiert eine Generatorfunktion, die einen Stream<T> erzeugt.
/// yield gibt einen einzelnen Wert in den Stream.
/// Die Funktion pausiert nach jedem yield und fährt fort,
/// wenn der nächste Wert angefordert wird.
Stream<FortschrittsInfo> verarbeiteMitFortschritt(
  List<DateiInfo> dateien,
) async* {
  for (var i = 0; i < dateien.length; i++) {
    final datei = dateien[i];

    // yield: "Gestartet"-Event in den Stream geben
    yield FortschrittsInfo(
      aktuellerIndex: i,
      gesamt: dateien.length,
      dateiName: datei.name,
      status: 'gestartet',
    );

    // Datei verarbeiten (await in async* ist erlaubt)
    final ergebnis = await verarbeiteEineDatei(datei);

    // yield: "Abgeschlossen"- oder "Fehler"-Event
    yield FortschrittsInfo(
      aktuellerIndex: i + 1,
      gesamt: dateien.length,
      dateiName: datei.name,
      status: ergebnis.erfolgreich
          ? 'abgeschlossen (${(ergebnis.dauer.inMilliseconds / 1000).toStringAsFixed(1)}s)'
          : 'fehler: ${ergebnis.nachricht}',
    );
  }
}

// ============================================================
// 6. STREAMCONTROLLER FÜR LIVE-STATISTIKEN
// ============================================================

/// Monitor-Klasse, die einen Fortschritts-Stream überwacht
/// und formatierte Log-Nachrichten über einen eigenen Broadcast-Stream ausgibt.
class VerarbeitungsMonitor {
  /// Broadcast-Controller — erlaubt mehrere Listener.
  final _logController = StreamController<String>.broadcast();

  /// Subscription für den Fortschritts-Stream.
  StreamSubscription<FortschrittsInfo>? _subscription;

  int _erfolgreich = 0;
  int _fehlgeschlagen = 0;

  /// Öffentlicher Getter für den Log-Stream.
  /// Nur der Stream wird exponiert, nicht der Controller.
  Stream<String> get logStream => _logController.stream;

  /// Überwacht einen Fortschritts-Stream und erzeugt Log-Nachrichten.
  ///
  /// Verwendet listen() statt await for, um den Stream im Hintergrund
  /// zu überwachen und einen Completer für die Abschlussmeldung zu nutzen.
  Future<void> überwache(Stream<FortschrittsInfo> fortschritt) {
    // Completer wird manuell vervollständigt, wenn der Stream endet
    final completer = Completer<void>();

    _erfolgreich = 0;
    _fehlgeschlagen = 0;

    _subscription = fortschritt.listen(
      (info) {
        // Formatierte Log-Nachricht in den eigenen Stream einspeisen
        if (info.status == 'gestartet') {
          _logController.add('${info.balken} Starte: ${info.dateiName}...');
        } else if (info.status.startsWith('fehler')) {
          _fehlgeschlagen++;
          _logController.add('${info.balken} FEHLER: ${info.dateiName}');
        } else {
          _erfolgreich++;
          _logController.add('${info.balken} Fertig:  ${info.dateiName} — ${info.status}');
        }
      },
      onDone: () {
        // Zusammenfassung senden
        _logController.add('');
        _logController.add('--- Monitor-Zusammenfassung ---');
        _logController.add('Erfolgreich:    $_erfolgreich');
        _logController.add('Fehlgeschlagen: $_fehlgeschlagen');
        _logController.add('Gesamt:         ${_erfolgreich + _fehlgeschlagen}');

        // Completer vervollständigen — die Überwachung ist beendet
        completer.complete();
      },
      onError: (e) {
        _logController.add('Monitor-Fehler: $e');
      },
    );

    return completer.future;
  }

  /// Ressourcen freigeben.
  /// Wichtig: Offene StreamController und Subscriptions müssen geschlossen werden!
  void dispose() {
    _subscription?.cancel();
    _logController.close();
  }
}

// ============================================================
// BONUSAUFGABE 1: Timeout
// ============================================================

/// Führt eine asynchrone Operation mit Timeout aus.
///
/// .timeout() ist eine eingebaute Methode auf Futures, die eine
/// TimeoutException wirft, wenn das Future nicht rechtzeitig abschließt.
Future<T> mitTimeout<T>(
  Future<T> Function() operation, {
  Duration timeout = const Duration(seconds: 3),
}) async {
  return operation().timeout(
    timeout,
    onTimeout: () => throw TimeoutException(
      'Operation hat das Zeitlimit von ${timeout.inSeconds}s überschritten',
      timeout,
    ),
  );
}

// ============================================================
// BONUSAUFGABE 2: Retry-Logik
// ============================================================

/// Führt eine Operation mit automatischer Wiederholung bei Fehler aus.
///
/// Generische Funktion — funktioniert mit jedem Rückgabetyp T.
/// Wartet zwischen Versuchen progressiv länger (exponential backoff).
Future<T> mitWiederholung<T>(
  Future<T> Function() operation, {
  int maxVersuche = 3,
}) async {
  for (var versuch = 1; versuch <= maxVersuche; versuch++) {
    try {
      return await operation();
    } catch (e) {
      if (versuch == maxVersuche) {
        // Letzter Versuch fehlgeschlagen — Fehler weiterwerfen
        print('  Alle $maxVersuche Versuche fehlgeschlagen.');
        rethrow;
      }
      // Warte progressiv länger vor dem nächsten Versuch
      var wartezeit = Duration(milliseconds: versuch * 500);
      print('  Versuch $versuch/$maxVersuche fehlgeschlagen. '
          'Nächster Versuch in ${wartezeit.inMilliseconds}ms...');
      await Future.delayed(wartezeit);
    }
  }

  // Wird nie erreicht, aber der Compiler braucht einen Rückgabewert
  throw StateError('Unreachable');
}

// ============================================================
// 7. MAIN — Alles zusammenführen
// ============================================================

void main() async {
  print('=== Asynchroner Datei-Prozessor ===\n');

  // Testdateien erstellen
  const dateien = [
    DateiInfo(name: 'bericht.txt', größeKb: 200, typ: 'txt'),
    DateiInfo(name: 'daten.csv', größeKb: 500, typ: 'csv'),
    DateiInfo(name: 'fehler_datei.json', größeKb: 100, typ: 'json'),
    DateiInfo(name: 'config.json', größeKb: 50, typ: 'json'),
    DateiInfo(name: 'protokoll.txt', größeKb: 300, typ: 'txt'),
    DateiInfo(name: 'export.xml', größeKb: 150, typ: 'xml'),
  ];

  print('Dateien: ${dateien.length}');
  for (var d in dateien) {
    print('  - $d');
  }
  print('');

  // =========================================
  // Teil 1: Sequentielle Verarbeitung mit Fortschritt
  // =========================================

  print('--- Sequentielle Verarbeitung mit Fortschritt ---');

  final seqStopwatch = Stopwatch()..start();

  // await for iteriert über jeden Wert im Stream
  // Der Stream wird von der async*-Generatorfunktion erzeugt
  await for (var info in verarbeiteMitFortschritt(dateien)) {
    if (info.status == 'gestartet') {
      print('${info.balken} Starte: ${info.dateiName}...');
    } else if (info.status.startsWith('fehler')) {
      print('${info.balken} FEHLER: ${info.dateiName} — ${info.status}');
    } else {
      print('${info.balken} Fertig:  ${info.dateiName} — ${info.status}');
    }
  }

  seqStopwatch.stop();
  final seqZeit = seqStopwatch.elapsed;
  print('\nSequentielle Gesamtzeit: '
      '${(seqZeit.inMilliseconds / 1000).toStringAsFixed(1)}s');

  print('');

  // =========================================
  // Teil 2: Parallele Verarbeitung
  // =========================================

  print('--- Parallele Verarbeitung ---');
  print('Alle ${dateien.length} Dateien gleichzeitig gestartet...');

  final parStopwatch = Stopwatch()..start();

  // Future.wait startet alle Futures parallel und wartet auf alle
  final ergebnisse = await verarbeiteParallel(dateien);

  parStopwatch.stop();
  final parZeit = parStopwatch.elapsed;

  for (var erg in ergebnisse) {
    print('  $erg');
  }

  final zeitErsparnis = seqZeit - parZeit;
  print('\nParallele Gesamtzeit: '
      '${(parZeit.inMilliseconds / 1000).toStringAsFixed(1)}s '
      '(${(zeitErsparnis.inMilliseconds / 1000).toStringAsFixed(1)}s schneller!)');

  print('');

  // =========================================
  // Teil 3: Monitor mit StreamController
  // =========================================

  print('--- Monitor-Überwachung ---');

  final monitor = VerarbeitungsMonitor();

  // Log-Stream abonnieren, um die Nachrichten auszugeben
  final logSubscription = monitor.logStream.listen(
    (nachricht) => print('  [Monitor] $nachricht'),
  );

  // Monitor starten — überwacht den Fortschritts-Stream
  final fortschrittsStream = verarbeiteMitFortschritt(dateien);
  await monitor.überwache(fortschrittsStream);

  // Aufräumen — StreamSubscription und Controller schließen
  await logSubscription.cancel();
  monitor.dispose();

  print('');

  // =========================================
  // Teil 4: Zusammenfassung
  // =========================================

  print('--- Gesamtzusammenfassung ---');

  final erfolge = ergebnisse.where((e) => e.erfolgreich).toList();
  final fehler = ergebnisse.where((e) => !e.erfolgreich).toList();

  print('Erfolgreich: ${erfolge.length}/${ergebnisse.length}');
  print('Fehlgeschlagen: ${fehler.length}/${ergebnisse.length}');

  if (erfolge.isNotEmpty) {
    // Sortiere nach Dauer, um schnellste und langsamste zu finden
    erfolge.sort((a, b) => a.dauer.compareTo(b.dauer));
    final schnellste = erfolge.first;
    final langsamste = erfolge.last;

    print('Schnellste: ${schnellste.datei.name} '
        '(${(schnellste.dauer.inMilliseconds / 1000).toStringAsFixed(1)}s)');
    print('Langsamste: ${langsamste.datei.name} '
        '(${(langsamste.dauer.inMilliseconds / 1000).toStringAsFixed(1)}s)');
  }

  if (fehler.isNotEmpty) {
    print('\nFehlgeschlagene Dateien:');
    for (var f in fehler) {
      print('  - ${f.datei.name}: ${f.nachricht}');
    }
  }

  print('');

  // =========================================
  // Bonus 1: Timeout-Demonstration
  // =========================================

  print('--- Bonus: Timeout ---');

  try {
    // Versuche eine große Datei mit kurzem Timeout zu laden
    final großeDatei = DateiInfo(name: 'riesig.bin', größeKb: 5000, typ: 'bin');
    await mitTimeout(
      () => ladeDatei(großeDatei),
      timeout: Duration(seconds: 1),
    );
    print('Große Datei geladen');
  } on TimeoutException catch (e) {
    print('Erwarteter Timeout: $e');
  }

  print('');

  // =========================================
  // Bonus 2: Retry-Demonstration
  // =========================================

  print('--- Bonus: Retry-Logik ---');

  var versuchsZähler = 0;

  try {
    var ergebnis = await mitWiederholung(
      () async {
        versuchsZähler++;
        // Simuliere: Erst beim 3. Versuch erfolgreich
        if (versuchsZähler < 3) {
          throw Exception('Server nicht erreichbar (Versuch $versuchsZähler)');
        }
        return 'Erfolgreich beim $versuchsZähler. Versuch!';
      },
      maxVersuche: 3,
    );
    print('Retry-Ergebnis: $ergebnis');
  } catch (e) {
    print('Endgültig fehlgeschlagen: $e');
  }

  print('\n=== Programm beendet ===');
}
```

## Erwartete Ausgabe

```
=== Asynchroner Datei-Prozessor ===

Dateien: 6
  - bericht.txt (200 KB, .txt)
  - daten.csv (500 KB, .csv)
  - fehler_datei.json (100 KB, .json)
  - config.json (50 KB, .json)
  - protokoll.txt (300 KB, .txt)
  - export.xml (150 KB, .xml)

--- Sequentielle Verarbeitung mit Fortschritt ---
[  0%] Starte: bericht.txt...
[ 17%] Fertig:  bericht.txt — abgeschlossen (0.9s)
[ 17%] Starte: daten.csv...
[ 33%] Fertig:  daten.csv — abgeschlossen (1.5s)
[ 33%] Starte: fehler_datei.json...
[ 50%] FEHLER: fehler_datei.json — fehler: ...
[ 50%] Starte: config.json...
[ 67%] Fertig:  config.json — abgeschlossen (0.6s)
[ 67%] Starte: protokoll.txt...
[ 83%] Fertig:  protokoll.txt — abgeschlossen (1.1s)
[ 83%] Starte: export.xml...
[100%] Fertig:  export.xml — abgeschlossen (0.8s)

Sequentielle Gesamtzeit: 5.2s

--- Parallele Verarbeitung ---
Alle 6 Dateien gleichzeitig gestartet...
  [OK] bericht.txt — 0.9s: INHALT VON BERICHT.TXT (200 KB)
  [OK] daten.csv — 1.5s: CSV verarbeitet: 6 Felder gefunden
  [FEHLER] fehler_datei.json — 0.2s: Exception: ...
  [OK] config.json — 0.6s: JSON geparst: 28 Zeichen verarbeitet
  [OK] protokoll.txt — 1.1s: INHALT VON PROTOKOLL.TXT (300 KB)
  [OK] export.xml — 0.8s: XML transformiert: ...

Parallele Gesamtzeit: 1.5s (3.7s schneller!)

--- Gesamtzusammenfassung ---
Erfolgreich: 5/6
Fehlgeschlagen: 1/6
Schnellste: config.json (0.6s)
Langsamste: daten.csv (1.5s)

--- Bonus: Timeout ---
Erwarteter Timeout: TimeoutException ...

--- Bonus: Retry-Logik ---
  Versuch 1/3 fehlgeschlagen. Nächster Versuch in 500ms...
  Versuch 2/3 fehlgeschlagen. Nächster Versuch in 1000ms...
Retry-Ergebnis: Erfolgreich beim 3. Versuch!

=== Programm beendet ===
```

## Erklärung der Dart-spezifischen Features

| Feature | Wo in der Lösung | Erklärung |
|---------|------------------|-----------|
| `Future.delayed` | `ladeDatei()`, `verarbeiteDatei()` | Simuliert asynchrone I/O durch verzögerte Futures |
| `async` / `await` | Überall | Macht asynchronen Code lesbar wie synchronen Code |
| `try` / `catch` | `verarbeiteEineDatei()` | Fehlerbehandlung in async-Funktionen — fängt Future-Fehler |
| `Future.wait` | `verarbeiteParallel()` | Startet mehrere Futures parallel und wartet auf alle |
| `async*` / `yield` | `verarbeiteMitFortschritt()` | Generator-Funktion, die einen Stream erzeugt |
| `await for` | `main()` | Iteriert über Stream-Werte (wie `for await` in JS) |
| `StreamController.broadcast()` | `VerarbeitungsMonitor` | Erlaubt mehrere Listener auf dem gleichen Stream |
| `listen()` | Monitor, Log-Subscription | Abonniert einen Stream (Alternative zu `await for`) |
| `Completer` | `überwache()` | Manuelles Vervollständigen eines Future (Callback → Future) |
| `.timeout()` | `mitTimeout()` | Zeitlimit für Futures — wirft TimeoutException |
| `Stopwatch` | Zeitmessungen | Misst tatsächlich verstrichene Zeit |
| `rethrow` | `mitWiederholung()` | Wirft den aktuellen Fehler erneut (behält Stack Trace) |
| `dispose()` | `VerarbeitungsMonitor` | Ressourcen-Freigabe-Pattern (wichtig in Flutter!) |
