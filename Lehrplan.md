# Dart & Flutter Lehrplan -- 4 Wochen

> **Zielgruppe:** Entwickler mit Vorkenntnissen in C++, JavaScript/HTML/CSS und Python.
> Grundlegende Programmierkonzepte (Variablen, Schleifen, Funktionen, OOP-Basics) werden als bekannt vorausgesetzt.

---

## Wochenübersicht

| Woche | Schwerpunkt | Module |
|-------|------------|--------|
| **1** | Dart -- Die Sprache | Module 1--4 |
| **2** | Flutter -- Grundlagen | Module 5--8 |
| **3** | Flutter -- Fortgeschritten | Module 9--12 |
| **4** | Profi-Themen & Projekt | Module 13--16 |

---

## Woche 1 -- Dart: Die Sprache

In der ersten Woche lernst du Dart als Sprache kennen. Da du bereits C++, JS und Python beherrschst, wirst du viele Konzepte wiedererkennen. Der Fokus liegt auf den Dart-spezifischen Eigenheiten.

### Modul 1: Dart Syntax & Grundlagen (Tag 1--2)

**Themen:** Typsystem, Variablen (`var`, `final`, `const`, `late`), Funktionen (Named/Positional Parameters, Arrow-Syntax), Kontrollstrukturen, String-Interpolation, Type Inference.

- [Lehrstoff](woche_1/01_dart_grundlagen/lehrstoff.md)
- [Ressourcen](woche_1/01_dart_grundlagen/ressourcen.md)
- [Übung](woche_1/01_dart_grundlagen/uebung.md)
- [Lösung](woche_1/01_dart_grundlagen/loesung.md)

### Modul 2: OOP in Dart (Tag 3--4)

**Themen:** Klassen, Konstruktoren (Named, Factory, Redirecting), Vererbung, `abstract class`, `interface` (implizit), Mixins (`with`), Extension Methods, Enums (enhanced Enums), Operator-Overloading.

- [Lehrstoff](woche_1/02_oop_in_dart/lehrstoff.md)
- [Ressourcen](woche_1/02_oop_in_dart/ressourcen.md)
- [Übung](woche_1/02_oop_in_dart/uebung.md)
- [Lösung](woche_1/02_oop_in_dart/loesung.md)

### Modul 3: Asynchrone Programmierung (Tag 5)

**Themen:** `Future`, `async`/`await`, `Stream`, `StreamController`, `yield`/`yield*`, Error-Handling bei asynchronem Code, `Completer`.

- [Lehrstoff](woche_1/03_async_programmierung/lehrstoff.md)
- [Ressourcen](woche_1/03_async_programmierung/ressourcen.md)
- [Übung](woche_1/03_async_programmierung/uebung.md)
- [Lösung](woche_1/03_async_programmierung/loesung.md)

### Modul 4: Collections, Generics & Null Safety (Tag 6--7)

**Themen:** `List`, `Map`, `Set`, Collection-Methoden (`map`, `where`, `fold`, `expand`), Spread-Operator, Collection-if/for, Generics, Sound Null Safety (`?`, `!`, `??`, `?.`, `late`), Pattern Matching (Dart 3), Records, Sealed Classes.

- [Lehrstoff](woche_1/04_collections_generics_null_safety/lehrstoff.md)
- [Ressourcen](woche_1/04_collections_generics_null_safety/ressourcen.md)
- [Übung](woche_1/04_collections_generics_null_safety/uebung.md)
- [Lösung](woche_1/04_collections_generics_null_safety/loesung.md)

---

## Woche 2 -- Flutter: Grundlagen

Ab jetzt arbeitest du mit Flutter. Du lernst das Widget-Konzept, Layouts und Navigation.

### Modul 5: Flutter Einstieg & Widget-Grundlagen (Tag 1--2)

**Themen:** Flutter-Architektur, Widget-Tree, `StatelessWidget`, `BuildContext`, `MaterialApp`, `Scaffold`, `AppBar`, `Text`, `Icon`, `Image`, `ElevatedButton`, Hot Reload vs. Hot Restart.

- [Lehrstoff](woche_2/05_flutter_einstieg_widgets/lehrstoff.md)
- [Ressourcen](woche_2/05_flutter_einstieg_widgets/ressourcen.md)
- [Übung](woche_2/05_flutter_einstieg_widgets/uebung.md)
- [Lösung](woche_2/05_flutter_einstieg_widgets/loesung.md)

### Modul 6: StatefulWidgets & State (Tag 3--4)

**Themen:** `StatefulWidget`, `State<T>`, `setState()`, Widget-Lifecycle (`initState`, `dispose`, `didUpdateWidget`, `didChangeDependencies`), `Key`-Konzept, `GlobalKey`.

- [Lehrstoff](woche_2/06_stateful_widgets_state/lehrstoff.md)
- [Ressourcen](woche_2/06_stateful_widgets_state/ressourcen.md)
- [Übung](woche_2/06_stateful_widgets_state/uebung.md)
- [Lösung](woche_2/06_stateful_widgets_state/loesung.md)

### Modul 7: Layouts & Styling (Tag 5)

**Themen:** `Row`, `Column`, `Stack`, `Expanded`, `Flexible`, `SizedBox`, `Container`, `Padding`, `Align`, `ListView`, `GridView`, `SingleChildScrollView`, `ThemeData`, `TextStyle`, `BoxDecoration`, `MediaQuery`, Responsive Design.

- [Lehrstoff](woche_2/07_layouts_und_styling/lehrstoff.md)
- [Ressourcen](woche_2/07_layouts_und_styling/ressourcen.md)
- [Übung](woche_2/07_layouts_und_styling/uebung.md)
- [Lösung](woche_2/07_layouts_und_styling/loesung.md)

### Modul 8: Navigation & Routing (Tag 6--7)

**Themen:** `Navigator.push`/`pop`, Named Routes, `onGenerateRoute`, `go_router` Package, Datenübergabe zwischen Screens, Deep Linking, `WillPopScope` / `PopScope`.

- [Lehrstoff](woche_2/08_navigation_und_routing/lehrstoff.md)
- [Ressourcen](woche_2/08_navigation_und_routing/ressourcen.md)
- [Übung](woche_2/08_navigation_und_routing/uebung.md)
- [Lösung](woche_2/08_navigation_und_routing/loesung.md)

---

## Woche 3 -- Flutter: Fortgeschritten

Diese Woche behandelt State Management, API-Anbindung, lokale Datenhaltung und Formulare.

### Modul 9: State Management mit Provider (Tag 1--2)

**Themen:** Warum State Management?, `InheritedWidget` (Konzept), `provider` Package, `ChangeNotifier`, `ChangeNotifierProvider`, `Consumer`, `Selector`, `MultiProvider`, Einführung in Riverpod (Ausblick).

- [Lehrstoff](woche_3/09_state_management/lehrstoff.md)
- [Ressourcen](woche_3/09_state_management/ressourcen.md)
- [Übung](woche_3/09_state_management/uebung.md)
- [Lösung](woche_3/09_state_management/loesung.md)

### Modul 10: HTTP, REST-APIs & JSON (Tag 3--4)

**Themen:** `http` Package, GET/POST/PUT/DELETE Requests, JSON-Serialisierung (`dart:convert`), Model-Klassen mit `fromJson`/`toJson`, `FutureBuilder`, Error Handling, `json_serializable` (Code-Generierung).

- [Lehrstoff](woche_3/10_http_rest_apis/lehrstoff.md)
- [Ressourcen](woche_3/10_http_rest_apis/ressourcen.md)
- [Übung](woche_3/10_http_rest_apis/uebung.md)
- [Lösung](woche_3/10_http_rest_apis/loesung.md)

### Modul 11: Lokale Datenspeicherung (Tag 5)

**Themen:** `shared_preferences` (Key-Value), `sqflite` (SQLite-Datenbank), `hive` (NoSQL), Datei-I/O mit `path_provider`, Vergleich der Ansätze.

- [Lehrstoff](woche_3/11_lokale_datenspeicherung/lehrstoff.md)
- [Ressourcen](woche_3/11_lokale_datenspeicherung/ressourcen.md)
- [Übung](woche_3/11_lokale_datenspeicherung/uebung.md)
- [Lösung](woche_3/11_lokale_datenspeicherung/loesung.md)

### Modul 12: Formulare & Validierung (Tag 6--7)

**Themen:** `Form`, `GlobalKey<FormState>`, `TextFormField`, Validatoren, `InputDecoration`, `DropdownButtonFormField`, `DatePicker`, `TimePicker`, Custom Form Fields, Debouncing.

- [Lehrstoff](woche_3/12_formulare_und_validierung/lehrstoff.md)
- [Ressourcen](woche_3/12_formulare_und_validierung/ressourcen.md)
- [Übung](woche_3/12_formulare_und_validierung/uebung.md)
- [Lösung](woche_3/12_formulare_und_validierung/loesung.md)

---

## Woche 4 -- Profi-Themen & Abschlussprojekt

Die letzte Woche deckt fortgeschrittene Themen ab und endet mit einem Abschlussprojekt, das alles Gelernte zusammenführt.

### Modul 13: Animationen (Tag 1)

**Themen:** Implizite Animationen (`AnimatedContainer`, `AnimatedOpacity`), Explizite Animationen (`AnimationController`, `Tween`, `CurvedAnimation`), `Hero`-Animationen, `AnimatedList`, `Lottie`-Animationen.

- [Lehrstoff](woche_4/13_animationen/lehrstoff.md)
- [Ressourcen](woche_4/13_animationen/ressourcen.md)
- [Übung](woche_4/13_animationen/uebung.md)
- [Lösung](woche_4/13_animationen/loesung.md)

### Modul 14: Testing (Tag 2)

**Themen:** Unit Tests (`test` Package), Widget Tests (`flutter_test`), Mocking (`mocktail`), Integration Tests, Code Coverage, Test-Driven Development (TDD) Grundlagen.

- [Lehrstoff](woche_4/14_testing/lehrstoff.md)
- [Ressourcen](woche_4/14_testing/ressourcen.md)
- [Übung](woche_4/14_testing/uebung.md)
- [Lösung](woche_4/14_testing/loesung.md)

### Modul 15: Packages, Plugins & Plattformintegration (Tag 3)

**Themen:** pub.dev, eigene Packages erstellen, Platform Channels (MethodChannel), Plattform-spezifischer Code (`Platform`, `kIsWeb`), Permissions, App-Icons & Splash Screens, Build & Release (Android/iOS).

- [Lehrstoff](woche_4/15_packages_und_plattform/lehrstoff.md)
- [Ressourcen](woche_4/15_packages_und_plattform/ressourcen.md)
- [Übung](woche_4/15_packages_und_plattform/uebung.md)
- [Lösung](woche_4/15_packages_und_plattform/loesung.md)

### Modul 16: Abschlussprojekt (Tag 4--7)

**Projekt:** Eine vollständige App (z.B. eine Notiz-App mit Cloud-Sync oder eine Wetter-App), die alle gelernten Konzepte vereint: State Management, API-Anbindung, lokale Speicherung, Navigation, Formulare, Animationen und Tests.

- [Projektbeschreibung](woche_4/16_abschlussprojekt/lehrstoff.md)
- [Ressourcen](woche_4/16_abschlussprojekt/ressourcen.md)
- [Aufgabenstellung](woche_4/16_abschlussprojekt/uebung.md)
- [Referenzlösung](woche_4/16_abschlussprojekt/loesung.md)

---

## Täglicher Zeitplan (Empfehlung)

| Block | Dauer | Inhalt |
|-------|-------|--------|
| Theorie | 1--2 h | Lehrstoff lesen, Code-Beispiele nachvollziehen |
| Praxis | 2--3 h | Übung bearbeiten |
| Vertiefung | 1 h | Ressourcen studieren, experimentieren |
| Review | 30 min | Lösung vergleichen, Notizen machen |

---

## Empfohlene Werkzeuge

- **IDE:** VS Code mit Dart & Flutter Extensions oder Android Studio
- **Dart Playground:** [DartPad](https://dartpad.dev) -- ideal für Woche 1
- **Emulator:** Android Emulator oder iOS Simulator
- **Versionskontrolle:** Git (kannst du ja schon)
- **Terminal:** Flutter CLI (`flutter doctor`, `flutter create`, `flutter run`)

---

## Voraussetzungen installieren

```bash
# Flutter SDK installieren (siehe https://docs.flutter.dev/get-started/install)
# Danach prüfen:
flutter doctor

# Neues Projekt erstellen:
flutter create mein_projekt
cd mein_projekt
flutter run
```

---

> **Tipp:** Nutze DartPad (https://dartpad.dev) für die Dart-Übungen in Woche 1. Ab Woche 2 arbeitest du mit echten Flutter-Projekten in deiner IDE.
