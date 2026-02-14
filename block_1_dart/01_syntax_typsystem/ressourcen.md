# Ressourcen 1.1: Dart Syntax & Typsystem

---

## Offizielle Dokumentation

- [Dart Language Tour](https://dart.dev/language) — Offizielle Sprachübersicht
- [Dart Type System](https://dart.dev/language/type-system) — Typsystem im Detail
- [Effective Dart: Usage](https://dart.dev/effective-dart/usage) — Best Practices

---

## Online-Tools

- [DartPad](https://dartpad.dev) — Online Dart/Flutter Editor (ideal für Übungen)
- [Dart Cheatsheet](https://dart.dev/codelabs/dart-cheatsheet) — Interaktives Codelab

---

## Vertiefende Artikel

### var, final, const
- [Understanding const in Dart](https://dart.dev/language/variables#final-and-const) — Wann welches verwenden

### Typsystem
- [Sound Null Safety](https://dart.dev/null-safety) — Dart's Null-Safety-System (Vorschau für spätere Einheiten)

---

## Video-Tutorials

- [Dart in 100 Seconds](https://www.youtube.com/watch?v=NrO0CJCbYLA) — Fireship (Schnellübersicht)
- [Dart Tutorial for Beginners](https://www.youtube.com/watch?v=Ej_Pcr4uC2Q) — Mitch Koko

---

## Wichtige Konzepte zum Merken

```dart
// var → Typ wird inferiert, Wert kann sich ändern
var name = 'Dart';

// final → Wert wird einmal zur LAUFZEIT festgelegt
final startzeit = DateTime.now();

// const → Wert muss zur KOMPILIERZEIT bekannt sein
const pi = 3.14159;

// late → Initialisierung verzögert
late String config;

// String-Interpolation
print('Hallo $name!');           // Variable
print('2+2 = ${2 + 2}');         // Ausdruck
```

---

## Nächste Einheit

**Einheit 1.2: Funktionen & Kontrollstrukturen**
- Funktionsparameter (named, positional, optional)
- Arrow-Syntax
- if/else, switch, for, while
