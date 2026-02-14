# Modul 9: Uebung -- Einkaufslisten-App mit Provider

## Aufgabenstellung

Baue eine **Einkaufslisten-App**, die das `provider` Package fuer State Management nutzt. Die App soll mehrere Provider, verschiedene Zugriffsmethoden und eine saubere Architektur demonstrieren.

---

## Anforderungen

### 1. Datenmodell

Erstelle eine `ShoppingItem`-Klasse mit folgenden Feldern:
- `id` (String) -- Eindeutige ID
- `name` (String) -- Name des Artikels
- `quantity` (int) -- Menge (Standard: 1)
- `isBought` (bool) -- Ob der Artikel bereits gekauft wurde
- `category` (String) -- Kategorie (z.B. "Obst", "Getraenke", "Haushalt")

### 2. ShoppingListProvider (ChangeNotifier)

Erstelle einen `ShoppingListProvider` mit folgender Funktionalitaet:
- **Artikel hinzufuegen** (`addItem`) -- mit Name, Menge und Kategorie
- **Artikel entfernen** (`removeItem`) -- anhand der ID
- **Als gekauft markieren / Markierung aufheben** (`toggleBought`) -- Toggle
- **Menge aendern** (`updateQuantity`)
- **Alle gekauften Artikel entfernen** (`clearBought`)
- **Getter:** `items`, `boughtItems`, `unboughtItems`, `itemsByCategory`

### 3. StatsProvider (ChangeNotifier)

Erstelle einen separaten `StatsProvider`, der Statistiken berechnet:
- Gesamtanzahl aller Artikel
- Anzahl gekaufter Artikel
- Anzahl offener Artikel
- Prozentualer Fortschritt (gekauft / gesamt)
- Anzahl verschiedener Kategorien

**Hinweis:** Verwende `ChangeNotifierProxyProvider`, damit der StatsProvider auf den ShoppingListProvider reagiert.

### 4. MultiProvider Setup

Richte in `main.dart` einen `MultiProvider` ein mit:
- `ShoppingListProvider`
- `StatsProvider` (abhaengig von ShoppingListProvider)

### 5. Screens

Erstelle drei Screens:

#### a) Einkaufsliste (Hauptscreen)
- Zeige alle Artikel gruppiert nach Kategorie an
- Jeder Artikel hat:
  - Checkbox zum Abhaken (toggleBought)
  - Name und Menge
  - Wischgeste (Dismissible) zum Loeschen
- Gekaufte Artikel sollen durchgestrichen dargestellt werden
- FloatingActionButton zum Hinzufuegen

#### b) Artikel hinzufuegen (Dialog oder Screen)
- Textfeld fuer den Artikelnamen
- Dropdown fuer die Kategorie
- Zaehler fuer die Menge (+/- Buttons)
- Speichern-Button

#### c) Statistik-Screen
- Zeige die Statistiken aus dem StatsProvider an
- Nutze `Selector` oder `context.select()`, damit sich nur die relevanten Teile aktualisieren
- Zeige einen Fortschrittsbalken (LinearProgressIndicator) fuer den Einkaufsfortschritt

### 6. Technische Anforderungen

- Verwende `Consumer<T>` mindestens einmal
- Verwende `context.watch<T>()` mindestens einmal
- Verwende `context.read<T>()` fuer alle Button-Callbacks
- Verwende `Selector<T, S>` mindestens einmal fuer eine Performance-Optimierung
- Verwende den `child`-Parameter von Consumer mindestens einmal

---

## Projektstruktur

```
lib/
├── main.dart
├── models/
│   └── shopping_item.dart
├── providers/
│   ├── shopping_list_provider.dart
│   └── stats_provider.dart
├── screens/
│   ├── shopping_list_screen.dart
│   ├── add_item_screen.dart
│   └── stats_screen.dart
└── widgets/
    └── shopping_item_tile.dart
```

---

## Bonusaufgaben

1. **Sortierung:** Ermoegliche das Sortieren der Liste (alphabetisch, nach Kategorie, gekaufte ans Ende)
2. **Suche:** Fuege eine Suchleiste hinzu, die die Liste filtert
3. **Undo:** Wenn ein Artikel geloescht wird, zeige eine SnackBar mit "Rueckgaengig"-Button
4. **Persistenz-Vorbereitung:** Strukturiere den Provider so, dass er spaeter leicht mit lokaler Speicherung (Modul 11) erweitert werden kann

---

## Hinweise

- Starte mit dem Datenmodell und dem ShoppingListProvider
- Teste den Provider zuerst mit einfachen Testdaten, bevor du die UI baust
- Verwende `List.unmodifiable()` in den Gettern, damit niemand die interne Liste direkt veraendert
- Denke an `notifyListeners()` nach jeder State-Aenderung
- Fuer die Kategorien kannst du eine feste Liste verwenden: `['Obst & Gemuese', 'Getraenke', 'Milchprodukte', 'Fleisch & Fisch', 'Haushalt', 'Sonstiges']`

---

## Erwartetes Verhalten

1. App startet mit leerer Einkaufsliste
2. Benutzer fuegt Artikel hinzu (Name, Kategorie, Menge)
3. Artikel erscheinen in der Liste, gruppiert nach Kategorie
4. Benutzer kann Artikel abhaken (Checkbox)
5. Abgehakte Artikel werden durchgestrichen dargestellt
6. Statistik-Screen zeigt aktuelle Zahlen und Fortschritt
7. Artikel koennen durch Wischen geloescht werden
8. "Alle gekauften entfernen"-Button raumt die Liste auf
