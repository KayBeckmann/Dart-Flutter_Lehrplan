# Modul 2: Ressourcen — OOP in Dart

## Offizielle Dokumentation

- **Dart Language Tour: Classes**
  https://dart.dev/language/classes
  Umfassende Referenz zu allen Klassen-Features (Konstruktoren, Vererbung, Mixins, etc.).

- **Dart Language Tour: Constructors**
  https://dart.dev/language/constructors
  Detaillierte Erklärung aller Konstruktor-Varianten (Named, Factory, Const, Redirecting).

- **Dart Language Tour: Extend a class**
  https://dart.dev/language/extend
  Vererbung, Methoden überschreiben und abstrakte Klassen.

- **Dart Language Tour: Mixins**
  https://dart.dev/language/mixins
  Offizielle Dokumentation zu Mixins mit `mixin`, `with` und `on`.

- **Dart Language Tour: Extension Methods**
  https://dart.dev/language/extension-methods
  Wie man bestehende Typen um neue Methoden erweitert.

- **Dart Language Tour: Enums**
  https://dart.dev/language/enums
  Einfache und Enhanced Enums mit Feldern und Methoden.

- **Effective Dart: Design**
  https://dart.dev/effective-dart/design
  Best Practices für API-Design, Klassen-Hierarchien und Naming Conventions.

## Vertiefende Artikel

- **Understanding Mixins in Dart**
  https://dart.dev/resources/dart-cheatsheet
  Interaktives Codelab, das auch Mixins behandelt.

- **Dart Extension Methods Fundamentals — Code With Andrea**
  https://codewithandrea.com/articles/dart-extensions/
  Ausführlicher Artikel über Extension Methods mit vielen praktischen Beispielen.

- **Factory Constructors in Dart — A Deep Dive**
  https://dart.dev/language/constructors#factory-constructors
  Wann Factory-Konstruktoren sinnvoll sind und wie sie sich von normalen Konstruktoren unterscheiden.

- **Cascade Notation in Dart**
  https://dart.dev/language/operators#cascade-notation
  Offizielle Dokumentation zur Cascade-Notation (`..'` und `?..`).

## Tutorials und Videos

- **Dart OOP Crash Course (Code With Andrea)**
  https://codewithandrea.com/
  Strukturierte Tutorials zu Dart OOP-Konzepten.

- **Flutter & Dart — The Complete Guide (Maximilian Schwarzmüller, Udemy)**
  Umfangreicher Kurs, der auch Dart-OOP im Detail behandelt.

- **Dart Mixins Explained (YouTube)**
  Suche nach "Dart mixins tutorial" — es gibt mehrere gute Erklärvideos auf Englisch und Deutsch.

- **The Boring Flutter Development Show — OOP in Dart**
  https://www.youtube.com/playlist?list=PLOU2XLYxmsIK0r_D-zWcmJ1plIcDNnRkK
  Google-Entwickler zeigen OOP-Patterns in realen Flutter-Projekten.

## Interaktive Übungen

- **DartPad**
  https://dartpad.dev
  Ideal zum Experimentieren mit Klassen, Mixins und Extension Methods direkt im Browser.

- **Dart Cheatsheet Codelab**
  https://dart.dev/codelabs/dart-cheatsheet
  Interaktives Codelab mit Übungen zu OOP-Konzepten.

## Vergleichs-Ressourcen

- **Dart vs C++ OOP**
  Dart hat Einfachvererbung (wie Java), Mixins statt Mehrfachvererbung, keine Header-Dateien, und automatisches Speichermanagement. Sichtbarkeit wird über `_`-Präfix gesteuert statt über `public`/`private`/`protected`.

- **Dart vs JavaScript OOP**
  https://dart.dev/guides/language/coming-from/js-to-dart
  Dart-Klassen vs. JS-Prototypen und ES6-Klassen. Dart hat echte Klassen mit Typsystem statt syntaktischem Zucker über Prototypen.

- **Dart vs Python OOP**
  Dart erzwingt Typen (kein Duck Typing), hat kein `self`, keine Mehrfachvererbung (dafür Mixins), und verwendet `_`-Prefix für Sichtbarkeit (statt Konvention).

## Design Patterns in Dart

- **Design Patterns in Dart — RefactoringGuru**
  https://refactoring.guru/design-patterns
  Allgemeine Design-Pattern-Referenz — die Dart-Implementierung leitet sich direkt aus den gezeigten OOP-Konzepten ab.

- **Singleton in Dart**
  Am besten mit Factory-Konstruktor und statischer Instanz implementiert (siehe lehrstoff.md, Factory-Konstruktor).

- **Builder Pattern mit Cascade Notation**
  Die Cascade-Notation (`..`) macht das Builder-Pattern in Dart besonders elegant.
