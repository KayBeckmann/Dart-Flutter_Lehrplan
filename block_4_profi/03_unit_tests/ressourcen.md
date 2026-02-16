# Ressourcen zu Einheit 4.3: Unit Tests

## Offizielle Dokumentation

- [Testing Flutter Apps](https://docs.flutter.dev/testing)
- [An introduction to unit testing](https://docs.flutter.dev/cookbook/testing/unit/introduction)
- [test Package](https://pub.dev/packages/test)
- [Dart Testing](https://dart.dev/guides/testing)

## Packages

- [test](https://pub.dev/packages/test) - Dart Test Framework
- [mocktail](https://pub.dev/packages/mocktail) - Mocking (empfohlen)
- [mockito](https://pub.dev/packages/mockito) - Klassisches Mocking
- [fake_async](https://pub.dev/packages/fake_async) - Zeit-Kontrolle in Tests
- [clock](https://pub.dev/packages/clock) - Testbare Zeit

## Tutorials & Artikel

- [Flutter Testing Guide](https://medium.com/flutter-community/flutter-testing-a-comprehensive-guide-52b1c6e9a6a1)
- [TDD in Flutter](https://resocoder.com/2019/08/27/flutter-tdd-clean-architecture-course-1-explanation-project-structure/)
- [Mocktail Tutorial](https://verygood.ventures/blog/mocktail)
- [Testing Best Practices](https://codewithandrea.com/articles/flutter-test-tips/)

## Videos

- [Flutter Testing for Beginners](https://www.youtube.com/watch?v=RDY6UYh-nyg)
- [Unit Testing in Flutter](https://www.youtube.com/watch?v=zlYQe-9QMhc)
- [TDD in Flutter](https://www.youtube.com/watch?v=u7wEbSH_v3k)

## Bücher

- [Test-Driven Development by Example](https://www.amazon.com/Test-Driven-Development-Kent-Beck/dp/0321146530) - Kent Beck
- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) - Robert C. Martin

## Tools

- [Very Good CLI](https://pub.dev/packages/very_good_cli) - Projekt-Templates mit Tests
- [Coverage](https://pub.dev/packages/coverage) - Code Coverage
- [lcov](https://github.com/linux-test-project/lcov) - Coverage Reports

## Code Coverage

```bash
# Coverage generieren
flutter test --coverage

# HTML-Report (benötigt lcov)
genhtml coverage/lcov.info -o coverage/html

# Report öffnen
open coverage/html/index.html
```

## Zum Vertiefen

- [Property-based Testing](https://pub.dev/packages/glados)
- [Golden Tests](https://docs.flutter.dev/cookbook/testing/widget/matchesgoldenfile)
- [Integration Tests](https://docs.flutter.dev/testing/integration-tests)
