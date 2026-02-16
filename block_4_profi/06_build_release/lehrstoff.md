# Einheit 4.6: Build & Release

## Lernziele

Nach dieser Einheit kannst du:
- App-Icons und Splash Screens konfigurieren
- Berechtigungen für Android und iOS setzen
- Release-Builds erstellen
- Apps für den Store vorbereiten

---

## 1. App-Icons

### flutter_launcher_icons Package

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21

  # Adaptive Icon für Android
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"

  # Web
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#FFFFFF"
    theme_color: "#2196F3"
```

```bash
# Icons generieren
dart run flutter_launcher_icons
```

### Manuell (Android)

```
android/app/src/main/res/
├── mipmap-hdpi/
│   └── ic_launcher.png       # 72x72
├── mipmap-mdpi/
│   └── ic_launcher.png       # 48x48
├── mipmap-xhdpi/
│   └── ic_launcher.png       # 96x96
├── mipmap-xxhdpi/
│   └── ic_launcher.png       # 144x144
└── mipmap-xxxhdpi/
    └── ic_launcher.png       # 192x192
```

### Manuell (iOS)

```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
├── Icon-App-20x20@1x.png
├── Icon-App-20x20@2x.png
├── Icon-App-20x20@3x.png
├── Icon-App-29x29@1x.png
├── ... (alle Größen)
└── Contents.json
```

---

## 2. Splash Screens

### flutter_native_splash Package

```yaml
# pubspec.yaml
dev_dependencies:
  flutter_native_splash: ^2.3.0

flutter_native_splash:
  color: "#FFFFFF"
  image: assets/splash/logo.png

  # Android 12+ Splash
  android_12:
    color: "#FFFFFF"
    icon_background_color: "#FFFFFF"
    image: assets/splash/logo.png

  # iOS
  ios: true

  # Web
  web: true
  web_image_mode: center

  # Fullscreen (keine Statusbar)
  fullscreen: false
```

```bash
# Splash Screen generieren
dart run flutter_native_splash:create

# Splash entfernen (nach App-Start)
dart run flutter_native_splash:remove
```

### Im Code entfernen

```dart
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() {
  // Splash behalten während Initialisierung
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialisierung...
  await initializeApp();

  // Splash entfernen
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}
```

---

## 3. App-Name & Bundle ID

### Android

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.my_app">

    <application
        android:label="Meine App"
        android:icon="@mipmap/ic_launcher">
        ...
    </application>
</manifest>
```

```groovy
// android/app/build.gradle
android {
    defaultConfig {
        applicationId "com.mycompany.myapp"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### iOS

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <key>CFBundleName</key>
    <string>Meine App</string>

    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>

    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
</dict>
```

In Xcode:
- Runner → General → Identity → Bundle Identifier

---

## 4. Berechtigungen

### Android Berechtigungen

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest>
    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Kamera -->
    <uses-permission android:name="android.permission.CAMERA"/>

    <!-- Speicher -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

    <!-- Standort -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <!-- Mikrofon -->
    <uses-permission android:name="android.permission.RECORD_AUDIO"/>

    <!-- Benachrichtigungen -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

    <application ...>
</manifest>
```

### iOS Berechtigungen

```xml
<!-- ios/Runner/Info.plist -->
<dict>
    <!-- Kamera -->
    <key>NSCameraUsageDescription</key>
    <string>Diese App benötigt Zugriff auf die Kamera für Fotos.</string>

    <!-- Fotobibliothek -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Diese App benötigt Zugriff auf Fotos.</string>

    <!-- Standort -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Diese App benötigt Ihren Standort für...</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>Diese App benötigt Standortzugriff im Hintergrund.</string>

    <!-- Mikrofon -->
    <key>NSMicrophoneUsageDescription</key>
    <string>Diese App benötigt Zugriff auf das Mikrofon.</string>

    <!-- Kontakte -->
    <key>NSContactsUsageDescription</key>
    <string>Diese App benötigt Zugriff auf Ihre Kontakte.</string>

    <!-- Face ID -->
    <key>NSFaceIDUsageDescription</key>
    <string>Diese App nutzt Face ID zur Authentifizierung.</string>
</dict>
```

### Permission Handler Package

```yaml
dependencies:
  permission_handler: ^11.0.0
```

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> requestCameraPermission() async {
  final status = await Permission.camera.request();

  if (status.isGranted) {
    // Berechtigung erteilt
  } else if (status.isDenied) {
    // Berechtigung abgelehnt
  } else if (status.isPermanentlyDenied) {
    // Permanent abgelehnt → Einstellungen öffnen
    await openAppSettings();
  }
}

// Mehrere Berechtigungen
Future<void> requestPermissions() async {
  final statuses = await [
    Permission.camera,
    Permission.microphone,
    Permission.storage,
  ].request();

  if (statuses[Permission.camera]!.isGranted) {
    // Kamera OK
  }
}
```

---

## 5. Build-Konfiguration

### Flavor/Build Variants

```groovy
// android/app/build.gradle
android {
    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "MyApp Dev"
        }
        staging {
            dimension "environment"
            applicationIdSuffix ".staging"
            versionNameSuffix "-staging"
            resValue "string", "app_name", "MyApp Staging"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "MyApp"
        }
    }
}
```

```bash
# Build mit Flavor
flutter build apk --flavor dev
flutter build apk --flavor prod
```

### Environment Variables

```dart
// lib/config/environment.dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.example.com',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );
}
```

```bash
# Build mit Variablen
flutter build apk --dart-define=API_URL=https://prod.api.com --dart-define=PRODUCTION=true
```

---

## 6. Release Builds

### Android Release

```bash
# APK (Universal)
flutter build apk --release

# APK pro Architektur (kleiner)
flutter build apk --split-per-abi

# App Bundle (für Play Store)
flutter build appbundle --release
```

### Keystore erstellen (Android)

```bash
# Keystore generieren
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

```properties
# android/key.properties (nicht committen!)
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/path/to/upload-keystore.jks
```

```groovy
// android/app/build.gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### iOS Release

```bash
# iOS Build (Archiv)
flutter build ios --release

# IPA für Distribution
flutter build ipa --release
```

In Xcode:
1. Product → Archive
2. Distribute App → App Store Connect

---

## 7. App Store Vorbereitung

### Google Play Store

Benötigt:
- App Bundle (.aab)
- App-Icon (512x512)
- Feature Graphic (1024x500)
- Screenshots (mind. 2)
- Beschreibung (kurz & lang)
- Datenschutzerklärung URL
- Content Rating (Fragebogen)

### Apple App Store

Benötigt:
- Build über Xcode/Transporter
- App-Icon (1024x1024, ohne Alpha)
- Screenshots für alle Geräte
- App-Beschreibung
- Keywords
- Support URL
- Privacy Policy URL
- App Store Connect Konfiguration

### App Store Screenshots

```yaml
# Größen für iOS
- iPhone 6.7" (1290 x 2796)
- iPhone 6.5" (1284 x 2778)
- iPhone 5.5" (1242 x 2208)
- iPad Pro 12.9" (2048 x 2732)

# Größen für Android
- Phone (1080 x 1920)
- 7" Tablet (1200 x 1920)
- 10" Tablet (1800 x 2560)
```

---

## 8. ProGuard & Code Shrinking

### ProGuard Rules (Android)

```proguard
# android/app/proguard-rules.pro

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase (falls verwendet)
-keep class com.google.firebase.** { *; }

# JSON Serialization (falls reflection)
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
```

### Build-Optimierungen

```groovy
// android/app/build.gradle
android {
    buildTypes {
        release {
            minifyEnabled true     // Code Shrinking
            shrinkResources true   // Resource Shrinking
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
        }
    }
}
```

---

## 9. CI/CD Basics

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - run: flutter pub get
      - run: flutter test
      - run: flutter build apk --release

      - uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - run: flutter pub get
      - run: flutter test
      - run: flutter build ios --release --no-codesign
```

### Fastlane (Optional)

```ruby
# ios/fastlane/Fastfile
default_platform(:ios)

platform :ios do
  desc "Deploy to TestFlight"
  lane :beta do
    build_app(scheme: "Runner")
    upload_to_testflight
  end
end
```

---

## 10. Debugging Release Builds

### Symbolicate Crash Reports

```bash
# Android - Mapping-Datei
build/app/outputs/mapping/release/mapping.txt

# iOS - dSYM Dateien
build/ios/archive/Runner.xcarchive/dSYMs/
```

### Release mit Debug-Info

```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# iOS
flutter build ios --release --obfuscate --split-debug-info=build/debug-info
```

---

## Zusammenfassung

| Thema | Tool/Methode |
|-------|--------------|
| App Icons | `flutter_launcher_icons` |
| Splash Screen | `flutter_native_splash` |
| Berechtigungen | `permission_handler` |
| Android Build | `flutter build apk/appbundle` |
| iOS Build | `flutter build ios/ipa` |
| Signing | Keystore (Android), Xcode (iOS) |
| CI/CD | GitHub Actions, Fastlane |

**Checkliste vor Release:**
- [ ] App-Icon in allen Größen
- [ ] Splash Screen konfiguriert
- [ ] Alle Berechtigungen mit Beschreibung
- [ ] Release-Signatur eingerichtet
- [ ] ProGuard konfiguriert
- [ ] Tests bestanden
- [ ] Store-Beschreibung & Screenshots
- [ ] Datenschutzerklärung verlinkt
