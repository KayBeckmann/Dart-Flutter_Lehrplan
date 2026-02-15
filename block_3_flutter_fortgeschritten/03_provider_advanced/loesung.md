# Lösung 3.3: Provider Advanced

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   └── app_config.dart
├── providers/
│   ├── auth_notifier.dart
│   ├── theme_notifier.dart
│   ├── settings_notifier.dart
│   ├── user_stats_notifier.dart
│   └── providers.dart
├── services/
│   └── api_service.dart
└── pages/
    └── settings_page.dart
```

---

## models/app_config.dart

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
    await Future.delayed(const Duration(seconds: 2));
    return AppConfig(
      apiBaseUrl: 'https://api.example.com',
      maxUploadSize: 10 * 1024 * 1024,
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

---

## providers/auth_notifier.dart

```dart
import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  String? _userId;
  String? _token;
  String? _userName;
  String? _userEmail;

  bool get isLoggedIn => _userId != null;
  String? get userId => _userId;
  String? get token => _token;
  String? get userName => _userName;
  String? get userEmail => _userEmail;

  void login(String userId, String token,
      {String? name, String? email}) {
    _userId = userId;
    _token = token;
    _userName = name ?? 'Max Mustermann';
    _userEmail = email ?? 'max@example.com';
    notifyListeners();
  }

  void logout() {
    _userId = null;
    _token = null;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }
}
```

---

## providers/theme_notifier.dart

```dart
import 'package:flutter/material.dart';

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;
  bool get isDarkMode => _mode == ThemeMode.dark;

  void setTheme(ThemeMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  void toggleDarkMode() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
```

---

## providers/settings_notifier.dart

```dart
import 'package:flutter/foundation.dart';

class SettingsNotifier extends ChangeNotifier {
  bool _notificationsEnabled = true;
  String _language = 'de';

  bool get notificationsEnabled => _notificationsEnabled;
  String get language => _language;

  void setNotifications(bool enabled) {
    if (_notificationsEnabled != enabled) {
      _notificationsEnabled = enabled;
      notifyListeners();
    }
  }

  void setLanguage(String lang) {
    if (_language != lang) {
      _language = lang;
      notifyListeners();
    }
  }
}
```

---

## providers/user_stats_notifier.dart

```dart
import 'package:flutter/foundation.dart';

class UserStatsNotifier extends ChangeNotifier {
  int _totalItems = 10;
  int _completedItems = 8;
  int _points = 150;
  String _level = 'Pro';
  DateTime _lastActive = DateTime.now();

  int get totalItems => _totalItems;
  int get completedItems => _completedItems;
  int get points => _points;
  String get level => _level;
  DateTime get lastActive => _lastActive;

  double get completionRate =>
      _totalItems == 0 ? 0 : _completedItems / _totalItems;

  void addItem() {
    _totalItems++;
    notifyListeners();
  }

  void completeItem() {
    if (_completedItems < _totalItems) {
      _completedItems++;
      _points += 10;
      _checkLevelUp();
      notifyListeners();
    }
  }

  void _checkLevelUp() {
    if (_points >= 1000) {
      _level = 'Master';
    } else if (_points >= 500) {
      _level = 'Expert';
    } else if (_points >= 100) {
      _level = 'Pro';
    } else {
      _level = 'Beginner';
    }
  }

  void updateLastActive() {
    _lastActive = DateTime.now();
    notifyListeners();
  }
}
```

---

## services/api_service.dart

```dart
class ApiService {
  final String? authToken;

  ApiService({this.authToken});

  bool get isAuthenticated => authToken != null;

  Future<Map<String, dynamic>> fetchUserData() async {
    if (authToken == null) {
      throw Exception('Not authenticated');
    }

    await Future.delayed(const Duration(seconds: 1));

    return {
      'name': 'Max Mustermann',
      'email': 'max@example.com',
      'premium': true,
    };
  }

  Future<List<String>> fetchItems() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ['Item 1', 'Item 2', 'Item 3'];
  }
}
```

---

## providers/providers.dart

```dart
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../models/app_config.dart';
import '../services/api_service.dart';
import 'auth_notifier.dart';
import 'theme_notifier.dart';
import 'settings_notifier.dart';
import 'user_stats_notifier.dart';

class Providers {
  static List<SingleChildWidget> get all => [
        // 1. Theme Notifier
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),

        // 2. Auth Notifier
        ChangeNotifierProvider(create: (_) {
          final auth = AuthNotifier();
          // Simuliere eingeloggten User
          auth.login('user123', 'token_abc',
              name: 'Max Mustermann', email: 'max@example.com');
          return auth;
        }),

        // 3. Settings Notifier
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),

        // 4. User Stats Notifier
        ChangeNotifierProvider(create: (_) => UserStatsNotifier()),

        // 5. API Service (abhängig von Auth)
        ProxyProvider<AuthNotifier, ApiService>(
          update: (_, auth, __) => ApiService(authToken: auth.token),
        ),

        // 6. App Config (async laden)
        FutureProvider<AppConfig>(
          create: (_) => AppConfig.load(),
          initialData: AppConfig.defaultConfig,
        ),
      ];
}
```

---

## main.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/providers.dart';
import 'providers/theme_notifier.dart';
import 'pages/settings_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: Providers.all,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          title: 'Provider Advanced',
          themeMode: themeNotifier.mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const SettingsPage(),
        );
      },
    );
  }
}
```

---

## pages/settings_page.dart

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_config.dart';
import '../providers/auth_notifier.dart';
import '../providers/theme_notifier.dart';
import '../providers/settings_notifier.dart';
import '../providers/user_stats_notifier.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AccountSection(),
          SizedBox(height: 24),
          _AppearanceSection(),
          SizedBox(height: 24),
          _NotificationSection(),
          SizedBox(height: 24),
          _LanguageSection(),
          SizedBox(height: 24),
          _StatsSection(),
          SizedBox(height: 24),
          _ConfigSection(),
        ],
      ),
    );
  }
}

// Account Section
class _AccountSection extends StatelessWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        print('AccountSection rebuild');

        if (!auth.isLoggedIn) {
          return Card(
            child: ListTile(
              title: const Text('Nicht angemeldet'),
              trailing: ElevatedButton(
                onPressed: () {
                  auth.login('user123', 'token_abc');
                },
                child: const Text('Anmelden'),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konto',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(auth.userName ?? 'Unbekannt'),
                  subtitle: Text(auth.userEmail ?? ''),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => auth.logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Abmelden'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Appearance Section mit Selector
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    // Selector: Nur bei Mode-Änderung rebuilden
    final isDarkMode = context.select<ThemeNotifier, bool>(
      (notifier) => notifier.isDarkMode,
    );

    print('AppearanceSection rebuild');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Darstellung',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: isDarkMode,
              onChanged: (_) {
                context.read<ThemeNotifier>().toggleDarkMode();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Notification Section
class _NotificationSection extends StatelessWidget {
  const _NotificationSection();

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SettingsNotifier, bool>(
      (s) => s.notificationsEnabled,
    );

    print('NotificationSection rebuild');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Benachrichtigungen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SwitchListTile(
              title: const Text('Push-Benachrichtigungen'),
              value: enabled,
              onChanged: (value) {
                context.read<SettingsNotifier>().setNotifications(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Language Section
class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final language = context.select<SettingsNotifier, String>(
      (s) => s.language,
    );

    print('LanguageSection rebuild');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprache',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: language,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<SettingsNotifier>().setLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Stats Section mit mehreren Selectors
class _StatsSection extends StatelessWidget {
  const _StatsSection();

  @override
  Widget build(BuildContext context) {
    print('StatsSection container rebuild');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiken',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _PointsDisplay(),
            const _ProgressDisplay(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    context.read<UserStatsNotifier>().addItem();
                  },
                  child: const Text('+ Item'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.read<UserStatsNotifier>().completeItem();
                  },
                  child: const Text('+ Erledigt'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PointsDisplay extends StatelessWidget {
  const _PointsDisplay();

  @override
  Widget build(BuildContext context) {
    // Nur Points und Level selektieren
    return Selector<UserStatsNotifier, (int, String)>(
      selector: (_, stats) => (stats.points, stats.level),
      builder: (_, data, __) {
        final (points, level) = data;
        print('PointsDisplay rebuild: $points points, $level');

        return ListTile(
          leading: const Icon(Icons.star),
          title: Text('Level: $level'),
          subtitle: Text('Punkte: $points'),
        );
      },
    );
  }
}

class _ProgressDisplay extends StatelessWidget {
  const _ProgressDisplay();

  @override
  Widget build(BuildContext context) {
    // Nur Progress-relevante Daten selektieren
    return Selector<UserStatsNotifier, (int, int)>(
      selector: (_, stats) => (stats.completedItems, stats.totalItems),
      builder: (_, data, __) {
        final (completed, total) = data;
        final percentage = total == 0 ? 0 : (completed / total * 100).round();
        print('ProgressDisplay rebuild: $completed/$total');

        return Column(
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: Text('Fortschritt: $completed/$total ($percentage%)'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : completed / total,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Config Section mit FutureProvider
class _ConfigSection extends StatelessWidget {
  const _ConfigSection();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<AppConfig>();

    print('ConfigSection rebuild');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Konfiguration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListTile(
              title: const Text('API URL'),
              subtitle: Text(config.apiBaseUrl),
            ),
            ListTile(
              title: const Text('Max Upload'),
              subtitle: Text(
                '${(config.maxUploadSize / 1024 / 1024).toStringAsFixed(0)} MB',
              ),
            ),
            ListTile(
              title: const Text('Wartungsmodus'),
              subtitle: Text(config.maintenanceMode ? 'Aktiv' : 'Inaktiv'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Debug-Output Analyse

Beim Ändern einzelner Werte werden nur die relevanten Widgets rebuilt:

```
// Bei Dark Mode Toggle:
AppearanceSection rebuild

// Bei Notification Toggle:
NotificationSection rebuild

// Bei completeItem():
PointsDisplay rebuild: 160 points, Pro
ProgressDisplay rebuild: 9/10

// Bei addItem():
ProgressDisplay rebuild: 9/11
// PointsDisplay wird NICHT rebuilt!
```

---

## Bonus: Riverpod Vergleich

```dart
// Riverpod Version - providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Einfacher State
final counterProvider = StateProvider<int>((ref) => 0);

// Notifier (wie ChangeNotifier)
final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, UserStats>((ref) {
  return UserStatsNotifier();
});

// Abhängiger Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final auth = ref.watch(authProvider);
  return ApiService(authToken: auth.token);
});

// Usage in Widget
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch = context.watch
    final count = ref.watch(counterProvider);

    return ElevatedButton(
      // read = context.read
      onPressed: () => ref.read(counterProvider.notifier).state++,
      child: Text('$count'),
    );
  }
}
```

**Hauptunterschiede:**
1. Kein `BuildContext` nötig
2. Provider sind global definiert
3. `ref.watch` statt `context.watch`
4. Automatisches Dispose
5. Bessere Compile-Time Checks
