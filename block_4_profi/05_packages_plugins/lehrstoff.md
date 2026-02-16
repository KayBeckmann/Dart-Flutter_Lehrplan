# Einheit 4.5: Packages & Plugins

## Lernziele

Nach dieser Einheit kannst du:
- Packages von pub.dev nutzen und bewerten
- Eigene Packages erstellen und veröffentlichen
- Platform Channels (MethodChannel) verstehen
- Plattform-spezifischen Code schreiben

---

## 1. Packages verwenden

### Package hinzufügen

```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  provider: ^6.1.0
  shared_preferences: ^2.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.0
```

```bash
# Package hinzufügen
flutter pub add http
flutter pub add --dev mocktail

# Dependencies installieren
flutter pub get

# Veraltete Dependencies prüfen
flutter pub outdated

# Dependencies aktualisieren
flutter pub upgrade
```

### Package-Qualität bewerten

Auf pub.dev achten auf:
- **Likes** - Community-Beliebtheit
- **Pub Points** - Qualitätsmetriken (max 140)
- **Popularity** - Nutzungshäufigkeit
- **Null Safety** - Dart 3 kompatibel
- **Platform Support** - iOS, Android, Web, Desktop
- **Maintenance** - Letzte Updates, offene Issues

### Wichtige Packages

| Kategorie | Package | Beschreibung |
|-----------|---------|--------------|
| State | `provider`, `riverpod`, `bloc` | State Management |
| HTTP | `http`, `dio` | Netzwerk-Requests |
| Storage | `shared_preferences`, `hive`, `sqflite` | Lokale Daten |
| UI | `flutter_svg`, `cached_network_image` | Erweiterte Widgets |
| Utils | `intl`, `path_provider`, `url_launcher` | Hilfsfunktionen |
| Testing | `mocktail`, `bloc_test` | Test-Utilities |

---

## 2. Eigene Packages erstellen

### Package-Projekt anlegen

```bash
# Dart Package (nur Dart-Code)
flutter create --template=package my_package

# Flutter Plugin (mit Plattform-Code)
flutter create --template=plugin --platforms=android,ios my_plugin
```

### Package-Struktur

```
my_package/
├── lib/
│   ├── my_package.dart        # Haupt-Export
│   └── src/
│       ├── models/
│       │   └── user.dart
│       └── services/
│           └── api_service.dart
├── test/
│   └── my_package_test.dart
├── example/                    # Beispiel-App
│   └── lib/
│       └── main.dart
├── pubspec.yaml
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### Haupt-Export-Datei

```dart
// lib/my_package.dart

/// A useful package for doing things.
library my_package;

// Public exports
export 'src/models/user.dart';
export 'src/services/api_service.dart' show ApiService;
export 'src/utils/validators.dart' hide internalHelper;
```

### pubspec.yaml für Package

```yaml
name: my_package
description: A useful Flutter package for managing users.
version: 1.0.0
homepage: https://github.com/username/my_package
repository: https://github.com/username/my_package
issue_tracker: https://github.com/username/my_package/issues

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

# Für reine Dart-Packages (ohne Flutter):
# environment:
#   sdk: '>=3.0.0 <4.0.0'
#
# dependencies:
#   http: ^1.1.0
```

### Beispiel: Validatoren-Package

```dart
// lib/src/validators.dart

/// Email validator
class EmailValidator {
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+$',
  );

  /// Validates an email address.
  ///
  /// Returns `true` if [email] is a valid email format.
  ///
  /// Example:
  /// ```dart
  /// EmailValidator.isValid('test@example.com'); // true
  /// EmailValidator.isValid('invalid'); // false
  /// ```
  static bool isValid(String email) {
    return _emailRegex.hasMatch(email);
  }
}

/// Password validator with configurable rules.
class PasswordValidator {
  final int minLength;
  final bool requireUppercase;
  final bool requireDigit;
  final bool requireSpecial;

  const PasswordValidator({
    this.minLength = 8,
    this.requireUppercase = true,
    this.requireDigit = true,
    this.requireSpecial = false,
  });

  /// Validates a password against configured rules.
  ValidationResult validate(String password) {
    final errors = <String>[];

    if (password.length < minLength) {
      errors.add('Minimum $minLength characters required');
    }
    if (requireUppercase && !password.contains(RegExp(r'[A-Z]'))) {
      errors.add('Uppercase letter required');
    }
    if (requireDigit && !password.contains(RegExp(r'[0-9]'))) {
      errors.add('Digit required');
    }
    if (requireSpecial && !password.contains(RegExp(r'[!@#$%^&*]'))) {
      errors.add('Special character required');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
    );
  }
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;

  const ValidationResult({
    required this.isValid,
    required this.errors,
  });
}
```

---

## 3. Package veröffentlichen

### Vorbereitung

```bash
# Package analysieren
flutter pub publish --dry-run

# Typische Probleme beheben:
# - README.md hinzufügen
# - CHANGELOG.md pflegen
# - LICENSE-Datei hinzufügen
# - Description in pubspec.yaml
# - Dartdoc-Kommentare
```

### README.md Template

```markdown
# my_package

A Flutter package for user validation.

## Features

- Email validation
- Password validation with configurable rules
- Phone number validation

## Getting started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  my_package: ^1.0.0
```

## Usage

```dart
import 'package:my_package/my_package.dart';

// Email validation
if (EmailValidator.isValid('test@example.com')) {
  print('Valid email!');
}

// Password validation
final validator = PasswordValidator(
  minLength: 8,
  requireUppercase: true,
);
final result = validator.validate('MyPassword1');
print(result.isValid); // true
```

## Additional information

For more examples, see the `/example` folder.
```

### CHANGELOG.md

```markdown
## 1.0.0

- Initial release
- Email validation
- Password validation

## 1.0.1

- Added phone number validation
- Bug fix for special characters

## 1.1.0

- Added German locale support
- Breaking: Renamed `ValidationResult.valid` to `isValid`
```

### Veröffentlichen

```bash
# Auf pub.dev veröffentlichen
flutter pub publish

# Bei erstem Publish: Authentifizierung erforderlich
# Folge den Anweisungen im Terminal
```

---

## 4. Platform Channels

### MethodChannel Grundlagen

```dart
// Dart-Seite
import 'package:flutter/services.dart';

class BatteryService {
  static const _channel = MethodChannel('com.example/battery');

  Future<int> getBatteryLevel() async {
    try {
      final level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level ?? -1;
    } on PlatformException catch (e) {
      print('Failed to get battery level: ${e.message}');
      return -1;
    }
  }

  Future<bool> isCharging() async {
    final charging = await _channel.invokeMethod<bool>('isCharging');
    return charging ?? false;
  }
}
```

### Android Implementation (Kotlin)

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
package com.example.my_app

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        val batteryLevel = getBatteryLevel()
                        if (batteryLevel != -1) {
                            result.success(batteryLevel)
                        } else {
                            result.error("UNAVAILABLE", "Battery level not available", null)
                        }
                    }
                    "isCharging" -> {
                        result.success(isCharging())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        return batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    }

    private fun isCharging(): Boolean {
        val intent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val status = intent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        return status == BatteryManager.BATTERY_STATUS_CHARGING ||
               status == BatteryManager.BATTERY_STATUS_FULL
    }
}
```

### iOS Implementation (Swift)

```swift
// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController
        let batteryChannel = FlutterMethodChannel(
            name: "com.example/battery",
            binaryMessenger: controller.binaryMessenger
        )

        batteryChannel.setMethodCallHandler { [weak self] (call, result) in
            switch call.method {
            case "getBatteryLevel":
                result(self?.getBatteryLevel())
            case "isCharging":
                result(self?.isCharging())
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func getBatteryLevel() -> Int {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return Int(UIDevice.current.batteryLevel * 100)
    }

    private func isCharging() -> Bool {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UIDevice.current.batteryState == .charging ||
               UIDevice.current.batteryState == .full
    }
}
```

---

## 5. EventChannel für Streams

### Dart-Seite

```dart
class BatteryMonitor {
  static const _eventChannel = EventChannel('com.example/battery_events');

  Stream<int> get batteryLevelStream {
    return _eventChannel.receiveBroadcastStream().map((level) => level as int);
  }
}

// Verwendung
class BatteryWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: BatteryMonitor().batteryLevelStream,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('Battery: ${snapshot.data}%');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
```

### Android EventChannel (Kotlin)

```kotlin
class MainActivity: FlutterActivity() {
    private val EVENT_CHANNEL = "com.example/battery_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                private var receiver: BroadcastReceiver? = null

                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    receiver = object : BroadcastReceiver() {
                        override fun onReceive(context: Context?, intent: Intent?) {
                            val level = intent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
                            events?.success(level)
                        }
                    }
                    registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
                }

                override fun onCancel(arguments: Any?) {
                    unregisterReceiver(receiver)
                    receiver = null
                }
            })
    }
}
```

---

## 6. Plattform-spezifischer Code

### Platform Check

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformService {
  static String get platformName {
    if (kIsWeb) return 'Web';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isMacOS) return 'macOS';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isLinux) return 'Linux';
    return 'Unknown';
  }

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  static bool get isDesktop => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);
}
```

### Conditional Imports

```dart
// lib/storage/storage.dart
export 'storage_stub.dart'
    if (dart.library.io) 'storage_io.dart'
    if (dart.library.html) 'storage_web.dart';

// lib/storage/storage_stub.dart
class Storage {
  Future<void> save(String key, String value) {
    throw UnimplementedError();
  }
}

// lib/storage/storage_io.dart
import 'package:shared_preferences/shared_preferences.dart';

class Storage {
  Future<void> save(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

// lib/storage/storage_web.dart
import 'dart:html' as html;

class Storage {
  Future<void> save(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}
```

### Plattform-spezifische Widgets

```dart
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const AdaptiveButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        child: Text(text),
      );
    }
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class AdaptiveDialog {
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    if (Platform.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
```

---

## 7. Flutter Plugin erstellen

### Plugin-Struktur

```
my_plugin/
├── lib/
│   └── my_plugin.dart
├── android/
│   └── src/main/kotlin/.../MyPlugin.kt
├── ios/
│   └── Classes/
│       └── MyPlugin.swift
├── example/
├── pubspec.yaml
└── README.md
```

### Plugin pubspec.yaml

```yaml
name: my_plugin
description: A Flutter plugin for native features.
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

flutter:
  plugin:
    platforms:
      android:
        package: com.example.my_plugin
        pluginClass: MyPlugin
      ios:
        pluginClass: MyPlugin
```

---

## Zusammenfassung

| Konzept | Beschreibung |
|---------|--------------|
| Package | Wiederverwendbarer Dart/Flutter Code |
| Plugin | Package mit nativem Plattform-Code |
| pub.dev | Zentrales Package-Repository |
| MethodChannel | Synchrone Kommunikation mit Native |
| EventChannel | Stream-basierte Kommunikation |
| Platform Check | Plattform-spezifische Logik |

**Best Practices:**
- Packages gut dokumentieren (README, Dartdoc)
- CHANGELOG.md pflegen
- Semantic Versioning verwenden
- Platform Channels nur wenn nötig
- Beispiel-App im `/example` Ordner
