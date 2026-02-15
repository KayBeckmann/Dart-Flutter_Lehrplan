# Einheit 2.2: StatelessWidget & Basis-Widgets

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.1

---

## 2.1 StatelessWidget

Ein StatelessWidget ist **unveränderlich** — es hat keinen internen State:

```dart
class Begrüßung extends StatelessWidget {
  final String name;

  const Begrüßung({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text('Hallo, $name!');
  }
}

// Verwendung:
Begrüßung(name: 'Max')
```

---

## 2.2 BuildContext

`BuildContext` gibt Zugriff auf Position im Widget-Tree und Theme:

```dart
@override
Widget build(BuildContext context) {
  // Theme-Daten holen
  var theme = Theme.of(context);
  var screenSize = MediaQuery.of(context).size;

  return Text(
    'Bildschirmbreite: ${screenSize.width}',
    style: theme.textTheme.headlineMedium,
  );
}
```

---

## 2.3 Text Widget

```dart
Text('Einfacher Text')

Text(
  'Formatierter Text',
  style: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
    letterSpacing: 2,
  ),
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)

// Rich Text
Text.rich(
  TextSpan(
    text: 'Normal ',
    children: [
      TextSpan(
        text: 'Fett',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      TextSpan(text: ' und wieder normal'),
    ],
  ),
)
```

---

## 2.4 Icon Widget

```dart
Icon(Icons.favorite)

Icon(
  Icons.star,
  size: 48,
  color: Colors.amber,
)

// Mit Semantik für Accessibility
Icon(
  Icons.home,
  semanticLabel: 'Startseite',
)
```

---

## 2.5 Image Widget

```dart
// Aus dem Netzwerk
Image.network(
  'https://picsum.photos/200',
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, progress) {
    if (progress == null) return child;
    return CircularProgressIndicator();
  },
)

// Aus Assets (pubspec.yaml konfigurieren!)
Image.asset('assets/images/logo.png')

// Aus Datei
Image.file(File('/path/to/image.png'))
```

---

## 2.6 Button Widgets

```dart
// ElevatedButton — hervorgehoben
ElevatedButton(
  onPressed: () => print('Gedrückt!'),
  child: Text('Klick mich'),
)

// TextButton — flach
TextButton(
  onPressed: () {},
  child: Text('Text Button'),
)

// OutlinedButton — mit Rahmen
OutlinedButton(
  onPressed: () {},
  child: Text('Outlined'),
)

// IconButton
IconButton(
  icon: Icon(Icons.favorite),
  onPressed: () {},
)

// FloatingActionButton
FloatingActionButton(
  onPressed: () {},
  child: Icon(Icons.add),
)

// Mit Icon
ElevatedButton.icon(
  onPressed: () {},
  icon: Icon(Icons.send),
  label: Text('Senden'),
)
```

---

## 2.7 Container Widget

```dart
Container(
  width: 200,
  height: 100,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    color: Colors.blue,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Text('Container-Inhalt'),
)
```

---

## 2.8 Card Widget

```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Titel', style: TextStyle(fontSize: 20)),
        SizedBox(height: 8),
        Text('Beschreibung hier...'),
      ],
    ),
  ),
)
```

---

## 2.9 Scaffold & AppBar

```dart
Scaffold(
  appBar: AppBar(
    title: Text('Meine App'),
    leading: IconButton(
      icon: Icon(Icons.menu),
      onPressed: () {},
    ),
    actions: [
      IconButton(icon: Icon(Icons.search), onPressed: () {}),
      IconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
    ],
  ),
  body: Center(child: Text('Inhalt')),
  floatingActionButton: FloatingActionButton(
    onPressed: () {},
    child: Icon(Icons.add),
  ),
  bottomNavigationBar: BottomNavigationBar(
    items: [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Start'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
    ],
  ),
)
```

---

## 2.10 Beispiel: Profilkarte

```dart
class ProfilKarte extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarUrl;

  const ProfilKarte({
    super.key,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null ? Icon(Icons.person) : null,
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                )),
                Text(email, style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```
