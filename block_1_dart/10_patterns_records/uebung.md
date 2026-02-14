# Übung 1.10: Pattern Matching & Records

---

## Aufgabe 1: Records (15 Min.)

```dart
void main() {
  // TODO: Implementiere minMax
  var (min, max) = minMax([3, 1, 4, 1, 5, 9, 2, 6]);
  print('Min: $min, Max: $max');

  // TODO: Implementiere parseKoordinate
  var (x, y) = parseKoordinate('12.5,7.3');
  print('X: $x, Y: $y');

  // TODO: Implementiere erstellePerson
  var person = erstellePerson('Max Mustermann', 30);
  print('${person.vorname} ${person.nachname}, ${person.alter}');
}

// (int, int) minMax(List<int>)
// (double, double) parseKoordinate(String) — Format: "x,y"
// ({String vorname, String nachname, int alter}) erstellePerson(String name, int alter)
```

---

## Aufgabe 2: Destructuring (15 Min.)

```dart
void main() {
  var daten = {
    'benutzer': {
      'name': 'Max',
      'adresse': {
        'stadt': 'Berlin',
        'plz': '10115',
      },
    },
    'bestellungen': [
      {'id': 1, 'betrag': 99.99},
      {'id': 2, 'betrag': 149.99},
    ],
  };

  // TODO: Extrahiere mit Destructuring:
  // - Benutzername
  // - Stadt
  // - Erste Bestellungs-ID
  // - Anzahl Bestellungen
}
```

---

## Aufgabe 3: Pattern Matching (20 Min.)

```dart
void main() {
  var eingaben = [
    'exit',
    'help',
    'add 5 3',
    'mul 4 7',
    'div 10 2',
    'div 10 0',
    'unknown',
  ];

  for (var eingabe in eingaben) {
    print('> $eingabe');
    print(verarbeiteBefehl(eingabe));
    print('');
  }
}

// TODO: Implementiere verarbeiteBefehl(String eingabe) -> String
// - 'exit' -> 'Programm beendet'
// - 'help' -> 'Befehle: exit, help, add x y, mul x y, div x y'
// - 'add x y' -> Summe
// - 'mul x y' -> Produkt
// - 'div x y' -> Quotient (Fehler bei y=0)
// - sonst -> 'Unbekannter Befehl'
//
// Hint: Verwende switch mit List-Patterns für split(' ')
```

---

## Aufgabe 4: Sealed Classes (20 Min.)

```dart
void main() {
  List<JsonWert> json = [
    JsonString('Hallo'),
    JsonNumber(42),
    JsonBool(true),
    JsonNull(),
    JsonArray([JsonNumber(1), JsonNumber(2)]),
    JsonObject({'name': JsonString('Max')}),
  ];

  for (var wert in json) {
    print(zuDartWert(wert));
  }
}

// TODO: Implementiere:
// - sealed class JsonWert
// - JsonString, JsonNumber, JsonBool, JsonNull, JsonArray, JsonObject
// - dynamic zuDartWert(JsonWert) mit exhaustive switch
```

---

## Bonusaufgabe: Expression Parser

```dart
void main() {
  var ausdrücke = [
    Zahl(5),
    Addition(Zahl(3), Zahl(4)),
    Multiplikation(Addition(Zahl(2), Zahl(3)), Zahl(4)),
    Division(Zahl(10), Zahl(2)),
    Division(Zahl(10), Zahl(0)),
  ];

  for (var expr in ausdrücke) {
    print('${formatiere(expr)} = ${auswerten(expr)}');
  }
}

// TODO: Implementiere:
// - sealed class Ausdruck
// - Zahl, Addition, Subtraktion, Multiplikation, Division
// - double? auswerten(Ausdruck)
// - String formatiere(Ausdruck)
```
