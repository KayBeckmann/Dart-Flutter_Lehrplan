# Übung 4.5: Packages & Plugins

## Ziel

Eigene Packages erstellen und Platform Channels nutzen.

---

## Aufgabe 1: Package-Recherche (15 min)

Recherchiere auf pub.dev:

1. Finde 3 State Management Packages und vergleiche:
   - Pub Points
   - Likes
   - Letzte Aktualisierung
   - Dokumentationsqualität

2. Finde ein Package für:
   - PDF-Generierung
   - Biometrie-Authentifizierung
   - Push Notifications

Dokumentiere deine Entscheidungskriterien.

---

## Aufgabe 2: Validator Package (30 min)

Erstelle ein eigenes Validierungs-Package:

```
my_validators/
├── lib/
│   ├── my_validators.dart
│   └── src/
│       ├── email_validator.dart
│       ├── password_validator.dart
│       ├── phone_validator.dart
│       └── iban_validator.dart
├── test/
├── example/
├── pubspec.yaml
└── README.md
```

Anforderungen:
- Alle Validatoren als static methods
- Konfigurierbare Regeln für Passwort
- Deutsche und internationale Telefonnummern
- IBAN-Validierung (vereinfacht)
- Vollständige Dartdoc-Kommentare
- Unit Tests für alle Validatoren
- Beispiel-App

---

## Aufgabe 3: Widget Package (25 min)

Erstelle ein Package mit wiederverwendbaren Widgets:

```dart
// Widgets die das Package enthalten soll:

// 1. LoadingButton
// - Zeigt CircularProgressIndicator während isLoading
// - Deaktiviert während Loading
LoadingButton(
  isLoading: _isLoading,
  onPressed: _submit,
  child: Text('Submit'),
)

// 2. RatingBar
// - Interaktive Sterne-Bewertung (1-5)
// - Callback für Änderungen
RatingBar(
  rating: 3,
  onRatingChanged: (rating) {},
)

// 3. ExpandableText
// - Text mit "mehr anzeigen" wenn zu lang
ExpandableText(
  text: longText,
  maxLines: 3,
)
```

---

## Aufgabe 4: Platform Channel - Device Info (30 min)

Implementiere einen Platform Channel für Geräteinformationen:

```dart
class DeviceInfoService {
  // Implementiere:
  Future<String> getDeviceModel();
  Future<String> getOsVersion();
  Future<int> getAvailableStorage();  // in MB
  Future<bool> isEmulator();
}
```

Implementiere für:
- Android (Kotlin)
- iOS (Swift) - optional

---

## Aufgabe 5: EventChannel - Connectivity (25 min)

Erstelle einen EventChannel für Netzwerk-Status:

```dart
class ConnectivityService {
  Stream<ConnectivityStatus> get statusStream;
}

enum ConnectivityStatus {
  wifi,
  mobile,
  none,
}
```

Der Stream soll:
- Initial den aktuellen Status senden
- Bei Änderungen updaten
- Korrekt disposen

---

## Aufgabe 6: Plattform-spezifisches UI (20 min)

Erstelle adaptive Widgets:

```dart
// 1. AdaptiveScaffold
// - iOS: CupertinoPageScaffold
// - Android: Scaffold mit AppBar

// 2. AdaptiveListTile
// - iOS: CupertinoListTile style
// - Android: Material ListTile

// 3. AdaptiveSwitch
// - iOS: CupertinoSwitch
// - Android: Material Switch

// 4. AdaptiveProgressIndicator
// - iOS: CupertinoActivityIndicator
// - Android: CircularProgressIndicator
```

---

## Aufgabe 7: Package veröffentlichen (Dry-Run) (20 min)

Bereite dein Validator-Package zur Veröffentlichung vor:

1. Vervollständige README.md:
   - Features-Liste
   - Installation
   - Usage mit Code-Beispielen
   - API-Dokumentation

2. Erstelle CHANGELOG.md

3. Füge LICENSE hinzu (MIT)

4. Führe aus:
```bash
flutter pub publish --dry-run
```

5. Behebe alle gemeldeten Probleme

---

## Aufgabe 8: Plugin-Struktur verstehen (15 min)

Analysiere ein bestehendes Plugin:

```bash
# Clone ein einfaches Plugin
git clone https://github.com/miguelpruivo/flutter_file_picker

# Oder schaue dir an:
# - shared_preferences
# - url_launcher
# - image_picker
```

Dokumentiere:
- Wie ist der Code organisiert?
- Wo ist der Dart-Code?
- Wo ist der Android/iOS Code?
- Wie kommunizieren sie?

---

## Bonus: Pigeon für Type-Safe Channels

Nutze das `pigeon` Package für typsichere Platform Channels:

```dart
// pigeons/messages.dart
import 'package:pigeon/pigeon.dart';

class DeviceInfo {
  String? model;
  String? osVersion;
}

@HostApi()
abstract class DeviceInfoApi {
  DeviceInfo getDeviceInfo();
}
```

```bash
# Code generieren
flutter pub run pigeon --input pigeons/messages.dart
```

---

## Abgabe-Checkliste

- [ ] Package-Vergleich dokumentiert
- [ ] Validator Package erstellt
- [ ] Alle Validatoren getestet
- [ ] Widget Package mit 3 Widgets
- [ ] Platform Channel für Device Info
- [ ] EventChannel für Connectivity
- [ ] Adaptive Widgets implementiert
- [ ] Package publish --dry-run erfolgreich
- [ ] Plugin-Struktur dokumentiert
