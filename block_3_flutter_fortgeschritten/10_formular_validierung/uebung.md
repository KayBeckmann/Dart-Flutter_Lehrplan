# Übung 3.10: Formular-Validierung

## Ziel

Verschiedene Validierungsszenarien implementieren.

---

## Aufgabe 1: Validator-Bibliothek (25 min)

Erstelle eine `Validators` Klasse mit wiederverwendbaren Validatoren:

```dart
class Validators {
  // Pflichtfeld
  static String? required(String? value);

  // Mindestlänge
  static String? Function(String?) minLength(int length);

  // Maximallänge
  static String? Function(String?) maxLength(int length);

  // E-Mail Format
  static String? email(String? value);

  // Nur Zahlen
  static String? numeric(String? value);

  // Nur Buchstaben
  static String? alpha(String? value);

  // Alphanumerisch
  static String? alphanumeric(String? value);

  // Benutzerdefiniertes Pattern
  static String? Function(String?) pattern(RegExp regex, String message);

  // Mehrere Validatoren kombinieren
  static String? Function(String?) combine(List<String? Function(String?)> validators);
}
```

Teste jeden Validator mit verschiedenen Eingaben.

---

## Aufgabe 2: Passwort-Validierung (20 min)

Erstelle einen Passwort-Validator mit Echtzeit-Feedback:

```
┌─────────────────────────────────┐
│ Passwort                        │
│ ┌─────────────────────────────┐ │
│ │ ●●●●●●●●●●                  │ │
│ └─────────────────────────────┘ │
│                                 │
│ Anforderungen:                  │
│ ✅ Mindestens 8 Zeichen         │
│ ✅ Großbuchstabe                │
│ ❌ Kleinbuchstabe               │
│ ✅ Zahl                         │
│ ❌ Sonderzeichen                │
│                                 │
│ Stärke: ████████░░ Mittel       │
└─────────────────────────────────┘
```

- Zeige jede Anforderung einzeln
- Grünes Häkchen wenn erfüllt
- Stärke-Anzeige aktualisiert sich live

---

## Aufgabe 3: Registrierungsformular (30 min)

Erstelle ein Registrierungsformular mit:

1. **Benutzername**
   - Pflichtfeld, 3-20 Zeichen
   - Nur Buchstaben, Zahlen, Unterstriche
   - Async-Check: Simuliere "admin" und "test" als vergeben

2. **E-Mail**
   - Pflichtfeld
   - Gültiges E-Mail Format

3. **Passwort**
   - Alle Anforderungen aus Aufgabe 2

4. **Passwort bestätigen**
   - Muss mit Passwort übereinstimmen

5. **Geburtsdatum**
   - Muss in der Vergangenheit liegen
   - Mindestens 13 Jahre alt

6. **AGBs akzeptieren**
   - Checkbox muss angehakt sein

---

## Aufgabe 4: Cross-Field Validierung (20 min)

Erstelle ein Datum-Range Formular:

```dart
class DateRangeForm {
  DateTime? startDate;
  DateTime? endDate;
  int? maxDays;  // Optional: Maximale Dauer
}
```

Validierungen:
- Startdatum erforderlich
- Enddatum erforderlich
- Enddatum muss nach Startdatum liegen
- Wenn maxDays gesetzt: Differenz darf maxDays nicht überschreiten

```
Fehler: Enddatum (15.03.2024) liegt vor Startdatum (20.03.2024)
```

---

## Aufgabe 5: AutovalidateMode verstehen (15 min)

Erstelle drei identische Formulare mit verschiedenen AutovalidateModes:

1. `AutovalidateMode.disabled`
2. `AutovalidateMode.always`
3. `AutovalidateMode.onUserInteraction`

Beobachte und dokumentiere:
- Wann werden Fehler angezeigt?
- Wie fühlt sich die UX an?
- Welcher Modus ist wann am besten?

---

## Aufgabe 6: Async-Validierung mit Debounce (20 min)

Implementiere ein E-Mail Feld mit Server-Validierung:

```dart
Future<bool> checkEmailExists(String email) async {
  await Future.delayed(Duration(milliseconds: 500));
  // Simuliere: Diese E-Mails sind "registriert"
  return ['test@example.com', 'admin@example.com'].contains(email);
}
```

Anforderungen:
- Debounce: Erst nach 500ms Pause prüfen
- Loading-Indikator während der Prüfung
- Grünes Häkchen wenn E-Mail verfügbar
- Rotes X wenn bereits registriert
- Fehler im Validator berücksichtigen

---

## Aufgabe 7: Formular mit Conditional Fields (25 min)

Erstelle ein Versandformular:

```
Lieferart: ○ Abholung  ○ Versand

[Wenn Versand ausgewählt:]
Straße: ____________
PLZ: ____
Stadt: ____________
Land: [Dropdown: DE, AT, CH]

[Wenn DE ausgewählt:]
Packstation: ○ Ja  ○ Nein

[Wenn Packstation Ja:]
Packstation Nr: ________
Postnummer: __________
```

- Felder werden nur angezeigt wenn relevant
- Validierung nur für sichtbare Felder
- PLZ-Format abhängig vom Land

---

## Abgabe-Checkliste

- [ ] Validators Klasse mit allen Methoden
- [ ] Passwort-Validierung mit Live-Feedback
- [ ] Registrierungsformular vollständig
- [ ] Cross-Field Validierung für Datum
- [ ] AutovalidateMode Dokumentation
- [ ] Async-Validierung mit Debounce
- [ ] Conditional Fields funktionieren
