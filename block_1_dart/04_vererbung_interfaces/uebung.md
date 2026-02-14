# Übung 1.4: Vererbung & Interfaces

> **Dauer:** ca. 60 Minuten

---

## Aufgabe 1: Vererbungshierarchie (20 Min.)

Erstelle eine Klassenhierarchie für geometrische Formen:

```dart
void main() {
  List<Form> formen = [
    Rechteck(5, 3),
    Quadrat(4),
    Kreis(2.5),
    Dreieck(3, 4, 5),
  ];

  for (var form in formen) {
    print('${form.name}:');
    print('  Fläche: ${form.flaeche.toStringAsFixed(2)}');
    print('  Umfang: ${form.umfang.toStringAsFixed(2)}');
  }
}

// TODO: Implementiere:
// 1. Abstrakte Klasse 'Form' mit:
//    - Abstrakter Getter: name, flaeche, umfang
//
// 2. Klasse 'Rechteck' extends Form:
//    - Felder: breite, hoehe
//    - Fläche = breite * höhe
//    - Umfang = 2 * (breite + höhe)
//
// 3. Klasse 'Quadrat' extends Rechteck:
//    - Nur ein Parameter (seite)
//    - Nutzt den Rechteck-Konstruktor
//
// 4. Klasse 'Kreis' extends Form:
//    - Feld: radius
//    - Fläche = π * r²
//    - Umfang = 2 * π * r
//
// 5. Klasse 'Dreieck' extends Form:
//    - Felder: a, b, c (Seitenlängen)
//    - Umfang = a + b + c
//    - Fläche mit Heronformel: sqrt(s*(s-a)*(s-b)*(s-c)) wobei s = Umfang/2
```

---

## Aufgabe 2: Interface-Implementierung (15 Min.)

Implementiere ein Plugin-System mit Interfaces:

```dart
void main() {
  var plugins = <Plugin>[
    LoggerPlugin('app.log'),
    CachePlugin(maxGröße: 100),
    AnalyticsPlugin('UA-12345'),
  ];

  var app = App(plugins);
  app.starte();
  app.beende();
}

// TODO: Implementiere:
// 1. Abstrakte Klasse/Interface 'Plugin' mit:
//    - String get name
//    - void initialisiere()
//    - void beende()
//
// 2. Klasse 'LoggerPlugin' implements Plugin
// 3. Klasse 'CachePlugin' implements Plugin
// 4. Klasse 'AnalyticsPlugin' implements Plugin
//
// 5. Klasse 'App':
//    - Nimmt Liste von Plugins im Konstruktor
//    - starte(): Ruft initialisiere() auf allen Plugins auf
//    - beende(): Ruft beende() auf allen Plugins auf
```

---

## Aufgabe 3: Operator Overloading (15 Min.)

Erstelle eine `Bruch`-Klasse mit Operatoren:

```dart
void main() {
  var a = Bruch(1, 2);  // 1/2
  var b = Bruch(1, 3);  // 1/3

  print('$a + $b = ${a + b}');  // 1/2 + 1/3 = 5/6
  print('$a - $b = ${a - b}');  // 1/2 - 1/3 = 1/6
  print('$a * $b = ${a * b}');  // 1/2 * 1/3 = 1/6
  print('$a / $b = ${a / b}');  // 1/2 / 1/3 = 3/2

  print('$a == ${Bruch(2, 4)}: ${a == Bruch(2, 4)}');  // true (gekürzt gleich)
  print('$a > $b: ${a > b}');  // true
  print('$a < $b: ${a < b}');  // false

  print('${Bruch(6, 8).kuerze()}');  // 3/4
}

// TODO: Implementiere Bruch-Klasse mit:
// - Felder: zaehler, nenner
// - Operatoren: +, -, *, /, ==, <, >, <=, >=
// - Methode: kuerze() (gibt gekürzten Bruch zurück)
// - toString(): "zaehler/nenner"
//
// Formeln:
// a/b + c/d = (a*d + c*b) / (b*d)
// a/b - c/d = (a*d - c*b) / (b*d)
// a/b * c/d = (a*c) / (b*d)
// a/b / c/d = (a*d) / (b*c)
//
// Hinweis: Nutze den GGT (größter gemeinsamer Teiler) zum Kürzen
```

---

## Aufgabe 4: Polymorphismus & Typprüfung (10 Min.)

Implementiere ein Nachrichtensystem:

```dart
void main() {
  List<Nachricht> nachrichten = [
    TextNachricht('Hallo Welt!'),
    BildNachricht('foto.jpg', 1024 * 500),
    AudioNachricht('sprachnachricht.mp3', Duration(seconds: 30)),
    TextNachricht('Wie gehts?'),
  ];

  var stats = analysiereNachrichten(nachrichten);
  print('Statistik: $stats');
  // {text: 2, bild: 1, audio: 1, gesamtGröße: 512000, gesamtDauer: 0:00:30}
}

// TODO: Implementiere:
// 1. Abstrakte Klasse 'Nachricht' mit:
//    - DateTime get zeitstempel
//    - String get vorschau
//
// 2. TextNachricht, BildNachricht, AudioNachricht
//
// 3. Funktion analysiereNachrichten:
//    - Zählt jeden Nachrichtentyp
//    - Summiert Größe aller Bilder
//    - Summiert Dauer aller Audio-Nachrichten
//    - Nutzt 'is' für Typprüfung
```

---

## Bonusaufgabe: Mehrfache Interfaces

Implementiere ein Dateisystem mit mehreren Interfaces:

```dart
void main() {
  var dateien = <Datei>[
    TextDatei('readme.txt', 'Hallo Welt'),
    BildDatei('foto.png', 1920, 1080),
    Ordner('dokumente', [
      TextDatei('notes.txt', 'Notizen...'),
    ]),
  ];

  for (var datei in dateien) {
    print(datei.info);

    if (datei is Druckbar) {
      datei.drucke();
    }

    if (datei is Komprimierbar) {
      print('Komprimiert: ${datei.komprimiere()} Bytes');
    }
  }
}

// TODO: Implementiere:
// - Interface 'Druckbar' mit drucke()
// - Interface 'Komprimierbar' mit int komprimiere()
// - Abstrakte Klasse 'Datei' mit name, größe, info
// - TextDatei implements Druckbar, Komprimierbar
// - BildDatei implements Komprimierbar
// - Ordner (enthält Liste von Dateien, größe = Summe aller Inhalte)
```
