# Lösung 1.10: Pattern Matching & Records

---

## Aufgabe 1

```dart
(int, int) minMax(List<int> zahlen) {
  if (zahlen.isEmpty) throw ArgumentError('Liste ist leer');
  var min = zahlen[0];
  var max = zahlen[0];
  for (var z in zahlen) {
    if (z < min) min = z;
    if (z > max) max = z;
  }
  return (min, max);
}

(double, double) parseKoordinate(String s) {
  var teile = s.split(',');
  return (double.parse(teile[0]), double.parse(teile[1]));
}

({String vorname, String nachname, int alter}) erstellePerson(String name, int alter) {
  var teile = name.split(' ');
  return (vorname: teile[0], nachname: teile.sublist(1).join(' '), alter: alter);
}
```

---

## Aufgabe 2

```dart
void main() {
  var daten = {...};  // wie oben

  // Nested Destructuring
  if (daten case {
    'benutzer': {'name': String name, 'adresse': {'stadt': String stadt}},
    'bestellungen': [{'id': int ersteId}, ...var rest],
  }) {
    print('Name: $name');
    print('Stadt: $stadt');
    print('Erste Bestellungs-ID: $ersteId');
    print('Anzahl Bestellungen: ${rest.length + 1}');
  }
}
```

---

## Aufgabe 3

```dart
String verarbeiteBefehl(String eingabe) {
  var teile = eingabe.split(' ');

  return switch (teile) {
    ['exit'] => 'Programm beendet',
    ['help'] => 'Befehle: exit, help, add x y, mul x y, div x y',
    ['add', var a, var b] => 'Ergebnis: ${int.parse(a) + int.parse(b)}',
    ['mul', var a, var b] => 'Ergebnis: ${int.parse(a) * int.parse(b)}',
    ['div', var a, '0'] => 'Fehler: Division durch Null',
    ['div', var a, var b] => 'Ergebnis: ${int.parse(a) / int.parse(b)}',
    _ => 'Unbekannter Befehl: $eingabe',
  };
}
```

---

## Aufgabe 4

```dart
sealed class JsonWert {}

class JsonString extends JsonWert {
  final String wert;
  JsonString(this.wert);
}

class JsonNumber extends JsonWert {
  final num wert;
  JsonNumber(this.wert);
}

class JsonBool extends JsonWert {
  final bool wert;
  JsonBool(this.wert);
}

class JsonNull extends JsonWert {}

class JsonArray extends JsonWert {
  final List<JsonWert> elemente;
  JsonArray(this.elemente);
}

class JsonObject extends JsonWert {
  final Map<String, JsonWert> felder;
  JsonObject(this.felder);
}

dynamic zuDartWert(JsonWert json) => switch (json) {
  JsonString(:var wert) => wert,
  JsonNumber(:var wert) => wert,
  JsonBool(:var wert) => wert,
  JsonNull() => null,
  JsonArray(:var elemente) => elemente.map(zuDartWert).toList(),
  JsonObject(:var felder) => felder.map((k, v) => MapEntry(k, zuDartWert(v))),
};
```

---

## Bonusaufgabe

```dart
sealed class Ausdruck {}

class Zahl extends Ausdruck {
  final double wert;
  Zahl(num wert) : wert = wert.toDouble();
}

class Addition extends Ausdruck {
  final Ausdruck links, rechts;
  Addition(this.links, this.rechts);
}

class Subtraktion extends Ausdruck {
  final Ausdruck links, rechts;
  Subtraktion(this.links, this.rechts);
}

class Multiplikation extends Ausdruck {
  final Ausdruck links, rechts;
  Multiplikation(this.links, this.rechts);
}

class Division extends Ausdruck {
  final Ausdruck links, rechts;
  Division(this.links, this.rechts);
}

double? auswerten(Ausdruck expr) => switch (expr) {
  Zahl(:var wert) => wert,
  Addition(:var links, :var rechts) =>
    (auswerten(links) ?? 0) + (auswerten(rechts) ?? 0),
  Subtraktion(:var links, :var rechts) =>
    (auswerten(links) ?? 0) - (auswerten(rechts) ?? 0),
  Multiplikation(:var links, :var rechts) =>
    (auswerten(links) ?? 0) * (auswerten(rechts) ?? 0),
  Division(:var links, :var rechts) =>
    auswerten(rechts) == 0 ? null : (auswerten(links) ?? 0) / auswerten(rechts)!,
};

String formatiere(Ausdruck expr) => switch (expr) {
  Zahl(:var wert) => wert.toString(),
  Addition(:var links, :var rechts) =>
    '(${formatiere(links)} + ${formatiere(rechts)})',
  Subtraktion(:var links, :var rechts) =>
    '(${formatiere(links)} - ${formatiere(rechts)})',
  Multiplikation(:var links, :var rechts) =>
    '(${formatiere(links)} * ${formatiere(rechts)})',
  Division(:var links, :var rechts) =>
    '(${formatiere(links)} / ${formatiere(rechts)})',
};
```
