# Übung 1.9: Generics & Null Safety

---

## Aufgabe 1: Generische Klasse (15 Min.)

```dart
void main() {
  var stack = Stack<int>();
  stack.push(1);
  stack.push(2);
  stack.push(3);

  print(stack.pop());   // 3
  print(stack.peek());  // 2
  print(stack.isEmpty); // false
  print(stack.größe);   // 2
}

// TODO: Implementiere Stack<T>
// - push(T): Element hinzufügen
// - pop(): Element entfernen und zurückgeben
// - peek(): Oberstes Element ohne entfernen
// - isEmpty, größe
```

---

## Aufgabe 2: Generische Funktionen (15 Min.)

```dart
void main() {
  var zahlen = [3, 1, 4, 1, 5, 9, 2, 6];

  print(finde(zahlen, (n) => n > 5));  // 9
  print(finde(zahlen, (n) => n > 100)); // null

  print(transformiere<int, String>(zahlen, (n) => 'Zahl: $n'));
  // [Zahl: 3, Zahl: 1, ...]

  print(partitioniere(zahlen, (n) => n.isEven));
  // ([4, 2, 6], [3, 1, 1, 5, 9])
}

// TODO: Implementiere:
// - T? finde<T>(List<T>, bool Function(T))
// - List<R> transformiere<T, R>(List<T>, R Function(T))
// - (List<T>, List<T>) partitioniere<T>(List<T>, bool Function(T))
```

---

## Aufgabe 3: Null Safety (15 Min.)

```dart
void main() {
  // Korrigiere die Null-Safety-Fehler:

  String? getName() => DateTime.now().second.isEven ? 'Max' : null;

  // TODO: Fix these
  var name = getName();
  print(name.length);  // Fehler!

  var länge = name.length ?? 0;  // Fehler!

  if (name != null) {
    // TODO: Warum funktioniert das hier?
  }
}

// TODO: Implementiere sicher
String grüße(String? name, String? grußwort) {
  // - Wenn beide null: "Hallo!"
  // - Wenn name null: "$grußwort!"
  // - Wenn grußwort null: "Hallo, $name!"
  // - Sonst: "$grußwort, $name!"
}
```

---

## Aufgabe 4: Type Constraints (15 Min.)

```dart
void main() {
  var zahlen = [3, 1, 4, 1, 5];
  var texte = ['Birne', 'Apfel', 'Orange'];

  print(sortiert(zahlen));  // [1, 1, 3, 4, 5]
  print(sortiert(texte));   // [Apfel, Birne, Orange]

  print(inBereich(5, 1, 10));  // true
  print(inBereich(15, 1, 10)); // false
}

// TODO: Implementiere mit Type Constraints:
// - List<T> sortiert<T extends Comparable<T>>(List<T>)
// - bool inBereich<T extends num>(T wert, T min, T max)
```

---

## Bonusaufgabe: Result-Typ

```dart
void main() {
  var r1 = teile(10, 2);
  var r2 = teile(10, 0);

  r1.wenn(
    erfolg: (wert) => print('Ergebnis: $wert'),
    fehler: (msg) => print('Fehler: $msg'),
  );

  r2.wenn(
    erfolg: (wert) => print('Ergebnis: $wert'),
    fehler: (msg) => print('Fehler: $msg'),
  );
}

Result<double> teile(int a, int b) {
  if (b == 0) return Fehler('Division durch Null');
  return Erfolg(a / b);
}

// TODO: Implementiere Result<T>, Erfolg<T>, Fehler<T>
// - sealed class Result<T>
// - wenn({void Function(T) erfolg, void Function(String) fehler})
```
