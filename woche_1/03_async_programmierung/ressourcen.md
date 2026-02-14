# Modul 3: Ressourcen — Asynchrone Programmierung

## Offizielle Dokumentation

- **Asynchronous Programming: Futures, async, await**
  https://dart.dev/codelabs/async-await
  Offizielles interaktives Codelab — die beste Einführung in async/await in Dart.

- **Dart Language Tour: Asynchrony Support**
  https://dart.dev/language/async
  Offizielle Referenz zu `async`, `await`, `Future`, `Stream`, Generatoren.

- **Dart Streams Tutorial**
  https://dart.dev/tutorials/language/streams
  Ausführliches Tutorial zu Streams, StreamController und Stream-Transformationen.

- **dart:async Library**
  https://api.dart.dev/stable/dart-async/dart-async-library.html
  API-Dokumentation für `Future`, `Stream`, `StreamController`, `Completer`, `Timer` und mehr.

- **Dart Isolates**
  https://dart.dev/language/isolates
  Offizielle Dokumentation zu Isolates und `Isolate.run()`.

- **Concurrency in Dart**
  https://dart.dev/language/concurrency
  Überblick über Darts Concurrency-Modell (Event Loop, Isolates).

## Vertiefende Artikel

- **The Event Loop and Dart** (Flutter Dokumentation)
  https://dart.dev/articles/event-loop
  Detaillierte Erklärung des Event Loops, der Microtask Queue und der Event Queue.

- **Dart Futures — Code With Andrea**
  https://codewithandrea.com/articles/dart-futures/
  Praxisorientierter Artikel über Futures mit vielen Codebeispielen.

- **Dart Streams — Code With Andrea**
  https://codewithandrea.com/articles/dart-streams/
  Umfassender Artikel zu Streams, StreamController und async-Generatoren.

- **Understanding Isolates in Flutter**
  https://docs.flutter.dev/perf/isolates
  Wie Isolates in Flutter verwendet werden und wann sie sinnvoll sind.

## Tutorials und Videos

- **Async/Await in Dart — Fireship**
  https://www.youtube.com/watch?v=SmTCmDMi4BY
  Kompakte Erklärung von async/await in unter 10 Minuten.

- **Flutter Streams Explained — Reso Coder**
  https://www.youtube.com/watch?v=nQBpOIHE4eE
  Detaillierte Erklärung von Streams mit Flutter-bezogenen Beispielen.

- **Dart Isolates & Multithreading (Flutter in Focus)**
  https://www.youtube.com/watch?v=vl_AaCgudcY
  Offizielle Google-Erklärung zu Isolates.

- **The Boring Flutter Show — Async Programming**
  https://www.youtube.com/playlist?list=PLOU2XLYxmsIK0r_D-zWcmJ1plIcDNnRkK
  Reale Anwendungen von asynchroner Programmierung in Flutter.

## Interaktive Übungen

- **DartPad**
  https://dartpad.dev
  Async-Code direkt im Browser testen. Beachte: `dart:io` steht in DartPad nicht zur Verfügung, aber Futures und Streams funktionieren.

- **Async/Await Codelab**
  https://dart.dev/codelabs/async-await
  Interaktive Übungen zu Futures und async/await.

## Vergleichs-Ressourcen

- **Dart vs JavaScript Async**
  | Feature | Dart | JavaScript |
  |---------|------|-----------|
  | Einzelwert | `Future<T>` | `Promise<T>` |
  | Wertfolge | `Stream<T>` | `AsyncIterable<T>` / RxJS Observable |
  | Dann-Verkettung | `.then()` | `.then()` |
  | Fehler fangen | `.catchError()` | `.catch()` |
  | Abschluss | `.whenComplete()` | `.finally()` |
  | Generator (sync) | `sync*` / `yield` | `function*` / `yield` |
  | Generator (async) | `async*` / `yield` | `async function*` / `yield` |

- **Dart vs Python Async**
  | Feature | Dart | Python |
  |---------|------|--------|
  | Event Loop | Automatisch | Muss mit `asyncio.run()` gestartet werden |
  | Future/Coroutine | `Future<T>` | `Coroutine` / `asyncio.Future` |
  | Stream | `Stream<T>` | `AsyncGenerator` / `asyncio.Queue` |
  | Parallel | `Future.wait()` | `asyncio.gather()` |
  | Heavy Compute | `Isolate.run()` | `multiprocessing` |

## Weiterführende Themen

- **Stream Transformers**
  https://api.dart.dev/stable/dart-async/StreamTransformer-class.html
  Für fortgeschrittene Stream-Transformationen.

- **RxDart (Reactive Extensions für Dart)**
  https://pub.dev/packages/rxdart
  Erweitert Darts Streams um Operatoren aus der Reactive-Programming-Welt (ähnlich RxJS).

- **Dart Zone API**
  https://api.dart.dev/stable/dart-async/Zone-class.html
  Fortgeschrittenes Konzept für Fehlerbehandlung und asynchrone Kontexte.
