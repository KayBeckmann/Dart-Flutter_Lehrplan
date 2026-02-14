# Modul 5: Loesung -- Visitenkarten-App

## Vollstaendige Loesung (lib/main.dart)

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const VisitenkartApp());
}

// ============================================================
// 1. Root-Widget: MaterialApp mit Theme
// ============================================================
class VisitenkartApp extends StatelessWidget {
  const VisitenkartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visitenkarte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const VisitenkartSeite(),
    );
  }
}

// ============================================================
// 2. Hauptseite mit Scaffold
// ============================================================
class VisitenkartSeite extends StatelessWidget {
  const VisitenkartSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Visitenkarte'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              // Oberer Bereich: Profilbild, Name, Beruf
              ProfilHeader(
                name: 'Max Mustermann',
                beruf: 'Flutter-Entwickler',
                bildUrl: 'https://i.pravatar.cc/300',
              ),
              SizedBox(height: 32),

              // Kontaktbereich mit allen Kontaktzeilen
              KontaktBereich(),
              SizedBox(height: 24),

              // Social Media Leiste
              SocialMediaLeiste(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. ProfilHeader: Bild, Name und Berufsbezeichnung
// ============================================================
class ProfilHeader extends StatelessWidget {
  const ProfilHeader({
    super.key,
    required this.name,
    required this.beruf,
    this.bildUrl,
  });

  final String name;
  final String beruf;
  final String? bildUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rundes Profilbild
        CircleAvatar(
          radius: 65,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
                bildUrl != null ? NetworkImage(bildUrl!) : null,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: bildUrl == null
                ? Text(
                    name.split(' ').map((n) => n[0]).join(),
                    style: const TextStyle(fontSize: 36),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),

        // Name
        Text(
          name,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),

        // Berufsbezeichnung
        Text(
          beruf,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),

        // Trennlinie
        SizedBox(
          width: 150,
          child: Divider(
            thickness: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// 4. KontaktBereich: Alle Kontaktzeilen zusammen
// ============================================================
class KontaktBereich extends StatelessWidget {
  const KontaktBereich({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            KontaktZeile(
              icon: Icons.phone,
              text: '+49 123 456 7890',
              farbe: Colors.green,
            ),
            Divider(height: 1, indent: 72),
            KontaktZeile(
              icon: Icons.email,
              text: 'max.mustermann@example.de',
              farbe: Colors.red,
            ),
            Divider(height: 1, indent: 72),
            KontaktZeile(
              icon: Icons.location_on,
              text: 'Berlin, Deutschland',
              farbe: Colors.blue,
            ),
            Divider(height: 1, indent: 72),
            KontaktZeile(
              icon: Icons.language,
              text: 'www.maxmustermann.de',
              farbe: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. KontaktZeile: Wiederverwendbares Widget fuer eine Zeile
// ============================================================
class KontaktZeile extends StatelessWidget {
  const KontaktZeile({
    super.key,
    required this.icon,
    required this.text,
    this.farbe,
  });

  final IconData icon;
  final String text;
  final Color? farbe;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (farbe ?? Theme.of(context).colorScheme.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: farbe ?? Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        text,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

// ============================================================
// 6. Social Media Leiste (Bonus)
// ============================================================
class SocialMediaLeiste extends StatelessWidget {
  const SocialMediaLeiste({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Social Media',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _socialButton(
                  context,
                  icon: Icons.code,
                  label: 'GitHub',
                  farbe: Colors.black87,
                ),
                const SizedBox(width: 16),
                _socialButton(
                  context,
                  icon: Icons.work,
                  label: 'LinkedIn',
                  farbe: Colors.blue.shade700,
                ),
                const SizedBox(width: 16),
                _socialButton(
                  context,
                  icon: Icons.alternate_email,
                  label: 'Twitter',
                  farbe: Colors.lightBlue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _socialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color farbe,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label geoeffnet')),
            );
          },
          icon: Icon(icon),
          color: farbe,
          iconSize: 32,
          tooltip: label,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

---

## Erklaerung der Loesung

### Widget-Struktur

```
VisitenkartApp (MaterialApp)
  └── VisitenkartSeite (Scaffold)
       ├── AppBar
       └── SingleChildScrollView
            └── Column
                 ├── ProfilHeader
                 │    ├── CircleAvatar (Profilbild)
                 │    ├── Text (Name)
                 │    ├── Text (Beruf)
                 │    └── Divider
                 ├── KontaktBereich (Card)
                 │    ├── KontaktZeile (Telefon)
                 │    ├── KontaktZeile (E-Mail)
                 │    ├── KontaktZeile (Standort)
                 │    └── KontaktZeile (Webseite)
                 └── SocialMediaLeiste (Card)
                      └── Row mit IconButtons
```

### Wichtige Design-Entscheidungen

1. **SingleChildScrollView:** Umschliesst den gesamten Inhalt, damit die Seite auf kleinen Bildschirmen scrollbar ist.

2. **Wiederverwendbare KontaktZeile:** Nimmt `icon`, `text` und optionale `farbe` als Parameter. So vermeidet man Code-Duplikation.

3. **CircleAvatar mit Rand:** Zwei verschachtelte `CircleAvatar`-Widgets (aussen groesser) erzeugen einen farbigen Rand.

4. **Theme-Integration:** Farben und Textstile werden ueber `Theme.of(context)` abgerufen, nicht hart codiert. Das macht die App konsistent und leicht anpassbar.

5. **ListTile in KontaktZeile:** `ListTile` bietet automatisch das richtige Spacing und die richtige Ausrichtung fuer Icon-Text-Kombinationen.

6. **Null-Safety beim Bild:** `bildUrl` ist optional (`String?`). Wenn kein Bild angegeben wird, werden stattdessen Initialen angezeigt.

### So fuehrst du die App aus

```bash
flutter create visitenkarte
cd visitenkarte
# Ersetze den Inhalt von lib/main.dart mit dem Code oben
flutter run
```
