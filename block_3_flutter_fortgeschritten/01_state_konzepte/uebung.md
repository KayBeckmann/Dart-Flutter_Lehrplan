# Übung 3.1: State Management Konzepte

## Ziel

Eine Einkaufslisten-App implementieren, die State Management Probleme demonstriert und mit "Lifting State Up" löst.

---

## Aufgabe 1: Prop Drilling Problem erkennen (20 min)

Analysiere folgende Widget-Struktur:

```
ShoppingApp
├── AppBar (zeigt Anzahl der Items)
├── ShoppingList
│   └── ShoppingItem (mehrere)
│       ├── ItemName
│       ├── ItemQuantity
│       └── DeleteButton
└── AddItemButton (fügt neues Item hinzu)
```

**Fragen:**
1. Wo sollte der State (Liste der Items) leben?
2. Welche Widgets brauchen Zugriff auf den State?
3. Welche Widgets brauchen nur Callbacks?
4. Durch welche Widgets müsste man Daten/Callbacks durchreichen?

---

## Aufgabe 2: Lifting State Up implementieren (40 min)

Erstelle eine einfache Einkaufslisten-App mit folgenden Features:

### Datenmodell

```dart
class ShoppingItem {
  final String id;
  final String name;
  final int quantity;
  final bool purchased;

  ShoppingItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.purchased = false,
  });

  // copyWith implementieren
}
```

### Anforderungen

1. **ShoppingApp (StatefulWidget)**
   - Hält die Liste aller `ShoppingItem`s
   - Stellt Methoden bereit: `addItem`, `togglePurchased`, `removeItem`, `updateQuantity`

2. **ShoppingAppBar (StatelessWidget)**
   - Zeigt: "Einkaufsliste (3 von 5 erledigt)"
   - Erhält die Item-Liste als Parameter

3. **ShoppingListView (StatelessWidget)**
   - Zeigt alle Items als Liste
   - Erhält Items und Callbacks als Parameter

4. **ShoppingItemTile (StatelessWidget)**
   - Zeigt Name und Menge
   - Checkbox für "purchased"
   - Buttons für +/- Menge
   - Delete-Button
   - Durchgestrichener Text wenn purchased

5. **AddItemDialog**
   - TextField für Name
   - Ruft `addItem` Callback auf

### Beispiel-UI

```
┌─────────────────────────────────┐
│ Einkaufsliste (2 von 4 erledigt)│
├─────────────────────────────────┤
│ ☑ Milch            [-] 2 [+] 🗑 │
│ ☑ Brot             [-] 1 [+] 🗑 │
│ ☐ Eier             [-] 6 [+] 🗑 │
│ ☐ Butter           [-] 1 [+] 🗑 │
├─────────────────────────────────┤
│           [+ Hinzufügen]        │
└─────────────────────────────────┘
```

---

## Aufgabe 3: InheritedWidget verstehen (Theorie)

Ohne Code zu schreiben, beantworte:

1. Was ist der Unterschied zwischen `dependOnInheritedWidgetOfExactType` und `getInheritedWidgetOfExactType`?

2. Was bewirkt `updateShouldNotify`? Wann gibt man `true` zurück, wann `false`?

3. Warum braucht man neben dem `InheritedWidget` auch ein `StatefulWidget`?

4. Was passiert, wenn ein Widget `InheritedWidget.of(context)` aufruft, aber kein passendes `InheritedWidget` im Tree existiert?

---

## Aufgabe 4: State-Kategorisierung

Kategorisiere folgenden State als "Ephemeral" oder "App State":

| State | Kategorie | Begründung |
|-------|-----------|------------|
| Aktueller Tab-Index in einer TabBar | | |
| Eingeloggter User | | |
| Scroll-Position in einer Liste | | |
| Dark/Light Mode Einstellung | | |
| Formular-Eingaben während der Eingabe | | |
| Warenkorb-Inhalt | | |
| Animation-Progress | | |
| Ausgewähltes Element in einer Liste | | |
| Offline-Cache von API-Daten | | |
| Ob ein Dropdown geöffnet ist | | |

---

## Bonus: ChangeNotifier vorbereiten

Refaktoriere den State aus Aufgabe 2 in einen `ChangeNotifier`:

```dart
class ShoppingListNotifier extends ChangeNotifier {
  final List<ShoppingItem> _items = [];

  // Implementiere:
  // - items getter (unmodifizierbare Liste)
  // - purchasedCount getter
  // - totalCount getter
  // - addItem(String name)
  // - togglePurchased(String id)
  // - updateQuantity(String id, int delta)
  // - removeItem(String id)
}
```

Dies bereitet auf die nächste Einheit (Provider Basics) vor.

---

## Abgabe-Checkliste

- [ ] Prop Drilling Analyse dokumentiert
- [ ] Einkaufslisten-App funktioniert
- [ ] State lebt im richtigen Widget
- [ ] Keine unnötigen StatefulWidgets
- [ ] Callbacks werden korrekt durchgereicht
- [ ] Theorie-Fragen beantwortet
- [ ] State-Kategorisierung ausgefüllt
