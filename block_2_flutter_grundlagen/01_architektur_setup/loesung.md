# Lösung 2.1: Flutter Architektur & Setup

---

## Aufgabe 2

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const LernApp());
}

class LernApp extends StatelessWidget {
  const LernApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LernApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ProfilSeite(),
    );
  }
}

class ProfilSeite extends StatelessWidget {
  const ProfilSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mein Profil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 100, color: Colors.teal),
            SizedBox(height: 16),
            Text(
              'Max Mustermann',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Flutter-Entwickler',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 3

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// In ProfilSeite:
Text(
  'Max Mustermann',
  style: GoogleFonts.robotoMono(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),
```

---

## Aufgabe 4: Widget-Tree

```
MaterialApp
└── Scaffold
    ├── AppBar
    │   ├── Text ("Test")
    │   └── IconButton
    │       └── Icon (settings)
    ├── Column
    │   ├── Image
    │   ├── Text ("Titel")
    │   └── Row
    │       ├── ElevatedButton
    │       │   └── Text ("OK")
    │       └── ElevatedButton
    │           └── Text ("Abbrechen")
    └── FloatingActionButton
        └── Icon (add)
```

---

## Bonusaufgabe

```dart
MaterialApp(
  debugShowCheckedModeBanner: false,  // Diese Zeile hinzufügen
  // ...
)
```
