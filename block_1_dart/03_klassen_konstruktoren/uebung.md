# Übung 1.3: Klassen & Konstruktoren

> **Dauer:** ca. 60 Minuten

---

## Aufgabe 1: Grundlegende Klasse (15 Min.)

Erstelle eine `Person`-Klasse mit verschiedenen Konstruktoren:

```dart
void main() {
  // Diese Aufrufe sollten funktionieren:
  var p1 = Person('Max', 'Mustermann', 30);
  var p2 = Person.nurVorname('Anna');
  var p3 = Person.ausMap({'vorname': 'Tom', 'nachname': 'Schmidt', 'alter': 25});

  print(p1.vollerName);  // Max Mustermann
  print(p1.istErwachsen);  // true
  print(p2);  // Person: Anna (Alter unbekannt)
  print(p3);  // Person: Tom Schmidt, 25 Jahre
}

// TODO: Implementiere die Person-Klasse
// - Felder: vorname, nachname (beide final), alter (nullable)
// - Hauptkonstruktor mit this.vorname, this.nachname, this.alter
// - Benannter Konstruktor: Person.nurVorname(String vorname)
// - Benannter Konstruktor: Person.ausMap(Map<String, dynamic> map)
// - Getter: vollerName, istErwachsen
// - toString() überschreiben
```

---

## Aufgabe 2: Factory & Cache (15 Min.)

Implementiere eine `Datenbank`-Klasse mit Singleton-Pattern:

```dart
void main() {
  var db1 = Datenbank('produktions_db');
  var db2 = Datenbank('produktions_db');
  var db3 = Datenbank('test_db');

  print(identical(db1, db2));  // true (gleicher Name = gleiche Instanz)
  print(identical(db1, db3));  // false (unterschiedliche Namen)

  db1.verbinde();
  print(db1.istVerbunden);  // true
  print(db2.istVerbunden);  // true (selbe Instanz!)

  print(Datenbank.alleInstanzen);  // ['produktions_db', 'test_db']
}

// TODO: Implementiere die Datenbank-Klasse
// - Privater Konstruktor
// - Factory-Konstruktor mit Cache
// - Felder: name (final), _verbunden (privat)
// - Methode: verbinde()
// - Getter: istVerbunden
// - Statischer Getter: alleInstanzen (Liste aller gecachten Namen)
```

---

## Aufgabe 3: Const-Konstruktor (10 Min.)

Erstelle eine immutable `Vektor2D`-Klasse:

```dart
void main() {
  const v1 = Vektor2D(3, 4);
  const v2 = Vektor2D(3, 4);
  const ursprung = Vektor2D.null_();

  print(identical(v1, v2));  // true (const-Objekte werden dedupliziert)
  print(v1.länge);           // 5.0
  print(v1 + Vektor2D(1, 1)); // Vektor2D(4, 5)
  print(v1 * 2);             // Vektor2D(6, 8)
  print(ursprung);           // Vektor2D(0, 0)
}

// TODO: Implementiere die Vektor2D-Klasse
// - Const-Konstruktor
// - Benannter Konstruktor: Vektor2D.null_() für (0, 0)
// - Getter: länge (Betrag des Vektors: sqrt(x² + y²))
// - Operator +, *, - überladen
// - toString() überschreiben

// Hinweis: import 'dart:math' für sqrt()
```

---

## Aufgabe 4: Getters, Setters & Validierung (15 Min.)

Erstelle eine `Temperatur`-Klasse mit Umrechnung:

```dart
void main() {
  var t = Temperatur.celsius(25);

  print(t.celsius);     // 25.0
  print(t.fahrenheit);  // 77.0
  print(t.kelvin);      // 298.15

  t.fahrenheit = 32;
  print(t.celsius);     // 0.0

  t.kelvin = 0;
  print(t.celsius);     // -273.15

  // Das sollte einen Fehler werfen:
  try {
    t.kelvin = -10;  // Unter absolutem Nullpunkt!
  } catch (e) {
    print('Fehler: $e');
  }
}

// TODO: Implementiere die Temperatur-Klasse
// - Intern wird die Temperatur in Kelvin gespeichert (_kelvin)
// - Getter und Setter für: celsius, fahrenheit, kelvin
// - Setter sollten bei ungültigen Werten (< 0 Kelvin) eine Exception werfen
// - Benannte Konstruktoren: Temperatur.celsius(), .fahrenheit(), .kelvin()
//
// Formeln:
// K = C + 273.15
// F = C * 9/5 + 32
```

---

## Aufgabe 5: Cascade Notation (10 Min.)

Refaktoriere den folgenden Code mit Cascade Notation:

```dart
// VORHER (ohne Cascade):
void main() {
  var builder = StringBuilder();
  builder.schreibeZeile('Überschrift');
  builder.schreibeZeile('============');
  builder.schreibeZeile('');
  builder.schreibe('Absatz 1: ');
  builder.schreibeZeile('Dies ist ein Text.');
  builder.schreibeZeile('');
  builder.schreibeZeile('Ende.');
  print(builder.build());
}

class StringBuilder {
  final _buffer = StringBuffer();

  void schreibe(String text) => _buffer.write(text);
  void schreibeZeile(String text) => _buffer.writeln(text);
  String build() => _buffer.toString();
}

// TODO: Schreibe main() mit Cascade Notation um
// Der StringBuilder-Code bleibt gleich
```

---

## Bonusaufgabe: Builder-Pattern

Implementiere einen `EmailBuilder` mit dem Builder-Pattern:

```dart
void main() {
  var email = EmailBuilder()
    .von('sender@mail.de')
    .an('empfänger@mail.de')
    .cc(['kopie1@mail.de', 'kopie2@mail.de'])
    .betreff('Wichtige Nachricht')
    .text('Hallo,\n\ndies ist der Inhalt.\n\nGruß')
    .build();

  print(email);
  // Von: sender@mail.de
  // An: empfänger@mail.de
  // CC: kopie1@mail.de, kopie2@mail.de
  // Betreff: Wichtige Nachricht
  // ---
  // Hallo,
  //
  // dies ist der Inhalt.
  //
  // Gruß
}

// TODO: Implementiere Email und EmailBuilder
// EmailBuilder-Methoden geben 'this' zurück für Method Chaining
```
