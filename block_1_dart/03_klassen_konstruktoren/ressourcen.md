# Ressourcen 1.3: Klassen & Konstruktoren

---

## Offizielle Dokumentation

- [Classes](https://dart.dev/language/classes) — Klassen in Dart
- [Constructors](https://dart.dev/language/constructors) — Konstruktoren im Detail
- [Methods](https://dart.dev/language/methods) — Methoden, Getter, Setter

---

## Best Practices

### Konstruktor-Wahl

| Situation | Konstruktor-Typ |
|-----------|-----------------|
| Einfache Initialisierung | `ClassName(this.field)` |
| Alternative Erstellung | Benannter Konstruktor |
| Caching/Singleton | Factory-Konstruktor |
| Immutable Objekte | Const-Konstruktor |
| Validierung vor Init | Initialisierungsliste |

### Wann `final` vs. `var` für Felder?

```dart
// Gut: final für Felder, die sich nicht ändern
class Person {
  final String name;  // Wird nie geändert
  int alter;          // Kann sich ändern
}
```

---

## Nächste Einheit

**Einheit 1.4: Vererbung & Interfaces**
- extends, super
- Abstract Classes
- implements
