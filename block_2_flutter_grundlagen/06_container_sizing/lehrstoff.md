# Einheit 2.6: Container, Sizing & Spacing

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.5

---

## 6.1 Container

```dart
Container(
  width: 200,
  height: 100,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  alignment: Alignment.center,
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black, width: 2),
    boxShadow: [
      BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
    ],
  ),
  child: Text('Inhalt'),
)
```

---

## 6.2 SizedBox

```dart
// Feste Größe
SizedBox(
  width: 100,
  height: 50,
  child: ElevatedButton(...),
)

// Als Spacer
Column(children: [
  Text('Oben'),
  SizedBox(height: 20),  // Abstand
  Text('Unten'),
])

// Volle Breite
SizedBox(
  width: double.infinity,
  child: ElevatedButton(...),
)
```

---

## 6.3 Expanded & Flexible

```dart
Row(children: [
  Container(width: 50, color: Colors.red),
  Expanded(  // Füllt restlichen Platz
    child: Container(color: Colors.green),
  ),
  Container(width: 50, color: Colors.blue),
])

Row(children: [
  Expanded(flex: 2, child: Container(color: Colors.red)),   // 2/3
  Expanded(flex: 1, child: Container(color: Colors.blue)),  // 1/3
])

// Flexible — wie Expanded, aber kann kleiner sein
Row(children: [
  Flexible(
    fit: FlexFit.loose,  // Kann kleiner sein als verfügbar
    child: Text('Langer Text der abgeschnitten werden kann'),
  ),
])
```

---

## 6.4 Padding

```dart
Padding(
  padding: EdgeInsets.all(16),
  child: Text('Mit Padding'),
)

// EdgeInsets Varianten
EdgeInsets.all(16)                    // Alle Seiten gleich
EdgeInsets.symmetric(horizontal: 20, vertical: 10)
EdgeInsets.only(left: 10, top: 5)
EdgeInsets.fromLTRB(10, 20, 10, 20)  // Left, Top, Right, Bottom
```

---

## 6.5 Center & Align

```dart
Center(child: Text('Zentriert'))

Align(
  alignment: Alignment.topRight,
  child: Text('Oben rechts'),
)

// Alignment Werte
Alignment.topLeft      Alignment.topCenter      Alignment.topRight
Alignment.centerLeft   Alignment.center         Alignment.centerRight
Alignment.bottomLeft   Alignment.bottomCenter   Alignment.bottomRight
```

---

## 6.6 ConstrainedBox & FractionallySizedBox

```dart
// Einschränkungen
ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: 100,
    maxWidth: 300,
    minHeight: 50,
    maxHeight: 200,
  ),
  child: Container(color: Colors.blue),
)

// Prozentuale Größe
FractionallySizedBox(
  widthFactor: 0.8,   // 80% der Breite
  heightFactor: 0.5,  // 50% der Höhe
  child: Container(color: Colors.red),
)
```

---

## 6.7 AspectRatio

```dart
AspectRatio(
  aspectRatio: 16 / 9,  // Breite / Höhe
  child: Container(color: Colors.blue),
)
```

---

## 6.8 Spacer

```dart
Row(children: [
  Text('Links'),
  Spacer(),  // Füllt den Platz dazwischen
  Text('Rechts'),
])

Row(children: [
  Text('1'),
  Spacer(flex: 1),
  Text('2'),
  Spacer(flex: 2),  // Doppelt so viel Platz
  Text('3'),
])
```

---

## 6.9 IntrinsicWidth & IntrinsicHeight

```dart
// Alle Kinder gleich breit wie das breiteste
IntrinsicWidth(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ElevatedButton(onPressed: () {}, child: Text('Kurz')),
      ElevatedButton(onPressed: () {}, child: Text('Mittellanger Text')),
      ElevatedButton(onPressed: () {}, child: Text('OK')),
    ],
  ),
)
```

---

## 6.10 Beispiel: Login-Formular Layout

```dart
class LoginLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              Spacer(flex: 2),
              Icon(Icons.lock, size: 80, color: Colors.blue),
              SizedBox(height: 48),
              TextField(decoration: InputDecoration(labelText: 'Email')),
              SizedBox(height: 16),
              TextField(decoration: InputDecoration(labelText: 'Passwort')),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text('Anmelden'),
                ),
              ),
              Spacer(flex: 3),
              TextButton(onPressed: () {}, child: Text('Registrieren')),
            ],
          ),
        ),
      ),
    );
  }
}
```
