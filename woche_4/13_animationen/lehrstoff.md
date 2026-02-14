# Modul 13: Animationen in Flutter

## 13.1 Überblick: Implizite vs. Explizite Animationen

Animationen sind das Herzstück einer guten User Experience. Flutter bietet ein leistungsstarkes Animationssystem, das sich in zwei Hauptkategorien aufteilt:

| Typ | Beschreibung | Kontrolle | Einsatz |
|-----|-------------|-----------|---------|
| **Implizite Animationen** | Flutter animiert automatisch zwischen altem und neuem Wert | Gering (nur Zielwert, Dauer, Kurve) | Einfache UI-Übergänge |
| **Explizite Animationen** | Du steuerst jeden Frame der Animation selbst | Voll (Start, Stop, Repeat, Richtung) | Komplexe, wiederholende oder verkettete Animationen |

**Vergleich zu CSS:**
- **Implizite Animationen** entsprechen CSS `transition` -- du definierst nur den Endzustand, der Browser (Flutter) animiert den Übergang.
- **Explizite Animationen** entsprechen CSS `@keyframes` + `animation` -- du definierst den genauen Ablauf Frame für Frame.

```
Entscheidungshilfe:

Möchtest du nur einen Eigenschaftswechsel animieren?
  → JA → Implizite Animation (AnimatedContainer, AnimatedOpacity, ...)
  → NEIN → Brauchst du volle Kontrolle (Loop, Reverse, Verkettung)?
              → JA → Explizite Animation (AnimationController + Tween)
              → NEIN → Hero-Animation oder AnimatedList?
```

---

## 13.2 Implizite Animationen (Einfach)

Implizite Animationen sind der einfachste Weg, Animationen in Flutter hinzuzufügen. Du änderst einfach einen Eigenschaftswert, und Flutter animiert den Übergang automatisch.

### AnimatedContainer

`AnimatedContainer` ist das vielseitigste implizite Animations-Widget. Es animiert jede Eigenschaft, die sich ändert: Größe, Farbe, Border, Padding, Margin, Decoration.

```dart
class AnimatedContainerDemo extends StatefulWidget {
  const AnimatedContainerDemo({super.key});

  @override
  State<AnimatedContainerDemo> createState() => _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<AnimatedContainerDemo> {
  bool _istErweitert = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _istErweitert = !_istErweitert),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        width: _istErweitert ? 300 : 150,
        height: _istErweitert ? 200 : 100,
        padding: EdgeInsets.all(_istErweitert ? 24 : 8),
        decoration: BoxDecoration(
          color: _istErweitert ? Colors.blue : Colors.red,
          borderRadius: BorderRadius.circular(_istErweitert ? 24 : 8),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: _istErweitert ? 16 : 4,
              offset: Offset(0, _istErweitert ? 8 : 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            _istErweitert ? 'Erweitert!' : 'Tippe mich!',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
```

**Vergleich zu CSS:**
```css
/* CSS-Äquivalent */
.container {
  transition: all 500ms ease-in-out;
  width: 150px;
  height: 100px;
  background: red;
}
.container.expanded {
  width: 300px;
  height: 200px;
  background: blue;
}
```

Der Unterschied: In CSS definierst du die Transition auf dem Element. In Flutter verwendest du ein spezielles Widget (`AnimatedContainer` statt `Container`).

### AnimatedOpacity

Animiert die Transparenz eines Widgets -- ideal für Ein-/Ausblend-Effekte.

```dart
class EinblendEffekt extends StatefulWidget {
  const EinblendEffekt({super.key});

  @override
  State<EinblendEffekt> createState() => _EinblendEffektState();
}

class _EinblendEffektState extends State<EinblendEffekt> {
  bool _sichtbar = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _sichtbar = !_sichtbar),
          child: Text(_sichtbar ? 'Ausblenden' : 'Einblenden'),
        ),
        AnimatedOpacity(
          opacity: _sichtbar ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
          child: const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ich kann verschwinden!'),
            ),
          ),
        ),
      ],
    );
  }
}
```

**Hinweis:** `AnimatedOpacity` versteckt das Widget visuell, aber es nimmt weiterhin Platz ein und reagiert auf Gesten. Wenn du das Widget komplett entfernen willst, verwende `AnimatedCrossFade` oder `AnimatedSwitcher`.

### AnimatedPositioned

Animiert die Position eines Widgets innerhalb eines `Stack`. Perfekt für Slide-Animationen.

```dart
class SlideAnimation extends StatefulWidget {
  const SlideAnimation({super.key});

  @override
  State<SlideAnimation> createState() => _SlideAnimationState();
}

class _SlideAnimationState extends State<SlideAnimation> {
  bool _istOben = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            top: _istOben ? 0 : 200,
            left: _istOben ? 0 : 150,
            child: GestureDetector(
              onTap: () => setState(() => _istOben = !_istOben),
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.touch_app, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### AnimatedCrossFade

Blendet zwischen zwei Widgets über -- eines wird ausgeblendet, das andere eingeblendet.

```dart
class CrossFadeDemo extends StatefulWidget {
  const CrossFadeDemo({super.key});

  @override
  State<CrossFadeDemo> createState() => _CrossFadeDemoState();
}

class _CrossFadeDemoState extends State<CrossFadeDemo> {
  bool _zeigeErstes = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => setState(() => _zeigeErstes = !_zeigeErstes),
          child: const Text('Wechseln'),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 400),
          crossFadeState: _zeigeErstes
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: const Card(
            color: Colors.blue,
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Widget A', style: TextStyle(color: Colors.white)),
            ),
          ),
          secondChild: const Card(
            color: Colors.green,
            child: Padding(
              padding: EdgeInsets.all(48),
              child: Text('Widget B', style: TextStyle(color: Colors.white)),
            ),
          ),
        ),
      ],
    );
  }
}
```

### AnimatedSwitcher

`AnimatedSwitcher` ist flexibler als `AnimatedCrossFade` -- es animiert den Wechsel zwischen beliebigen Widgets, basierend auf deren `key`.

```dart
class SwitcherDemo extends StatefulWidget {
  const SwitcherDemo({super.key});

  @override
  State<SwitcherDemo> createState() => _SwitcherDemoState();
}

class _SwitcherDemoState extends State<SwitcherDemo> {
  int _zaehler = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: Text(
            '$_zaehler',
            // Key ist entscheidend! Ohne Key erkennt Flutter keinen Wechsel.
            key: ValueKey<int>(_zaehler),
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _zaehler++),
          child: const Text('Erhöhen'),
        ),
      ],
    );
  }
}
```

**Wichtig:** Der `key` ist entscheidend bei `AnimatedSwitcher`. Ohne unterschiedliche Keys erkennt Flutter nicht, dass sich das Widget geändert hat, und spielt keine Animation ab.

### AnimatedDefaultTextStyle

Animiert Textformatierungen wie Schriftgröße, Farbe und Gewicht.

```dart
class TextStyleAnimation extends StatefulWidget {
  const TextStyleAnimation({super.key});

  @override
  State<TextStyleAnimation> createState() => _TextStyleAnimationState();
}

class _TextStyleAnimationState extends State<TextStyleAnimation> {
  bool _hervorgehoben = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _hervorgehoben = !_hervorgehoben),
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        style: TextStyle(
          fontSize: _hervorgehoben ? 32 : 16,
          fontWeight: _hervorgehoben ? FontWeight.bold : FontWeight.normal,
          color: _hervorgehoben ? Colors.blue : Colors.black,
        ),
        child: const Text('Tippe zum Hervorheben'),
      ),
    );
  }
}
```

### Duration und Curves

Jede implizite Animation benötigt eine `Duration` und kann eine `Curve` verwenden:

```dart
// Duration -- Dauer der Animation
const Duration(milliseconds: 300)  // 0.3 Sekunden (schnelle UI-Reaktion)
const Duration(milliseconds: 500)  // 0.5 Sekunden (Standard)
const Duration(seconds: 1)         // 1 Sekunde (langsame, bewusste Animation)

// Curves -- bestimmen die Beschleunigungskurve
Curves.linear        // Konstante Geschwindigkeit (langweilig)
Curves.easeIn        // Langsam starten, schnell enden
Curves.easeOut       // Schnell starten, langsam enden
Curves.easeInOut     // Langsam starten und enden (natürlich, empfohlen!)
Curves.bounceOut     // Federeffekt am Ende
Curves.elasticOut    // Elastischer Überschwung
Curves.fastOutSlowIn // Material Design Standard-Kurve
Curves.decelerate    // Abbremsen
```

**Vergleich zu CSS:**
```
CSS                          Dart/Flutter
─────────────────────────    ──────────────────────
ease                     →   Curves.ease
ease-in                  →   Curves.easeIn
ease-out                 →   Curves.easeOut
ease-in-out              →   Curves.easeInOut
linear                   →   Curves.linear
cubic-bezier(a,b,c,d)   →   Cubic(a, b, c, d)
```

### Übersicht aller impliziten Animations-Widgets

| Widget | Animiert | CSS-Äquivalent |
|--------|----------|----------------|
| `AnimatedContainer` | Größe, Farbe, Padding, Margin, Decoration | `transition: all` |
| `AnimatedOpacity` | Transparenz | `transition: opacity` |
| `AnimatedPositioned` | Position in Stack | `transition: top, left, ...` |
| `AnimatedCrossFade` | Überblendung zweier Widgets | -- |
| `AnimatedSwitcher` | Widget-Wechsel mit Transition | -- |
| `AnimatedDefaultTextStyle` | Textstil | `transition: font-size, color` |
| `AnimatedPadding` | Innenabstand | `transition: padding` |
| `AnimatedAlign` | Ausrichtung | `transition: align` |
| `AnimatedPhysicalModel` | Elevation, Schatten | `transition: box-shadow` |
| `AnimatedSlide` | Verschiebung (als Offset) | `transition: transform` |
| `AnimatedRotation` | Drehung | `transition: transform rotate` |
| `AnimatedScale` | Skalierung | `transition: transform scale` |
| `AnimatedFractionallySizedBox` | Größe relativ zum Elternelement | -- |

---

## 13.3 Explizite Animationen (Volle Kontrolle)

Wenn du mehr Kontrolle brauchst -- Schleifen, Verkettung, Synchronisation mehrerer Animationen -- verwendest du explizite Animationen.

### Die drei Bausteine

```
┌──────────────────────────────────────────────────────┐
│                 Explizite Animation                  │
│                                                      │
│  AnimationController ──→ Tween ──→ Animation<T>     │
│  (Steuerung: 0.0→1.0)   (Wertebereich)  (Aktueller Wert)  │
│                                                      │
│  Optional: CurvedAnimation (Beschleunigungskurve)   │
│                                                      │
│  Darstellung: AnimatedBuilder oder AnimatedWidget    │
└──────────────────────────────────────────────────────┘
```

### AnimationController

Der `AnimationController` ist das Herzstück jeder expliziten Animation. Er erzeugt Werte von 0.0 bis 1.0 über eine bestimmte Dauer.

```dart
class PulsierendesWidget extends StatefulWidget {
  const PulsierendesWidget({super.key});

  @override
  State<PulsierendesWidget> createState() => _PulsierendesWidgetState();
}

// SingleTickerProviderStateMixin liefert den vsync-Parameter
// Es stellt sicher, dass die Animation nur läuft, wenn das Widget sichtbar ist.
// Bei mehreren AnimationControllern: TickerProviderStateMixin (ohne "Single")
class _PulsierendesWidgetState extends State<PulsierendesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this, // "this" ist der TickerProvider (das Mixin)
    );

    // Animation starten
    _controller.forward(); // Einmal von 0.0 → 1.0
  }

  @override
  void dispose() {
    _controller.dispose(); // WICHTIG: Immer disposen!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _controller.value, // Wert zwischen 0.0 und 1.0
          child: child,
        );
      },
      child: const Text('Einblenden', style: TextStyle(fontSize: 24)),
    );
  }
}
```

**Warum vsync?** `vsync` (Vertical Sync) bindet die Animation an die Bildwiederholrate des Displays (typisch 60fps). Es verhindert:
- Unnötige Berechnungen, wenn das Widget nicht sichtbar ist
- Animationen, die schneller als die Bildwiederholrate laufen

**Vergleich zu JS:** `vsync` ist vergleichbar mit `requestAnimationFrame()` in JavaScript. Ohne `vsync` wäre es wie ein `setInterval()` -- ineffizient und nicht synchron mit dem Display.

### Animation-Steuerung

```dart
// Vorwärts abspielen (0.0 → 1.0)
_controller.forward();

// Rückwärts abspielen (1.0 → 0.0)
_controller.reverse();

// Endlos wiederholen (0→1→0→1→...)
_controller.repeat(reverse: true);

// Endlos vorwärts wiederholen (0→1, 0→1, 0→1, ...)
_controller.repeat();

// An bestimmte Position springen
_controller.value = 0.5;

// Von bestimmter Position starten
_controller.forward(from: 0.3);

// Stoppen
_controller.stop();

// Zurücksetzen
_controller.reset();

// Status prüfen
_controller.status; // AnimationStatus.forward, .reverse, .completed, .dismissed
_controller.isAnimating; // bool
_controller.isCompleted; // bool

// Listener
_controller.addListener(() {
  // Wird bei jedem Frame aufgerufen
  print('Aktueller Wert: ${_controller.value}');
});

_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    print('Animation abgeschlossen!');
    _controller.reverse(); // Automatisch zurücklaufen
  }
});
```

### Tween

Ein `Tween` (von "between") mappt den Controller-Bereich (0.0 - 1.0) auf beliebige Wertebereiche:

```dart
// Numerische Tweens
final groesseTween = Tween<double>(begin: 50.0, end: 200.0);
final opacityTween = Tween<double>(begin: 0.0, end: 1.0);

// Farb-Tween
final farbTween = ColorTween(begin: Colors.red, end: Colors.blue);

// Int-Tween
final intTween = IntTween(begin: 0, end: 255);

// Tween mit Controller verbinden
final Animation<double> groesseAnimation = groesseTween.animate(_controller);

// Aktuellen Wert lesen
print(groesseAnimation.value); // z.B. 125.0 wenn Controller bei 0.5 ist
```

### TweenSequence

Für Animationen mit mehreren Phasen:

```dart
final farbSequenz = TweenSequence<Color?>([
  TweenSequenceItem(
    tween: ColorTween(begin: Colors.red, end: Colors.blue),
    weight: 30, // 30% der Gesamtdauer
  ),
  TweenSequenceItem(
    tween: ColorTween(begin: Colors.blue, end: Colors.green),
    weight: 30, // 30% der Gesamtdauer
  ),
  TweenSequenceItem(
    tween: ColorTween(begin: Colors.green, end: Colors.red),
    weight: 40, // 40% der Gesamtdauer
  ),
]);

final Animation<Color?> farbAnimation = farbSequenz.animate(_controller);
```

### CurvedAnimation

Fügt eine Beschleunigungskurve zur Animation hinzu:

```dart
late AnimationController _controller;
late Animation<double> _animation;

@override
void initState() {
  super.initState();
  _controller = AnimationController(
    duration: const Duration(milliseconds: 800),
    vsync: this,
  );

  // CurvedAnimation wraps den Controller
  final curvedAnimation = CurvedAnimation(
    parent: _controller,
    curve: Curves.bounceOut,        // Kurve für forward()
    reverseCurve: Curves.easeIn,    // Kurve für reverse() (optional)
  );

  // Tween mit CurvedAnimation verbinden
  _animation = Tween<double>(begin: 0, end: 300).animate(curvedAnimation);
}
```

### AnimatedBuilder

`AnimatedBuilder` ist der empfohlene Weg, explizite Animationen im Widget-Tree darzustellen. Es baut nur den animierten Teil neu, nicht das gesamte Widget.

```dart
class RotierendesLogo extends StatefulWidget {
  const RotierendesLogo({super.key});

  @override
  State<RotierendesLogo> createState() => _RotierendesLogoState();
}

class _RotierendesLogoState extends State<RotierendesLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // Endlos drehen

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159, // 360 Grad in Radian
    ).animate(_controller);

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller, // Reagiert auf jeden Frame-Update
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child, // child wird NICHT neu gebaut!
          ),
        );
      },
      // Das child wird einmal gebaut und an den builder übergeben.
      // So wird das FlutterLogo nicht bei jedem Frame neu erstellt.
      child: const FlutterLogo(size: 80),
    );
  }
}
```

**Performance-Tipp:** Übergib statische Widgets als `child` an `AnimatedBuilder`. Sie werden nur einmal gebaut und bei jedem Frame wiederverwendet.

### AnimatedWidget

Alternative zu `AnimatedBuilder` -- eine eigene Widget-Klasse für die Animation:

```dart
class PulsierenderKreis extends AnimatedWidget {
  const PulsierenderKreis({
    super.key,
    required Animation<double> animation,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      width: animation.value,
      height: animation.value,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
    );
  }
}

// Verwendung:
// PulsierenderKreis(animation: _sizeAnimation)
```

### Vollständiges Beispiel: Animierter Button

```dart
class AnimierterButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const AnimierterButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  State<AnimierterButton> createState() => _AnimierterButtonState();
}

class _AnimierterButtonState extends State<AnimierterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _farbAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _farbAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.blue.shade700,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: _farbAnimation.value,
                borderRadius: BorderRadius.circular(12),
              ),
              child: child,
            ),
          );
        },
        child: Text(
          widget.text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
```

### Stagger-Animationen (Gestaffelte Animationen)

Mehrere Animationen laufen versetzt über denselben Controller, indem du `Interval` als Kurve verwendest:

```dart
class StaggerDemo extends StatefulWidget {
  const StaggerDemo({super.key});

  @override
  State<StaggerDemo> createState() => _StaggerDemoState();
}

class _StaggerDemoState extends State<StaggerDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Phase 1: Einblenden (0% - 25% der Gesamtdauer)
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Phase 2: Hochschieben (25% - 50%)
    _slideAnimation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.5, curve: Curves.easeOut),
      ),
    );

    // Phase 3: Skalieren (50% - 75%)
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.75, curve: Curves.elasticOut),
      ),
    );

    // Phase 4: Farbe ändern (75% - 100%)
    _colorAnimation = ColorTween(
      begin: Colors.grey,
      end: Colors.blue,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.75, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            _controller.reset();
            _controller.forward();
          },
          child: const Text('Animation starten'),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: Offset(0, _slideAnimation.value),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: _colorAnimation.value,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.star, color: Colors.white, size: 48),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
```

**Vergleich zu CSS:**
```css
/* CSS Stagger-Animation */
@keyframes stagger {
  0%   { opacity: 0; }
  25%  { opacity: 1; transform: translateY(100px); }
  50%  { transform: translateY(0); }
  75%  { transform: scale(1); }
  100% { background: blue; }
}
```

Die Flutter-Variante mit `Interval` ist präziser, weil jede Eigenschaft ihren eigenen Zeitbereich und Kurve hat.

---

## 13.4 Hero-Animationen (Page Transitions)

Hero-Animationen erstellen fließende Übergänge zwischen zwei Screens. Das "Hero"-Widget fliegt visuell von seiner Position auf Screen A zu seiner Position auf Screen B.

```dart
// Screen A: Produktliste
class ProduktListe extends StatelessWidget {
  const ProduktListe({super.key});

  @override
  Widget build(BuildContext context) {
    final produkte = [
      {'id': '1', 'name': 'Laptop', 'bild': 'assets/laptop.png'},
      {'id': '2', 'name': 'Handy', 'bild': 'assets/handy.png'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Produkte')),
      body: ListView.builder(
        itemCount: produkte.length,
        itemBuilder: (context, index) {
          final produkt = produkte[index];
          return ListTile(
            leading: Hero(
              tag: 'produkt-${produkt['id']}', // Eindeutiger Tag!
              child: CircleAvatar(
                backgroundImage: AssetImage(produkt['bild']!),
              ),
            ),
            title: Text(produkt['name']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProduktDetail(produkt: produkt),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// Screen B: Produktdetail
class ProduktDetail extends StatelessWidget {
  final Map<String, String> produkt;

  const ProduktDetail({super.key, required this.produkt});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(produkt['name']!)),
      body: Column(
        children: [
          Hero(
            tag: 'produkt-${produkt['id']}', // Gleicher Tag wie auf Screen A!
            child: Image.asset(
              produkt['bild']!,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Details zu ${produkt['name']}',
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Wichtige Regeln für Hero-Animationen:**
1. Beide `Hero`-Widgets müssen den **gleichen `tag`** haben.
2. Der `tag` muss **eindeutig** innerhalb eines Screens sein.
3. Die Animation funktioniert nur bei **Page Transitions** (Navigator.push/pop).
4. Das `child` darf unterschiedlich sein (z.B. klein auf Screen A, groß auf Screen B).

### Hero mit CustomRectTween

```dart
Hero(
  tag: 'meinHero',
  // Benutzerdefinierte Flugbahn
  createRectTween: (begin, end) {
    return MaterialRectCenterArcTween(begin: begin, end: end);
  },
  // Benutzerdefinierter Übergang-Placeholder
  placeholderBuilder: (context, size, child) {
    return Container(
      width: size.width,
      height: size.height,
      color: Colors.grey.shade200,
    );
  },
  child: const FlutterLogo(size: 50),
)
```

---

## 13.5 AnimatedList

`AnimatedList` animiert das Hinzufügen und Entfernen von Items automatisch -- viel eleganter als eine normale `ListView`.

```dart
class AnimierteListe extends StatefulWidget {
  const AnimierteListe({super.key});

  @override
  State<AnimierteListe> createState() => _AnimierteListeState();
}

class _AnimierteListeState extends State<AnimierteListe> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _items = <String>['Apfel', 'Banane', 'Kirsche'];
  int _naechsteId = 3;

  void _itemHinzufuegen() {
    final index = _items.length;
    _items.add('Frucht $_naechsteId');
    _naechsteId++;
    // AnimatedList über das neue Item informieren
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 500),
    );
  }

  void _itemEntfernen(int index) {
    final entferntesItem = _items.removeAt(index);
    // AnimatedList über das entfernte Item informieren
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(entferntesItem, animation),
      duration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildItem(String item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                final index = _items.indexOf(item);
                if (index != -1) _itemEntfernen(index);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Animierte Liste')),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          return _buildItem(_items[index], animation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _itemHinzufuegen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Tipp:** Für noch schönere Animationen kannst du `SlideTransition`, `ScaleTransition` oder eigene Transitions statt `SizeTransition` verwenden.

---

## 13.6 Lottie-Animationen einbinden

Lottie ist ein Format für hochwertige, vektorbasierte Animationen, die mit Adobe After Effects oder online erstellt werden. Tausende kostenlose Animationen findest du auf [lottiefiles.com](https://lottiefiles.com).

### Setup

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.1.0
```

### Verwendung

```dart
import 'package:lottie/lottie.dart';

class LottieDemo extends StatelessWidget {
  const LottieDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Aus dem Asset-Ordner laden
        Lottie.asset(
          'assets/animations/loading.json',
          width: 200,
          height: 200,
          fit: BoxFit.contain,
        ),

        // Aus dem Netzwerk laden
        Lottie.network(
          'https://lottie.host/beispiel/animation.json',
          width: 150,
          height: 150,
        ),
      ],
    );
  }
}
```

### Lottie mit Controller steuern

```dart
class GesteuerterLottie extends StatefulWidget {
  const GesteuerterLottie({super.key});

  @override
  State<GesteuerterLottie> createState() => _GesteuerterLottieState();
}

class _GesteuerterLottieState extends State<GesteuerterLottie>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Lottie.asset(
          'assets/animations/checkmark.json',
          controller: _controller,
          width: 200,
          height: 200,
          onLoaded: (composition) {
            // Animation-Dauer an die Lottie-Datei anpassen
            _controller.duration = composition.duration;
          },
        ),
        ElevatedButton(
          onPressed: () {
            _controller.reset();
            _controller.forward(); // Einmal abspielen
          },
          child: const Text('Abspielen'),
        ),
      ],
    );
  }
}
```

### Assets registrieren

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/animations/
```

---

## 13.7 CustomPainter mit Animationen

Für vollständig benutzerdefinierte Zeichnungen, die animiert werden:

```dart
class AnimierterKreis extends StatefulWidget {
  const AnimierterKreis({super.key});

  @override
  State<AnimierterKreis> createState() => _AnimierterKreisState();
}

class _AnimierterKreisState extends State<AnimierterKreis>
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
        return CustomPaint(
          size: const Size(200, 200),
          painter: KreisPainter(fortschritt: _controller.value),
        );
      },
    );
  }
}

class KreisPainter extends CustomPainter {
  final double fortschritt;

  KreisPainter({required this.fortschritt});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Hintergrundkreis
    final hintergrundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius - 4, hintergrundPaint);

    // Fortschrittskreis
    final fortschrittPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -3.14159 / 2, // Start oben
      2 * 3.14159 * fortschritt, // Wie viel des Kreises gezeichnet wird
      false,
      fortschrittPaint,
    );

    // Prozenttext
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(fortschritt * 100).toInt()}%',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(KreisPainter oldDelegate) {
    return oldDelegate.fortschritt != fortschritt;
  }
}
```

---

## 13.8 Performance-Tipps

### RepaintBoundary

`RepaintBoundary` isoliert einen Teil des Widget-Trees, sodass er unabhängig vom Rest neu gezeichnet werden kann:

```dart
// Ohne RepaintBoundary: Die Animation löst ein Repaint des
// gesamten umgebenden Widget-Trees aus.

// Mit RepaintBoundary: Nur der animierte Bereich wird neu gezeichnet.
RepaintBoundary(
  child: AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      return Transform.rotate(
        angle: _controller.value * 2 * 3.14159,
        child: child,
      );
    },
    child: const FlutterLogo(size: 100),
  ),
)
```

### Weitere Performance-Tipps

```dart
// 1. child-Parameter von AnimatedBuilder nutzen
// SCHLECHT: Widget wird bei jedem Frame neu erstellt
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: const ExpensiveWidget(), // Wird jedes Mal neu gebaut!
    );
  },
);

// GUT: Widget wird einmal gebaut und wiederverwendet
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.scale(
      scale: _controller.value,
      child: child, // Wird wiederverwendet!
    );
  },
  child: const ExpensiveWidget(), // Nur einmal gebaut
);

// 2. AnimationController disposen
@override
void dispose() {
  _controller.dispose(); // Verhindert Memory Leaks
  super.dispose();
}

// 3. Animationen nur laufen lassen, wenn nötig
// Der Controller wird automatisch pausiert, wenn das Widget
// nicht sichtbar ist (dank vsync), aber du solltest
// lang laufende Animationen explizit stoppen.

// 4. Vermeide setState() für Animationen
// SCHLECHT: setState() baut das gesamte Widget neu
_controller.addListener(() {
  setState(() {}); // Unnötig wenn AnimatedBuilder verwendet wird
});

// GUT: AnimatedBuilder reagiert automatisch auf Änderungen
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) { ... },
)
```

### Debug-Werkzeuge

```dart
// In main.dart oder über DevTools:
// debugProfileBuildsEnabled = true;  // Zeigt langsame Builds
// debugRepaintRainbowEnabled = true; // Zeigt Repaints als Regenbogenfarben
```

---

## 13.9 Vergleich zu CSS Animations/Transitions

| Konzept | CSS | Flutter |
|---------|-----|---------|
| Einfacher Übergang | `transition: property duration curve` | `AnimatedContainer(duration, curve)` |
| Keyframe-Animation | `@keyframes { 0% {...} 100% {...} }` | `AnimationController` + `Tween` |
| Beschleunigungskurve | `ease-in-out`, `cubic-bezier()` | `Curves.easeInOut`, `Cubic()` |
| Wiederholung | `animation-iteration-count: infinite` | `controller.repeat()` |
| Verzögerung | `animation-delay: 500ms` | `Future.delayed()` oder `Interval` |
| Mehrere Phasen | `@keyframes { 0%{} 50%{} 100%{} }` | `TweenSequence` oder `Interval` |
| Gestaffelt | `.item:nth-child(n) { delay: n*100ms }` | `Interval` mit verschiedenen Bereichen |
| Seitenwechsel | View Transitions API | `Hero` Widget |
| GPU-Beschleunigung | `will-change: transform` | Automatisch (Skia/Impeller Engine) |

**Vorteil Flutter:** Animationen laufen bei 60/120fps nativ -- kein Jank durch JavaScript-Main-Thread-Blockierung wie im Browser.

---

## 13.10 Zusammenfassung

```
Implizite Animationen (einfach):
├── AnimatedContainer    → Größe, Farbe, Decoration
├── AnimatedOpacity      → Transparenz
├── AnimatedPositioned   → Position im Stack
├── AnimatedCrossFade    → Überblendung zweier Widgets
├── AnimatedSwitcher     → Widget-Wechsel (Key beachten!)
└── AnimatedDefaultTextStyle → Textstil

Explizite Animationen (volle Kontrolle):
├── AnimationController  → Steuerung (forward, reverse, repeat)
├── Tween               → Wertebereich (begin → end)
├── CurvedAnimation     → Beschleunigungskurve
├── AnimatedBuilder     → Widget-Tree-Integration (bevorzugt)
├── AnimatedWidget      → Eigene Widget-Klasse
├── TweenSequence       → Mehrphasige Animation
└── Interval            → Stagger-Animationen

Spezielle Animationen:
├── Hero                → Page-Transition-Animation
├── AnimatedList        → Listen-Items animiert hinzufügen/entfernen
├── Lottie              → Hochwertige After-Effects-Animationen
└── CustomPainter       → Vollständig benutzerdefinierte Animationen
```
