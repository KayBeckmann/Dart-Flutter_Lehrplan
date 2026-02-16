# Lösung 4.2: Explizite Animationen

## Aufgabe 1: Pulsing Button

```dart
class PulsingButton extends StatefulWidget {
  const PulsingButton({super.key});

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _shadowAnimation = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: _shadowAnimation.value,
                      spreadRadius: _shadowAnimation.value / 4,
                    ),
                  ],
                ),
                child: const Text(
                  'Pulse!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _controller.repeat(reverse: true),
              child: const Text('Start'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _controller.stop(),
              child: const Text('Stop'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _controller.reset(),
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Aufgabe 2: Loading Spinner

```dart
class BouncingDotsLoader extends StatefulWidget {
  const BouncingDotsLoader({super.key});

  @override
  State<BouncingDotsLoader> createState() => _BouncingDotsLoaderState();
}

class _BouncingDotsLoaderState extends State<BouncingDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // Staggered animations für 3 Dots
    for (int i = 0; i < 3; i++) {
      final start = i * 0.15;
      final end = start + 0.4;
      _animations.add(
        Tween<double>(begin: 0, end: -20).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end.clamp(0, 1), curve: Curves.easeInOut),
          ),
        ),
      );
    }
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Transform.translate(
                    offset: Offset(0, _animations[index].value),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.blue[400 + (index * 200)],
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
        const SizedBox(height: 24),
        const Text(
          'Loading...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 3: Flip Card

```dart
class FlipCard extends StatefulWidget {
  final String question;
  final String answer;

  const FlipCard({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _showFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      if (_controller.value >= 0.5 && _showFront) {
        setState(() => _showFront = false);
      } else if (_controller.value < 0.5 && !_showFront) {
        setState(() => _showFront = true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flip() {
    if (_controller.status == AnimationStatus.completed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Berechne Rotation (0 bis pi)
          final angle = _animation.value * 3.14159;
          // Spiegle die Rückseite
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)  // Perspektive
            ..rotateY(angle);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: _showFront
                ? _buildCardFace(
                    widget.question,
                    Icons.help_outline,
                    Colors.blue,
                  )
                : Transform(
                    transform: Matrix4.identity()..rotateY(3.14159),
                    alignment: Alignment.center,
                    child: _buildCardFace(
                      widget.answer,
                      Icons.lightbulb_outline,
                      Colors.green,
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace(String text, IconData icon, Color color) {
    return Container(
      width: 250,
      height: 350,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tap to flip',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 4: Staggered List

```dart
class StaggeredNotificationList extends StatefulWidget {
  const StaggeredNotificationList({super.key});

  @override
  State<StaggeredNotificationList> createState() =>
      _StaggeredNotificationListState();
}

class _StaggeredNotificationListState extends State<StaggeredNotificationList>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _items = [
    ('📧', 'Neue Nachricht', 'Von Max Mustermann'),
    ('🔔', 'Erinnerung', 'Meeting in 30 Minuten'),
    ('📦', 'Paket versendet', 'Ankunft morgen'),
    ('💬', 'Kommentar', 'Auf deinen Beitrag'),
    ('❤️', 'Gefällt mir', '5 neue Likes'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: _replay,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final intervalStart = index * 0.1;
          final intervalEnd = (intervalStart + 0.4).clamp(0.0, 1.0);

          final slideAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(intervalStart, intervalEnd,
                  curve: Curves.easeOutCubic),
            ),
          );

          final fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(intervalStart, intervalEnd),
            ),
          );

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: fadeAnimation,
                child: SlideTransition(
                  position: slideAnimation,
                  child: child,
                ),
              );
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Text(_items[index].$1, style: const TextStyle(fontSize: 24)),
                title: Text(_items[index].$2),
                subtitle: Text(_items[index].$3),
                trailing: const Icon(Icons.chevron_right),
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

## Aufgabe 5: Hero Gallery

```dart
// Grid Screen
class HeroGalleryGrid extends StatelessWidget {
  const HeroGalleryGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery')),
      body: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          final color = Colors.primaries[index % Colors.primaries.length];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HeroGalleryDetail(
                    index: index,
                    color: color,
                  ),
                ),
              );
            },
            child: Hero(
              tag: 'image-$index',
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Detail Screen
class HeroGalleryDetail extends StatelessWidget {
  final int index;
  final Color color;

  const HeroGalleryDetail({
    super.key,
    required this.index,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Bild ${index + 1}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Hero(
                tag: 'image-$index',
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Beschreibung für Bild ${index + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 6: Animated Counter

```dart
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({super.key});

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  int _count = 0;

  void _increment() {
    if (_count < 9999) {
      setState(() => _count++);
    }
  }

  void _decrement() {
    if (_count > 0) {
      setState(() => _count--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final digits = _count.toString().padLeft(4, '0').split('');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: digits.map((digit) {
              return _AnimatedDigit(digit: int.parse(digit));
            }).toList(),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              onPressed: _decrement,
              heroTag: 'minus',
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 32),
            FloatingActionButton(
              onPressed: _increment,
              heroTag: 'plus',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedDigit extends StatelessWidget {
  final int digit;

  const _AnimatedDigit({required this.digit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          final inAnimation = Tween<Offset>(
            begin: const Offset(0, -1),
            end: Offset.zero,
          ).animate(animation);

          return ClipRect(
            child: SlideTransition(
              position: inAnimation,
              child: child,
            ),
          );
        },
        child: Text(
          '$digit',
          key: ValueKey(digit),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
```

---

## Aufgabe 7: Lottie Integration

```dart
import 'package:lottie/lottie.dart';

class LottieDemo extends StatefulWidget {
  const LottieDemo({super.key});

  @override
  State<LottieDemo> createState() => _LottieDemoState();
}

class _LottieDemoState extends State<LottieDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isLooping = false;
  double _speed = 1.0;

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

  void _toggleLoop() {
    setState(() => _isLooping = !_isLooping);
    if (_isLooping) {
      _controller.repeat();
    } else {
      _controller.stop();
    }
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    // Duration anpassen
    if (_controller.duration != null) {
      _controller.duration = Duration(
        milliseconds: (_controller.duration!.inMilliseconds / speed).round(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.network(
          'https://assets5.lottiefiles.com/packages/lf20_V9t630.json',
          controller: _controller,
          width: 200,
          height: 200,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
          },
        ),
        const SizedBox(height: 24),

        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _controller.forward(),
              tooltip: 'Play',
            ),
            IconButton(
              icon: const Icon(Icons.pause),
              onPressed: () => _controller.stop(),
              tooltip: 'Pause',
            ),
            IconButton(
              icon: const Icon(Icons.replay),
              onPressed: () {
                _controller.reset();
                _controller.forward();
              },
              tooltip: 'Replay',
            ),
            IconButton(
              icon: Icon(_isLooping ? Icons.repeat_on : Icons.repeat),
              onPressed: _toggleLoop,
              tooltip: 'Loop',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Column(
                children: [
                  LinearProgressIndicator(value: _controller.value),
                  const SizedBox(height: 8),
                  Text('${(_controller.value * 100).toInt()}%'),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Speed Controls
        const Text('Speed:'),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [0.5, 1.0, 2.0].map((speed) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text('${speed}x'),
                selected: _speed == speed,
                onSelected: (_) => _setSpeed(speed),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 8: Animated Menu

```dart
class RadialMenu extends StatefulWidget {
  const RadialMenu({super.key});

  @override
  State<RadialMenu> createState() => _RadialMenuState();
}

class _RadialMenuState extends State<RadialMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  final _menuItems = [
    (Icons.camera_alt, Colors.red),
    (Icons.folder, Colors.orange),
    (Icons.link, Colors.yellow),
    (Icons.edit, Colors.green),
    (Icons.save, Colors.blue),
    (Icons.share, Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Menu Items
          ...List.generate(_menuItems.length, (index) {
            final angle = (index * 60 - 90) * 3.14159 / 180;
            final radius = 80.0;

            final intervalStart = index * 0.1;
            final intervalEnd = (intervalStart + 0.4).clamp(0.0, 1.0);

            final animation = CurvedAnimation(
              parent: _controller,
              curve: Interval(intervalStart, intervalEnd,
                  curve: Curves.easeOutBack),
            );

            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final x = animation.value * radius * cos(angle);
                final y = animation.value * radius * sin(angle);

                return Transform.translate(
                  offset: Offset(x, y),
                  child: Transform.scale(
                    scale: animation.value,
                    child: child,
                  ),
                );
              },
              child: FloatingActionButton(
                heroTag: 'menu-$index',
                mini: true,
                backgroundColor: _menuItems[index].$2,
                onPressed: () {
                  _toggle();
                  // Handle action
                },
                child: Icon(_menuItems[index].$1, size: 20),
              ),
            );
          }),

          // Main Button
          FloatingActionButton(
            onPressed: _toggle,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * 0.75 * 3.14159,
                  child: Icon(_isOpen ? Icons.close : Icons.add),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Import für cos/sin
import 'dart:math';
```
