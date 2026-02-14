# Einheit 1.9: Generics & Null Safety

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1-1.8

---

## 9.1 Generics Grundlagen

Generics ermöglichen typsichere, wiederverwendbare Komponenten:

```dart
class Box<T> {
  T inhalt;
  Box(this.inhalt);

  T hole() => inhalt;
  void setze(T wert) => inhalt = wert;
}

void main() {
  var intBox = Box<int>(42);
  var stringBox = Box<String>('Hallo');

  print(intBox.hole());     // 42
  print(stringBox.hole());  // Hallo
}
```

---

## 9.2 Generische Funktionen

```dart
T erstesElement<T>(List<T> liste) {
  if (liste.isEmpty) throw ArgumentError('Liste ist leer');
  return liste.first;
}

List<T> wiederhole<T>(T wert, int anzahl) {
  return List.filled(anzahl, wert);
}

void main() {
  print(erstesElement([1, 2, 3]));      // 1
  print(erstesElement(['a', 'b']));     // a
  print(wiederhole('x', 3));            // [x, x, x]
}
```

---

## 9.3 Type Constraints mit `extends`

```dart
// T muss num oder Unterklasse sein
T max<T extends num>(T a, T b) {
  return a > b ? a : b;
}

// T muss Comparable implementieren
T minimum<T extends Comparable<T>>(List<T> liste) {
  return liste.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
}

void main() {
  print(max(5, 3));       // 5
  print(max(3.14, 2.71)); // 3.14
  // max('a', 'b');       // FEHLER: String ist kein num
}
```

---

## 9.4 Sound Null Safety

Seit Dart 2.12 sind Typen standardmäßig **non-nullable**:

```dart
String name = 'Dart';
// name = null;  // FEHLER!

// Mit ? wird der Typ nullable
String? vielleichtName = 'Dart';
vielleichtName = null;  // OK
```

### Null-aware Operatoren

```dart
String? name;

// ?. — Null-safe Zugriff
var länge = name?.length;  // null wenn name null

// ?? — Null-Coalescing
var sicher = name ?? 'Standard';

// ??= — Zuweisen wenn null
name ??= 'Fallback';

// ! — Null-Assertion (mit Vorsicht!)
var garantiert = name!;  // Wirft wenn null
```

---

## 9.5 Null-Checks und Flow Analysis

```dart
void verarbeite(String? eingabe) {
  // Nach dem Check weiß Dart, dass eingabe nicht null ist
  if (eingabe == null) {
    print('Keine Eingabe');
    return;
  }

  // Hier ist eingabe automatisch non-null
  print('Länge: ${eingabe.length}');
}

// Auch mit is-Checks
void verarbeite2(Object? obj) {
  if (obj is String) {
    // obj ist hier automatisch String
    print(obj.toUpperCase());
  }
}
```

---

## 9.6 late Keyword

```dart
class Service {
  // Wird später initialisiert, aber garantiert vor Zugriff
  late final String apiKey;

  void konfiguriere(String key) {
    apiKey = key;
  }

  // Lazy Initialization
  late final String teureBerechnung = _berechne();

  String _berechne() {
    print('Wird nur bei Bedarf berechnet');
    return 'Ergebnis';
  }
}
```

---

## 9.7 Zusammenfassendes Beispiel

```dart
class Repository<T> {
  final Map<int, T> _speicher = {};
  int _nächsteId = 0;

  int speichere(T item) {
    var id = _nächsteId++;
    _speicher[id] = item;
    return id;
  }

  T? finde(int id) => _speicher[id];

  T findeOderFehler(int id) {
    var item = _speicher[id];
    if (item == null) throw ArgumentError('ID $id nicht gefunden');
    return item;
  }

  List<T> alle() => _speicher.values.toList();

  bool lösche(int id) => _speicher.remove(id) != null;
}

class Benutzer {
  final String name;
  Benutzer(this.name);
}

void main() {
  var repo = Repository<Benutzer>();

  var id1 = repo.speichere(Benutzer('Max'));
  var id2 = repo.speichere(Benutzer('Anna'));

  print(repo.finde(id1)?.name);  // Max
  print(repo.finde(999)?.name);  // null

  for (var u in repo.alle()) {
    print(u.name);
  }
}
```
