# Übung 4.2: Explizite Animationen

## Ziel

AnimationController beherrschen und komplexe Animationen erstellen.

---

## Aufgabe 1: Pulsing Button (20 min)

Erstelle einen Button mit Pulsier-Animation:

```
┌─────────────────────────────────────┐
│                                     │
│         ╭─────────────╮             │
│         │   Pulse!    │  ← pulsiert │
│         ╰─────────────╯             │
│                                     │
│   [Start]  [Stop]  [Reset]          │
└─────────────────────────────────────┘
```

Anforderungen:
- Button pulsiert kontinuierlich (scale 1.0 → 1.2 → 1.0)
- Zusätzlich: Schatten pulsiert mit
- Steuerung über Start/Stop/Reset Buttons
- `repeat(reverse: true)` verwenden

---

## Aufgabe 2: Loading Spinner (25 min)

Erstelle einen custom Loading-Spinner:

```
┌─────────────────────────────────────┐
│                                     │
│            ◠ ◡ ◠                    │
│          ◡       ◡                  │
│          ◠       ◠   ← 3 Dots      │
│            ◡ ◠ ◡                    │
│                                     │
│         Loading...                  │
└─────────────────────────────────────┘
```

Anforderungen:
- 3 Kreise die nacheinander hüpfen (staggered)
- Jeder Kreis bewegt sich vertikal
- Verschiedene Delays (0ms, 200ms, 400ms)
- Smooth loop

---

## Aufgabe 3: Flip Card (25 min)

Erstelle eine Karte die sich umdreht:

```
Vorderseite:           Rückseite (nach Flip):
┌─────────────┐        ┌─────────────┐
│             │        │             │
│     🃏      │   →    │   Antwort   │
│  Frage...   │        │   Text...   │
│             │        │             │
└─────────────┘        └─────────────┘
```

Anforderungen:
- 3D-Flip Animation (um Y-Achse)
- Vorderseite zeigt Frage
- Rückseite zeigt Antwort
- Bei 90° Inhalt wechseln
- Tap zum Umdrehen

---

## Aufgabe 4: Staggered List (20 min)

Erstelle eine Liste mit gestaffelter Einblend-Animation:

```
┌─────────────────────────────────────┐
│ Notifications                       │
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │  ← Slide in 0ms
│ │ 📧 Neue Nachricht             │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │  ← Slide in 100ms
│ │ 🔔 Erinnerung                 │   │
│ └───────────────────────────────┘   │
│ ┌───────────────────────────────┐   │  ← Slide in 200ms
│ │ 📦 Paket versendet            │   │
│ └───────────────────────────────┘   │
└─────────────────────────────────────┘
```

Anforderungen:
- Items sliden von rechts rein
- Gestaffelt mit 100ms Verzögerung
- Fade + Slide kombiniert
- Button zum "Replay"

---

## Aufgabe 5: Hero Gallery (25 min)

Erstelle eine Bildergalerie mit Hero-Animationen:

```
Grid-Ansicht:              Detail-Ansicht:
┌───┬───┬───┐              ┌─────────────────┐
│ 1 │ 2 │ 3 │              │                 │
├───┼───┼───┤    tap →     │    Bild 1       │
│ 4 │ 5 │ 6 │              │   (fullscreen)  │
├───┼───┼───┤              │                 │
│ 7 │ 8 │ 9 │              │  Beschreibung   │
└───┴───┴───┘              └─────────────────┘
```

Anforderungen:
- GridView mit Vorschaubildern
- Tap öffnet Detail-Screen
- Hero-Animation für das Bild
- Zurück mit Back-Button/Gesture

---

## Aufgabe 6: Animated Counter (20 min)

Erstelle einen Counter mit rollenden Zahlen:

```
┌─────────────────────────────────────┐
│                                     │
│           ┌─────────┐               │
│           │  0042   │  ← Zahlen    │
│           └─────────┘    rollen    │
│                                     │
│       [-]           [+]             │
└─────────────────────────────────────┘
```

Anforderungen:
- Zahlen "rollen" wie bei einem Zähler
- Jede Ziffer animiert einzeln
- Slide-Transition nach oben/unten
- Min: 0, Max: 9999

---

## Aufgabe 7: Lottie Integration (20 min)

Integriere Lottie-Animationen:

```
┌─────────────────────────────────────┐
│                                     │
│         [Lottie Animation]          │
│                                     │
│   ▶️ Play   ⏸️ Pause   🔄 Loop      │
│                                     │
│   Progress: ═══════════░░░ 70%     │
│                                     │
│   Speed: [0.5x] [1x] [2x]          │
└─────────────────────────────────────┘
```

Anforderungen:
- Lottie-Animation von LottieFiles laden
- Play/Pause/Reset Controls
- Progress-Anzeige
- Geschwindigkeit änderbar
- Loop toggle

---

## Aufgabe 8: Animated Menu (30 min)

Erstelle ein animiertes Radial-Menu:

```
Geschlossen:              Geöffnet:
                                    📷
                          📁              🔗
     [+]           →           [×]
                          ✏️              💾
                                    📤
```

Anforderungen:
- FAB öffnet/schließt Menu
- Items fliegen radial nach außen
- Staggered Animation
- Rotation des Haupt-Buttons (+ → ×)
- Tap auf Item führt Aktion aus

---

## Bonus: Page Transition

Erstelle eine Custom Page Transition:

```dart
// Ziel: Eigene Übergangsanimation zwischen Screens
// - Slide von unten + Fade
// - Scale-Effekt
// - Alte Page faded/scaled out
```

```
Screen 1                 Transition              Screen 2
┌─────────┐             ┌─────────┐             ┌─────────┐
│         │             │ ▲▲▲▲▲▲▲ │             │         │
│  Page   │     →       │ Screen 2│      →      │  Page   │
│    1    │             │ ▲▲▲▲▲▲▲ │             │    2    │
│         │             │         │             │         │
└─────────┘             └─────────┘             └─────────┘
```

---

## Abgabe-Checkliste

- [ ] Pulsing Button mit Controller
- [ ] Custom Loading Spinner (staggered)
- [ ] 3D Flip Card Animation
- [ ] Staggered List mit Interval
- [ ] Hero Gallery funktioniert
- [ ] Animated Counter mit rollenden Ziffern
- [ ] Lottie mit Controls
- [ ] Animated Radial Menu
- [ ] Alle Controller werden disposed
- [ ] Code ist sauber strukturiert
