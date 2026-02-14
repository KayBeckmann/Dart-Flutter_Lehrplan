# Lösung 1.8: Collections

---

## Aufgabe 1

```dart
void main() {
  var noten = [2, 1, 3, 1, 2, 4, 2, 1, 3, 2];

  var durchschnitt = noten.reduce((a, b) => a + b) / noten.length;
  print('Durchschnitt: $durchschnitt');

  var beste = noten.reduce((a, b) => a < b ? a : b);
  print('Beste Note: $beste');

  var häufigkeit = <int, int>{};
  for (var note in noten) {
    häufigkeit[note] = (häufigkeit[note] ?? 0) + 1;
  }
  print('Häufigkeit: $häufigkeit');

  var sortiert = [...noten]..sort();
  print('Sortiert: $sortiert');
}
```

---

## Aufgabe 2

```dart
void main() {
  var inventar = {'Apfel': 50, 'Birne': 30, 'Orange': 0, 'Banane': 25, 'Kiwi': 0};

  var verfügbar = inventar.entries
      .where((e) => e.value > 0)
      .map((e) => e.key)
      .toList();
  print('Verfügbar: $verfügbar');

  var gesamt = inventar.values.reduce((a, b) => a + b);
  print('Gesamtbestand: $gesamt');

  var sortiert = inventar.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  print('Nach Bestand: ${sortiert.map((e) => '${e.key}: ${e.value}')}');

  inventar.updateAll((key, value) => value + 10);
  print('Erhöht: $inventar');
}
```

---

## Aufgabe 3

```dart
void main() {
  var teamA = {'Max', 'Anna', 'Tom', 'Lisa'};
  var teamB = {'Tom', 'Lisa', 'Paul', 'Marie'};

  print('Beide: ${teamA.intersection(teamB)}');
  print('Nur A: ${teamA.difference(teamB)}');
  print('Alle: ${teamA.union(teamB)}');
  print('Genau eins: ${teamA.difference(teamB).union(teamB.difference(teamA))}');
}
```

---

## Aufgabe 4

```dart
void main() {
  var verkäufe = [
    {'produkt': 'Laptop', 'preis': 999.0, 'menge': 5},
    {'produkt': 'Maus', 'preis': 29.0, 'menge': 50},
    {'produkt': 'Tastatur', 'preis': 79.0, 'menge': 30},
    {'produkt': 'Monitor', 'preis': 399.0, 'menge': 10},
    {'produkt': 'USB-Stick', 'preis': 15.0, 'menge': 100},
  ];

  var gesamtumsatz = verkäufe
      .map((v) => (v['preis'] as double) * (v['menge'] as int))
      .reduce((a, b) => a + b);
  print('Gesamtumsatz: $gesamtumsatz €');

  var mitUmsatz = verkäufe.map((v) => {
    ...v,
    'umsatz': (v['preis'] as double) * (v['menge'] as int),
  }).toList()..sort((a, b) => (b['umsatz'] as double).compareTo(a['umsatz'] as double));

  print('Top 3: ${mitUmsatz.take(3).map((v) => v['produkt'])}');

  var teuer = verkäufe.where((v) => (v['preis'] as double) > 50).toList();
  print('Teuer: ${teuer.map((v) => v['produkt'])}');

  var report = [
    'Verkaufsbericht',
    '===============',
    for (var v in mitUmsatz)
      '${v['produkt']}: ${v['umsatz']} €',
  ].join('\n');
  print(report);
}
```

---

## Bonusaufgabe

```dart
extension ListExtensions<T> on List<T> {
  Map<K, List<T>> gruppiereNach<K>(K Function(T) keyFn) {
    var result = <K, List<T>>{};
    for (var item in this) {
      var key = keyFn(item);
      (result[key] ??= []).add(item);
    }
    return result;
  }

  List<List<T>> chunks(int größe) {
    var result = <List<T>>[];
    for (var i = 0; i < length; i += größe) {
      result.add(sublist(i, i + größe > length ? length : i + größe));
    }
    return result;
  }
}
```
