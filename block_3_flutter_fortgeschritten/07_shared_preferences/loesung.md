# Lösung 3.7: SharedPreferences

## Aufgabe 2: SettingsService

```dart
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _darkModeKey = 'darkMode';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications';
  static const _fontSizeKey = 'fontSize';
  static const _usernameKey = 'username';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // Dark Mode
  bool get darkMode => _prefs.getBool(_darkModeKey) ?? false;
  Future<void> setDarkMode(bool value) => _prefs.setBool(_darkModeKey, value);

  // Language
  String get language => _prefs.getString(_languageKey) ?? 'de';
  Future<void> setLanguage(String value) =>
      _prefs.setString(_languageKey, value);

  // Notifications
  bool get notifications => _prefs.getBool(_notificationsKey) ?? true;
  Future<void> setNotifications(bool value) =>
      _prefs.setBool(_notificationsKey, value);

  // Font Size
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16.0;
  Future<void> setFontSize(double value) =>
      _prefs.setDouble(_fontSizeKey, value);

  // Username
  String get username => _prefs.getString(_usernameKey) ?? 'Guest';
  Future<void> setUsername(String value) =>
      _prefs.setString(_usernameKey, value);

  // Reset
  Future<void> resetToDefaults() async {
    await _prefs.remove(_darkModeKey);
    await _prefs.remove(_languageKey);
    await _prefs.remove(_notificationsKey);
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove(_usernameKey);
  }
}
```

---

## Aufgabe 4: SettingsNotifier

```dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends ChangeNotifier {
  static const _darkModeKey = 'darkMode';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications';
  static const _fontSizeKey = 'fontSize';
  static const _usernameKey = 'username';

  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs);

  static Future<SettingsNotifier> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsNotifier(prefs);
  }

  // Dark Mode
  bool get darkMode => _prefs.getBool(_darkModeKey) ?? false;

  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool(_darkModeKey, value);
    notifyListeners();
  }

  // Language
  String get language => _prefs.getString(_languageKey) ?? 'de';

  Future<void> setLanguage(String value) async {
    await _prefs.setString(_languageKey, value);
    notifyListeners();
  }

  // Notifications
  bool get notifications => _prefs.getBool(_notificationsKey) ?? true;

  Future<void> setNotifications(bool value) async {
    await _prefs.setBool(_notificationsKey, value);
    notifyListeners();
  }

  // Font Size
  double get fontSize => _prefs.getDouble(_fontSizeKey) ?? 16.0;

  Future<void> setFontSize(double value) async {
    await _prefs.setDouble(_fontSizeKey, value);
    notifyListeners();
  }

  // Username
  String get username => _prefs.getString(_usernameKey) ?? 'Guest';

  Future<void> setUsername(String value) async {
    await _prefs.setString(_usernameKey, value);
    notifyListeners();
  }

  // Reset
  Future<void> resetToDefaults() async {
    await _prefs.remove(_darkModeKey);
    await _prefs.remove(_languageKey);
    await _prefs.remove(_notificationsKey);
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove(_usernameKey);
    notifyListeners();
  }
}
```

---

## Settings Page UI

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: Consumer<SettingsNotifier>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profil
              _SectionHeader(title: 'Profil'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Benutzername'),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: settings.username,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        onFieldSubmitted: (value) {
                          settings.setUsername(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Darstellung
              _SectionHeader(title: 'Darstellung'),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      value: settings.darkMode,
                      onChanged: (value) => settings.setDarkMode(value),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: const Text('Schriftgröße'),
                      subtitle: Slider(
                        value: settings.fontSize,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: settings.fontSize.round().toString(),
                        onChanged: (value) => settings.setFontSize(value),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Sprache
              _SectionHeader(title: 'Sprache'),
              Card(
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('Deutsch'),
                      value: 'de',
                      groupValue: settings.language,
                      onChanged: (value) => settings.setLanguage(value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('English'),
                      value: 'en',
                      groupValue: settings.language,
                      onChanged: (value) => settings.setLanguage(value!),
                    ),
                    RadioListTile<String>(
                      title: const Text('Français'),
                      value: 'fr',
                      groupValue: settings.language,
                      onChanged: (value) => settings.setLanguage(value!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Benachrichtigungen
              _SectionHeader(title: 'Benachrichtigungen'),
              Card(
                child: SwitchListTile(
                  title: const Text('Push-Nachrichten'),
                  value: settings.notifications,
                  onChanged: (value) => settings.setNotifications(value),
                ),
              ),
              const SizedBox(height: 24),

              // Reset Button
              OutlinedButton(
                onPressed: () => _showResetDialog(context, settings),
                child: const Text('Auf Standard zurücksetzen'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showResetDialog(BuildContext context, SettingsNotifier settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zurücksetzen?'),
        content: const Text(
          'Alle Einstellungen werden auf die Standardwerte zurückgesetzt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              settings.resetToDefaults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Einstellungen zurückgesetzt')),
              );
            },
            child: const Text('Zurücksetzen'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
```

---

## Aufgabe 5: SearchHistory

```dart
class SearchHistoryService {
  static const _key = 'searchHistory';
  static const _maxItems = 5;

  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  List<String> get history => _prefs.getStringList(_key) ?? [];

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final current = history.toList();
    current.remove(query);
    current.insert(0, query.trim());

    if (current.length > _maxItems) {
      current.removeLast();
    }

    await _prefs.setStringList(_key, current);
  }

  Future<void> removeSearch(String query) async {
    final current = history.toList();
    current.remove(query);
    await _prefs.setStringList(_key, current);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_key);
  }
}

// UI
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late SearchHistoryService _historyService;
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initHistory();
  }

  Future<void> _initHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _historyService = SearchHistoryService(prefs);
    });
  }

  void _search() {
    final query = _controller.text;
    if (query.isNotEmpty) {
      _historyService.addSearch(query);
      setState(() {});
      // Perform actual search...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suche')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Letzte Suchen'),
                TextButton(
                  onPressed: () {
                    _historyService.clearHistory();
                    setState(() {});
                  },
                  child: const Text('Löschen'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _historyService.history.length,
              itemBuilder: (context, index) {
                final query = _historyService.history[index];
                return Dismissible(
                  key: ValueKey(query),
                  onDismissed: (_) {
                    _historyService.removeSearch(query);
                    setState(() {});
                  },
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(query),
                    onTap: () {
                      _controller.text = query;
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 6: Onboarding

```dart
class OnboardingService {
  static const _key = 'hasSeenOnboarding';

  final SharedPreferences _prefs;

  OnboardingService(this._prefs);

  bool get hasSeenOnboarding => _prefs.getBool(_key) ?? false;

  Future<void> completeOnboarding() async {
    await _prefs.setBool(_key, true);
  }

  Future<void> resetOnboarding() async {
    await _prefs.remove(_key);
  }
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = [
    const _OnboardingContent(
      icon: Icons.flutter_dash,
      title: 'Willkommen!',
      description: 'Entdecke die Möglichkeiten unserer App.',
    ),
    const _OnboardingContent(
      icon: Icons.star,
      title: 'Tolle Features',
      description: 'Nutze alle Funktionen für deinen Erfolg.',
    ),
    const _OnboardingContent(
      icon: Icons.rocket_launch,
      title: 'Los geht\'s!',
      description: 'Starte jetzt durch.',
    ),
  ];

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    final onboarding = OnboardingService(prefs);
    await onboarding.completeOnboarding();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (_, index) => _pages[index],
              ),
            ),
            // Dots Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.all(4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _currentPage == _pages.length - 1
                      ? _complete
                      : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? 'Starten' : 'Weiter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _OnboardingContent({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 120, color: Theme.of(context).primaryColor),
          const SizedBox(height: 48),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(description, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

---

## Verständnisfragen - Antworten

1. **Warum await bei getInstance()?**
   - SharedPreferences muss Platform-spezifischen Code aufrufen (Android/iOS)
   - Der Zugriff auf den Dateisystem ist asynchron
   - Die Instanz muss erst initialisiert werden

2. **getString('nonexistent')?**
   - Gibt `null` zurück
   - Deshalb immer Default-Wert mit `?? 'default'` angeben

3. **Warum keine sensiblen Daten?**
   - SharedPreferences speichert im Klartext
   - Auf gerooteten Geräten lesbar
   - Kein verschlüsseltes Storage
   - Besser: `flutter_secure_storage` für Tokens/Passwörter

4. **SharedPreferences vs. Datenbank?**
   - SharedPreferences: Einfache Key-Value Paare, wenige Einträge, keine Queries
   - Datenbank: Strukturierte Daten, viele Einträge, komplexe Abfragen

5. **Warum ensureInitialized()?**
   - `SharedPreferences.getInstance()` nutzt Platform Channels
   - Diese erfordern, dass Flutter Binding initialisiert ist
   - Ohne Binding: Crash beim Zugriff auf native Plattform
