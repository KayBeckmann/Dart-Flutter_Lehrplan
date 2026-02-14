# Einheit 1.10: Pattern Matching & Records

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1-1.9 | **Dart 3.0+**

---

## 10.1 Records

Records sind anonyme, immutable Datentypen:

```dart
// Positional Record
var punkt = (3, 4);
print(punkt.$1);  // 3
print(punkt.$2);  // 4

// Named Record
var person = (name: 'Max', alter: 30);
print(person.name);   // Max
print(person.alter);  // 30

// Gemischt
var gemischt = ('Wert', name: 'Max', 42);
print(gemischt.$1);    // Wert
print(gemischt.$2);    // 42
print(gemischt.name);  // Max
```

### Records als Rückgabewert

```dart
(int, int) teileRest(int a, int b) {
  return (a ~/ b, a % b);
}

(String name, int alter) holePerson() {
  return ('Max', 30);
}

void main() {
  var (quotient, rest) = teileRest(10, 3);
  print('$quotient Rest $rest');  // 3 Rest 1

  var (name, alter) = holePerson();
  print('$name ist $alter');
}
```

---

## 10.2 Destructuring

```dart
// List Destructuring
var zahlen = [1, 2, 3, 4, 5];
var [erste, zweite, ...rest] = zahlen;
print(erste);  // 1
print(rest);   // [3, 4, 5]

// Map Destructuring
var map = {'name': 'Max', 'alter': 30};
var {'name': name, 'alter': alter} = map;

// Record Destructuring
var (x, y) = (3, 4);
var (:name, :alter) = (name: 'Max', alter: 30);
```

---

## 10.3 Pattern Matching mit switch

```dart
String beschreibe(Object? obj) {
  return switch (obj) {
    null => 'Nichts',
    int i when i < 0 => 'Negative Zahl: $i',
    int i => 'Zahl: $i',
    String s when s.isEmpty => 'Leerer String',
    String s => 'Text: $s',
    List l when l.isEmpty => 'Leere Liste',
    [var first, ...var rest] => 'Liste mit $first und ${rest.length} weiteren',
    (int x, int y) => 'Punkt ($x, $y)',
    {'typ': 'user', 'name': var name} => 'Benutzer: $name',
    _ => 'Unbekannt: $obj',
  };
}
```

---

## 10.4 Sealed Classes

```dart
sealed class Form {}

class Kreis extends Form {
  final double radius;
  Kreis(this.radius);
}

class Rechteck extends Form {
  final double breite, höhe;
  Rechteck(this.breite, this.höhe);
}

class Dreieck extends Form {
  final double a, b, c;
  Dreieck(this.a, this.b, this.c);
}

double berechneFlaeche(Form form) {
  return switch (form) {
    Kreis(:var radius) => 3.14159 * radius * radius,
    Rechteck(:var breite, :var höhe) => breite * höhe,
    Dreieck(:var a, :var b, :var c) => _heron(a, b, c),
  };
  // Kein default nötig — Compiler weiß, dass alle Fälle abgedeckt sind!
}

double _heron(double a, double b, double c) {
  var s = (a + b + c) / 2;
  return (s * (s - a) * (s - b) * (s - c)).abs();
}
```

---

## 10.5 If-Case

```dart
void main() {
  var daten = {'typ': 'benutzer', 'name': 'Max', 'alter': 30};

  // If-Case statt komplexer Typprüfungen
  if (daten case {'typ': 'benutzer', 'name': String name}) {
    print('Benutzer gefunden: $name');
  }

  var punkt = (3, 4);
  if (punkt case (int x, int y) when x == y) {
    print('Diagonaler Punkt');
  } else if (punkt case (int x, int y)) {
    print('Punkt bei $x, $y');
  }
}
```

---

## 10.6 Zusammenfassendes Beispiel

```dart
sealed class ApiAntwort<T> {}

class Erfolg<T> extends ApiAntwort<T> {
  final T daten;
  final int statusCode;
  Erfolg(this.daten, {this.statusCode = 200});
}

class Fehler<T> extends ApiAntwort<T> {
  final String nachricht;
  final int statusCode;
  Fehler(this.nachricht, {required this.statusCode});
}

class Laden<T> extends ApiAntwort<T> {}

void verarbeite<T>(ApiAntwort<T> antwort) {
  switch (antwort) {
    case Erfolg(:var daten, :var statusCode):
      print('Erfolg ($statusCode): $daten');
    case Fehler(:var nachricht, statusCode: var code) when code >= 500:
      print('Serverfehler: $nachricht');
    case Fehler(:var nachricht, :var statusCode):
      print('Fehler ($statusCode): $nachricht');
    case Laden():
      print('Lädt...');
  }
}

void main() {
  verarbeite(Erfolg({'name': 'Max'}));
  verarbeite(Fehler('Nicht gefunden', statusCode: 404));
  verarbeite(Fehler('Interner Fehler', statusCode: 500));
  verarbeite(Laden<String>());
}
```
