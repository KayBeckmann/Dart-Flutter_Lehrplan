# Übung 1.6: Futures & async/await

> **Dauer:** ca. 60 Minuten

---

## Aufgabe 1: Basis-Futures (15 Min.)

```dart
void main() async {
  // TODO: Implementiere holeBenutzername(int id)
  // - Simuliere 500ms Verzögerung
  // - Gib "Benutzer_$id" zurück
  // - Werfe Exception wenn id < 0

  print(await holeBenutzername(1));   // Benutzer_1
  print(await holeBenutzername(42));  // Benutzer_42

  try {
    print(await holeBenutzername(-1));
  } catch (e) {
    print('Fehler: $e');
  }
}
```

---

## Aufgabe 2: Verkettete Futures (15 Min.)

```dart
void main() async {
  // Simuliere: Login -> Profil laden -> Einstellungen laden
  // Jeder Schritt hängt vom vorherigen ab

  var benutzer = await login('max@mail.de', 'geheim');
  print('Eingeloggt: ${benutzer['name']}');

  var profil = await ladeProfil(benutzer['id'] as int);
  print('Profil: $profil');

  var settings = await ladeEinstellungen(benutzer['id'] as int);
  print('Einstellungen: $settings');
}

// TODO: Implementiere login(), ladeProfil(), ladeEinstellungen()
// Jede Funktion mit ~300ms Verzögerung
```

---

## Aufgabe 3: Parallele Futures (15 Min.)

```dart
void main() async {
  var start = DateTime.now();

  // TODO: Lade alle drei Ressourcen PARALLEL mit Future.wait
  // Jede dauert 1 Sekunde
  // Gesamtzeit sollte ~1 Sekunde sein (nicht 3)

  var [wetter, nachrichten, aktien] = await Future.wait([
    ladeWetter(),
    ladeNachrichten(),
    ladeAktien(),
  ]);

  var dauer = DateTime.now().difference(start);
  print('Geladen in ${dauer.inMilliseconds}ms');
  print('Wetter: $wetter');
  print('Nachrichten: $nachrichten');
  print('Aktien: $aktien');
}

// TODO: Implementiere die drei Lade-Funktionen
```

---

## Aufgabe 4: Timeout & Retry (15 Min.)

```dart
void main() async {
  // TODO: Implementiere mitTimeout<T>(Future<T> future, Duration timeout)
  // - Gibt das Ergebnis zurück wenn rechtzeitig
  // - Wirft TimeoutException wenn zu langsam

  try {
    var schnell = await mitTimeout(
      Future.delayed(Duration(milliseconds: 100), () => 'OK'),
      Duration(milliseconds: 500),
    );
    print('Schnell: $schnell');

    var langsam = await mitTimeout(
      Future.delayed(Duration(seconds: 2), () => 'Zu spät'),
      Duration(milliseconds: 500),
    );
    print('Langsam: $langsam');
  } on TimeoutException {
    print('Timeout!');
  }

  // BONUS: Implementiere retry<T>(Future<T> Function() fn, int versuche)
}
```

---

## Bonusaufgabe: API-Client mit Cache

```dart
void main() async {
  var client = CachingApiClient();

  // Erster Aufruf: Lädt von "Server"
  print(await client.get('/users'));  // Lädt...

  // Zweiter Aufruf: Aus Cache
  print(await client.get('/users'));  // Sofort!

  // Cache leeren
  client.leereCache();
  print(await client.get('/users'));  // Lädt wieder...
}

// TODO: Implementiere CachingApiClient
// - get(String url) cached Ergebnisse
// - leereCache() löscht den Cache
```
