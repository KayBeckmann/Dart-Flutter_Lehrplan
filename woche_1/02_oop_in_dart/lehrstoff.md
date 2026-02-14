# Modul 2: Objektorientierte Programmierung in Dart

## 2.1 Klassen und Objekte

Dart ist eine vollständig objektorientierte Sprache — **alles ist ein Objekt**, sogar Zahlen und Funktionen. Jedes Objekt ist eine Instanz einer Klasse, und alle Klassen (außer `Null`) erben von `Object`.

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
- **C++:** Ähnlich wie C++-Klassen, aber keine Header-Dateien nötig, kein manuelles Speichermanagement.
- **Python:** Kein `self`-Parameter nötig, Felder werden direkt in der Klasse deklariert (nicht in `__init__`).
- **JS:** Wie ES6-Klassen, aber mit echtem Typsystem und keinem Prototypen-Modell im Hintergrund.

---

## 2.2 Konstruktoren

Dart bietet ein reichhaltiges System an Konstruktoren — deutlich vielfältiger als in den meisten anderen Sprachen.

### Shorthand-Konstruktor mit `this.param`

Die häufigste und idiomatischste Form in Dart:

```dart
class Punkt {
  final double x;
  final double y;

  // this.x und this.y weisen die Parameter direkt den Feldern zu
  // Das ist kürzer als die explizite Zuweisung im Body
  Punkt(this.x, this.y);
}

// Vergleich — das ist äquivalent zu:
class PunktLang {
  final double x;
  final double y;

  PunktLang(double x, double y)
      : this.x = x,
        this.y = y;
}
```

**Vergleich zu C++:** Ähnlich wie die Initialisierungsliste (`: x(x), y(y)`), aber noch kompakter.

### Benannte Konstruktoren

Dart erlaubt mehrere Konstruktoren mit unterschiedlichen Namen — in C++ würde man dafür Überladung oder statische Fabrikmethoden verwenden:

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

  print('$p1, $p2, $p3, $p4');
}
```

### Initialisierungsliste

Code, der **vor** dem Konstruktor-Body ausgeführt wird. Besonders wichtig für `final`-Felder:

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

### Factory-Konstruktor

Ein `factory`-Konstruktor muss nicht zwingend eine neue Instanz erstellen — er kann gecachte Objekte zurückgeben oder Subtypen erzeugen:

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

**Vergleich zu Python:** Ähnlich wie `__new__` in Python, aber expliziter und ohne Magie.

### Const-Konstruktor

Erzeugt kompilierzeitkonstante Objekte — besonders wichtig in Flutter für Performance:

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
  // Zwei const-Objekte mit gleichen Werten sind identisch (gleiche Referenz)
  const a = Farbe(255, 0, 0);
  const b = Farbe(255, 0, 0);
  print(identical(a, b));  // true — nur EINE Instanz im Speicher!
}
```

### Redirecting-Konstruktor

Leitet an einen anderen Konstruktor derselben Klasse weiter:

```dart
class Punkt {
  final double x;
  final double y;

  Punkt(this.x, this.y);

  // Redirecting: leitet an den Hauptkonstruktor weiter
  Punkt.aufXAchse(double x) : this(x, 0);
  Punkt.aufYAchse(double y) : this(0, y);
  Punkt.ursprung() : this(0, 0);
}
```

---

## 2.3 Getters und Setters

Dart hat eingebaute Unterstützung für berechnete Properties — ohne explizite `getProperty()`/`setProperty()`-Methoden wie in Java:

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
  print(k.fläche);         // 78.53975 — Getter-Aufruf sieht aus wie Feld-Zugriff
  print(k.umfang);         // 31.4159

  k.durchmesser = 20;      // Setter-Aufruf
  print(k.radius);         // 10.0
}
```

**Vergleich:**
- **C++:** Ersetzt `getX()` / `setX()` durch eine sauberere Syntax.
- **Python:** Ähnlich wie `@property` und `@property.setter`, aber syntaktisch leichter.
- **JS:** Wie ES6 `get` / `set` in Klassen.

---

## 2.4 Vererbung (extends)

```dart
class Fahrzeug {
  final String marke;
  int _kilometerstand = 0;  // Privat (beginnt mit _)

  Fahrzeug(this.marke);

  int get kilometerstand => _kilometerstand;

  void fahre(int km) {
    _kilometerstand += km;
    print('$marke fährt $km km. Stand: $_kilometerstand km');
  }

  @override
  String toString() => '$marke ($runtimeType)';
}

class Auto extends Fahrzeug {
  final int türen;

  // super. übergibt Parameter an den Eltern-Konstruktor
  // Dart 3 erlaubt super-Parameter direkt:
  Auto(super.marke, {this.türen = 4});

  // Methode überschreiben
  @override
  void fahre(int km) {
    print('Auto startet Motor...');
    super.fahre(km);  // Eltern-Methode aufrufen
  }
}

class Elektroauto extends Auto {
  int akkustand;

  Elektroauto(super.marke, {super.türen, this.akkustand = 100});

  @override
  void fahre(int km) {
    if (akkustand <= 0) {
      print('Akku leer! Kann nicht fahren.');
      return;
    }
    super.fahre(km);
    akkustand -= (km * 0.2).round();
    print('Akkustand: $akkustand%');
  }
}

void main() {
  var tesla = Elektroauto('Tesla', türen: 4, akkustand: 80);
  tesla.fahre(100);
  // Auto startet Motor...
  // Tesla fährt 100 km. Stand: 100 km
  // Akkustand: 60%
}
```

**Vergleich zu C++:** Dart hat nur Einfachvererbung (wie Java). Für Mehrfach-Vererbung gibt es Mixins (Abschnitt 2.7). Kein `virtual` nötig — alle Methoden sind standardmäßig überschreibbar.

### Sichtbarkeit / Zugriffsmodifikatoren

Dart verwendet **keine Schlüsselwörter** wie `public`, `private`, `protected`. Stattdessen:

```dart
class Beispiel {
  String öffentlich = 'sichtbar';       // Öffentlich (Standard)
  String _privat = 'nur in Bibliothek'; // Privat auf Library-Ebene (Unterstrich)

  // Es gibt kein "protected" in Dart!
}
```

**Wichtig:** `_` macht ein Mitglied privat auf **Library-Ebene** (Datei-Ebene), nicht auf Klassen-Ebene. Alle Klassen in derselben Datei können auf `_privat` zugreifen.

---

## 2.5 Abstrakte Klassen

```dart
// abstract-Klassen können nicht direkt instanziiert werden
abstract class Form {
  // Abstrakte Methoden (ohne Body) — müssen von Unterklassen implementiert werden
  double berechneFlaeche();
  double berechneUmfang();

  // Konkrete Methode — wird vererbt
  void beschreibe() {
    print('${runtimeType}: Fläche=${berechneFlaeche().toStringAsFixed(2)}, '
        'Umfang=${berechneUmfang().toStringAsFixed(2)}');
  }
}

class Quadrat extends Form {
  final double seite;
  Quadrat(this.seite);

  @override
  double berechneFlaeche() => seite * seite;

  @override
  double berechneUmfang() => 4 * seite;
}

void main() {
  // var f = Form();  // FEHLER — abstrakte Klasse kann nicht instanziiert werden
  var q = Quadrat(5);
  q.beschreibe();  // Quadrat: Fläche=25.00, Umfang=20.00
}
```

**Vergleich:**
- **C++:** Wie Klassen mit rein virtuellen Funktionen (`= 0`).
- **Python:** Wie `ABC` mit `@abstractmethod`.

---

## 2.6 Implizite Interfaces (implements)

In Dart ist **jede Klasse gleichzeitig ein Interface**. Es gibt kein separates `interface`-Schlüsselwort. Mit `implements` verpflichtet sich eine Klasse, **alle** Methoden und Properties einer anderen Klasse zu implementieren:

```dart
class Druckbar {
  void drucke() {
    print('Druckbar: Standard-Ausgabe');
  }
}

class Speicherbar {
  void speichere() {
    print('In Datei gespeichert');
  }
}

// implements — ALLE Methoden müssen neu implementiert werden
// (die Implementierung der Elternklasse wird NICHT geerbt)
class Dokument implements Druckbar, Speicherbar {
  final String inhalt;
  Dokument(this.inhalt);

  @override
  void drucke() {
    print('Dokument drucken: $inhalt');
  }

  @override
  void speichere() {
    print('Dokument speichern: $inhalt');
  }
}

void main() {
  Druckbar d = Dokument('Hallo');
  d.drucke();  // Dokument drucken: Hallo
}
```

**Unterschied extends vs. implements:**

| | `extends` | `implements` |
|---|-----------|-------------|
| Anzahl | Nur eine Klasse | Mehrere Klassen |
| Erbt Code | Ja | Nein — alles muss neu implementiert werden |
| Konstruktoren | Werden vererbt (super) | Nein |
| Konzept | "ist ein" mit geteiltem Code | "verhält sich wie" (Vertrag) |

---

## 2.7 Mixins

Mixins sind Darts Lösung für Code-Wiederverwendung ohne Mehrfachvererbung. Ein Mixin ist eine Klasse, deren Code in andere Klassen "eingemischt" werden kann.

```dart
// Mixin mit dem mixin-Schlüsselwort definieren
mixin Schwimmfähig {
  double geschwindigkeit = 0;

  void schwimme() {
    geschwindigkeit = 5.0;
    print('$runtimeType schwimmt mit $geschwindigkeit km/h');
  }
}

mixin Fliegbar {
  double höhe = 0;

  void fliege() {
    höhe = 100;
    print('$runtimeType fliegt auf $höhe m Höhe');
  }
}

mixin Laufbar {
  void laufe() {
    print('$runtimeType läuft');
  }
}

class Tier {
  final String name;
  Tier(this.name);
}

// Mixins mit 'with' einbinden
class Ente extends Tier with Schwimmfähig, Fliegbar, Laufbar {
  Ente(super.name);
}

class Fisch extends Tier with Schwimmfähig {
  Fisch(super.name);
}

class Adler extends Tier with Fliegbar {
  Adler(super.name);
}

void main() {
  var ente = Ente('Donald');
  ente.schwimme();  // Ente schwimmt mit 5.0 km/h
  ente.fliege();    // Ente fliegt auf 100.0 m Höhe
  ente.laufe();     // Ente läuft

  var fisch = Fisch('Nemo');
  fisch.schwimme();  // Fisch schwimmt mit 5.0 km/h
  // fisch.fliege();  // FEHLER — Fisch hat kein Fliegbar-Mixin
}
```

### Mixin mit `on`-Einschränkung

Mit `on` kann ein Mixin einschränken, auf welche Klassen es angewendet werden darf:

```dart
class Musiker {
  void spieleInstrument() {
    print('Spielt ein Instrument');
  }
}

// Dieses Mixin kann NUR auf Klassen angewendet werden, die Musiker sind
mixin Sänger on Musiker {
  void singe() {
    print('Singt ein Lied');
    spieleInstrument();  // Kann Methoden von Musiker verwenden
  }
}

class Rockstar extends Musiker with Sänger {
  // OK — Rockstar extends Musiker
}

// class Fan with Sänger { }  // FEHLER — Fan ist kein Musiker
```

**Vergleich:**
- **C++:** Mixins ersetzen Teile der Mehrfachvererbung, ohne die Diamond-Problem-Komplexität.
- **Python:** Ähnlich wie Python-Mixins (Klassen, die in der MRO verwendet werden), aber formalisiert.

---

## 2.8 Extension Methods

Extension Methods erlauben es, **bestehenden Klassen neue Methoden hinzuzufügen**, ohne sie zu verändern oder zu erben:

```dart
// Extension auf den String-Typ
extension StringErweiterungen on String {
  // Neuer Getter
  bool get istEmail => contains('@') && contains('.');

  // Neue Methode
  String wiederhole(int n, {String trennzeichen = ' '}) {
    return List.generate(n, (_) => this).join(trennzeichen);
  }

  // Capitalize — erster Buchstabe groß
  String get großAnfang {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

// Extension auf int
extension IntErweiterungen on int {
  Duration get sekunden => Duration(seconds: this);
  Duration get minuten => Duration(minutes: this);
  Duration get stunden => Duration(hours: this);

  bool get istPrimzahl {
    if (this < 2) return false;
    for (var i = 2; i * i <= this; i++) {
      if (this % i == 0) return false;
    }
    return true;
  }
}

// Extension auf List<double>
extension StatistikErweiterungen on List<double> {
  double get durchschnitt => reduce((a, b) => a + b) / length;
  double get summe => reduce((a, b) => a + b);
}

void main() {
  // String Extensions nutzen
  print('test@email.de'.istEmail);     // true
  print('Ha'.wiederhole(3));           // Ha Ha Ha
  print('dart'.großAnfang);            // Dart

  // Int Extensions
  print(7.istPrimzahl);               // true
  print(5.sekunden);                   // 0:00:05.000000
  print(2.stunden);                    // 2:00:00.000000

  // List<double> Extension
  var werte = [1.0, 2.0, 3.0, 4.0, 5.0];
  print(werte.durchschnitt);           // 3.0
  print(werte.summe);                  // 15.0
}
```

**Vergleich:**
- **C#:** Dart's Extension Methods sind direkt von C# inspiriert.
- **Python:** Ähnlich wie Monkey Patching, aber statisch geprüft und sicher.
- **JS:** Ähnlich wie Prototype-Erweiterung, aber ohne globale Mutation.

---

## 2.9 Enhanced Enums (Dart 2.17+)

Enhanced Enums können Felder, Methoden und sogar Interfaces implementieren — deutlich mächtiger als einfache Enums:

```dart
enum Planet implements Comparable<Planet> {
  merkur(masseKg: 3.303e+23, radiusM: 2.4397e6),
  venus(masseKg: 4.869e+24, radiusM: 6.0518e6),
  erde(masseKg: 5.976e+24, radiusM: 6.37814e6),
  mars(masseKg: 6.421e+23, radiusM: 3.3972e6);

  // Finale Felder — werden im Konstruktor gesetzt
  final double masseKg;
  final double radiusM;

  // Const-Konstruktor — Enums sind immer const
  const Planet({required this.masseKg, required this.radiusM});

  // Berechnete Getter
  static const double _gravitationskonst = 6.67300E-11;

  double get oberflächengravitation =>
      _gravitationskonst * masseKg / (radiusM * radiusM);

  double get oberflächengewicht =>
      oberflächengravitation * 75; // 75 kg Standardgewicht

  // Interface-Implementierung
  @override
  int compareTo(Planet other) => masseKg.compareTo(other.masseKg);

  // Methode
  String beschreibung() =>
      '$name: Masse=${masseKg.toStringAsExponential(2)}, '
      'Radius=${(radiusM / 1000).toStringAsFixed(0)} km';
}

enum HttpStatus {
  ok(200, 'OK'),
  created(201, 'Created'),
  badRequest(400, 'Bad Request'),
  notFound(404, 'Not Found'),
  serverError(500, 'Internal Server Error');

  final int code;
  final String nachricht;

  const HttpStatus(this.code, this.nachricht);

  bool get istErfolgreich => code >= 200 && code < 300;
  bool get istFehler => code >= 400;

  @override
  String toString() => '$code $nachricht';
}

void main() {
  for (var planet in Planet.values) {
    print(planet.beschreibung());
  }

  // Sortieren nach Masse (dank Comparable)
  var sortiert = Planet.values.toList()..sort();
  print('\nNach Masse sortiert:');
  for (var p in sortiert) {
    print('  ${p.name}');
  }

  // HttpStatus verwenden
  var status = HttpStatus.notFound;
  print('\n$status');                    // 404 Not Found
  print('Fehler: ${status.istFehler}');  // true

  // Enum lookup by name
  var s = HttpStatus.values.byName('ok');
  print(s);  // 200 OK
}
```

**Vergleich:**
- **C++:** `enum class` in C++ kann nur Ganzzahl-Werte haben. Dart-Enums können beliebige Felder und Methoden besitzen.
- **Python:** Ähnlich wie `enum.Enum` mit Feldern, aber syntaktisch sauberer.
- **Java:** Dart's Enhanced Enums sind direkt von Java-Enums inspiriert und funktionieren fast identisch.

---

## 2.10 Operator Overloading

```dart
class Vektor {
  final double x;
  final double y;

  const Vektor(this.x, this.y);

  // Operatoren überladen
  Vektor operator +(Vektor other) => Vektor(x + other.x, y + other.y);
  Vektor operator -(Vektor other) => Vektor(x - other.x, y - other.y);
  Vektor operator *(double skalar) => Vektor(x * skalar, y * skalar);
  Vektor operator -() => Vektor(-x, -y);  // Unärer Negations-Operator

  // Vergleich
  @override
  bool operator ==(Object other) =>
      other is Vektor && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  // Index-Operator
  double operator [](int index) {
    return switch (index) {
      0 => x,
      1 => y,
      _ => throw RangeError('Index muss 0 oder 1 sein'),
    };
  }

  double get länge => (x * x + y * y);  // Vereinfacht (ohne sqrt für das Beispiel)

  @override
  String toString() => 'Vektor($x, $y)';
}

void main() {
  var a = Vektor(1, 2);
  var b = Vektor(3, 4);

  print(a + b);      // Vektor(4.0, 6.0)
  print(a - b);      // Vektor(-2.0, -2.0)
  print(a * 3);      // Vektor(3.0, 6.0)
  print(-a);         // Vektor(-1.0, -2.0)
  print(a == Vektor(1, 2));  // true
  print(a[0]);       // 1.0
  print(a[1]);       // 2.0
}
```

**Überladbare Operatoren in Dart:**
`+`, `-`, `*`, `/`, `~/` (Integer-Division), `%`, `==`, `<`, `>`, `<=`, `>=`, `[]`, `[]=`, `~`, `<<`, `>>`, `>>>`, `^`, `|`, `&`

**Vergleich zu C++:** Sehr ähnlich wie in C++, aber `=` und `()` können **nicht** überladen werden.

---

## 2.11 Static Members

```dart
class Zähler {
  // Statische Variable — gehört zur Klasse, nicht zur Instanz
  static int _gesamtAnzahl = 0;

  final int id;
  final String name;

  Zähler(this.name) : id = ++_gesamtAnzahl;

  // Statische Methode
  static int get gesamtAnzahl => _gesamtAnzahl;

  // Statische Factory-Methode
  static Zähler erstelle(String name) {
    print('Erstelle Zähler: $name');
    return Zähler(name);
  }

  static void resetZähler() {
    _gesamtAnzahl = 0;
  }

  @override
  String toString() => 'Zähler(id: $id, name: $name)';
}

void main() {
  var a = Zähler('Alpha');
  var b = Zähler('Beta');
  var c = Zähler.erstelle('Gamma');

  print(a);  // Zähler(id: 1, name: Alpha)
  print(b);  // Zähler(id: 2, name: Beta)
  print(c);  // Zähler(id: 3, name: Gamma)
  print('Gesamt: ${Zähler.gesamtAnzahl}');  // Gesamt: 3
}
```

---

## 2.12 Cascade Notation (`..`)

Die Cascade-Notation erlaubt es, mehrere Operationen auf demselben Objekt hintereinander auszuführen, ohne die Variable jedes Mal wiederholen zu müssen:

```dart
class Anfrage {
  String url = '';
  String methode = 'GET';
  Map<String, String> header = {};
  String? body;

  void sende() {
    print('$methode $url');
    print('Header: $header');
    if (body != null) print('Body: $body');
  }
}

void main() {
  // OHNE Cascade — repetitiv
  var req1 = Anfrage();
  req1.url = 'https://api.example.com/daten';
  req1.methode = 'POST';
  req1.header['Content-Type'] = 'application/json';
  req1.body = '{"key": "value"}';
  req1.sende();

  // MIT Cascade — elegant und kompakt
  var req2 = Anfrage()
    ..url = 'https://api.example.com/daten'
    ..methode = 'POST'
    ..header['Content-Type'] = 'application/json'
    ..body = '{"key": "value"}'
    ..sende();

  // Cascades können auch verschachtelt werden
  // ..header.addAll({...}) funktioniert direkt

  // Null-aware Cascade (?..) — nur wenn Objekt nicht null ist
  Anfrage? vielleicht;
  vielleicht
    ?..url = 'test'
    ..methode = 'GET';  // Wird nicht ausgeführt, da vielleicht null ist
}
```

**Vergleich:**
- **JS/Python:** Kein direktes Äquivalent. In JS würde man Method Chaining verwenden (wo jede Methode `this` zurückgibt).
- Cascades funktionieren mit **jeder** Klasse, ohne dass die Klasse speziell dafür designed sein muss.

---

## 2.13 Zusammenfassendes Beispiel

```dart
/// Ein vollständiges Beispiel, das alle OOP-Konzepte verbindet.

// Mixin
mixin Protokollierbar {
  void protokolliere(String nachricht) {
    print('[${DateTime.now().toIso8601String()}] $runtimeType: $nachricht');
  }
}

// Abstrakte Klasse
abstract class Speicher<T> {
  T? lade(String schlüssel);
  void speichere(String schlüssel, T wert);
  void lösche(String schlüssel);
}

// Enhanced Enum
enum Priorität implements Comparable<Priorität> {
  niedrig(1, 'Niedrig'),
  mittel(2, 'Mittel'),
  hoch(3, 'Hoch'),
  kritisch(4, 'Kritisch');

  final int stufe;
  final String bezeichnung;
  const Priorität(this.stufe, this.bezeichnung);

  @override
  int compareTo(Priorität other) => stufe.compareTo(other.stufe);

  @override
  String toString() => bezeichnung;
}

// Hauptklasse mit Vererbung, Mixin, Operators
class Aufgabe with Protokollierbar implements Comparable<Aufgabe> {
  final int id;
  String titel;
  Priorität priorität;
  bool erledigt;

  static int _nächsteId = 0;

  // Shorthand-Konstruktor mit benannten Parametern
  Aufgabe({
    required this.titel,
    this.priorität = Priorität.mittel,
    this.erledigt = false,
  }) : id = ++_nächsteId;

  // Benannter Konstruktor
  Aufgabe.ausMap(Map<String, dynamic> map)
      : id = ++_nächsteId,
        titel = map['titel'] as String,
        priorität = Priorität.values.byName(map['priorität'] as String),
        erledigt = map['erledigt'] as bool? ?? false;

  void abschließen() {
    erledigt = true;
    protokolliere('Aufgabe "$titel" abgeschlossen');
  }

  @override
  int compareTo(Aufgabe other) => other.priorität.compareTo(priorität);

  @override
  String toString() {
    var status = erledigt ? 'x' : ' ';
    return '[$status] #$id $titel ($priorität)';
  }
}

// Extension Method
extension AufgabenListeErweiterung on List<Aufgabe> {
  List<Aufgabe> get offene => where((a) => !a.erledigt).toList();
  List<Aufgabe> get erledigte => where((a) => a.erledigt).toList();
  List<Aufgabe> nachPriorität() => toList()..sort();

  String zusammenfassung() {
    return 'Gesamt: $length | Offen: ${offene.length} | Erledigt: ${erledigte.length}';
  }
}

void main() {
  // Aufgaben erstellen
  var aufgaben = [
    Aufgabe(titel: 'Dart lernen', priorität: Priorität.hoch),
    Aufgabe(titel: 'Flutter installieren', priorität: Priorität.kritisch),
    Aufgabe(titel: 'Kaffee trinken', priorität: Priorität.niedrig),
    Aufgabe.ausMap({'titel': 'Code reviewen', 'priorität': 'mittel'}),
  ];

  // Cascade Notation zum Modifizieren
  aufgaben[2]
    ..priorität = Priorität.hoch
    ..abschließen();

  // Extension Methods nutzen
  print('--- Alle Aufgaben (nach Priorität) ---');
  for (var a in aufgaben.nachPriorität()) {
    print(a);
  }

  print('\n${aufgaben.zusammenfassung()}');
}
```
