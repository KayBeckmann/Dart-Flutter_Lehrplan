# Einheit 4.2: Explizite Animationen

## Lernziele

Nach dieser Einheit kannst du:
- `AnimationController` erstellen und steuern
- `Tween` und `CurvedAnimation` nutzen
- `AnimatedBuilder` und `AnimatedWidget` einsetzen
- Hero-Animationen implementieren
- Lottie-Animationen einbinden

---

## 1. AnimationController

### Grundlagen

```dart
class ExplicitAnimationDemo extends StatefulWidget {
  const ExplicitAnimationDemo({super.key});

  @override
  State<ExplicitAnimationDemo> createState() => _ExplicitAnimationDemoState();
}

class _ExplicitAnimationDemoState extends State<ExplicitAnimationDemo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,  // TickerProvider für Performance
    );
  }

  @override
  void dispose() {
    _controller.dispose();  // Wichtig: Immer disposen!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animation anzeigen
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.rotate(
              angle: _controller.value * 2 * 3.14159,
              child: child,
            );
          },
          child: const FlutterLogo(size: 100),
        ),
        const SizedBox(height: 32),

        // Steuerung
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _controller.forward(),
              child: const Text('Forward'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _controller.reverse(),
              child: const Text('Reverse'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _controller.repeat(),
              child: const Text('Repeat'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _controller.stop(),
              child: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### AnimationController Methoden

```dart
// Vorwärts abspielen (0 → 1)
_controller.forward();

// Rückwärts abspielen (1 → 0)
_controller.reverse();

// Von Anfang starten
_controller.forward(from: 0.0);

// Wiederholen
_controller.repeat();

// Hin und her wiederholen
_controller.repeat(reverse: true);

// Stoppen
_controller.stop();

// Zurücksetzen
_controller.reset();

// Direkt auf Wert setzen
_controller.value = 0.5;

// Zu Wert animieren
_controller.animateTo(0.75);

// Status abfragen
_controller.status;  // AnimationStatus.forward, .reverse, .completed, .dismissed

// Listener
_controller.addListener(() {
  print('Value: ${_controller.value}');
});

_controller.addStatusListener((status) {
  if (status == AnimationStatus.completed) {
    print('Animation fertig!');
  }
});
```

### Multiple Controller (TickerProviderStateMixin)

```dart
class MultipleAnimations extends StatefulWidget {
  const MultipleAnimations({super.key});

  @override
  State<MultipleAnimations> createState() => _MultipleAnimationsState();
}

class _MultipleAnimationsState extends State<MultipleAnimations>
    with TickerProviderStateMixin {  // Nicht SingleTickerProvider!

  late AnimationController _controller1;
  late AnimationController _controller2;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _controller2 = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    super.dispose();
  }

  // ...
}
```

---

## 2. Tween

### Grundlagen

```dart
// Tween definiert Start- und Endwert
final sizeTween = Tween<double>(begin: 50, end: 200);

// Animation erstellen
final sizeAnimation = sizeTween.animate(_controller);

// Wert abrufen
print(sizeAnimation.value);  // Interpolierter Wert
```

### Verschiedene Tween-Typen

```dart
// Double
Tween<double>(begin: 0, end: 100);

// Color
ColorTween(begin: Colors.red, end: Colors.blue);

// Offset (für Bewegung)
Tween<Offset>(begin: Offset.zero, end: const Offset(100, 50));

// Size
SizeTween(begin: const Size(50, 50), end: const Size(200, 200));

// Rect
RectTween(
  begin: const Rect.fromLTWH(0, 0, 50, 50),
  end: const Rect.fromLTWH(100, 100, 200, 200),
);

// Int
IntTween(begin: 0, end: 100);

// BorderRadius
BorderRadiusTween(
  begin: BorderRadius.circular(0),
  end: BorderRadius.circular(50),
);

// Decoration
DecorationTween(
  begin: const BoxDecoration(color: Colors.red),
  end: const BoxDecoration(color: Colors.blue),
);

// EdgeInsets
EdgeInsetsTween(
  begin: const EdgeInsets.all(0),
  end: const EdgeInsets.all(32),
);
```

### Tween-Ketten

```dart
class ChainedAnimation extends StatefulWidget {
  const ChainedAnimation({super.key});

  @override
  State<ChainedAnimation> createState() => _ChainedAnimationState();
}

class _ChainedAnimationState extends State<ChainedAnimation>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _sizeAnimation;
  late Animation<Color?> _colorAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Verschiedene Tweens mit demselben Controller
    _sizeAnimation = Tween<double>(begin: 50, end: 200).animate(_controller);

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.blue,
    ).animate(_controller);

    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
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
      onTap: () {
        if (_controller.status == AnimationStatus.completed) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value,
            child: Container(
              width: _sizeAnimation.value,
              height: _sizeAnimation.value,
              color: _colorAnimation.value,
            ),
          );
        },
      ),
    );
  }
}
```

---

## 3. CurvedAnimation

### Curves anwenden

```dart
class CurvedAnimationDemo extends StatefulWidget {
  const CurvedAnimationDemo({super.key});

  @override
  State<CurvedAnimationDemo> createState() => _CurvedAnimationDemoState();
}

class _CurvedAnimationDemoState extends State<CurvedAnimationDemo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    // CurvedAnimation für nicht-lineare Bewegung
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,  // Andere Curve beim Rückwärts
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: child,
        );
      },
      child: const FlutterLogo(size: 100),
    );
  }
}
```

### Tween mit Curve kombinieren

```dart
// Methode 1: CurvedAnimation
final curvedAnimation = CurvedAnimation(
  parent: _controller,
  curve: Curves.bounceOut,
);
final sizeAnimation = Tween<double>(begin: 0, end: 200).animate(curvedAnimation);

// Methode 2: chain()
final sizeAnimation = Tween<double>(begin: 0, end: 200)
    .chain(CurveTween(curve: Curves.bounceOut))
    .animate(_controller);
```

---

## 4. AnimatedBuilder vs AnimatedWidget

### AnimatedBuilder

```dart
// Gut für einmalige Verwendung
AnimatedBuilder(
  animation: _controller,
  builder: (context, child) {
    return Transform.rotate(
      angle: _controller.value * 2 * 3.14159,
      child: child,  // child wird nicht rebuildet!
    );
  },
  child: const FlutterLogo(size: 100),  // Optimierung
)
```

### AnimatedWidget (für Wiederverwendung)

```dart
// Eigenes animiertes Widget erstellen
class SpinningLogo extends AnimatedWidget {
  const SpinningLogo({
    super.key,
    required Animation<double> animation,
  }) : super(listenable: animation);

  Animation<double> get _animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: _animation.value * 2 * 3.14159,
      child: const FlutterLogo(size: 100),
    );
  }
}

// Verwendung
SpinningLogo(animation: _controller)
```

### Custom Animated Widget mit Tween

```dart
class PulsingCircle extends AnimatedWidget {
  final Color color;

  const PulsingCircle({
    super.key,
    required Animation<double> animation,
    required this.color,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    return Container(
      width: 50 + (animation.value * 20),
      height: 50 + (animation.value * 20),
      decoration: BoxDecoration(
        color: color.withOpacity(1 - animation.value * 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
```

---

## 5. Staggered Animations

### Sequentielle Animationen

```dart
class StaggeredDemo extends StatefulWidget {
  const StaggeredDemo({super.key});

  @override
  State<StaggeredDemo> createState() => _StaggeredDemoState();
}

class _StaggeredDemoState extends State<StaggeredDemo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _width;
  late Animation<double> _height;
  late Animation<EdgeInsets> _padding;
  late Animation<BorderRadius?> _borderRadius;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Staggered: Verschiedene Intervalle
    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _width = Tween<double>(begin: 50, end: 200).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.4, curve: Curves.easeOut),
      ),
    );

    _height = Tween<double>(begin: 50, end: 200).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.6, curve: Curves.easeOut),
      ),
    );

    _padding = EdgeInsetsTween(
      begin: const EdgeInsets.all(0),
      end: const EdgeInsets.all(16),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.8, curve: Curves.easeOut),
      ),
    );

    _borderRadius = BorderRadiusTween(
      begin: BorderRadius.circular(0),
      end: BorderRadius.circular(50),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
      ),
    );

    _color = ColorTween(begin: Colors.blue, end: Colors.purple).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0),  // Über gesamte Dauer
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
    return GestureDetector(
      onTap: () {
        if (_controller.status == AnimationStatus.completed) {
          _controller.reverse();
        } else {
          _controller.forward();
        }
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacity.value,
            child: Container(
              width: _width.value,
              height: _height.value,
              padding: _padding.value,
              decoration: BoxDecoration(
                color: _color.value,
                borderRadius: _borderRadius.value,
              ),
              child: const Center(
                child: Text(
                  'Tap me',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

---

## 6. Hero Animations

### Basic Hero

```dart
// Screen 1 (Liste)
class ProductListScreen extends StatelessWidget {
  final products = ['Product 1', 'Product 2', 'Product 3'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    productId: index,
                    productName: products[index],
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'product-$index',  // Eindeutiger Tag!
              child: Card(
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    color: Colors.blue[100 * (index + 1)],
                  ),
                  title: Text(products[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Screen 2 (Detail)
class ProductDetailScreen extends StatelessWidget {
  final int productId;
  final String productName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(productName)),
      body: Column(
        children: [
          Hero(
            tag: 'product-$productId',  // Gleicher Tag!
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.blue[100 * (productId + 1)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              productName,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Hero mit Custom Flight

```dart
Hero(
  tag: 'avatar',
  flightShuttleBuilder: (
    flightContext,
    animation,
    flightDirection,
    fromHeroContext,
    toHeroContext,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.rotate(
          angle: animation.value * 2 * 3.14159,
          child: fromHeroContext.widget,
        );
      },
    );
  },
  child: const CircleAvatar(
    radius: 30,
    child: Icon(Icons.person),
  ),
)
```

---

## 7. Lottie Animationen

### Setup

```yaml
# pubspec.yaml
dependencies:
  lottie: ^3.0.0
```

### Basis-Verwendung

```dart
import 'package:lottie/lottie.dart';

// Aus Assets
Lottie.asset('assets/animations/loading.json')

// Aus Netzwerk
Lottie.network('https://example.com/animation.json')

// Mit Optionen
Lottie.asset(
  'assets/animations/success.json',
  width: 200,
  height: 200,
  fit: BoxFit.contain,
  repeat: false,  // Nur einmal abspielen
  reverse: true,  // Rückwärts
  animate: true,  // Auto-start
)
```

### Mit Controller

```dart
class LottieControllerDemo extends StatefulWidget {
  const LottieControllerDemo({super.key});

  @override
  State<LottieControllerDemo> createState() => _LottieControllerDemoState();
}

class _LottieControllerDemoState extends State<LottieControllerDemo>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset(
          'assets/animations/heart.json',
          controller: _controller,
          onLoaded: (composition) {
            // Duration aus Lottie-Datei übernehmen
            _controller.duration = composition.duration;
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _controller.forward(),
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _controller.stop(),
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () => _controller.reset(),
            ),
            IconButton(
              icon: const Icon(Icons.repeat),
              onPressed: () => _controller.repeat(),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Lottie als Button

```dart
class LikeButton extends StatefulWidget {
  const LikeButton({super.key});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleLike() {
    setState(() => _isLiked = !_isLiked);

    if (_isLiked) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleLike,
      child: Lottie.asset(
        'assets/animations/like.json',
        controller: _controller,
        width: 60,
        height: 60,
        onLoaded: (composition) {
          _controller.duration = composition.duration;
        },
      ),
    );
  }
}
```

---

## 8. Praktisches Beispiel: Animated Drawer

```dart
class AnimatedDrawer extends StatefulWidget {
  const AnimatedDrawer({super.key});

  @override
  State<AnimatedDrawer> createState() => _AnimatedDrawerState();
}

class _AnimatedDrawerState extends State<AnimatedDrawer>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -280, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 1, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Drawer
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnimation.value, 0),
                child: child,
              );
            },
            child: Container(
              width: 280,
              color: Colors.blue[800],
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Menu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _menuItem(Icons.home, 'Home'),
                    _menuItem(Icons.person, 'Profile'),
                    _menuItem(Icons.settings, 'Settings'),
                    _menuItem(Icons.logout, 'Logout'),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnimation.value + 280, 0),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.centerLeft,
                  child: child,
                ),
              );
            },
            child: GestureDetector(
              onTap: _isOpen ? _toggleDrawer : null,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! > 0 && !_isOpen) {
                  _toggleDrawer();
                } else if (details.primaryVelocity! < 0 && _isOpen) {
                  _toggleDrawer();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(_isOpen ? 20 : 0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: AnimatedIcon(
                        icon: AnimatedIcons.menu_close,
                        progress: _controller,
                      ),
                      onPressed: _toggleDrawer,
                    ),
                    title: const Text('Animated Drawer'),
                  ),
                  body: const Center(
                    child: Text('Main Content'),
                  ),
                ),
              ),
            ),
          ),

          // Overlay
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return IgnorePointer(
                ignoring: !_isOpen,
                child: Container(
                  color: Colors.black.withOpacity(_fadeAnimation.value),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: _toggleDrawer,
    );
  }
}
```

---

## Zusammenfassung

| Konzept | Verwendung |
|---------|------------|
| `AnimationController` | Steuert Animation (start, stop, repeat) |
| `Tween` | Definiert Wertebereich (begin → end) |
| `CurvedAnimation` | Fügt Easing/Curves hinzu |
| `AnimatedBuilder` | Rebuildet nur animierten Teil |
| `AnimatedWidget` | Wiederverwendbare animierte Widgets |
| `Interval` | Staggered Animations |
| `Hero` | Shared Element Transitions |
| `Lottie` | After Effects Animationen |

**Best Practices:**
- Immer `dispose()` für Controller
- `SingleTickerProviderStateMixin` für einen Controller
- `TickerProviderStateMixin` für mehrere Controller
- `child`-Parameter in AnimatedBuilder für Performance
- Hero-Tags müssen eindeutig sein
