# Übung 3.12: DatePicker, TimePicker & Dialoge

## Ziel

Eine Termin-Planungs-App mit verschiedenen Dialogen erstellen.

---

## Aufgabe 1: DatePicker Integration (20 min)

Erstelle ein Formular für einen Termin:

```
┌─────────────────────────────────┐
│ Neuer Termin                    │
├─────────────────────────────────┤
│ Datum: [15.03.2024        📅]  │
│ Uhrzeit: [14:30          🕐]   │
│ Dauer: [1 Stunde         ▼]    │
└─────────────────────────────────┘
```

Anforderungen:
- Datum darf nicht in der Vergangenheit liegen
- Wochenenden deaktivieren
- Uhrzeit in 15-Minuten-Schritten (z.B. 14:00, 14:15, 14:30)
- Dauer als Dropdown (30 Min, 1h, 1.5h, 2h)

---

## Aufgabe 2: Termin-Übersicht mit Dialog (25 min)

Erstelle eine Liste von Terminen mit Aktions-Dialog:

```
┌─────────────────────────────────┐
│ Termine                         │
├─────────────────────────────────┤
│ 📅 Meeting mit Team             │
│    15.03.2024, 14:00           │
│ ─────────────────────────────── │
│ 📅 Arzttermin                   │
│    16.03.2024, 10:30           │
└─────────────────────────────────┘
```

Bei Tap auf einen Termin:
- Bottom Sheet mit Optionen:
  - Details anzeigen
  - Bearbeiten
  - Verschieben
  - Löschen

Bei "Löschen":
- Bestätigungsdialog anzeigen

---

## Aufgabe 3: Date Range Picker (15 min)

Erstelle einen Urlaubsplaner:

```
┌─────────────────────────────────┐
│ Urlaub planen                   │
├─────────────────────────────────┤
│ Zeitraum auswählen:             │
│ [01.04.2024 - 14.04.2024]      │
│                                 │
│ Dauer: 14 Tage (10 Werktage)   │
└─────────────────────────────────┘
```

- Zeige ausgewählten Zeitraum
- Berechne Anzahl der Tage
- Berechne Werktage (ohne Wochenenden)

---

## Aufgabe 4: Debounced Search (20 min)

Erstelle eine Suchfunktion mit Debouncing:

```dart
// Simulierte API
Future<List<String>> searchContacts(String query) async {
  await Future.delayed(const Duration(milliseconds: 300));

  final contacts = [
    'Max Mustermann', 'Maria Müller', 'Michael Meyer',
    'Anna Schmidt', 'Andreas Fischer', 'Petra Wagner',
  ];

  return contacts
      .where((c) => c.toLowerCase().contains(query.toLowerCase()))
      .toList();
}
```

Anforderungen:
- Debounce von 500ms
- Loading-Indikator während Suche
- Ergebnisse live anzeigen
- "Keine Ergebnisse" wenn leer

---

## Aufgabe 5: Custom Dialog (20 min)

Erstelle einen wiederverwendbaren Bewertungs-Dialog:

```
┌─────────────────────────────────┐
│         Bewertung               │
│                                 │
│     ☆ ☆ ☆ ★ ★                  │
│                                 │
│ ┌─────────────────────────────┐ │
│ │ Dein Kommentar...           │ │
│ │                             │ │
│ └─────────────────────────────┘ │
│                                 │
│   [Abbrechen]    [Bewerten]    │
└─────────────────────────────────┘
```

- Sterne-Bewertung (1-5)
- Optionaler Kommentar
- Rückgabe: `(int rating, String? comment)`

```dart
final result = await showRatingDialog(context);
if (result != null) {
  print('Rating: ${result.$1}, Comment: ${result.$2}');
}
```

---

## Aufgabe 6: Snackbar Actions (15 min)

Implementiere verschiedene Snackbar-Szenarien:

1. **Erfolg:** "Termin gespeichert" (grün, 2 Sekunden)

2. **Warnung:** "Offline-Modus aktiv" (orange, persistent, mit "Einstellungen" Action)

3. **Fehler:** "Speichern fehlgeschlagen" (rot, mit "Erneut versuchen" Action)

4. **Undo:** "Termin gelöscht" (mit "Rückgängig" Action, 5 Sekunden)

---

## Aufgabe 7: Komplette Termin-App (30 min)

Kombiniere alles zu einer Termin-App:

```
┌─────────────────────────────────┐
│ Meine Termine       [🔍] [+]   │
├─────────────────────────────────┤
│ Heute                           │
│ ├── 09:00 Standup Meeting       │
│ └── 14:00 Code Review           │
│                                 │
│ Morgen                          │
│ └── 10:30 Kundengespräch        │
│                                 │
│ Diese Woche                     │
│ └── Fr 15:00 Team-Event        │
└─────────────────────────────────┘
```

Features:
- Suche mit Debouncing
- FAB zum Erstellen (öffnet Bottom Sheet)
- Tap auf Termin → Details Dialog
- Long Press → Aktions-Bottom Sheet
- Löschen mit Undo-Snackbar
- Datum/Zeit Picker beim Erstellen
- Bewertung nach abgeschlossenem Termin

---

## Abgabe-Checkliste

- [ ] DatePicker mit Einschränkungen
- [ ] TimePicker integriert
- [ ] Bottom Sheet für Aktionen
- [ ] Bestätigungsdialog für Löschen
- [ ] Date Range Picker funktioniert
- [ ] Debounced Search implementiert
- [ ] Custom Rating Dialog
- [ ] Verschiedene Snackbar-Typen
- [ ] Komplette Termin-App
