# Modul 1: Dart Syntax & Grundlagen

## 1.1 Dart im Überblick

Dart ist eine von Google entwickelte, objektorientierte Programmiersprache mit C-ähnlicher Syntax. Für Entwickler mit C++-, JavaScript- und Python-Erfahrung ist der Einstieg daher sehr intuitiv. Dart bringt jedoch einige einzigartige Eigenschaften mit:

### Kompilierungsmodi

Dart unterstützt **zwei Kompilierungsmodi**, was es besonders vielseitig macht:

| Modus | Beschreibung | Einsatz |
|-------|-------------|---------|
| **JIT** (Just-In-Time) | Kompiliert zur Laufzeit, ermöglicht Hot Reload | Entwicklungsphase (Flutter Debug) |
| **AOT** (Ahead-Of-Time) | Kompiliert zu nativem Maschinencode | Produktions-Builds (Flutter Release) |

**Vergleich:**
- **C++** ist rein AOT-kompiliert — Dart bietet zusätzlich JIT für schnellere Entwicklungszyklen.
- **JavaScript** wird von der Engine zur Laufzeit interpretiert/JIT-kompiliert — Dart kann echten nativen Code erzeugen.
- **Python** ist interpretiert — Dart ist in der Produktion deutlich performanter durch AOT-Kompilierung.

### Typsystem

Dart verwendet ein **starkes, statisches Typsystem mit Typinferenz**. Das heißt:
- Alle Typen werden zur Kompilierzeit geprüft (wie C++, anders als Python/JS).
- Der Compiler kann Typen automatisch ableiten, sodass man nicht immer explizit annotieren muss (ähnlich `auto` in C++ oder TypeScript).

```dart
// Typinferenz — der Compiler erkennt den Typ automatisch
var name = 'Dart';       // Typ: String (inferiert)
var zahl = 42;            // Typ: int (inferiert)
var pi = 3.14;            // Typ: double (inferiert)

// Explizite Typangabe — gleichwertiger Code
String name2 = 'Dart';
int zahl2 = 42;
double pi2 = 3.14;
```

---

## 1.2 Variablen: var, final, const, late, dynamic

### `var` — Typinferenz bei der Deklaration

```dart
var stadt = 'Berlin';   // Typ wird als String inferiert
stadt = 'München';      // OK — neuer Wert, gleicher Typ
// stadt = 42;           // FEHLER — Typ ist String, nicht int
```

**Vergleich zu JS:** In JavaScript ist `var` funktions-scoped und erlaubt beliebige Typwechsel. In Dart ist `var` block-scoped (wie JS `let`) und der inferierte Typ ist fix.

### `final` — Einmalige Zuweisung (Laufzeit-Konstante)

```dart
final zeitpunkt = DateTime.now();  // Wird zur Laufzeit bestimmt
final String gruß = 'Hallo';      // Expliziter Typ möglich

// zeitpunkt = DateTime.now();     // FEHLER — final kann nicht neu zugewiesen werden
```

**Vergleich:**
- Wie `const` in JavaScript (nicht zu verwechseln mit Dart's `const`!)
- Wie `final` in Java
- Ähnlich zu C++ `const` bei lokalen Variablen

### `const` — Kompilierzeit-Konstante

```dart
const double pi = 3.14159265;     // Muss zur Kompilierzeit bekannt sein
const maxVersuche = 3;

// const jetzt = DateTime.now();   // FEHLER — DateTime.now() ist keine Kompilierzeit-Konstante
```

**Wichtig:** `const` in Dart ist strenger als in C++. Der Wert muss vollständig zur **Kompilierzeit** feststehen.

```dart
// const vs final — der entscheidende Unterschied:
final laufzeit = DateTime.now();       // OK — wird zur Laufzeit bestimmt
// const kompilierzeit = DateTime.now(); // FEHLER — nicht zur Kompilierzeit bekannt

const liste = [1, 2, 3];              // Die Liste selbst ist unveränderlich (deeply immutable)
final liste2 = [1, 2, 3];             // Die Referenz ist fix, aber die Liste kann verändert werden
// liste.add(4);                       // FEHLER — const-Liste ist unveränderlich
liste2.add(4);                         // OK — final schützt nur die Referenz
```

### `late` — Verzögerte Initialisierung

```dart
late String beschreibung;

void initialisiere() {
  beschreibung = 'Wird später gesetzt';  // Initialisierung bei erster Zuweisung
}

// Lazy Initialization — wird erst beim ersten Zugriff berechnet
late final String teureBerechnung = _berechneAufwendig();

String _berechneAufwendig() {
  print('Berechnung läuft...');
  return 'Ergebnis';
}
```

**Vergleich zu Python:** Ähnlich wie eine Property mit `@cached_property`, aber als Sprachfeature.

### `dynamic` — Opt-out aus dem Typsystem

```dart
dynamic irgendwas = 'Text';
irgendwas = 42;         // OK — Typ kann sich ändern
irgendwas = true;       // OK — beliebiger Typ

// VORSICHT: Fehler werden erst zur Laufzeit erkannt!
// irgendwas.nichtExistierendeMethode();  // Kein Kompilierfehler, aber Laufzeitfehler
```

**Vergleich:** `dynamic` verhält sich wie Variablen in Python oder JavaScript — kein statischer Typcheck. **Sollte sparsam eingesetzt werden!**

### Übersicht

| Schlüsselwort | Typ änderbar | Wert änderbar | Wann initialisiert |
|--------------|-------------|--------------|-------------------|
| `var` | Nein (inferiert) | Ja | Bei Deklaration |
| `final` | Nein | Nein | Zur Laufzeit |
| `const` | Nein | Nein | Zur Kompilierzeit |
| `late` | Nein | Ja (oder final) | Verzögert |
| `dynamic` | Ja | Ja | Bei Deklaration |

---

## 1.3 Typsystem: Grundtypen

### Zahlen: `int`, `double`, `num`

```dart
int ganzzahl = 42;
double kommazahl = 3.14;
num beliebig = 42;          // num ist Obertyp von int und double
beliebig = 3.14;            // OK — num akzeptiert beides

// Nützliche Methoden
print(42.isEven);            // true
print(3.14.ceil());          // 4
print(3.14.toStringAsFixed(1)); // '3.1'

// Konvertierungen
int a = 3;
double b = a.toDouble();    // 3.0
int c = 3.7.toInt();        // 3 (abgeschnitten, nicht gerundet!)
int d = 3.7.round();        // 4

// Integer-Literale
var hex = 0xFF;              // 255
var binär = 0b1010;          // 10 (binär, wie in C++)
```

**Vergleich zu C++:** Kein `float` — Dart verwendet ausschließlich `double` (64-Bit IEEE 754). Es gibt keine implizite Konvertierung zwischen `int` und `double`.

**Vergleich zu JS:** JavaScript hat nur `number` (immer double). Dart unterscheidet echte Ganzzahlen (`int`) von Kommazahlen (`double`).

### `String`

```dart
var einfach = 'Einfache Anführungszeichen';
var doppelt = "Doppelte Anführungszeichen";
var mehrzeilig = '''
Dies ist ein
mehrzeiliger String.
''';

// Raw Strings (kein Escaping)
var pfad = r'C:\Users\name\docs';   // Backslash wird nicht interpretiert

// Nützliche String-Methoden
var text = '  Hallo Welt  ';
print(text.trim());                  // 'Hallo Welt'
print(text.contains('Welt'));        // true
print('abc'.padLeft(6, '0'));        // '000abc'
print('Hallo'.replaceAll('l', 'r')); // 'Harro'
print('a,b,c'.split(','));          // ['a', 'b', 'c']
```

**Vergleich zu Python:** Mehrzeilige Strings verwenden `'''` wie Python. Raw Strings nutzen `r'...'` statt Python's `r"..."`.

### `bool`

```dart
bool aktiv = true;
bool fertig = false;

// Dart ist streng — keine truthy/falsy Werte wie in JS/Python!
// if (1) { ... }     // FEHLER — int ist kein bool
// if ('text') { ... } // FEHLER — String ist kein bool
if (1 > 0) { }        // OK — Vergleichsoperator ergibt bool
```

**Wichtiger Unterschied zu JS/Python:** In Dart gibt es **keine implizite Konvertierung** zu `bool`. Bedingungen müssen explizit `bool`-Werte sein.

### Typinferenz im Detail

```dart
var x = 42;           // Typ: int
var y = 42.0;         // Typ: double
var z = 'Hallo';      // Typ: String
var w = [1, 2, 3];    // Typ: List<int>
var m = {'a': 1};     // Typ: Map<String, int>

// runtimeType gibt den Laufzeittyp zurück
print(x.runtimeType);  // int
print(w.runtimeType);  // List<int>

// Typüberprüfung mit 'is'
if (x is int) {
  print('x ist ein int');
}
```

---

## 1.4 String-Interpolation

Dart bietet eine elegante Syntax für String-Interpolation, die einfacher ist als in den meisten anderen Sprachen:

```dart
var name = 'Dart';
var version = 3;

// Einfache Variable mit $
print('Willkommen bei $name!');              // Willkommen bei Dart!

// Ausdrücke mit ${}
print('$name Version ${version + 1}');       // Dart Version 4
print('Großbuchstaben: ${name.toUpperCase()}'); // Großbuchstaben: DART

// Verschachtelt und komplex
var liste = [1, 2, 3];
print('Summe: ${liste.reduce((a, b) => a + b)}'); // Summe: 6

// Vergleich mit anderen Sprachen:
// C++:    std::format("Hallo {}", name)  oder  "Hallo " + name   (C++20)
// JS:     `Hallo ${name}`                (Template Literals)
// Python: f'Hallo {name}'               (f-Strings)
// Dart:   'Hallo $name'                 (am kürzesten!)
```

**Tipp:** Verwende `$variable` für einfache Variablen und `${ausdruck}` nur wenn ein Ausdruck ausgewertet werden muss.

---

## 1.5 Funktionen

In Dart sind Funktionen **First-Class-Objekte** — sie können Variablen zugewiesen, als Parameter übergeben und von Funktionen zurückgegeben werden (wie in JS und Python).

### Grundlegende Syntax

```dart
// Volle Syntax mit Rückgabetyp
int addiere(int a, int b) {
  return a + b;
}

// Arrow-Syntax für einzeilige Funktionen (wie JS Arrow Functions)
int addiere2(int a, int b) => a + b;

// Rückgabetyp kann inferiert werden (wird aber empfohlen, ihn anzugeben)
addiere3(int a, int b) => a + b;
```

### Positionelle Parameter

```dart
// Erforderliche positionelle Parameter
String begrüße(String name, String grußwort) {
  return '$grußwort, $name!';
}

// Aufruf:
begrüße('Welt', 'Hallo');  // 'Hallo, Welt!'
```

### Optionale positionelle Parameter `[...]`

```dart
// Optionale Parameter stehen in eckigen Klammern
String begrüße(String name, [String grußwort = 'Hallo', String suffix = '']) {
  return '$grußwort, $name$suffix';
}

// Aufrufe:
begrüße('Welt');                    // 'Hallo, Welt'
begrüße('Welt', 'Hi');             // 'Hi, Welt'
begrüße('Welt', 'Hi', '!');       // 'Hi, Welt!'
```

### Benannte Parameter `{...}`

```dart
// Benannte Parameter stehen in geschweiften Klammern
// 'required' markiert Pflichtparameter
void erstelleBenutzer({
  required String name,
  required String email,
  int alter = 0,            // Optional mit Standardwert
  String? telefon,           // Optional und nullable (kann null sein)
}) {
  print('Name: $name, Email: $email, Alter: $alter');
  if (telefon != null) {
    print('Telefon: $telefon');
  }
}

// Aufrufe — Reihenfolge der benannten Parameter ist beliebig:
erstelleBenutzer(name: 'Max', email: 'max@mail.de');
erstelleBenutzer(email: 'anna@mail.de', name: 'Anna', alter: 25);
```

**Vergleich:**
- **Python:** Ähnlich wie Python's Keyword-Argumente, aber expliziter durch `required`.
- **C++:** C++ hat keine benannten Parameter — in Dart ist dies ein eingebautes Sprachfeature.
- **JS:** JS-Objekt-Destructuring `({name, email})` ist konzeptionell ähnlich.

### Arrow-Syntax `=>`

```dart
// Arrow-Syntax ist Kurzschreibweise für { return ausdruck; }
int quadrat(int n) => n * n;
String formatiere(double wert) => wert.toStringAsFixed(2);
bool istGerade(int n) => n % 2 == 0;

// Auch für void-Funktionen nutzbar
void logge(String nachricht) => print('[LOG] $nachricht');

// Arrow-Syntax mit mehreren Ausdrücken ist NICHT möglich
// Für mehrere Anweisungen den normalen Block { } verwenden
```

### Funktionen als First-Class-Objekte

```dart
// Funktion in Variable speichern
var verdopple = (int n) => n * 2;
print(verdopple(5));  // 10

// Typ der Variable
int Function(int) dreifach = (n) => n * 3;

// Funktion als Parameter übergeben
void wendeAn(int wert, int Function(int) operation) {
  print('Ergebnis: ${operation(wert)}');
}
wendeAn(5, verdopple);   // Ergebnis: 10
wendeAn(5, (n) => n + 1); // Ergebnis: 6

// Funktion als Rückgabewert
int Function(int) multiplikator(int faktor) {
  return (int n) => n * faktor;
}
var mal5 = multiplikator(5);
print(mal5(3));  // 15
```

### Typedefs

```dart
// Typedef für Funktionstypen (verbessert Lesbarkeit)
typedef Vergleich = int Function(String, String);

void sortiereMit(List<String> liste, Vergleich vergleiche) {
  liste.sort(vergleiche);
}

sortiereMit(['b', 'a', 'c'], (a, b) => a.compareTo(b));
```

---

## 1.6 Kontrollfluss

### if / else

```dart
var alter = 20;

if (alter >= 18) {
  print('Volljährig');
} else if (alter >= 16) {
  print('Bedingt geschäftsfähig');
} else {
  print('Minderjährig');
}

// Ternärer Operator (wie C++/JS/Python's ... if ... else ...)
var status = alter >= 18 ? 'Erwachsen' : 'Minderjährig';
```

### for und for-in

```dart
// Klassische for-Schleife (wie C++/JS)
for (var i = 0; i < 5; i++) {
  print(i);
}

// for-in (wie Python's for...in, JS's for...of)
var farben = ['Rot', 'Grün', 'Blau'];
for (var farbe in farben) {
  print(farbe);
}

// forEach mit Lambda
farben.forEach((farbe) => print(farbe));
// oder mit Methodenreferenz (tear-off):
farben.forEach(print);
```

### while und do-while

```dart
var i = 0;
while (i < 5) {
  print(i);
  i++;
}

// do-while — Body wird mindestens einmal ausgeführt
var eingabe = '';
do {
  eingabe = 'simuliert'; // In der Praxis: Benutzereingabe lesen
} while (eingabe.isEmpty);
```

### switch — Klassisch und Dart 3 Patterns

```dart
// Klassisches switch
var befehl = 'start';
switch (befehl) {
  case 'start':
    print('Starte...');
    break;   // break ist erforderlich (kein Fall-Through wie in C++)
  case 'stop':
    print('Stoppe...');
    break;
  default:
    print('Unbekannter Befehl');
}

// Dart 3: Switch als Ausdruck (Expression) mit Pattern Matching
var statusCode = 404;
var nachricht = switch (statusCode) {
  200 => 'OK',
  301 => 'Umgeleitet',
  404 => 'Nicht gefunden',
  >= 500 && < 600 => 'Serverfehler',
  _ => 'Unbekannt',   // _ ist der Wildcard/Default
};
print(nachricht);  // 'Nicht gefunden'

// Switch Expression mit Guard-Klauseln
var wert = 42;
var beschreibung = switch (wert) {
  0 => 'Null',
  < 0 => 'Negativ',
  > 0 && < 100 => 'Klein und positiv',
  >= 100 when wert.isEven => 'Groß und gerade',
  _ => 'Sonstiges',
};
```

**Hinweis:** Pattern Matching wird in Modul 4 (Collections, Generics & Null Safety) ausführlich behandelt.

### assert

```dart
// assert wird nur im Debug-Modus ausgewertet (JIT/Debug-Build)
// In Produktions-Builds (AOT) werden asserts komplett ignoriert
var alter2 = 25;
assert(alter2 >= 0, 'Alter darf nicht negativ sein');

// Nützlich für Entwicklungszeit-Checks
void setzeProzentwert(double wert) {
  assert(wert >= 0 && wert <= 100, 'Wert muss zwischen 0 und 100 liegen');
  // ... Implementierung
}
```

**Vergleich zu C++:** Ähnlich wie C++ `assert()`, aber nur im Debug-Modus aktiv (ohne `#define NDEBUG`).

---

## 1.7 Top-Level-Funktionen, main() und print()

In Dart können Funktionen auf der **obersten Ebene** definiert werden — sie müssen nicht in einer Klasse stehen (anders als in Java):

```dart
// datei: mein_programm.dart

// Top-Level-Konstante
const String appName = 'Meine App';

// Top-Level-Funktion
String formatiereDatum(DateTime datum) {
  return '${datum.day}.${datum.month}.${datum.year}';
}

// Top-Level-Variable
var zähler = 0;

// Einstiegspunkt — jedes Dart-Programm benötigt eine main()-Funktion
void main() {
  print('$appName gestartet');
  print(formatiereDatum(DateTime.now()));
}
```

### Kommandozeilenargumente

```dart
// main() kann Argumente entgegennehmen
void main(List<String> args) {
  if (args.isEmpty) {
    print('Keine Argumente übergeben.');
    return;
  }

  for (var arg in args) {
    print('Argument: $arg');
  }
}

// Aufruf: dart run mein_programm.dart arg1 arg2 arg3
```

### print() und stdout

```dart
void main() {
  // Standard-Ausgabe mit Zeilenumbruch
  print('Hallo Welt');

  // Ausgabe ohne automatischen Zeilenumbruch
  // (benötigt import 'dart:io')
  // stdout.write('Kein Zeilenumbruch');
  // stdout.writeln('Mit Zeilenumbruch');

  // Objekte werden automatisch mit toString() konvertiert
  print([1, 2, 3]);       // [1, 2, 3]
  print({'a': 1});         // {a: 1}
  print(DateTime.now());   // 2024-01-15 14:30:00.000
}
```

---

## 1.8 Null-Safety-Vorschau

Dart verfügt seit Version 2.12 über **Sound Null Safety** — ein mächtiges Feature, das `NullPointerException`-Fehler (die berühmte "Billion Dollar Mistake") bereits zur Kompilierzeit verhindert. Die ausführliche Behandlung erfolgt in **Modul 4**, hier ein kurzer Überblick:

```dart
// Standardmäßig können Variablen NICHT null sein
String name = 'Dart';
// name = null;           // FEHLER zur Kompilierzeit!

// Mit ? wird ein Typ nullable
String? vielleichtName = 'Dart';
vielleichtName = null;    // OK

// Null-aware Operatoren (Vorschau)
String? eingabe = null;
var länge = eingabe?.length;    // null (kein Fehler!)
var standard = eingabe ?? 'Standard';  // 'Standard'

// Null-Check erzwingt Non-Null
String sicher = eingabe!;  // Wirft Exception wenn null — mit Vorsicht verwenden!
```

**Vergleich:**
- **C++:** Kein eingebautes Null-Safety-System (Pointer können immer null sein).
- **JavaScript:** Optional Chaining (`?.`) und Nullish Coalescing (`??`) existieren seit ES2020 — Dart hatte sie früher und geht weiter mit Compile-Time-Garantien.
- **Python:** Optional-Typen via `typing.Optional`, aber nur zur statischen Analyse (MyPy), nicht erzwungen.

---

## 1.9 Weitere nützliche Konzepte

### Enums (einfache Variante)

```dart
enum Wochentag { montag, dienstag, mittwoch, donnerstag, freitag, samstag, sonntag }

void main() {
  var heute = Wochentag.freitag;
  print(heute);            // Wochentag.freitag
  print(heute.name);       // 'freitag'
  print(heute.index);      // 4

  // In switch verwenden
  switch (heute) {
    case Wochentag.samstag:
    case Wochentag.sonntag:
      print('Wochenende!');
      break;
    default:
      print('Arbeitstag');
  }
}
```

### Exceptions und Fehlerbehandlung

```dart
// Dart kann jeden Typ werfen, empfohlen ist aber Exception/Error
void teile(int a, int b) {
  if (b == 0) {
    throw ArgumentError('Division durch Null');
  }
  print(a / b);
}

void main() {
  try {
    teile(10, 0);
  } on ArgumentError catch (e) {
    // Spezifischen Fehlertyp fangen
    print('Argument-Fehler: $e');
  } on FormatException {
    // Ohne catch-Variable
    print('Format-Fehler');
  } catch (e, stackTrace) {
    // Alle anderen Fehler fangen
    print('Unbekannter Fehler: $e');
    print('Stack Trace: $stackTrace');
  } finally {
    // Wird immer ausgeführt
    print('Aufräumarbeiten');
  }
}
```

**Vergleich:**
- `on Type catch (e)` entspricht `catch (Type& e)` in C++ oder `except Type as e` in Python.
- Das `finally`-Block existiert wie in Python und JS.
- Der Stack Trace wird als zweiter Parameter in `catch` übergeben (einzigartig in Dart).

### Imports und Libraries

```dart
// Dart-Standardbibliothek
import 'dart:math';
import 'dart:io';
import 'dart:convert';

// Externe Pakete (via pub)
// import 'package:http/http.dart' as http;

// Relative Imports
// import 'utils/helfer.dart';

// Import mit Präfix (wie Python's import ... as ...)
import 'dart:math' as math;
var wurzel = math.sqrt(16);

// Selektiver Import
import 'dart:math' show sqrt, pi;
import 'dart:math' hide Random;
```

---

## 1.10 Zusammenfassung: Dart auf einen Blick

```dart
/// Ein vollständiges Beispielprogramm, das die Grundlagen zusammenfasst.

const String appVersion = '1.0.0';  // Kompilierzeit-Konstante

// Top-Level-Funktion mit benannten Parametern
String erstelleProfil({
  required String name,
  required int alter,
  String beruf = 'Unbekannt',
}) {
  return '''
Profil:
  Name:  $name
  Alter: $alter Jahre
  Beruf: $beruf
  ''';
}

// Arrow-Funktion
bool istErwachsen(int alter) => alter >= 18;

// Funktion mit optionalen positionellen Parametern
double berechnePreis(double basis, [double steuer = 0.19, double rabatt = 0.0]) {
  return basis * (1 + steuer) * (1 - rabatt);
}

void main(List<String> args) {
  print('App Version: $appVersion');

  // Variablen-Deklaration
  var name = 'Max Mustermann';    // Typinferenz: String
  final alter = 28;                // Laufzeit-Konstante
  const pi = 3.14159;             // Kompilierzeit-Konstante

  // String-Interpolation
  print('Hallo $name! Pi ist ungefähr ${pi.toStringAsFixed(2)}');

  // Kontrollfluss
  if (istErwachsen(alter)) {
    print('$name ist erwachsen.');
  }

  // Switch Expression (Dart 3)
  var altersgruppe = switch (alter) {
    < 13 => 'Kind',
    >= 13 && < 18 => 'Jugendlicher',
    >= 18 && < 65 => 'Erwachsener',
    _ => 'Senior',
  };
  print('Altersgruppe: $altersgruppe');

  // Benannte Parameter
  print(erstelleProfil(name: name, alter: alter, beruf: 'Entwickler'));

  // Optionale Parameter
  var preis = berechnePreis(100.0);
  var preisReduziert = berechnePreis(100.0, 0.19, 0.10);
  print('Normalpreis: ${preis.toStringAsFixed(2)} EUR');
  print('Reduziert:   ${preisReduziert.toStringAsFixed(2)} EUR');

  // Schleifen
  var sprachen = ['Dart', 'C++', 'Python', 'JavaScript'];
  for (var sprache in sprachen) {
    print('  - $sprache');
  }
}
```

Dieses Programm kann mit `dart run dateiname.dart` ausgeführt werden.
