# Modul 14: Testing -- Ressourcen

## Offizielle Dokumentation

- **Flutter Testing Übersicht**
  https://docs.flutter.dev/testing/overview
  Einstiegspunkt für alle Testarten in Flutter. Erklärt die Unterschiede zwischen Unit, Widget und Integration Tests.

- **Unit Testing Cookbook**
  https://docs.flutter.dev/cookbook/testing/unit/introduction
  Schritt-für-Schritt-Anleitung für Unit Tests in Flutter.

- **Widget Testing Cookbook**
  https://docs.flutter.dev/cookbook/testing/widget/introduction
  Offizielles Tutorial für Widget Tests mit Interaktionen.

- **Integration Testing**
  https://docs.flutter.dev/testing/integration-tests
  Offizielle Anleitung für Integration Tests auf echten Geräten.

- **test Package API**
  https://pub.dev/packages/test
  Dokumentation des Dart-Test-Frameworks mit allen Matchern.

- **flutter_test API**
  https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html
  Vollständige API-Referenz für Widget-Tests.

## Mocking

- **mocktail Package**
  https://pub.dev/packages/mocktail
  Das empfohlene Mocking-Package für Dart/Flutter. Einfacher als mockito, da keine Code-Generierung nötig ist.

- **mockito Package (Alternative)**
  https://pub.dev/packages/mockito
  Das klassische Mocking-Framework. Benötigt build_runner für Code-Generierung.

## Integration Tests

- **integration_test Package**
  https://pub.dev/packages/integration_test
  Offizielles Package für Integration Tests.

- **patrol Package**
  https://pub.dev/packages/patrol
  Erweitertes Integration-Test-Framework mit nativer Interaktion (Berechtigungsdialoge, Benachrichtigungen, etc.).

## Videos

- **Flutter Testing für Einsteiger (Flutter YouTube)**
  https://www.youtube.com/watch?v=RDY6UYh-nyg
  Offizielles Video-Tutorial zu den verschiedenen Testarten.

- **Testing in Flutter -- The Complete Guide (Reso Coder)**
  https://www.youtube.com/watch?v=hUAUAkIZmX0
  Umfassendes Tutorial mit praxisnahen Beispielen.

- **Widget Testing Deep Dive (Flutter YouTube)**
  https://www.youtube.com/watch?v=eedHuJpSJOw
  Detailliertes Video zu Widget Tests mit WidgetTester.

## Weiterführende Artikel

- **Effective Dart: Testing**
  https://dart.dev/effective-dart/testing
  Offizielle Richtlinien für guten Teststil in Dart.

- **Test-Driven Development mit Flutter**
  https://codewithandrea.com/articles/flutter-test-driven-development/
  Praktische Anleitung zu TDD in Flutter-Projekten von Andrea Bizzotto.

- **Code Coverage in Flutter**
  https://docs.flutter.dev/testing/code-coverage
  Anleitung zur Messung und Visualisierung von Code Coverage.

## Tools

- **Flutter Coverage Extension (VS Code)**
  Zeigt Code Coverage direkt im Editor an, markiert getestete und ungetestete Zeilen.

- **Very Good CLI**
  https://pub.dev/packages/very_good_cli
  CLI-Tool von Very Good Ventures mit Test-Coverage-Enforcement und Best-Practice-Templates.

- **lcov (Coverage-Report-Generator)**
  https://github.com/linux-test-project/lcov
  Tool zur Generierung von HTML-Coverage-Reports aus lcov.info-Dateien.

## Vergleich mit bekannten Test-Frameworks

| Feature | Flutter (`test` + `flutter_test`) | Jest (JavaScript) | pytest (Python) | Google Test (C++) |
|---------|------|------|--------|-------------|
| Test definieren | `test('...', () {})` | `test('...', () => {})` | `def test_...():` | `TEST(Suite, Name) {}` |
| Gruppieren | `group('...', () {})` | `describe('...', () => {})` | `class Test...:` | `TEST_F(Fixture, Name)` |
| Setup/Teardown | `setUp()` / `tearDown()` | `beforeEach()` / `afterEach()` | `setup_method()` | `SetUp()` / `TearDown()` |
| Assertions | `expect(a, matcher)` | `expect(a).toBe(b)` | `assert a == b` | `EXPECT_EQ(a, b)` |
| Mocking | `mocktail` / `mockito` | `jest.mock()` | `unittest.mock` | `gmock` |
| Ausführen | `flutter test` | `npm test` | `pytest` | `ctest` / `gtest` |
