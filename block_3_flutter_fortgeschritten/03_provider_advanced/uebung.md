# Übung 3.3: Provider Advanced

## Ziel

Eine App mit mehreren Providern und Abhängigkeiten zwischen ihnen erstellen.

---

## Aufgabe 1: MultiProvider Setup (15 min)

Erstelle eine App mit folgenden Providern:

1. **ThemeNotifier** - Verwaltet Dark/Light Mode
2. **AuthNotifier** - Verwaltet User-Login-Status
3. **SettingsNotifier** - Verwaltet App-Einstellungen

```dart
// ThemeNotifier
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  void setTheme(ThemeMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void toggleDarkMode() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

// AuthNotifier
class AuthNotifier extends ChangeNotifier {
  String? _userId;
  String? _token;

  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;
  String? get token => _token;

  void login(String userId, String token) {
    _userId = userId;
    _token = token;
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _token = null;
    notifyListeners();
  }
}

// SettingsNotifier
class SettingsNotifier extends ChangeNotifier {
  bool _notificationsEnabled = true;
  String _language = 'de';

  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;

  void setNotifications(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    notifyListeners();
  }
}
```

Registriere alle drei mit `MultiProvider` in `main()`.

---

## Aufgabe 2: ProxyProvider für API-Service (20 min)

Erstelle einen `ApiService`, der vom `AuthNotifier` abhängt:

```dart
class ApiService {
  final String? authToken;

  ApiService({this.authToken});

  // Simulierte API-Calls
  Future<Map<String, dynamic>> fetchUserData() async {
    if (authToken == null) {
      throw Exception('Not authenticated');
    }

    // Simuliere Netzwerk-Delay
    await Future.delayed(Duration(seconds: 1));

    return {
      'name': 'Max Mustermann',
      'email': 'max@example.com',
      'premium': true,
    };
  }

  Future<List<String>> fetchItems() async {
    await Future.delayed(Duration(milliseconds: 500));
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}
```

Füge den `ApiService` als `ProxyProvider` hinzu, der bei Änderungen am Auth-Token aktualisiert wird.

---

## Aufgabe 3: Selector für Performance (20 min)

Erstelle ein `UserStatsNotifier` mit vielen Properties:

```dart
class UserStatsNotifier extends ChangeNotifier {
  int _totalItems = 0;
  int _completedItems = 0;
  int _points = 0;
  String _level = 'Beginner';
  DateTime _lastActive = DateTime.now();

  int get totalItems => _totalItems;
  int get completedItems => _completedItems;
  int get points => _points;
  String get level => _level;
  DateTime get lastActive => _lastActive;

  // Computed
  double get completionRate =>
      _totalItems == 0 ? 0 : _completedItems / _totalItems;

  void addItem() {
    _totalItems++;
    notifyListeners();
  }

  void completeItem() {
    _completedItems++;
    _points += 10;
    _checkLevelUp();
    notifyListeners();
  }

  void _checkLevelUp() {
    if (_points >= 100) _level = 'Pro';
    if (_points >= 500) _level = 'Expert';
    if (_points >= 1000) _level = 'Master';
  }

  void updateLastActive() {
    _lastActive = DateTime.now();
    notifyListeners();
  }
}
```

Erstelle drei separate Widgets, die jeweils `Selector` verwenden:

1. **PointsDisplay** - Zeigt nur `points` und `level`
2. **ProgressDisplay** - Zeigt nur `completedItems` und `totalItems`
3. **LastActiveDisplay** - Zeigt nur `lastActive`

Füge Debug-Prints in jeden `builder` ein, um zu sehen, wann sie rebuilden:

```dart
Selector<UserStatsNotifier, int>(
  selector: (_, stats) => stats.points,
  builder: (_, points, __) {
    print('PointsDisplay rebuild');
    return Text('Points: $points');
  },
);
```

---

## Aufgabe 4: Kombination - Settings-Seite (30 min)

Baue eine Settings-Seite, die alle Provider verwendet:

```
┌─────────────────────────────────┐
│ Einstellungen                   │
├─────────────────────────────────┤
│                                 │
│ Konto                           │
│ ┌─────────────────────────────┐ │
│ │ Max Mustermann              │ │
│ │ max@example.com             │ │
│ │ [Abmelden]                  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Darstellung                     │
│ ┌─────────────────────────────┐ │
│ │ Dark Mode          [Toggle] │ │
│ └─────────────────────────────┘ │
│                                 │
│ Benachrichtigungen              │
│ ┌─────────────────────────────┐ │
│ │ Push-Benachrichtigungen [✓] │ │
│ └─────────────────────────────┘ │
│                                 │
│ Sprache                         │
│ ┌─────────────────────────────┐ │
│ │ Deutsch              [▼]   │ │
│ └─────────────────────────────┘ │
│                                 │
│ Statistiken                     │
│ ┌─────────────────────────────┐ │
│ │ Level: Pro                  │ │
│ │ Punkte: 150                 │ │
│ │ Fortschritt: 8/10 (80%)    │ │
│ └─────────────────────────────┘ │
│                                 │
└─────────────────────────────────┘
```

Anforderungen:
- Nutze `Consumer` oder `Selector` je nach Bedarf
- "Abmelden" Button ruft `authNotifier.logout()` auf
- Theme Toggle ändert zwischen Dark/Light Mode
- Statistiken verwenden `Selector` für optimale Performance

---

## Aufgabe 5: FutureProvider für Konfiguration (15 min)

Simuliere das Laden einer App-Konfiguration:

```dart
class AppConfig {
  final String apiBaseUrl;
  final int maxUploadSize;
  final bool maintenanceMode;

  AppConfig({
    required this.apiBaseUrl,
    required this.maxUploadSize,
    required this.maintenanceMode,
  });

  static Future<AppConfig> load() async {
    // Simuliere Laden vom Server
    await Future.delayed(Duration(seconds: 2));

    return AppConfig(
      apiBaseUrl: 'https://api.example.com',
      maxUploadSize: 10 * 1024 * 1024, // 10 MB
      maintenanceMode: false,
    );
  }

  static AppConfig get defaultConfig => AppConfig(
    apiBaseUrl: 'https://api.example.com',
    maxUploadSize: 5 * 1024 * 1024,
    maintenanceMode: false,
  );
}
```

1. Füge einen `FutureProvider<AppConfig>` hinzu
2. Zeige einen Loading-Spinner während des Ladens
3. Zeige die Config-Werte nach dem Laden

---

## Bonus: Riverpod Vergleich

Implementiere einen einfachen Counter mit Riverpod und vergleiche die Syntax:

```dart
// pubspec.yaml
// flutter_riverpod: ^2.4.9

import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Provider definieren
final counterProvider = StateProvider<int>((ref) => 0);

// 2. App mit ProviderScope wrappen
void main() {
  runApp(ProviderScope(child: MyApp()));
}

// 3. ConsumerWidget statt StatelessWidget
class CounterPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);

    return Scaffold(
      body: Center(child: Text('Count: $count')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(counterProvider.notifier).state++,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

Notiere Unterschiede zu Provider.

---

## Abgabe-Checkliste

- [ ] MultiProvider mit 3+ Providern konfiguriert
- [ ] ProxyProvider für ApiService implementiert
- [ ] Selector in mindestens 3 Widgets verwendet
- [ ] Debug-Prints zeigen korrektes Rebuild-Verhalten
- [ ] Settings-Seite funktioniert vollständig
- [ ] FutureProvider mit Loading-State
- [ ] (Bonus) Riverpod-Vergleich dokumentiert
