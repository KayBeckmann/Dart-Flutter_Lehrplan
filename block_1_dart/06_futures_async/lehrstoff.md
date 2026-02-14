# Einheit 1.6: Futures & async/await

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 1.1-1.5

---

## 6.1 Das Event-Loop-Modell

Dart ist **single-threaded** mit einem **Event Loop**, ähnlich wie JavaScript:

```dart
void main() {
  print('1: Start');
  Future(() => print('3: Future'));
  print('2: Ende des synchronen Codes');
}
// Ausgabe: 1, 2, 3
```

---

## 6.2 Futures

Ein `Future<T>` repräsentiert einen Wert, der **in der Zukunft** verfügbar sein wird:

```dart
// Future erstellen
Future<String> holeDaten() {
  return Future.delayed(Duration(seconds: 1), () => 'Daten geladen');
}

// Future.value — sofort erfüllt
Future<int> sofort() => Future.value(42);

// Future.error — sofort fehlgeschlagen
Future<int> fehler() => Future.error('Fehler!');
```

### Futures verketten

```dart
void main() {
  holeDaten()
      .then((daten) => print('Erhalten: $daten'))
      .catchError((e) => print('Fehler: $e'))
      .whenComplete(() => print('Fertig'));
}
```

---

## 6.3 async / await

Syntaktischer Zucker für lesbaren asynchronen Code:

```dart
Future<void> hauptprogramm() async {
  print('Start');

  try {
    final daten = await holeDaten();
    print('Daten: $daten');

    final verarbeitet = await verarbeite(daten);
    print('Verarbeitet: $verarbeitet');
  } catch (e) {
    print('Fehler: $e');
  }
}

Future<String> holeDaten() async {
  await Future.delayed(Duration(seconds: 1));
  return 'API-Antwort';
}

Future<String> verarbeite(String daten) async {
  await Future.delayed(Duration(milliseconds: 500));
  return daten.toUpperCase();
}
```

---

## 6.4 Parallele Futures mit `Future.wait`

```dart
Future<void> parallelLaden() async {
  // Alle Futures starten gleichzeitig
  var ergebnisse = await Future.wait([
    Future.delayed(Duration(seconds: 2), () => 'A'),
    Future.delayed(Duration(seconds: 1), () => 'B'),
    Future.delayed(Duration(seconds: 3), () => 'C'),
  ]);

  // Gesamtzeit: ~3 Sekunden (nicht 6!)
  print(ergebnisse);  // [A, B, C]
}
```

### `Future.any` — Das schnellste gewinnt

```dart
var schnellstes = await Future.any([
  Future.delayed(Duration(seconds: 3), () => 'Langsam'),
  Future.delayed(Duration(seconds: 1), () => 'Schnell'),
]);
print(schnellstes);  // Schnell
```

---

## 6.5 Fehlerbehandlung

```dart
Future<void> mitFehler() async {
  try {
    var ergebnis = await riskanteOperation();
    print('OK: $ergebnis');
  } on FormatException catch (e) {
    print('Format-Fehler: $e');
  } on TimeoutException {
    print('Timeout!');
  } catch (e, stackTrace) {
    print('Fehler: $e');
    print('Stack: $stackTrace');
  } finally {
    print('Aufräumen...');
  }
}
```

---

## 6.6 Zusammenfassendes Beispiel

```dart
class ApiClient {
  Future<Map<String, dynamic>> get(String url) async {
    print('GET $url');
    await Future.delayed(Duration(milliseconds: 500));
    return {'status': 'ok', 'data': 'Antwort von $url'};
  }
}

Future<void> ladeAlles() async {
  var api = ApiClient();

  // Parallel laden
  var [benutzer, einstellungen] = await Future.wait([
    api.get('/user'),
    api.get('/settings'),
  ]);

  print('Benutzer: $benutzer');
  print('Einstellungen: $einstellungen');
}

void main() async {
  await ladeAlles();
}
```
