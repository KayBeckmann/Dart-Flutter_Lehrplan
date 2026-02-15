# Übung 3.7: SharedPreferences

## Ziel

Eine Settings-Seite mit persistenten Einstellungen implementieren.

---

## Aufgabe 1: Setup & Basics (15 min)

1. Füge `shared_preferences` zu deinem Projekt hinzu
2. Erstelle eine einfache App, die einen Counter persistent speichert
3. Der Counter soll beim App-Neustart den letzten Wert anzeigen

```dart
// Speichern
await prefs.setInt('counter', value);

// Laden
final value = prefs.getInt('counter') ?? 0;
```

---

## Aufgabe 2: SettingsService erstellen (25 min)

Erstelle einen `SettingsService` mit folgenden Einstellungen:

```dart
class SettingsService {
  // Keys als Konstanten
  static const _darkModeKey = 'darkMode';
  static const _languageKey = 'language';
  static const _notificationsKey = 'notifications';
  static const _fontSizeKey = 'fontSize';
  static const _usernameKey = 'username';

  // Implementiere:
  // - Getter für jeden Wert (mit sinnvollen Defaults)
  // - Setter für jeden Wert (async)
  // - resetToDefaults() Methode
}
```

**Defaults:**
- darkMode: `false`
- language: `'de'`
- notifications: `true`
- fontSize: `16.0`
- username: `'Guest'`

---

## Aufgabe 3: Settings UI bauen (30 min)

Erstelle eine Settings-Seite mit:

```
┌─────────────────────────────────┐
│ Einstellungen                   │
├─────────────────────────────────┤
│                                 │
│ Profil                          │
│ ┌─────────────────────────────┐ │
│ │ Benutzername                │ │
│ │ [Max Mustermann        ]    │ │
│ └─────────────────────────────┘ │
│                                 │
│ Darstellung                     │
│ ┌─────────────────────────────┐ │
│ │ Dark Mode          [Toggle] │ │
│ │ Schriftgröße       [Slider] │ │
│ │ 12 ──────●────────── 24     │ │
│ └─────────────────────────────┘ │
│                                 │
│ Sprache                         │
│ ┌─────────────────────────────┐ │
│ │ ○ Deutsch                   │ │
│ │ ○ English                   │ │
│ │ ○ Français                  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Benachrichtigungen              │
│ ┌─────────────────────────────┐ │
│ │ Push-Nachrichten   [Toggle] │ │
│ └─────────────────────────────┘ │
│                                 │
│ [    Auf Standard zurücksetzen  ]│
│                                 │
└─────────────────────────────────┘
```

Anforderungen:
- Einstellungen werden sofort gespeichert
- Beim Öffnen werden gespeicherte Werte geladen
- Dark Mode ändert sofort das App-Theme

---

## Aufgabe 4: Mit ChangeNotifier (20 min)

Refaktoriere den `SettingsService` zu einem `SettingsNotifier`:

```dart
class SettingsNotifier extends ChangeNotifier {
  final SharedPreferences _prefs;

  SettingsNotifier(this._prefs);

  // Bei jedem Setter: notifyListeners() aufrufen
  Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('darkMode', value);
    notifyListeners();  // UI aktualisiert sich automatisch
  }
}
```

Integriere mit Provider:
- App-Theme reagiert auf Dark Mode Änderungen
- Settings-Seite zeigt immer aktuelle Werte

---

## Aufgabe 5: Search History (20 min)

Implementiere eine Suchhistorie:

```dart
class SearchHistoryService {
  static const _maxItems = 5;

  // Implementiere:
  List<String> get history;
  Future<void> addSearch(String query);
  Future<void> removeSearch(String query);
  Future<void> clearHistory();
}
```

Erstelle eine Such-UI:
- TextField für Suche
- Liste der letzten Suchen
- Tippen auf Item → In TextField übernehmen
- Swipe zum Löschen
- "Verlauf löschen" Button

---

## Aufgabe 6: Onboarding Flow (20 min)

Implementiere einen "First Launch" Flow:

1. Beim ersten Start: Zeige Onboarding-Screens
2. Nach Onboarding: Speichere `hasSeenOnboarding = true`
3. Bei weiteren Starts: Direkt zur Home-Seite

```dart
class OnboardingService {
  bool get hasSeenOnboarding;
  Future<void> completeOnboarding();
  Future<void> resetOnboarding();  // Für Testing
}
```

Onboarding-Screens (3 Seiten mit PageView):
1. "Willkommen bei der App"
2. "Entdecke Features"
3. "Los geht's!" mit Button zum Abschließen

---

## Aufgabe 7: Verständnisfragen

1. Warum muss `SharedPreferences.getInstance()` awaited werden?

2. Was passiert, wenn man `getString('nonexistent')` aufruft?

3. Warum sollte man sensible Daten (Passwörter, Tokens) NICHT in SharedPreferences speichern?

4. Wann würdest du SharedPreferences verwenden, wann eine Datenbank?

5. Warum `WidgetsFlutterBinding.ensureInitialized()` vor `SharedPreferences.getInstance()`?

---

## Bonus: Themes mit Persistenz

Erweitere die App um ein Theme-System:

```dart
enum AppTheme {
  light,
  dark,
  blue,
  green,
  purple;

  ThemeData get themeData {
    switch (this) {
      case AppTheme.light:
        return ThemeData.light();
      case AppTheme.dark:
        return ThemeData.dark();
      case AppTheme.blue:
        return ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue));
      // ...
    }
  }
}
```

- Theme-Auswahl in Settings
- Theme wird persistent gespeichert
- App startet mit gespeichertem Theme

---

## Abgabe-Checkliste

- [ ] SharedPreferences Package installiert
- [ ] Counter-App mit Persistenz
- [ ] SettingsService mit allen Methoden
- [ ] Settings-UI vollständig
- [ ] ChangeNotifier-Integration
- [ ] SearchHistory funktioniert
- [ ] Onboarding-Flow implementiert
- [ ] Verständnisfragen beantwortet
