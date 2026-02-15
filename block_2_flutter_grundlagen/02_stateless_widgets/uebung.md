# Übung 2.2: StatelessWidget & Basis-Widgets

---

## Aufgabe 1: Visitenkarte (20 Min.)

Erstelle ein `Visitenkarte`-Widget:

```dart
// Verwendung:
Visitenkarte(
  name: 'Max Mustermann',
  position: 'Senior Developer',
  firma: 'Tech GmbH',
  email: 'max@tech.de',
  telefon: '+49 123 456789',
)
```

**Anforderungen:**
- Card mit abgerundeten Ecken
- Icon für jeden Kontakttyp (Email, Telefon)
- Name fett und größer
- Firmenname in Grau

---

## Aufgabe 2: Produktkarte (20 Min.)

Erstelle ein `ProduktKarte`-Widget für einen Shop:

```dart
ProduktKarte(
  name: 'Flutter T-Shirt',
  preis: 29.99,
  bildUrl: 'https://picsum.photos/200',
  aufLager: true,
)
```

**Anforderungen:**
- Bild oben
- Name und Preis darunter
- "Auf Lager" / "Ausverkauft" Badge
- "In den Warenkorb" Button

---

## Aufgabe 3: Bewertungsanzeige (15 Min.)

Erstelle ein `Bewertung`-Widget:

```dart
Bewertung(sterne: 4, maxSterne: 5)
// Zeigt: ★★★★☆
```

**Anforderungen:**
- Zeigt gefüllte und leere Sterne
- Farbe: Amber für gefüllt, Grau für leer
- Optional: Anzahl Bewertungen anzeigen

---

## Bonusaufgabe: Wetterkarte

```dart
WetterKarte(
  stadt: 'Berlin',
  temperatur: 22,
  zustand: WetterZustand.sonnig,
)

enum WetterZustand { sonnig, bewölkt, regnerisch, schnee }
```
