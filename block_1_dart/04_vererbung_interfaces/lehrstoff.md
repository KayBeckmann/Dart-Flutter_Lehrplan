# Einheit 1.4: Vererbung & Interfaces

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.3

---

## 4.1 Vererbung mit `extends`

```dart
class Fahrzeug {
  final String marke;
  int _kilometerstand = 0;

  Fahrzeug(this.marke);

  int get kilometerstand => _kilometerstand;

  void fahre(int km) {
    _kilometerstand += km;
    print('$marke fährt $km km. Stand: $_kilometerstand km');
  }
}

class Auto extends Fahrzeug {
  final int türen;

  // super. übergibt Parameter an den Eltern-Konstruktor
  Auto(super.marke, {this.türen = 4});

  // Methode überschreiben
  @override
  void fahre(int km) {
    print('Auto startet Motor...');
    super.fahre(km);  // Eltern-Methode aufrufen
  }
}

void main() {
  var auto = Auto('BMW', türen: 4);
  auto.fahre(100);
  // Auto startet Motor...
  // BMW fährt 100 km. Stand: 100 km
}
```

**Vergleich zu C++:** Dart hat nur Einfachvererbung. Kein `virtual` nötig — alle Methoden sind standardmäßig überschreibbar.

---

## 4.2 Abstrakte Klassen

```dart
// abstract-Klassen können nicht direkt instanziiert werden
abstract class Form {
  // Abstrakte Methoden — müssen von Unterklassen implementiert werden
  double berechneFlaeche();
  double berechneUmfang();

  // Konkrete Methode — wird vererbt
  void beschreibe() {
    print('${runtimeType}: Fläche=${berechneFlaeche().toStringAsFixed(2)}');
  }
}

class Quadrat extends Form {
  final double seite;
  Quadrat(this.seite);

  @override
  double berechneFlaeche() => seite * seite;

  @override
  double berechneUmfang() => 4 * seite;
}

class Kreis extends Form {
  final double radius;
  Kreis(this.radius);

  @override
  double berechneFlaeche() => 3.14159 * radius * radius;

  @override
  double berechneUmfang() => 2 * 3.14159 * radius;
}

void main() {
  // var f = Form();  // FEHLER — abstrakte Klasse
  List<Form> formen = [Quadrat(5), Kreis(3)];
  for (var form in formen) {
    form.beschreibe();
  }
}
```

---

## 4.3 Implizite Interfaces (`implements`)

In Dart ist **jede Klasse gleichzeitig ein Interface**. Mit `implements` muss man **alle** Methoden neu implementieren:

```dart
class Druckbar {
  void drucke() => print('Standard-Ausgabe');
}

class Speicherbar {
  void speichere() => print('In Datei gespeichert');
}

// implements — ALLE Methoden müssen neu implementiert werden
class Dokument implements Druckbar, Speicherbar {
  final String inhalt;
  Dokument(this.inhalt);

  @override
  void drucke() => print('Dokument drucken: $inhalt');

  @override
  void speichere() => print('Dokument speichern: $inhalt');
}
```

### Unterschied `extends` vs. `implements`

| | `extends` | `implements` |
|---|-----------|-------------|
| Anzahl | Nur eine Klasse | Mehrere Klassen |
| Erbt Code | Ja | Nein |
| Konstruktoren | Werden vererbt | Nein |
| Konzept | "ist ein" mit Code | "verhält sich wie" |

---

## 4.4 Operator Overloading

```dart
class Vektor {
  final double x;
  final double y;

  const Vektor(this.x, this.y);

  Vektor operator +(Vektor other) => Vektor(x + other.x, y + other.y);
  Vektor operator -(Vektor other) => Vektor(x - other.x, y - other.y);
  Vektor operator *(double skalar) => Vektor(x * skalar, y * skalar);
  Vektor operator -() => Vektor(-x, -y);

  @override
  bool operator ==(Object other) =>
      other is Vektor && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  // Index-Operator
  double operator [](int index) => switch (index) {
    0 => x,
    1 => y,
    _ => throw RangeError('Index muss 0 oder 1 sein'),
  };

  @override
  String toString() => 'Vektor($x, $y)';
}

void main() {
  var a = Vektor(1, 2);
  var b = Vektor(3, 4);

  print(a + b);      // Vektor(4.0, 6.0)
  print(a * 3);      // Vektor(3.0, 6.0)
  print(a == Vektor(1, 2));  // true
  print(a[0]);       // 1.0
}
```

**Überladbare Operatoren:** `+`, `-`, `*`, `/`, `~/`, `%`, `==`, `<`, `>`, `<=`, `>=`, `[]`, `[]=`, `~`, `<<`, `>>`, `^`, `|`, `&`

---

## 4.5 Polymorphismus

```dart
abstract class Tier {
  String get name;
  void sprich();
}

class Hund extends Tier {
  @override
  String get name => 'Hund';

  @override
  void sprich() => print('Wuff!');
}

class Katze extends Tier {
  @override
  String get name => 'Katze';

  @override
  void sprich() => print('Miau!');
}

void main() {
  List<Tier> tiere = [Hund(), Katze(), Hund()];

  for (var tier in tiere) {
    print('${tier.name} sagt:');
    tier.sprich();
  }
}
```

---

## 4.6 Typprüfung und Casting

```dart
void verarbeite(Object obj) {
  // Typprüfung mit 'is'
  if (obj is String) {
    // Smart Cast: obj wird automatisch als String behandelt
    print('String mit ${obj.length} Zeichen');
  } else if (obj is int) {
    print('Integer: $obj');
  } else if (obj is List) {
    print('Liste mit ${obj.length} Elementen');
  }

  // Explizites Casting mit 'as'
  // var text = obj as String;  // Wirft Exception wenn nicht String

  // Sicheres Casting
  var text = obj as String?;  // null wenn nicht String
}
```

---

## 4.7 Zusammenfassendes Beispiel

```dart
abstract class Zahlungsmethode {
  String get name;
  bool verarbeite(double betrag);
}

class Kreditkarte implements Zahlungsmethode {
  final String kartennummer;
  double _limit;

  Kreditkarte(this.kartennummer, this._limit);

  @override
  String get name => 'Kreditkarte (*${kartennummer.substring(kartennummer.length - 4)})';

  @override
  bool verarbeite(double betrag) {
    if (betrag > _limit) {
      print('$name: Limit überschritten!');
      return false;
    }
    _limit -= betrag;
    print('$name: ${betrag.toStringAsFixed(2)} EUR abgebucht');
    return true;
  }
}

class PayPal implements Zahlungsmethode {
  final String email;
  double guthaben;

  PayPal(this.email, this.guthaben);

  @override
  String get name => 'PayPal ($email)';

  @override
  bool verarbeite(double betrag) {
    if (betrag > guthaben) {
      print('$name: Nicht genug Guthaben!');
      return false;
    }
    guthaben -= betrag;
    print('$name: ${betrag.toStringAsFixed(2)} EUR bezahlt');
    return true;
  }
}

void bezahle(Zahlungsmethode methode, double betrag) {
  print('Zahlung über ${methode.name}...');
  methode.verarbeite(betrag);
}

void main() {
  var karte = Kreditkarte('1234567890123456', 1000);
  var paypal = PayPal('user@mail.de', 500);

  bezahle(karte, 150);
  bezahle(paypal, 75);
}
```
