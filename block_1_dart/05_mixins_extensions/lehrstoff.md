# Einheit 1.5: Mixins & Extensions

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.4

---

## 5.1 Mixins — Code-Wiederverwendung ohne Vererbung

Mixins sind Darts Lösung für Code-Wiederverwendung ohne Mehrfachvererbung:

```dart
mixin Schwimmfähig {
  void schwimme() => print('$runtimeType schwimmt');
}

mixin Fliegbar {
  void fliege() => print('$runtimeType fliegt');
}

mixin Laufbar {
  void laufe() => print('$runtimeType läuft');
}

class Tier {
  final String name;
  Tier(this.name);
}

// Mixins mit 'with' einbinden
class Ente extends Tier with Schwimmfähig, Fliegbar, Laufbar {
  Ente(super.name);
}

class Fisch extends Tier with Schwimmfähig {
  Fisch(super.name);
}

void main() {
  var ente = Ente('Donald');
  ente.schwimme();  // Ente schwimmt
  ente.fliege();    // Ente fliegt
  ente.laufe();     // Ente läuft
}
```

---

## 5.2 Mixin mit `on`-Einschränkung

```dart
class Musiker {
  void spieleInstrument() => print('Spielt Instrument');
}

// Mixin kann NUR auf Musiker-Unterklassen angewendet werden
mixin Sänger on Musiker {
  void singe() {
    print('Singt');
    spieleInstrument();  // Kann Musiker-Methoden nutzen
  }
}

class Rockstar extends Musiker with Sänger {}

// class Fan with Sänger {}  // FEHLER — Fan ist kein Musiker
```

---

## 5.3 Extension Methods

Bestehenden Klassen neue Methoden hinzufügen, ohne sie zu verändern:

```dart
extension StringErweiterungen on String {
  bool get istEmail => contains('@') && contains('.');

  String wiederhole(int n) => List.filled(n, this).join(' ');

  String get großAnfang {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

extension IntErweiterungen on int {
  Duration get sekunden => Duration(seconds: this);
  Duration get minuten => Duration(minutes: this);

  bool get istPrimzahl {
    if (this < 2) return false;
    for (var i = 2; i * i <= this; i++) {
      if (this % i == 0) return false;
    }
    return true;
  }
}

void main() {
  print('test@mail.de'.istEmail);  // true
  print('ha'.wiederhole(3));       // ha ha ha
  print('dart'.großAnfang);        // Dart
  print(7.istPrimzahl);            // true
  print(5.sekunden);               // 0:00:05.000000
}
```

---

## 5.4 Enhanced Enums (Dart 2.17+)

Enums mit Feldern, Methoden und Interfaces:

```dart
enum Planet implements Comparable<Planet> {
  merkur(masseKg: 3.303e+23, radiusM: 2.4397e6),
  venus(masseKg: 4.869e+24, radiusM: 6.0518e6),
  erde(masseKg: 5.976e+24, radiusM: 6.37814e6),
  mars(masseKg: 6.421e+23, radiusM: 3.3972e6);

  final double masseKg;
  final double radiusM;

  const Planet({required this.masseKg, required this.radiusM});

  double get oberflächengravitation =>
      6.67300E-11 * masseKg / (radiusM * radiusM);

  @override
  int compareTo(Planet other) => masseKg.compareTo(other.masseKg);
}

enum HttpStatus {
  ok(200, 'OK'),
  notFound(404, 'Not Found'),
  serverError(500, 'Server Error');

  final int code;
  final String nachricht;

  const HttpStatus(this.code, this.nachricht);

  bool get istErfolgreich => code >= 200 && code < 300;

  @override
  String toString() => '$code $nachricht';
}

void main() {
  print(HttpStatus.notFound);           // 404 Not Found
  print(HttpStatus.ok.istErfolgreich);  // true
}
```

---

## 5.5 Zusammenfassendes Beispiel

```dart
mixin Serialisierbar {
  Map<String, dynamic> toJson();
  String toJsonString() => toJson().toString();
}

mixin Validierbar {
  List<String> validiere();
  bool get istGültig => validiere().isEmpty;
}

extension ListErweiterungen<T> on List<T> {
  T? get erstesOderNull => isEmpty ? null : first;
  List<T> ohneNull() => where((e) => e != null).toList();
}

class Benutzer with Serialisierbar, Validierbar {
  String name;
  String email;
  int? alter;

  Benutzer({required this.name, required this.email, this.alter});

  @override
  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    if (alter != null) 'alter': alter,
  };

  @override
  List<String> validiere() {
    var fehler = <String>[];
    if (name.isEmpty) fehler.add('Name fehlt');
    if (!email.contains('@')) fehler.add('Email ungültig');
    if (alter != null && alter! < 0) fehler.add('Alter ungültig');
    return fehler;
  }
}

void main() {
  var user = Benutzer(name: 'Max', email: 'max@mail.de', alter: 25);
  print(user.istGültig);      // true
  print(user.toJsonString()); // {name: Max, email: max@mail.de, alter: 25}
}
```
