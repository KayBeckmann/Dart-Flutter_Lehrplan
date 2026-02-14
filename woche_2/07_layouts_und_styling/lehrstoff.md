# Modul 7: Layouts & Styling

## Lernziele

Nach diesem Modul kannst du:

- Das Flutter-Layout-System (Constraints-basiert) verstehen und erklaeren
- Row, Column, Stack und Wrap fuer verschiedene Layouts einsetzen
- Expanded, Flexible und Spacer richtig verwenden
- ListView und GridView fuer scrollbare Listen und Raster erstellen
- Widgets mit BoxDecoration, ThemeData und TextTheme stylen
- Responsive Layouts mit MediaQuery und LayoutBuilder bauen

---

## 1. Das Flutter-Layout-System

Flutter verwendet ein Constraint-basiertes Layout-System, das sich fundamental von CSS unterscheidet. Die zentrale Regel:

> **Constraints gehen runter, Sizes gehen hoch, Positionen setzt das Eltern-Widget.**

```
Eltern-Widget
  │
  │ "Du darfst 100-300px breit und 50-200px hoch sein" (Constraints)
  │
  ▼
Kind-Widget
  │
  │ "Ich moechte 200px breit und 100px hoch sein" (Size)
  │
  ▲
Eltern-Widget
  │
  │ "Okay, ich setze dich auf Position (10, 20)" (Position)
```

### Constraints im Detail

Jedes Widget bekommt von seinem Eltern-Widget einen `BoxConstraints`-Wert:

```dart
BoxConstraints(
  minWidth: 0,       // Minimale Breite
  maxWidth: 393,     // Maximale Breite (z.B. Bildschirmbreite)
  minHeight: 0,      // Minimale Hoehe
  maxHeight: 852,    // Maximale Hoehe (z.B. Bildschirmhoehe)
)
```

**Tight Constraints:** min == max (Widget MUSS diese Groesse haben)
**Loose Constraints:** min < max (Widget kann waehlen)

> **CSS-Vergleich:** In CSS bestimmt ein Element seine Groesse selbst (z.B. `width: 200px`), und das Eltern-Element passt sich an. In Flutter ist es umgekehrt: Das Eltern-Widget sagt dem Kind, wie gross es sein DARF, und das Kind waehlt innerhalb dieser Grenzen.

### LayoutBuilder -- Constraints inspizieren

```dart
LayoutBuilder(
  builder: (context, constraints) {
    print('Max-Breite: ${constraints.maxWidth}');
    print('Max-Hoehe: ${constraints.maxHeight}');

    return Container(
      width: constraints.maxWidth * 0.8,
      height: 100,
      color: Colors.blue,
      child: const Text('80% der verfuegbaren Breite'),
    );
  },
)
```

---

## 2. Row und Column

`Row` und `Column` sind die Grundbausteine fuer lineare Layouts -- vergleichbar mit CSS Flexbox.

### Row (horizontale Anordnung)

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,    // Horizontal
  crossAxisAlignment: CrossAxisAlignment.center,  // Vertikal
  children: [
    Container(width: 50, height: 50, color: Colors.red),
    Container(width: 50, height: 70, color: Colors.green),
    Container(width: 50, height: 30, color: Colors.blue),
  ],
)
```

### Column (vertikale Anordnung)

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.start,     // Vertikal
  crossAxisAlignment: CrossAxisAlignment.stretch, // Horizontal
  children: [
    Container(height: 50, color: Colors.red),
    Container(height: 70, color: Colors.green),
    Container(height: 30, color: Colors.blue),
  ],
)
```

### MainAxisAlignment-Optionen

```
Row:  Hauptachse = horizontal →
Column: Hauptachse = vertikal ↓

start:            |■ ■ ■         |
end:              |         ■ ■ ■|
center:           |    ■ ■ ■     |
spaceBetween:     |■     ■     ■|
spaceAround:      |  ■   ■   ■  |
spaceEvenly:      |  ■  ■  ■  ■  |  (nicht ganz korrekt darstellbar)
```

> **CSS-Flexbox-Vergleich:**
> - `Row` = `display: flex; flex-direction: row;`
> - `Column` = `display: flex; flex-direction: column;`
> - `MainAxisAlignment.spaceBetween` = `justify-content: space-between;`
> - `CrossAxisAlignment.center` = `align-items: center;`
> - `CrossAxisAlignment.stretch` = `align-items: stretch;`

### CrossAxisAlignment-Optionen

```
Fuer Row (Kreuzachse = vertikal):

start:    ■ ■ ■         center:     ■ ■          end:              ■
                                  ■   ■                          ■ ■
                                ■                              ■

stretch:  ■ ■ ■    (alle gleich hoch)
          ■ ■ ■
          ■ ■ ■
```

### mainAxisSize

```dart
// Standardmaessig nimmt Row/Column den gesamten verfuegbaren Platz ein
Column(
  mainAxisSize: MainAxisSize.max, // Standard: nimmt volle Hoehe
  children: [...],
)

Column(
  mainAxisSize: MainAxisSize.min, // Nur so gross wie der Inhalt
  children: [...],
)
```

---

## 3. Expanded und Flexible

### Expanded

`Expanded` fuellt den verbleibenden Platz in einer Row oder Column:

```dart
Row(
  children: [
    Container(width: 80, height: 50, color: Colors.red),       // Fix: 80px
    Expanded(
      child: Container(height: 50, color: Colors.green),         // Fuellt den Rest
    ),
    Container(width: 80, height: 50, color: Colors.blue),       // Fix: 80px
  ],
)
// Ergebnis: |ROT(80)|----GRUEN(Rest)----|BLAU(80)|
```

### flex-Faktor

Mehrere `Expanded`-Widgets teilen den Platz nach ihrem `flex`-Wert auf:

```dart
Row(
  children: [
    Expanded(
      flex: 2,  // 2/3 des Platzes
      child: Container(height: 50, color: Colors.red),
    ),
    Expanded(
      flex: 1,  // 1/3 des Platzes
      child: Container(height: 50, color: Colors.blue),
    ),
  ],
)
// Ergebnis: |------ROT (66%)------|--BLAU (33%)--|
```

> **CSS-Vergleich:** `Expanded(flex: 2)` entspricht `flex: 2;` in CSS Flexbox.

### Flexible

`Flexible` ist wie `Expanded`, erlaubt dem Kind aber, kleiner zu sein als der verfuegbare Platz:

```dart
Row(
  children: [
    Flexible(
      // fit: FlexFit.loose (Standard) -- Kind darf kleiner sein
      child: Container(width: 50, height: 50, color: Colors.red),
    ),
    Flexible(
      fit: FlexFit.tight, // Wie Expanded -- Kind muss den Platz fuellen
      child: Container(height: 50, color: Colors.blue),
    ),
  ],
)
```

| Widget | Verhalten |
|--------|-----------|
| `Expanded` | MUSS den verfuegbaren Platz fuellen (`FlexFit.tight`) |
| `Flexible` | DARF den verfuegbaren Platz fuellen, muss aber nicht (`FlexFit.loose`) |

### Spacer

Ein `Spacer` ist ein `Expanded` ohne Kind -- er erzeugt flexiblen Leerraum:

```dart
Row(
  children: [
    const Text('Links'),
    const Spacer(),           // Flexibler Leerraum
    const Text('Rechts'),
  ],
)
// Ergebnis: |Links              Rechts|

// Mit flex:
Row(
  children: [
    const Text('A'),
    const Spacer(flex: 2),
    const Text('B'),
    const Spacer(flex: 1),
    const Text('C'),
  ],
)
// Ergebnis: |A          B     C|
```

---

## 4. Stack und Positioned

`Stack` stapelt Widgets uebereinander -- vergleichbar mit `position: absolute` in CSS.

```dart
Stack(
  children: [
    // Unterstes Widget (Hintergrund)
    Container(
      width: 200,
      height: 200,
      color: Colors.blue,
    ),
    // Darueber
    Positioned(
      top: 10,
      left: 10,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.red,
      ),
    ),
    // Ganz oben
    Positioned(
      bottom: 10,
      right: 10,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.green,
      ),
    ),
  ],
)
```

### Stack-Alignment

```dart
Stack(
  alignment: Alignment.center,  // Nicht-positionierte Kinder zentrieren
  clipBehavior: Clip.none,       // Kinder duerfen ueber den Stack hinausragen
  children: [
    Container(width: 200, height: 200, color: Colors.grey),
    Container(width: 100, height: 100, color: Colors.blue), // Zentriert
  ],
)
```

### Positioned

```dart
Positioned(
  top: 10,      // Abstand von oben
  left: 20,     // Abstand von links
  right: 20,    // Abstand von rechts (statt width)
  bottom: null, // Nicht gesetzt
  width: 100,   // Explizite Breite (statt left+right)
  height: 50,   // Explizite Hoehe
  child: Container(color: Colors.red),
)

// Positioned.fill -- fuellt den gesamten Stack
Positioned.fill(
  child: Container(color: Colors.blue.withValues(alpha: 0.3)),
)
```

### Praktisches Beispiel: Badge auf Icon

```dart
Stack(
  clipBehavior: Clip.none,
  children: [
    const Icon(Icons.shopping_cart, size: 48),
    Positioned(
      top: -8,
      right: -8,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Text(
          '3',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    ),
  ],
)
```

---

## 5. Wrap

`Wrap` ordnet Kinder in einer Zeile an und bricht automatisch in die naechste Zeile um, wenn der Platz nicht reicht:

```dart
Wrap(
  spacing: 8,         // Horizontaler Abstand zwischen Kindern
  runSpacing: 8,      // Vertikaler Abstand zwischen Zeilen
  alignment: WrapAlignment.start,
  children: [
    Chip(label: Text('Flutter')),
    Chip(label: Text('Dart')),
    Chip(label: Text('Firebase')),
    Chip(label: Text('Material Design')),
    Chip(label: Text('Cross-Platform')),
    Chip(label: Text('Hot Reload')),
    Chip(label: Text('Widgets')),
  ],
)
// Ergebnis:
// |Flutter  Dart  Firebase  Material Design|
// |Cross-Platform  Hot Reload  Widgets     |
```

> **CSS-Vergleich:** `Wrap` entspricht `display: flex; flex-wrap: wrap;` in CSS.

---

## 6. ListView

`ListView` ist ein scrollbares Widget fuer Listen. Es gibt mehrere Varianten:

### ListView (einfach)

```dart
// Alle Kinder werden sofort erstellt (nur fuer kurze Listen!)
ListView(
  padding: const EdgeInsets.all(16),
  children: const [
    ListTile(title: Text('Eintrag 1')),
    ListTile(title: Text('Eintrag 2')),
    ListTile(title: Text('Eintrag 3')),
  ],
)
```

### ListView.builder (empfohlen fuer lange Listen)

```dart
// Kinder werden lazy erstellt (nur sichtbare Elemente)
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) {
    return ListTile(
      leading: CircleAvatar(child: Text('${index + 1}')),
      title: Text('Eintrag ${index + 1}'),
      subtitle: Text('Beschreibung fuer Eintrag ${index + 1}'),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: () {
        // Aktion bei Antippen
      },
    );
  },
)
```

> **Wichtig:** `ListView.builder` erstellt nur die sichtbaren Elemente. Bei einer Liste mit 10.000 Eintraegen werden trotzdem nur ca. 10-15 Widgets gleichzeitig im Speicher gehalten. Das ist vergleichbar mit Virtualisierung (z.B. `react-window` in React).

### ListView.separated

```dart
// Wie builder, aber mit Trennern zwischen den Elementen
ListView.separated(
  itemCount: 20,
  separatorBuilder: (context, index) => const Divider(),
  itemBuilder: (context, index) {
    return ListTile(
      title: Text('Eintrag ${index + 1}'),
    );
  },
)
```

### Unterschied zu Column + SingleChildScrollView

```dart
// SCHLECHT fuer lange Listen: Alle Kinder werden sofort erstellt!
SingleChildScrollView(
  child: Column(
    children: List.generate(1000, (index) => ListTile(title: Text('$index'))),
  ),
)

// GUT: Nur sichtbare Kinder werden erstellt
ListView.builder(
  itemCount: 1000,
  itemBuilder: (context, index) => ListTile(title: Text('$index')),
)
```

| Ansatz | Kinder erstellt | Geeignet fuer |
|--------|----------------|---------------|
| Column + SingleChildScrollView | Alle sofort | Wenige Elemente (< 20) |
| ListView | Alle sofort | Wenige Elemente (< 20) |
| ListView.builder | Nur sichtbare | Viele Elemente (beliebig viele) |

### Horizontale ListView

```dart
SizedBox(
  height: 120, // Hoehe muss explizit angegeben werden!
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: 10,
    itemBuilder: (context, index) {
      return Container(
        width: 100,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.primaries[index % Colors.primaries.length],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      );
    },
  ),
)
```

---

## 7. GridView

`GridView` zeigt Kinder in einem Raster an:

### GridView.count (feste Spaltenanzahl)

```dart
GridView.count(
  crossAxisCount: 3,        // 3 Spalten
  crossAxisSpacing: 8,      // Horizontaler Abstand
  mainAxisSpacing: 8,       // Vertikaler Abstand
  childAspectRatio: 1.0,    // Breite/Hoehe-Verhaeltnis (1 = quadratisch)
  padding: const EdgeInsets.all(16),
  children: List.generate(9, (index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.primaries[index % Colors.primaries.length],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'Kachel ${index + 1}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }),
)
```

### GridView.builder (fuer viele Elemente)

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 3 / 2,
  ),
  itemCount: 20,
  padding: const EdgeInsets.all(16),
  itemBuilder: (context, index) {
    return Card(
      child: Center(
        child: Text('Item ${index + 1}'),
      ),
    );
  },
)
```

### GridView.extent (maximale Breite pro Element)

```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: 200,   // Maximale Breite pro Element
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.0,
  ),
  itemCount: 12,
  itemBuilder: (context, index) {
    return Card(
      child: Center(child: Text('Item ${index + 1}')),
    );
  },
)
```

> **CSS-Vergleich:**
> - `GridView.count(crossAxisCount: 3)` = `display: grid; grid-template-columns: repeat(3, 1fr);`
> - `GridView.extent(maxCrossAxisExtent: 200)` = `display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));`

---

## 8. SingleChildScrollView

Macht ein einzelnes Kind scrollbar:

```dart
SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      // Viel Inhalt, der moeglicherweise nicht auf den Bildschirm passt
      Container(height: 200, color: Colors.red),
      const SizedBox(height: 16),
      Container(height: 200, color: Colors.green),
      const SizedBox(height: 16),
      Container(height: 200, color: Colors.blue),
      const SizedBox(height: 16),
      Container(height: 200, color: Colors.orange),
    ],
  ),
)

// Horizontal scrollbar
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: List.generate(
      20,
      (index) => Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(8),
        color: Colors.primaries[index % Colors.primaries.length],
      ),
    ),
  ),
)
```

---

## 9. Container, Padding, Align, Center, FractionallySizedBox

### Container (das Schweizer Taschenmesser)

```dart
Container(
  width: 200,
  height: 100,
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(horizontal: 24),
  alignment: Alignment.center,
  transform: Matrix4.rotationZ(0.1),  // Leichte Rotation
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: Colors.grey, width: 1),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  ),
  child: const Text('Container'),
)
```

### Padding

```dart
// Padding ist ein eigenstaendiges Widget (leichter als Container)
Padding(
  padding: const EdgeInsets.all(16),
  child: Text('Mit Abstand'),
)

// EdgeInsets-Varianten:
EdgeInsets.all(16)                                // Alle Seiten gleich
EdgeInsets.symmetric(horizontal: 16, vertical: 8) // Horizontal und vertikal
EdgeInsets.only(left: 8, top: 16)                  // Nur bestimmte Seiten
EdgeInsets.fromLTRB(8, 16, 8, 0)                   // Links, Oben, Rechts, Unten
```

### Align

```dart
Align(
  alignment: Alignment.bottomRight,
  child: const Text('Unten rechts'),
)

// Alignment-Werte:
// Alignment.topLeft      Alignment.topCenter      Alignment.topRight
// Alignment.centerLeft   Alignment.center          Alignment.centerRight
// Alignment.bottomLeft   Alignment.bottomCenter   Alignment.bottomRight
// Alignment(-0.5, 0.3)   // Benutzerdefiniert (-1 bis 1)
```

### Center

```dart
// Center ist ein Alias fuer Align(alignment: Alignment.center)
Center(
  child: Text('Zentriert'),
)

// Mit eingeschraenkter Groesse:
Center(
  widthFactor: 0.8,   // 80% der Breite des Kindes
  heightFactor: 0.5,
  child: Container(color: Colors.blue, width: 100, height: 100),
)
```

### FractionallySizedBox

Gibt dem Kind eine Groesse als Bruchteil des verfuegbaren Platzes:

```dart
FractionallySizedBox(
  widthFactor: 0.8,   // 80% der verfuegbaren Breite
  heightFactor: 0.5,  // 50% der verfuegbaren Hoehe
  child: Container(color: Colors.blue),
)
```

---

## 10. BoxDecoration

`BoxDecoration` ist das Haupt-Styling-Werkzeug fuer Container:

### Borders und BorderRadius

```dart
Container(
  decoration: BoxDecoration(
    // Abgerundete Ecken
    borderRadius: BorderRadius.circular(16),
    // Oder einzelne Ecken:
    borderRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
    ),

    // Rahmen
    border: Border.all(color: Colors.blue, width: 2),
    // Oder einzelne Seiten:
    border: const Border(
      bottom: BorderSide(color: Colors.blue, width: 2),
    ),
  ),
)
```

### Gradient

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple, Colors.pink],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    ),
  ),
)

// Radiales Gradient
Container(
  decoration: BoxDecoration(
    gradient: RadialGradient(
      colors: [Colors.yellow, Colors.orange, Colors.red],
      center: Alignment.center,
      radius: 0.8,
    ),
  ),
)
```

### BoxShadow

```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 10,       // Weichheit
        spreadRadius: 2,      // Ausdehnung
        offset: const Offset(0, 4), // Versatz (x, y)
      ),
      // Mehrere Schatten moeglich:
      BoxShadow(
        color: Colors.blue.withValues(alpha: 0.1),
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
)
```

---

## 11. ThemeData, TextTheme und ColorScheme

### ThemeData konfigurieren

```dart
MaterialApp(
  theme: ThemeData(
    // Material 3 aktivieren
    useMaterial3: true,

    // Farbschema aus einer Grundfarbe generieren
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),

    // AppBar-Theme
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
    ),

    // Card-Theme
    cardTheme: CardTheme(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // Button-Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),

    // Input-Theme
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
    ),
  ),
)
```

### ColorScheme verwenden

```dart
@override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Container(
    color: colorScheme.surface,                    // Hintergrund
    child: Column(
      children: [
        Container(
          color: colorScheme.primary,               // Hauptfarbe
          child: Text(
            'Titel',
            style: TextStyle(color: colorScheme.onPrimary), // Text auf primary
          ),
        ),
        Container(
          color: colorScheme.secondaryContainer,    // Sekundaerer Container
          child: Text(
            'Sekundaer',
            style: TextStyle(color: colorScheme.onSecondaryContainer),
          ),
        ),
        Container(
          color: colorScheme.errorContainer,        // Fehler-Container
          child: Text(
            'Fehler',
            style: TextStyle(color: colorScheme.onErrorContainer),
          ),
        ),
      ],
    ),
  );
}
```

### TextTheme verwenden

```dart
@override
Widget build(BuildContext context) {
  final textTheme = Theme.of(context).textTheme;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Display Large',    style: textTheme.displayLarge),
      Text('Display Medium',   style: textTheme.displayMedium),
      Text('Display Small',    style: textTheme.displaySmall),
      Text('Headline Large',   style: textTheme.headlineLarge),
      Text('Headline Medium',  style: textTheme.headlineMedium),
      Text('Headline Small',   style: textTheme.headlineSmall),
      Text('Title Large',      style: textTheme.titleLarge),
      Text('Title Medium',     style: textTheme.titleMedium),
      Text('Title Small',      style: textTheme.titleSmall),
      Text('Body Large',       style: textTheme.bodyLarge),
      Text('Body Medium',      style: textTheme.bodyMedium),
      Text('Body Small',       style: textTheme.bodySmall),
      Text('Label Large',      style: textTheme.labelLarge),
      Text('Label Medium',     style: textTheme.labelMedium),
      Text('Label Small',      style: textTheme.labelSmall),
    ],
  );
}
```

### Dark Theme

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
    useMaterial3: true,
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  ),
  themeMode: ThemeMode.system, // Oder ThemeMode.light / ThemeMode.dark
)
```

---

## 12. Responsive Design mit MediaQuery und LayoutBuilder

### MediaQuery

Gibt Informationen ueber den Bildschirm:

```dart
@override
Widget build(BuildContext context) {
  final mediaQuery = MediaQuery.of(context);

  final bildschirmBreite = mediaQuery.size.width;
  final bildschirmHoehe = mediaQuery.size.height;
  final orientation = mediaQuery.orientation;
  final pixelRatio = mediaQuery.devicePixelRatio;
  final padding = mediaQuery.padding;        // Safe Area (Notch, etc.)
  final viewInsets = mediaQuery.viewInsets;   // Tastatur-Hoehe
  final textScaleFactor = mediaQuery.textScaler;

  return Text('Breite: $bildschirmBreite');
}
```

### LayoutBuilder fuer Responsive Layouts

```dart
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 900) {
      // Desktop-Layout: 3 Spalten
      return _DesktopLayout();
    } else if (constraints.maxWidth > 600) {
      // Tablet-Layout: 2 Spalten
      return _TabletLayout();
    } else {
      // Mobil-Layout: 1 Spalte
      return _MobilLayout();
    }
  },
)
```

### Praktisches Beispiel: Responsive Grid

```dart
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Spaltenanzahl basierend auf Breite
        int spalten;
        if (constraints.maxWidth > 900) {
          spalten = 4;
        } else if (constraints.maxWidth > 600) {
          spalten = 3;
        } else {
          spalten = 2;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: spalten,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: 20,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            return Card(
              child: Center(
                child: Text('Item ${index + 1}'),
              ),
            );
          },
        );
      },
    );
  }
}
```

> **CSS-Vergleich:**
> - `MediaQuery` = `@media` Queries in CSS
> - `LayoutBuilder` = Container Queries in CSS (moderner, auf das Widget bezogen statt auf den Viewport)

---

## 13. CustomScrollView und Slivers (Ueberblick)

Slivers sind die Low-Level-Bausteine fuer scrollbare Bereiche. Sie ermoeglichen komplexe Scroll-Effekte:

```dart
CustomScrollView(
  slivers: [
    // Kollabierender App-Bar
    SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Meine App'),
        background: Image.network(
          'https://picsum.photos/800/400',
          fit: BoxFit.cover,
        ),
      ),
    ),

    // Fester Bereich (wie ein normales Widget)
    SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Ueberschrift',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    ),

    // Liste innerhalb des ScrollView
    SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => ListTile(title: Text('Eintrag ${index + 1}')),
        childCount: 20,
      ),
    ),

    // Grid innerhalb des ScrollView
    SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Card(
          child: Center(child: Text('Grid ${index + 1}')),
        ),
        childCount: 12,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
    ),
  ],
)
```

> **Tipp:** Slivers brauchst du, wenn du verschiedene scrollbare Bereiche (Liste + Grid + Header) in einem einzigen Scroll-Bereich kombinieren willst. Fuer einfache Faelle reichen ListView und GridView.

---

## 14. Vergleichstabelle: Flutter Layout vs. CSS

| CSS | Flutter |
|-----|---------|
| `display: flex; flex-direction: row;` | `Row()` |
| `display: flex; flex-direction: column;` | `Column()` |
| `display: grid;` | `GridView()` |
| `flex: 1;` | `Expanded()` |
| `flex-wrap: wrap;` | `Wrap()` |
| `justify-content: center;` | `MainAxisAlignment.center` |
| `align-items: center;` | `CrossAxisAlignment.center` |
| `position: absolute;` | `Stack` + `Positioned` |
| `width: 100%;` | `double.infinity` oder `SizedBox.expand()` |
| `padding: 16px;` | `Padding(padding: EdgeInsets.all(16))` |
| `margin: 16px;` | `Container(margin: EdgeInsets.all(16))` |
| `border-radius: 12px;` | `BorderRadius.circular(12)` |
| `box-shadow: ...;` | `BoxShadow(...)` in `BoxDecoration` |
| `background: linear-gradient(...)` | `LinearGradient(...)` in `BoxDecoration` |
| `overflow: scroll;` | `SingleChildScrollView` / `ListView` |
| `@media (min-width: 600px)` | `MediaQuery.of(context).size.width > 600` |
| Container Queries | `LayoutBuilder` |

---

## 15. Zusammenfassung

| Konzept | Wann verwenden |
|---------|---------------|
| Row / Column | Lineare Anordnung (horizontal / vertikal) |
| Expanded | Kind soll verbleibenden Platz fuellen |
| Flexible | Kind darf verbleibenden Platz nutzen (muss aber nicht) |
| Stack | Widgets uebereinander stapeln |
| Wrap | Automatischer Zeilenumbruch |
| ListView.builder | Lange scrollbare Listen |
| GridView | Raster-Layout |
| Container + BoxDecoration | Styling (Farbe, Rahmen, Schatten, Gradient) |
| ThemeData | App-weites, konsistentes Design |
| MediaQuery | Bildschirm-Informationen |
| LayoutBuilder | Responsive Layout basierend auf verfuegbarem Platz |
| Slivers | Komplexe, kombinierte Scroll-Bereiche |
