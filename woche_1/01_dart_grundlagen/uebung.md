# Modul 1: Übung — Temperatur-Konverter (CLI)

## Ziel

Erstelle ein Dart-Kommandozeilenprogramm, das Temperaturen zwischen Celsius, Fahrenheit und Kelvin umrechnet. Die Übung festigt den Umgang mit Variablen, Funktionen, String-Interpolation und Kontrollfluss in Dart.

## Anforderungen

### 1. Konvertierungsfunktionen

Erstelle folgende Funktionen mit **benannten Parametern**:

- `celsiusNachFahrenheit({required double celsius})` → `double`
- `fahrenheitNachCelsius({required double fahrenheit})` → `double`
- `celsiusNachKelvin({required double celsius})` → `double`
- `kelvinNachCelsius({required double kelvin})` → `double`
- `fahrenheitNachKelvin({required double fahrenheit})` → `double`
- `kelvinNachFahrenheit({required double kelvin})` → `double`

**Hinweis:** Verwende **Arrow-Syntax** (`=>`) für einfache Funktionen, die nur eine Berechnung durchführen.

**Formeln:**
- F = C * 9/5 + 32
- C = (F - 32) * 5/9
- K = C + 273.15
- C = K - 273.15

### 2. Formatierungsfunktion

Erstelle eine Funktion `formatiere`, die:
- Die Temperatur und Einheit als Parameter nimmt
- Einen **optionalen Parameter** `nachkommastellen` mit Standardwert `1` hat
- **String-Interpolation** nutzt, um das Ergebnis zu formatieren
- Den formatierten String zurückgibt (z.B. `"100.0 °C"`)

### 3. Universelle Konvertierungsfunktion

Erstelle eine Funktion `konvertiere` mit:
- Benanntem Parameter `wert` (required)
- Benanntem Parameter `von` (required) — Einheit als String ('C', 'F', 'K')
- Benanntem Parameter `nach` (required) — Zieleinheit als String
- Benanntem Parameter `nachkommastellen` mit Standardwert `2`
- Verwende einen **switch-Ausdruck** (Dart 3), um die richtige Konvertierungsfunktion auszuwählen
- Gib den formatierten Ergebnis-String zurück

### 4. Konstanten und finale Variablen

- Definiere den absoluten Nullpunkt als `const` (in Celsius: -273.15)
- Definiere den Siedepunkt und Gefrierpunkt von Wasser als `const`
- Verwende `final` für Ergebnisse, die sich nicht ändern sollen

### 5. Temperaturliste verarbeiten

In der `main()`-Funktion:

- Erstelle eine `const`-Liste mit Testtemperaturen in Celsius: `[-40.0, -17.78, 0.0, 20.0, 37.0, 100.0, -273.15]`
- Iteriere über die Liste mit einer `for-in`-Schleife
- Konvertiere jede Temperatur nach Fahrenheit **und** Kelvin
- Gib das Ergebnis formatiert aus, zum Beispiel:

```
=== Temperatur-Konverter ===

Absoluter Nullpunkt: -273.15 °C
Gefrierpunkt Wasser:    0.00 °C
Siedepunkt Wasser:    100.00 °C

--- Umrechnungstabelle ---
  -40.00 °C  =   -40.00 °F  =  233.15 K
  -17.78 °C  =     0.00 °F  =  255.37 K
    0.00 °C  =    32.00 °F  =  273.15 K
   20.00 °C  =    68.00 °F  =  293.15 K
   37.00 °C  =    98.60 °F  =  310.15 K
  100.00 °C  =   212.00 °F  =  373.15 K
 -273.15 °C  =  -459.67 °F  =    0.00 K
```

### 6. Validierung

Erstelle eine Funktion `istGültigeTemperatur`, die:
- Den Temperaturwert und die Einheit entgegennimmt
- Prüft, ob die Temperatur **oberhalb des absoluten Nullpunkts** liegt
- Ein `bool` zurückgibt
- Verwende `assert` zusätzlich in den Konvertierungsfunktionen, um ungültige Temperaturen im Debug-Modus abzufangen

## Bonusaufgaben

1. **Zusammenfassung berechnen:** Gib am Ende den Durchschnitt, den niedrigsten und den höchsten Wert der Celsius-Liste aus. Verwende dafür geeignete Methoden.

2. **Anonyme Funktion:** Erstelle eine Variable, die eine anonyme Funktion enthält, welche eine Temperatur in allen drei Einheiten als formatierten String zurückgibt.

3. **Typedef:** Definiere einen `typedef` für den Funktionstyp der Konvertierungsfunktionen und verwende ihn.

## Hinweise

- Starte DartPad (https://dartpad.dev) oder erstelle eine lokale `.dart`-Datei.
- Verwende `toStringAsFixed(n)` zur Formatierung von Dezimalzahlen.
- Nutze `padLeft()` um Zahlen rechtsbündig auszurichten.
- Erinnere dich: `const`-Listen sind unveränderlich, `final`-Listen können verändert werden.
- Alle Formeln findest du in der Lehrstoff-Datei oder online.
