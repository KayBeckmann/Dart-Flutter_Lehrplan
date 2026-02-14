# Übung 1.8: Collections

---

## Aufgabe 1: List-Operationen (15 Min.)

```dart
void main() {
  var noten = [2, 1, 3, 1, 2, 4, 2, 1, 3, 2];

  // TODO:
  // 1. Berechne den Durchschnitt
  // 2. Finde die beste (kleinste) Note
  // 3. Zähle wie oft jede Note vorkommt (Map<int, int>)
  // 4. Sortiere die Noten aufsteigend (ohne Original zu ändern)
}
```

---

## Aufgabe 2: Map-Verarbeitung (15 Min.)

```dart
void main() {
  var inventar = {
    'Apfel': 50,
    'Birne': 30,
    'Orange': 0,
    'Banane': 25,
    'Kiwi': 0,
  };

  // TODO:
  // 1. Finde alle Produkte mit Bestand > 0
  // 2. Berechne den Gesamtbestand
  // 3. Erstelle eine sortierte Liste der Produkte nach Bestand
  // 4. Erhöhe alle Bestände um 10
}
```

---

## Aufgabe 3: Set-Operationen (10 Min.)

```dart
void main() {
  var teamA = {'Max', 'Anna', 'Tom', 'Lisa'};
  var teamB = {'Tom', 'Lisa', 'Paul', 'Marie'};

  // TODO:
  // 1. Wer ist in beiden Teams?
  // 2. Wer ist nur in Team A?
  // 3. Alle Personen (ohne Duplikate)
  // 4. Wer ist in genau einem Team?
}
```

---

## Aufgabe 4: Komplexe Transformationen (20 Min.)

```dart
void main() {
  var verkäufe = [
    {'produkt': 'Laptop', 'preis': 999.0, 'menge': 5},
    {'produkt': 'Maus', 'preis': 29.0, 'menge': 50},
    {'produkt': 'Tastatur', 'preis': 79.0, 'menge': 30},
    {'produkt': 'Monitor', 'preis': 399.0, 'menge': 10},
    {'produkt': 'USB-Stick', 'preis': 15.0, 'menge': 100},
  ];

  // TODO:
  // 1. Gesamtumsatz berechnen (preis * menge)
  // 2. Top 3 Produkte nach Umsatz
  // 3. Produkte mit Stückpreis > 50€
  // 4. Erstelle Report-String mit Collection-for
}
```

---

## Bonusaufgabe: Eigene Collection-Extension

```dart
void main() {
  var zahlen = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  print(zahlen.gruppiereNach((n) => n.isEven ? 'gerade' : 'ungerade'));
  // {gerade: [2, 4, 6, 8, 10], ungerade: [1, 3, 5, 7, 9]}

  print(zahlen.chunks(3));
  // [[1, 2, 3], [4, 5, 6], [7, 8, 9], [10]]
}

// TODO: Implementiere Extensions gruppiereNach und chunks
```
