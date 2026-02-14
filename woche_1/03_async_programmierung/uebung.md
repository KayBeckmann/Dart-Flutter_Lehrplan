# Modul 3: Übung — Asynchroner Datei-Prozessor (Simulation)

## Ziel

Baue eine Simulation eines asynchronen Dateiverarbeitungssystems. Da wir kein echtes Dateisystem verwenden, werden alle I/O-Operationen mit `Future.delayed` simuliert. Die Übung festigt den Umgang mit Futures, async/await, Streams, Generatoren und Fehlerbehandlung.

## Szenario

Du entwickelst ein System, das "Dateien" lädt, verarbeitet und die Ergebnisse zusammenfasst. Das System soll robust mit Fehlern umgehen und Fortschrittsinformationen über einen Stream bereitstellen.

## Anforderungen

### 1. Datenmodell

Erstelle eine Klasse `DateiInfo` mit:
- Feldern: `name` (String), `größeKb` (int), `typ` (String, z.B. 'txt', 'csv', 'json')
- Einer `toString()`-Methode

Erstelle eine Klasse `VerarbeitungsErgebnis` mit:
- Feldern: `datei` (DateiInfo), `dauer` (Duration), `erfolgreich` (bool), `nachricht` (String)

### 2. Simulierte I/O-Funktionen

Implementiere folgende Funktionen, die Dateioperationen mit `Future.delayed` simulieren:

**`ladeDatei(DateiInfo datei)`** → `Future<String>`
- Simuliert das Laden einer Datei
- Wartezeit proportional zur Dateigröße: `größeKb * 2` Millisekunden (max 2000ms)
- Gibt den "Dateiinhalt" als String zurück: `"Inhalt von {name} ({größeKb} KB)"`
- Wirft eine Exception, wenn der Dateiname mit 'fehler' beginnt (Fehlersimulation)

**`verarbeiteDatei(String inhalt, String typ)`** → `Future<String>`
- Simuliert die Verarbeitung des Dateiinhalts
- Wartezeit: 500ms
- Gibt einen verarbeiteten String zurück (z.B. Inhalt in Großbuchstaben für 'txt', Wortzählung für 'csv', etc.)

### 3. Einzeldatei-Verarbeitung mit Fehlerbehandlung

Implementiere `verarbeiteEineDatei(DateiInfo datei)` → `Future<VerarbeitungsErgebnis>`
- Lädt und verarbeitet die Datei
- Misst die verstrichene Zeit mit `Stopwatch`
- Gibt ein `VerarbeitungsErgebnis` zurück
- Fängt Fehler ab und gibt ein `VerarbeitungsErgebnis` mit `erfolgreich: false` zurück (kein Crash!)

### 4. Parallele Verarbeitung mit `Future.wait`

Implementiere `verarbeiteParallel(List<DateiInfo> dateien)` → `Future<List<VerarbeitungsErgebnis>>`
- Startet alle Dateiverarbeitungen **gleichzeitig** (parallel)
- Verwendet `Future.wait`
- Gibt alle Ergebnisse zurück (auch fehlerhafte)

### 5. Fortschritts-Stream mit `async*` Generator

Implementiere `verarbeiteMitFortschritt(List<DateiInfo> dateien)` → `Stream<FortschrittsInfo>`

Erstelle dafür eine Klasse `FortschrittsInfo` mit:
- `aktuellerIndex` (int)
- `gesamt` (int)
- `dateiName` (String)
- `status` (String: 'gestartet', 'abgeschlossen', 'fehler')
- Getter `prozent` → `double` (0.0 bis 1.0)

Der Generator soll:
- Die Dateien **sequentiell** (nacheinander) verarbeiten
- Vor und nach jeder Datei ein `FortschrittsInfo`-Event yielden
- Bei Fehlern ein Fehler-Event yielden und mit der nächsten Datei fortfahren

### 6. StreamController für Live-Statistiken

Erstelle eine Klasse `VerarbeitungsMonitor` mit:
- Einem privaten `StreamController<String>.broadcast()` für Log-Nachrichten
- Einem öffentlichen Getter `logStream` → `Stream<String>`
- Einer Methode `überwache(Stream<FortschrittsInfo> fortschritt)`, die:
  - Den Fortschritts-Stream abonniert
  - Formatierte Log-Nachrichten in den eigenen StreamController einspeist
  - Am Ende eine Zusammenfassung ausgibt
- Einer `dispose()`-Methode zum Aufräumen

### 7. Main-Funktion

In `main()`:

1. Erstelle eine Liste mit mindestens 6 Testdateien (verschiedene Größen und Typen, mindestens eine mit 'fehler' im Namen)

2. **Sequentielle Verarbeitung** mit Fortschrittsanzeige:
   - Verwende `verarbeiteMitFortschritt()` mit `await for`
   - Gib den Fortschritt aus

3. **Parallele Verarbeitung:**
   - Verwende `verarbeiteParallel()`
   - Vergleiche die Gesamtzeit mit der sequentiellen Verarbeitung

4. **Zusammenfassung:**
   - Anzahl erfolgreicher/fehlerhafter Verarbeitungen
   - Gesamtdauer
   - Schnellste und langsamste Datei

## Erwartete Ausgabe (ungefähr)

```
=== Asynchroner Datei-Prozessor ===

--- Sequentielle Verarbeitung mit Fortschritt ---
[  0%] Starte: bericht.txt (200 KB)...
[ 17%] Fertig:  bericht.txt — 0.9s
[ 17%] Starte: daten.csv (500 KB)...
[ 33%] Fertig:  daten.csv — 1.5s
[ 33%] Starte: fehler_datei.json (100 KB)...
[ 50%] FEHLER: fehler_datei.json — Datei konnte nicht geladen werden
[ 50%] Starte: config.json (50 KB)...
[ 67%] Fertig:  config.json — 0.6s
...

Sequentielle Gesamtzeit: 5.2s

--- Parallele Verarbeitung ---
Alle 6 Dateien gleichzeitig gestartet...
Parallele Gesamtzeit: 1.8s (3.4s schneller!)

--- Zusammenfassung ---
Erfolgreich: 5/6
Fehlgeschlagen: 1/6
Schnellste: config.json (0.6s)
Langsamste: großeDatei.csv (1.8s)
```

## Hinweise

- Verwende `Stopwatch` für Zeitmessungen: `var sw = Stopwatch()..start();` und `sw.elapsed`.
- `Future.delayed(Duration(milliseconds: n))` simuliert I/O-Wartezeit.
- Vergiss nicht, StreamController mit `close()` zu schließen und Subscriptions mit `cancel()` zu beenden.
- Alle Fehler sollen **gefangen** werden — das Programm darf nicht abstürzen.
- Teste mit `dart run dateiname.dart` oder in DartPad (ohne `dart:io`).

## Bonusaufgaben

1. **Timeout:** Implementiere ein Timeout für einzelne Dateioperationen (z.B. 3 Sekunden). Verwende `Future.any` oder `.timeout()`.

2. **Retry-Logik:** Implementiere eine Funktion `mitWiederholung<T>(Future<T> Function() operation, {int maxVersuche = 3})`, die fehlgeschlagene Operationen bis zu N Mal wiederholt.

3. **Abbruch-Mechanismus:** Erweitere den Monitor um eine `abbrechen()`-Methode, die die laufende Verarbeitung über einen `Completer` abbricht.
