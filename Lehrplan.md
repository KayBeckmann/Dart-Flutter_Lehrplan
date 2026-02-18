# Dart & Flutter Lehrplan (Frontend & Backend)

> **Zielgruppe:** Entwickler mit Vorkenntnissen in C++, JavaScript/HTML/CSS und Python.
> Grundlegende Programmierkonzepte (Variablen, Schleifen, Funktionen, OOP-Basics) werden als bekannt vorausgesetzt.

> **Zeitaufwand:** 2 Stunden pro Lerneinheit. Insgesamt 76 Lerneinheiten (~152 Stunden).

---

## Übersicht

### Teil A: Frontend (Dart & Flutter)

| Block | Schwerpunkt | Lerneinheiten | Zeitraum |
|-------|-------------|---------------|----------|
| **1** | Dart -- Die Sprache | 10 Einheiten | ~2 Wochen |
| **2** | Flutter -- Grundlagen | 10 Einheiten | ~2 Wochen |
| **3** | Flutter -- Fortgeschritten | 12 Einheiten | ~2,5 Wochen |
| **4** | Profi-Themen & Projekt | 12 Einheiten | ~2,5 Wochen |

### Teil B: Backend (Dart Server)

| Block | Schwerpunkt | Lerneinheiten | Zeitraum |
|-------|-------------|---------------|----------|
| **5** | Server-Grundlagen | 6 Einheiten | ~1 Woche |
| **6** | REST API Entwicklung | 8 Einheiten | ~1,5 Wochen |
| **7** | Datenbanken | 8 Einheiten | ~1,5 Wochen |
| **8** | Auth & Sicherheit | 6 Einheiten | ~1 Woche |
| **9** | Produktion & Projekt | 4 Einheiten | ~1 Woche |

---

# Teil A: Frontend (Dart & Flutter)

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

# Teil B: Backend (Dart Server)

> **Voraussetzung:** Abschluss von Block 1 (Dart-Grundlagen) oder vergleichbare Dart-Kenntnisse.

---

## Block 5 -- Server-Grundlagen

In diesem Block lernst du, wie HTTP-Server in Dart funktionieren und wie du mit dem Shelf-Framework professionelle APIs entwickelst.

### Einheit 5.1: Dart auf dem Server (2h)

**Themen:** Dart außerhalb von Flutter, `dart:io`, HTTP-Grundlagen, einfacher HTTP-Server, Request/Response Lifecycle.

- [Lehrstoff](block_5_server_grundlagen/01_dart_server/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/01_dart_server/ressourcen.md)
- [Übung](block_5_server_grundlagen/01_dart_server/uebung.md)
- [Lösung](block_5_server_grundlagen/01_dart_server/loesung.md)

### Einheit 5.2: Shelf Framework Basics (2h)

**Themen:** Shelf-Architektur, Handler, Request/Response-Objekte, Pipeline, Server starten.

- [Lehrstoff](block_5_server_grundlagen/02_shelf_basics/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/02_shelf_basics/ressourcen.md)
- [Übung](block_5_server_grundlagen/02_shelf_basics/uebung.md)
- [Lösung](block_5_server_grundlagen/02_shelf_basics/loesung.md)

### Einheit 5.3: Routing mit shelf_router (2h)

**Themen:** `shelf_router` Package, Route-Definition, URL-Parameter, Query-Parameter, Route-Gruppen.

- [Lehrstoff](block_5_server_grundlagen/03_routing/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/03_routing/ressourcen.md)
- [Übung](block_5_server_grundlagen/03_routing/uebung.md)
- [Lösung](block_5_server_grundlagen/03_routing/loesung.md)

### Einheit 5.4: Middleware (2h)

**Themen:** Middleware-Konzept, Logging, CORS, Request-Transformation, Middleware-Ketten, Error-Handling-Middleware.

- [Lehrstoff](block_5_server_grundlagen/04_middleware/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/04_middleware/ressourcen.md)
- [Übung](block_5_server_grundlagen/04_middleware/uebung.md)
- [Lösung](block_5_server_grundlagen/04_middleware/loesung.md)

### Einheit 5.5: Konfiguration & Umgebungsvariablen (2h)

**Themen:** Environment Variables, `.env`-Dateien, Konfigurationsklassen, Unterschiedliche Umgebungen (dev/prod).

- [Lehrstoff](block_5_server_grundlagen/05_konfiguration/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/05_konfiguration/ressourcen.md)
- [Übung](block_5_server_grundlagen/05_konfiguration/uebung.md)
- [Lösung](block_5_server_grundlagen/05_konfiguration/loesung.md)

### Einheit 5.6: Projekt-Struktur & Architektur (2h)

**Themen:** Ordnerstruktur für Backend-Projekte, Layered Architecture, Dependency Injection, Service-Pattern.

- [Lehrstoff](block_5_server_grundlagen/06_projektstruktur/lehrstoff.md)
- [Ressourcen](block_5_server_grundlagen/06_projektstruktur/ressourcen.md)
- [Übung](block_5_server_grundlagen/06_projektstruktur/uebung.md)
- [Lösung](block_5_server_grundlagen/06_projektstruktur/loesung.md)

---

## Block 6 -- REST API Entwicklung

Dieser Block behandelt die Entwicklung professioneller REST APIs mit Best Practices für Design, Validierung und Error Handling.

### Einheit 6.1: REST-Prinzipien & API-Design (2h)

**Themen:** REST-Architektur, HTTP-Methoden, Ressourcen-Naming, API-Versionierung, HATEOAS.

- [Lehrstoff](block_6_rest_api/01_rest_prinzipien/lehrstoff.md)
- [Ressourcen](block_6_rest_api/01_rest_prinzipien/ressourcen.md)
- [Übung](block_6_rest_api/01_rest_prinzipien/uebung.md)
- [Lösung](block_6_rest_api/01_rest_prinzipien/loesung.md)

### Einheit 6.2: JSON Serialisierung (2h)

**Themen:** `dart:convert`, Model-Klassen, `fromJson`/`toJson`, `json_serializable`, Nested Objects, Listen.

- [Lehrstoff](block_6_rest_api/02_json_serialisierung/lehrstoff.md)
- [Ressourcen](block_6_rest_api/02_json_serialisierung/ressourcen.md)
- [Übung](block_6_rest_api/02_json_serialisierung/uebung.md)
- [Lösung](block_6_rest_api/02_json_serialisierung/loesung.md)

### Einheit 6.3: Request Body Parsing (2h)

**Themen:** JSON-Body lesen, Form-Daten, Multipart/File-Uploads, Content-Type Handling.

- [Lehrstoff](block_6_rest_api/03_request_body/lehrstoff.md)
- [Ressourcen](block_6_rest_api/03_request_body/ressourcen.md)
- [Übung](block_6_rest_api/03_request_body/uebung.md)
- [Lösung](block_6_rest_api/03_request_body/loesung.md)

### Einheit 6.4: CRUD-Operationen (2h)

**Themen:** Create, Read, Update, Delete implementieren, HTTP-Statuscodes, Response-Formate.

- [Lehrstoff](block_6_rest_api/04_crud/lehrstoff.md)
- [Ressourcen](block_6_rest_api/04_crud/ressourcen.md)
- [Übung](block_6_rest_api/04_crud/uebung.md)
- [Lösung](block_6_rest_api/04_crud/loesung.md)

### Einheit 6.5: Input-Validierung (2h)

**Themen:** Validierungsstrategien, Custom Validators, Fehler-Aggregation, Schema-Validierung.

- [Lehrstoff](block_6_rest_api/05_validierung/lehrstoff.md)
- [Ressourcen](block_6_rest_api/05_validierung/ressourcen.md)
- [Übung](block_6_rest_api/05_validierung/uebung.md)
- [Lösung](block_6_rest_api/05_validierung/loesung.md)

### Einheit 6.6: Error Handling & HTTP-Statuscodes (2h)

**Themen:** Exception-Hierarchie, Error-Response-Format, Global Error Handler, Logging.

- [Lehrstoff](block_6_rest_api/06_error_handling/lehrstoff.md)
- [Ressourcen](block_6_rest_api/06_error_handling/ressourcen.md)
- [Übung](block_6_rest_api/06_error_handling/uebung.md)
- [Lösung](block_6_rest_api/06_error_handling/loesung.md)

### Einheit 6.7: Pagination & Filtering (2h)

**Themen:** Offset/Limit-Pagination, Cursor-Pagination, Sortierung, Filter-Parameter, Meta-Informationen.

- [Lehrstoff](block_6_rest_api/07_pagination/lehrstoff.md)
- [Ressourcen](block_6_rest_api/07_pagination/ressourcen.md)
- [Übung](block_6_rest_api/07_pagination/uebung.md)
- [Lösung](block_6_rest_api/07_pagination/loesung.md)

### Einheit 6.8: API-Dokumentation (2h)

**Themen:** OpenAPI/Swagger, Automatische Dokumentation, Postman Collections, API-Testing-Tools.

- [Lehrstoff](block_6_rest_api/08_dokumentation/lehrstoff.md)
- [Ressourcen](block_6_rest_api/08_dokumentation/ressourcen.md)
- [Übung](block_6_rest_api/08_dokumentation/uebung.md)
- [Lösung](block_6_rest_api/08_dokumentation/loesung.md)

---

## Block 7 -- Datenbanken

Dieser Block behandelt die Anbindung relationaler und NoSQL-Datenbanken an deine Dart-Backend-Anwendung.

### Einheit 7.1: SQL-Grundlagen & PostgreSQL Setup (2h)

**Themen:** PostgreSQL installieren, SQL-Basics (SELECT, INSERT, UPDATE, DELETE), pgAdmin, Docker-Setup.

- [Lehrstoff](block_7_datenbanken/01_sql_grundlagen/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/01_sql_grundlagen/ressourcen.md)
- [Übung](block_7_datenbanken/01_sql_grundlagen/uebung.md)
- [Lösung](block_7_datenbanken/01_sql_grundlagen/loesung.md)

### Einheit 7.2: PostgreSQL mit Dart (2h)

**Themen:** `postgres` Package, Connection Pool, Prepared Statements, Transaktionen.

- [Lehrstoff](block_7_datenbanken/02_postgres_dart/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/02_postgres_dart/ressourcen.md)
- [Übung](block_7_datenbanken/02_postgres_dart/uebung.md)
- [Lösung](block_7_datenbanken/02_postgres_dart/loesung.md)

### Einheit 7.3: Repository-Pattern für Datenbanken (2h)

**Themen:** Repository-Abstraktion, Interface-basiertes Design, Unit of Work, Testbarkeit.

- [Lehrstoff](block_7_datenbanken/03_repository_pattern/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/03_repository_pattern/ressourcen.md)
- [Übung](block_7_datenbanken/03_repository_pattern/uebung.md)
- [Lösung](block_7_datenbanken/03_repository_pattern/loesung.md)

### Einheit 7.4: Relationale Modellierung (2h)

**Themen:** Primärschlüssel, Fremdschlüssel, 1:1, 1:n, n:m Beziehungen, JOINs, Normalisierung.

- [Lehrstoff](block_7_datenbanken/04_relationale_modellierung/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/04_relationale_modellierung/ressourcen.md)
- [Übung](block_7_datenbanken/04_relationale_modellierung/uebung.md)
- [Lösung](block_7_datenbanken/04_relationale_modellierung/loesung.md)

### Einheit 7.5: Migrations (2h)

**Themen:** Schema-Versionierung, Migration-Tools, Up/Down Migrations, Seed-Daten.

- [Lehrstoff](block_7_datenbanken/05_migrations/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/05_migrations/ressourcen.md)
- [Übung](block_7_datenbanken/05_migrations/uebung.md)
- [Lösung](block_7_datenbanken/05_migrations/loesung.md)

### Einheit 7.6: NoSQL mit MongoDB (2h)

**Themen:** MongoDB-Grundlagen, Dokumentenmodell, `mongo_dart` Package, CRUD-Operationen.

- [Lehrstoff](block_7_datenbanken/06_mongodb/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/06_mongodb/ressourcen.md)
- [Übung](block_7_datenbanken/06_mongodb/uebung.md)
- [Lösung](block_7_datenbanken/06_mongodb/loesung.md)

### Einheit 7.7: Queries & Aggregationen (2h)

**Themen:** Komplexe Queries, Aggregation Pipeline (MongoDB), Window Functions (PostgreSQL), Indizes.

- [Lehrstoff](block_7_datenbanken/07_queries_aggregationen/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/07_queries_aggregationen/ressourcen.md)
- [Übung](block_7_datenbanken/07_queries_aggregationen/uebung.md)
- [Lösung](block_7_datenbanken/07_queries_aggregationen/loesung.md)

### Einheit 7.8: Caching mit Redis (2h)

**Themen:** Redis-Grundlagen, `redis` Package, Caching-Strategien, Session-Storage, Pub/Sub.

- [Lehrstoff](block_7_datenbanken/08_redis_caching/lehrstoff.md)
- [Ressourcen](block_7_datenbanken/08_redis_caching/ressourcen.md)
- [Übung](block_7_datenbanken/08_redis_caching/uebung.md)
- [Lösung](block_7_datenbanken/08_redis_caching/loesung.md)

---

## Block 8 -- Authentifizierung & Sicherheit

Dieser Block behandelt alle Aspekte der Absicherung deiner API.

### Einheit 8.1: Passwort-Hashing & Benutzer-Registrierung (2h)

**Themen:** Sichere Passwort-Speicherung, bcrypt/argon2, Salt, User-Model, Registrierungsflow.

- [Lehrstoff](block_8_auth_sicherheit/01_passwort_hashing/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/01_passwort_hashing/ressourcen.md)
- [Übung](block_8_auth_sicherheit/01_passwort_hashing/uebung.md)
- [Lösung](block_8_auth_sicherheit/01_passwort_hashing/loesung.md)

### Einheit 8.2: JWT-Authentifizierung (2h)

**Themen:** JWT-Struktur, Access Tokens, Refresh Tokens, Token-Validierung, `dart_jsonwebtoken`.

- [Lehrstoff](block_8_auth_sicherheit/02_jwt/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/02_jwt/ressourcen.md)
- [Übung](block_8_auth_sicherheit/02_jwt/uebung.md)
- [Lösung](block_8_auth_sicherheit/02_jwt/loesung.md)

### Einheit 8.3: Auth-Middleware & geschützte Routen (2h)

**Themen:** Authentication Middleware, Authorization, Role-Based Access Control (RBAC), Guards.

- [Lehrstoff](block_8_auth_sicherheit/03_auth_middleware/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/03_auth_middleware/ressourcen.md)
- [Übung](block_8_auth_sicherheit/03_auth_middleware/uebung.md)
- [Lösung](block_8_auth_sicherheit/03_auth_middleware/loesung.md)

### Einheit 8.4: OAuth 2.0 & Social Login (2h)

**Themen:** OAuth 2.0 Flow, Google/GitHub Login, Token-Exchange, Provider-Integration.

- [Lehrstoff](block_8_auth_sicherheit/04_oauth/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/04_oauth/ressourcen.md)
- [Übung](block_8_auth_sicherheit/04_oauth/uebung.md)
- [Lösung](block_8_auth_sicherheit/04_oauth/loesung.md)

### Einheit 8.5: API-Sicherheit (2h)

**Themen:** CORS richtig konfigurieren, Rate Limiting, Input Sanitization, SQL Injection Prevention, HTTPS.

- [Lehrstoff](block_8_auth_sicherheit/05_api_sicherheit/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/05_api_sicherheit/ressourcen.md)
- [Übung](block_8_auth_sicherheit/05_api_sicherheit/uebung.md)
- [Lösung](block_8_auth_sicherheit/05_api_sicherheit/loesung.md)

### Einheit 8.6: Testing der Auth-Schicht (2h)

**Themen:** Unit Tests für Auth, Integration Tests, Mock-Authentication, Test-Fixtures.

- [Lehrstoff](block_8_auth_sicherheit/06_auth_testing/lehrstoff.md)
- [Ressourcen](block_8_auth_sicherheit/06_auth_testing/ressourcen.md)
- [Übung](block_8_auth_sicherheit/06_auth_testing/uebung.md)
- [Lösung](block_8_auth_sicherheit/06_auth_testing/loesung.md)

---

## Block 9 -- Produktion & Abschlussprojekt

Der letzte Block behandelt Produktions-Themen und endet mit einem Abschlussprojekt.

### Einheit 9.1: WebSockets & Real-time (2h)

**Themen:** WebSocket-Protokoll, `shelf_web_socket`, Bidirektionale Kommunikation, Chat-Beispiel.

- [Lehrstoff](block_9_produktion/01_websockets/lehrstoff.md)
- [Ressourcen](block_9_produktion/01_websockets/ressourcen.md)
- [Übung](block_9_produktion/01_websockets/uebung.md)
- [Lösung](block_9_produktion/01_websockets/loesung.md)

### Einheit 9.2: Background Jobs & Scheduling (2h)

**Themen:** Async Tasks, Job Queues, Scheduled Tasks, Cron-Jobs, Worker-Pattern.

- [Lehrstoff](block_9_produktion/02_background_jobs/lehrstoff.md)
- [Ressourcen](block_9_produktion/02_background_jobs/ressourcen.md)
- [Übung](block_9_produktion/02_background_jobs/uebung.md)
- [Lösung](block_9_produktion/02_background_jobs/loesung.md)

### Einheit 9.3: Logging & Monitoring (2h)

**Themen:** Strukturiertes Logging, Log-Level, Monitoring-Metriken, Health Checks, Alerting.

- [Lehrstoff](block_9_produktion/03_logging_monitoring/lehrstoff.md)
- [Ressourcen](block_9_produktion/03_logging_monitoring/ressourcen.md)
- [Übung](block_9_produktion/03_logging_monitoring/uebung.md)
- [Lösung](block_9_produktion/03_logging_monitoring/loesung.md)

### Einheit 9.4: Deployment & Docker (2h)

**Themen:** Docker-Container, Dockerfile, Docker Compose, Cloud-Deployment (Railway/Fly.io), CI/CD.

- [Lehrstoff](block_9_produktion/04_deployment/lehrstoff.md)
- [Ressourcen](block_9_produktion/04_deployment/ressourcen.md)
- [Übung](block_9_produktion/04_deployment/uebung.md)
- [Lösung](block_9_produktion/04_deployment/loesung.md)

### Einheit 9.5: Backend-Abschlussprojekt (8-12h)

**Projekt:** Eine vollständige Task-Management-API mit:

- User-Authentifizierung (JWT)
- Projekte & Tasks (CRUD)
- Team-Mitglieder & Berechtigungen
- PostgreSQL-Datenbank
- Redis-Caching
- WebSocket für Real-time Updates
- Docker-Deployment
- API-Dokumentation
- Vollständige Test-Suite

- [Projektbeschreibung](block_9_produktion/05_abschlussprojekt/lehrstoff.md)
- [Ressourcen](block_9_produktion/05_abschlussprojekt/ressourcen.md)
- [Aufgabenstellung](block_9_produktion/05_abschlussprojekt/uebung.md)
- [Referenzlösung](block_9_produktion/05_abschlussprojekt/loesung.md)

---

## Lerneinheit-Struktur (2 Stunden)

| Phase | Dauer | Inhalt |
|-------|-------|--------|
| Theorie | 45 min | Lehrstoff lesen, Code-Beispiele nachvollziehen |
| Praxis | 60 min | Übung bearbeiten |
| Review | 15 min | Lösung vergleichen, Ressourcen bei Bedarf |

---

## Empfohlene Werkzeuge

### Frontend (Flutter)

- **IDE:** VS Code mit Dart & Flutter Extensions oder Android Studio
- **Dart Playground:** [DartPad](https://dartpad.dev) -- ideal für Block 1
- **Emulator:** Android Emulator oder iOS Simulator
- **Versionskontrolle:** Git
- **Terminal:** Flutter CLI (`flutter doctor`, `flutter create`, `flutter run`)

### Backend (Dart Server)

- **IDE:** VS Code mit Dart Extension
- **HTTP-Client:** Postman, Insomnia, oder curl
- **Datenbank:** PostgreSQL + pgAdmin, MongoDB Compass
- **Container:** Docker Desktop
- **Terminal:** Dart CLI (`dart run`, `dart compile`)

---

## Voraussetzungen installieren

### Flutter (Frontend)

```bash
# Flutter SDK installieren (siehe https://docs.flutter.dev/get-started/install)
# Danach prüfen:
flutter doctor

# Neues Projekt erstellen:
flutter create mein_projekt
cd mein_projekt
flutter run
```

### Dart Server (Backend)

```bash
# Dart SDK (mindestens 3.0)
dart --version

# Neues Server-Projekt erstellen
dart create -t server-shelf my_api
cd my_api
dart run bin/server.dart
```

---

## Docker für Datenbanken (Backend)

```bash
# PostgreSQL
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres:15

# MongoDB
docker run -d -p 27017:27017 mongo:6

# Redis
docker run -d -p 6379:6379 redis:7
```

---

> **Tipp:** Nutze DartPad (https://dartpad.dev) für die Dart-Übungen in Block 1. Ab Block 2 arbeitest du mit echten Flutter-Projekten. Für Backend-Entwicklung ab Block 5 nutze Docker für die Datenbanken.
