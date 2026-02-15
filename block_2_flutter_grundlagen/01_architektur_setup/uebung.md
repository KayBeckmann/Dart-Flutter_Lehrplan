# Übung 2.1: Flutter Architektur & Setup

---

## Aufgabe 1: Projekt erstellen (10 Min.)

1. Erstelle ein neues Flutter-Projekt namens `lernapp`
2. Starte die App im Browser oder Emulator
3. Ändere den Text "You have pushed..." zu "Willkommen bei Flutter!"
4. Nutze Hot Reload um die Änderung zu sehen

---

## Aufgabe 2: App umbauen (20 Min.)

Ersetze den Inhalt von `lib/main.dart`:

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const LernApp());
}

class LernApp extends StatelessWidget {
  const LernApp({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implementiere MaterialApp mit:
    // - title: 'LernApp'
    // - theme mit colorScheme (Farbe deiner Wahl)
    // - home: ProfilSeite()
  }
}

class ProfilSeite extends StatelessWidget {
  const ProfilSeite({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implementiere Scaffold mit:
    // - AppBar mit Titel "Mein Profil"
    // - body: Column mit:
    //   - Icon (Icons.person, size: 100)
    //   - Text mit deinem Namen
    //   - Text mit "Flutter-Entwickler"
  }
}
```

---

## Aufgabe 3: Package hinzufügen (15 Min.)

1. Füge das Package `google_fonts` hinzu
2. Ändere die Schriftart des Namens zu "Roboto Mono"
3. Teste mit Hot Reload

```dart
// Hint:
import 'package:google_fonts/google_fonts.dart';

Text(
  'Mein Name',
  style: GoogleFonts.robotoMono(fontSize: 24),
)
```

---

## Aufgabe 4: Widget-Tree zeichnen (10 Min.)

Zeichne den Widget-Tree für folgende Struktur:

```dart
MaterialApp(
  home: Scaffold(
    appBar: AppBar(
      title: Text('Test'),
      actions: [
        IconButton(icon: Icon(Icons.settings), onPressed: () {}),
      ],
    ),
    body: Column(
      children: [
        Image.network('...'),
        Text('Titel'),
        Row(
          children: [
            ElevatedButton(child: Text('OK'), onPressed: () {}),
            ElevatedButton(child: Text('Abbrechen'), onPressed: () {}),
          ],
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      child: Icon(Icons.add),
      onPressed: () {},
    ),
  ),
)
```

---

## Bonusaufgabe: Debug-Banner entfernen

Entferne das "DEBUG"-Banner in der oberen rechten Ecke.

Hint: MaterialApp hat eine Property `debugShowCheckedModeBanner`
