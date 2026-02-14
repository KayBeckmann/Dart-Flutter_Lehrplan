# Einheit 1.1: Dart Syntax & Typsystem

> **Dauer:** 2 Stunden | **Voraussetzungen:** Grundlegende Programmierkenntnisse (C++, JS, Python)

---

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

## 1.5 Enums (einfache Variante)

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

---

## 1.6 Dein erstes Dart-Programm

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

### Programm ausführen

```bash
# Mit DartPad (online): https://dartpad.dev
# Oder lokal:
dart run mein_programm.dart
```

---

## Zusammenfassung

| Konzept | Dart | C++ | JavaScript | Python |
|---------|------|-----|------------|--------|
| Typinferenz | `var x = 42;` | `auto x = 42;` | `let x = 42;` | `x = 42` |
| Konstante (Laufzeit) | `final` | `const` | `const` | - |
| Konstante (Kompilierzeit) | `const` | `constexpr` | - | - |
| String-Interpolation | `'$var'` | - | `` `${var}` `` | `f'{var}'` |
| Strikte Typen | Ja | Ja | Nein | Nein |
