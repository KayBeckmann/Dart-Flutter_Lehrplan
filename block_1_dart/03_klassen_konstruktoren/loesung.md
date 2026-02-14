# Lösung 1.3: Klassen & Konstruktoren

---

## Aufgabe 1: Grundlegende Klasse

```dart
class Person {
  final String vorname;
  final String nachname;
  final int? alter;

  // Hauptkonstruktor
  Person(this.vorname, this.nachname, this.alter);

  // Benannte Konstruktoren
  Person.nurVorname(this.vorname)
      : nachname = '',
        alter = null;

  Person.ausMap(Map<String, dynamic> map)
      : vorname = map['vorname'] as String,
        nachname = map['nachname'] as String? ?? '',
        alter = map['alter'] as int?;

  // Getter
  String get vollerName =>
      nachname.isEmpty ? vorname : '$vorname $nachname';

  bool get istErwachsen => (alter ?? 0) >= 18;

  @override
  String toString() {
    var altersInfo = alter != null ? '$alter Jahre' : 'Alter unbekannt';
    return nachname.isEmpty
        ? 'Person: $vorname ($altersInfo)'
        : 'Person: $vollerName, $altersInfo';
  }
}

void main() {
  var p1 = Person('Max', 'Mustermann', 30);
  var p2 = Person.nurVorname('Anna');
  var p3 = Person.ausMap({'vorname': 'Tom', 'nachname': 'Schmidt', 'alter': 25});

  print(p1.vollerName);    // Max Mustermann
  print(p1.istErwachsen);  // true
  print(p2);               // Person: Anna (Alter unbekannt)
  print(p3);               // Person: Tom Schmidt, 25 Jahre
}
```

---

## Aufgabe 2: Factory & Cache

```dart
class Datenbank {
  final String name;
  bool _verbunden = false;

  // Cache für Instanzen
  static final Map<String, Datenbank> _cache = {};

  // Privater Konstruktor
  Datenbank._intern(this.name);

  // Factory-Konstruktor
  factory Datenbank(String name) {
    return _cache.putIfAbsent(name, () => Datenbank._intern(name));
  }

  // Getter
  bool get istVerbunden => _verbunden;

  // Statischer Getter für alle Instanznamen
  static List<String> get alleInstanzen => _cache.keys.toList();

  // Methoden
  void verbinde() {
    _verbunden = true;
    print('Verbunden mit $name');
  }

  void trenne() {
    _verbunden = false;
    print('Getrennt von $name');
  }
}

void main() {
  var db1 = Datenbank('produktions_db');
  var db2 = Datenbank('produktions_db');
  var db3 = Datenbank('test_db');

  print(identical(db1, db2));  // true
  print(identical(db1, db3));  // false

  db1.verbinde();
  print(db1.istVerbunden);  // true
  print(db2.istVerbunden);  // true

  print(Datenbank.alleInstanzen);  // [produktions_db, test_db]
}
```

---

## Aufgabe 3: Const-Konstruktor

```dart
import 'dart:math';

class Vektor2D {
  final double x;
  final double y;

  // Const-Konstruktor
  const Vektor2D(this.x, this.y);

  // Benannter Konstruktor für Nullvektor
  const Vektor2D.null_() : x = 0, y = 0;

  // Getter für die Länge
  double get länge => sqrt(x * x + y * y);

  // Operator-Überladung
  Vektor2D operator +(Vektor2D other) => Vektor2D(x + other.x, y + other.y);
  Vektor2D operator -(Vektor2D other) => Vektor2D(x - other.x, y - other.y);
  Vektor2D operator *(num skalar) => Vektor2D(x * skalar, y * skalar);
  Vektor2D operator -() => Vektor2D(-x, -y);

  @override
  String toString() => 'Vektor2D($x, $y)';

  @override
  bool operator ==(Object other) =>
      other is Vektor2D && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

void main() {
  const v1 = Vektor2D(3, 4);
  const v2 = Vektor2D(3, 4);
  const ursprung = Vektor2D.null_();

  print(identical(v1, v2));     // true
  print(v1.länge);              // 5.0
  print(v1 + Vektor2D(1, 1));   // Vektor2D(4.0, 5.0)
  print(v1 * 2);                // Vektor2D(6.0, 8.0)
  print(ursprung);              // Vektor2D(0, 0)
}
```

---

## Aufgabe 4: Getters, Setters & Validierung

```dart
class Temperatur {
  double _kelvin;

  // Private Konstruktor
  Temperatur._(this._kelvin) {
    _validiere(_kelvin);
  }

  // Benannte Konstruktoren
  Temperatur.kelvin(double k) : this._(k);
  Temperatur.celsius(double c) : this._(c + 273.15);
  Temperatur.fahrenheit(double f) : this._((f - 32) * 5 / 9 + 273.15);

  // Validierung
  void _validiere(double kelvin) {
    if (kelvin < 0) {
      throw ArgumentError('Temperatur kann nicht unter 0 Kelvin liegen');
    }
  }

  // Getter
  double get kelvin => _kelvin;
  double get celsius => _kelvin - 273.15;
  double get fahrenheit => celsius * 9 / 5 + 32;

  // Setter
  set kelvin(double k) {
    _validiere(k);
    _kelvin = k;
  }

  set celsius(double c) {
    kelvin = c + 273.15;
  }

  set fahrenheit(double f) {
    celsius = (f - 32) * 5 / 9;
  }

  @override
  String toString() =>
      '${celsius.toStringAsFixed(2)}°C / ${fahrenheit.toStringAsFixed(2)}°F / ${kelvin.toStringAsFixed(2)}K';
}

void main() {
  var t = Temperatur.celsius(25);

  print(t.celsius);     // 25.0
  print(t.fahrenheit);  // 77.0
  print(t.kelvin);      // 298.15

  t.fahrenheit = 32;
  print(t.celsius);     // 0.0

  t.kelvin = 0;
  print(t.celsius);     // -273.15

  try {
    t.kelvin = -10;
  } catch (e) {
    print('Fehler: $e');
  }
}
```

---

## Aufgabe 5: Cascade Notation

```dart
class StringBuilder {
  final _buffer = StringBuffer();

  void schreibe(String text) => _buffer.write(text);
  void schreibeZeile(String text) => _buffer.writeln(text);
  String build() => _buffer.toString();
}

void main() {
  var text = (StringBuilder()
        ..schreibeZeile('Überschrift')
        ..schreibeZeile('============')
        ..schreibeZeile('')
        ..schreibe('Absatz 1: ')
        ..schreibeZeile('Dies ist ein Text.')
        ..schreibeZeile('')
        ..schreibeZeile('Ende.'))
      .build();

  print(text);
}
```

---

## Bonusaufgabe: Builder-Pattern

```dart
class Email {
  final String von;
  final String an;
  final List<String> cc;
  final String betreff;
  final String text;

  Email._({
    required this.von,
    required this.an,
    required this.cc,
    required this.betreff,
    required this.text,
  });

  @override
  String toString() {
    var buffer = StringBuffer()
      ..writeln('Von: $von')
      ..writeln('An: $an');

    if (cc.isNotEmpty) {
      buffer.writeln('CC: ${cc.join(', ')}');
    }

    buffer
      ..writeln('Betreff: $betreff')
      ..writeln('---')
      ..write(text);

    return buffer.toString();
  }
}

class EmailBuilder {
  String _von = '';
  String _an = '';
  List<String> _cc = [];
  String _betreff = '';
  String _text = '';

  EmailBuilder von(String adresse) {
    _von = adresse;
    return this;
  }

  EmailBuilder an(String adresse) {
    _an = adresse;
    return this;
  }

  EmailBuilder cc(List<String> adressen) {
    _cc = adressen;
    return this;
  }

  EmailBuilder betreff(String betreff) {
    _betreff = betreff;
    return this;
  }

  EmailBuilder text(String text) {
    _text = text;
    return this;
  }

  Email build() {
    if (_von.isEmpty || _an.isEmpty) {
      throw StateError('Von und An müssen gesetzt sein');
    }
    return Email._(
      von: _von,
      an: _an,
      cc: _cc,
      betreff: _betreff,
      text: _text,
    );
  }
}

void main() {
  var email = EmailBuilder()
      .von('sender@mail.de')
      .an('empfänger@mail.de')
      .cc(['kopie1@mail.de', 'kopie2@mail.de'])
      .betreff('Wichtige Nachricht')
      .text('Hallo,\n\ndies ist der Inhalt.\n\nGruß')
      .build();

  print(email);
}
```
