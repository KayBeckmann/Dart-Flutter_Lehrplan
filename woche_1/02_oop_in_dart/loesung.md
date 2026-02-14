# Modul 2: Lösung — Geometrische Formen-Hierarchie

```dart
import 'dart:math';

// ============================================================
// 1. ENHANCED ENUM: Farbe
// ============================================================

/// Enhanced Enum mit Feldern, Methoden und einem const-Konstruktor.
/// Jede Farbe hat einen Hex-Wert und RGB-Komponenten.
/// Records (int r, int g, int b) speichern die RGB-Werte als Tuple.
enum Farbe {
  rot(hexWert: '#FF0000', rgb: (r: 255, g: 0, b: 0)),
  grün(hexWert: '#00FF00', rgb: (r: 0, g: 255, b: 0)),
  blau(hexWert: '#0000FF', rgb: (r: 0, g: 0, b: 255)),
  gelb(hexWert: '#FFFF00', rgb: (r: 255, g: 255, b: 0)),
  schwarz(hexWert: '#000000', rgb: (r: 0, g: 0, b: 0)),
  weiß(hexWert: '#FFFFFF', rgb: (r: 255, g: 255, b: 255)),
  orange(hexWert: '#FFA500', rgb: (r: 255, g: 165, b: 0));

  // Felder — müssen final sein (Enums sind immer const)
  final String hexWert;
  final ({int r, int g, int b}) rgb; // Named Record

  // Const-Konstruktor — Pflicht für Enums
  const Farbe({required this.hexWert, required this.rgb});

  /// Prüft ob die Farbe dunkel ist (Durchschnitt der RGB-Werte < 128).
  bool istDunkel() => (rgb.r + rgb.g + rgb.b) / 3 < 128;

  @override
  String toString() =>
      '${name[0].toUpperCase()}${name.substring(1)} ($hexWert)';
}

// ============================================================
// 2. MIXIN: Druckbar
// ============================================================

/// Mixin, das eine beschreibe()-Methode bereitstellt.
/// Erwartet, dass die einbindende Klasse einen 'info'-Getter hat.
/// In Dart können Mixins auf Properties der Zielklasse zugreifen,
/// wenn diese über ein gemeinsames Interface definiert sind.
mixin Druckbar {
  /// Muss von der Klasse bereitgestellt werden, die dieses Mixin verwendet.
  String get info;

  /// Gibt eine formatierte Beschreibung zurück.
  /// runtimeType liefert den tatsächlichen Klassennamen zur Laufzeit.
  String beschreibe() => '[$runtimeType] $info';
}

// ============================================================
// 3. ABSTRAKTE KLASSE: Form
// ============================================================

/// Abstrakte Basisklasse für alle geometrischen Formen.
/// Verwendet Mixin 'Druckbar' und implementiert Comparable für Sortierung.
abstract class Form with Druckbar implements Comparable<Form> {
  /// Farbe der Form — Standardwert schwarz.
  Farbe farbe;

  Form({this.farbe = Farbe.schwarz});

  /// Abstrakte Methoden — müssen von Unterklassen implementiert werden.
  double fläche();
  double umfang();

  /// Formatiert die Fläche mit gegebener Nachkommastellenzahl.
  /// Optionaler positioneller Parameter mit Standardwert.
  String formatierteFläche([int nachkommastellen = 2]) =>
      fläche().toStringAsFixed(nachkommastellen);

  /// Vergleich basierend auf der Fläche (für Sortierung).
  /// Implementiert Comparable<Form> (Bonusaufgabe 3).
  @override
  int compareTo(Form other) => fläche().compareTo(other.fläche());

  // ---------------------------------------------------------
  // FACTORY-KONSTRUKTOR — erstellt die richtige Unterklasse aus einem Map.
  // Factory-Konstruktoren dürfen in abstrakten Klassen stehen und
  // können Unterklassen zurückgeben.
  // ---------------------------------------------------------
  factory Form.ausMap(Map<String, dynamic> daten) {
    // Farbe aus dem Map lesen (optional)
    final farbeStr = daten['farbe'] as String?;
    final farbe = farbeStr != null
        ? Farbe.values.byName(farbeStr)
        : Farbe.schwarz;

    // Typ bestimmen und die richtige Unterklasse erstellen
    // Switch-Expression mit Pattern Matching (Dart 3)
    return switch (daten['typ'] as String) {
      'kreis' => Kreis(
          (daten['radius'] as num).toDouble(),
          farbe: farbe,
        ),
      'rechteck' => Rechteck(
          (daten['breite'] as num).toDouble(),
          (daten['höhe'] as num).toDouble(),
          farbe: farbe,
        ),
      'dreieck' => Dreieck(
          (daten['a'] as num).toDouble(),
          (daten['b'] as num).toDouble(),
          (daten['c'] as num).toDouble(),
          farbe: farbe,
        ),
      String typ => throw ArgumentError('Unbekannter Formtyp: $typ'),
    };
  }
}

// ============================================================
// 4. KONKRETE KLASSEN
// ============================================================

/// Kreis — demonstriert Shorthand-Konstruktor und benannte Konstruktoren.
class Kreis extends Form {
  final double radius;

  /// Shorthand-Konstruktor: this.radius weist den Parameter direkt dem Feld zu.
  /// super.farbe leitet den benannten Parameter an den Eltern-Konstruktor weiter.
  Kreis(this.radius, {super.farbe});

  /// Benannter Konstruktor — Einheitskreis mit Radius 1.
  /// Redirecting-Konstruktor mit : this(...)
  Kreis.einheit({Farbe farbe = Farbe.schwarz}) : this(1.0, farbe: farbe);

  @override
  double fläche() => pi * radius * radius;

  @override
  double umfang() => 2 * pi * radius;

  /// Getter 'info' wird vom Mixin 'Druckbar' benötigt.
  @override
  String get info => 'Radius: $radius, Farbe: $farbe';

  @override
  String toString() => 'Kreis(radius: $radius)';
}

/// Rechteck — demonstriert benannte Konstruktoren und Getter/Setter.
class Rechteck extends Form {
  double breite;
  double höhe;

  Rechteck(this.breite, this.höhe, {super.farbe});

  /// Benannter Konstruktor für ein Quadrat (Breite == Höhe).
  /// Redirecting: leitet an den Hauptkonstruktor weiter.
  Rechteck.quadrat(double seite, {Farbe farbe = Farbe.schwarz})
      : this(seite, seite, farbe: farbe);

  @override
  double fläche() => breite * höhe;

  @override
  double umfang() => 2 * (breite + höhe);

  /// Getter für das Seitenverhältnis (Bonusaufgabe 2).
  double get seitenverhältnis => breite / höhe;

  /// Setter — passt die Höhe an, um das gewünschte Verhältnis zu erreichen.
  set seitenverhältnis(double verhältnis) {
    höhe = breite / verhältnis;
  }

  /// Prüft ob es ein Quadrat ist.
  bool get istQuadrat => breite == höhe;

  @override
  String get info =>
      '${breite.toStringAsFixed(1)} x ${höhe.toStringAsFixed(1)}, '
      'Farbe: $farbe${istQuadrat ? " (Quadrat)" : ""}';

  @override
  String toString() => 'Rechteck(${breite}x$höhe)';
}

/// Dreieck — demonstriert Validierung mit assert und die Heron'sche Formel.
class Dreieck extends Form {
  final double a;
  final double b;
  final double c;

  /// Konstruktor mit Dreiecksungleichung als assert.
  /// Die Dreiecksungleichung besagt: Jede Seite muss kleiner sein
  /// als die Summe der beiden anderen Seiten.
  Dreieck(this.a, this.b, this.c, {super.farbe})
      : assert(a + b > c && a + c > b && b + c > a,
            'Dreiecksungleichung verletzt: $a, $b, $c');

  /// Heron'sche Formel zur Flächenberechnung.
  /// s = halber Umfang, dann Fläche = sqrt(s*(s-a)*(s-b)*(s-c))
  @override
  double fläche() {
    final s = umfang() / 2; // Halber Umfang
    return sqrt(s * (s - a) * (s - b) * (s - c));
  }

  @override
  double umfang() => a + b + c;

  @override
  String get info =>
      'Seiten: ${a.toStringAsFixed(1)}/${b.toStringAsFixed(1)}/${c.toStringAsFixed(1)}, '
      'Farbe: $farbe';

  @override
  String toString() => 'Dreieck($a, $b, $c)';
}

// ============================================================
// 5. EXTENSION METHOD auf List<Form>
// ============================================================

/// Extension Methods fügen bestehenden Typen neue Funktionalität hinzu,
/// ohne die Originalklasse zu verändern.
extension FormenListe on List<Form> {
  /// Berechnet die Gesamtfläche aller Formen.
  /// fold() startet mit 0.0 und summiert alle Flächen auf.
  double get gesamtFläche =>
      fold<double>(0.0, (summe, form) => summe + form.fläche());

  /// Berechnet den Gesamtumfang aller Formen.
  double get gesamtUmfang =>
      fold<double>(0.0, (summe, form) => summe + form.umfang());

  /// Gibt eine nach Fläche sortierte Kopie der Liste zurück.
  /// toList() erstellt eine Kopie, damit die Originalliste unverändert bleibt.
  /// ..sort() nutzt die Comparable-Implementierung von Form.
  List<Form> nachFläche() => toList()..sort();

  /// Filtert die Liste nach einem bestimmten Formtyp.
  /// Generische Methode — T muss ein Subtyp von Form sein.
  /// whereType<T>() ist eine eingebaute Methode, die nach Laufzeittyp filtert.
  List<T> nachTyp<T extends Form>() => whereType<T>().toList();

  /// Erstellt eine formatierte Zusammenfassung.
  String zusammenfassung() {
    if (isEmpty) return 'Keine Formen vorhanden.';

    final kreise = nachTyp<Kreis>().length;
    final rechtecke = nachTyp<Rechteck>().length;
    final dreiecke = nachTyp<Dreieck>().length;

    return '''
--- Zusammenfassung ---
Gesamtfläche:  ${gesamtFläche.toStringAsFixed(2)}
Gesamtumfang:  ${gesamtUmfang.toStringAsFixed(2)}
Anzahl Formen: $length
Kreise: $kreise, Rechtecke: $rechtecke, Dreiecke: $dreiecke''';
  }
}

// ============================================================
// 6. FORMENGRUPPE — Operator Overloading
// ============================================================

/// Demonstriert Operator-Überladung (+, []) und die Verwendung von Mixin.
class FormenGruppe with Druckbar {
  final String name;
  final List<Form> _formen;

  FormenGruppe(this.name, [List<Form>? formen])
      : _formen = formen ?? [];

  /// Operator + : Zwei FormenGruppen zusammenführen.
  /// Erstellt eine neue Gruppe mit allen Formen aus beiden Gruppen.
  FormenGruppe operator +(FormenGruppe other) {
    return FormenGruppe(
      '$name + ${other.name}',
      [..._formen, ...other._formen], // Spread-Operator kombiniert beide Listen
    );
  }

  /// Operator [] : Zugriff auf einzelne Formen per Index.
  Form operator [](int index) => _formen[index];

  /// Anzahl der Formen in der Gruppe.
  int get anzahl => _formen.length;

  /// Alle Formen als unveränderliche Liste.
  List<Form> get formen => List.unmodifiable(_formen);

  /// Formen hinzufügen (für Cascade-Demonstration).
  void fügeHinzu(Form form) => _formen.add(form);

  @override
  String get info => 'Gruppe "$name" mit $anzahl Formen';

  @override
  String toString() => 'FormenGruppe($name, $anzahl Formen)';
}

// ============================================================
// 7. MAIN — Alles zusammenführen
// ============================================================

void main() {
  print('=== Geometrische Formen ===\n');

  // ---- Formen direkt erstellen ----

  var kreis = Kreis(5.0, farbe: Farbe.rot);
  var einheitskreis = Kreis.einheit(farbe: Farbe.grün);
  var rechteck = Rechteck(4.0, 6.0);
  var quadrat = Rechteck.quadrat(3.0, farbe: Farbe.gelb);
  var dreieck = Dreieck(3.0, 4.0, 5.0, farbe: Farbe.blau);

  // ---- Formen via Factory-Konstruktor aus Maps erstellen ----

  var kreisAusMap = Form.ausMap({
    'typ': 'kreis',
    'radius': 2.5,
    'farbe': 'orange',
  });

  var rechteckAusMap = Form.ausMap({
    'typ': 'rechteck',
    'breite': 10.0,
    'höhe': 5.0,
    'farbe': 'grün',
  });

  // ---- Alle Formen in einer Liste sammeln ----

  var formen = <Form>[
    kreis,
    einheitskreis,
    rechteck,
    quadrat,
    dreieck,
    kreisAusMap,
    rechteckAusMap,
  ];

  // ---- Beschreibungen ausgeben (Mixin 'Druckbar' in Aktion) ----

  for (var form in formen) {
    print(form.beschreibe());
    print('  Fläche:  ${form.formatierteFläche()}');
    print('  Umfang:  ${form.umfang().toStringAsFixed(2)}');
    print('');
  }

  // ---- Extension Methods nutzen ----

  print(formen.zusammenfassung());
  print('');

  // Nach Fläche sortiert
  print('--- Nach Fläche sortiert ---');
  for (var form in formen.nachFläche()) {
    print('  ${form.beschreibe()} — Fläche: ${form.formatierteFläche()}');
  }
  print('');

  // Nur Kreise filtern
  print('--- Nur Kreise ---');
  var kreise = formen.nachTyp<Kreis>();
  for (var k in kreise) {
    print('  ${k.beschreibe()}');
  }
  print('');

  // ---- FormenGruppe und Operator Overloading ----

  print('--- FormenGruppen ---');

  // Cascade Notation: Formen hinzufügen mit ..
  var gruppe1 = FormenGruppe('Runde Formen')
    ..fügeHinzu(kreis)
    ..fügeHinzu(einheitskreis)
    ..fügeHinzu(kreisAusMap);

  var gruppe2 = FormenGruppe('Eckige Formen')
    ..fügeHinzu(rechteck)
    ..fügeHinzu(quadrat)
    ..fügeHinzu(dreieck);

  // Operator + : Gruppen zusammenführen
  var alleGruppen = gruppe1 + gruppe2;

  print(gruppe1.beschreibe());       // [FormenGruppe] Gruppe "Runde Formen" mit 3 Formen
  print(gruppe2.beschreibe());       // [FormenGruppe] Gruppe "Eckige Formen" mit 3 Formen
  print(alleGruppen.beschreibe());   // [FormenGruppe] Gruppe "..." mit 6 Formen

  // Operator [] : Index-Zugriff
  print('\nErste Form in Gesamtgruppe: ${alleGruppen[0].beschreibe()}');
  print('');

  // ---- Enhanced Enum demonstrieren ----

  print('--- Farben ---');
  for (var farbe in Farbe.values) {
    var dunkel = farbe.istDunkel() ? 'dunkel' : 'hell';
    print('  $farbe — $dunkel (RGB: ${farbe.rgb.r}, ${farbe.rgb.g}, ${farbe.rgb.b})');
  }
  print('');

  // ---- Getter/Setter demonstrieren (Bonusaufgabe 2) ----

  print('--- Getter/Setter ---');
  var r = Rechteck(10.0, 5.0);
  print('Seitenverhältnis: ${r.seitenverhältnis}');  // 2.0
  r.seitenverhältnis = 4.0;  // Setter: passt Höhe an
  print('Neue Höhe nach Verhältnis 4:1 : ${r.höhe}');  // 2.5
  print('Breite unverändert: ${r.breite}');  // 10.0

  // ---- Sortierung demonstrieren (Bonusaufgabe 3) ----

  print('\n--- Sortiert nach Fläche (Comparable) ---');
  var sortiert = formen.toList()..sort();
  for (var form in sortiert) {
    print('  ${form.formatierteFläche().padLeft(8)} — ${form.beschreibe()}');
  }
}
```

## Erwartete Ausgabe (gekürzt)

```
=== Geometrische Formen ===

[Kreis] Radius: 5.0, Farbe: Rot (#FF0000)
  Fläche:  78.54
  Umfang:  31.42

[Kreis] Radius: 1.0, Farbe: Grün (#00FF00)
  Fläche:  3.14
  Umfang:  6.28

[Rechteck] 4.0 x 6.0, Farbe: Schwarz (#000000)
  Fläche:  24.00
  Umfang:  20.00

[Rechteck] 3.0 x 3.0, Farbe: Gelb (#FFFF00) (Quadrat)
  Fläche:  9.00
  Umfang:  12.00

[Dreieck] Seiten: 3.0/4.0/5.0, Farbe: Blau (#0000FF)
  Fläche:  6.00
  Umfang:  12.00

[Kreis] Radius: 2.5, Farbe: Orange (#FFA500)
  Fläche:  19.63
  Umfang:  15.71

[Rechteck] 10.0 x 5.0, Farbe: Grün (#00FF00)
  Fläche:  50.00
  Umfang:  30.00

--- Zusammenfassung ---
Gesamtfläche:  190.31
Gesamtumfang:  127.41
Anzahl Formen: 7
Kreise: 3, Rechtecke: 2, Dreiecke: 1

--- FormenGruppen ---
[FormenGruppe] Gruppe "Runde Formen" mit 3 Formen
[FormenGruppe] Gruppe "Eckige Formen" mit 3 Formen
[FormenGruppe] Gruppe "Runde Formen + Eckige Formen" mit 6 Formen
```

## Erklärung der Dart-spezifischen Features

| Feature | Wo in der Lösung | Erklärung |
|---------|------------------|-----------|
| Enhanced Enum | `Farbe` | Enum mit Feldern (`hexWert`, `rgb`), Methoden (`istDunkel()`) und const-Konstruktor |
| Record | `({int r, int g, int b})` | Named Record als leichtgewichtiger Datencontainer für RGB-Werte |
| Mixin | `Druckbar` | Code-Wiederverwendung ohne Vererbung — wird mit `with` eingebunden |
| Abstrakte Klasse | `Form` | Definiert den Vertrag (abstrakte Methoden) für alle Unterklassen |
| Factory-Konstruktor | `Form.ausMap()` | Erstellt die richtige Unterklasse basierend auf Map-Daten |
| Shorthand-Konstruktor | `Kreis(this.radius, ...)` | `this.param` weist direkt dem Feld zu |
| Benannte Konstruktoren | `Kreis.einheit()`, `Rechteck.quadrat()` | Mehrere Konstruktoren mit sprechenden Namen |
| Getter/Setter | `seitenverhältnis` | Berechnete Properties mit Validierung |
| Extension Methods | `FormenListe` | Neue Methoden auf `List<Form>` ohne die Klasse zu ändern |
| Operator Overloading | `FormenGruppe.+`, `FormenGruppe.[]` | Eigene Logik für Operatoren |
| Cascade Notation | `FormenGruppe('..') ..fügeHinzu(..)` | Mehrere Aufrufe auf demselben Objekt ohne Wiederholung |
| `super.farbe` | Konstruktoren der Unterklassen | Dart 3 Syntax zum Weiterleiten benannter Parameter an super |
| `Comparable` | `Form.compareTo()` | Ermöglicht Sortierung mit `.sort()` |
| Spread-Operator | `[..._formen, ...other._formen]` | Listen kombinieren (Vorschau auf Modul 4) |
