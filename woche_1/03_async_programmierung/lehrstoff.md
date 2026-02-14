# Modul 3: Asynchrone Programmierung in Dart

## 3.1 Das Event-Loop-Modell

Dart ist **single-threaded** — es gibt nur einen Ausführungsstrang. Asynchrone Operationen werden über einen **Event Loop** gesteuert, ähnlich wie in JavaScript/Node.js.

### Wie der Event Loop funktioniert

```
┌──────────────────────────────────────────────┐
│                 Event Loop                    │
│                                              │
│  1. Synchronen Code ausführen                │
│  2. Microtask-Queue abarbeiten               │
│  3. Event-Queue abarbeiten (Timer, I/O, etc.)│
│  4. Zurück zu Schritt 2                      │
│                                              │
└──────────────────────────────────────────────┘
```

Es gibt **zwei Queues**:

| Queue | Priorität | Typische Quellen |
|-------|-----------|-----------------|
| **Microtask Queue** | Höher (wird zuerst abgearbeitet) | `Future.microtask()`, `scheduleMicrotask()` |
| **Event Queue** | Niedriger | `Future()`, `Future.delayed()`, I/O, Timer, UI-Events |

```dart
void main() {
  print('1: Start');

  // Event Queue — wird zuletzt ausgeführt
  Future(() => print('4: Future (Event Queue)'));

  // Microtask Queue — wird vor Event Queue ausgeführt
  Future.microtask(() => print('3: Microtask'));

  print('2: Ende des synchronen Codes');
}

// Ausgabe:
// 1: Start
// 2: Ende des synchronen Codes
// 3: Microtask
// 4: Future (Event Queue)
```

**Vergleich zu JavaScript:** Nahezu identisch — JavaScript hat ebenfalls einen Event Loop mit Microtask Queue (Promise-Callbacks) und Macrotask Queue (setTimeout, I/O). Wer den JS Event Loop versteht, versteht auch Darts Modell.

**Vergleich zu Python:** Python's `asyncio` hat einen ähnlichen Event Loop, aber er muss explizit gestartet werden (`asyncio.run()`). In Dart läuft der Event Loop automatisch.

**Vergleich zu C++:** C++ hat keine eingebaute Event Loop (außer in Frameworks). Asynchronität wird über Threads, `std::async` oder `std::future` gelöst. Darts Modell ist fundamental anders — ein Thread, keine Race Conditions.

---

## 3.2 Futures

Ein `Future<T>` repräsentiert einen Wert vom Typ `T`, der **in der Zukunft** verfügbar sein wird. Es ist Darts Äquivalent zu JavaScript's `Promise`.

### Zustände eines Future

```
Future<T>
  ├── Uncompleted (ausstehend)
  ├── Completed with value (erfolgreich, Typ T)
  └── Completed with error (fehlgeschlagen)
```

### Futures erstellen

```dart
// 1. Future.value — sofort erfüllt (nützlich für Tests/Mocking)
Future<String> sofort() => Future.value('Sofort da!');

// 2. Future.delayed — nach einer Verzögerung erfüllt
Future<String> verzögert() =>
    Future.delayed(Duration(seconds: 2), () => 'Nach 2 Sekunden');

// 3. Future.error — sofort fehlgeschlagen
Future<String> fehler() => Future.error('Etwas ging schief');

// 4. Implizit durch async-Funktionen (siehe nächster Abschnitt)
Future<int> berechne() async {
  return 42;  // Wird automatisch in Future.value(42) verpackt
}
```

### Futures verketten mit `.then`, `.catchError`, `.whenComplete`

```dart
void main() {
  print('Anfrage startet...');

  holeDaten()
      .then((daten) {
        // Wird aufgerufen, wenn das Future erfolgreich abgeschlossen ist
        print('Daten erhalten: $daten');
        return verarbeiteDaten(daten);  // Gibt ein neues Future zurück
      })
      .then((ergebnis) {
        print('Verarbeitet: $ergebnis');
      })
      .catchError((fehler) {
        // Fängt Fehler aus ALLEN vorherigen .then()-Aufrufen
        print('Fehler: $fehler');
      })
      .whenComplete(() {
        // Wird IMMER ausgeführt (wie finally)
        print('Fertig (egal ob Erfolg oder Fehler)');
      });

  print('Anfrage gesendet (asynchron).');
}

Future<String> holeDaten() =>
    Future.delayed(Duration(seconds: 1), () => 'API-Antwort');

Future<String> verarbeiteDaten(String daten) =>
    Future.delayed(Duration(milliseconds: 500), () => daten.toUpperCase());
```

**Vergleich zu JS:** `.then()` / `.catch()` / `.finally()` in JavaScript ist nahezu identisch. In Dart heißen die Methoden `.then()` / `.catchError()` / `.whenComplete()`.

---

## 3.3 async / await

`async` / `await` ist syntaktischer Zucker, der asynchronen Code wie synchronen Code aussehen lässt. Der Compiler transformiert ihn intern in Future-Chains.

```dart
// MIT async/await — lesbar und verständlich
Future<void> hauptprogramm() async {
  print('Anfrage startet...');

  try {
    final daten = await holeDaten();           // Wartet auf das Future
    print('Daten erhalten: $daten');

    final ergebnis = await verarbeiteDaten(daten); // Wartet auf das nächste Future
    print('Verarbeitet: $ergebnis');
  } catch (e) {
    print('Fehler: $e');
  } finally {
    print('Fertig.');
  }
}

// Simulierte asynchrone Funktionen
Future<String> holeDaten() async {
  // await Future.delayed simuliert eine Netzwerkanfrage
  await Future.delayed(Duration(seconds: 1));
  return 'API-Antwort';
}

Future<String> verarbeiteDaten(String daten) async {
  await Future.delayed(Duration(milliseconds: 500));
  return daten.toUpperCase();
}

void main() async {
  await hauptprogramm();
  print('Programm beendet.');
}
```

### Wichtige Regeln für async/await

```dart
// 1. Eine async-Funktion gibt IMMER ein Future zurück
Future<int> gibZahl() async => 42;
// Rückgabetyp ist Future<int>, nicht int!

// 2. await kann NUR in async-Funktionen verwendet werden
// void test() { await gibZahl(); }  // FEHLER!
void test() async { await gibZahl(); }  // OK

// 3. await blockiert NICHT den Event Loop — es pausiert nur DIESE Funktion
void main() async {
  print('Vor await');
  await Future.delayed(Duration(seconds: 1));
  // Während der Wartezeit können andere Events verarbeitet werden
  print('Nach await');
}

// 4. void vs. Future<void> bei async-Funktionen
void feuerUndVergiss() async {
  // WARNUNG: Fehler gehen verloren, da kein Future zurückgegeben wird!
  await Future.delayed(Duration(seconds: 1));
  throw 'Dieser Fehler geht verloren!';
}

Future<void> besser() async {
  // Future<void> ermöglicht await und Fehlerbehandlung durch den Aufrufer
  await Future.delayed(Duration(seconds: 1));
}
```

**Vergleich zu JS:** Nahezu identisch — `async function` / `await` in JS funktioniert genauso. Der einzige Unterschied: In Dart muss man explizit `Future<void>` als Rückgabetyp angeben.

**Vergleich zu Python:** Python's `async def` / `await` ist syntaktisch sehr ähnlich, aber Python benötigt eine Event Loop (`asyncio.run()`), die nicht automatisch läuft.

---

## 3.4 Fehlerbehandlung in asynchronem Code

```dart
// 1. try/catch mit await
Future<void> mitTryCatch() async {
  try {
    var ergebnis = await riskanteOperation();
    print('Erfolg: $ergebnis');
  } on FormatException catch (e) {
    // Spezifischer Fehlertyp
    print('Format-Fehler: $e');
  } on TimeoutException {
    // Anderer spezifischer Fehlertyp
    print('Zeitüberschreitung!');
  } catch (e, stackTrace) {
    // Alle anderen Fehler (mit Stack Trace)
    print('Unbekannter Fehler: $e');
    print('Stack Trace: $stackTrace');
  } finally {
    print('Aufräumarbeiten...');
  }
}

// 2. Fehler in Future-Chains
Future<void> mitCatchError() {
  return riskanteOperation()
      .then((wert) => print('Erfolg: $wert'))
      .catchError(
        (e) => print('Fehler: $e'),
        test: (e) => e is FormatException,  // Nur bestimmte Fehler fangen
      )
      .whenComplete(() => print('Fertig'));
}

// 3. Fehler aus mehreren Futures
Future<void> mehrereFutures() async {
  try {
    // Future.wait wirft den ERSTEN Fehler, der auftritt
    var ergebnisse = await Future.wait([
      holeDatenA(),
      holeDatenB(),
      holeDatenC(),
    ]);
    print('Alle erfolgreich: $ergebnisse');
  } catch (e) {
    print('Mindestens ein Future ist fehlgeschlagen: $e');
  }
}

Future<String> riskanteOperation() async {
  await Future.delayed(Duration(milliseconds: 100));
  if (DateTime.now().second % 2 == 0) {
    throw FormatException('Ungültige Daten');
  }
  return 'OK';
}

Future<String> holeDatenA() => Future.delayed(Duration(seconds: 1), () => 'A');
Future<String> holeDatenB() => Future.delayed(Duration(seconds: 2), () => 'B');
Future<String> holeDatenC() => Future.delayed(Duration(seconds: 1), () => 'C');
```

---

## 3.5 Future-Kombinatoren

### `Future.wait` — Alle Futures parallel ausführen

```dart
Future<void> parallelLaden() async {
  print('Lade alles parallel...');

  // Alle drei Futures starten gleichzeitig
  // Future.wait wartet, bis ALLE fertig sind
  var ergebnisse = await Future.wait([
    ladeBenutzerdaten(),    // dauert 2 Sekunden
    ladeEinstellungen(),    // dauert 1 Sekunde
    ladeBenachrichtigungen(), // dauert 3 Sekunden
  ]);

  // Gesamtzeit: ~3 Sekunden (nicht 6!), da sie parallel laufen
  print('Benutzerdaten: ${ergebnisse[0]}');
  print('Einstellungen: ${ergebnisse[1]}');
  print('Benachrichtigungen: ${ergebnisse[2]}');
}

Future<String> ladeBenutzerdaten() =>
    Future.delayed(Duration(seconds: 2), () => 'Max Mustermann');
Future<String> ladeEinstellungen() =>
    Future.delayed(Duration(seconds: 1), () => 'Dunkel-Modus: An');
Future<String> ladeBenachrichtigungen() =>
    Future.delayed(Duration(seconds: 3), () => '5 neue Nachrichten');
```

### `Future.any` — Das schnellste Future gewinnt

```dart
Future<void> schnellsterGewinnt() async {
  // Gibt das Ergebnis des ERSTEN abgeschlossenen Future zurück
  var schnellstes = await Future.any([
    Future.delayed(Duration(seconds: 3), () => 'Server A'),
    Future.delayed(Duration(seconds: 1), () => 'Server B'),  // Gewinnt!
    Future.delayed(Duration(seconds: 2), () => 'Server C'),
  ]);

  print('Schnellste Antwort von: $schnellstes');  // Server B
}
```

### `Future.delayed` — Verzögerte Ausführung

```dart
// Timer / Verzögerung
Future<void> mitVerzögerung() async {
  print('Warte 2 Sekunden...');
  await Future.delayed(Duration(seconds: 2));
  print('Fertig!');

  // Mit Rückgabewert
  var wert = await Future.delayed(
    Duration(seconds: 1),
    () => 'Verzögerter Wert',
  );
  print(wert);
}
```

### `Future.forEach` — Sequentielle Verarbeitung

```dart
Future<void> sequentiellVerarbeiten() async {
  var aufgaben = ['Datei 1', 'Datei 2', 'Datei 3'];

  // Verarbeitet NACHEINANDER (nicht parallel)
  await Future.forEach(aufgaben, (aufgabe) async {
    print('Verarbeite $aufgabe...');
    await Future.delayed(Duration(seconds: 1));
    print('$aufgabe fertig.');
  });

  print('Alle Aufgaben abgeschlossen.');
}
```

---

## 3.6 Streams

Während ein `Future` **einen einzigen** zukünftigen Wert darstellt, repräsentiert ein `Stream` eine **Sequenz von asynchronen Werten** über die Zeit.

**Analogie:**
- `Future<T>` = ein einzelnes asynchrones Ergebnis (wie ein `Promise` in JS)
- `Stream<T>` = mehrere asynchrone Ergebnisse über die Zeit (wie ein Observable in RxJS)

### Zwei Arten von Streams

| Typ | Beschreibung | Beispiel |
|-----|-------------|---------|
| **Single-Subscription** | Nur **ein** Listener erlaubt | Datei lesen, HTTP-Antwort |
| **Broadcast** | **Mehrere** Listener erlaubt | UI-Events, WebSocket-Nachrichten |

### Stream erstellen und nutzen

```dart
import 'dart:async';

// 1. Stream aus einer Iterable erstellen
void streamAusListe() {
  var stream = Stream.fromIterable([1, 2, 3, 4, 5]);

  // listen() abonniert den Stream
  stream.listen(
    (wert) => print('Wert: $wert'),       // onData
    onError: (e) => print('Fehler: $e'),   // onError
    onDone: () => print('Stream beendet'), // onDone
    cancelOnError: false,                   // Bei Fehler nicht abbrechen
  );
}

// 2. Stream.periodic — gibt regelmäßig Werte aus
void periodischerStream() {
  var stream = Stream.periodic(
    Duration(seconds: 1),
    (zähler) => 'Tick $zähler',  // Transformation des Zählers
  ).take(5);  // Nur die ersten 5 Werte

  stream.listen(print);
  // Tick 0, Tick 1, Tick 2, Tick 3, Tick 4
}

// 3. await for — Stream mit await konsumieren
Future<void> mitAwaitFor() async {
  var stream = Stream.fromIterable([10, 20, 30, 40, 50]);

  // await for iteriert über jeden Wert im Stream
  await for (var wert in stream) {
    print('Empfangen: $wert');
  }
  print('Stream beendet.');
}
```

### Stream-Methoden (Transformationen)

```dart
Future<void> streamMethoden() async {
  var zahlen = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  // map — jeden Wert transformieren
  var verdoppelt = zahlen.map((n) => n * 2);

  // where — filtern
  var stream2 = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  var gerade = stream2.where((n) => n.isEven);

  // Mehrere Transformationen verketten
  var stream3 = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  var ergebnis = stream3
      .where((n) => n.isEven)      // 2, 4, 6, 8, 10
      .map((n) => n * n)            // 4, 16, 36, 64, 100
      .take(3);                     // 4, 16, 36

  await for (var w in ergebnis) {
    print(w);
  }

  // Weitere nützliche Stream-Methoden:
  var stream4 = Stream.fromIterable([1, 2, 3, 4, 5]);
  print(await stream4.first);         // 1

  var stream5 = Stream.fromIterable([1, 2, 3, 4, 5]);
  print(await stream5.last);          // 5

  var stream6 = Stream.fromIterable([1, 2, 3, 4, 5]);
  print(await stream6.length);        // 5

  var stream7 = Stream.fromIterable([1, 2, 3, 4, 5]);
  print(await stream7.contains(3));   // true

  var stream8 = Stream.fromIterable([1, 2, 3, 4, 5]);
  var liste = await stream8.toList(); // [1, 2, 3, 4, 5]
  print(liste);

  var stream9 = Stream.fromIterable([1, 2, 3, 4, 5]);
  var summe = await stream9.reduce((a, b) => a + b);  // 15
  print(summe);
}
```

**Vergleich zu JS:** Streams in Dart entsprechen am ehesten RxJS Observables oder Node.js ReadableStreams. JavaScript hat seit kurzem auch `ReadableStream` und Async Iterators (`for await...of`), aber Darts Stream-API ist ausgereifter.

---

## 3.7 StreamController

Ein `StreamController` ermöglicht es, einen eigenen Stream programmatisch zu befüllen:

```dart
import 'dart:async';

// Single-Subscription StreamController (Standard)
void singleSubscription() {
  // Controller erstellen
  var controller = StreamController<String>();

  // Stream abonnieren
  controller.stream.listen(
    (daten) => print('Empfangen: $daten'),
    onDone: () => print('Stream geschlossen'),
  );

  // Werte in den Stream einspeisen
  controller.add('Hallo');
  controller.add('Welt');
  controller.add('Dart');

  // Stream schließen (onDone wird aufgerufen)
  controller.close();
}

// Broadcast StreamController (mehrere Listener erlaubt)
void broadcastStream() {
  var controller = StreamController<int>.broadcast();

  // Erster Listener
  controller.stream.listen(
    (wert) => print('Listener A: $wert'),
  );

  // Zweiter Listener
  controller.stream.listen(
    (wert) => print('Listener B: ${wert * 10}'),
  );

  controller.add(1);  // Listener A: 1, Listener B: 10
  controller.add(2);  // Listener A: 2, Listener B: 20
  controller.add(3);  // Listener A: 3, Listener B: 30

  controller.close();
}

// StreamController mit Ressourcen-Management
class Datenproduzent {
  final _controller = StreamController<String>();
  Timer? _timer;
  int _zähler = 0;

  // Stream nach außen geben (read-only)
  Stream<String> get stream => _controller.stream;

  void starte() {
    _timer = Timer.periodic(Duration(seconds: 1), (_) {
      _zähler++;
      _controller.add('Datenpunkt $_zähler');

      if (_zähler >= 5) {
        stoppe();
      }
    });
  }

  void stoppe() {
    _timer?.cancel();
    _controller.close();
  }
}

void main() async {
  var produzent = Datenproduzent();

  produzent.stream.listen(
    (daten) => print(daten),
    onDone: () => print('Produzent gestoppt.'),
  );

  produzent.starte();
  // Datenpunkt 1 ... Datenpunkt 5
}
```

---

## 3.8 Async-Generatoren: `async*`, `yield`, `yield*`

Async-Generatoren erzeugen Streams deklarativ — ähnlich wie synchrone Generatoren (`sync*`/`Iterable`), aber für asynchrone Werte:

```dart
// sync* generiert ein Iterable (synchron)
Iterable<int> zähleSync(int bis) sync* {
  for (var i = 1; i <= bis; i++) {
    yield i;  // Gibt einen Wert zurück und pausiert
  }
}

// async* generiert einen Stream (asynchron)
Stream<int> zähleAsync(int bis) async* {
  for (var i = 1; i <= bis; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i;  // Gibt einen Wert in den Stream und pausiert
  }
}

// yield* delegiert an einen anderen Stream/Iterable
Stream<int> kombiniereStreams() async* {
  yield* zähleAsync(3);       // 1, 2, 3
  yield 0;                     // 0
  yield* zähleAsync(3);       // 1, 2, 3
}

// Praktisches Beispiel: Seitenweise Daten laden
Stream<List<String>> ladeSeitenweise({int seitenGröße = 10}) async* {
  var seite = 0;
  var hatMehr = true;

  while (hatMehr) {
    // Simuliere API-Aufruf
    await Future.delayed(Duration(seconds: 1));
    var daten = List.generate(
      seitenGröße,
      (i) => 'Element ${seite * seitenGröße + i}',
    );

    yield daten;

    seite++;
    hatMehr = seite < 3;  // Simuliere: 3 Seiten verfügbar
  }
}

// Fortschrittsanzeige mit Generator
Stream<double> fortschritt(int schritte) async* {
  for (var i = 0; i <= schritte; i++) {
    await Future.delayed(Duration(milliseconds: 200));
    yield i / schritte;  // 0.0 bis 1.0
  }
}

void main() async {
  // Synchroner Generator
  print('Synchron: ${zähleSync(5).toList()}');  // [1, 2, 3, 4, 5]

  // Asynchroner Generator mit await for
  print('\nAsynchron:');
  await for (var zahl in zähleAsync(5)) {
    print('  $zahl');
  }

  // Fortschritt
  print('\nFortschritt:');
  await for (var prozent in fortschritt(10)) {
    var balken = '=' * (prozent * 20).round();
    var leer = ' ' * (20 - (prozent * 20).round());
    // \r setzt den Cursor an den Zeilenanfang (Überschreiben)
    print('[$balken$leer] ${(prozent * 100).toStringAsFixed(0)}%');
  }

  // Seitenweises Laden
  print('\nSeitenweise:');
  await for (var seite in ladeSeitenweise(seitenGröße: 3)) {
    print('  Seite geladen: $seite');
  }
}
```

**Vergleich zu Python:** Python hat `async for` und `async def ... yield` (async generators). Die Syntax ist sehr ähnlich. Dart verwendet `async*` statt `async def`.

**Vergleich zu JS:** JavaScript hat `async function*` (async generators) und `for await...of`, was konzeptionell identisch ist.

---

## 3.9 Completer

Ein `Completer` ermöglicht es, ein Future manuell von außen zu vervollständigen — nützlich wenn man eine Callback-basierte API in eine Future-basierte umwandeln will:

```dart
import 'dart:async';

/// Verpackt eine Callback-basierte Operation in ein Future.
Future<String> ladeÜberCallback() {
  // Completer erstellt ein Future, das wir manuell vervollständigen können
  var completer = Completer<String>();

  // Simuliere eine Callback-basierte API
  simuliereCallbackApi(
    erfolgCallback: (daten) {
      // Future mit Wert vervollständigen
      completer.complete(daten);
    },
    fehlerCallback: (fehler) {
      // Future mit Fehler vervollständigen
      completer.completeError(fehler);
    },
  );

  // Das Future kann bereits zurückgegeben werden,
  // obwohl es noch nicht vervollständigt ist
  return completer.future;
}

void simuliereCallbackApi({
  required void Function(String) erfolgCallback,
  required void Function(String) fehlerCallback,
}) {
  // Simulierte asynchrone Operation
  Timer(Duration(seconds: 1), () {
    erfolgCallback('Daten vom Callback');
  });
}

/// Timeout-Wrapper mit Completer
Future<T> mitTimeout<T>(Future<T> future, Duration timeout) {
  var completer = Completer<T>();

  // Timer für den Timeout
  var timer = Timer(timeout, () {
    if (!completer.isCompleted) {
      completer.completeError(TimeoutException('Zeitüberschreitung', timeout));
    }
  });

  // Wenn das Future zuerst fertig wird
  future.then((wert) {
    timer.cancel();
    if (!completer.isCompleted) {
      completer.complete(wert);
    }
  }).catchError((fehler) {
    timer.cancel();
    if (!completer.isCompleted) {
      completer.completeError(fehler);
    }
  });

  return completer.future;
}

void main() async {
  try {
    var ergebnis = await ladeÜberCallback();
    print(ergebnis);  // Daten vom Callback

    var mitZeit = await mitTimeout(
      Future.delayed(Duration(seconds: 2), () => 'Langsam'),
      Duration(seconds: 1),
    );
    print(mitZeit);
  } on TimeoutException catch (e) {
    print('Timeout: $e');
  }
}
```

**Hinweis:** `Completer` wird in der Praxis selten direkt benötigt, da `async/await` die meisten Anwendungsfälle abdeckt. Er ist jedoch nützlich bei der Integration von Callback-basierten APIs (z.B. Platform Channels in Flutter).

---

## 3.10 Isolates (Überblick)

Für CPU-intensive Berechnungen, die den Event Loop blockieren würden, bietet Dart **Isolates** — unabhängige Ausführungseinheiten mit eigenem Speicher:

```dart
import 'dart:isolate';

// Einfache Verwendung mit Isolate.run (Dart 2.19+)
Future<void> mitIsolateRun() async {
  // Die Berechnung läuft in einem separaten Isolate
  var ergebnis = await Isolate.run(() {
    // CPU-intensive Berechnung
    var summe = 0;
    for (var i = 0; i < 1000000000; i++) {
      summe += i;
    }
    return summe;
  });

  print('Ergebnis: $ergebnis');
}

// compute() in Flutter — noch einfacher
// (Flutter-spezifisch, nicht in dart:isolate)
// var ergebnis = await compute(teureBerechnung, parameter);
```

### Isolates vs. Threads

| Eigenschaft | Dart Isolate | C++/Java Thread |
|-------------|-------------|----------------|
| Geteilter Speicher | **Nein** — jedes Isolate hat eigenen Heap | Ja |
| Kommunikation | Über Messages (SendPort/ReceivePort) | Über geteilten Speicher |
| Race Conditions | **Unmöglich** (kein geteilter Zustand) | Möglich (Locks nötig) |
| Overhead | Höher (eigener Heap) | Niedriger |

**Vergleich zu JS:** JavaScript hat Web Workers (ähnlich — separater Speicher, Message Passing).

**Vergleich zu Python:** Python hat `multiprocessing` (ähnlich — separate Prozesse) und den GIL für Threads.

**Vergleich zu C++:** C++ Threads teilen sich den Speicher — Darts Isolates sind sicherer, da Race Conditions strukturell ausgeschlossen sind.

---

## 3.11 Zusammenfassendes Beispiel

```dart
import 'dart:async';

/// Ein vollständiges Beispiel, das Futures, Streams, async/await
/// und Generatoren kombiniert.

// Simulierter Datenbankservice
class DatenbankService {
  final _änderungenController = StreamController<String>.broadcast();

  /// Stream von Datenbankänderungen (Broadcast — mehrere Listener).
  Stream<String> get änderungen => _änderungenController.stream;

  /// Simuliert das Laden eines Benutzers (Future).
  Future<Map<String, dynamic>> ladeBenutzer(int id) async {
    await Future.delayed(Duration(milliseconds: 500));

    if (id < 0) throw ArgumentError('Ungültige ID: $id');

    return {
      'id': id,
      'name': 'Benutzer $id',
      'email': 'user$id@example.com',
    };
  }

  /// Simuliert das Laden mehrerer Benutzer parallel.
  Future<List<Map<String, dynamic>>> ladeAlleBenutzer(List<int> ids) async {
    return Future.wait(ids.map((id) => ladeBenutzer(id)));
  }

  /// Stream-Generator: Gibt Benutzer seitenweise zurück.
  Stream<Map<String, dynamic>> streamBenutzer(int anzahl) async* {
    for (var i = 1; i <= anzahl; i++) {
      var benutzer = await ladeBenutzer(i);
      _änderungenController.add('Benutzer $i geladen');
      yield benutzer;
    }
  }

  /// Aufräumen — Controller schließen.
  void dispose() {
    _änderungenController.close();
  }
}

void main() async {
  var db = DatenbankService();

  // 1. Einzelner Future
  print('=== Einzelner Benutzer ===');
  var benutzer = await db.ladeBenutzer(1);
  print(benutzer);

  // 2. Parallele Futures
  print('\n=== Mehrere Benutzer parallel ===');
  var alle = await db.ladeAlleBenutzer([1, 2, 3, 4, 5]);
  for (var b in alle) {
    print('  ${b['name']}');
  }

  // 3. Fehlerbehandlung
  print('\n=== Fehlerbehandlung ===');
  try {
    await db.ladeBenutzer(-1);
  } catch (e) {
    print('Erwarteter Fehler: $e');
  }

  // 4. Stream abonnieren (Änderungen beobachten)
  print('\n=== Stream-Verarbeitung ===');
  var änderungsAbo = db.änderungen.listen(
    (änderung) => print('  Änderung: $änderung'),
  );

  // 5. Async Generator mit await for
  await for (var b in db.streamBenutzer(3)) {
    print('  Empfangen: ${b['name']}');
  }

  // 6. Aufräumen
  await änderungsAbo.cancel();
  db.dispose();

  print('\nFertig!');
}
```
