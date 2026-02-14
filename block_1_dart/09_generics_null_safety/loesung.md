# Lösung 1.9: Generics & Null Safety

---

## Aufgabe 1

```dart
class Stack<T> {
  final List<T> _elemente = [];

  void push(T element) => _elemente.add(element);

  T pop() {
    if (isEmpty) throw StateError('Stack ist leer');
    return _elemente.removeLast();
  }

  T peek() {
    if (isEmpty) throw StateError('Stack ist leer');
    return _elemente.last;
  }

  bool get isEmpty => _elemente.isEmpty;
  int get größe => _elemente.length;
}
```

---

## Aufgabe 2

```dart
T? finde<T>(List<T> liste, bool Function(T) bedingung) {
  for (var element in liste) {
    if (bedingung(element)) return element;
  }
  return null;
}

List<R> transformiere<T, R>(List<T> liste, R Function(T) transform) {
  return liste.map(transform).toList();
}

(List<T>, List<T>) partitioniere<T>(List<T> liste, bool Function(T) bedingung) {
  var wahr = <T>[];
  var falsch = <T>[];
  for (var e in liste) {
    (bedingung(e) ? wahr : falsch).add(e);
  }
  return (wahr, falsch);
}
```

---

## Aufgabe 3

```dart
void main() {
  String? getName() => DateTime.now().second.isEven ? 'Max' : null;

  var name = getName();

  // Fix 1: Null-Check
  print(name?.length);

  // Fix 2: Richtige Syntax
  var länge = name?.length ?? 0;

  // Flow Analysis: Nach dem Check ist name non-null
  if (name != null) {
    print(name.length);  // OK!
  }
}

String grüße(String? name, String? grußwort) {
  var g = grußwort ?? 'Hallo';
  var n = name;

  if (n == null) return '$g!';
  return '$g, $n!';
}
```

---

## Aufgabe 4

```dart
List<T> sortiert<T extends Comparable<T>>(List<T> liste) {
  return [...liste]..sort();
}

bool inBereich<T extends num>(T wert, T min, T max) {
  return wert >= min && wert <= max;
}
```

---

## Bonusaufgabe

```dart
sealed class Result<T> {
  void wenn({
    required void Function(T) erfolg,
    required void Function(String) fehler,
  });
}

class Erfolg<T> extends Result<T> {
  final T wert;
  Erfolg(this.wert);

  @override
  void wenn({
    required void Function(T) erfolg,
    required void Function(String) fehler,
  }) => erfolg(wert);
}

class Fehler<T> extends Result<T> {
  final String nachricht;
  Fehler(this.nachricht);

  @override
  void wenn({
    required void Function(T) erfolg,
    required void Function(String) fehler,
  }) => fehler(nachricht);
}

Result<double> teile(int a, int b) {
  if (b == 0) return Fehler('Division durch Null');
  return Erfolg(a / b);
}
```
