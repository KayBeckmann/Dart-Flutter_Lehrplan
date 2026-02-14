# Lösung 1.7: Streams

---

## Aufgabe 1

```dart
Stream<int> countdown(int von) async* {
  for (var i = von; i >= 0; i--) {
    yield i;
    if (i > 0) await Future.delayed(Duration(seconds: 1));
  }
}
```

---

## Aufgabe 2

```dart
void main() async {
  var ereignisse = Stream.fromIterable([
    {'typ': 'klick', 'x': 100, 'y': 200},
    {'typ': 'move', 'x': 110, 'y': 200},
    {'typ': 'klick', 'x': 150, 'y': 250},
    {'typ': 'move', 'x': 160, 'y': 260},
    {'typ': 'klick', 'x': 200, 'y': 300},
  ]);

  await for (var e in ereignisse.where((e) => e['typ'] == 'klick')) {
    print('(${e['x']}, ${e['y']})');
  }
}
```

---

## Aufgabe 3

```dart
import 'dart:async';

class ChatRoom {
  final _controller = StreamController<Map<String, String>>.broadcast();

  Stream<Map<String, String>> get nachrichten => _controller.stream;

  void sende(String von, String text) {
    _controller.add({'von': von, 'text': text});
  }

  void schließe() => _controller.close();
}
```

---

## Bonusaufgabe

```dart
extension StreamDebounce<T> on Stream<T> {
  Stream<T> debounce(Duration dauer) async* {
    Timer? timer;
    T? letzterWert;
    var hatWert = false;
    var completer = Completer<void>();

    listen(
      (wert) {
        letzterWert = wert;
        hatWert = true;
        timer?.cancel();
        timer = Timer(dauer, () => completer.complete());
      },
      onDone: () {
        timer?.cancel();
        completer.complete();
      },
    );

    await completer.future;
    if (hatWert) yield letzterWert as T;
  }
}
```
