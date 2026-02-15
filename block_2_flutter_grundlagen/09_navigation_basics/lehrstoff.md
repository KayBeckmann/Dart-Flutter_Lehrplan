# Einheit 2.9: Navigation Basics

> **Dauer:** 2 Stunden | **Voraussetzungen:** Einheit 2.8

---

## 9.1 Navigator.push & pop

```dart
// Zu neuer Seite navigieren
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => DetailPage()),
);

// Zurück zur vorherigen Seite
Navigator.pop(context);

// Mit Kurzform
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => DetailPage()),
);
```

---

## 9.2 Daten übergeben

```dart
// Daten an neue Seite übergeben
class DetailPage extends StatelessWidget {
  final String titel;
  final int id;

  const DetailPage({required this.titel, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titel)),
      body: Center(child: Text('ID: $id')),
    );
  }
}

// Navigation mit Daten
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailPage(titel: 'Produkt', id: 42),
  ),
);
```

---

## 9.3 Daten zurückgeben

```dart
// Seite die Daten zurückgibt
class SelectionPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Auswahl')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Option A'),
            onTap: () => Navigator.pop(context, 'A'),
          ),
          ListTile(
            title: Text('Option B'),
            onTap: () => Navigator.pop(context, 'B'),
          ),
        ],
      ),
    );
  }
}

// Auf Ergebnis warten
void _selectOption() async {
  final result = await Navigator.push<String>(
    context,
    MaterialPageRoute(builder: (context) => SelectionPage()),
  );

  if (result != null) {
    print('Ausgewählt: $result');
  }
}
```

---

## 9.4 pushReplacement & pushAndRemoveUntil

```dart
// Aktuelle Seite ersetzen (kein Zurück möglich)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => HomePage()),
);

// Alle Seiten entfernen und neue hinzufügen
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => LoginPage()),
  (route) => false,  // Entfernt alle vorherigen Routes
);

// Bis zu bestimmter Route entfernen
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => HomePage()),
  ModalRoute.withName('/'),  // Behält Root-Route
);
```

---

## 9.5 WillPopScope / PopScope

```dart
// Zurück-Navigation abfangen (Flutter 3.16+)
PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) {
    if (didPop) return;
    _showExitDialog();
  },
  child: Scaffold(...),
)

// Ältere Version (deprecated)
WillPopScope(
  onWillPop: () async {
    final shouldPop = await _showExitDialog();
    return shouldPop ?? false;
  },
  child: Scaffold(...),
)

Future<bool?> _showExitDialog() {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Beenden?'),
      content: Text('Möchtest du wirklich zurück?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Nein'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Ja'),
        ),
      ],
    ),
  );
}
```

---

## 9.6 Page Transitions

```dart
// Custom PageRoute
class FadeRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  FadeRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 300),
        );
}

// Verwendung
Navigator.push(context, FadeRoute(page: DetailPage()));

// Slide Transition
class SlideRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SlideRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final tween = Tween(
              begin: Offset(1.0, 0.0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeInOut));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}
```

---

## 9.7 BottomNavigationBar

```dart
class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _pages = [
    HomePage(),
    SearchPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Suche',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
```

---

## 9.8 Drawer Navigation

```dart
Scaffold(
  appBar: AppBar(title: Text('App')),
  drawer: Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CircleAvatar(radius: 30, child: Icon(Icons.person)),
              SizedBox(height: 8),
              Text('Benutzer Name', style: TextStyle(
                color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
        ListTile(
          leading: Icon(Icons.home),
          title: Text('Home'),
          onTap: () {
            Navigator.pop(context);  // Drawer schließen
            // Navigation...
          },
        ),
        ListTile(
          leading: Icon(Icons.settings),
          title: Text('Einstellungen'),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => SettingsPage()));
          },
        ),
        Divider(),
        ListTile(
          leading: Icon(Icons.logout),
          title: Text('Abmelden'),
          onTap: () => _logout(),
        ),
      ],
    ),
  ),
  body: HomePage(),
)
```

---

## 9.9 TabBar Navigation

```dart
class TabExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tabs'),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: 'Home'),
              Tab(icon: Icon(Icons.star), text: 'Favoriten'),
              Tab(icon: Icon(Icons.person), text: 'Profil'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Center(child: Text('Home Tab')),
            Center(child: Text('Favoriten Tab')),
            Center(child: Text('Profil Tab')),
          ],
        ),
      ),
    );
  }
}
```

