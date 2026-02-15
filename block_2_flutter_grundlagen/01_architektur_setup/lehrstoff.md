# Einheit 2.1: Flutter Architektur & Setup

> **Dauer:** 2 Stunden | **Voraussetzungen:** Block 1 (Dart)

---

## 1.1 Was ist Flutter?

Flutter ist Googles UI-Toolkit für plattformübergreifende Apps aus einer Codebasis:

- **Mobile:** Android, iOS
- **Desktop:** Windows, macOS, Linux
- **Web:** Browser-Apps

### Architektur

```
┌─────────────────────────────────────┐
│           Deine App (Dart)          │
├─────────────────────────────────────┤
│         Flutter Framework           │
│   (Widgets, Rendering, Animation)   │
├─────────────────────────────────────┤
│           Flutter Engine            │
│      (Skia, Dart Runtime, Text)     │
├─────────────────────────────────────┤
│        Platform Embedder            │
│   (Android, iOS, Windows, etc.)     │
└─────────────────────────────────────┘
```

---

## 1.2 Installation prüfen

```bash
# Flutter-Installation prüfen
flutter doctor

# Erwartete Ausgabe:
# [✓] Flutter (Channel stable, 3.x.x)
# [✓] Android toolchain
# [✓] Chrome - develop for the web
# [✓] Android Studio
# [✓] VS Code
```

---

## 1.3 Erstes Projekt erstellen

```bash
# Neues Projekt
flutter create meine_app
cd meine_app

# App starten
flutter run

# Oder spezifisches Gerät
flutter devices          # Verfügbare Geräte anzeigen
flutter run -d chrome    # Im Browser
flutter run -d android   # Android Emulator
```

---

## 1.4 Projektstruktur

```
meine_app/
├── lib/
│   └── main.dart         # Einstiegspunkt
├── test/                  # Tests
├── android/               # Android-spezifisch
├── ios/                   # iOS-spezifisch
├── web/                   # Web-spezifisch
├── pubspec.yaml           # Dependencies & Assets
└── pubspec.lock           # Lock-Datei
```

---

## 1.5 main.dart verstehen

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
      title: 'Meine App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const StartSeite(),
    );
  }
}

class StartSeite extends StatelessWidget {
  const StartSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startseite'),
      ),
      body: const Center(
        child: Text('Hallo Flutter!'),
      ),
    );
  }
}
```

---

## 1.6 Widget-Tree

Alles in Flutter ist ein **Widget**. Widgets bilden einen Baum:

```
MaterialApp
└── Scaffold
    ├── AppBar
    │   └── Text
    └── Center
        └── Text
```

---

## 1.7 Hot Reload vs. Hot Restart

| Feature | Hot Reload | Hot Restart |
|---------|------------|-------------|
| Shortcut | `r` | `R` |
| Geschwindigkeit | Sehr schnell | Schnell |
| State erhalten | Ja | Nein |
| Wann nutzen | UI-Änderungen | State-Änderungen |

```bash
# In der Konsole während flutter run:
r  # Hot Reload
R  # Hot Restart
q  # Beenden
```

---

## 1.8 pubspec.yaml

```yaml
name: meine_app
description: Meine erste Flutter-App
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  # Externe Packages hier hinzufügen
  # http: ^1.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  # Assets hier deklarieren
  # assets:
  #   - assets/images/
```

---

## 1.9 Packages installieren

```bash
# Package hinzufügen
flutter pub add http

# Dependencies installieren
flutter pub get

# Outdated packages prüfen
flutter pub outdated

# Upgrade
flutter pub upgrade
```

---

## 1.10 DevTools

```bash
# DevTools öffnen
flutter pub global activate devtools
flutter pub global run devtools

# Oder über VS Code / Android Studio
```

**DevTools bieten:**
- Widget Inspector
- Performance Profiling
- Memory Analysis
- Network Monitoring
