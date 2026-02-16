# Lösung 4.6: Build & Release

## Aufgabe 1 & 2: App-Icon und Splash Screen

### pubspec.yaml

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
  flutter_native_splash: ^2.3.0

# App Icon Konfiguration
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"
  min_sdk_android: 21

  # Adaptive Icon (Android)
  adaptive_icon_background: "#2196F3"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"

  # Web
  web:
    generate: true
    image_path: "assets/icon/app_icon.png"
    background_color: "#2196F3"
    theme_color: "#2196F3"

# Splash Screen Konfiguration
flutter_native_splash:
  color: "#2196F3"
  image: assets/splash/logo.png

  android_12:
    color: "#2196F3"
    icon_background_color: "#2196F3"
    image: assets/splash/logo.png

  ios: true
  web: true
  fullscreen: false
```

### Icons und Splash generieren

```bash
# Icons generieren
dart run flutter_launcher_icons

# Splash Screen generieren
dart run flutter_native_splash:create
```

### Splash im Code entfernen

```dart
// lib/main.dart
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  // Splash behalten
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // App initialisieren
  await _initializeApp();

  // Splash entfernen
  FlutterNativeSplash.remove();

  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  // SharedPreferences laden
  // Firebase initialisieren
  // etc.
  await Future.delayed(const Duration(seconds: 1));
}
```

---

## Aufgabe 3: App-Metadaten

### Android - android/app/build.gradle

```groovy
android {
    namespace "com.deinname.appname"
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.deinname.appname"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### Android - AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application
        android:label="Meine App"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round">
        ...
    </application>
</manifest>
```

### iOS - Info.plist

```xml
<dict>
    <key>CFBundleDisplayName</key>
    <string>Meine App</string>

    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>

    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>

    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
</dict>
```

---

## Aufgabe 4: Berechtigungen

### Android - AndroidManifest.xml

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Internet -->
    <uses-permission android:name="android.permission.INTERNET"/>

    <!-- Kamera -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>

    <!-- Standort -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>

    <application ...>
    </application>
</manifest>
```

### iOS - Info.plist

```xml
<dict>
    <!-- Kamera -->
    <key>NSCameraUsageDescription</key>
    <string>Diese App benötigt Zugriff auf die Kamera, um Fotos aufzunehmen.</string>

    <!-- Standort -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Diese App benötigt Ihren Standort, um Ihnen relevante Inhalte in Ihrer Nähe anzuzeigen.</string>

    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Diese App benötigt Ihren Standort auch im Hintergrund für Benachrichtigungen.</string>
</dict>
```

### Permission Handler Implementation

```dart
// lib/services/permission_service.dart
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Fordert Kamera-Berechtigung an
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Dialog anzeigen und zu Einstellungen leiten
      final opened = await openAppSettings();
      if (opened) {
        // Warten bis User zurückkommt und erneut prüfen
        await Future.delayed(const Duration(seconds: 1));
        return await Permission.camera.isGranted;
      }
    }

    return false;
  }

  /// Fordert Standort-Berechtigung an
  Future<bool> requestLocationPermission() async {
    // Zuerst prüfen ob Location Services aktiviert
    final serviceEnabled = await Permission.location.serviceStatus.isEnabled;
    if (!serviceEnabled) {
      // User auffordern Location Services zu aktivieren
      return false;
    }

    var status = await Permission.locationWhenInUse.status;

    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  /// Prüft alle benötigten Berechtigungen
  Future<Map<Permission, PermissionStatus>> checkAllPermissions() async {
    return await [
      Permission.camera,
      Permission.locationWhenInUse,
    ].request();
  }
}

// Verwendung im Widget
class CameraButton extends StatelessWidget {
  final PermissionService _permissionService = PermissionService();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final granted = await _permissionService.requestCameraPermission();
        if (granted) {
          // Kamera öffnen
          _openCamera(context);
        } else {
          // Fehlermeldung
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kamera-Berechtigung erforderlich'),
            ),
          );
        }
      },
      child: const Text('Kamera öffnen'),
    );
  }

  void _openCamera(BuildContext context) {
    // Kamera-Logik
  }
}
```

---

## Aufgabe 5: Build-Varianten

### android/app/build.gradle

```groovy
android {
    flavorDimensions "environment"

    productFlavors {
        dev {
            dimension "environment"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "MyApp Dev"
        }
        prod {
            dimension "environment"
            resValue "string", "app_name", "MyApp"
        }
    }
}
```

### Environment Config

```dart
// lib/config/environment.dart
class Environment {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://dev-api.example.com',
  );

  static const bool isProduction = bool.fromEnvironment(
    'PRODUCTION',
    defaultValue: false,
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'MyApp Dev',
  );
}

// Verwendung
class ApiService {
  final _baseUrl = Environment.apiUrl;

  Future<Response> get(String path) {
    return http.get(Uri.parse('$_baseUrl/$path'));
  }
}
```

### Build-Befehle

```bash
# Development
flutter build apk --flavor dev \
  --dart-define=API_URL=https://dev-api.example.com \
  --dart-define=PRODUCTION=false

# Production
flutter build apk --flavor prod \
  --dart-define=API_URL=https://api.example.com \
  --dart-define=PRODUCTION=true
```

---

## Aufgabe 6: Release Build

### Keystore erstellen

```bash
keytool -genkey -v \
  -keystore ~/my-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias my-key-alias
```

### android/key.properties

```properties
storePassword=<dein-store-passwort>
keyPassword=<dein-key-passwort>
keyAlias=my-key-alias
storeFile=/Users/dein-name/my-release-key.jks
```

### android/app/build.gradle

```groovy
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
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### Build ausführen

```bash
# Release APK
flutter build apk --release

# Release App Bundle (für Play Store)
flutter build appbundle --release

# Mit Obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
```

---

## Bonus: GitHub Actions

### .github/workflows/release.yml

```yaml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'

      - name: Get dependencies
        run: flutter pub get

      - name: Run tests
        run: flutter test

      - name: Decode Keystore
        run: |
          echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 --decode > android/app/keystore.jks

      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=${{ secrets.KEY_ALIAS }}" >> android/key.properties
          echo "storeFile=keystore.jks" >> android/key.properties

      - name: Build APK
        run: flutter build apk --release

      - name: Build App Bundle
        run: flutter build appbundle --release

      - name: Upload APK
        uses: actions/upload-artifact@v3
        with:
          name: release-apk
          path: build/app/outputs/flutter-apk/app-release.apk

      - name: Upload AAB
        uses: actions/upload-artifact@v3
        with:
          name: release-aab
          path: build/app/outputs/bundle/release/app-release.aab

  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'

      - name: Get dependencies
        run: flutter pub get

      - name: Build iOS (no codesign)
        run: flutter build ios --release --no-codesign

      # Für echtes Signing: Certificates und Provisioning Profiles einrichten
```
