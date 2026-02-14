# Lösung 1.6: Futures & async/await

---

## Aufgabe 1

```dart
Future<String> holeBenutzername(int id) async {
  if (id < 0) throw ArgumentError('ID muss positiv sein');
  await Future.delayed(Duration(milliseconds: 500));
  return 'Benutzer_$id';
}
```

---

## Aufgabe 2

```dart
Future<Map<String, dynamic>> login(String email, String passwort) async {
  await Future.delayed(Duration(milliseconds: 300));
  return {'id': 1, 'name': 'Max', 'email': email};
}

Future<Map<String, dynamic>> ladeProfil(int userId) async {
  await Future.delayed(Duration(milliseconds: 300));
  return {'bio': 'Entwickler', 'avatar': 'avatar.png'};
}

Future<Map<String, dynamic>> ladeEinstellungen(int userId) async {
  await Future.delayed(Duration(milliseconds: 300));
  return {'theme': 'dark', 'notifications': true};
}
```

---

## Aufgabe 3

```dart
Future<String> ladeWetter() async {
  await Future.delayed(Duration(seconds: 1));
  return 'Sonnig, 22°C';
}

Future<List<String>> ladeNachrichten() async {
  await Future.delayed(Duration(seconds: 1));
  return ['Nachricht 1', 'Nachricht 2'];
}

Future<Map<String, double>> ladeAktien() async {
  await Future.delayed(Duration(seconds: 1));
  return {'AAPL': 150.0, 'GOOGL': 2800.0};
}
```

---

## Aufgabe 4

```dart
import 'dart:async';

Future<T> mitTimeout<T>(Future<T> future, Duration timeout) {
  return future.timeout(timeout);
}

// Alternativ manuell:
Future<T> mitTimeoutManuell<T>(Future<T> future, Duration timeout) async {
  var ergebnis = await Future.any([
    future,
    Future.delayed(timeout, () => throw TimeoutException('Timeout')),
  ]);
  return ergebnis as T;
}

// Bonus: Retry
Future<T> retry<T>(Future<T> Function() fn, int versuche) async {
  for (var i = 0; i < versuche; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i == versuche - 1) rethrow;
      await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
    }
  }
  throw StateError('Unreachable');
}
```

---

## Bonusaufgabe

```dart
class CachingApiClient {
  final Map<String, dynamic> _cache = {};

  Future<dynamic> get(String url) async {
    if (_cache.containsKey(url)) {
      print('Cache-Hit: $url');
      return _cache[url];
    }

    print('Lade: $url');
    await Future.delayed(Duration(milliseconds: 500));
    var daten = {'url': url, 'data': 'Response'};
    _cache[url] = daten;
    return daten;
  }

  void leereCache() => _cache.clear();
}
```
