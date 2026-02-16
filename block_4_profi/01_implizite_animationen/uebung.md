# Übung 4.1: Implizite Animationen

## Ziel

Verschiedene implizite Animationen implementieren und kombinieren.

---

## Aufgabe 1: Animated Settings Toggle (20 min)

Erstelle einen animierten Settings-Schalter:

```
┌─────────────────────────────────────┐
│  🔔 Benachrichtigungen              │
│  ┌──────────┐                       │
│  │ ████░░░░ │  ← Slider animiert   │
│  └──────────┘                       │
│                                     │
│  Wenn aktiv:                        │
│  - Hintergrund wird grün            │
│  - Icon wird größer                 │
│  - Text wird fett                   │
└─────────────────────────────────────┘
```

Anforderungen:
- `AnimatedContainer` für Hintergrundfarbe
- `AnimatedDefaultTextStyle` für Text
- `AnimatedScale` oder `TweenAnimationBuilder` für Icon
- Sanfte Übergänge (300ms)

---

## Aufgabe 2: Expandable Card (25 min)

Erstelle eine erweiterbare Info-Karte:

```
Eingeklappt:
┌─────────────────────────────────────┐
│ 📦 Bestellung #12345            ▼  │
│ Status: Versendet                   │
└─────────────────────────────────────┘

Ausgeklappt:
┌─────────────────────────────────────┐
│ 📦 Bestellung #12345            ▲  │
│ Status: Versendet                   │
├─────────────────────────────────────┤
│ Artikel: Flutter Buch               │
│ Preis: 29,99€                       │
│ Lieferadresse: Musterstr. 1         │
│ Voraussichtlich: 15.03.2024         │
└─────────────────────────────────────┘
```

Anforderungen:
- Tap auf Karte zum Auf-/Zuklappen
- `AnimatedContainer` für Höhe
- `AnimatedRotation` für den Pfeil
- `AnimatedOpacity` für den Inhalt
- Details erscheinen smooth

---

## Aufgabe 3: AnimatedSwitcher Gallery (20 min)

Erstelle eine Bildergalerie mit verschiedenen Übergängen:

```
┌─────────────────────────────────────┐
│                                     │
│        ┌─────────────┐              │
│        │   Bild 1    │              │
│        └─────────────┘              │
│                                     │
│    [◄]              [►]            │
│                                     │
│   Übergang: [Fade ▼]                │
└─────────────────────────────────────┘
```

Übergänge implementieren:
- Fade (Standard)
- Scale
- Slide (links/rechts)
- Rotation

---

## Aufgabe 4: Progress Animation (20 min)

Erstelle einen animierten Fortschrittsanzeiger:

```
┌─────────────────────────────────────┐
│                                     │
│         Upload läuft...             │
│                                     │
│    ┌────────────────────────┐       │
│    │████████████░░░░░░░░░░░░│       │
│    └────────────────────────┘       │
│              67%                    │
│                                     │
│    [Simulieren]                     │
└─────────────────────────────────────┘
```

Anforderungen:
- `TweenAnimationBuilder` für den Fortschritt
- Animierte Prozentanzeige
- Farbwechsel: rot → gelb → grün
- Bei 100%: Erfolgsmeldung mit Animation

---

## Aufgabe 5: AnimatedList Todo (25 min)

Erstelle eine Todo-Liste mit animierten Einträgen:

```
┌─────────────────────────────────────┐
│ Meine Todos                    [+]  │
├─────────────────────────────────────┤
│ ☐ Flutter lernen              [🗑] │  ← Slide in
│ ☑ Dart verstanden             [🗑] │  ← durchgestrichen
│ ☐ App veröffentlichen         [🗑] │
└─────────────────────────────────────┘
```

Anforderungen:
- `AnimatedList` für Add/Remove
- Neue Items sliden von rechts rein
- Gelöschte Items faden und schrumpfen
- Checkbox-Animation beim Abhaken
- Durchstreich-Animation für erledigte Items

---

## Aufgabe 6: Animated Navigation Bar (20 min)

Erstelle eine animierte Bottom Navigation:

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│           [Content]                 │
│                                     │
│                                     │
├─────────────────────────────────────┤
│   🏠      🔍      ❤️      👤       │
│  Home   Search  Favs   Profile      │
│   ●                                 │
└─────────────────────────────────────┘
```

Anforderungen:
- Aktives Icon wird größer
- Indikator (Punkt) bewegt sich animiert
- Label erscheint nur bei aktivem Item
- Sanfte Farbübergänge

---

## Aufgabe 7: Komplette Animated Page (30 min)

Erstelle eine Landing Page mit Stagger-Animationen:

```
┌─────────────────────────────────────┐
│                                     │
│      ┌─────────┐                    │  ← Logo faded ein
│      │  LOGO   │                    │
│      └─────────┘                    │
│                                     │
│      Willkommen!                    │  ← Titel slided
│                                     │
│      Entdecke unsere App            │  ← Subtitle faded
│                                     │
│      ┌───────────────────┐          │
│      │    Los geht's     │          │  ← Button scaled
│      └───────────────────┘          │
│                                     │
└─────────────────────────────────────┘
```

Anforderungen:
- Elemente erscheinen nacheinander (staggered)
- Verschiedene Animationstypen
- Alle mit `TweenAnimationBuilder`
- Verzögerung zwischen Elementen: 200ms
- Gesamtdauer: ~1 Sekunde

---

## Bonus: Animated Theme Switcher

Erstelle einen Theme-Wechsel mit Animation:

```dart
// Anforderung:
// - Dark/Light Mode Toggle
// - Sanfter Farbübergang für gesamte App
// - Icon-Animation (Sonne ↔ Mond)
// - Optional: Ripple-Effekt vom Toggle-Button
```

---

## Abgabe-Checkliste

- [ ] Settings Toggle mit mehreren Animationen
- [ ] Expandable Card funktioniert smooth
- [ ] AnimatedSwitcher mit 4 Übergängen
- [ ] Progress Animation mit Farbwechsel
- [ ] AnimatedList mit Add/Remove
- [ ] Animated Navigation Bar
- [ ] Staggered Landing Page
- [ ] Code ist sauber und kommentiert
