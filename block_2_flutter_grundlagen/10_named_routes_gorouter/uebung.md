# Übung 2.10: Named Routes & go_router

---

## Aufgabe 1: Named Routes Setup (15 Min.)

Erstelle eine App mit Named Routes:

```dart
// Routes:
// '/' -> HomePage
// '/about' -> AboutPage
// '/contact' -> ContactPage

// Navigation zwischen den Seiten
```

---

## Aufgabe 2: go_router mit Parametern (25 Min.)

Erstelle einen Blog mit go_router:

```dart
// Routes:
// '/' -> Liste aller Posts
// '/post/:id' -> Einzelner Post
// '/category/:name' -> Posts einer Kategorie
// '/search?q=...' -> Suche mit Query
```

---

## Aufgabe 3: ShellRoute mit Navigation (15 Min.)

Erstelle eine App mit BottomNavigationBar:

```
┌─────────────────────────┐
│                         │
│     [Page Content]      │
│                         │
├─────────────────────────┤
│  Home | Shop | Account  │
└─────────────────────────┘

// Jeder Tab hat eigene Sub-Routes
// Home: /
// Shop: /shop, /shop/product/:id
// Account: /account, /account/settings
```

---

## Bonusaufgabe: Auth Guard

Implementiere einen Login-Redirect:
- Geschützte Routen leiten zu /login um
- Nach Login zurück zur ursprünglichen Route

