# Übung 1.7: Streams

---

## Aufgabe 1: Stream-Generator (15 Min.)

```dart
void main() async {
  // TODO: Implementiere countdown(int von)
  // - Zählt von 'von' bis 0
  // - 1 Sekunde Pause zwischen Zahlen
  // - yield jede Zahl

  await for (var n in countdown(5)) {
    print(n);
  }
  print('Start!');
}
```

---

## Aufgabe 2: Stream-Transformationen (15 Min.)

```dart
void main() async {
  var ereignisse = Stream.fromIterable([
    {'typ': 'klick', 'x': 100, 'y': 200},
    {'typ': 'move', 'x': 110, 'y': 200},
    {'typ': 'klick', 'x': 150, 'y': 250},
    {'typ': 'move', 'x': 160, 'y': 260},
    {'typ': 'klick', 'x': 200, 'y': 300},
  ]);

  // TODO: Filtere nur 'klick'-Events und extrahiere Koordinaten
  // Erwartete Ausgabe: (100, 200), (150, 250), (200, 300)
}
```

---

## Aufgabe 3: StreamController (20 Min.)

```dart
void main() async {
  var chat = ChatRoom();

  chat.nachrichten.listen((n) => print('[${n['von']}]: ${n['text']}'));

  chat.sende('Max', 'Hallo!');
  chat.sende('Anna', 'Hi Max!');
  chat.sende('Max', 'Wie gehts?');

  await Future.delayed(Duration(milliseconds: 100));
  chat.schließe();
}

// TODO: Implementiere ChatRoom
// - StreamController<Map<String, String>> für Nachrichten
// - Stream<...> get nachrichten
// - void sende(String von, String text)
// - void schließe()
```

---

## Bonusaufgabe: Debounce

```dart
void main() async {
  var eingaben = Stream.fromIterable(['H', 'Ha', 'Hal', 'Hall', 'Hallo']);

  // TODO: Implementiere debounce Extension
  // - Wartet 300ms nach letzter Eingabe
  // - Gibt nur die letzte Eingabe aus

  await for (var e in eingaben.debounce(Duration(milliseconds: 300))) {
    print('Suche: $e');
  }
  // Sollte nur "Hallo" ausgeben
}
```
