# Ressourcen 1.2: Funktionen & Kontrollstrukturen

---

## Offizielle Dokumentation

- [Functions](https://dart.dev/language/functions) — Dart-Funktionen im Detail
- [Control Flow](https://dart.dev/language/loops) — Schleifen und Bedingungen
- [Patterns](https://dart.dev/language/patterns) — Dart 3 Pattern Matching

---

## Best Practices

### Parameter-Reihenfolge

```dart
// Gut: Required zuerst, dann optional
void funktion(
  String required1,
  int required2, {
  String optional1 = 'default',
  int? optional2,
}) { }

// Gut: Benannte Parameter bei mehr als 2-3 Parametern
void erstelleBenutzer({
  required String name,
  required String email,
  int? alter,
}) { }
```

### Wann Arrow-Syntax verwenden?

```dart
// Gut: Einzeiler
int quadrat(int n) => n * n;

// Schlecht: Zu komplex für Arrow
int komplex(int n) => n > 0 ? n * n : n < 0 ? -n * n : 0;  // Schwer lesbar

// Besser: Normaler Body
int komplex(int n) {
  if (n > 0) return n * n;
  if (n < 0) return -n * n;
  return 0;
}
```

---

## Wichtige Patterns

### Callback-Pattern

```dart
void ladeDaten({
  required void Function(String) onErfolg,
  required void Function(Exception) onFehler,
}) {
  try {
    var daten = 'Geladene Daten';
    onErfolg(daten);
  } catch (e) {
    onFehler(e as Exception);
  }
}
```

### Factory-Pattern mit Funktionen

```dart
typedef Logger = void Function(String);

Logger erstelleLogger(String prefix) {
  return (String nachricht) => print('[$prefix] $nachricht');
}
```

---

## Nächste Einheit

**Einheit 1.3: Klassen & Konstruktoren**
- Klassen und Properties
- Verschiedene Konstruktortypen
- Getter und Setter
