# Modul 5: Flutter Einstieg & Widget-Grundlagen

## Lernziele

Nach diesem Modul kannst du:

- Die Flutter-Architektur erklaren und die Rolle von Framework, Engine und Embedder benennen
- Ein neues Flutter-Projekt erstellen und die Projektstruktur verstehen
- StatelessWidgets schreiben und den Widget-Tree aufbauen
- Grundlegende Widgets (Text, Icon, Image, Buttons, Container) einsetzen
- Hot Reload und Hot Restart zielgerichtet nutzen
- Die pubspec.yaml konfigurieren (Dependencies, Assets)

---

## 1. Was ist Flutter?

Flutter ist Googles Open-Source-UI-Toolkit zum Erstellen von nativ kompilierten Anwendungen fuer Mobile, Web und Desktop -- aus einer einzigen Codebase.

### Vergleich zu bekannten Technologien

| Aspekt | Web (JS/HTML/CSS) | Flutter |
|--------|-------------------|---------|
| Rendering | Browser DOM | Eigene Rendering-Engine (Skia/Impeller) |
| Styling | CSS | Widget-Properties und ThemeData |
| Komponenten | HTML-Elemente + React/Vue Components | Widgets |
| Layout | CSS Flexbox/Grid | Row/Column/Stack (aehnlich Flexbox) |
| Hot Reload | Webpack HMR | Flutter Hot Reload (schneller, State bleibt erhalten) |

### Die drei Schichten der Flutter-Architektur

```
┌─────────────────────────────────────────────┐
│           Framework (Dart)                   │
│  ┌─────────┬──────────┬──────────────────┐  │
│  │ Material │ Cupertino│ Widgets          │  │
│  ├─────────┴──────────┴──────────────────┤  │
│  │ Rendering                              │  │
│  ├────────────────────────────────────────┤  │
│  │ Foundation                             │  │
│  └────────────────────────────────────────┘  │
├─────────────────────────────────────────────┤
│           Engine (C/C++)                     │
│  Skia/Impeller, Dart Runtime, Text Layout   │
├─────────────────────────────────────────────┤
│           Embedder (Plattform-spezifisch)   │
│  Android, iOS, Windows, macOS, Linux, Web   │
└─────────────────────────────────────────────┘
```

**Framework (Dart):** Das ist die Schicht, in der du als Entwickler arbeitest. Sie enthaelt alle Widgets, das Material Design, das Rendering-System und die Grundlagen-Bibliothek. Alles in Dart geschrieben.

**Engine (C/C++):** Die Flutter Engine ist in C++ geschrieben und kuemmert sich um das Low-Level-Rendering mit Skia (oder dem neueren Impeller), die Dart-Laufzeitumgebung, Text-Layout und den Plattform-Channel.

**Embedder:** Der Embedder ist plattformspezifisch und stellt die Verbindung zum Betriebssystem her. Er kuemmert sich um das Fenster, den Render-Surface, Eingabegeraete und den Event-Loop.

> **C++-Hintergrund:** Die Engine ist in C++ geschrieben -- du koenntest theoretisch in den Quellcode schauen und wuerdest vieles wiedererkennen. Fuer die taegliche Arbeit ist das aber nicht noetig.

---

## 2. Alles ist ein Widget -- Der Widget-Tree

Das zentrale Konzept von Flutter: **Alles ist ein Widget.** Ein Button? Widget. Ein Padding? Widget. Ein Theme? Widget. Eine ganze Seite? Widget.

Widgets sind unveraenderliche (immutable) Beschreibungen eines Teils der Benutzeroberflaeche. Sie bilden einen Baum (Widget-Tree), aehnlich dem DOM-Tree im Web:

```
MaterialApp
  └── Scaffold
       ├── AppBar
       │    └── Text("Meine App")
       └── Center
            └── Column
                 ├── Text("Hallo Welt")
                 └── ElevatedButton
                      └── Text("Klick mich")
```

> **Web-Vergleich:** Der Widget-Tree ist vergleichbar mit dem Virtual DOM in React. Flutter baut intern drei Baeume: den Widget-Tree (Konfiguration), den Element-Tree (Instanzen) und den Render-Tree (Layout/Paint). Als Entwickler arbeitest du fast ausschliesslich mit dem Widget-Tree.

### Widgets sind immutable

Widgets werden nicht veraendert -- sie werden neu erstellt. Wenn sich etwas aendert, baut Flutter den betroffenen Teil des Widget-Trees neu auf. Das klingt teuer, ist aber extrem optimiert (aehnlich wie Reacts Reconciliation).

```dart
// Ein Widget ist eine Konfiguration, kein lebendes Objekt
// Bei jeder Aenderung wird ein neues Widget erstellt
Text(
  'Hallo',
  style: TextStyle(fontSize: 24),
)
```

---

## 3. Flutter-Projekt erstellen und Projektstruktur

### Neues Projekt erstellen

```bash
# Projekt erstellen
flutter create meine_app

# In den Projektordner wechseln
cd meine_app

# App starten
flutter run
```

Optionen bei `flutter create`:

```bash
# Mit spezifischer Organisation (fuer Package-Name)
flutter create --org com.meinefirma meine_app

# Nur bestimmte Plattformen
flutter create --platforms android,ios,web meine_app

# Leeres Projekt (ohne Counter-Beispiel)
flutter create --empty meine_app
```

### Projektstruktur

```
meine_app/
├── android/          # Android-spezifischer Code (Gradle, Manifest, etc.)
├── ios/              # iOS-spezifischer Code (Xcode-Projekt)
├── web/              # Web-spezifischer Code (index.html)
├── linux/            # Linux Desktop-Code
├── macos/            # macOS Desktop-Code
├── windows/          # Windows Desktop-Code
├── lib/              # *** DEIN DART/FLUTTER-CODE ***
│   └── main.dart     # Einstiegspunkt der App
├── test/             # Unit- und Widget-Tests
├── pubspec.yaml      # *** PROJEKT-KONFIGURATION ***
├── pubspec.lock      # Gelockte Dependency-Versionen
├── analysis_options.yaml  # Linter-Konfiguration
└── README.md
```

**Wichtig:** Dein gesamter App-Code liegt in `lib/`. Die Plattform-Ordner (android/, ios/, etc.) beruehrst du selten.

> **Vergleich zu Web-Projekten:** `pubspec.yaml` ist das Equivalent zu `package.json` in der JS-Welt. `pubspec.lock` entspricht `package-lock.json` oder `yarn.lock`.

---

## 4. MaterialApp und CupertinoApp

Jede Flutter-App beginnt mit einem Top-Level-Widget, das das Design-System festlegt:

### MaterialApp (Material Design -- Google)

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MeineApp());
}

class MeineApp extends StatelessWidget {
  const MeineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meine Erste App',
      debugShowCheckedModeBanner: false, // Entfernt das Debug-Banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MeineStartseite(),
    );
  }
}
```

### CupertinoApp (iOS-Style -- Apple)

```dart
import 'package:flutter/cupertino.dart';

void main() {
  runApp(const MeineApp());
}

class MeineApp extends StatelessWidget {
  const MeineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Meine iOS App',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: MeineStartseite(),
    );
  }
}
```

> **Tipp:** Fuer die meisten Apps ist `MaterialApp` die beste Wahl, da Material Design auf beiden Plattformen gut aussieht und mehr Widgets bietet. Du kannst trotzdem Cupertino-Widgets innerhalb einer MaterialApp verwenden.

---

## 5. Scaffold, AppBar und Body

`Scaffold` ist das Grundgeruest einer Material-Design-Seite:

```dart
class MeineStartseite extends StatelessWidget {
  const MeineStartseite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Die obere Leiste
      appBar: AppBar(
        title: const Text('Meine App'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Einstellungen oeffnen
            },
          ),
        ],
      ),

      // Der Hauptinhalt
      body: const Center(
        child: Text('Hallo Welt!'),
      ),

      // Schwebender Action-Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aktion ausfuehren
        },
        child: const Icon(Icons.add),
      ),

      // Untere Navigationsleiste
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),

      // Seitliche Schublade
      drawer: const Drawer(
        child: Center(child: Text('Drawer-Inhalt')),
      ),
    );
  }
}
```

### Scaffold-Eigenschaften im Ueberblick

| Property | Beschreibung |
|----------|-------------|
| `appBar` | Die obere App-Leiste |
| `body` | Der Hauptinhalt der Seite |
| `floatingActionButton` | Der schwebende Aktionsbutton |
| `bottomNavigationBar` | Untere Navigation |
| `drawer` | Seitliches Menue (von links) |
| `endDrawer` | Seitliches Menue (von rechts) |
| `backgroundColor` | Hintergrundfarbe |
| `bottomSheet` | Permanent sichtbares Bottom Sheet |

---

## 6. StatelessWidget: build()-Methode und BuildContext

Ein `StatelessWidget` hat keinen veraenderlichen Zustand. Es wird einmal gebaut und aendert sich nur, wenn das Eltern-Widget es neu erstellt.

### Aufbau eines StatelessWidget

```dart
class Begruessung extends StatelessWidget {
  // Konstruktor mit Key-Parameter
  const Begruessung({
    super.key,
    required this.name,
    this.schriftgroesse = 24.0,
  });

  // Properties sind final (immutable)
  final String name;
  final double schriftgroesse;

  // Die build-Methode beschreibt das UI
  @override
  Widget build(BuildContext context) {
    return Text(
      'Hallo, $name!',
      style: TextStyle(fontSize: schriftgroesse),
    );
  }
}

// Verwendung:
const Begruessung(name: 'Max')
Begruessung(name: 'Anna', schriftgroesse: 32.0)
```

### BuildContext

Der `BuildContext` ist die Position des Widgets im Widget-Tree. Er wird gebraucht, um:

- Auf das Theme zuzugreifen: `Theme.of(context)`
- Die Bildschirmgroesse abzufragen: `MediaQuery.of(context)`
- Zu navigieren: `Navigator.of(context)`
- Snackbars anzuzeigen: `ScaffoldMessenger.of(context)`

```dart
@override
Widget build(BuildContext context) {
  // Theme-Farbe ueber den Context abrufen
  final farbe = Theme.of(context).colorScheme.primary;

  // Bildschirmbreite abfragen
  final breite = MediaQuery.of(context).size.width;

  return Container(
    width: breite * 0.8, // 80% der Bildschirmbreite
    color: farbe,
    child: const Text('Themed Container'),
  );
}
```

> **React-Vergleich:** `BuildContext` ist vergleichbar mit dem Context-Konzept in React (`useContext`). Es ermoeglicht Widgets, auf Daten von weiter oben im Baum zuzugreifen, ohne sie explizit durchreichen zu muessen.

### Das const-Schluesselwort bei Widgets

```dart
// CONST: Widget wird zur Compile-Zeit erstellt (effizienter)
const Text('Statischer Text')

// NICHT const: Widget wird zur Laufzeit erstellt
Text('Dynamischer Text: $variable')

// const-Konstruktor im eigenen Widget
class MeinWidget extends StatelessWidget {
  const MeinWidget({super.key}); // const-Konstruktor

  @override
  Widget build(BuildContext context) {
    return const Text('Fest'); // Inhalt auch const
  }
}
```

> **Tipp:** Verwende `const` wo immer moeglich. Der Dart-Analyzer (und deine IDE) schlaegt es dir auch vor. const-Widgets werden vom Framework bei Rebuilds uebersprungen.

---

## 7. Grundlegende Widgets

### Text

```dart
// Einfacher Text
const Text('Hallo Welt')

// Text mit Styling
Text(
  'Gestylter Text',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
    letterSpacing: 2.0,
    fontStyle: FontStyle.italic,
    decoration: TextDecoration.underline,
    decorationColor: Colors.red,
    decorationStyle: TextDecorationStyle.wavy,
  ),
)

// Text mit Theme-Style
Text(
  'Ueberschrift',
  style: Theme.of(context).textTheme.headlineMedium,
)

// Mehrzeiliger Text mit Overflow
Text(
  'Ein sehr langer Text, der moeglicherweise nicht in eine Zeile passt...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis, // ... am Ende
  textAlign: TextAlign.center,
)

// Rich Text (verschiedene Styles in einem Text)
RichText(
  text: TextSpan(
    text: 'Hallo ',
    style: DefaultTextStyle.of(context).style,
    children: const [
      TextSpan(
        text: 'fette',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: ' Welt!'),
    ],
  ),
)

// Alternative: Text.rich
Text.rich(
  TextSpan(
    text: 'Preis: ',
    children: [
      TextSpan(
        text: '29,99 EUR',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
      ),
    ],
  ),
)
```

### Icon

```dart
// Einfaches Icon
const Icon(Icons.favorite)

// Icon mit Anpassungen
Icon(
  Icons.star,
  size: 48.0,
  color: Colors.amber,
)

// Alle verfuegbaren Icons: https://fonts.google.com/icons
// Einige haeufig verwendete:
const Icon(Icons.home)
const Icon(Icons.settings)
const Icon(Icons.person)
const Icon(Icons.search)
const Icon(Icons.add)
const Icon(Icons.delete)
const Icon(Icons.edit)
const Icon(Icons.email)
const Icon(Icons.phone)
const Icon(Icons.location_on)
```

### Image

```dart
// Bild aus dem Netzwerk
Image.network(
  'https://picsum.photos/200/300',
  width: 200,
  height: 300,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return const CircularProgressIndicator();
  },
  errorBuilder: (context, error, stackTrace) {
    return const Icon(Icons.error);
  },
)

// Bild aus Assets (lokal)
// Zuerst in pubspec.yaml registrieren (siehe Abschnitt 11)
Image.asset(
  'assets/images/mein_bild.png',
  width: 150,
  height: 150,
  fit: BoxFit.contain,
)

// Rundes Profilbild mit CircleAvatar
CircleAvatar(
  radius: 50,
  backgroundImage: NetworkImage('https://picsum.photos/200'),
  backgroundColor: Colors.grey,
  child: const Text('MN'), // Fallback wenn kein Bild
)

// BoxFit-Optionen:
// BoxFit.cover    - Fuellt den Bereich, schneidet ggf. ab
// BoxFit.contain  - Passt komplett rein, ggf. mit Raendern
// BoxFit.fill     - Streckt/staucht auf exakte Groesse
// BoxFit.fitWidth - Breite passt, Hoehe ggf. abgeschnitten
// BoxFit.fitHeight - Hoehe passt, Breite ggf. abgeschnitten
// BoxFit.none     - Keine Skalierung

// ClipRRect fuer abgerundete Ecken bei Bildern
ClipRRect(
  borderRadius: BorderRadius.circular(16),
  child: Image.network(
    'https://picsum.photos/200',
    width: 200,
    height: 200,
    fit: BoxFit.cover,
  ),
)
```

### Buttons

```dart
// ElevatedButton (hervorgehobener Button mit Schatten)
ElevatedButton(
  onPressed: () {
    print('Gedrueckt!');
  },
  child: const Text('Elevated Button'),
)

// ElevatedButton mit Styling
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.blue,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 4,
  ),
  child: const Text('Gestylter Button'),
)

// ElevatedButton mit Icon
ElevatedButton.icon(
  onPressed: () {},
  icon: const Icon(Icons.send),
  label: const Text('Senden'),
)

// TextButton (flacher Button ohne Schatten)
TextButton(
  onPressed: () {},
  child: const Text('Text Button'),
)

// OutlinedButton (Button mit Rahmen)
OutlinedButton(
  onPressed: () {},
  child: const Text('Outlined Button'),
)

// IconButton (nur ein Icon als Button)
IconButton(
  onPressed: () {},
  icon: const Icon(Icons.favorite),
  color: Colors.red,
  iconSize: 32,
  tooltip: 'Favorit',
)

// FloatingActionButton (schwebender runder Button)
FloatingActionButton(
  onPressed: () {},
  child: const Icon(Icons.add),
)

// FloatingActionButton erweitert (mit Text)
FloatingActionButton.extended(
  onPressed: () {},
  icon: const Icon(Icons.add),
  label: const Text('Hinzufuegen'),
)

// Deaktivierter Button (onPressed: null)
ElevatedButton(
  onPressed: null, // Button ist ausgegraut und nicht klickbar
  child: const Text('Deaktiviert'),
)
```

---

## 8. Container, SizedBox und Card

### Container

`Container` ist eines der vielseitigsten Widgets. Es kombiniert Groesse, Padding, Margin, Dekoration und mehr:

```dart
Container(
  width: 200,
  height: 100,
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  decoration: BoxDecoration(
    color: Colors.blue.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.blue, width: 2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 8,
        offset: const Offset(2, 4),
      ),
    ],
  ),
  child: const Text('Ich bin ein Container'),
)

// Container mit Farbverlauf
Container(
  width: double.infinity,
  height: 200,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
  child: const Center(
    child: Text(
      'Gradient!',
      style: TextStyle(color: Colors.white, fontSize: 32),
    ),
  ),
)
```

> **CSS-Vergleich:** `Container` vereint viele CSS-Eigenschaften in einem Widget: `width`, `height`, `padding`, `margin`, `background-color`, `border`, `border-radius`, `box-shadow`. In Flutter sind das alles Widget-Properties statt CSS-Regeln.

### SizedBox

`SizedBox` gibt einem Widget eine feste Groesse oder dient als Abstandhalter:

```dart
// Als Abstandhalter (haeufigster Einsatz)
Column(
  children: const [
    Text('Erster Text'),
    SizedBox(height: 16), // Vertikaler Abstand
    Text('Zweiter Text'),
  ],
)

Row(
  children: const [
    Icon(Icons.star),
    SizedBox(width: 8), // Horizontaler Abstand
    Text('Stern'),
  ],
)

// Feste Groesse erzwingen
SizedBox(
  width: 100,
  height: 50,
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('Fix'),
  ),
)

// Maximale Groesse (fuellt den verfuegbaren Platz)
SizedBox.expand(
  child: Container(color: Colors.red),
)
```

### Card

`Card` ist ein Material-Design-Widget mit abgerundeten Ecken und Schatten:

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Text(
          'Kartentitel',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text('Dies ist der Inhalt der Karte.'),
      ],
    ),
  ),
)

// Card mit ListTile (haeufige Kombination)
Card(
  child: ListTile(
    leading: const CircleAvatar(child: Text('A')),
    title: const Text('Anna Mueller'),
    subtitle: const Text('Flutter-Entwicklerin'),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      // Navigation oder Aktion
    },
  ),
)
```

---

## 9. Hot Reload vs. Hot Restart

Eines der staerksten Features von Flutter ist der **Hot Reload**. Er macht die Entwicklung extrem schnell.

### Hot Reload (Strg+S / Cmd+S oder `r` im Terminal)

- Injiziert geaenderten Quellcode in die laufende Dart VM
- **State bleibt erhalten!** (z.B. Scroll-Position, eingegebener Text)
- Dauert unter 1 Sekunde
- Funktioniert bei: Widget-Aenderungen, Styling, Layout

```
Szenario: Du aenderst die Farbe eines Buttons von blau zu rot.
→ Hot Reload: Button wird sofort rot, alles andere bleibt.
→ Keine App-Neustart noetig!
```

### Hot Restart (`R` im Terminal oder Restart-Button)

- Startet die App komplett neu
- **State geht verloren** (alles wird zurueckgesetzt)
- Dauert einige Sekunden
- Noetig bei: Aenderungen an `main()`, globalen Variablen, StatefulWidget-State-Initialisierung

### Wann wird ein voller Neustart benoetigt?

- Aenderungen an nativen Plugins
- Aenderungen in `pubspec.yaml` (neue Dependencies)
- Aenderungen an nativem Code (android/, ios/)

### Vergleich zu Web-Development

| Feature | Web (Webpack HMR) | Flutter Hot Reload |
|---------|-------------------|-------------------|
| Geschwindigkeit | 1-5 Sekunden | < 1 Sekunde |
| State-Erhalt | Teilweise (mit HMR) | Ja (zuverlaessig) |
| Funktioniert bei | Komponentenaenderungen | Widget-Aenderungen |
| Einschraenkungen | Manche Aenderungen brauchen Refresh | State-Initialisierung braucht Hot Restart |

---

## 10. pubspec.yaml: Dependencies und Assets

Die `pubspec.yaml` ist die zentrale Konfigurationsdatei deines Flutter-Projekts:

```yaml
name: meine_app
description: Eine tolle Flutter App.
publish_to: 'none'      # Nicht auf pub.dev veroeffentlichen
version: 1.0.0+1        # Version + Build-Nummer

environment:
  sdk: ^3.6.0           # Minimum Dart SDK Version

# Dependencies (Produktions-Pakete)
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8    # iOS-Icons
  http: ^1.3.0               # HTTP-Requests
  google_fonts: ^6.2.1       # Google Fonts

# Entwicklungs-Dependencies (nur fuer Tests etc.)
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

# Flutter-spezifische Konfiguration
flutter:
  uses-material-design: true  # Material Icons aktivieren

  # Assets (Bilder, Dateien, etc.)
  assets:
    - assets/images/           # Ganzer Ordner
    - assets/images/logo.png   # Einzelne Datei
    - assets/data/config.json

  # Schriftarten
  fonts:
    - family: MeineSchrift
      fonts:
        - asset: assets/fonts/MeineSchrift-Regular.ttf
        - asset: assets/fonts/MeineSchrift-Bold.ttf
          weight: 700
```

### Dependencies installieren

```bash
# Neue Dependency hinzufuegen (empfohlen)
flutter pub add http

# Oder manuell in pubspec.yaml eintragen, dann:
flutter pub get

# Dependency entfernen
flutter pub remove http

# Alle Dependencies aktualisieren
flutter pub upgrade

# Veraltete Dependencies anzeigen
flutter pub outdated
```

> **npm-Vergleich:** `flutter pub add` = `npm install`, `flutter pub get` = `npm install` (nach manueller Aenderung), `pub.dev` = `npmjs.com`.

### Assets verwenden

1. Erstelle den Ordner `assets/images/` im Projektstammverzeichnis
2. Lege deine Bilder dort ab
3. Registriere sie in `pubspec.yaml` (siehe oben)
4. Verwende sie im Code:

```dart
Image.asset('assets/images/logo.png')
```

---

## 11. Zusammenfassendes Beispiel: Erste vollstaendige App

Hier ein komplettes Beispiel, das alle bisher gelernten Konzepte zusammenfuehrt:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MeineApp());
}

class MeineApp extends StatelessWidget {
  const MeineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Widget-Galerie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const WidgetGalerie(),
    );
  }
}

class WidgetGalerie extends StatelessWidget {
  const WidgetGalerie({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget-Galerie'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ueberschrift
            Text(
              'Grundlegende Widgets',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),

            // Profil-Bereich
            const ProfilKarte(),
            const SizedBox(height: 16),

            // Button-Galerie
            const ButtonGalerie(),
            const SizedBox(height: 16),

            // Info-Karte
            const InfoKarte(
              titel: 'Flutter ist toll',
              beschreibung:
                  'Mit Flutter kannst du native Apps fuer '
                  'mehrere Plattformen aus einer Codebase erstellen.',
              icon: Icons.flutter_dash,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('FAB gedrueckt!')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Eigenes Widget: Profilkarte
class ProfilKarte extends StatelessWidget {
  const ProfilKarte({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Text(
                'MN',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Max Mustermann',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Flutter-Entwickler',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Eigenes Widget: Button-Galerie
class ButtonGalerie extends StatelessWidget {
  const ButtonGalerie({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buttons',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Elevated'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Text'),
                ),
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Outlined'),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.favorite),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send),
                  label: const Text('Mit Icon'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Eigenes Widget: Info-Karte (mit Parametern)
class InfoKarte extends StatelessWidget {
  const InfoKarte({
    super.key,
    required this.titel,
    required this.beschreibung,
    required this.icon,
  });

  final String titel;
  final String beschreibung;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    beschreibung,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 12. Zusammenfassung und Merkregeln

| Konzept | Merke dir |
|---------|-----------|
| Widget-Tree | Alles ist ein Widget. Widgets sind immutable. |
| StatelessWidget | Kein eigener State. `build()` beschreibt das UI. |
| BuildContext | Position im Baum. Zugang zu Theme, MediaQuery, Navigator. |
| const | Nutze `const` wo moeglich fuer bessere Performance. |
| Container | Das "Schweizer Taschenmesser" -- Groesse, Padding, Dekoration. |
| SizedBox | Feste Groesse oder Abstandhalter. |
| Card | Material-Karte mit Schatten und abgerundeten Ecken. |
| Hot Reload | Strg+S, State bleibt, < 1 Sekunde. |
| pubspec.yaml | Dependencies, Assets, Fonts konfigurieren. |

### Haeufige Fehler von Anfaengern

1. **Vergessene `const`-Keywords:** IDE-Warnungen beachten
2. **Assets nicht in pubspec.yaml registriert:** `Image.asset()` braucht pubspec-Eintrag
3. **Zu viel in einem Widget:** Extrahiere eigene Widgets fuer Lesbarkeit
4. **Container statt SizedBox fuer Abstaende:** `SizedBox` ist leichtgewichtiger
5. **Hot Reload statt Hot Restart bei State-Aenderungen:** Wenn sich Initialisierungslogik aendert, brauchst du Hot Restart
