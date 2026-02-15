# Übung 3.11: Dropdowns, Checkboxen & Switches

## Ziel

Ein Einstellungsformular mit verschiedenen Auswahloptionen erstellen.

---

## Aufgabe 1: Dropdown Basics (20 min)

Erstelle ein Bestellformular mit Dropdowns:

1. **Produktkategorie** (Pflichtfeld)
   - Elektronik, Kleidung, Bücher, Sport

2. **Zahlungsart**
   - Kreditkarte, PayPal, Rechnung, Vorkasse

3. **Lieferzeit**
   - Standard (3-5 Tage), Express (1-2 Tage), Overnight

Anforderungen:
- Hint-Text wenn nichts ausgewählt
- Validierung: Kategorie ist Pflichtfeld
- Icons vor den Optionen

---

## Aufgabe 2: Checkboxen (20 min)

Erstelle einen Newsletter-Bereich:

```
┌─────────────────────────────────┐
│ Newsletter Einstellungen        │
├─────────────────────────────────┤
│ ☑ Newsletter abonnieren        │
│                                 │
│ Wenn abonniert:                 │
│ ☑ Wöchentliche Updates         │
│ ☐ Monatliche Zusammenfassung   │
│ ☑ Produktneuheiten             │
│ ☐ Sonderangebote               │
│                                 │
│ [Alle auswählen] [Keine]        │
└─────────────────────────────────┘
```

- Haupt-Checkbox aktiviert/deaktiviert Unteroptionen
- "Alle auswählen" und "Keine" Buttons
- Unteroptionen nur sichtbar wenn Newsletter aktiv

---

## Aufgabe 3: Radio Buttons (15 min)

Erstelle einen Versandoptionen-Wähler:

```dart
enum ShippingOption {
  standard,   // Kostenlos, 5-7 Tage
  express,    // 4,99€, 2-3 Tage
  overnight,  // 9,99€, Nächster Tag
}
```

Zeige für jede Option:
- Titel
- Preis
- Lieferzeit
- Icon

Berechne den Gesamtpreis basierend auf der Auswahl.

---

## Aufgabe 4: Switches (15 min)

Erstelle einen Settings-Bereich:

```
┌─────────────────────────────────┐
│ App Einstellungen               │
├─────────────────────────────────┤
│ Dark Mode                [===] │
│ Benachrichtigungen       [===] │
│ Standortdienste          [   ] │
│ Automatische Updates     [===] │
│ Datensammlung            [   ] │
└─────────────────────────────────┘
```

- Jeder Switch hat Titel und Icon
- Änderungen werden sofort "gespeichert" (State)
- Zeige Snackbar bei Änderung

---

## Aufgabe 5: Chips (25 min)

Erstelle einen Tag-Filter:

```
┌─────────────────────────────────┐
│ Kategorien filtern              │
├─────────────────────────────────┤
│ ┌────┐ ┌────┐ ┌────┐ ┌────┐    │
│ │Web │ │App │ │API │ │ DB │    │
│ └────┘ └────┘ └────┘ └────┘    │
│ ┌─────┐ ┌──────┐ ┌───────┐     │
│ │UI/UX│ │DevOps│ │Testing│     │
│ └─────┘ └──────┘ └───────┘     │
│                                 │
│ Ausgewählt: Web, API            │
│ [Filter anwenden]               │
└─────────────────────────────────┘
```

Features:
- FilterChip für Multi-Select
- Zeige ausgewählte Tags als Text
- "Filter anwenden" Button
- Mindestens eine Auswahl erforderlich

---

## Aufgabe 6: Größenauswahl mit ChoiceChip (15 min)

Erstelle eine Größenauswahl für einen Shop:

```
Größe auswählen:
[XS] [S] [M*] [L] [XL] [XXL]

* = nicht verfügbar (disabled)
```

- Nur eine Größe auswählbar
- Einige Größen als "nicht verfügbar" markieren
- Disabled Chips visuell unterscheiden
- Validierung: Größe muss ausgewählt sein

---

## Aufgabe 7: Komplett-Formular (30 min)

Erstelle ein vollständiges Produktkonfigurations-Formular:

```
┌─────────────────────────────────┐
│ Produkt konfigurieren           │
├─────────────────────────────────┤
│ Modell: [MacBook Pro    ▼]     │
│                                 │
│ Farbe:                          │
│ ○ Space Grau  ○ Silber         │
│                                 │
│ Speicher:                       │
│ [256GB] [512GB] [1TB] [2TB]    │
│                                 │
│ Extras:                         │
│ ☑ AppleCare+ (+149€)           │
│ ☐ Magic Mouse (+99€)           │
│ ☐ Magic Keyboard (+129€)       │
│                                 │
│ Gravur: [Toggle]                │
│ [Wenn aktiv: TextField]         │
│                                 │
│ Geschenkverpackung: [Toggle]    │
│                                 │
│ ─────────────────────────────── │
│ Gesamtpreis: 2.497€             │
│                                 │
│ [In den Warenkorb]              │
└─────────────────────────────────┘
```

Anforderungen:
- Dropdown für Modell (verschiedene Basispreise)
- Radio für Farbe
- ChoiceChip für Speicher (Aufpreis)
- Checkboxen für Extras (mit Preisen)
- Switch für Gravur (zeigt TextField wenn aktiv)
- Switch für Geschenkverpackung
- Echtzeit-Preisberechnung
- Validierung vor "In den Warenkorb"

---

## Abgabe-Checkliste

- [ ] Dropdowns mit Validierung
- [ ] Checkbox-Gruppe mit Master-Checkbox
- [ ] Radio Buttons mit Beschreibung
- [ ] Switches in Settings-Stil
- [ ] FilterChip Multi-Select
- [ ] ChoiceChip Single-Select
- [ ] Komplett-Formular mit Preisberechnung
