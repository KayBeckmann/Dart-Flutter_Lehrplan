# Modul 7: Loesung -- Dashboard-App

## Vollstaendige Loesung (lib/main.dart)

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const DashboardApp());
}

// ============================================================
// 1. Root-Widget mit Theme
// ============================================================
class DashboardApp extends StatelessWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const DashboardSeite(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

// ============================================================
// 2. Dashboard-Seite
// ============================================================
class DashboardSeite extends StatelessWidget {
  const DashboardSeite({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      drawer: const _AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Simuliertes Neuladen
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistik-Karten
              const StatistikBereich(),
              const SizedBox(height: 24),

              // Letzte Aktivitaeten
              Text(
                'Letzte Aktivitaeten',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const AktivitaetenListe(),
              const SizedBox(height: 24),

              // Kategorien
              Text(
                'Kategorien',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const KategorienGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 3. Statistik-Bereich -- responsive mit LayoutBuilder
// ============================================================
class StatistikBereich extends StatelessWidget {
  const StatistikBereich({super.key});

  static const _statistiken = [
    _StatistikDaten(
      icon: Icons.people_outline,
      titel: 'Benutzer',
      wert: '1.234',
      trend: '+12%',
      istPositiv: true,
      farbe: Colors.blue,
    ),
    _StatistikDaten(
      icon: Icons.euro,
      titel: 'Umsatz',
      wert: '5.678',
      trend: '+8%',
      istPositiv: true,
      farbe: Colors.green,
    ),
    _StatistikDaten(
      icon: Icons.shopping_bag_outlined,
      titel: 'Bestellungen',
      wert: '89',
      trend: '-3%',
      istPositiv: false,
      farbe: Colors.orange,
    ),
    _StatistikDaten(
      icon: Icons.star_outline,
      titel: 'Bewertung',
      wert: '4.7',
      trend: '+0.2',
      istPositiv: true,
      farbe: Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobil: 2x2 Grid
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: _statistiken
                .map((s) => StatistikKarte(daten: s))
                .toList(),
          );
        } else {
          // Tablet/Desktop: 1 Row
          return Row(
            children: _statistiken
                .map((s) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: StatistikKarte(daten: s),
                      ),
                    ))
                .toList(),
          );
        }
      },
    );
  }
}

class _StatistikDaten {
  const _StatistikDaten({
    required this.icon,
    required this.titel,
    required this.wert,
    required this.trend,
    required this.istPositiv,
    required this.farbe,
  });

  final IconData icon;
  final String titel;
  final String wert;
  final String trend;
  final bool istPositiv;
  final Color farbe;
}

// ============================================================
// 4. Statistik-Karte
// ============================================================
class StatistikKarte extends StatelessWidget {
  const StatistikKarte({super.key, required this.daten});

  final _StatistikDaten daten;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Icon und Trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: daten.farbe.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    daten.icon,
                    color: daten.farbe,
                    size: 24,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (daten.istPositiv ? Colors.green : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        daten.istPositiv
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 14,
                        color:
                            daten.istPositiv ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        daten.trend,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: daten.istPositiv
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Wert und Titel
            Text(
              daten.wert,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
            ),
            Text(
              daten.titel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 5. Aktivitaeten-Liste
// ============================================================
class AktivitaetenListe extends StatelessWidget {
  const AktivitaetenListe({super.key});

  static const _aktivitaeten = [
    _AktivitaetDaten(
      icon: Icons.shopping_bag,
      iconFarbe: Colors.blue,
      titel: 'Neue Bestellung eingegangen',
      beschreibung: 'Bestellung #1234 von Max M.',
      zeit: 'Vor 5 Min.',
    ),
    _AktivitaetDaten(
      icon: Icons.person_add,
      iconFarbe: Colors.green,
      titel: 'Neuer Benutzer registriert',
      beschreibung: 'Anna S. hat ein Konto erstellt',
      zeit: 'Vor 15 Min.',
    ),
    _AktivitaetDaten(
      icon: Icons.payment,
      iconFarbe: Colors.orange,
      titel: 'Zahlung erhalten',
      beschreibung: 'EUR 129,99 fuer Bestellung #1230',
      zeit: 'Vor 1 Std.',
    ),
    _AktivitaetDaten(
      icon: Icons.star,
      iconFarbe: Colors.amber,
      titel: 'Neue Bewertung',
      beschreibung: '5 Sterne von Benutzer Tom K.',
      zeit: 'Vor 2 Std.',
    ),
    _AktivitaetDaten(
      icon: Icons.inventory,
      iconFarbe: Colors.red,
      titel: 'Lagerbestand niedrig',
      beschreibung: 'Produkt "Widget Pro" -- nur 3 Stueck uebrig',
      zeit: 'Vor 3 Std.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(_aktivitaeten.length * 2 - 1, (index) {
          if (index.isOdd) {
            return const Divider(height: 1, indent: 72);
          }
          final aktivitaet = _aktivitaeten[index ~/ 2];
          return AktivitaetEintrag(daten: aktivitaet);
        }),
      ),
    );
  }
}

class _AktivitaetDaten {
  const _AktivitaetDaten({
    required this.icon,
    required this.iconFarbe,
    required this.titel,
    required this.beschreibung,
    required this.zeit,
  });

  final IconData icon;
  final Color iconFarbe;
  final String titel;
  final String beschreibung;
  final String zeit;
}

// ============================================================
// 6. Aktivitaet-Eintrag
// ============================================================
class AktivitaetEintrag extends StatelessWidget {
  const AktivitaetEintrag({super.key, required this.daten});

  final _AktivitaetDaten daten;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: daten.iconFarbe.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(daten.icon, color: daten.iconFarbe),
      ),
      title: Text(
        daten.titel,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(daten.beschreibung),
      trailing: Text(
        daten.zeit,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ============================================================
// 7. Kategorien-Grid -- responsive mit LayoutBuilder
// ============================================================
class KategorienGrid extends StatelessWidget {
  const KategorienGrid({super.key});

  static const _kategorien = [
    _KategorieDaten(
      icon: Icons.devices,
      name: 'Elektronik',
      anzahl: 156,
      farbe: Colors.blue,
    ),
    _KategorieDaten(
      icon: Icons.checkroom,
      name: 'Kleidung',
      anzahl: 243,
      farbe: Colors.pink,
    ),
    _KategorieDaten(
      icon: Icons.menu_book,
      name: 'Buecher',
      anzahl: 89,
      farbe: Colors.amber,
    ),
    _KategorieDaten(
      icon: Icons.sports_esports,
      name: 'Spiele',
      anzahl: 67,
      farbe: Colors.green,
    ),
    _KategorieDaten(
      icon: Icons.home,
      name: 'Haushalt',
      anzahl: 134,
      farbe: Colors.orange,
    ),
    _KategorieDaten(
      icon: Icons.fitness_center,
      name: 'Sport',
      anzahl: 45,
      farbe: Colors.teal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int spalten;
        if (constraints.maxWidth > 900) {
          spalten = 4;
        } else if (constraints.maxWidth > 600) {
          spalten = 3;
        } else {
          spalten = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: spalten,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _kategorien.length,
          itemBuilder: (context, index) {
            return KategorieKachel(daten: _kategorien[index]);
          },
        );
      },
    );
  }
}

class _KategorieDaten {
  const _KategorieDaten({
    required this.icon,
    required this.name,
    required this.anzahl,
    required this.farbe,
  });

  final IconData icon;
  final String name;
  final int anzahl;
  final Color farbe;
}

// ============================================================
// 8. Kategorie-Kachel
// ============================================================
class KategorieKachel extends StatelessWidget {
  const KategorieKachel({super.key, required this.daten});

  final _KategorieDaten daten;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            builder: (context) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(daten.icon, size: 48, color: daten.farbe),
                      const SizedBox(height: 16),
                      Text(
                        daten.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text('${daten.anzahl} Produkte'),
                    ],
                  ),
                ),
              );
            },
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: daten.farbe.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  daten.icon,
                  color: daten.farbe,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                daten.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${daten.anzahl} Produkte',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 9. App-Drawer
// ============================================================
class _AppDrawer extends StatelessWidget {
  const _AppDrawer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    'AD',
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Admin Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Benutzer'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Bestellungen'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Statistiken'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Einstellungen'),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
```

---

## Erklaerung der Loesung

### Widget-Baum

```
DashboardApp (MaterialApp)
  └── DashboardSeite (Scaffold)
       ├── AppBar
       ├── Drawer (_AppDrawer)
       └── RefreshIndicator
            └── SingleChildScrollView
                 └── Column
                      ├── StatistikBereich
                      │    └── LayoutBuilder
                      │         ├── < 600px: GridView.count (2x2)
                      │         └── >= 600px: Row mit Expanded
                      │              └── StatistikKarte (x4)
                      ├── AktivitaetenListe (Card)
                      │    └── Column mit AktivitaetEintrag (x5)
                      └── KategorienGrid
                           └── LayoutBuilder
                                └── GridView.builder (2/3/4 Spalten)
                                     └── KategorieKachel (x6)
```

### Design-Entscheidungen

1. **Daten-Klassen mit `const`:** Die `_StatistikDaten`, `_AktivitaetDaten` und `_KategorieDaten` Klassen kapseln die Daten sauber. Sie sind `const`-faehig, sodass die statischen Listen effizient sind.

2. **LayoutBuilder statt MediaQuery:** `LayoutBuilder` reagiert auf den verfuegbaren Platz des Widgets, nicht auf die Bildschirmgroesse. Das ist flexibler, z.B. wenn das Dashboard in einem Split-View oder als Teil einer groesseren Seite angezeigt wird.

3. **shrinkWrap + NeverScrollableScrollPhysics:** Wenn ein `GridView` innerhalb eines `SingleChildScrollView` liegt, muss es `shrinkWrap: true` verwenden (damit es nur so gross wird wie sein Inhalt) und `NeverScrollableScrollPhysics()` (damit es nicht selbst scrollt).

4. **RefreshIndicator:** Umschliesst den `SingleChildScrollView` und bietet Pull-to-Refresh-Funktionalitaet.

5. **InkWell auf KategorieKachel:** Bietet visuelles Feedback beim Tippen und oeffnet ein Bottom Sheet.

6. **Responsive Statistik-Karten:** Auf schmalen Bildschirmen werden sie als 2x2-Grid angezeigt, auf breiten als eine Reihe mit gleich verteiltem Platz (Expanded).

### So fuehrst du die App aus

```bash
flutter create dashboard
cd dashboard
# Ersetze den Inhalt von lib/main.dart mit dem Code oben
flutter run -d chrome    # Im Browser testen (einfach Fenstergroesse aendern)
# oder
flutter run              # Im Emulator/Geraet testen
```
