# Lösung 1.5: Mixins & Extensions

---

## Aufgabe 1: Mixins für Spielcharaktere

```dart
mixin Kämpfer {
  void angreifen() => print('$runtimeType greift an!');
  void verteidigen() => print('$runtimeType verteidigt sich!');
}

mixin Heiler {
  void heilen() => print('$runtimeType heilt!');
}

mixin Zauberer {
  void zaubern() => print('$runtimeType zaubert!');
  void manaRegenerieren() => print('$runtimeType regeneriert Mana');
}

class Charakter {
  final String name;
  Charakter(this.name);
}

class Krieger extends Charakter with Kämpfer {
  Krieger(super.name);
}

class Magier extends Charakter with Zauberer {
  Magier(super.name);
}

class Paladin extends Charakter with Kämpfer, Heiler, Zauberer {
  Paladin(super.name);
}

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
```

---

## Aufgabe 2: Extension Methods

```dart
extension StringExtensions on String {
  String get titleCase => split(' ')
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  String get reverse => split('').reversed.join();

  bool get nurZiffern => isNotEmpty && split('').every((c) => '0123456789'.contains(c));
}

extension ListIntExtensions on List<int> {
  int get summe => fold(0, (a, b) => a + b);
  double get durchschnitt => isEmpty ? 0 : summe / length;
  List<int> get zweiteHälfte => sublist(length ~/ 2);
}

extension DateTimeExtensions on DateTime {
  bool get istWochenende => weekday == DateTime.saturday || weekday == DateTime.sunday;
  String get deutschesDatum => '${day.toString().padLeft(2, '0')}.'
      '${month.toString().padLeft(2, '0')}.$year';
}

extension IntExtensions on int {
  String get toRömisch {
    if (this <= 0 || this > 3999) return toString();

    const römisch = [
      (1000, 'M'), (900, 'CM'), (500, 'D'), (400, 'CD'),
      (100, 'C'), (90, 'XC'), (50, 'L'), (40, 'XL'),
      (10, 'X'), (9, 'IX'), (5, 'V'), (4, 'IV'), (1, 'I'),
    ];

    var ergebnis = StringBuffer();
    var rest = this;

    for (var (wert, zeichen) in römisch) {
      while (rest >= wert) {
        ergebnis.write(zeichen);
        rest -= wert;
      }
    }
    return ergebnis.toString();
  }
}

void main() {
  print('hello world'.titleCase);
  print('hello'.reverse);
  print('12345'.nurZiffern);
  print([1, 2, 3, 4, 5].summe);
  print(DateTime.now().deutschesDatum);
  print(42.toRömisch);
}
```

---

## Aufgabe 3: Enhanced Enum

```dart
enum BestellStatus {
  neu(icon: '🆕', label: 'Neu'),
  bezahlt(icon: '💳', label: 'Bezahlt'),
  versendet(icon: '📦', label: 'Versendet'),
  geliefert(icon: '✅', label: 'Geliefert'),
  storniert(icon: '❌', label: 'Storniert');

  final String icon;
  final String label;

  const BestellStatus({required this.icon, required this.label});

  bool get istAbgeschlossen => this == geliefert || this == storniert;

  BestellStatus? get nächsterStatus => switch (this) {
    neu => bezahlt,
    bezahlt => versendet,
    versendet => geliefert,
    _ => null,
  };
}

void main() {
  var status = BestellStatus.versendet;
  print('${status.icon} ${status.label}');
  print('Abgeschlossen: ${status.istAbgeschlossen}');
  print('Nächster: ${status.nächsterStatus}');
}
```
