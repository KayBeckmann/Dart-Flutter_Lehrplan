# Einheit 1.8: Collections

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1-1.2

---

## 8.1 List

```dart
// Erstellung
var zahlen = [1, 2, 3, 4, 5];
var leer = <int>[];
var fixiert = List.filled(5, 0);  // [0, 0, 0, 0, 0]
var generiert = List.generate(5, (i) => i * 2);  // [0, 2, 4, 6, 8]

// Zugriff
print(zahlen[0]);       // 1
print(zahlen.first);    // 1
print(zahlen.last);     // 5
print(zahlen.length);   // 5

// Modifikation
zahlen.add(6);
zahlen.addAll([7, 8]);
zahlen.insert(0, 0);
zahlen.removeAt(0);
zahlen.removeLast();
```

---

## 8.2 Map

```dart
var person = {
  'name': 'Max',
  'alter': 30,
  'stadt': 'Berlin',
};

// Zugriff
print(person['name']);           // Max
print(person['fehlt']);          // null
print(person.containsKey('name')); // true

// Modifikation
person['email'] = 'max@mail.de';
person.remove('stadt');

// Iteration
for (var entry in person.entries) {
  print('${entry.key}: ${entry.value}');
}
```

---

## 8.3 Set

```dart
var zahlen = {1, 2, 3, 3, 4};  // {1, 2, 3, 4} — keine Duplikate
var leer = <int>{};

zahlen.add(5);
zahlen.remove(1);
print(zahlen.contains(2));  // true

// Mengenoperationen
var a = {1, 2, 3};
var b = {2, 3, 4};
print(a.union(b));        // {1, 2, 3, 4}
print(a.intersection(b)); // {2, 3}
print(a.difference(b));   // {1}
```

---

## 8.4 Collection-Methoden

```dart
var zahlen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

// map — transformieren
var verdoppelt = zahlen.map((n) => n * 2).toList();

// where — filtern
var gerade = zahlen.where((n) => n.isEven).toList();

// fold — reduzieren mit Startwert
var summe = zahlen.fold(0, (acc, n) => acc + n);

// reduce — reduzieren ohne Startwert
var produkt = zahlen.reduce((a, b) => a * b);

// any / every
print(zahlen.any((n) => n > 5));   // true
print(zahlen.every((n) => n > 0)); // true

// firstWhere / lastWhere
var erstesGerade = zahlen.firstWhere((n) => n.isEven);
```

---

## 8.5 Spread-Operator & Collection-if/for

```dart
// Spread
var a = [1, 2, 3];
var b = [0, ...a, 4];  // [0, 1, 2, 3, 4]

// Null-aware Spread
List<int>? vielleicht;
var c = [1, ...?vielleicht, 2];  // [1, 2]

// Collection-if
var istAdmin = true;
var menu = [
  'Start',
  'Profil',
  if (istAdmin) 'Admin',
];

// Collection-for
var quadrate = [
  for (var i = 1; i <= 5; i++) i * i,
];  // [1, 4, 9, 16, 25]
```

---

## 8.6 Zusammenfassendes Beispiel

```dart
void main() {
  var benutzer = [
    {'name': 'Max', 'alter': 30, 'aktiv': true},
    {'name': 'Anna', 'alter': 25, 'aktiv': false},
    {'name': 'Tom', 'alter': 35, 'aktiv': true},
    {'name': 'Lisa', 'alter': 28, 'aktiv': true},
  ];

  // Aktive Benutzer über 25, sortiert nach Alter
  var ergebnis = benutzer
      .where((u) => u['aktiv'] == true)
      .where((u) => (u['alter'] as int) > 25)
      .toList()
    ..sort((a, b) => (a['alter'] as int).compareTo(b['alter'] as int));

  for (var u in ergebnis) {
    print('${u['name']}: ${u['alter']} Jahre');
  }

  // Durchschnittsalter
  var durchschnitt = benutzer
      .map((u) => u['alter'] as int)
      .reduce((a, b) => a + b) / benutzer.length;
  print('Durchschnittsalter: $durchschnitt');
}
```
