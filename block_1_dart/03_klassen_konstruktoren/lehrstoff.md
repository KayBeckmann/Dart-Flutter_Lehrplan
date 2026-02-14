# Einheit 1.3: Klassen & Konstruktoren

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1, 1.2

---

## 3.1 Klassen und Objekte

Dart ist eine vollständig objektorientierte Sprache — **alles ist ein Objekt**, sogar Zahlen und Funktionen.

```dart
class Punkt {
  // Instanzvariablen (Felder)
  double x;
  double y;

  // Konstruktor (ausführlich)
  Punkt(double x, double y) {
    this.x = x;
    this.y = y;
  }
}

void main() {
  // Objekt erstellen — 'new' ist optional seit Dart 2
  var p = Punkt(3.0, 4.0);
  print('${p.x}, ${p.y}');  // 3.0, 4.0
}
```

**Vergleich:**
- **C++:** Ähnlich, aber keine Header-Dateien nötig, kein manuelles Speichermanagement.
- **Python:** Kein `self`-Parameter nötig, Felder werden direkt in der Klasse deklariert.
- **JS:** Wie ES6-Klassen, aber mit echtem Typsystem.

---

## 3.2 Shorthand-Konstruktor mit `this.param`

Die häufigste und idiomatischste Form in Dart:

```dart
class Punkt {
  final double x;
  final double y;

  // this.x und this.y weisen die Parameter direkt den Feldern zu
  Punkt(this.x, this.y);
}

// Das ist äquivalent zu:
class PunktLang {
  final double x;
  final double y;

  PunktLang(double x, double y)
      : this.x = x,
        this.y = y;
}
```

---

## 3.3 Benannte Konstruktoren

Dart erlaubt mehrere Konstruktoren mit unterschiedlichen Namen:

```dart
class Punkt {
  final double x;
  final double y;

  Punkt(this.x, this.y);

  // Benannter Konstruktor — erstellt einen Punkt auf der X-Achse
  Punkt.aufXAchse(double x) : this(x, 0);

  // Benannter Konstruktor — Ursprung
  Punkt.ursprung() : this(0, 0);

  // Benannter Konstruktor — aus Map (z.B. JSON)
  Punkt.ausMap(Map<String, double> map)
      : x = map['x'] ?? 0,
        y = map['y'] ?? 0;

  @override
  String toString() => 'Punkt($x, $y)';
}

void main() {
  var p1 = Punkt(3, 4);
  var p2 = Punkt.aufXAchse(5);     // Punkt(5, 0)
  var p3 = Punkt.ursprung();        // Punkt(0, 0)
  var p4 = Punkt.ausMap({'x': 1, 'y': 2});  // Punkt(1, 2)
}
```

---

## 3.4 Initialisierungsliste

Code, der **vor** dem Konstruktor-Body ausgeführt wird. Wichtig für `final`-Felder:

```dart
class Rechteck {
  final double breite;
  final double höhe;
  final double fläche;

  // Initialisierungsliste — berechnet fläche vor dem Body
  Rechteck(this.breite, this.höhe)
      : fläche = breite * höhe,
        assert(breite > 0, 'Breite muss positiv sein'),
        assert(höhe > 0, 'Höhe muss positiv sein');
}
```

---

## 3.5 Factory-Konstruktor

Ein `factory`-Konstruktor muss nicht zwingend eine neue Instanz erstellen:

```dart
class Logger {
  final String name;

  // Cache für bereits erstellte Logger
  static final Map<String, Logger> _cache = {};

  // Privater Konstruktor (beginnt mit _)
  Logger._intern(this.name);

  // Factory — gibt gecachte Instanz zurück oder erstellt neue
  factory Logger(String name) {
    return _cache.putIfAbsent(name, () => Logger._intern(name));
  }
}

void main() {
  var a = Logger('UI');
  var b = Logger('UI');
  print(identical(a, b));  // true — selbe Instanz aus dem Cache!
}
```

---

## 3.6 Const-Konstruktor

Erzeugt kompilierzeitkonstante Objekte — wichtig in Flutter für Performance:

```dart
class Farbe {
  final int rot;
  final int grün;
  final int blau;

  // Alle Felder müssen final sein für einen const-Konstruktor
  const Farbe(this.rot, this.grün, this.blau);

  // Vordefinierte Konstanten
  static const Farbe weiß = Farbe(255, 255, 255);
  static const Farbe schwarz = Farbe(0, 0, 0);
}

void main() {
  // Zwei const-Objekte mit gleichen Werten sind identisch
  const a = Farbe(255, 0, 0);
  const b = Farbe(255, 0, 0);
  print(identical(a, b));  // true — nur EINE Instanz im Speicher!
}
```

---

## 3.7 Getters und Setters

Dart hat eingebaute Unterstützung für berechnete Properties:

```dart
class Kreis {
  double radius;

  Kreis(this.radius);

  // Getter — wird wie ein Feld zugegriffen: kreis.fläche
  double get fläche => 3.14159 * radius * radius;
  double get umfang => 2 * 3.14159 * radius;

  // Setter — mit Validierung
  set durchmesser(double d) {
    assert(d > 0, 'Durchmesser muss positiv sein');
    radius = d / 2;
  }

  double get durchmesser => radius * 2;
}

void main() {
  var k = Kreis(5);
  print(k.fläche);         // 78.53975
  print(k.umfang);         // 31.4159

  k.durchmesser = 20;      // Setter-Aufruf
  print(k.radius);         // 10.0
}
```

---

## 3.8 Sichtbarkeit / Private Member

Dart verwendet **keine Schlüsselwörter** wie `public`, `private`. Stattdessen:

```dart
class Beispiel {
  String öffentlich = 'sichtbar';       // Öffentlich (Standard)
  String _privat = 'nur in Library';    // Privat auf Library-Ebene (Unterstrich)
}
```

**Wichtig:** `_` macht ein Mitglied privat auf **Library-Ebene** (Datei-Ebene), nicht auf Klassen-Ebene.

---

## 3.9 Static Members

```dart
class Zähler {
  // Statische Variable — gehört zur Klasse, nicht zur Instanz
  static int _gesamtAnzahl = 0;

  final int id;
  final String name;

  Zähler(this.name) : id = ++_gesamtAnzahl;

  // Statische Methode
  static int get gesamtAnzahl => _gesamtAnzahl;

  @override
  String toString() => 'Zähler(id: $id, name: $name)';
}

void main() {
  var a = Zähler('Alpha');
  var b = Zähler('Beta');
  print('Gesamt: ${Zähler.gesamtAnzahl}');  // Gesamt: 2
}
```

---

## 3.10 Cascade Notation (`..`)

Mehrere Operationen auf demselben Objekt hintereinander:

```dart
class Anfrage {
  String url = '';
  String methode = 'GET';
  Map<String, String> header = {};
  String? body;

  void sende() => print('$methode $url');
}

void main() {
  // MIT Cascade — elegant und kompakt
  var req = Anfrage()
    ..url = 'https://api.example.com/daten'
    ..methode = 'POST'
    ..header['Content-Type'] = 'application/json'
    ..body = '{"key": "value"}'
    ..sende();
}
```

---

## 3.11 Zusammenfassendes Beispiel

```dart
class Bankkonto {
  final String inhaber;
  final String _kontonummer;
  double _saldo;

  static int _kontoZähler = 0;

  // Hauptkonstruktor mit Initialisierungsliste
  Bankkonto(this.inhaber, {double startguthaben = 0})
      : _kontonummer = 'DE${++_kontoZähler}'.padLeft(10, '0'),
        _saldo = startguthaben,
        assert(startguthaben >= 0);

  // Benannter Konstruktor
  Bankkonto.ohneGuthaben(String inhaber) : this(inhaber, startguthaben: 0);

  // Getter
  String get kontonummer => _kontonummer;
  double get saldo => _saldo;

  // Methoden
  void einzahlen(double betrag) {
    assert(betrag > 0);
    _saldo += betrag;
  }

  bool abheben(double betrag) {
    if (betrag > _saldo) return false;
    _saldo -= betrag;
    return true;
  }

  @override
  String toString() => 'Konto $_kontonummer ($inhaber): ${_saldo.toStringAsFixed(2)} EUR';
}

void main() {
  var konto = Bankkonto('Max Mustermann', startguthaben: 1000)
    ..einzahlen(500)
    ..abheben(200);

  print(konto);  // Konto DE000000001 (Max Mustermann): 1300.00 EUR
}
```
