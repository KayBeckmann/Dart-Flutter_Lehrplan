# Modul 1: Lösung — Temperatur-Konverter (CLI)

```dart
/// Temperatur-Konverter — Lösung Modul 1
///
/// Demonstriert: var/final/const, benannte Parameter, Arrow-Syntax,
/// String-Interpolation, for-in, switch-Expressions, assert, Typedef.

// ============================================================
// KONSTANTEN — Verwendung von const für Kompilierzeit-Konstanten
// ============================================================

/// Absoluter Nullpunkt in Celsius — physikalische Konstante, ideal für const
const double absoluterNullpunktCelsius = -273.15;
const double gefrierpunktWasser = 0.0;
const double siedepunktWasser = 100.0;

// ============================================================
// TYPEDEF — Funktionstyp für Konvertierungsfunktionen (Bonusaufgabe 3)
// ============================================================

/// Definiert den Typ für alle Konvertierungsfunktionen.
/// So können wir Funktionen dieses Typs einheitlich als Parameter übergeben.
typedef TemperaturKonverter = double Function({required double wert});

// ============================================================
// KONVERTIERUNGSFUNKTIONEN — Arrow-Syntax und benannte Parameter
// ============================================================

/// Celsius nach Fahrenheit.
/// Arrow-Syntax (=>) ist ideal für Einzeiler-Funktionen.
/// Benannte Parameter ({required ...}) verbessern die Lesbarkeit am Aufrufort.
double celsiusNachFahrenheit({required double celsius}) => celsius * 9 / 5 + 32;

/// Fahrenheit nach Celsius.
double fahrenheitNachCelsius({required double fahrenheit}) =>
    (fahrenheit - 32) * 5 / 9;

/// Celsius nach Kelvin.
double celsiusNachKelvin({required double celsius}) => celsius - absoluterNullpunktCelsius;

/// Kelvin nach Celsius.
double kelvinNachCelsius({required double kelvin}) => kelvin + absoluterNullpunktCelsius;

/// Fahrenheit nach Kelvin — leitet über Celsius um.
/// Zeigt, wie man Funktionen kombiniert.
double fahrenheitNachKelvin({required double fahrenheit}) =>
    celsiusNachKelvin(celsius: fahrenheitNachCelsius(fahrenheit: fahrenheit));

/// Kelvin nach Fahrenheit — leitet über Celsius um.
double kelvinNachFahrenheit({required double kelvin}) =>
    celsiusNachFahrenheit(celsius: kelvinNachCelsius(kelvin: kelvin));

// ============================================================
// FORMATIERUNGSFUNKTION — Optionaler Parameter mit Standardwert
// ============================================================

/// Formatiert eine Temperatur mit Einheit.
///
/// [nachkommastellen] ist ein optionaler positioneller Parameter mit
/// Standardwert 1. Die eckigen Klammern [...] markieren ihn als optional.
/// String-Interpolation mit ${...} wird für die Formatierung verwendet.
String formatiere(double temperatur, String einheit, [int nachkommastellen = 1]) {
  // toStringAsFixed gibt einen String mit fester Nachkommastellenzahl zurück
  return '${temperatur.toStringAsFixed(nachkommastellen)} $einheit';
}

// ============================================================
// VALIDIERUNG — bool-Rückgabe und assert
// ============================================================

/// Prüft, ob eine Temperatur physikalisch gültig ist (über absolutem Nullpunkt).
/// Benannte Parameter machen den Aufruf selbst-dokumentierend:
///   istGültigeTemperatur(wert: -300, einheit: 'C')
bool istGültigeTemperatur({required double wert, required String einheit}) {
  // Konvertiere zunächst alles nach Celsius für den Vergleich
  final celsiusWert = switch (einheit) {
    'C' => wert,
    'F' => fahrenheitNachCelsius(fahrenheit: wert),
    'K' => kelvinNachCelsius(kelvin: wert),
    _ => wert, // Fallback — eigentlich sollte die Einheit validiert werden
  };

  return celsiusWert >= absoluterNullpunktCelsius;
}

// ============================================================
// UNIVERSELLE KONVERTIERUNG — switch-Expression (Dart 3)
// ============================================================

/// Konvertiert einen Temperaturwert zwischen beliebigen Einheiten.
///
/// Verwendet einen switch-Ausdruck (Dart 3 Feature) mit Tuple-artigem
/// Pattern Matching über (von, nach)-Kombinationen.
/// [nachkommastellen] hat den Standardwert 2.
String konvertiere({
  required double wert,
  required String von,
  required String nach,
  int nachkommastellen = 2,
}) {
  // assert wird nur im Debug-Modus ausgewertet — ideal für Entwicklungszeit-Checks
  assert(
    istGültigeTemperatur(wert: wert, einheit: von),
    'Temperatur $wert °$von liegt unter dem absoluten Nullpunkt!',
  );

  // Dart 3 switch-Expression mit Record-Pattern-Matching
  // (von, nach) erzeugt ein Record, das gegen die Patterns geprüft wird
  final ergebnis = switch ((von, nach)) {
    ('C', 'F') => celsiusNachFahrenheit(celsius: wert),
    ('C', 'K') => celsiusNachKelvin(celsius: wert),
    ('F', 'C') => fahrenheitNachCelsius(fahrenheit: wert),
    ('F', 'K') => fahrenheitNachKelvin(fahrenheit: wert),
    ('K', 'C') => kelvinNachCelsius(kelvin: wert),
    ('K', 'F') => kelvinNachFahrenheit(kelvin: wert),
    // Gleiche Einheit — keine Konvertierung nötig
    (String a, String b) when a == b => wert,
    // Unbekannte Kombination
    _ => throw ArgumentError('Unbekannte Einheiten-Kombination: $von -> $nach'),
  };

  // Einheitensymbol bestimmen — 'K' hat kein Gradzeichen
  final einheitSymbol = nach == 'K' ? 'K' : '°$nach';

  return formatiere(ergebnis, einheitSymbol, nachkommastellen);
}

// ============================================================
// BONUSAUFGABE 2 — Anonyme Funktion in Variable
// ============================================================

/// Eine anonyme Funktion, die in einer Variable gespeichert wird.
/// Gibt eine Temperatur in allen drei Einheiten zurück.
/// Der Typ wird per Typinferenz als Function bestimmt (var).
final alleEinheiten = (double celsius) {
  final f = celsiusNachFahrenheit(celsius: celsius);
  final k = celsiusNachKelvin(celsius: celsius);
  return '${celsius.toStringAsFixed(2)} °C = '
      '${f.toStringAsFixed(2)} °F = '
      '${k.toStringAsFixed(2)} K';
};

// ============================================================
// MAIN — Einstiegspunkt des Programms
// ============================================================

void main() {
  // const-Liste — vollständig unveränderlich (Kompilierzeit-Konstante)
  const testTemperaturen = [-40.0, -17.78, 0.0, 20.0, 37.0, 100.0, -273.15];

  // Header ausgeben
  print('=== Temperatur-Konverter ===');
  print('');

  // Konstanten anzeigen mit String-Interpolation
  print('Absoluter Nullpunkt: ${absoluterNullpunktCelsius.toStringAsFixed(2)} °C');
  print('Gefrierpunkt Wasser:    ${gefrierpunktWasser.toStringAsFixed(2)} °C');
  print('Siedepunkt Wasser:    ${siedepunktWasser.toStringAsFixed(2)} °C');
  print('');

  // Umrechnungstabelle
  print('--- Umrechnungstabelle ---');

  // for-in Schleife über die Temperaturliste
  for (var celsius in testTemperaturen) {
    // final für Ergebnisse, die sich nicht mehr ändern
    final fahrenheit = celsiusNachFahrenheit(celsius: celsius);
    final kelvin = celsiusNachKelvin(celsius: celsius);

    // Formatierte Ausgabe mit padLeft für rechtsbündige Ausrichtung
    // padLeft(8) füllt den String links mit Leerzeichen auf 8 Zeichen Breite
    final cStr = celsius.toStringAsFixed(2).padLeft(8);
    final fStr = fahrenheit.toStringAsFixed(2).padLeft(8);
    final kStr = kelvin.toStringAsFixed(2).padLeft(8);

    print('$cStr °C  = $fStr °F  = $kStr K');
  }

  print('');

  // Universelle Konvertierung demonstrieren
  print('--- Universelle Konvertierung ---');
  print(konvertiere(wert: 100, von: 'C', nach: 'F'));           // 212.00 °F
  print(konvertiere(wert: 0, von: 'K', nach: 'C'));             // -273.15 °C
  print(konvertiere(wert: 32, von: 'F', nach: 'K'));            // 273.15 K
  print(konvertiere(wert: 20, von: 'C', nach: 'C'));            // 20.00 °C (gleiche Einheit)
  print(konvertiere(wert: 98.6, von: 'F', nach: 'C', nachkommastellen: 1)); // 37.0 °C

  print('');

  // Validierung demonstrieren
  print('--- Validierung ---');
  print('20 °C gültig: ${istGültigeTemperatur(wert: 20, einheit: "C")}');    // true
  print('-300 °C gültig: ${istGültigeTemperatur(wert: -300, einheit: "C")}'); // false
  print('0 K gültig: ${istGültigeTemperatur(wert: 0, einheit: "K")}');        // true
  print('-1 K gültig: ${istGültigeTemperatur(wert: -1, einheit: "K")}');      // false

  print('');

  // ============================================================
  // BONUSAUFGABE 1 — Zusammenfassung berechnen
  // ============================================================

  print('--- Zusammenfassung ---');

  // reduce() kombiniert alle Elemente zu einem Ergebnis
  // Hier: Findet den kleinsten Wert, indem es paarweise vergleicht
  final minTemp = testTemperaturen.reduce(
    (a, b) => a < b ? a : b,
  );

  final maxTemp = testTemperaturen.reduce(
    (a, b) => a > b ? a : b,
  );

  // fold() ist wie reduce(), aber mit einem Startwert
  // Hier: Summiert alle Werte auf, ausgehend von 0.0
  final summe = testTemperaturen.fold<double>(
    0.0,
    (vorherigerWert, element) => vorherigerWert + element,
  );
  final durchschnitt = summe / testTemperaturen.length;

  print('Anzahl Werte:  ${testTemperaturen.length}');
  print('Minimum:       ${minTemp.toStringAsFixed(2)} °C');
  print('Maximum:       ${maxTemp.toStringAsFixed(2)} °C');
  print('Durchschnitt:  ${durchschnitt.toStringAsFixed(2)} °C');

  print('');

  // ============================================================
  // BONUSAUFGABE 2 — Anonyme Funktion verwenden
  // ============================================================

  print('--- Alle Einheiten (anonyme Funktion) ---');
  print(alleEinheiten(37.0));   // Körpertemperatur
  print(alleEinheiten(0.0));    // Gefrierpunkt
  print(alleEinheiten(100.0));  // Siedepunkt

  print('');

  // ============================================================
  // BONUSAUFGABE 3 — Typedef demonstrieren
  // ============================================================

  print('--- Typedef-Demonstration ---');

  // Eine Funktion, die einen TemperaturKonverter entgegennimmt
  // und auf eine Liste von Werten anwendet
  void wendeKonverterAn(
    List<double> werte,
    TemperaturKonverter konverter,
    String zielEinheit,
  ) {
    for (var w in werte) {
      final ergebnis = konverter(wert: w);
      print('  ${w.toStringAsFixed(1)} -> ${ergebnis.toStringAsFixed(1)} $zielEinheit');
    }
  }

  // Wir müssen Wrapper-Funktionen erstellen, die dem Typedef entsprechen,
  // da unsere Konvertierungsfunktionen spezifische Parameternamen haben.
  double cNachF({required double wert}) => celsiusNachFahrenheit(celsius: wert);
  double cNachK({required double wert}) => celsiusNachKelvin(celsius: wert);

  print('Celsius -> Fahrenheit:');
  wendeKonverterAn([0, 20, 37, 100], cNachF, '°F');

  print('Celsius -> Kelvin:');
  wendeKonverterAn([0, 20, 37, 100], cNachK, 'K');
}
```

## Erwartete Ausgabe

```
=== Temperatur-Konverter ===

Absoluter Nullpunkt: -273.15 °C
Gefrierpunkt Wasser:    0.00 °C
Siedepunkt Wasser:    100.00 °C

--- Umrechnungstabelle ---
  -40.00 °C  =   -40.00 °F  =   233.15 K
  -17.78 °C  =     0.00 °F  =   255.37 K
    0.00 °C  =    32.00 °F  =   273.15 K
   20.00 °C  =    68.00 °F  =   293.15 K
   37.00 °C  =    98.60 °F  =   310.15 K
  100.00 °C  =   212.00 °F  =   373.15 K
 -273.15 °C  =  -459.67 °F  =     0.00 K

--- Universelle Konvertierung ---
212.00 °F
-273.15 °C
273.15 K
20.00 °C
37.0 °C

--- Validierung ---
20 °C gültig: true
-300 °C gültig: false
0 K gültig: true
-1 K gültig: false

--- Zusammenfassung ---
Anzahl Werte:  7
Minimum:       -273.15 °C
Maximum:       100.00 °C
Durchschnitt:  -24.87 °C

--- Alle Einheiten (anonyme Funktion) ---
37.00 °C = 98.60 °F = 310.15 K
0.00 °C = 32.00 °F = 273.15 K
100.00 °C = 212.00 °F = 373.15 K

--- Typedef-Demonstration ---
Celsius -> Fahrenheit:
  0.0 -> 32.0 °F
  20.0 -> 68.0 °F
  37.0 -> 98.6 °F
  100.0 -> 212.0 °F
Celsius -> Kelvin:
  0.0 -> 273.2 K
  20.0 -> 293.2 K
  37.0 -> 310.2 K
  100.0 -> 373.2 K
```

## Erklärung der Dart-spezifischen Features

| Feature | Wo in der Lösung | Erklärung |
|---------|------------------|-----------|
| `const` | `absoluterNullpunktCelsius`, `testTemperaturen` | Kompilierzeit-Konstanten — Wert steht fest, bevor das Programm läuft |
| `final` | `fahrenheit`, `kelvin`, `alleEinheiten` | Laufzeit-Konstanten — Wert wird einmal berechnet und ist dann fix |
| Benannte Parameter | `{required double celsius}` | Verbessern Lesbarkeit: `celsiusNachFahrenheit(celsius: 100)` statt `celsiusNachFahrenheit(100)` |
| Arrow-Syntax | `=> celsius * 9 / 5 + 32` | Kurzform für Einzeiler-Funktionen |
| String-Interpolation | `'$cStr °C'`, `'${celsius.toStringAsFixed(2)}'` | `$var` für einfache Variablen, `${expr}` für Ausdrücke |
| Switch-Expression | `switch ((von, nach)) { ... }` | Dart 3 Pattern Matching mit Records |
| `assert` | In `konvertiere()` | Debug-Modus-Prüfung, wird in Produktion ignoriert |
| Typedef | `TemperaturKonverter` | Gibt einem Funktionstyp einen lesbaren Namen |
| `for-in` | `for (var celsius in testTemperaturen)` | Iteration wie Python's `for x in list` |
| `reduce` / `fold` | Bonusaufgabe 1 | Funktionale Aggregation über Listen |
| Anonyme Funktion | `alleEinheiten = (double celsius) { ... }` | Funktion als Wert in Variable |
