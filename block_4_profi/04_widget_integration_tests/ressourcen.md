# Ressourcen zu Einheit 4.4: Widget & Integration Tests

## Offizielle Dokumentation

- [Widget Testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)
- [flutter_test Package](https://api.flutter.dev/flutter/flutter_test/flutter_test-library.html)
- [WidgetTester](https://api.flutter.dev/flutter/flutter_test/WidgetTester-class.html)
- [Finder](https://api.flutter.dev/flutter/flutter_test/Finder-class.html)

## Flutter Cookbook

- [An introduction to widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- [Find widgets](https://docs.flutter.dev/cookbook/testing/widget/finders)
- [Tap, drag, and enter text](https://docs.flutter.dev/cookbook/testing/widget/tap-drag)

## Videos

- [Widget Testing Flutter](https://www.youtube.com/watch?v=75i5VmTI6A0)
- [Integration Testing](https://www.youtube.com/watch?v=WPEsnJgW99M)
- [Golden Tests](https://www.youtube.com/watch?v=L0LPkMU-JWw)

## Tutorials & Artikel

- [Complete Guide to Widget Testing](https://codewithandrea.com/articles/flutter-widget-test-guide/)
- [Flutter Testing for Beginners](https://resocoder.com/2019/07/30/flutter-testing-for-beginners/)
- [Golden Tests Tutorial](https://medium.com/flutter-community/flutter-golden-tests-the-ultimate-guide-5c7cecc60680)

## Packages

- [integration_test](https://pub.dev/packages/integration_test) - Integration Tests
- [golden_toolkit](https://pub.dev/packages/golden_toolkit) - Erweiterte Golden Tests
- [patrol](https://pub.dev/packages/patrol) - Native Integration Tests
- [flutter_test_robots](https://pub.dev/packages/flutter_test_robots) - Test Utilities

## Tools

- [Coverage](https://pub.dev/packages/coverage) - Code Coverage
- [lcov](https://github.com/linux-test-project/lcov) - Coverage Reports
- [Codecov](https://codecov.io/) - Coverage in CI

## Golden Test Tools

```bash
# Goldens aktualisieren
flutter test --update-goldens

# Nur Golden Tests
flutter test --tags golden
```

## Zum Vertiefen

- [Accessibility Testing](https://docs.flutter.dev/development/accessibility-and-localization/accessibility#testing-for-accessibility)
- [Performance Testing](https://docs.flutter.dev/testing/integration-tests/debugging)
- [Patrol Native Testing](https://patrol.leancode.co/)
