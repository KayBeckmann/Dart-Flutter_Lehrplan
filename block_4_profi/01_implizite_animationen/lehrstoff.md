# Einheit 4.1: Implizite Animationen

## Lernziele

Nach dieser Einheit kannst du:
- Implizite Animationen verstehen und einsetzen
- `AnimatedContainer` und andere Animated-Widgets nutzen
- `AnimatedSwitcher` für Widget-Übergänge verwenden
- `TweenAnimationBuilder` für Custom-Animationen einsetzen

---

## 1. Was sind implizite Animationen?

### Implizit vs. Explizit

| Typ | Beschreibung | Kontrolle |
|-----|--------------|-----------|
| **Implizit** | Animation startet automatisch bei Property-Änderung | Wenig (duration, curve) |
| **Explizit** | Volle Kontrolle über Start, Stop, Wiederholung | Voll (AnimationController) |

**Faustregel:** Beginne mit impliziten Animationen. Wechsle zu expliziten nur bei komplexen Anforderungen.

---

## 2. AnimatedContainer

### Basis-Beispiel

```dart
class AnimatedContainerDemo extends StatefulWidget {
  const AnimatedContainerDemo({super.key});

  @override
  State<AnimatedContainerDemo> createState() => _AnimatedContainerDemoState();
}

class _AnimatedContainerDemoState extends State<AnimatedContainerDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: _expanded ? 200 : 100,
        height: _expanded ? 200 : 100,
        decoration: BoxDecoration(
          color: _expanded ? Colors.blue : Colors.red,
          borderRadius: BorderRadius.circular(_expanded ? 100 : 8),
        ),
        child: const Center(
          child: Text('Tap me', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
```

### Animierbare Properties

`AnimatedContainer` animiert automatisch:
- `width`, `height`
- `color` (über decoration)
- `padding`, `margin`
- `alignment`
- `transform`
- `borderRadius` (über decoration)

```dart
AnimatedContainer(
  duration: const Duration(milliseconds: 500),
  curve: Curves.elasticOut,
  width: _width,
  height: _height,
  padding: EdgeInsets.all(_padding),
  margin: EdgeInsets.all(_margin),
  alignment: _alignment,
  transform: Matrix4.rotationZ(_rotation),
  decoration: BoxDecoration(
    color: _color,
    borderRadius: BorderRadius.circular(_radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black26,
        blurRadius: _shadowBlur,
        offset: Offset(0, _shadowOffset),
      ),
    ],
  ),
  child: child,
)
```

---

## 3. Weitere Animated-Widgets

### AnimatedOpacity

```dart
AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: _visible ? 1.0 : 0.0,
  child: const Text('Fade in/out'),
)
```

### AnimatedPadding

```dart
AnimatedPadding(
  duration: const Duration(milliseconds: 200),
  padding: EdgeInsets.all(_selected ? 32 : 8),
  child: const Card(child: Text('Padding animiert')),
)
```

### AnimatedAlign

```dart
AnimatedAlign(
  duration: const Duration(milliseconds: 400),
  alignment: _alignRight ? Alignment.centerRight : Alignment.centerLeft,
  child: Container(width: 50, height: 50, color: Colors.blue),
)
```

### AnimatedPositioned (in Stack)

```dart
Stack(
  children: [
    AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      left: _moved ? 200 : 0,
      top: _moved ? 100 : 0,
      child: Container(width: 50, height: 50, color: Colors.red),
    ),
  ],
)
```

### AnimatedDefaultTextStyle

```dart
AnimatedDefaultTextStyle(
  duration: const Duration(milliseconds: 300),
  style: TextStyle(
    fontSize: _large ? 32 : 16,
    fontWeight: _large ? FontWeight.bold : FontWeight.normal,
    color: _large ? Colors.blue : Colors.black,
  ),
  child: const Text('Animierter Text'),
)
```

### AnimatedCrossFade

```dart
AnimatedCrossFade(
  duration: const Duration(milliseconds: 300),
  crossFadeState: _showFirst
      ? CrossFadeState.showFirst
      : CrossFadeState.showSecond,
  firstChild: const Icon(Icons.favorite, size: 100, color: Colors.red),
  secondChild: const Icon(Icons.star, size: 100, color: Colors.amber),
)
```

### AnimatedPhysicalModel

```dart
AnimatedPhysicalModel(
  duration: const Duration(milliseconds: 300),
  shape: BoxShape.rectangle,
  elevation: _elevated ? 16 : 0,
  color: _elevated ? Colors.white : Colors.grey[200]!,
  shadowColor: Colors.black,
  borderRadius: BorderRadius.circular(8),
  child: const Padding(
    padding: EdgeInsets.all(16),
    child: Text('Elevation animiert'),
  ),
)
```

---

## 4. AnimatedSwitcher

### Widget-Wechsel animieren

```dart
class CounterWithAnimation extends StatefulWidget {
  const CounterWithAnimation({super.key});

  @override
  State<CounterWithAnimation> createState() => _CounterWithAnimationState();
}

class _CounterWithAnimationState extends State<CounterWithAnimation> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Text(
            '$_count',
            // Key ist wichtig! Sonst erkennt Flutter den Wechsel nicht
            key: ValueKey<int>(_count),
            style: const TextStyle(fontSize: 48),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
```

### Verschiedene Transitions

```dart
// Fade (Standard)
transitionBuilder: (child, animation) {
  return FadeTransition(opacity: animation, child: child);
},

// Scale
transitionBuilder: (child, animation) {
  return ScaleTransition(scale: animation, child: child);
},

// Slide von unten
transitionBuilder: (child, animation) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(animation),
    child: child,
  );
},

// Rotation
transitionBuilder: (child, animation) {
  return RotationTransition(turns: animation, child: child);
},

// Kombiniert
transitionBuilder: (child, animation) {
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(scale: animation, child: child),
  );
},
```

### Layout-Builder für komplexe Wechsel

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 500),
  switchInCurve: Curves.easeOut,
  switchOutCurve: Curves.easeIn,
  layoutBuilder: (currentChild, previousChildren) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...previousChildren,
        if (currentChild != null) currentChild,
      ],
    );
  },
  transitionBuilder: (child, animation) {
    return FadeTransition(opacity: animation, child: child);
  },
  child: _widgets[_currentIndex],
)
```

---

## 5. TweenAnimationBuilder

### Custom-Animationen ohne Controller

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: _progress),
  duration: const Duration(milliseconds: 500),
  builder: (context, value, child) {
    return Column(
      children: [
        LinearProgressIndicator(value: value),
        Text('${(value * 100).toInt()}%'),
      ],
    );
  },
)
```

### Mit verschiedenen Typen

```dart
// Color Animation
TweenAnimationBuilder<Color?>(
  tween: ColorTween(begin: Colors.red, end: _targetColor),
  duration: const Duration(milliseconds: 300),
  builder: (context, color, child) {
    return Container(
      width: 100,
      height: 100,
      color: color,
    );
  },
)

// Size Animation
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 50, end: _targetSize),
  duration: const Duration(milliseconds: 400),
  curve: Curves.elasticOut,
  builder: (context, size, child) {
    return Container(
      width: size,
      height: size,
      color: Colors.blue,
      child: child,
    );
  },
  child: const Icon(Icons.star, color: Colors.white),  // child wird nicht rebuildet
)

// Offset Animation
TweenAnimationBuilder<Offset>(
  tween: Tween<Offset>(
    begin: Offset.zero,
    end: _targetOffset,
  ),
  duration: const Duration(milliseconds: 300),
  builder: (context, offset, child) {
    return Transform.translate(
      offset: offset,
      child: child,
    );
  },
  child: const FlutterLogo(size: 100),
)
```

### onEnd Callback

```dart
TweenAnimationBuilder<double>(
  tween: Tween<double>(begin: 0, end: 1),
  duration: const Duration(seconds: 2),
  onEnd: () {
    // Animation fertig
    print('Animation completed!');
    // Nächste Animation starten, Navigation, etc.
  },
  builder: (context, value, child) {
    return Opacity(
      opacity: value,
      child: child,
    );
  },
  child: const Text('Fade In Complete'),
)
```

---

## 6. Curves

### Verfügbare Curves

```dart
// Linear
curve: Curves.linear,

// Ease (Standard)
curve: Curves.ease,
curve: Curves.easeIn,
curve: Curves.easeOut,
curve: Curves.easeInOut,

// Cubic
curve: Curves.fastOutSlowIn,
curve: Curves.slowMiddle,

// Bounce
curve: Curves.bounceIn,
curve: Curves.bounceOut,
curve: Curves.bounceInOut,

// Elastic
curve: Curves.elasticIn,
curve: Curves.elasticOut,
curve: Curves.elasticInOut,

// Back (überschießt)
curve: Curves.easeInBack,
curve: Curves.easeOutBack,
curve: Curves.easeInOutBack,
```

### Curve-Visualisierung

```dart
class CurveDemo extends StatefulWidget {
  const CurveDemo({super.key});

  @override
  State<CurveDemo> createState() => _CurveDemoState();
}

class _CurveDemoState extends State<CurveDemo> {
  bool _animated = false;
  Curve _selectedCurve = Curves.easeInOut;

  final _curves = {
    'linear': Curves.linear,
    'easeInOut': Curves.easeInOut,
    'bounceOut': Curves.bounceOut,
    'elasticOut': Curves.elasticOut,
    'easeOutBack': Curves.easeOutBack,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DropdownButton<String>(
          value: _curves.entries
              .firstWhere((e) => e.value == _selectedCurve)
              .key,
          items: _curves.keys.map((name) {
            return DropdownMenuItem(value: name, child: Text(name));
          }).toList(),
          onChanged: (name) {
            setState(() => _selectedCurve = _curves[name]!);
          },
        ),
        const SizedBox(height: 32),
        AnimatedAlign(
          duration: const Duration(milliseconds: 1000),
          curve: _selectedCurve,
          alignment: _animated
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => setState(() => _animated = !_animated),
          child: const Text('Animate'),
        ),
      ],
    );
  }
}
```

---

## 7. AnimatedList

### Dynamische Listen mit Animation

```dart
class AnimatedListDemo extends StatefulWidget {
  const AnimatedListDemo({super.key});

  @override
  State<AnimatedListDemo> createState() => _AnimatedListDemoState();
}

class _AnimatedListDemoState extends State<AnimatedListDemo> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _items = <String>['Item 1', 'Item 2', 'Item 3'];

  void _addItem() {
    final index = _items.length;
    _items.add('Item ${index + 1}');
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _removeItem(int index) {
    final removedItem = _items.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildItem(removedItem, animation),
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildItem(String item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: Card(
          child: ListTile(
            title: Text(item),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final index = _items.indexOf(item);
                if (index != -1) _removeItem(index);
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
      appBar: AppBar(title: const Text('AnimatedList')),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _items.length,
        itemBuilder: (context, index, animation) {
          return _buildItem(_items[index], animation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## 8. Praktisches Beispiel: Animated Card

```dart
class AnimatedProductCard extends StatefulWidget {
  final String title;
  final String price;
  final String imageUrl;

  const AnimatedProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.imageUrl,
  });

  @override
  State<AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<AnimatedProductCard> {
  bool _isHovered = false;
  bool _isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_isHovered ? 1.05 : 1.0),
        child: AnimatedPhysicalModel(
          duration: const Duration(milliseconds: 200),
          shape: BoxShape.rectangle,
          elevation: _isHovered ? 12 : 4,
          color: Colors.white,
          shadowColor: Colors.black,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image mit Overlay
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      widget.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _isFavorite = !_isFavorite),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isFavorite
                              ? Colors.red
                              : Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            key: ValueKey(_isFavorite),
                            color: _isFavorite ? Colors.white : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: _isHovered ? 18 : 14,
                        fontWeight: _isHovered
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: Colors.green[700],
                      ),
                      child: Text(widget.price),
                    ),
                  ],
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

## Zusammenfassung

| Widget | Animiert |
|--------|----------|
| `AnimatedContainer` | Size, Color, Padding, Margin, Decoration |
| `AnimatedOpacity` | Opacity (0.0 - 1.0) |
| `AnimatedPadding` | Padding |
| `AnimatedAlign` | Alignment |
| `AnimatedPositioned` | Position in Stack |
| `AnimatedDefaultTextStyle` | TextStyle |
| `AnimatedCrossFade` | Wechsel zwischen zwei Widgets |
| `AnimatedSwitcher` | Beliebiger Widget-Wechsel |
| `AnimatedList` | Listen mit Add/Remove |
| `TweenAnimationBuilder` | Custom Tween-Animationen |

**Best Practices:**
- Implizite Animationen für einfache Übergänge
- `duration` von 200-400ms für UI-Feedback
- `Curves.easeInOut` als Standard-Curve
- `key` bei `AnimatedSwitcher` nicht vergessen
