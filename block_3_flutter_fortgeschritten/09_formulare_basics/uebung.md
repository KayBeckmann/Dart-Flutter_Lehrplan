# Übung 3.9: Formulare Basics

## Ziel

Ein Kontaktformular mit verschiedenen Eingabefeldern erstellen.

---

## Aufgabe 1: Einfaches Formular (20 min)

Erstelle ein Login-Formular mit:
- E-Mail Feld
- Passwort Feld (verborgen)
- Login Button
- "Passwort vergessen?" Link

Anforderungen:
- Beide Felder sind Pflichtfelder
- E-Mail muss "@" enthalten
- Button ist disabled während Validierung fehlschlägt

---

## Aufgabe 2: InputDecoration Styling (20 min)

Erstelle drei unterschiedlich gestylte TextFormFields:

1. **Outline Style:**
   - Umrandetes Feld
   - Icon links
   - Clear-Button rechts

2. **Filled Style:**
   - Gefüllter Hintergrund
   - Keine Umrandung
   - Abgerundete Ecken

3. **Custom Style:**
   - Unterstrichen
   - Prefix-Text
   - Counter anzeigen

---

## Aufgabe 3: Kontaktformular (30 min)

Erstelle ein vollständiges Kontaktformular:

```
┌─────────────────────────────────┐
│ Kontakt                         │
├─────────────────────────────────┤
│                                 │
│ Name *                          │
│ ┌─────────────────────────────┐ │
│ │ 👤 Max Mustermann           │ │
│ └─────────────────────────────┘ │
│                                 │
│ E-Mail *                        │
│ ┌─────────────────────────────┐ │
│ │ ✉️  max@example.com          │ │
│ └─────────────────────────────┘ │
│                                 │
│ Telefon                         │
│ ┌─────────────────────────────┐ │
│ │ 📞 +49 123 456789           │ │
│ └─────────────────────────────┘ │
│                                 │
│ Betreff *                       │
│ ┌─────────────────────────────┐ │
│ │ Anfrage zu Produkt X        │ │
│ └─────────────────────────────┘ │
│                                 │
│ Nachricht *                     │
│ ┌─────────────────────────────┐ │
│ │ Ihre Nachricht hier...      │ │
│ │                             │ │
│ │                             │ │
│ │                             │ │
│ │                      42/500 │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Zurücksetzen]  [Absenden]      │
│                                 │
└─────────────────────────────────┘
```

Features:
- Pflichtfelder mit *
- Passende Keyboard-Typen
- Character Counter bei Nachricht
- Tab-Navigation zwischen Feldern
- Validierung bei Submit

---

## Aufgabe 4: FocusNode Navigation (15 min)

Erweitere das Kontaktformular:
1. Enter auf einem Feld → Fokus zum nächsten
2. Letzes Feld → Submit
3. Button um Fokus auf erstes Feld zu setzen

```dart
TextFormField(
  focusNode: _nameFocus,
  textInputAction: TextInputAction.next,
  onFieldSubmitted: (_) {
    FocusScope.of(context).requestFocus(_emailFocus);
  },
)
```

---

## Aufgabe 5: Passwort mit Toggle (15 min)

Erstelle ein Passwort-Feld mit:
- Auge-Icon zum Ein-/Ausblenden
- Passwort-Stärke Anzeige
- Mindestens 8 Zeichen
- Mindestens eine Zahl

```
┌─────────────────────────────────┐
│ Passwort *                      │
│ ┌─────────────────────────────┐ │
│ │ 🔒 ●●●●●●●●          👁    │ │
│ └─────────────────────────────┘ │
│ Stärke: ████████░░ Mittel       │
└─────────────────────────────────┘
```

---

## Aufgabe 6: Formular-Daten Model (20 min)

Erstelle ein Model für die Formulardaten:

```dart
class ContactFormData {
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;

  ContactFormData({
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
  });
}
```

1. Bei Submit: Erstelle `ContactFormData` Objekt
2. Zeige die Daten in einem Dialog
3. Nach Bestätigung: Formular zurücksetzen

---

## Aufgabe 7: Verständnisfragen

1. Wann braucht man einen `TextEditingController`?

2. Was ist der Unterschied zwischen `TextField` und `TextFormField`?

3. Warum muss man Controller und FocusNodes in `dispose()` freigeben?

4. Was macht `AutovalidateMode.onUserInteraction`?

5. Wie kann man den Fokus programmatisch setzen?

---

## Abgabe-Checkliste

- [ ] Login-Formular funktioniert
- [ ] Drei verschiedene InputDecoration Styles
- [ ] Kontaktformular mit allen Feldern
- [ ] Validierung funktioniert
- [ ] FocusNode Navigation implementiert
- [ ] Passwort Toggle funktioniert
- [ ] Formular-Daten in Model
- [ ] Verständnisfragen beantwortet
