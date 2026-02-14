# Lösung 1.1: Dart Syntax & Typsystem

---

## Aufgabe 1: Variablen-Deklaration

```dart
void main() {
  // 1. var — der Name kann sich ändern
  var benutzername = 'Max';

  // 2. const — mathematische Konstante, zur Kompilierzeit bekannt
  const pi = 3.14159265;

  // 3. final — Zeitstempel wird zur Laufzeit bestimmt
  final startzeit = DateTime.now();

  // 4. late — wird später initialisiert
  late String konfiguration;
  konfiguration = 'debug'; // Muss vor erstem Zugriff initialisiert werden

  // 5. const — fester Wert, der sich nie ändert
  const maxVersuche = 3;

  print('Benutzer: $benutzername');
  print('Pi: $pi');
  print('Gestartet: $startzeit');
  print('Konfiguration: $konfiguration');
  print('Max Versuche: $maxVersuche');
}
```

---

## Aufgabe 2: Typkonvertierungen

```dart
void main() {
  String eingabe = '42.7';

  // String zu double
  double alsDouble = double.parse(eingabe);

  // double zu int (abgerundet) — toInt() schneidet ab
  int abgerundet = alsDouble.toInt();

  // double zu int (gerundet)
  int gerundet = alsDouble.round();

  // double zu int (aufgerundet)
  int aufgerundet = alsDouble.ceil();

  // Formatierter String mit 1 Nachkommastelle
  String formatiert = alsDouble.toStringAsFixed(1);

  print('Original: $eingabe');
  print('Als Double: $alsDouble');
  print('Abgerundet: $abgerundet');
  print('Gerundet: $gerundet');
  print('Aufgerundet: $aufgerundet');
  print('Formatiert: $formatiert');
}
```

**Erklärung:**
- `double.parse()` wandelt einen String in double um
- `toInt()` schneidet die Nachkommastellen ab (floor für positive, ceil für negative)
- `round()` rundet mathematisch korrekt
- `ceil()` rundet immer auf
- `toStringAsFixed(n)` formatiert mit n Nachkommastellen

---

## Aufgabe 3: String-Interpolation

```dart
void main() {
  erstelleVisitenkarte(
    name: 'Max Mustermann',
    firma: 'Tech GmbH',
    position: 'Senior Developer',
    email: 'max@tech.de',
    telefon: '+49 123 456789',
  );
}

void erstelleVisitenkarte({
  required String name,
  required String firma,
  required String position,
  required String email,
  required String telefon,
}) {
  const breite = 36;

  var karte = '''
┌${'─' * breite}┐
│  ${name.toUpperCase().padRight(breite - 2)}│
│  ${position.padRight(breite - 2)}│
│${' ' * breite}│
│  ${firma.padRight(breite - 2)}│
│  ${email.padRight(breite - 2)}│
│  ${telefon.padRight(breite - 2)}│
└${'─' * breite}┘''';

  print(karte);
}
```

**Alternative kompaktere Version:**

```dart
void erstelleVisitenkarte({
  required String name,
  required String firma,
  required String position,
  required String email,
  required String telefon,
}) {
  String zeile(String text) => '│  ${text.padRight(34)}│';
  String leer() => '│${' ' * 36}│';

  print('┌${'─' * 36}┐');
  print(zeile(name.toUpperCase()));
  print(zeile(position));
  print(leer());
  print(zeile(firma));
  print(zeile(email));
  print(zeile(telefon));
  print('└${'─' * 36}┘');
}
```

---

## Aufgabe 4: Typ-Checks und Typumwandlung

```dart
void main() {
  verarbeite('Hallo');
  verarbeite(42);
  verarbeite(3.14);
  verarbeite(true);
  verarbeite([1, 2, 3]);
}

void verarbeite(dynamic wert) {
  if (wert is String) {
    print('Text mit ${wert.length} Zeichen: $wert');
  } else if (wert is int) {
    var parität = wert.isEven ? 'gerade' : 'ungerade';
    print('Ganzzahl: $wert ($parität)');
  } else if (wert is double) {
    print('Kommazahl: $wert (gerundet: ${wert.round()})');
  } else if (wert is bool) {
    var bezeichnung = wert ? 'wahr' : 'falsch';
    print('Wahrheitswert: $bezeichnung');
  } else if (wert is List) {
    print('Liste mit ${wert.length} Elementen');
  } else {
    print('Unbekannter Typ: ${wert.runtimeType}');
  }
}
```

**Mit switch (Dart 3 Pattern Matching):**

```dart
void verarbeite(dynamic wert) {
  var beschreibung = switch (wert) {
    String s => 'Text mit ${s.length} Zeichen: $s',
    int i => 'Ganzzahl: $i (${i.isEven ? 'gerade' : 'ungerade'})',
    double d => 'Kommazahl: $d (gerundet: ${d.round()})',
    bool b => 'Wahrheitswert: ${b ? 'wahr' : 'falsch'}',
    List l => 'Liste mit ${l.length} Elementen',
    _ => 'Unbekannter Typ: ${wert.runtimeType}',
  };
  print(beschreibung);
}
```

---

## Aufgabe 5: Konstanten-Quiz

| Zeile | Kompiliert? | Erklärung |
|-------|-------------|-----------|
| **A** | Nein | `DateTime.now()` ist keine Kompilierzeit-Konstante |
| **B** | Ja | `final` erlaubt Laufzeit-Initialisierung |
| **C** | Ja | Arithmetik mit Konstanten ergibt eine Konstante |
| **D** | Ja | `final` schützt nur die Referenz, nicht den Inhalt |
| **E** | Kompiliert, aber... | Laufzeitfehler! `const`-Listen sind unveränderlich |
| **F** | Ja | `var` erlaubt neue Werte des gleichen Typs |
| **G** | Nein | Typ wurde als String inferiert, 42 ist int |
| **H** | Kompiliert, aber... | Laufzeitfehler! `late` Variable wurde nicht initialisiert |
| **I** | Ja | `late` Variable wurde vor Zugriff initialisiert |

---

## Bonusaufgabe: Temperaturrechner

```dart
void main() {
  // Konstanten
  const double kelvinOffset = 273.15;
  const double fahrenheitFaktor = 9 / 5;
  const double fahrenheitOffset = 32;

  var celsius = 25.0;

  // Berechnungen
  double fahrenheit = (celsius * fahrenheitFaktor) + fahrenheitOffset;
  double kelvin = celsius + kelvinOffset;

  // Formatierte Ausgabe
  print('${celsius.toStringAsFixed(2)} °C = '
        '${fahrenheit.toStringAsFixed(2)} °F = '
        '${kelvin.toStringAsFixed(2)} K');

  // Erweitert: Als Funktion
  print(konvertiereTemperatur(0, 'C'));
  print(konvertiereTemperatur(100, 'C'));
  print(konvertiereTemperatur(-40, 'C'));  // Spaßfakt: -40°C = -40°F
}

String konvertiereTemperatur(double wert, String einheit) {
  const kelvinOffset = 273.15;

  double celsius;

  // Zuerst alles in Celsius umrechnen
  switch (einheit.toUpperCase()) {
    case 'C':
      celsius = wert;
      break;
    case 'F':
      celsius = (wert - 32) * 5 / 9;
      break;
    case 'K':
      celsius = wert - kelvinOffset;
      break;
    default:
      return 'Ungültige Einheit: $einheit';
  }

  // Von Celsius in alle Einheiten
  var fahrenheit = (celsius * 9 / 5) + 32;
  var kelvin = celsius + kelvinOffset;

  return '${celsius.toStringAsFixed(2)} °C = '
         '${fahrenheit.toStringAsFixed(2)} °F = '
         '${kelvin.toStringAsFixed(2)} K';
}
```
