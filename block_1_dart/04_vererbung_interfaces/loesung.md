# Lösung 1.4: Vererbung & Interfaces

---

## Aufgabe 1: Vererbungshierarchie

```dart
import 'dart:math';

abstract class Form {
  String get name;
  double get flaeche;
  double get umfang;
}

class Rechteck extends Form {
  final double breite;
  final double hoehe;

  Rechteck(this.breite, this.hoehe);

  @override
  String get name => 'Rechteck (${breite}x$hoehe)';

  @override
  double get flaeche => breite * hoehe;

  @override
  double get umfang => 2 * (breite + hoehe);
}

class Quadrat extends Rechteck {
  Quadrat(double seite) : super(seite, seite);

  @override
  String get name => 'Quadrat (${breite}x$breite)';
}

class Kreis extends Form {
  final double radius;

  Kreis(this.radius);

  @override
  String get name => 'Kreis (r=$radius)';

  @override
  double get flaeche => pi * radius * radius;

  @override
  double get umfang => 2 * pi * radius;
}

class Dreieck extends Form {
  final double a, b, c;

  Dreieck(this.a, this.b, this.c);

  @override
  String get name => 'Dreieck ($a, $b, $c)';

  @override
  double get umfang => a + b + c;

  @override
  double get flaeche {
    var s = umfang / 2;
    return sqrt(s * (s - a) * (s - b) * (s - c));
  }
}

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
```

---

## Aufgabe 2: Interface-Implementierung

```dart
abstract class Plugin {
  String get name;
  void initialisiere();
  void beende();
}

class LoggerPlugin implements Plugin {
  final String dateiname;

  LoggerPlugin(this.dateiname);

  @override
  String get name => 'Logger';

  @override
  void initialisiere() => print('[$name] Öffne $dateiname');

  @override
  void beende() => print('[$name] Schließe $dateiname');
}

class CachePlugin implements Plugin {
  final int maxGröße;

  CachePlugin({required this.maxGröße});

  @override
  String get name => 'Cache';

  @override
  void initialisiere() => print('[$name] Cache initialisiert (max: $maxGröße MB)');

  @override
  void beende() => print('[$name] Cache geleert');
}

class AnalyticsPlugin implements Plugin {
  final String trackingId;

  AnalyticsPlugin(this.trackingId);

  @override
  String get name => 'Analytics';

  @override
  void initialisiere() => print('[$name] Tracking gestartet: $trackingId');

  @override
  void beende() => print('[$name] Session beendet');
}

class App {
  final List<Plugin> _plugins;

  App(this._plugins);

  void starte() {
    print('=== App startet ===');
    for (var plugin in _plugins) {
      plugin.initialisiere();
    }
    print('=== App bereit ===\n');
  }

  void beende() {
    print('\n=== App beendet ===');
    for (var plugin in _plugins.reversed) {
      plugin.beende();
    }
  }
}

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
```

---

## Aufgabe 3: Operator Overloading

```dart
class Bruch implements Comparable<Bruch> {
  final int zaehler;
  final int nenner;

  Bruch(this.zaehler, this.nenner) : assert(nenner != 0);

  // GGT mit Euklids Algorithmus
  static int _ggt(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      var t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  Bruch kuerze() {
    var teiler = _ggt(zaehler, nenner);
    var z = zaehler ~/ teiler;
    var n = nenner ~/ teiler;
    // Vorzeichen normalisieren
    if (n < 0) {
      z = -z;
      n = -n;
    }
    return Bruch(z, n);
  }

  double get dezimal => zaehler / nenner;

  Bruch operator +(Bruch other) =>
      Bruch(zaehler * other.nenner + other.zaehler * nenner,
            nenner * other.nenner).kuerze();

  Bruch operator -(Bruch other) =>
      Bruch(zaehler * other.nenner - other.zaehler * nenner,
            nenner * other.nenner).kuerze();

  Bruch operator *(Bruch other) =>
      Bruch(zaehler * other.zaehler, nenner * other.nenner).kuerze();

  Bruch operator /(Bruch other) =>
      Bruch(zaehler * other.nenner, nenner * other.zaehler).kuerze();

  @override
  bool operator ==(Object other) {
    if (other is! Bruch) return false;
    var a = kuerze();
    var b = other.kuerze();
    return a.zaehler == b.zaehler && a.nenner == b.nenner;
  }

  @override
  int get hashCode => Object.hash(kuerze().zaehler, kuerze().nenner);

  @override
  int compareTo(Bruch other) => dezimal.compareTo(other.dezimal);

  bool operator <(Bruch other) => compareTo(other) < 0;
  bool operator >(Bruch other) => compareTo(other) > 0;
  bool operator <=(Bruch other) => compareTo(other) <= 0;
  bool operator >=(Bruch other) => compareTo(other) >= 0;

  @override
  String toString() => '$zaehler/$nenner';
}

void main() {
  var a = Bruch(1, 2);
  var b = Bruch(1, 3);

  print('$a + $b = ${a + b}');
  print('$a - $b = ${a - b}');
  print('$a * $b = ${a * b}');
  print('$a / $b = ${a / b}');
  print('$a == ${Bruch(2, 4)}: ${a == Bruch(2, 4)}');
  print('$a > $b: ${a > b}');
  print('${Bruch(6, 8).kuerze()}');
}
```

---

## Aufgabe 4: Polymorphismus & Typprüfung

```dart
abstract class Nachricht {
  final DateTime zeitstempel = DateTime.now();
  String get vorschau;
}

class TextNachricht extends Nachricht {
  final String text;
  TextNachricht(this.text);

  @override
  String get vorschau => text.length > 20 ? '${text.substring(0, 20)}...' : text;
}

class BildNachricht extends Nachricht {
  final String dateiname;
  final int größeBytes;

  BildNachricht(this.dateiname, this.größeBytes);

  @override
  String get vorschau => '📷 $dateiname';
}

class AudioNachricht extends Nachricht {
  final String dateiname;
  final Duration dauer;

  AudioNachricht(this.dateiname, this.dauer);

  @override
  String get vorschau => '🎵 ${dauer.inSeconds}s';
}

Map<String, dynamic> analysiereNachrichten(List<Nachricht> nachrichten) {
  var textCount = 0;
  var bildCount = 0;
  var audioCount = 0;
  var gesamtGröße = 0;
  var gesamtDauer = Duration.zero;

  for (var n in nachrichten) {
    if (n is TextNachricht) {
      textCount++;
    } else if (n is BildNachricht) {
      bildCount++;
      gesamtGröße += n.größeBytes;
    } else if (n is AudioNachricht) {
      audioCount++;
      gesamtDauer += n.dauer;
    }
  }

  return {
    'text': textCount,
    'bild': bildCount,
    'audio': audioCount,
    'gesamtGröße': gesamtGröße,
    'gesamtDauer': gesamtDauer,
  };
}

void main() {
  List<Nachricht> nachrichten = [
    TextNachricht('Hallo Welt!'),
    BildNachricht('foto.jpg', 1024 * 500),
    AudioNachricht('sprachnachricht.mp3', Duration(seconds: 30)),
    TextNachricht('Wie gehts?'),
  ];

  var stats = analysiereNachrichten(nachrichten);
  print('Statistik: $stats');
}
```
