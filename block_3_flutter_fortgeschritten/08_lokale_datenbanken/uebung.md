# Übung 3.8: Lokale Datenbanken

## Ziel

Eine Notizen-App mit lokaler Datenbank implementieren.

---

## Aufgabe 1: sqflite Setup (20 min)

1. Füge `sqflite` und `path` zu deinem Projekt hinzu
2. Erstelle einen `DatabaseHelper` mit:
   - Singleton-Pattern
   - Datenbank-Initialisierung
   - `onCreate` mit Tabellen-Erstellung

Tabellen-Schema für Notes:

```sql
CREATE TABLE notes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  content TEXT,
  color INTEGER DEFAULT 0,
  is_pinned INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT
);
```

---

## Aufgabe 2: Note Model & Repository (25 min)

Erstelle das Note Model:

```dart
class Note {
  final int? id;
  final String title;
  final String content;
  final int color;  // Farb-Index (0-5)
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Implementiere:
  // - Konstruktor
  // - toMap()
  // - fromMap()
  // - copyWith()
}
```

Erstelle das `NoteRepository` mit:
- `insert(Note note)`
- `getAll()`
- `getById(int id)`
- `update(Note note)`
- `delete(int id)`
- `search(String query)` - Suche in title und content
- `getPinned()` - Nur angepinnte Notizen

---

## Aufgabe 3: Notes UI mit sqflite (30 min)

Erstelle eine Notizen-App:

```
┌─────────────────────────────────┐
│ Notizen                 [🔍]   │
├─────────────────────────────────┤
│ Angepinnt                       │
│ ┌─────────────────────────────┐ │
│ │ 📌 Wichtige Notiz           │ │
│ │ Text hier...                │ │
│ └─────────────────────────────┘ │
│                                 │
│ Alle Notizen                    │
│ ┌─────────────────────────────┐ │
│ │ Einkaufsliste               │ │
│ │ Milch, Brot, Eier...        │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ Meeting Notes               │ │
│ │ Projekt besprechen...       │ │
│ └─────────────────────────────┘ │
│                           [+]   │
└─────────────────────────────────┘
```

Features:
- Notizen erstellen/bearbeiten
- Notizen löschen (Swipe oder Long Press)
- Notizen anpinnen
- Farbauswahl (6 Farben)
- Suche

---

## Aufgabe 4: Hive Alternative (25 min)

Implementiere dieselbe Notizen-App mit Hive:

1. Setup:
   ```yaml
   dependencies:
     hive: ^2.2.3
     hive_flutter: ^1.1.0
   dev_dependencies:
     hive_generator: ^2.0.1
     build_runner: ^2.4.8
   ```

2. Note Model mit Hive Annotations:
   ```dart
   @HiveType(typeId: 0)
   class Note extends HiveObject {
     @HiveField(0)
     late String id;

     @HiveField(1)
     late String title;

     // ...
   }
   ```

3. Code generieren: `flutter pub run build_runner build`

4. Repository mit Hive implementieren

5. UI mit `ValueListenableBuilder` für reactive Updates

---

## Aufgabe 5: Vergleich (15 min)

Dokumentiere deine Erfahrungen:

| Kriterium | sqflite | Hive |
|-----------|---------|------|
| Setup-Aufwand | | |
| Code-Menge | | |
| Performance (gefühlt) | | |
| Flexibilität | | |
| Reaktive UI | | |
| Lernkurve | | |

Beantworte:
1. Welche Lösung würdest du für diese App bevorzugen? Warum?
2. Wann würdest du sqflite wählen?
3. Wann würdest du Hive wählen?

---

## Aufgabe 6: Bonus - Kategorien (Optional)

Erweitere die App um Kategorien:

sqflite:
```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  color INTEGER
);

-- Notes hat jetzt category_id
ALTER TABLE notes ADD COLUMN category_id INTEGER REFERENCES categories(id);
```

Features:
- Kategorien erstellen/bearbeiten/löschen
- Notizen einer Kategorie zuweisen
- Filter nach Kategorie
- JOIN-Query für Notizen mit Kategorie-Namen

---

## Aufgabe 7: Migration (Optional)

Implementiere eine Datenbank-Migration:

Version 1 → Version 2:
- Neues Feld `is_archived` hinzufügen

```dart
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 2) {
    await db.execute(
      'ALTER TABLE notes ADD COLUMN is_archived INTEGER DEFAULT 0',
    );
  }
}
```

Teste:
1. App mit Version 1 installieren
2. Einige Notizen erstellen
3. Version auf 2 erhöhen
4. App neu starten → Migration sollte laufen
5. Alte Daten müssen erhalten bleiben

---

## Abgabe-Checkliste

- [ ] sqflite Setup funktioniert
- [ ] Note Model mit toMap/fromMap
- [ ] NoteRepository mit allen CRUD-Methoden
- [ ] Notes UI vollständig
- [ ] Suche funktioniert
- [ ] Pinnen funktioniert
- [ ] Hive-Alternative implementiert
- [ ] Vergleich dokumentiert
- [ ] (Bonus) Kategorien
- [ ] (Bonus) Migration
