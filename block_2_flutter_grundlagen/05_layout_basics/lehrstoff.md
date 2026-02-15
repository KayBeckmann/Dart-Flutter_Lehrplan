# Einheit 2.5: Layout Basics — Row, Column, Stack

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.4

---

## 5.1 Row — Horizontales Layout

```dart
Row(
  mainAxisAlignment: MainAxisAlignment.center,  // Horizontal
  crossAxisAlignment: CrossAxisAlignment.start, // Vertikal
  children: [
    Icon(Icons.star),
    Text('Titel'),
    Icon(Icons.star),
  ],
)
```

### MainAxisAlignment (Horizontal bei Row)
- `start` — Links
- `end` — Rechts
- `center` — Zentriert
- `spaceBetween` — Gleichmäßig, ohne Rand
- `spaceAround` — Gleichmäßig, halber Rand
- `spaceEvenly` — Gleichmäßig, gleicher Abstand

---

## 5.2 Column — Vertikales Layout

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.start,   // Vertikal
  crossAxisAlignment: CrossAxisAlignment.center, // Horizontal
  children: [
    Text('Zeile 1'),
    Text('Zeile 2'),
    Text('Zeile 3'),
  ],
)
```

---

## 5.3 MainAxisSize

```dart
Column(
  mainAxisSize: MainAxisSize.min,  // Nur so groß wie nötig
  // mainAxisSize: MainAxisSize.max,  // Füllt verfügbaren Platz
  children: [...],
)
```

---

## 5.4 Stack — Überlappende Widgets

```dart
Stack(
  children: [
    Image.network('background.jpg'),
    Positioned(
      bottom: 16,
      left: 16,
      child: Text('Überschrift'),
    ),
    Positioned(
      top: 8,
      right: 8,
      child: Icon(Icons.favorite, color: Colors.red),
    ),
  ],
)
```

### Positioned
```dart
Positioned(
  top: 10,      // Abstand von oben
  left: 10,     // Abstand von links
  right: 10,    // Abstand von rechts
  bottom: 10,   // Abstand von unten
  child: Widget(),
)

Positioned.fill(  // Füllt den gesamten Stack
  child: Widget(),
)
```

---

## 5.5 Stack Alignment

```dart
Stack(
  alignment: Alignment.center,  // Standard-Ausrichtung für nicht-positioned
  children: [
    Container(width: 200, height: 200, color: Colors.blue),
    Container(width: 100, height: 100, color: Colors.red),  // Zentriert
  ],
)
```

---

## 5.6 Nested Layouts

```dart
Column(
  children: [
    Text('Header'),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(children: [Icon(Icons.home), Text('Home')]),
        Column(children: [Icon(Icons.search), Text('Suche')]),
        Column(children: [Icon(Icons.person), Text('Profil')]),
      ],
    ),
    Text('Footer'),
  ],
)
```

---

## 5.7 Beispiel: Profilkarte

```dart
class ProfilKarte extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Stack(
        children: [
          // Hintergrundbild
          Positioned.fill(
            child: Image.network('banner.jpg', fit: BoxFit.cover),
          ),
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(radius: 30, child: Icon(Icons.person)),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Max Mustermann',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text('Entwickler',
                      style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```
