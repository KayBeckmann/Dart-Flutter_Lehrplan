# Lösung 1.2: Funktionen & Kontrollstrukturen

---

## Aufgabe 1: Funktionsparameter

```dart
void main() {
  bestelleKaffee('Espresso');
  bestelleKaffee('Cappuccino', größe: 'groß');
  bestelleKaffee('Latte', größe: 'medium', extras: ['Vanille', 'Karamell']);
  bestelleKaffee('Americano', temperatur: 70);
}

void bestelleKaffee(
  String sorte, {
  String größe = 'klein',
  int temperatur = 85,
  List<String> extras = const [],
}) {
  var bestellung = 'Bestellung: $größe $sorte (${temperatur}°C)';

  if (extras.isNotEmpty) {
    bestellung += ' mit ${extras.join(', ')}';
  }

  print(bestellung);
}
```

---

## Aufgabe 2: Higher-Order Functions

```dart
typedef Berechnung = num Function(num, num);

Berechnung operation(String op) {
  return switch (op) {
    '+' => (a, b) => a + b,
    '-' => (a, b) => a - b,
    '*' => (a, b) => a * b,
    '/' => (a, b) => a / b,
    '%' => (a, b) => a % b,
    '^' => (a, b) => _potenz(a, b),
    _ => (a, b) => throw ArgumentError('Unbekannter Operator: $op'),
  };
}

num _potenz(num basis, num exponent) {
  num ergebnis = 1;
  for (var i = 0; i < exponent; i++) {
    ergebnis *= basis;
  }
  return ergebnis;
}

num berechne(num a, num b, String op) {
  var op_func = operation(op);
  return op_func(a, b);
}

void main() {
  var addieren = operation('+');
  var subtrahieren = operation('-');
  var multiplizieren = operation('*');
  var dividieren = operation('/');

  print(addieren(10, 5));       // 15
  print(subtrahieren(10, 5));   // 5
  print(multiplizieren(10, 5)); // 50
  print(dividieren(10, 5));     // 2.0

  print(berechne(10, 5, '+'));  // 15
  print(berechne(10, 5, '%'));  // 0
  print(berechne(2, 8, '^'));   // 256
}
```

---

## Aufgabe 3: Kontrollstrukturen

```dart
void main() {
  spiele();
}

void spiele() {
  var spieler = {
    'name': 'Held',
    'leben': 100,
    'gold': 50,
    'inventar': <String>['Schwert', 'Schild'],
  };

  var ereignisse = [
    {'typ': 'monster', 'name': 'Goblin', 'schaden': 20, 'beute': 30},
    {'typ': 'truhe', 'gold': 100},
    {'typ': 'falle', 'schaden': 15},
    {'typ': 'händler', 'item': 'Heiltrank', 'preis': 40},
    {'typ': 'monster', 'name': 'Drache', 'schaden': 50, 'beute': 200},
  ];

  for (var ereignis in ereignisse) {
    var typ = ereignis['typ'] as String;

    switch (typ) {
      case 'monster':
        var name = ereignis['name'];
        var schaden = ereignis['schaden'] as int;
        var beute = ereignis['beute'] as int;
        spieler['leben'] = (spieler['leben'] as int) - schaden;
        spieler['gold'] = (spieler['gold'] as int) + beute;
        print('Kampf gegen $name! -$schaden Leben, +$beute Gold');

      case 'truhe':
        var gold = ereignis['gold'] as int;
        spieler['gold'] = (spieler['gold'] as int) + gold;
        print('Truhe gefunden! +$gold Gold');

      case 'falle':
        var schaden = ereignis['schaden'] as int;
        spieler['leben'] = (spieler['leben'] as int) - schaden;
        print('In Falle getappt! -$schaden Leben');

      case 'händler':
        var item = ereignis['item'] as String;
        var preis = ereignis['preis'] as int;
        var gold = spieler['gold'] as int;
        if (gold >= preis) {
          spieler['gold'] = gold - preis;
          (spieler['inventar'] as List<String>).add(item);
          print('Gekauft: $item');
        } else {
          print('Nicht genug Gold für $item');
        }
    }

    // Leben prüfen
    if ((spieler['leben'] as int) <= 0) {
      print('\n=== GAME OVER ===');
      return;
    }

    print('  -> Leben: ${spieler['leben']}, Gold: ${spieler['gold']}');
  }

  print('\n=== SIEG! ===');
  print('Endstand: Leben: ${spieler['leben']}, Gold: ${spieler['gold']}');
  print('Inventar: ${(spieler['inventar'] as List).join(', ')}');
}
```

---

## Aufgabe 4: Switch Expressions

```dart
void main() {
  var punkte = [95, 82, 67, 54, 41, 38, 100, 0];

  for (var p in punkte) {
    var note = berechneNote(p);
    var beschreibung = beschreibeNote(note);
    print('$p Punkte = Note $note ($beschreibung)');
  }
}

int berechneNote(int punkte) => switch (punkte) {
  >= 90 => 1,
  >= 75 => 2,
  >= 60 => 3,
  >= 45 => 4,
  >= 30 => 5,
  _ => 6,
};

String beschreibeNote(int note) => switch (note) {
  1 => 'sehr gut',
  2 => 'gut',
  3 => 'befriedigend',
  4 => 'ausreichend',
  5 => 'mangelhaft',
  6 => 'ungenügend',
  _ => 'ungültig',
};
```

**Alternative mit Records:**

```dart
(int, String) bewerteVollständig(int punkte) {
  var note = berechneNote(punkte);
  return (note, beschreibeNote(note));
}

void main() {
  var (note, beschreibung) = bewerteVollständig(85);
  print('Note $note: $beschreibung');
}
```

---

## Aufgabe 5: Fehlerbehandlung

```dart
class DivisionException implements Exception {
  final String message;
  DivisionException({required this.message});

  @override
  String toString() => 'DivisionException: $message';
}

String sicheresDividieren(int a, int b) {
  if (b == 0) {
    return 'Fehler: Division durch Null';
  }
  if (b < 0) {
    return 'Fehler: Divisor darf nicht negativ sein';
  }
  return (a / b).toString();
}

double dividiereStrikt(int a, int b) {
  if (b == 0) {
    throw DivisionException(message: 'Division durch Null');
  }
  if (b < 0) {
    throw DivisionException(message: 'Divisor darf nicht negativ sein');
  }
  return a / b;
}

void main() {
  print(sicheresDividieren(10, 2));   // 5.0
  print(sicheresDividieren(10, 0));   // Fehler: Division durch Null
  print(sicheresDividieren(10, -1));  // Fehler: Divisor darf nicht negativ sein

  try {
    var ergebnis = dividiereStrikt(10, 0);
    print(ergebnis);
  } on DivisionException catch (e) {
    print('Fehler: ${e.message}');
  }

  // Mehrere Tests
  for (var divisor in [2, 0, -1, 5]) {
    try {
      print('10 / $divisor = ${dividiereStrikt(10, divisor)}');
    } on DivisionException catch (e) {
      print('10 / $divisor -> ${e.message}');
    }
  }
}
```

---

## Bonusaufgabe: FizzBuzz funktional

```dart
void main() {
  // Einzeiler-Version
  List.generate(20, (i) => i + 1)
      .map((n) => switch ((n % 3 == 0, n % 5 == 0)) {
            (true, true) => 'FizzBuzz',
            (true, false) => 'Fizz',
            (false, true) => 'Buzz',
            (false, false) => n.toString(),
          })
      .forEach(print);
}
```

**Alternative mit Pattern Matching:**

```dart
void main() {
  for (var i = 1; i <= 20; i++) {
    var result = switch (i) {
      _ when i % 15 == 0 => 'FizzBuzz',
      _ when i % 3 == 0 => 'Fizz',
      _ when i % 5 == 0 => 'Buzz',
      _ => i.toString(),
    };
    print(result);
  }
}
```

**Als Higher-Order Function:**

```dart
String Function(int) fizzBuzzFactory({
  Map<int, String> regeln = const {3: 'Fizz', 5: 'Buzz'},
}) {
  return (int n) {
    var ergebnis = StringBuffer();
    for (var eintrag in regeln.entries) {
      if (n % eintrag.key == 0) {
        ergebnis.write(eintrag.value);
      }
    }
    return ergebnis.isEmpty ? n.toString() : ergebnis.toString();
  };
}

void main() {
  var fizzBuzz = fizzBuzzFactory();
  var fizzBuzzBang = fizzBuzzFactory(regeln: {3: 'Fizz', 5: 'Buzz', 7: 'Bang'});

  for (var i = 1; i <= 21; i++) {
    print('$i: ${fizzBuzzBang(i)}');
  }
}
```
