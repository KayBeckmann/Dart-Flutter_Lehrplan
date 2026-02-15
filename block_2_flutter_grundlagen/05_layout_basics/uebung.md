# Übung 2.5: Layout Basics

---

## Aufgabe 1: Social Media Post (20 Min.)

Erstelle einen Social-Media-Post:

```
┌─────────────────────────────┐
│ [Avatar] Username    [···]  │  <- Row
│                             │
│ [  Großes Bild hier  ]      │  <- Image
│                             │
│ ♡ ♡ ↗ ☐                    │  <- Row mit Icons
│ 1.234 Likes                 │
│ Beschreibungstext hier...   │
└─────────────────────────────┘
```

---

## Aufgabe 2: App-Drawer (20 Min.)

Erstelle einen Navigations-Drawer:

```
┌─────────────────────────────┐
│ ┌────────────────────────┐  │
│ │   Header mit Bild      │  │ <- Stack
│ │   Name & Email         │  │
│ └────────────────────────┘  │
├─────────────────────────────┤
│ 🏠 Home                     │  <- ListTile
│ 👤 Profil                   │
│ ⚙️ Einstellungen            │
│ ─────────────────────────   │  <- Divider
│ 🚪 Logout                   │
└─────────────────────────────┘
```

---

## Aufgabe 3: Badge auf Icon (15 Min.)

Erstelle ein Icon mit Benachrichtigungs-Badge:

```dart
BadgeIcon(
  icon: Icons.notifications,
  count: 5,
)
// Zeigt das Icon mit rotem Kreis (Zahl) oben rechts
```

---

## Bonusaufgabe: Responsive Grid

Erstelle ein Grid das sich an die Bildschirmbreite anpasst.
