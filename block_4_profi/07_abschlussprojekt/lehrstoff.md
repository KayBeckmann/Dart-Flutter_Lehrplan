# Abschlussprojekt: Notiz-App mit Cloud-Sync

## Projektübersicht

In diesem Abschlussprojekt entwickelst du eine vollständige Notiz-App, die alle gelernten Konzepte aus dem gesamten Kurs vereint. Das Projekt erstreckt sich über 6 Einheiten (12 Stunden).

---

## App-Beschreibung

**NoteFlow** - Eine moderne Notiz-App mit folgenden Features:

- Notizen erstellen, bearbeiten, löschen
- Kategorien/Tags für Organisation
- Suche und Filter
- Lokale Speicherung (offline-first)
- Cloud-Synchronisation (optional)
- Dark/Light Mode
- Animierte UI-Übergänge

---

## Projektphasen

### Phase 1: Projektplanung & Setup (Einheit 4.7)

**Ziele:**
- Projektstruktur anlegen
- Dependencies definieren
- Architektur planen
- Datenmodelle entwerfen

**Aufgaben:**
1. Flutter-Projekt erstellen
2. Ordnerstruktur nach Clean Architecture
3. pubspec.yaml mit allen Dependencies
4. Grundlegende Datenmodelle
5. App-Theme definieren

### Phase 2: UI & Navigation (Einheit 4.8)

**Ziele:**
- Alle Screens implementieren
- Navigation einrichten
- Responsive Layouts
- Wiederverwendbare Widgets

**Screens:**
- Home (Notizliste)
- Note Detail/Editor
- Settings
- Search
- Category Management

### Phase 3: State Management & Datenmodelle (Einheit 4.9)

**Ziele:**
- Provider/Riverpod Setup
- State-Klassen implementieren
- Business-Logik
- Repository-Pattern

**Komponenten:**
- NotesNotifier/Provider
- CategoriesNotifier
- SettingsNotifier
- SearchState

### Phase 4: API-Anbindung & lokale Speicherung (Einheit 4.10)

**Ziele:**
- Lokale Datenbank (Hive/SQLite)
- REST API Service (optional)
- Offline-First Strategie
- Sync-Logik

**Implementierung:**
- LocalStorageService
- ApiService (Mock oder real)
- SyncService
- Error Handling

### Phase 5: Formulare & Validierung (Einheit 4.11)

**Ziele:**
- Note Editor mit Validierung
- Settings-Formular
- Kategorie-Dialog
- Input-Handling

**Features:**
- Titel-Validierung (nicht leer)
- Auto-Save (Debouncing)
- Unsaved Changes Detection
- Confirmation Dialogs

### Phase 6: Animationen, Tests & Feinschliff (Einheit 4.12)

**Ziele:**
- UI-Animationen
- Unit & Widget Tests
- Performance-Optimierung
- Release-Vorbereitung

**Aufgaben:**
- Hero-Animationen für Notizen
- List-Animationen
- Staggered Einblendungen
- Mindestens 80% Test-Coverage

---

## Architektur

### Ordnerstruktur

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── routes.dart
│   ├── theme.dart
│   └── constants.dart
├── models/
│   ├── note.dart
│   ├── category.dart
│   └── user_settings.dart
├── providers/
│   ├── notes_provider.dart
│   ├── categories_provider.dart
│   └── settings_provider.dart
├── services/
│   ├── storage_service.dart
│   ├── api_service.dart
│   └── sync_service.dart
├── repositories/
│   ├── notes_repository.dart
│   └── categories_repository.dart
├── screens/
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   ├── editor/
│   │   ├── editor_screen.dart
│   │   └── widgets/
│   ├── settings/
│   │   └── settings_screen.dart
│   └── search/
│       └── search_screen.dart
├── widgets/
│   ├── note_card.dart
│   ├── category_chip.dart
│   ├── empty_state.dart
│   └── loading_indicator.dart
└── utils/
    ├── date_formatter.dart
    └── validators.dart
```

### Datenfluss

```
UI (Screens/Widgets)
        ↓ ↑
    Providers
        ↓ ↑
   Repositories
        ↓ ↑
    Services
   ↙       ↘
Local DB    API
```

---

## Datenmodelle

### Note

```dart
@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? categoryId,
    @Default(false) bool isPinned,
    @Default(false) bool isArchived,
    @Default([]) List<String> tags,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}
```

### Category

```dart
@freezed
class Category with _$Category {
  const factory Category({
    required String id,
    required String name,
    required int color,
    @Default(0) int noteCount,
  }) = _Category;

  factory Category.fromJson(Map<String, dynamic> json) =>
      _$CategoryFromJson(json);
}
```

### UserSettings

```dart
@freezed
class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(SortOrder.updatedDesc) SortOrder defaultSortOrder,
    @Default(true) bool showPinnedFirst,
    @Default(true) bool confirmDelete,
    @Default(false) bool syncEnabled,
  }) = _UserSettings;
}
```

---

## Bewertungskriterien

### Funktionalität (40%)
- [ ] CRUD für Notizen funktioniert
- [ ] Kategorien können verwaltet werden
- [ ] Suche/Filter funktioniert
- [ ] Offline-Speicherung funktioniert
- [ ] Settings werden persistiert

### Code-Qualität (25%)
- [ ] Clean Architecture eingehalten
- [ ] Separation of Concerns
- [ ] Keine Code-Duplikation
- [ ] Sinnvolle Benennung
- [ ] Kommentare wo nötig

### UI/UX (20%)
- [ ] Konsistentes Design
- [ ] Responsive Layouts
- [ ] Sinnvolle Animationen
- [ ] Gute Error States
- [ ] Loading States

### Testing (15%)
- [ ] Unit Tests für Models
- [ ] Unit Tests für Repositories
- [ ] Widget Tests für wichtige Screens
- [ ] Mindestens 70% Coverage

---

## Zeitplan

| Einheit | Fokus | Dauer |
|---------|-------|-------|
| 4.7 | Projektplanung & Setup | 2h |
| 4.8 | UI & Navigation | 2h |
| 4.9 | State Management | 2h |
| 4.10 | Daten & API | 2h |
| 4.11 | Formulare | 2h |
| 4.12 | Animationen & Tests | 2h |

---

## Tipps

1. **Iterativ arbeiten** - Erst Grundfunktion, dann erweitern
2. **Commit oft** - Nach jeder funktionierenden Feature
3. **Tests parallel** - Nicht alles am Ende
4. **Keep it simple** - Lieber weniger Features, dafür robust
5. **Dokumentieren** - Für dich selbst in der Zukunft
