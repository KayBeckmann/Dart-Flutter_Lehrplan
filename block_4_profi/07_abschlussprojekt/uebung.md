# Aufgabenstellung: Abschlussprojekt NoteFlow

## Projektbeschreibung

Entwickle eine vollständige Notiz-App "NoteFlow" mit den unten beschriebenen Features. Das Projekt erstreckt sich über 6 Einheiten (12 Stunden Arbeitszeit).

---

## Einheit 4.7: Projektplanung & Setup (2h)

### Aufgaben

1. **Projekt erstellen**
   ```bash
   flutter create --org com.deinname noteflow
   ```

2. **Ordnerstruktur anlegen**
   - Erstelle die Verzeichnisse gemäß der Architektur
   - `lib/models/`, `lib/providers/`, `lib/services/`, etc.

3. **Dependencies hinzufügen**
   ```yaml
   # Füge hinzu:
   # - State Management (provider oder riverpod)
   # - Routing (go_router)
   # - Lokale DB (hive_flutter)
   # - Utilities (uuid, intl)
   # - Testing (mocktail)
   ```

4. **Datenmodelle erstellen**
   - `Note` Modell mit allen Properties
   - `Category` Modell
   - `UserSettings` Modell
   - JSON-Serialisierung

5. **Theme definieren**
   - Light Theme
   - Dark Theme
   - Gemeinsame Farben/Styles

### Abgabe
- [ ] Lauffähiges Projekt
- [ ] Alle Dependencies installiert
- [ ] Ordnerstruktur vorhanden
- [ ] Models implementiert
- [ ] Theme konfiguriert

---

## Einheit 4.8: UI & Navigation (2h)

### Aufgaben

1. **Navigation einrichten**
   - go_router konfigurieren
   - Routes definieren
   - Deep Links vorbereiten

2. **Home Screen**
   ```
   ┌─────────────────────────────────┐
   │ NoteFlow               🔍  ⚙️  │
   ├─────────────────────────────────┤
   │ [Alle] [Arbeit] [Privat] [+]   │
   ├─────────────────────────────────┤
   │ 📌 Wichtige Notiz              │
   │    Letzte Änderung: Heute      │
   ├─────────────────────────────────┤
   │ Meeting Notes                   │
   │    Letzte Änderung: Gestern    │
   ├─────────────────────────────────┤
   │ Einkaufsliste                  │
   │    Letzte Änderung: 12.03.     │
   └─────────────────────────────────┘
                              [+]
   ```

3. **Note Editor Screen**
   ```
   ┌─────────────────────────────────┐
   │ ←  Bearbeiten           💾  🗑️ │
   ├─────────────────────────────────┤
   │ Titel                          │
   │ ┌───────────────────────────┐  │
   │ │ Meine Notiz              │  │
   │ └───────────────────────────┘  │
   │                                │
   │ Inhalt                         │
   │ ┌───────────────────────────┐  │
   │ │ Lorem ipsum dolor sit    │  │
   │ │ amet, consectetur...     │  │
   │ │                          │  │
   │ └───────────────────────────┘  │
   │                                │
   │ Kategorie: [Arbeit ▼]          │
   │ Tags: [meeting] [wichtig] [+]  │
   └─────────────────────────────────┘
   ```

4. **Settings Screen**
   - Theme-Auswahl
   - Sortierung
   - Sync-Option (UI only)

5. **Wiederverwendbare Widgets**
   - NoteCard
   - CategoryChip
   - EmptyState
   - LoadingIndicator

### Abgabe
- [ ] Alle Screens implementiert
- [ ] Navigation funktioniert
- [ ] Responsive Layout
- [ ] Widgets extrahiert

---

## Einheit 4.9: State Management (2h)

### Aufgaben

1. **Provider Setup**
   - ProviderScope in main.dart
   - Alle Provider definieren

2. **NotesProvider**
   ```dart
   // Funktionen:
   - loadNotes()
   - addNote(Note)
   - updateNote(Note)
   - deleteNote(String id)
   - togglePin(String id)
   - archiveNote(String id)
   - searchNotes(String query)
   - filterByCategory(String? categoryId)
   ```

3. **CategoriesProvider**
   ```dart
   // Funktionen:
   - loadCategories()
   - addCategory(Category)
   - updateCategory(Category)
   - deleteCategory(String id)
   ```

4. **SettingsProvider**
   ```dart
   // Funktionen:
   - loadSettings()
   - updateThemeMode(ThemeMode)
   - updateSortOrder(SortOrder)
   - toggleConfirmDelete()
   ```

5. **Repository-Pattern**
   - NotesRepository Interface
   - CategoriesRepository Interface
   - Implementierungen

### Abgabe
- [ ] Alle Provider implementiert
- [ ] UI reagiert auf State-Änderungen
- [ ] Repository-Pattern umgesetzt
- [ ] Separation of Concerns

---

## Einheit 4.10: Daten & API (2h)

### Aufgaben

1. **Hive Setup**
   ```dart
   // In main.dart:
   await Hive.initFlutter();
   Hive.registerAdapter(NoteAdapter());
   Hive.registerAdapter(CategoryAdapter());
   ```

2. **LocalStorageService**
   ```dart
   class LocalStorageService {
     // Notes
     Future<List<Note>> getAllNotes();
     Future<void> saveNote(Note note);
     Future<void> deleteNote(String id);

     // Categories
     Future<List<Category>> getAllCategories();
     Future<void> saveCategory(Category category);

     // Settings
     Future<UserSettings> getSettings();
     Future<void> saveSettings(UserSettings settings);
   }
   ```

3. **ApiService (Mock)**
   ```dart
   class ApiService {
     // Simuliere API-Calls mit Delay
     Future<List<Note>> fetchNotes();
     Future<Note> createNote(Note note);
     Future<Note> updateNote(Note note);
     Future<void> deleteNote(String id);
   }
   ```

4. **Repository Implementation**
   - Lokale Daten als primäre Quelle
   - API als sekundäre Quelle (optional)
   - Offline-Erkennung

5. **Error Handling**
   - Try/Catch in Services
   - Error States in Providern
   - User-Feedback bei Fehlern

### Abgabe
- [ ] Daten werden lokal gespeichert
- [ ] Daten überleben App-Neustart
- [ ] API-Service (Mock) funktioniert
- [ ] Error Handling implementiert

---

## Einheit 4.11: Formulare & Validierung (2h)

### Aufgaben

1. **Note Editor Form**
   ```dart
   // Validierung:
   - Titel: Nicht leer, max 100 Zeichen
   - Inhalt: Optional, max 10000 Zeichen
   - Kategorie: Optional
   ```

2. **Auto-Save mit Debouncing**
   ```dart
   // Nach 2 Sekunden ohne Eingabe speichern
   // Indikator anzeigen beim Speichern
   ```

3. **Unsaved Changes Detection**
   ```dart
   // Bei Zurück-Navigation:
   // - Prüfen ob Änderungen vorhanden
   // - Dialog "Änderungen verwerfen?"
   ```

4. **Category Dialog**
   ```
   ┌─────────────────────────────────┐
   │ Neue Kategorie                  │
   ├─────────────────────────────────┤
   │ Name: [________________]        │
   │                                 │
   │ Farbe: 🔴 🟠 🟡 🟢 🔵 🟣       │
   │                                 │
   │    [Abbrechen]  [Speichern]    │
   └─────────────────────────────────┘
   ```

5. **Delete Confirmation**
   - Einstellung beachten
   - Dialog mit Notiz-Titel
   - Undo via Snackbar (optional)

### Abgabe
- [ ] Formular mit Validierung
- [ ] Auto-Save funktioniert
- [ ] Unsaved Changes Dialog
- [ ] Category CRUD mit Dialog
- [ ] Delete Confirmation

---

## Einheit 4.12: Animationen, Tests & Feinschliff (2h)

### Aufgaben

1. **Animationen**
   - Hero-Animation für Note-Karten
   - AnimatedList für Notizliste
   - Staggered Einblendung beim Laden
   - Page Transitions

2. **Unit Tests**
   ```dart
   // Teste:
   - Note Model (fromJson, toJson)
   - NotesRepository
   - Validators
   ```

3. **Widget Tests**
   ```dart
   // Teste:
   - NoteCard Widget
   - Home Screen (mit Mock-Daten)
   - Editor Screen (Formular)
   ```

4. **Feinschliff**
   - Loading States überall
   - Empty States
   - Error States
   - Pull-to-Refresh

5. **Release-Vorbereitung**
   - App-Icon
   - Splash Screen
   - Release Build testen

### Abgabe
- [ ] Animationen implementiert
- [ ] Unit Tests (min. 5)
- [ ] Widget Tests (min. 3)
- [ ] Code Coverage > 70%
- [ ] Release Build funktioniert

---

## Gesamtabgabe

### Pflicht-Features
- [ ] Notizen erstellen/bearbeiten/löschen
- [ ] Kategorien verwalten
- [ ] Suche funktioniert
- [ ] Offline-Speicherung
- [ ] Dark/Light Mode
- [ ] Grundlegende Animationen
- [ ] Tests vorhanden

### Bonus-Features (optional)
- [ ] Cloud-Sync mit Firebase/Supabase
- [ ] Markdown-Unterstützung
- [ ] Bilder in Notizen
- [ ] Export als PDF
- [ ] Widgets auf Homescreen
- [ ] Share-Funktion

### Dokumentation
- [ ] README.md mit Setup-Anleitung
- [ ] Screenshots der App
- [ ] Architektur-Beschreibung

---

## Hinweise

- Arbeite in kleinen Commits
- Teste regelmäßig auf echtem Gerät
- Bei Problemen: Dokumentation konsultieren
- Code Reviews mit Kollegen (falls möglich)
- Zeitmanagement beachten
