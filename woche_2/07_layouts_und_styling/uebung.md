# Modul 7: Uebung -- Dashboard-App

## Aufgabenstellung

Erstelle eine **Dashboard-Ansicht**, die verschiedene Layout-Widgets kombiniert und responsive auf unterschiedliche Bildschirmbreiten reagiert. Diese Uebung trainiert den Umgang mit Row, Column, Expanded, ListView, GridView, LayoutBuilder und ThemeData.

---

## Anforderungen

### 1. App-Setup mit Theme

- Verwende `MaterialApp` mit einem konsistenten `ThemeData`
- Definiere ein `ColorScheme` mit `ColorScheme.fromSeed`
- Konfiguriere `CardTheme`, `AppBarTheme` und `TextTheme`
- Unterstuetze Light- und Dark-Modus (`themeMode: ThemeMode.system`)

### 2. AppBar

- Titel: "Dashboard"
- Ein Such-Icon (`Icons.search`) als Action
- Optional: Drawer mit Navigations-Eintraegen

### 3. Statistik-Karten (oberer Bereich)

Erstelle eine Reihe von 3-4 Statistik-Karten in einer `Row`:

Jede Karte zeigt:
- Ein Icon
- Einen Titel (z.B. "Benutzer", "Umsatz", "Bestellungen", "Bewertung")
- Einen Wert (z.B. "1.234", "EUR 5.678", "89", "4.7")
- Optional: Trend-Indikator (Pfeil hoch/runter mit Prozent)

Anforderungen:
- Verwende `Expanded` fuer gleichmaessige Verteilung
- Jede Karte ist ein eigenes Widget (`StatistikKarte`)
- Cards mit `elevation` und abgerundeten Ecken
- Icons farblich hervorgehoben (z.B. in einem farbigen Kreis)

### 4. Letzte Aktivitaeten (ListView)

Unterhalb der Statistik-Karten:
- Ueberschrift "Letzte Aktivitaeten"
- Eine `ListView` (NICHT `ListView.builder`, da wenige statische Eintraege) oder alternativ eine `Column` in einem begrenzten Bereich
- Mindestens 5 Eintraege
- Jeder Eintrag zeigt: Icon, Titel, Beschreibung, Zeitstempel
- Verwende `ListTile` oder ein eigenes Layout
- Trennlinien zwischen den Eintraegen (Divider oder `ListView.separated`)

### 5. Kategorie-Kacheln (GridView)

Unterhalb der Aktivitaeten:
- Ueberschrift "Kategorien"
- Ein `GridView` mit 6-8 Kategorie-Kacheln
- Jede Kachel hat: Icon (gross), Name, Anzahl der Eintraege
- Farbige Hintergruende oder Icons
- Abgerundete Ecken

### 6. Responsive Layout (LayoutBuilder)

Das Layout soll sich an die Bildschirmbreite anpassen:

| Breite | Layout |
|--------|--------|
| < 600px (Mobil) | Statistik-Karten: 2x2 Grid, Kategorien: 2 Spalten |
| 600-900px (Tablet) | Statistik-Karten: 1 Row, Kategorien: 3 Spalten |
| > 900px (Desktop) | Statistik-Karten: 1 Row, Kategorien: 4 Spalten, Sidebar moeglich |

Verwende `LayoutBuilder` (nicht `MediaQuery`), damit das Layout auf den verfuegbaren Platz reagiert, nicht auf die Bildschirmgroesse.

### 7. Widget-Extraktion

Erstelle eigene Widgets fuer:

1. `DashboardApp` -- Root mit MaterialApp
2. `DashboardSeite` -- Scaffold mit AppBar
3. `StatistikKarte` -- Einzelne Statistik-Karte (Parameter: icon, titel, wert, farbe)
4. `StatistikBereich` -- Row/Grid der Statistik-Karten
5. `AktivitaetEintrag` -- Einzelner Listen-Eintrag
6. `KategorieKachel` -- Einzelne Grid-Kachel

---

## Bonus-Aufgaben (optional)

1. **Pull-to-Refresh:** Implementiere `RefreshIndicator` um die gesamte Seite
2. **Animierte Zahlen:** Lass die Statistik-Werte von 0 hochzaehlen beim ersten Anzeigen
3. **Bottom Sheet:** Tippen auf eine Kategorie-Kachel oeffnet ein `showModalBottomSheet`
4. **Drawer:** Implementiere einen Drawer mit Navigationspunkten
5. **Responsive Sidebar:** Auf breiten Screens (> 900px) zeige eine permanente Sidebar statt eines Drawers

---

## Erwartetes Ergebnis

### Mobil-Layout (< 600px)

```
┌──────────────────────────────┐
│         Dashboard            │
├──────────────────────────────┤
│  ┌──────────┐ ┌──────────┐  │
│  │ Benutzer │ │  Umsatz  │  │
│  │  1.234   │ │ EUR 5.678│  │
│  └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐  │
│  │Bestellung│ │ Bewertung│  │
│  │    89    │ │   4.7    │  │
│  └──────────┘ └──────────┘  │
│                              │
│  Letzte Aktivitaeten         │
│  ├─ Bestellung eingegangen  │
│  ├─ Neuer Benutzer          │
│  ├─ Zahlung erhalten        │
│  └─ ...                     │
│                              │
│  Kategorien                  │
│  ┌─────┐ ┌─────┐           │
│  │ Kat │ │ Kat │           │
│  └─────┘ └─────┘           │
│  ┌─────┐ ┌─────┐           │
│  │ Kat │ │ Kat │           │
│  └─────┘ └─────┘           │
└──────────────────────────────┘
```

### Tablet/Desktop-Layout (> 600px)

```
┌────────────────────────────────────────────────┐
│                  Dashboard                      │
├────────────────────────────────────────────────┤
│ ┌──────┐ ┌──────┐ ┌──────────┐ ┌──────────┐  │
│ │Nutzer│ │Umsatz│ │Bestellung│ │ Bewertung│  │
│ │1.234 │ │5.678 │ │    89    │ │   4.7    │  │
│ └──────┘ └──────┘ └──────────┘ └──────────┘  │
│                                                │
│ Letzte Aktivitaeten                            │
│ ├─ Bestellung eingegangen                     │
│ ├─ Neuer Benutzer registriert                 │
│ └─ ...                                        │
│                                                │
│ Kategorien                                     │
│ ┌────┐ ┌────┐ ┌────┐ (┌────┐)                │
│ │Kat │ │Kat │ │Kat │  │Kat │                 │
│ └────┘ └────┘ └────┘  └────┘                  │
│ ┌────┐ ┌────┐ ┌────┐ (┌────┐)                │
│ │Kat │ │Kat │ │Kat │  │Kat │                 │
│ └────┘ └────┘ └────┘  └────┘                  │
└────────────────────────────────────────────────┘
```

---

## Hinweise

- Die gesamte Seite muss scrollbar sein. Verwende einen `SingleChildScrollView` oder eine `CustomScrollView` mit Slivers.
- Ein `GridView` innerhalb eines `SingleChildScrollView` muss `shrinkWrap: true` und `physics: NeverScrollableScrollPhysics()` verwenden, um korrekt zu funktionieren.
- Denke an `const` ueberall wo moeglich.
- Teste dein Layout bei verschiedenen Fenstergroessen (im Browser oder Emulator das Fenster resizen).
