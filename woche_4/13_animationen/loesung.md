# Modul 13: Animationen -- Lösung

## Vollständige Lösung: Animierte Produktkarten-App

### Projektstruktur

```
lib/
  main.dart
  models/
    produkt.dart
  screens/
    lade_screen.dart
    produkt_liste_screen.dart
    produkt_detail_screen.dart
  widgets/
    produkt_karte.dart
    neu_badge.dart
    like_button.dart
    lottie_lader.dart
```

---

### models/produkt.dart

```dart
/// Datenmodell für ein Produkt.
/// Verwendet Konzepte aus Modul 2 (OOP) und Modul 4 (Enhanced Enums).
class Produkt {
  final String id;
  final String name;
  final double preis;
  final String beschreibung;
  final double bewertung;
  final bool istNeu;
  bool istLiked;

  Produkt({
    required this.id,
    required this.name,
    required this.preis,
    this.beschreibung = 'Keine Beschreibung verfügbar.',
    this.bewertung = 0.0,
    this.istNeu = false,
    this.istLiked = false,
  });

  /// Erstellt eine Kopie mit optionalen Änderungen (Modul 4: copyWith-Pattern).
  Produkt copyWith({
    String? name,
    double? preis,
    String? beschreibung,
    double? bewertung,
    bool? istNeu,
    bool? istLiked,
  }) {
    return Produkt(
      id: id,
      name: name ?? this.name,
      preis: preis ?? this.preis,
      beschreibung: beschreibung ?? this.beschreibung,
      bewertung: bewertung ?? this.bewertung,
      istNeu: istNeu ?? this.istNeu,
      istLiked: istLiked ?? this.istLiked,
    );
  }
}

/// Beispielprodukte für die Demo.
List<Produkt> beispielProdukte() {
  return [
    Produkt(
      id: '1',
      name: 'Wireless Kopfhörer',
      preis: 79.99,
      beschreibung:
          'Kabellose Bluetooth-Kopfhörer mit Noise-Cancelling und 30h Akkulaufzeit.',
      bewertung: 4.5,
      istNeu: true,
    ),
    Produkt(
      id: '2',
      name: 'USB-C Hub',
      preis: 34.99,
      beschreibung: '7-in-1 USB-C Hub mit HDMI, USB 3.0, SD-Kartenleser.',
      bewertung: 4.2,
    ),
    Produkt(
      id: '3',
      name: 'Mechanische Tastatur',
      preis: 129.99,
      beschreibung: 'RGB-beleuchtete mechanische Tastatur mit Cherry MX Switches.',
      bewertung: 4.8,
      istNeu: true,
    ),
    Produkt(
      id: '4',
      name: 'Laptop-Ständer',
      preis: 24.99,
      beschreibung: 'Ergonomischer Laptop-Ständer aus Aluminium, faltbar.',
      bewertung: 4.0,
    ),
    Produkt(
      id: '5',
      name: 'Webcam HD',
      preis: 49.99,
      beschreibung: '1080p Webcam mit Autofokus und Mikrofon.',
      bewertung: 3.9,
    ),
  ];
}
```

---

### widgets/neu_badge.dart

```dart
import 'package:flutter/material.dart';

/// Pulsierendes "Neu"-Badge mit expliziter Animation (Aufgabe 4).
///
/// Verwendet:
/// - AnimationController mit repeat(reverse: true) für Endlosschleife
/// - SingleTickerProviderStateMixin für vsync
/// - Tween für Skalierung und Opacity
/// - AnimatedBuilder für effizientes Neuzeichnen
class NeuBadge extends StatefulWidget {
  const NeuBadge({super.key});

  @override
  State<NeuBadge> createState() => _NeuBadgeState();
}

class _NeuBadgeState extends State<NeuBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Controller mit 1 Sekunde Dauer, endlos hin und her
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    // Skalierung: 0.9 → 1.1 mit sanfter Kurve
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Opacity: 0.7 → 1.0
    _opacityAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // Wichtig: Ressourcen freigeben!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      // child wird nur einmal gebaut (Performance-Optimierung)
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Text(
          'NEU',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
```

---

### widgets/like_button.dart

```dart
import 'package:flutter/material.dart';

/// Like-Button mit AnimatedSwitcher (Aufgabe 5).
///
/// Verwendet:
/// - AnimatedSwitcher für den Icon-Wechsel
/// - Benutzerdefinierter transitionBuilder mit Scale + Rotation
/// - ValueKey damit AnimatedSwitcher den Wechsel erkennt
class LikeButton extends StatelessWidget {
  final bool istLiked;
  final VoidCallback onTap;

  const LikeButton({
    super.key,
    required this.istLiked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          // Kombination aus Scale und Rotation für einen lebendigen Effekt
          return ScaleTransition(
            scale: animation,
            child: RotationTransition(
              turns: Tween<double>(begin: 0.5, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: Icon(
          istLiked ? Icons.favorite : Icons.favorite_border,
          // Key ist ENTSCHEIDEND: Ohne Key erkennt AnimatedSwitcher
          // keinen Unterschied und spielt keine Animation ab.
          key: ValueKey<bool>(istLiked),
          color: istLiked ? Colors.red : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}
```

---

### widgets/lottie_lader.dart

```dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Lottie-basierter Ladeindikator (Aufgabe 6).
///
/// Falls keine Lottie-Datei vorhanden ist, wird ein animierter
/// Fallback-Indikator angezeigt.
class LottieLader extends StatelessWidget {
  final double groesse;

  const LottieLader({super.key, this.groesse = 200});

  @override
  Widget build(BuildContext context) {
    // Versuche Lottie zu laden, mit Fallback bei Fehler
    return SizedBox(
      width: groesse,
      height: groesse,
      child: Lottie.asset(
        'assets/animations/loading.json',
        width: groesse,
        height: groesse,
        fit: BoxFit.contain,
        // Falls die Datei nicht existiert, zeigen wir einen Fallback
        errorBuilder: (context, error, stackTrace) {
          return _FallbackLader(groesse: groesse);
        },
      ),
    );
  }
}

/// Animierter Fallback, falls keine Lottie-Datei vorhanden.
/// Zeigt einen rotierenden und pulsierenden Kreis.
class _FallbackLader extends StatefulWidget {
  final double groesse;

  const _FallbackLader({required this.groesse});

  @override
  State<_FallbackLader> createState() => _FallbackLaderState();
}

class _FallbackLaderState extends State<_FallbackLader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * 3.14159,
          child: child,
        );
      },
      child: SizedBox(
        width: widget.groesse,
        height: widget.groesse,
        child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.blue.shade400,
          ),
        ),
      ),
    );
  }
}
```

---

### widgets/produkt_karte.dart

```dart
import 'package:flutter/material.dart';
import '../models/produkt.dart';
import 'neu_badge.dart';
import 'like_button.dart';

/// Animierte Produktkarte mit Expand/Collapse (Aufgabe 2).
///
/// Verwendet:
/// - AnimatedContainer für die Höhenänderung
/// - AnimatedOpacity für das Ein-/Ausblenden der Details
/// - AnimatedCrossFade für das Wechseln des Icons
/// - Hero-Widget für die Navigation zur Detailseite (Aufgabe 3)
/// - NeuBadge für neue Produkte (Aufgabe 4)
/// - LikeButton mit AnimatedSwitcher (Aufgabe 5)
class ProduktKarte extends StatefulWidget {
  final Produkt produkt;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final VoidCallback onTapBild;

  const ProduktKarte({
    super.key,
    required this.produkt,
    required this.onDelete,
    required this.onLike,
    required this.onTapBild,
  });

  @override
  State<ProduktKarte> createState() => _ProduktKarteState();
}

class _ProduktKarteState extends State<ProduktKarte> {
  bool _istErweitert = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(
            color: _istErweitert ? Colors.blue.shade200 : Colors.transparent,
            width: _istErweitert ? 1.5 : 0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Oberer Bereich: Bild + Info + Aktionen
            Row(
              children: [
                // Produktbild mit Hero-Animation (Aufgabe 3)
                GestureDetector(
                  onTap: widget.onTapBild,
                  child: Hero(
                    tag: 'produkt-bild-${widget.produkt.id}',
                    child: Stack(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _farbeFuerProdukt(widget.produkt.id),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_bag,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        // "Neu"-Badge (Aufgabe 4)
                        if (widget.produkt.istNeu)
                          const Positioned(
                            top: -2,
                            right: -2,
                            child: NeuBadge(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name und Preis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.produkt.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.produkt.preis.toStringAsFixed(2)} EUR',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Like-Button (Aufgabe 5)
                LikeButton(
                  istLiked: widget.produkt.istLiked,
                  onTap: widget.onLike,
                ),

                const SizedBox(width: 4),

                // Expand/Collapse Icon mit AnimatedCrossFade
                GestureDetector(
                  onTap: () => setState(() => _istErweitert = !_istErweitert),
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _istErweitert
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: const Icon(Icons.expand_more, size: 28),
                    secondChild: const Icon(Icons.expand_less, size: 28),
                  ),
                ),
              ],
            ),

            // Erweiterter Bereich mit AnimatedOpacity (Aufgabe 2)
            AnimatedOpacity(
              opacity: _istErweitert ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                height: _istErweitert ? null : 0,
                child: _istErweitert
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 24),
                          Text(
                            widget.produkt.beschreibung,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Bewertung
                          Row(
                            children: [
                              ...List.generate(5, (index) {
                                return Icon(
                                  index < widget.produkt.bewertung.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.produkt.bewertung}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Warenkorb-Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '${widget.produkt.name} zum Warenkorb hinzugefügt!',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.shopping_cart),
                              label: const Text('In den Warenkorb'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gibt eine Farbe basierend auf der Produkt-ID zurück.
  Color _farbeFuerProdukt(String id) {
    final farben = [
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.green.shade400,
    ];
    final index = int.tryParse(id) ?? 0;
    return farben[index % farben.length];
  }
}
```

---

### screens/lade_screen.dart

```dart
import 'package:flutter/material.dart';
import '../widgets/lottie_lader.dart';

/// Ladebildschirm mit Lottie-Animation (Aufgabe 6).
///
/// Zeigt für 3 Sekunden eine Ladeanimation und ruft dann
/// den Callback auf, um zur Hauptseite zu wechseln.
class LadeScreen extends StatefulWidget {
  final VoidCallback onLadeAbgeschlossen;

  const LadeScreen({super.key, required this.onLadeAbgeschlossen});

  @override
  State<LadeScreen> createState() => _LadeScreenState();
}

class _LadeScreenState extends State<LadeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-Out-Animation vorbereiten
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    // Nach 3 Sekunden: Ausblenden und dann Callback aufrufen
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          if (mounted) {
            widget.onLadeAbgeschlossen();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LottieLader(groesse: 200),
              const SizedBox(height: 32),
              Text(
                'Produkte werden geladen...',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### screens/produkt_detail_screen.dart

```dart
import 'package:flutter/material.dart';
import '../models/produkt.dart';

/// Detailseite mit Hero-Animation (Aufgabe 3).
///
/// Das Produktbild fliegt nahtlos von der Liste zu dieser Seite
/// dank identischem Hero-Tag.
class ProduktDetailScreen extends StatelessWidget {
  final Produkt produkt;

  const ProduktDetailScreen({super.key, required this.produkt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(produkt.name),
        backgroundColor: _farbeFuerProdukt(produkt.id),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero-Widget mit dem gleichen Tag wie in der ProduktKarte
            Hero(
              tag: 'produkt-bild-${produkt.id}',
              child: Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: _farbeFuerProdukt(produkt.id),
                ),
                child: const Icon(
                  Icons.shopping_bag,
                  color: Colors.white,
                  size: 100,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Produktname
                  Text(
                    produkt.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Preis
                  Text(
                    '${produkt.preis.toStringAsFixed(2)} EUR',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bewertung
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < produkt.bewertung.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 28,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        '${produkt.bewertung} / 5.0',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Beschreibung
                  const Text(
                    'Beschreibung',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    produkt.beschreibung,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Tags
                  Wrap(
                    spacing: 8,
                    children: [
                      if (produkt.istNeu)
                        Chip(
                          label: const Text('Neu'),
                          backgroundColor: Colors.red.shade100,
                          labelStyle: TextStyle(color: Colors.red.shade700),
                        ),
                      if (produkt.istLiked)
                        Chip(
                          label: const Text('Favorit'),
                          backgroundColor: Colors.pink.shade100,
                          labelStyle: TextStyle(color: Colors.pink.shade700),
                          avatar: const Icon(Icons.favorite, size: 16),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Kaufen-Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${produkt.name} wurde zum Warenkorb hinzugefügt!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text(
                        'In den Warenkorb',
                        style: TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _farbeFuerProdukt(produkt.id),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _farbeFuerProdukt(String id) {
    final farben = [
      Colors.blue.shade400,
      Colors.purple.shade400,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
      Colors.green.shade400,
    ];
    final index = int.tryParse(id) ?? 0;
    return farben[index % farben.length];
  }
}
```

---

### screens/produkt_liste_screen.dart

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/produkt.dart';
import '../widgets/produkt_karte.dart';
import 'produkt_detail_screen.dart';

/// Hauptbildschirm mit AnimatedList (Aufgabe 1).
///
/// Verwendet:
/// - AnimatedList für animiertes Hinzufügen/Entfernen
/// - SlideTransition + FadeTransition für den Eintrittseffekt
/// - Dismissible für Swipe-to-Delete
/// - Navigation zur Detailseite mit Hero-Animation
class ProduktListeScreen extends StatefulWidget {
  const ProduktListeScreen({super.key});

  @override
  State<ProduktListeScreen> createState() => _ProduktListeScreenState();
}

class _ProduktListeScreenState extends State<ProduktListeScreen> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _produkte = <Produkt>[];
  int _naechsteId = 100;

  @override
  void initState() {
    super.initState();
    // Beispielprodukte nacheinander hinzufügen (gestaffelter Effekt)
    final beispiele = beispielProdukte();
    for (var i = 0; i < beispiele.length; i++) {
      Future.delayed(Duration(milliseconds: 150 * i), () {
        if (mounted) {
          _produktHinzufuegen(beispiele[i]);
        }
      });
    }
  }

  void _produktHinzufuegen(Produkt produkt) {
    final index = _produkte.length;
    _produkte.add(produkt);
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _zufaelligesProduktHinzufuegen() {
    final random = Random();
    final namen = [
      'Smart Watch',
      'Bluetooth Lautsprecher',
      'Maus kabellos',
      'Monitor 27"',
      'SSD 1TB',
      'Mikrofon',
      'Tablet-Hülle',
      'Ladekabel 2m',
    ];
    final name = namen[random.nextInt(namen.length)];
    final preis = (random.nextDouble() * 150 + 10).roundToDouble();
    final produkt = Produkt(
      id: '${_naechsteId++}',
      name: name,
      preis: preis,
      beschreibung: 'Ein tolles Produkt: $name.',
      bewertung: (random.nextDouble() * 2 + 3).roundToDouble(),
      istNeu: random.nextBool(),
    );
    _produktHinzufuegen(produkt);
  }

  void _produktEntfernen(int index) {
    final entferntesProdukt = _produkte.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) {
        // Beim Entfernen: Nach links herausrutschen + ausblenden
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(-1, 0), // Nach links schieben
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeInBack,
          )),
          child: FadeTransition(
            opacity: animation,
            child: ProduktKarte(
              produkt: entferntesProdukt,
              onDelete: () {},
              onLike: () {},
              onTapBild: () {},
            ),
          ),
        );
      },
      duration: const Duration(milliseconds: 400),
    );
  }

  void _navigiereZuDetail(Produkt produkt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProduktDetailScreen(produkt: produkt),
      ),
    );
  }

  void _toggleLike(int index) {
    setState(() {
      _produkte[index].istLiked = !_produkte[index].istLiked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produkte'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Warenkorb-Icon mit AnimatedSwitcher für den Zähler
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _produkte.length,
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemBuilder: (context, index, animation) {
          // Beim Hinzufügen: Von rechts hereinrutschen + einblenden
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0), // Startet rechts außerhalb
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: FadeTransition(
              opacity: animation,
              child: Dismissible(
                key: ValueKey(_produkte[index].id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _produktEntfernen(index),
                child: ProduktKarte(
                  produkt: _produkte[index],
                  onDelete: () => _produktEntfernen(index),
                  onLike: () => _toggleLike(index),
                  onTapBild: () => _navigiereZuDetail(_produkte[index]),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _zufaelligesProduktHinzufuegen,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

### main.dart

```dart
import 'package:flutter/material.dart';
import 'screens/lade_screen.dart';
import 'screens/produkt_liste_screen.dart';

void main() {
  runApp(const MeineApp());
}

/// Hauptapp mit Ladebildschirm und AnimatedSwitcher-Übergang.
///
/// Kombiniert alle Animationskonzepte aus Modul 13:
/// - Lottie-Ladebildschirm (Aufgabe 6)
/// - AnimatedSwitcher für den Screen-Wechsel
/// - AnimatedList auf dem Hauptscreen (Aufgabe 1)
/// - Produktkarten mit Expand/Collapse (Aufgabe 2)
/// - Hero-Animationen zur Detailseite (Aufgabe 3)
/// - Pulsierendes Neu-Badge (Aufgabe 4)
/// - Like-Button mit AnimatedSwitcher (Aufgabe 5)
class MeineApp extends StatelessWidget {
  const MeineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animierte Produkte',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
      ),
      home: const AppWrapper(),
    );
  }
}

/// Wrapper der zwischen Ladebildschirm und Hauptapp wechselt.
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _laedt = true;

  @override
  Widget build(BuildContext context) {
    // AnimatedSwitcher für den Übergang zwischen Lade- und Hauptscreen
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _laedt
          ? LadeScreen(
              key: const ValueKey('laden'),
              onLadeAbgeschlossen: () {
                setState(() => _laedt = false);
              },
            )
          : const ProduktListeScreen(
              key: ValueKey('hauptseite'),
            ),
    );
  }
}
```

---

## Hinweise zur Lösung

### Verwendete Animationstypen

| Aufgabe | Widget/Technik | Typ |
|---------|---------------|-----|
| 1. Produktliste | `AnimatedList`, `SlideTransition`, `FadeTransition` | Implizit (AnimatedList) + Explizit (Transitions) |
| 2. Expand/Collapse | `AnimatedContainer`, `AnimatedOpacity`, `AnimatedCrossFade` | Implizit |
| 3. Hero-Animation | `Hero` Widget | Speziell (Page Transition) |
| 4. Neu-Badge | `AnimationController`, `Tween`, `AnimatedBuilder` | Explizit |
| 5. Like-Button | `AnimatedSwitcher`, `ScaleTransition`, `RotationTransition` | Implizit (AnimatedSwitcher) |
| 6. Lottie-Lader | `Lottie.asset()`, `AnimationController` | Extern (Lottie) |

### Wichtige Lektionen

1. **Immer `dispose()` aufrufen:** Jeder `AnimationController` muss in `dispose()` aufgeräumt werden, sonst entstehen Memory Leaks.

2. **`child`-Parameter nutzen:** Bei `AnimatedBuilder` das statische `child` als Parameter übergeben, nicht im Builder erstellen.

3. **Keys bei AnimatedSwitcher:** Ohne unterschiedliche Keys erkennt `AnimatedSwitcher` keinen Widget-Wechsel.

4. **Hero-Tags müssen eindeutig sein:** Gleicher Tag auf Start- und Zielscreen, aber eindeutig innerhalb eines Screens.

5. **Curves wählen:** `Curves.easeInOut` für die meisten UI-Animationen, `Curves.bounceOut` oder `Curves.elasticOut` für spielerische Effekte.
