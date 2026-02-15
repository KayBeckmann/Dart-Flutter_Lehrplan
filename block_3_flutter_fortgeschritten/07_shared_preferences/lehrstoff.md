# Einheit 3.7: SharedPreferences & Key-Value Storage

## Lernziele

Nach dieser Einheit kannst du:
- Das `shared_preferences` Package verwenden
- Einfache Daten persistent speichern
- Settings und User-Präferenzen implementieren
- Wissen, wann SharedPreferences vs. Datenbank sinnvoll ist

---

## 1. Setup

### Installation

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.2.2
```

```bash
flutter pub get
```

### Import

```dart
import 'package:shared_preferences/shared_preferences.dart';
```

---

## 2. Grundlegende Operationen

### Instanz holen

```dart
// Async - muss awaited werden
final prefs = await SharedPreferences.getInstance();
```

### Daten speichern

```dart
// String
await prefs.setString('username', 'max_mustermann');

// Int
await prefs.setInt('highscore', 1000);

// Double
await prefs.setDouble('volume', 0.8);

// Bool
await prefs.setBool('darkMode', true);

// String List
await prefs.setStringList('recentSearches', ['flutter', 'dart', 'widgets']);
```

### Daten lesen

```dart
// Mit Default-Wert über ?? Operator
final username = prefs.getString('username') ?? 'Guest';
final highscore = prefs.getInt('highscore') ?? 0;
final volume = prefs.getDouble('volume') ?? 1.0;
final darkMode = prefs.getBool('darkMode') ?? false;
final searches = prefs.getStringList('recentSearches') ?? [];
```

### Daten löschen

```dart
// Einzelnen Key löschen
await prefs.remove('username');

// Alle Daten löschen
await prefs.clear();
```

### Prüfen ob Key existiert

```dart
final hasUsername = prefs.containsKey('username');
```

---

## 3. Settings Service Pattern

### Strukturierte Implementierung

```dart
class SettingsService {
  static const _darkModeKey = 'darkMode';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications';
  static const _fontSizeKey = 'fontSize';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  // Factory für async Initialisierung
  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // Dark Mode
  bool get darkMode => _prefs.getBool(_darkModeKey) ?? false;
  Future<void> setDarkMode(bool value) =>
      _prefs.setBool(_darkModeKey, value);

  // Language
  String get language => _prefs.getString(_languageKey) ?? 'de';
  Future<void> setLanguage(String value) =>
      _prefs.setString(_languageKey, value);

  // Notifications
  bool get notificationsEnabled =>
      _prefs.getBool(_notificationsKey) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _prefs.setBool(_notificationsKey, value);

  // Font Size
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16.0;
  Future<void> setFontSize(double value) =>
      _prefs.setDouble(_fontSizeKey, value);

  // Reset all settings
  Future<void> resetToDefaults() async {
    await _prefs.remove(_darkModeKey);
    await _prefs.remove(_languageKey);
    await _prefs.remove(_notificationsKey);
    await _prefs.remove(_fontSizeKey);
  }
}
```

### Integration mit Provider

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsService = await SettingsService.create();

  runApp(
    Provider.value(
      value: settingsService,
      child: const MyApp(),
    ),
  );
}

// Verwendung
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsService>();

    return SwitchListTile(
      title: const Text('Dark Mode'),
      value: settings.darkMode,
      onChanged: (value) async {
        await settings.setDarkMode(value);
        // UI Update triggern...
      },
    );
  }
}
```

---

## 4. Mit ChangeNotifier kombinieren

```dart
class SettingsNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs);

  static Future<SettingsNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsNotifier(prefs);
  }

  // Dark Mode
  bool get darkMode => _prefs.getBool('darkMode') ?? false;

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('darkMode', value);
    notifyListeners();  // UI wird automatisch aktualisiert
  }

  // Notifications
  bool get notifications => _prefs.getBool('notifications') ?? true;

  Future<void> setNotifications(bool value) async {
    await _prefs.setBool('notifications', value);
    notifyListeners();
  }

  // Language
  String get language => _prefs.getString('language') ?? 'de';

  Future<void> setLanguage(String value) async {
    await _prefs.setString('language', value);
    notifyListeners();
  }
}

// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settingsNotifier = await SettingsNotifier.create();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsNotifier,
      child: const MyApp(),
    ),
  );
}

// App mit Theme-Reaktivität
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsNotifier>(
      builder: (context, settings, _) {
        return MaterialApp(
          themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: const HomePage(),
        );
      },
    );
  }
}
```

---

## 5. Komplexe Objekte speichern

SharedPreferences unterstützt nur primitive Typen. Für komplexe Objekte: JSON verwenden.

```dart
class UserPreferences {
  final String theme;
  final int fontSize;
  final List<String> favoriteCategories;

  UserPreferences({
    required this.theme,
    required this.fontSize,
    required this.favoriteCategories,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      theme: json['theme'] as String,
      fontSize: json['fontSize'] as int,
      favoriteCategories:
          (json['favoriteCategories'] as List<dynamic>).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'theme': theme,
        'fontSize': fontSize,
        'favoriteCategories': favoriteCategories,
      };

  static UserPreferences get defaults => UserPreferences(
        theme: 'light',
        fontSize: 16,
        favoriteCategories: [],
      );
}

// Speichern und Laden
class PreferencesService {
  static const _key = 'userPreferences';
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  UserPreferences get userPreferences {
    final json = _prefs.getString(_key);
    if (json == null) return UserPreferences.defaults;

    try {
      return UserPreferences.fromJson(jsonDecode(json));
    } catch (e) {
      return UserPreferences.defaults;
    }
  }

  Future<void> saveUserPreferences(UserPreferences prefs) async {
    await _prefs.setString(_key, jsonEncode(prefs.toJson()));
  }
}
```

---

## 6. First Launch / Onboarding

```dart
class OnboardingService {
  static const _hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const _firstLaunchDateKey = 'firstLaunchDate';

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  bool get hasSeenOnboarding =>
      _prefs.getBool(_hasSeenOnboardingKey) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_hasSeenOnboardingKey, true);
  }

  DateTime? get firstLaunchDate {
    final timestamp = _prefs.getString(_firstLaunchDateKey);
    if (timestamp == null) return null;
    return DateTime.parse(timestamp);
  }

  Future<void> recordFirstLaunch() async {
    if (firstLaunchDate == null) {
      await _prefs.setString(
        _firstLaunchDateKey,
        DateTime.now().toIso8601String(),
      );
    }
  }

  bool get isFirstLaunch => firstLaunchDate == null;
}

// Verwendung
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = OnboardingService(prefs);

    await onboarding.recordFirstLaunch();

    if (!mounted) return;

    if (onboarding.hasSeenOnboarding) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
```

---

## 7. Recent Items / History

```dart
class SearchHistoryService {
  static const _key = 'searchHistory';
  static const _maxItems = 10;

  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  List<String> get history => _prefs.getStringList(_key) ?? [];

  Future<void> addSearch(String query) async {
    final current = history;

    // Duplikat entfernen
    current.remove(query);

    // Am Anfang einfügen
    current.insert(0, query);

    // Auf max Größe begrenzen
    if (current.length > _maxItems) {
      current.removeLast();
    }

    await _prefs.setStringList(_key, current);
  }

  Future<void> removeSearch(String query) async {
    final current = history;
    current.remove(query);
    await _prefs.setStringList(_key, current);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }
}
```

---

## 8. Wann SharedPreferences vs. Datenbank?

### SharedPreferences verwenden für:

| Use Case | Beispiel |
|----------|----------|
| App-Einstellungen | Dark Mode, Sprache, Notifications |
| Einfache Flags | hasSeenOnboarding, isLoggedIn |
| Kleine Listen | Recent Searches, Favorites (wenige Items) |
| Einzelne Werte | Highscore, Last Sync Date |
| Cache-Marker | lastFetchTime für API Cache |

### Datenbank verwenden für:

| Use Case | Beispiel |
|----------|----------|
| Strukturierte Daten | Todos, Kontakte, Nachrichten |
| Große Datenmengen | 100+ Items |
| Komplexe Abfragen | Filtern, Sortieren, Suchen |
| Relationen | User → Posts → Comments |
| Offline-First Apps | Sync mit Server |

### Faustregel

```
SharedPreferences: Key-Value, < 50 Items, keine Queries
Datenbank: Strukturiert, viele Items, Queries nötig
```

---

## 9. Secure Storage Alternative

Für **sensible Daten** (Tokens, Passwörter) besser `flutter_secure_storage`:

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }
}
```

---

## Zusammenfassung

| Methode | Verwendung |
|---------|-----------|
| `setString/getString` | Text, JSON |
| `setInt/getInt` | Zahlen |
| `setBool/getBool` | Flags |
| `setDouble/getDouble` | Dezimalzahlen |
| `setStringList/getStringList` | Listen |
| `remove` | Einzelnen Key löschen |
| `clear` | Alles löschen |

**Best Practices:**
1. Keys als Konstanten definieren
2. Default-Werte immer angeben
3. Service-Klasse für Kapselung
4. Mit ChangeNotifier für reaktive UI
5. Sensible Daten → `flutter_secure_storage`
