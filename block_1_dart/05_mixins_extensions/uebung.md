# Übung 1.5: Mixins & Extensions

> **Dauer:** ca. 60 Minuten

---

## Aufgabe 1: Mixins für Spielcharaktere (20 Min.)

```dart
void main() {
  var krieger = Krieger('Conan');
  var magier = Magier('Gandalf');
  var paladin = Paladin('Arthas');

  krieger.angreifen();
  magier.zaubern();
  paladin.angreifen();
  paladin.heilen();
  paladin.zaubern();
}

// TODO: Implementiere Mixins:
// - Kämpfer: angreifen(), verteidigen()
// - Heiler: heilen()
// - Zauberer: zaubern(), manaRegenerieren()

// TODO: Implementiere Klassen:
// - Charakter (Basisklasse mit name)
// - Krieger extends Charakter with Kämpfer
// - Magier extends Charakter with Zauberer
// - Paladin extends Charakter with Kämpfer, Heiler, Zauberer
```

---

## Aufgabe 2: Extension Methods (20 Min.)

```dart
void main() {
  // String Extensions
  print('hello world'.titleCase);        // Hello World
  print('hello'.reverse);                // olleh
  print('12345'.nurZiffern);             // true
  print('abc123'.nurZiffern);            // false

  // List Extensions
  var zahlen = [1, 2, 3, 4, 5];
  print(zahlen.summe);                   // 15
  print(zahlen.durchschnitt);            // 3.0
  print(zahlen.zweiteHälfte);            // [4, 5]

  // DateTime Extensions
  var heute = DateTime.now();
  print(heute.istWochenende);
  print(heute.deutschesDatum);           // 14.02.2026

  // int Extensions
  print(42.toRömisch);                   // XLII
}

// TODO: Implementiere alle Extensions
```

---

## Aufgabe 3: Enhanced Enum (15 Min.)

```dart
void main() {
  var status = BestellStatus.versendet;

  print(status.label);                   // Versendet
  print(status.istAbgeschlossen);        // false
  print(status.nächsterStatus);          // BestellStatus.geliefert
  print(status.icon);                    // 📦

  // Alle Status durchgehen
  for (var s in BestellStatus.values) {
    print('${s.icon} ${s.label}');
  }
}

// TODO: Implementiere BestellStatus enum:
// - neu (icon: 🆕, label: "Neu")
// - bezahlt (icon: 💳, label: "Bezahlt")
// - versendet (icon: 📦, label: "Versendet")
// - geliefert (icon: ✅, label: "Geliefert")
// - storniert (icon: ❌, label: "Storniert")
//
// - Getter: istAbgeschlossen (geliefert oder storniert)
// - Getter: nächsterStatus (null wenn kein nächster)
```

---

## Bonusaufgabe: Mixin mit on-Einschränkung

```dart
void main() {
  var ordner = DateiOrdner('Dokumente', [
    TextDatei('readme.txt', 100),
    BildDatei('foto.jpg', 5000),
  ]);

  ordner.komprimiere();
  ordner.speichere();
  ordner.lade();
}

// TODO:
// - Abstrakte Klasse Datei mit name, größe
// - Mixin Komprimierbar on Datei mit komprimiere()
// - Mixin Speicherbar on Datei mit speichere(), lade()
// - TextDatei, BildDatei, DateiOrdner mit passenden Mixins
```
