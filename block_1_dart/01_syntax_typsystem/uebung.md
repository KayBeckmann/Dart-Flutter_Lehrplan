# Übung 1.1: Dart Syntax & Typsystem

> **Dauer:** ca. 60 Minuten | **Schwierigkeit:** Einsteiger

Nutze [DartPad](https://dartpad.dev) für diese Übungen.

---

## Aufgabe 1: Variablen-Deklaration (10 Min.)

Deklariere die folgenden Variablen mit dem **passenden Schlüsselwort** (`var`, `final`, `const`, `late`):

```dart
void main() {
  // 1. Eine Variable für den Namen eines Benutzers, der sich ändern kann
  // TODO: Deklariere 'benutzername'

  // 2. Die mathematische Konstante Pi (bekannt zur Kompilierzeit)
  // TODO: Deklariere 'pi'

  // 3. Der Zeitstempel, wann das Programm gestartet wurde
  // TODO: Deklariere 'startzeit'

  // 4. Eine Konfiguration, die erst später initialisiert wird
  // TODO: Deklariere 'konfiguration'

  // 5. Die maximale Anzahl an Login-Versuchen (immer 3)
  // TODO: Deklariere 'maxVersuche'

  // Gib alle Variablen aus
  print('Benutzer: $benutzername');
  print('Pi: $pi');
  print('Gestartet: $startzeit');
  print('Max Versuche: $maxVersuche');
}
```

---

## Aufgabe 2: Typkonvertierungen (15 Min.)

Schreibe eine Funktion, die verschiedene Typkonvertierungen durchführt:

```dart
void main() {
  // Gegeben:
  String eingabe = '42.7';

  // TODO: Konvertiere 'eingabe' zu double
  // double alsDouble = ...

  // TODO: Konvertiere das double zu int (abgerundet)
  // int abgerundet = ...

  // TODO: Konvertiere das double zu int (gerundet)
  // int gerundet = ...

  // TODO: Konvertiere das double zu int (aufgerundet)
  // int aufgerundet = ...

  // TODO: Erstelle einen formatierten String mit 1 Nachkommastelle
  // String formatiert = ...

  print('Original: $eingabe');
  print('Als Double: $alsDouble');
  print('Abgerundet: $abgerundet');
  print('Gerundet: $gerundet');
  print('Aufgerundet: $aufgerundet');
  print('Formatiert: $formatiert');

  // Erwartete Ausgabe:
  // Original: 42.7
  // Als Double: 42.7
  // Abgerundet: 42
  // Gerundet: 43
  // Aufgerundet: 43
  // Formatiert: 42.7
}
```

---

## Aufgabe 3: String-Interpolation (15 Min.)

Erstelle eine Funktion `erstelleVisitenkarte`, die eine formatierte Visitenkarte ausgibt:

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
  // TODO: Erstelle eine formatierte Visitenkarte mit String-Interpolation
  // Verwende mehrzeilige Strings (''') und String-Interpolation ($)

  // Erwartete Ausgabe (ungefähr):
  // ┌────────────────────────────────────┐
  // │  MAX MUSTERMANN                    │
  // │  Senior Developer                  │
  // │                                    │
  // │  Tech GmbH                         │
  // │  max@tech.de                       │
  // │  +49 123 456789                    │
  // └────────────────────────────────────┘
}
```

**Hinweise:**
- Verwende `name.toUpperCase()` für den Namen
- Nutze `padRight()` zum Auffüllen mit Leerzeichen
- Die Box sollte eine feste Breite von 38 Zeichen haben

---

## Aufgabe 4: Typ-Checks und Typumwandlung (10 Min.)

Schreibe eine Funktion, die den Typ einer Variable erkennt und entsprechend verarbeitet:

```dart
void main() {
  verarbeite('Hallo');
  verarbeite(42);
  verarbeite(3.14);
  verarbeite(true);
  verarbeite([1, 2, 3]);
}

void verarbeite(dynamic wert) {
  // TODO: Prüfe den Typ mit 'is' und gib eine passende Beschreibung aus

  // Für String: "Text mit X Zeichen: ..."
  // Für int: "Ganzzahl: X (gerade/ungerade)"
  // Für double: "Kommazahl: X (gerundet: Y)"
  // Für bool: "Wahrheitswert: wahr/falsch"
  // Für List: "Liste mit X Elementen"
  // Sonst: "Unbekannter Typ: ..."

  // Erwartete Ausgabe:
  // Text mit 5 Zeichen: Hallo
  // Ganzzahl: 42 (gerade)
  // Kommazahl: 3.14 (gerundet: 3)
  // Wahrheitswert: wahr
  // Liste mit 3 Elementen
}
```

---

## Aufgabe 5: Konstanten-Quiz (10 Min.)

Analysiere den folgenden Code und beantworte die Fragen:

```dart
void main() {
  // Welche der folgenden Zeilen kompilieren? Warum oder warum nicht?

  // A
  const a = DateTime.now();

  // B
  final b = DateTime.now();

  // C
  const c = 3.14 * 2;

  // D
  final d = [1, 2, 3];
  d.add(4);

  // E
  const e = [1, 2, 3];
  e.add(4);

  // F
  var f = 'test';
  f = 'neu';

  // G
  var g = 'test';
  g = 42;

  // H
  late String h;
  print(h);

  // I
  late String i;
  i = 'initialisiert';
  print(i);
}
```

Schreibe für jede Zeile (A-I):
1. Kompiliert sie? (Ja/Nein)
2. Wenn nein, warum nicht?
3. Wenn ja, aber Laufzeitfehler möglich, welcher?

---

## Bonusaufgabe: Temperaturrechner (optional)

Erstelle einen Temperaturrechner, der zwischen Celsius, Fahrenheit und Kelvin umrechnet:

```dart
void main() {
  // Definiere Konstanten für absolute Nullpunkte
  // const kelvinOffset = ...

  var celsius = 25.0;

  // Berechne Fahrenheit und Kelvin
  // Formel C -> F: (C * 9/5) + 32
  // Formel C -> K: C + 273.15

  // Formatierte Ausgabe mit 2 Nachkommastellen:
  // 25.00 °C = 77.00 °F = 298.15 K
}
```
