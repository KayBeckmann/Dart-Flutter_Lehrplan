# Einheit 1.7: Streams

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.6

---

## 7.1 Was sind Streams?

- `Future<T>` = **ein** asynchroner Wert
- `Stream<T>` = **mehrere** asynchrone Werte über die Zeit

```dart
// Stream aus Liste
var stream = Stream.fromIterable([1, 2, 3, 4, 5]);

stream.listen(
  (wert) => print('Wert: $wert'),
  onDone: () => print('Fertig'),
  onError: (e) => print('Fehler: $e'),
);
```

---

## 7.2 Stream-Typen

| Typ | Beschreibung | Beispiel |
|-----|-------------|---------|
| **Single-Subscription** | Nur ein Listener | Datei lesen |
| **Broadcast** | Mehrere Listener | UI-Events |

```dart
// Broadcast Stream
var controller = StreamController<int>.broadcast();
controller.stream.listen((v) => print('A: $v'));
controller.stream.listen((v) => print('B: $v'));
controller.add(1);  // A: 1, B: 1
```

---

## 7.3 StreamController

```dart
import 'dart:async';

var controller = StreamController<String>();

// Stream abonnieren
controller.stream.listen((daten) => print('Empfangen: $daten'));

// Werte einspeisen
controller.add('Hallo');
controller.add('Welt');

// Stream schließen
controller.close();
```

---

## 7.4 async* und yield

```dart
// Stream-Generator
Stream<int> zähle(int bis) async* {
  for (var i = 1; i <= bis; i++) {
    await Future.delayed(Duration(milliseconds: 500));
    yield i;
  }
}

// yield* delegiert an anderen Stream
Stream<int> kombiniereStreams() async* {
  yield* zähle(3);
  yield 0;
  yield* zähle(3);
}

void main() async {
  await for (var zahl in zähle(5)) {
    print(zahl);
  }
}
```

---

## 7.5 Stream-Transformationen

```dart
void main() async {
  var zahlen = Stream.fromIterable([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

  var ergebnis = zahlen
      .where((n) => n.isEven)      // Filtern: 2, 4, 6, 8, 10
      .map((n) => n * n)            // Transformieren: 4, 16, 36, 64, 100
      .take(3);                     // Begrenzen: 4, 16, 36

  await for (var w in ergebnis) {
    print(w);
  }
}
```

---

## 7.6 Zusammenfassendes Beispiel

```dart
import 'dart:async';

class EventBus {
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _controller.stream;

  void emit(String typ, dynamic daten) {
    _controller.add({'typ': typ, 'daten': daten, 'zeit': DateTime.now()});
  }

  Stream<Map<String, dynamic>> on(String typ) {
    return events.where((e) => e['typ'] == typ);
  }

  void dispose() => _controller.close();
}

void main() async {
  var bus = EventBus();

  bus.on('login').listen((e) => print('Login: ${e['daten']}'));
  bus.on('logout').listen((e) => print('Logout: ${e['daten']}'));

  bus.emit('login', 'Max');
  bus.emit('other', 'ignored');
  bus.emit('logout', 'Max');

  await Future.delayed(Duration(milliseconds: 100));
  bus.dispose();
}
```
