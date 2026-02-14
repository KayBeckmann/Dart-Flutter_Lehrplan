# Übung 1.2: Funktionen & Kontrollstrukturen

> **Dauer:** ca. 60 Minuten

---

## Aufgabe 1: Funktionsparameter (15 Min.)

Implementiere eine Funktion `bestelleKaffee` mit verschiedenen Parametertypen:

```dart
void main() {
  // Alle diese Aufrufe sollten funktionieren:
  bestelleKaffee('Espresso');
  bestelleKaffee('Cappuccino', größe: 'groß');
  bestelleKaffee('Latte', größe: 'medium', extras: ['Vanille', 'Karamell']);
  bestelleKaffee('Americano', temperatur: 70);
}

// TODO: Implementiere bestelleKaffee
// - sorte: required (positionell)
// - größe: optional (named), Standard: 'klein'
// - temperatur: optional (named), Standard: 85
// - extras: optional (named), Standard: leere Liste

// Erwartete Ausgabe:
// Bestellung: klein Espresso (85°C)
// Bestellung: groß Cappuccino (85°C)
// Bestellung: medium Latte (85°C) mit Vanille, Karamell
// Bestellung: klein Americano (70°C)
```

---

## Aufgabe 2: Higher-Order Functions (15 Min.)

Erstelle einen einfachen Taschenrechner mit Higher-Order Functions:

```dart
void main() {
  // TODO: Implementiere die Funktionen

  var addieren = operation('+');
  var subtrahieren = operation('-');
  var multiplizieren = operation('*');
  var dividieren = operation('/');

  print(addieren(10, 5));       // 15
  print(subtrahieren(10, 5));   // 5
  print(multiplizieren(10, 5)); // 50
  print(dividieren(10, 5));     // 2

  // Bonus: berechne sollte einen Operator-String akzeptieren
  print(berechne(10, 5, '+'));  // 15
  print(berechne(10, 5, '%'));  // 0 (Modulo)
}

// TODO: Definiere einen Typedef für Berechnungsfunktionen
// typedef Berechnung = ...

// TODO: Implementiere operation(String op) die eine Berechnung zurückgibt
// Hint: Verwende switch Expression

// TODO: Implementiere berechne(num a, num b, String op)
```

---

## Aufgabe 3: Kontrollstrukturen (15 Min.)

Implementiere ein Textadventure-Fragment mit verschiedenen Kontrollstrukturen:

```dart
void main() {
  spiele();
}

void spiele() {
  var spieler = {
    'name': 'Held',
    'leben': 100,
    'gold': 50,
    'inventar': ['Schwert', 'Schild'],
  };

  var ereignisse = [
    {'typ': 'monster', 'name': 'Goblin', 'schaden': 20, 'beute': 30},
    {'typ': 'truhe', 'gold': 100},
    {'typ': 'falle', 'schaden': 15},
    {'typ': 'händler', 'item': 'Heiltrank', 'preis': 40},
    {'typ': 'monster', 'name': 'Drache', 'schaden': 50, 'beute': 200},
  ];

  // TODO: Iteriere über ereignisse mit for-in
  // Für jedes Ereignis:
  // - 'monster': Ziehe schaden von leben ab, addiere beute zu gold
  //              Ausgabe: "Kampf gegen [name]! -[schaden] Leben, +[beute] Gold"
  // - 'truhe': Addiere gold
  //            Ausgabe: "Truhe gefunden! +[gold] Gold"
  // - 'falle': Ziehe schaden ab
  //            Ausgabe: "In Falle getappt! -[schaden] Leben"
  // - 'händler': Wenn genug Gold, kaufe Item (ziehe preis ab, füge item zu inventar)
  //              Ausgabe: "Gekauft: [item]" oder "Nicht genug Gold für [item]"

  // Wenn Leben <= 0, breche die Schleife ab und gib "Game Over" aus
  // Sonst gib am Ende den Spielerstand aus
}
```

---

## Aufgabe 4: Switch Expressions (10 Min.)

Verwende Dart 3 Switch Expressions für einen Notenrechner:

```dart
void main() {
  var punkte = [95, 82, 67, 54, 41, 38, 100, 0];

  for (var p in punkte) {
    var note = berechneNote(p);
    var beschreibung = beschreibeNote(note);
    print('$p Punkte = Note $note ($beschreibung)');
  }
}

// TODO: Implementiere berechneNote(int punkte) -> int
// 90-100: 1, 75-89: 2, 60-74: 3, 45-59: 4, 30-44: 5, <30: 6
// Verwende switch Expression mit Patterns

// TODO: Implementiere beschreibeNote(int note) -> String
// 1: "sehr gut", 2: "gut", 3: "befriedigend",
// 4: "ausreichend", 5: "mangelhaft", 6: "ungenügend"
// Verwende switch Expression
```

---

## Aufgabe 5: Fehlerbehandlung (10 Min.)

Implementiere eine sichere Division mit Fehlerbehandlung:

```dart
void main() {
  print(sicheresDividieren(10, 2));   // 5.0
  print(sicheresDividieren(10, 0));   // Fehler: Division durch Null
  print(sicheresDividieren(10, -1));  // Fehler: Divisor darf nicht negativ sein

  // Mit benutzerdefinierter Exception
  try {
    var ergebnis = dividiereStrikt(10, 0);
    print(ergebnis);
  } on DivisionException catch (e) {
    print('Fehler: ${e.message}');
  }
}

// TODO: Implementiere sicheresDividieren(int a, int b) -> String
// - Bei b == 0: Gib Fehlermeldung zurück (kein throw)
// - Bei b < 0: Gib Fehlermeldung zurück
// - Sonst: Gib das Ergebnis als String zurück

// TODO: Definiere eine eigene Exception-Klasse DivisionException
// - Hat ein Feld 'message'
// - Hat einen Konstruktor mit required message

// TODO: Implementiere dividiereStrikt(int a, int b) -> double
// - Wirft DivisionException bei b == 0 oder b < 0
// - Gibt sonst das Ergebnis zurück
```

---

## Bonusaufgabe: FizzBuzz funktional

Implementiere FizzBuzz auf funktionale Weise:

```dart
void main() {
  // FizzBuzz für 1-20 mit funktionalem Ansatz
  // Verwende: List.generate, map, switch expression

  // Regeln:
  // - Durch 3 und 5 teilbar: "FizzBuzz"
  // - Durch 3 teilbar: "Fizz"
  // - Durch 5 teilbar: "Buzz"
  // - Sonst: die Zahl

  // TODO: Implementiere mit einer einzigen Kette von Methodenaufrufen
  // List.generate(20, ...).map(...).forEach(print);
}
```
