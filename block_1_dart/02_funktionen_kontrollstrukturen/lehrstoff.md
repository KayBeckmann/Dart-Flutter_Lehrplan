# Einheit 1.2: Funktionen & Kontrollstrukturen

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1

---

## 2.1 Funktionen in Dart

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

---

## 2.2 Optionale Parameter

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
  String? telefon,           // Optional und nullable
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

---

## 2.3 Arrow-Syntax `=>`

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

---

## 2.4 Funktionen als First-Class-Objekte

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

## 2.5 Kontrollstrukturen

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

---

## 2.6 Switch-Statement

### Klassisches switch

```dart
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
```

### Dart 3: Switch als Ausdruck (Expression)

```dart
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

---

## 2.7 Exceptions und Fehlerbehandlung

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

---

## 2.8 Assert

```dart
// assert wird nur im Debug-Modus ausgewertet (JIT/Debug-Build)
// In Produktions-Builds (AOT) werden asserts komplett ignoriert
var alter = 25;
assert(alter >= 0, 'Alter darf nicht negativ sein');

// Nützlich für Entwicklungszeit-Checks
void setzeProzentwert(double wert) {
  assert(wert >= 0 && wert <= 100, 'Wert muss zwischen 0 und 100 liegen');
  // ... Implementierung
}
```

---

## 2.9 Zusammenfassendes Beispiel

```dart
/// Ein vollständiges Beispiel mit Funktionen und Kontrollstrukturen.

typedef Bewertung = String Function(int);

// Benannte Parameter + Standardwerte
String erstelleProfil({
  required String name,
  required int alter,
  String beruf = 'Unbekannt',
}) {
  return 'Profil: $name, $alter Jahre, $beruf';
}

// Arrow-Funktion
bool istErwachsen(int alter) => alter >= 18;

// Funktion die eine Funktion zurückgibt
Bewertung bewertungsFunktion(String kategorie) {
  return (int punkte) => switch (punkte) {
    >= 90 => '$kategorie: Sehr gut ($punkte)',
    >= 70 => '$kategorie: Gut ($punkte)',
    >= 50 => '$kategorie: Befriedigend ($punkte)',
    _ => '$kategorie: Ungenügend ($punkte)',
  };
}

void main() {
  // Benannte Parameter
  print(erstelleProfil(name: 'Max', alter: 28, beruf: 'Entwickler'));

  // Arrow-Funktion + Ternärer Operator
  var alter = 17;
  print(istErwachsen(alter) ? 'Volljährig' : 'Minderjährig');

  // Higher-Order Function
  var matheBewertung = bewertungsFunktion('Mathe');
  print(matheBewertung(85));  // Mathe: Gut (85)

  // for-in + switch Expression
  var noten = [95, 72, 45, 88];
  for (var note in noten) {
    print(matheBewertung(note));
  }
}
```
