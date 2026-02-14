# Dart & Flutter Lehrplan

> **Zielgruppe:** Entwickler mit Vorkenntnissen in C++, JavaScript/HTML/CSS und Python.
> Grundlegende Programmierkonzepte (Variablen, Schleifen, Funktionen, OOP-Basics) werden als bekannt vorausgesetzt.

> **Zeitaufwand:** 2 Stunden pro Lerneinheit. Insgesamt 44 Lerneinheiten (~88 Stunden).

---

## Übersicht

| Block | Schwerpunkt | Lerneinheiten | Zeitraum |
|-------|-------------|---------------|----------|
| **1** | Dart -- Die Sprache | 10 Einheiten | ~2 Wochen |
| **2** | Flutter -- Grundlagen | 10 Einheiten | ~2 Wochen |
| **3** | Flutter -- Fortgeschritten | 12 Einheiten | ~2,5 Wochen |
| **4** | Profi-Themen & Projekt | 12 Einheiten | ~2,5 Wochen |

---

## Block 1 -- Dart: Die Sprache

In diesem Block lernst du Dart als Sprache kennen. Da du bereits C++, JS und Python beherrschst, wirst du viele Konzepte wiedererkennen. Der Fokus liegt auf den Dart-spezifischen Eigenheiten.

### Einheit 1.1: Dart Syntax & Typsystem (2h)

**Themen:** Dart-Überblick, Typsystem, Variablen (`var`, `final`, `const`, `late`), Type Inference, String-Interpolation, `num`, `int`, `double`, `bool`, `String`.

- [Lehrstoff](block_1_dart/01_syntax_typsystem/lehrstoff.md)
- [Ressourcen](block_1_dart/01_syntax_typsystem/ressourcen.md)
- [Übung](block_1_dart/01_syntax_typsystem/uebung.md)
- [Lösung](block_1_dart/01_syntax_typsystem/loesung.md)

### Einheit 1.2: Funktionen & Kontrollstrukturen (2h)

**Themen:** Funktionen (Named/Positional Parameters, Default Values), Arrow-Syntax, Kontrollstrukturen (`if`, `switch`, `for`, `while`), Ternary Operator.

- [Lehrstoff](block_1_dart/02_funktionen_kontrollstrukturen/lehrstoff.md)
- [Ressourcen](block_1_dart/02_funktionen_kontrollstrukturen/ressourcen.md)
- [Übung](block_1_dart/02_funktionen_kontrollstrukturen/uebung.md)
- [Lösung](block_1_dart/02_funktionen_kontrollstrukturen/loesung.md)

### Einheit 1.3: Klassen & Konstruktoren (2h)

**Themen:** Klassen, Properties, Methoden, Konstruktoren (Standard, Named, Factory, Redirecting), `this`-Keyword, Initializer Lists.

- [Lehrstoff](block_1_dart/03_klassen_konstruktoren/lehrstoff.md)
- [Ressourcen](block_1_dart/03_klassen_konstruktoren/ressourcen.md)
- [Übung](block_1_dart/03_klassen_konstruktoren/uebung.md)
- [Lösung](block_1_dart/03_klassen_konstruktoren/loesung.md)

### Einheit 1.4: Vererbung & Interfaces (2h)

**Themen:** Vererbung (`extends`), `super`, Abstract Classes, Interfaces (implizit in Dart), `implements`, Operator-Overloading.

- [Lehrstoff](block_1_dart/04_vererbung_interfaces/lehrstoff.md)
- [Ressourcen](block_1_dart/04_vererbung_interfaces/ressourcen.md)
- [Übung](block_1_dart/04_vererbung_interfaces/uebung.md)
- [Lösung](block_1_dart/04_vererbung_interfaces/loesung.md)

### Einheit 1.5: Mixins & Extensions (2h)

**Themen:** Mixins (`with`), Wann Mixins vs. Vererbung, Extension Methods, Enhanced Enums (Dart 3).

- [Lehrstoff](block_1_dart/05_mixins_extensions/lehrstoff.md)
- [Ressourcen](block_1_dart/05_mixins_extensions/ressourcen.md)
- [Übung](block_1_dart/05_mixins_extensions/uebung.md)
- [Lösung](block_1_dart/05_mixins_extensions/loesung.md)

### Einheit 1.6: Futures & async/await (2h)

**Themen:** `Future`, `async`/`await`, `then`/`catchError`, Error-Handling, `Completer`, parallele Futures mit `Future.wait`.

- [Lehrstoff](block_1_dart/06_futures_async/lehrstoff.md)
- [Ressourcen](block_1_dart/06_futures_async/ressourcen.md)
- [Übung](block_1_dart/06_futures_async/uebung.md)
- [Lösung](block_1_dart/06_futures_async/loesung.md)

### Einheit 1.7: Streams (2h)

**Themen:** `Stream`, `StreamController`, `listen`, `yield`/`yield*`, Stream-Transformationen, Broadcast vs. Single-Subscription Streams.

- [Lehrstoff](block_1_dart/07_streams/lehrstoff.md)
- [Ressourcen](block_1_dart/07_streams/ressourcen.md)
- [Übung](block_1_dart/07_streams/uebung.md)
- [Lösung](block_1_dart/07_streams/loesung.md)

### Einheit 1.8: Collections (2h)

**Themen:** `List`, `Map`, `Set`, Collection-Methoden (`map`, `where`, `fold`, `expand`, `reduce`), Spread-Operator, Collection-if/for.

- [Lehrstoff](block_1_dart/08_collections/lehrstoff.md)
- [Ressourcen](block_1_dart/08_collections/ressourcen.md)
- [Übung](block_1_dart/08_collections/uebung.md)
- [Lösung](block_1_dart/08_collections/loesung.md)

### Einheit 1.9: Generics & Null Safety (2h)

**Themen:** Generics, Type Constraints, Sound Null Safety (`?`, `!`, `??`, `?.`, `late`), Null-aware Operators.

- [Lehrstoff](block_1_dart/09_generics_null_safety/lehrstoff.md)
- [Ressourcen](block_1_dart/09_generics_null_safety/ressourcen.md)
- [Übung](block_1_dart/09_generics_null_safety/uebung.md)
- [Lösung](block_1_dart/09_generics_null_safety/loesung.md)

### Einheit 1.10: Pattern Matching & Records (2h)

**Themen:** Records (Dart 3), Pattern Matching, Destructuring, Sealed Classes, Switch Expressions.

- [Lehrstoff](block_1_dart/10_patterns_records/lehrstoff.md)
- [Ressourcen](block_1_dart/10_patterns_records/ressourcen.md)
- [Übung](block_1_dart/10_patterns_records/uebung.md)
- [Lösung](block_1_dart/10_patterns_records/loesung.md)

---

## Block 2 -- Flutter: Grundlagen

Ab jetzt arbeitest du mit Flutter. Du lernst das Widget-Konzept, Layouts und Navigation.

### Einheit 2.1: Flutter Architektur & Setup (2h)

**Themen:** Flutter-Architektur, Widget-Tree, Projekt-Struktur, `flutter create`, `flutter run`, Hot Reload vs. Hot Restart, DevTools.

- [Lehrstoff](block_2_flutter_grundlagen/01_architektur_setup/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/01_architektur_setup/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/01_architektur_setup/uebung.md)
- [Lösung](block_2_flutter_grundlagen/01_architektur_setup/loesung.md)

### Einheit 2.2: StatelessWidget & Basis-Widgets (2h)

**Themen:** `StatelessWidget`, `BuildContext`, `MaterialApp`, `Scaffold`, `AppBar`, `Text`, `Icon`, `Image`, `ElevatedButton`.

- [Lehrstoff](block_2_flutter_grundlagen/02_stateless_widgets/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/02_stateless_widgets/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/02_stateless_widgets/uebung.md)
- [Lösung](block_2_flutter_grundlagen/02_stateless_widgets/loesung.md)

### Einheit 2.3: StatefulWidget Grundlagen (2h)

**Themen:** `StatefulWidget`, `State<T>`, `setState()`, Wann Stateful vs. Stateless.

- [Lehrstoff](block_2_flutter_grundlagen/03_stateful_grundlagen/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/03_stateful_grundlagen/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/03_stateful_grundlagen/uebung.md)
- [Lösung](block_2_flutter_grundlagen/03_stateful_grundlagen/loesung.md)

### Einheit 2.4: Widget-Lifecycle & Keys (2h)

**Themen:** Lifecycle-Methoden (`initState`, `dispose`, `didUpdateWidget`, `didChangeDependencies`), `Key`-Konzept, `GlobalKey`, `ValueKey`, `UniqueKey`.

- [Lehrstoff](block_2_flutter_grundlagen/04_lifecycle_keys/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/04_lifecycle_keys/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/04_lifecycle_keys/uebung.md)
- [Lösung](block_2_flutter_grundlagen/04_lifecycle_keys/loesung.md)

### Einheit 2.5: Layout Basics: Row, Column, Stack (2h)

**Themen:** `Row`, `Column`, `Stack`, `MainAxisAlignment`, `CrossAxisAlignment`, `Positioned`.

- [Lehrstoff](block_2_flutter_grundlagen/05_layout_basics/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/05_layout_basics/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/05_layout_basics/uebung.md)
- [Lösung](block_2_flutter_grundlagen/05_layout_basics/loesung.md)

### Einheit 2.6: Container, Sizing & Spacing (2h)

**Themen:** `Container`, `SizedBox`, `Expanded`, `Flexible`, `Padding`, `Align`, `Center`, `ConstrainedBox`.

- [Lehrstoff](block_2_flutter_grundlagen/06_container_sizing/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/06_container_sizing/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/06_container_sizing/uebung.md)
- [Lösung](block_2_flutter_grundlagen/06_container_sizing/loesung.md)

### Einheit 2.7: Listen & Scrolling (2h)

**Themen:** `ListView`, `ListView.builder`, `GridView`, `SingleChildScrollView`, `ScrollController`.

- [Lehrstoff](block_2_flutter_grundlagen/07_listen_scrolling/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/07_listen_scrolling/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/07_listen_scrolling/uebung.md)
- [Lösung](block_2_flutter_grundlagen/07_listen_scrolling/loesung.md)

### Einheit 2.8: Styling & Themes (2h)

**Themen:** `ThemeData`, `TextStyle`, `BoxDecoration`, `ColorScheme`, Dark/Light Mode, `MediaQuery`, Responsive Design Basics.

- [Lehrstoff](block_2_flutter_grundlagen/08_styling_themes/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/08_styling_themes/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/08_styling_themes/uebung.md)
- [Lösung](block_2_flutter_grundlagen/08_styling_themes/loesung.md)

### Einheit 2.9: Navigation Basics (2h)

**Themen:** `Navigator.push`/`pop`, `MaterialPageRoute`, Datenübergabe zwischen Screens, `Navigator.pushReplacement`.

- [Lehrstoff](block_2_flutter_grundlagen/09_navigation_basics/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/09_navigation_basics/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/09_navigation_basics/uebung.md)
- [Lösung](block_2_flutter_grundlagen/09_navigation_basics/loesung.md)

### Einheit 2.10: Named Routes & go_router (2h)

**Themen:** Named Routes, `onGenerateRoute`, `go_router` Package, Deep Linking, `PopScope`.

- [Lehrstoff](block_2_flutter_grundlagen/10_named_routes_gorouter/lehrstoff.md)
- [Ressourcen](block_2_flutter_grundlagen/10_named_routes_gorouter/ressourcen.md)
- [Übung](block_2_flutter_grundlagen/10_named_routes_gorouter/uebung.md)
- [Lösung](block_2_flutter_grundlagen/10_named_routes_gorouter/loesung.md)

---

## Block 3 -- Flutter: Fortgeschritten

Dieser Block behandelt State Management, API-Anbindung, lokale Datenhaltung und Formulare.

### Einheit 3.1: State Management Konzepte (2h)

**Themen:** Warum State Management?, Lifting State Up, `InheritedWidget` (Konzept), Überblick über Lösungen (Provider, Riverpod, Bloc).

- [Lehrstoff](block_3_flutter_fortgeschritten/01_state_konzepte/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/01_state_konzepte/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/01_state_konzepte/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/01_state_konzepte/loesung.md)

### Einheit 3.2: Provider Basics (2h)

**Themen:** `provider` Package, `ChangeNotifier`, `ChangeNotifierProvider`, `Consumer`, `context.watch` vs. `context.read`.

- [Lehrstoff](block_3_flutter_fortgeschritten/02_provider_basics/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/02_provider_basics/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/02_provider_basics/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/02_provider_basics/loesung.md)

### Einheit 3.3: Provider Advanced (2h)

**Themen:** `Selector`, `MultiProvider`, `ProxyProvider`, `FutureProvider`, Einführung in Riverpod.

- [Lehrstoff](block_3_flutter_fortgeschritten/03_provider_advanced/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/03_provider_advanced/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/03_provider_advanced/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/03_provider_advanced/loesung.md)

### Einheit 3.4: HTTP Requests (2h)

**Themen:** `http` Package, GET/POST Requests, Headers, Timeouts, Error Handling.

- [Lehrstoff](block_3_flutter_fortgeschritten/04_http_requests/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/04_http_requests/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/04_http_requests/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/04_http_requests/loesung.md)

### Einheit 3.5: JSON & Model-Klassen (2h)

**Themen:** JSON-Serialisierung (`dart:convert`), `fromJson`/`toJson`, PUT/DELETE Requests, `json_serializable` (Code-Generierung).

- [Lehrstoff](block_3_flutter_fortgeschritten/05_json_models/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/05_json_models/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/05_json_models/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/05_json_models/loesung.md)

### Einheit 3.6: FutureBuilder & StreamBuilder (2h)

**Themen:** `FutureBuilder`, `StreamBuilder`, Loading States, Error States, Skeleton Screens.

- [Lehrstoff](block_3_flutter_fortgeschritten/06_future_stream_builder/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/06_future_stream_builder/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/06_future_stream_builder/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/06_future_stream_builder/loesung.md)

### Einheit 3.7: SharedPreferences & Key-Value Storage (2h)

**Themen:** `shared_preferences` Package, Einfache Einstellungen speichern, Wann Key-Value vs. Datenbank.

- [Lehrstoff](block_3_flutter_fortgeschritten/07_shared_preferences/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/07_shared_preferences/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/07_shared_preferences/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/07_shared_preferences/loesung.md)

### Einheit 3.8: Lokale Datenbanken (2h)

**Themen:** `sqflite` (SQLite), `hive` (NoSQL), `path_provider`, CRUD-Operationen, Vergleich der Ansätze.

- [Lehrstoff](block_3_flutter_fortgeschritten/08_lokale_datenbanken/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/08_lokale_datenbanken/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/08_lokale_datenbanken/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/08_lokale_datenbanken/loesung.md)

### Einheit 3.9: Formulare Basics (2h)

**Themen:** `Form`, `GlobalKey<FormState>`, `TextFormField`, `InputDecoration`, `TextEditingController`.

- [Lehrstoff](block_3_flutter_fortgeschritten/09_formulare_basics/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/09_formulare_basics/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/09_formulare_basics/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/09_formulare_basics/loesung.md)

### Einheit 3.10: Formular-Validierung (2h)

**Themen:** Validatoren, `autovalidateMode`, Regex-Validierung, Cross-Field-Validierung.

- [Lehrstoff](block_3_flutter_fortgeschritten/10_formular_validierung/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/10_formular_validierung/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/10_formular_validierung/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/10_formular_validierung/loesung.md)

### Einheit 3.11: Dropdowns, Checkboxen & Switches (2h)

**Themen:** `DropdownButtonFormField`, `Checkbox`, `Switch`, `Radio`, `ChoiceChip`, Custom Form Fields.

- [Lehrstoff](block_3_flutter_fortgeschritten/11_dropdowns_checkboxen/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/11_dropdowns_checkboxen/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/11_dropdowns_checkboxen/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/11_dropdowns_checkboxen/loesung.md)

### Einheit 3.12: DatePicker, TimePicker & Dialoge (2h)

**Themen:** `showDatePicker`, `showTimePicker`, `AlertDialog`, `SimpleDialog`, `BottomSheet`, Debouncing.

- [Lehrstoff](block_3_flutter_fortgeschritten/12_datepicker_dialoge/lehrstoff.md)
- [Ressourcen](block_3_flutter_fortgeschritten/12_datepicker_dialoge/ressourcen.md)
- [Übung](block_3_flutter_fortgeschritten/12_datepicker_dialoge/uebung.md)
- [Lösung](block_3_flutter_fortgeschritten/12_datepicker_dialoge/loesung.md)

---

## Block 4 -- Profi-Themen & Abschlussprojekt

Der letzte Block deckt fortgeschrittene Themen ab und endet mit einem Abschlussprojekt, das alles Gelernte zusammenführt.

### Einheit 4.1: Implizite Animationen (2h)

**Themen:** `AnimatedContainer`, `AnimatedOpacity`, `AnimatedPadding`, `AnimatedSwitcher`, `TweenAnimationBuilder`.

- [Lehrstoff](block_4_profi/01_implizite_animationen/lehrstoff.md)
- [Ressourcen](block_4_profi/01_implizite_animationen/ressourcen.md)
- [Übung](block_4_profi/01_implizite_animationen/uebung.md)
- [Lösung](block_4_profi/01_implizite_animationen/loesung.md)

### Einheit 4.2: Explizite Animationen (2h)

**Themen:** `AnimationController`, `Tween`, `CurvedAnimation`, `AnimatedBuilder`, `Hero`-Animationen, `Lottie`.

- [Lehrstoff](block_4_profi/02_explizite_animationen/lehrstoff.md)
- [Ressourcen](block_4_profi/02_explizite_animationen/ressourcen.md)
- [Übung](block_4_profi/02_explizite_animationen/uebung.md)
- [Lösung](block_4_profi/02_explizite_animationen/loesung.md)

### Einheit 4.3: Unit Tests (2h)

**Themen:** `test` Package, Assertions, Matchers, Mocking mit `mocktail`, Test-Driven Development (TDD).

- [Lehrstoff](block_4_profi/03_unit_tests/lehrstoff.md)
- [Ressourcen](block_4_profi/03_unit_tests/ressourcen.md)
- [Übung](block_4_profi/03_unit_tests/uebung.md)
- [Lösung](block_4_profi/03_unit_tests/loesung.md)

### Einheit 4.4: Widget & Integration Tests (2h)

**Themen:** `flutter_test`, `WidgetTester`, `find`, `pump`, Integration Tests, Code Coverage.

- [Lehrstoff](block_4_profi/04_widget_integration_tests/lehrstoff.md)
- [Ressourcen](block_4_profi/04_widget_integration_tests/ressourcen.md)
- [Übung](block_4_profi/04_widget_integration_tests/uebung.md)
- [Lösung](block_4_profi/04_widget_integration_tests/loesung.md)

### Einheit 4.5: Packages & Plugins (2h)

**Themen:** pub.dev, eigene Packages erstellen, Platform Channels (MethodChannel), Plattform-spezifischer Code.

- [Lehrstoff](block_4_profi/05_packages_plugins/lehrstoff.md)
- [Ressourcen](block_4_profi/05_packages_plugins/ressourcen.md)
- [Übung](block_4_profi/05_packages_plugins/uebung.md)
- [Lösung](block_4_profi/05_packages_plugins/loesung.md)

### Einheit 4.6: Build & Release (2h)

**Themen:** Permissions, App-Icons, Splash Screens, Build für Android/iOS, Release-Builds, App Store Basics.

- [Lehrstoff](block_4_profi/06_build_release/lehrstoff.md)
- [Ressourcen](block_4_profi/06_build_release/ressourcen.md)
- [Übung](block_4_profi/06_build_release/uebung.md)
- [Lösung](block_4_profi/06_build_release/loesung.md)

### Einheit 4.7-4.12: Abschlussprojekt (6 × 2h)

**Projekt:** Eine vollständige App (z.B. eine Notiz-App mit Cloud-Sync oder eine Wetter-App), die alle gelernten Konzepte vereint: State Management, API-Anbindung, lokale Speicherung, Navigation, Formulare, Animationen und Tests.

| Einheit | Fokus |
|---------|-------|
| 4.7 | Projektplanung & Setup |
| 4.8 | UI & Navigation |
| 4.9 | State Management & Datenmodelle |
| 4.10 | API-Anbindung & lokale Speicherung |
| 4.11 | Formulare & Validierung |
| 4.12 | Animationen, Tests & Feinschliff |

- [Projektbeschreibung](block_4_profi/07_abschlussprojekt/lehrstoff.md)
- [Ressourcen](block_4_profi/07_abschlussprojekt/ressourcen.md)
- [Aufgabenstellung](block_4_profi/07_abschlussprojekt/uebung.md)
- [Referenzlösung](block_4_profi/07_abschlussprojekt/loesung.md)

---

## Lerneinheit-Struktur (2 Stunden)

| Phase | Dauer | Inhalt |
|-------|-------|--------|
| Theorie | 45 min | Lehrstoff lesen, Code-Beispiele nachvollziehen |
| Praxis | 60 min | Übung bearbeiten |
| Review | 15 min | Lösung vergleichen, Ressourcen bei Bedarf |

---

## Empfohlene Werkzeuge

- **IDE:** VS Code mit Dart & Flutter Extensions oder Android Studio
- **Dart Playground:** [DartPad](https://dartpad.dev) -- ideal für Block 1
- **Emulator:** Android Emulator oder iOS Simulator
- **Versionskontrolle:** Git
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

> **Tipp:** Nutze DartPad (https://dartpad.dev) für die Dart-Übungen in Block 1. Ab Block 2 arbeitest du mit echten Flutter-Projekten in deiner IDE.
