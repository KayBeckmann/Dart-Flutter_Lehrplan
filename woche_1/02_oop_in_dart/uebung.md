# Modul 2: Übung — Geometrische Formen-Hierarchie

## Ziel

Entwirf ein Klassen-System für geometrische Formen, das die zentralen OOP-Konzepte von Dart demonstriert: abstrakte Klassen, Mixins, Factory-Konstruktoren, Enhanced Enums, Extension Methods, Operator Overloading und Cascade Notation.

## Anforderungen

### 1. Enhanced Enum: `Farbe`

Erstelle ein Enhanced Enum `Farbe` mit:
- Mindestens 5 Farben (rot, grün, blau, gelb, schwarz)
- Einem Feld `hexWert` (String, z.B. `'#FF0000'`)
- Einem Feld `rgb` (Record mit `int r, int g, int b`)
- Einer Methode `istDunkel()`, die `true` zurückgibt wenn `(r + g + b) / 3 < 128`
- Einer `toString()`-Überschreibung, die Name und Hex-Wert ausgibt

### 2. Mixin: `Druckbar`

Erstelle ein Mixin `Druckbar` mit:
- Einer Methode `beschreibe()`, die einen formatierten String zurückgibt
- Die Methode soll `runtimeType` und ein abstraktes Feld `info` (String-Getter) verwenden
- Format: `"[Typname] Info-Text"`

### 3. Abstrakte Klasse: `Form`

Erstelle eine abstrakte Klasse `Form` mit:
- Einem Feld `farbe` vom Typ `Farbe` (mit Standardwert `Farbe.schwarz`)
- Abstrakten Methoden `fläche()` → `double` und `umfang()` → `double`
- Einem Getter `info` → `String` (für das Mixin)
- Einer konkreten Methode `formatierteFläche([int nachkommastellen = 2])` → `String`

### 4. Konkrete Klassen

Implementiere die folgenden Klassen, die `Form` erweitern und `Druckbar` verwenden:

**`Kreis`**
- Feld: `radius`
- Shorthand-Konstruktor mit benanntem Parameter für `farbe`
- Benannter Konstruktor `Kreis.einheit()` (Radius = 1)

**`Rechteck`**
- Felder: `breite`, `höhe`
- Shorthand-Konstruktor mit benanntem Parameter für `farbe`
- Benannter Konstruktor `Rechteck.quadrat(double seite)` — erstellt ein Quadrat

**`Dreieck`**
- Felder: `a`, `b`, `c` (drei Seiten)
- Shorthand-Konstruktor mit Validierung (assert: Dreiecksungleichung)
- Berechnung der Fläche mit der Heron'schen Formel:
  - `s = (a + b + c) / 2`
  - `fläche = sqrt(s * (s-a) * (s-b) * (s-c))`
  - (Benötigt `import 'dart:math'`)

### 5. Factory-Konstruktor

Füge der Klasse `Form` einen Factory-Konstruktor hinzu:

```dart
factory Form.ausMap(Map<String, dynamic> daten)
```

Der Konstruktor soll:
- Aus dem Feld `'typ'` im Map bestimmen, welche Unterklasse erstellt wird (`'kreis'`, `'rechteck'`, `'dreieck'`)
- Die entsprechenden Maße aus dem Map lesen
- Optional eine Farbe aus dem Feld `'farbe'` lesen (als Enum-Name)
- Bei unbekanntem Typ eine `ArgumentError`-Exception werfen

Beispiel-Maps:
```dart
{'typ': 'kreis', 'radius': 5.0, 'farbe': 'rot'}
{'typ': 'rechteck', 'breite': 4.0, 'höhe': 6.0}
{'typ': 'dreieck', 'a': 3.0, 'b': 4.0, 'c': 5.0, 'farbe': 'blau'}
```

### 6. Extension Method auf `List<Form>`

Erstelle eine Extension `FormenListe` auf `List<Form>` mit:
- Getter `gesamtFläche` → `double` (Summe aller Flächen)
- Getter `gesamtUmfang` → `double` (Summe aller Umfänge)
- Methode `nachFläche()` → `List<Form>` (sortiert nach Fläche, aufsteigend)
- Methode `nachTyp<T>()` → `List<T>` (filtert nach einem bestimmten Typ, z.B. nur Kreise)
- Methode `zusammenfassung()` → `String` (formattierte Übersicht)

### 7. Operator Overloading: FormenGruppe

Erstelle eine Klasse `FormenGruppe` mit:
- Einer internen Liste von Formen
- Operator `+` zum Zusammenführen zweier FormenGruppen
- Operator `[]` zum Zugriff auf einzelne Formen per Index
- Getter `anzahl`
- Implementierung des `Druckbar`-Mixins

### 8. Main-Funktion

In `main()`:
- Erstelle mindestens 5 verschiedene Formen (direkt und via Factory)
- Füge sie zu einer Liste zusammen
- Verwende die Extension Methods
- Demonstriere den `+`-Operator mit FormenGruppen
- Verwende Cascade Notation bei mindestens einem Objekt
- Gib eine formatierte Zusammenfassung aller Formen aus

## Erwartete Ausgabe (ungefähr)

```
=== Geometrische Formen ===

[Kreis] Radius: 5.0, Farbe: Rot (#FF0000)
  Fläche:  78.54
  Umfang:  31.42

[Rechteck] 4.0 x 6.0, Farbe: Schwarz (#000000)
  Fläche:  24.00
  Umfang:  20.00

[Dreieck] Seiten: 3.0/4.0/5.0, Farbe: Blau (#0000FF)
  Fläche:  6.00
  Umfang:  12.00

--- Zusammenfassung ---
Gesamtfläche:  108.54
Gesamtumfang:  63.42
Anzahl Formen: 3
Kreise: 1, Rechtecke: 1, Dreiecke: 1
```

## Hinweise

- Vergiss nicht `import 'dart:math'` für `sqrt` und `pi`.
- Verwende `@override` bei allen überschriebenen Methoden.
- Nutze Shorthand-Konstruktoren (`this.param`) wo möglich.
- Enhanced Enums müssen `const`-Konstruktoren haben.
- Für den Factory-Konstruktor in einer abstrakten Klasse: Das ist in Dart erlaubt und ein verbreitetes Pattern.
- Teste deine Extension Methods gründlich — sie sollen auch mit leeren Listen funktionieren.

## Bonusaufgaben

1. **Const-Konstruktor:** Mache `Kreis` const-fähig und demonstriere, dass `identical(const Kreis(5), const Kreis(5))` `true` ergibt.

2. **Getter/Setter:** Füge `Rechteck` einen Setter `seitenverhältnis` hinzu, der die Höhe anpasst und die Breite beibehält.

3. **Vergleichsoperator:** Implementiere `Comparable<Form>` basierend auf der Fläche und nutze `.sort()`.
