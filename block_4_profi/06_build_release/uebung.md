# Übung 4.6: Build & Release

## Ziel

Eine App für den Release vorbereiten und Store-tauglich machen.

---

## Aufgabe 1: App-Icon konfigurieren (20 min)

1. Erstelle ein App-Icon (mindestens 1024x1024 px)
   - Verwende ein Design-Tool oder einen Generator

2. Konfiguriere `flutter_launcher_icons`:
   - Standard-Icon für iOS und Android
   - Adaptive Icon für Android
   - Foreground und Background

3. Generiere die Icons:
```bash
dart run flutter_launcher_icons
```

4. Überprüfe die generierten Dateien.

---

## Aufgabe 2: Splash Screen einrichten (20 min)

1. Erstelle ein Splash-Logo (PNG mit Transparenz)

2. Konfiguriere `flutter_native_splash`:
   - Hintergrundfarbe passend zum Design
   - Logo zentriert
   - Android 12+ Konfiguration
   - Fullscreen-Option testen

3. Implementiere das Entfernen des Splash nach App-Start:
```dart
// Nach Initialisierung:
FlutterNativeSplash.remove();
```

---

## Aufgabe 3: App-Metadaten konfigurieren (15 min)

Setze folgende Werte für deine App:

### Android
- Application ID: `com.deinname.appname`
- App-Name (Label)
- Version: 1.0.0
- Build Number: 1

### iOS
- Bundle Identifier
- Display Name
- Version & Build

---

## Aufgabe 4: Berechtigungen einrichten (25 min)

Implementiere folgende Berechtigungen:

1. **Internet** (Standard)

2. **Kamera**
   - Android: Manifest
   - iOS: Info.plist mit deutscher Beschreibung

3. **Standort**
   - "When in use" Berechtigung
   - Sinnvolle Beschreibung

4. Implementiere Permission-Request im Code:
```dart
// Beim ersten Kamera-Zugriff
Future<bool> requestCameraPermission() async {
  // ...
}
```

5. Handle alle Fälle:
   - Granted
   - Denied
   - Permanently Denied → Settings öffnen

---

## Aufgabe 5: Build-Varianten (20 min)

Erstelle zwei Build-Varianten:

### Development
- App ID: `com.example.app.dev`
- App Name: "MyApp Dev"
- API URL: `https://dev-api.example.com`

### Production
- App ID: `com.example.app`
- App Name: "MyApp"
- API URL: `https://api.example.com`

Nutze:
- Android Flavors
- `--dart-define` für Variablen

---

## Aufgabe 6: Release Build erstellen (25 min)

### Android

1. Erstelle einen Keystore:
```bash
keytool -genkey -v -keystore my-release-key.jks ...
```

2. Konfiguriere `key.properties`

3. Konfiguriere `build.gradle` für Signing

4. Erstelle Release-Builds:
```bash
flutter build apk --release
flutter build appbundle --release
```

5. Notiere die Dateigrößen

### iOS (falls Mac verfügbar)

1. Öffne Xcode und konfiguriere Signing
2. Erstelle einen Archive-Build
3. Exportiere für Ad-Hoc Distribution

---

## Aufgabe 7: Store-Assets vorbereiten (20 min)

Erstelle folgende Assets:

### Screenshots
- Mindestens 3 Screenshots
- In korrekten Größen
- Mit App-Inhalt (nicht Splash)

### Beschreibungstexte
- Kurzbeschreibung (80 Zeichen)
- Vollständige Beschreibung (4000 Zeichen)
- Keywords/Tags

### Grafiken
- Feature Graphic für Play Store (1024x500)
- Promotional Text

---

## Aufgabe 8: Pre-Release Checkliste (15 min)

Gehe die folgende Checkliste durch:

### Code-Qualität
- [ ] Keine Debug-Prints im Code
- [ ] Keine hardcodierten Test-URLs
- [ ] Keine Test-Accounts
- [ ] Error Handling vollständig

### Konfiguration
- [ ] Korrekter App-Name
- [ ] Korrekte Bundle/Package ID
- [ ] Version und Build Number gesetzt
- [ ] Berechtigungen minimiert

### Assets
- [ ] App-Icon in allen Größen
- [ ] Splash Screen konfiguriert
- [ ] Screenshots erstellt

### Testing
- [ ] Release-Build getestet
- [ ] Auf echtem Gerät getestet
- [ ] Kritische Flows manuell geprüft

### Store
- [ ] Datenschutzerklärung URL
- [ ] Support-Kontakt
- [ ] Beschreibungstexte

---

## Bonus: CI/CD Pipeline

Erstelle eine GitHub Actions Workflow-Datei:

```yaml
# .github/workflows/release.yml

# Trigger: Bei Tag mit v* (z.B. v1.0.0)
# Jobs:
# 1. Tests ausführen
# 2. Android APK bauen
# 3. Artifacts hochladen
```

---

## Abgabe-Checkliste

- [ ] App-Icon generiert und sichtbar
- [ ] Splash Screen funktioniert
- [ ] App-Name und ID konfiguriert
- [ ] Berechtigungen eingerichtet
- [ ] Permission-Request implementiert
- [ ] Build-Varianten konfiguriert
- [ ] Release-APK erstellt
- [ ] Store-Assets vorbereitet
- [ ] Pre-Release Checkliste durchgegangen
