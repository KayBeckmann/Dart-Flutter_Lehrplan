# Übung 4.4: Widget & Integration Tests

## Ziel

Widget Tests für verschiedene UI-Komponenten schreiben und Integration Tests erstellen.

---

## Aufgabe 1: Counter Widget Tests (20 min)

Teste ein Counter-Widget vollständig:

```dart
class CounterWidget extends StatefulWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final void Function(int)? onChanged;

  const CounterWidget({
    super.key,
    this.initialValue = 0,
    this.minValue = 0,
    this.maxValue = 100,
    this.onChanged,
  });

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}
```

Teste:
- Initial value wird angezeigt
- Increment-Button erhöht Wert
- Decrement-Button verringert Wert
- Min-/Max-Grenzen werden eingehalten
- Buttons werden deaktiviert an Grenzen
- onChanged Callback wird aufgerufen

---

## Aufgabe 2: Form Widget Tests (25 min)

Teste ein Registrierungsformular:

```
┌─────────────────────────────────────┐
│ Registrierung                       │
├─────────────────────────────────────┤
│ Name: [________________]            │
│ Email: [________________]           │
│ Passwort: [________________]        │
│ Passwort bestätigen: [________]     │
│                                     │
│ [ ] AGB akzeptieren                 │
│                                     │
│ [      Registrieren      ]          │
└─────────────────────────────────────┘
```

Teste:
- Alle Felder sind vorhanden
- Validierung bei leerem Submit
- Email-Format Validierung
- Passwort-Übereinstimmung
- AGB müssen akzeptiert werden
- Submit-Button wird bei Loading deaktiviert

---

## Aufgabe 3: Liste mit Interaktionen (25 min)

Teste eine Todo-Liste:

```dart
class TodoList extends StatefulWidget {
  const TodoList({super.key});

  @override
  State<TodoList> createState() => _TodoListState();
}

// Features:
// - Liste von Todos anzeigen
// - Checkbox zum Abhaken
// - Swipe zum Löschen (Dismissible)
// - FAB zum Hinzufügen (öffnet Dialog)
// - Filter: Alle/Offen/Erledigt
```

Teste:
- Todos werden angezeigt
- Checkbox toggeln funktioniert
- Swipe-to-Delete
- Neues Todo hinzufügen über Dialog
- Filter wechseln

---

## Aufgabe 4: Navigation Tests (20 min)

Teste die Navigation zwischen Screens:

```dart
// App mit folgenden Screens:
// 1. Home Screen mit Liste
// 2. Detail Screen (bei Tap auf Item)
// 3. Edit Screen (bei Tap auf Edit-Button)
// 4. Settings Screen (über Drawer)
```

Teste:
- Navigation zu Detail bei Item-Tap
- Back-Navigation von Detail
- Navigation zu Edit mit korrekten Daten
- Rückgabe-Wert von Edit Screen
- Drawer öffnen und zu Settings navigieren

---

## Aufgabe 5: Async Widget Tests (20 min)

Teste ein Widget mit asynchronen Daten:

```dart
class UserProfile extends StatelessWidget {
  final UserRepository repository;

  const UserProfile({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: repository.getCurrentUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(key: Key('loading'));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', key: const Key('error'));
        }
        final user = snapshot.data!;
        return Column(
          children: [
            Text(user.name, key: const Key('name')),
            Text(user.email, key: const Key('email')),
          ],
        );
      },
    );
  }
}
```

Teste:
- Loading-State wird angezeigt
- Daten werden nach Laden angezeigt
- Fehler wird bei Exception angezeigt

---

## Aufgabe 6: Golden Tests (20 min)

Erstelle Golden Tests für UI-Komponenten:

1. **ProductCard** - Produktkarte mit Bild, Titel, Preis
2. **RatingStars** - 1-5 Sterne Bewertung
3. **StatusBadge** - Badge mit verschiedenen Farben (success, warning, error)

```dart
// Erstelle Golden Files für:
// - ProductCard in verschiedenen Zuständen
// - RatingStars mit 0-5 Sternen
// - StatusBadge für jeden Status
```

---

## Aufgabe 7: Integration Test (30 min)

Erstelle einen vollständigen Integration Test für einen User Flow:

```
User Flow: Produkt zum Warenkorb hinzufügen

1. App starten → Home Screen
2. Produkt suchen (Suchfeld)
3. Ergebnisse anzeigen
4. Auf Produkt tippen → Detail Screen
5. Menge auswählen
6. "In den Warenkorb" tippen
7. Snackbar bestätigen
8. Zum Warenkorb navigieren
9. Produkt ist im Warenkorb
```

Schreibe einen Integration Test der den gesamten Flow durchläuft.

---

## Aufgabe 8: Test Coverage Report (15 min)

1. Führe alle Tests mit Coverage aus
2. Generiere HTML-Report
3. Identifiziere ungetestete Bereiche
4. Schreibe Tests für mindestens einen ungetesteten Bereich

```bash
# Commands
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

Ziel: Erreiche mindestens 80% Coverage.

---

## Bonus: Custom Finder

Erstelle eigene Finder für häufige Patterns:

```dart
// Beispiel: Finder für Formularfeld mit Label
Finder findFieldByLabel(String label) {
  return find.ancestor(
    of: find.text(label),
    matching: find.byType(TextFormField),
  );
}

// Erstelle Finder für:
// 1. Card mit bestimmtem Titel
// 2. Button mit Icon und Text
// 3. ListTile mit Subtitle
```

---

## Abgabe-Checkliste

- [ ] Counter Widget vollständig getestet
- [ ] Form mit Validierung getestet
- [ ] Todo-Liste mit Interaktionen getestet
- [ ] Navigation Tests funktionieren
- [ ] Async Widget Tests mit Mocks
- [ ] Golden Tests für 3 Komponenten
- [ ] Integration Test für User Flow
- [ ] Coverage Report generiert
- [ ] Mindestens 80% Coverage erreicht
- [ ] Alle Tests sind grün
