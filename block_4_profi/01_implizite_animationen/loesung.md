# Lösung 4.1: Implizite Animationen

## Aufgabe 1: Animated Settings Toggle

```dart
class AnimatedSettingsToggle extends StatefulWidget {
  const AnimatedSettingsToggle({super.key});

  @override
  State<AnimatedSettingsToggle> createState() => _AnimatedSettingsToggleState();
}

class _AnimatedSettingsToggleState extends State<AnimatedSettingsToggle> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isEnabled = !_isEnabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isEnabled ? Colors.green[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isEnabled ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // Animiertes Icon
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: _isEnabled ? 1.3 : 1.0),
              duration: const Duration(milliseconds: 300),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Icon(
                    Icons.notifications,
                    color: _isEnabled ? Colors.green : Colors.grey,
                    size: 28,
                  ),
                );
              },
            ),
            const SizedBox(width: 16),
            // Animierter Text
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: _isEnabled ? FontWeight.bold : FontWeight.normal,
                  color: _isEnabled ? Colors.green[800] : Colors.grey[700],
                ),
                child: const Text('Benachrichtigungen'),
              ),
            ),
            // Animierter Switch-Indikator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 50,
              height: 28,
              decoration: BoxDecoration(
                color: _isEnabled ? Colors.green : Colors.grey[400],
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment:
                    _isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(3),
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 2: Expandable Card

```dart
class ExpandableOrderCard extends StatefulWidget {
  const ExpandableOrderCard({super.key});

  @override
  State<ExpandableOrderCard> createState() => _ExpandableOrderCardState();
}

class _ExpandableOrderCardState extends State<ExpandableOrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isExpanded ? 0.15 : 0.08),
              blurRadius: _isExpanded ? 12 : 6,
              offset: Offset(0, _isExpanded ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header (immer sichtbar)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bestellung #12345',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Status: Versendet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
                ],
              ),
            ),

            // Expandable Content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow('Artikel:', 'Flutter Buch'),
                    _buildDetailRow('Preis:', '29,99€'),
                    _buildDetailRow('Lieferadresse:', 'Musterstr. 1'),
                    _buildDetailRow('Voraussichtlich:', '15.03.2024'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Aufgabe 3: AnimatedSwitcher Gallery

```dart
class AnimatedGallery extends StatefulWidget {
  const AnimatedGallery({super.key});

  @override
  State<AnimatedGallery> createState() => _AnimatedGalleryState();
}

class _AnimatedGalleryState extends State<AnimatedGallery> {
  int _currentIndex = 0;
  String _transitionType = 'fade';

  final _images = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
  ];

  final _transitions = ['fade', 'scale', 'slide', 'rotation'];

  Widget _buildTransition(Widget child, Animation<double> animation) {
    switch (_transitionType) {
      case 'scale':
        return ScaleTransition(scale: animation, child: child);
      case 'slide':
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      case 'rotation':
        return RotationTransition(
          turns: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      default:
        return FadeTransition(opacity: animation, child: child);
    }
  }

  void _previous() {
    setState(() {
      _currentIndex = (_currentIndex - 1 + _images.length) % _images.length;
    });
  }

  void _next() {
    setState(() {
      _currentIndex = (_currentIndex + 1) % _images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gallery
        SizedBox(
          height: 200,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: _buildTransition,
            child: Container(
              key: ValueKey(_currentIndex),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _images[_currentIndex],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  'Bild ${_currentIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previous,
            ),
            const SizedBox(width: 32),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _next,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Transition Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Übergang: '),
            DropdownButton<String>(
              value: _transitionType,
              items: _transitions.map((t) {
                return DropdownMenuItem(value: t, child: Text(t));
              }).toList(),
              onChanged: (v) => setState(() => _transitionType = v!),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Aufgabe 4: Progress Animation

```dart
class AnimatedProgress extends StatefulWidget {
  const AnimatedProgress({super.key});

  @override
  State<AnimatedProgress> createState() => _AnimatedProgressState();
}

class _AnimatedProgressState extends State<AnimatedProgress> {
  double _progress = 0;
  bool _isComplete = false;

  Color _getColor(double progress) {
    if (progress < 0.3) return Colors.red;
    if (progress < 0.7) return Colors.orange;
    return Colors.green;
  }

  void _simulate() async {
    setState(() {
      _progress = 0;
      _isComplete = false;
    });

    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        setState(() => _progress = i / 100);
      }
    }

    if (mounted) {
      setState(() => _isComplete = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isComplete
              ? const Icon(
                  Icons.check_circle,
                  key: ValueKey('complete'),
                  color: Colors.green,
                  size: 64,
                )
              : const Text(
                  'Upload läuft...',
                  key: ValueKey('uploading'),
                  style: TextStyle(fontSize: 18),
                ),
        ),
        const SizedBox(height: 24),

        // Progress Bar
        SizedBox(
          width: 250,
          height: 20,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: _progress),
            duration: const Duration(milliseconds: 200),
            builder: (context, value, child) {
              return Stack(
                children: [
                  // Background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  // Progress
                  FractionallySizedBox(
                    widthFactor: value,
                    child: TweenAnimationBuilder<Color?>(
                      tween: ColorTween(
                        begin: _getColor(value),
                        end: _getColor(value),
                      ),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, color, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Percentage
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: _progress),
          duration: const Duration(milliseconds: 200),
          builder: (context, value, child) {
            return Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getColor(value),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: _simulate,
          child: const Text('Simulieren'),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 5: AnimatedList Todo

```dart
class AnimatedTodoList extends StatefulWidget {
  const AnimatedTodoList({super.key});

  @override
  State<AnimatedTodoList> createState() => _AnimatedTodoListState();
}

class _AnimatedTodoListState extends State<AnimatedTodoList> {
  final _listKey = GlobalKey<AnimatedListState>();
  final _todos = <Todo>[
    Todo(text: 'Flutter lernen'),
    Todo(text: 'Dart verstanden', isDone: true),
    Todo(text: 'App veröffentlichen'),
  ];

  void _addTodo() {
    final index = _todos.length;
    _todos.add(Todo(text: 'Neues Todo ${index + 1}'));
    _listKey.currentState?.insertItem(
      index,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _removeTodo(int index) {
    final removed = _todos.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildTodoItem(removed, animation, index),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _toggleTodo(int index) {
    setState(() {
      _todos[index].isDone = !_todos[index].isDone;
    });
  }

  Widget _buildTodoItem(Todo todo, Animation<double> animation, int index) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      )),
      child: FadeTransition(
        opacity: animation,
        child: SizeTransition(
          sizeFactor: animation,
          child: _TodoTile(
            todo: todo,
            onToggle: () => _toggleTodo(index),
            onDelete: () => _removeTodo(index),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meine Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTodo,
          ),
        ],
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: _todos.length,
        itemBuilder: (context, index, animation) {
          return _buildTodoItem(_todos[index], animation, index);
        },
      ),
    );
  }
}

class Todo {
  String text;
  bool isDone;

  Todo({required this.text, this.isDone = false});
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: GestureDetector(
          onTap: onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: todo.isDone ? Colors.green : Colors.transparent,
              border: Border.all(
                color: todo.isDone ? Colors.green : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: todo.isDone
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        ),
        title: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            decoration: todo.isDone ? TextDecoration.lineThrough : null,
            color: todo.isDone ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
          child: Text(todo.text),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
```

---

## Aufgabe 6: Animated Navigation Bar

```dart
class AnimatedBottomNav extends StatefulWidget {
  const AnimatedBottomNav({super.key});

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav> {
  int _selectedIndex = 0;

  final _items = [
    (Icons.home, 'Home'),
    (Icons.search, 'Search'),
    (Icons.favorite, 'Favs'),
    (Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Center(
          key: ValueKey(_selectedIndex),
          child: Text(
            _items[_selectedIndex].$2,
            style: const TextStyle(fontSize: 32),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final isSelected = _selectedIndex == index;
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1, end: isSelected ? 1.2 : 1.0),
                      duration: const Duration(milliseconds: 200),
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Icon(
                            _items[index].$1,
                            color: isSelected ? Colors.blue : Colors.grey,
                          ),
                        );
                      },
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: isSelected ? 16 : 0,
                        child: Text(
                          _items[index].$2,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 4,
                      width: isSelected ? 4 : 0,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
```

---

## Aufgabe 7: Staggered Landing Page

```dart
class StaggeredLandingPage extends StatefulWidget {
  const StaggeredLandingPage({super.key});

  @override
  State<StaggeredLandingPage> createState() => _StaggeredLandingPageState();
}

class _StaggeredLandingPageState extends State<StaggeredLandingPage> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    // Start animation after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _animate = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo (delay: 0ms)
            _AnimatedElement(
              animate: _animate,
              delay: const Duration(milliseconds: 0),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.flutter_dash,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title (delay: 200ms)
            _AnimatedElement(
              animate: _animate,
              delay: const Duration(milliseconds: 200),
              slideOffset: const Offset(0, 0.5),
              child: const Text(
                'Willkommen!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle (delay: 400ms)
            _AnimatedElement(
              animate: _animate,
              delay: const Duration(milliseconds: 400),
              child: Text(
                'Entdecke unsere App',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 48),

            // Button (delay: 600ms)
            _AnimatedElement(
              animate: _animate,
              delay: const Duration(milliseconds: 600),
              useScale: true,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Los geht's",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _animate = false);
          Future.delayed(const Duration(milliseconds: 100), () {
            setState(() => _animate = true);
          });
        },
        child: const Icon(Icons.replay),
      ),
    );
  }
}

class _AnimatedElement extends StatelessWidget {
  final bool animate;
  final Duration delay;
  final Widget child;
  final Offset slideOffset;
  final bool useScale;

  const _AnimatedElement({
    required this.animate,
    required this.delay,
    required this.child,
    this.slideOffset = Offset.zero,
    this.useScale = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: animate ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        // Apply delay
        final delayedValue = animate
            ? ((DateTime.now().millisecondsSinceEpoch / 1000) > delay.inMilliseconds / 1000
                ? value
                : 0.0)
            : 0.0;

        return Opacity(
          opacity: delayedValue.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(
              slideOffset.dx * (1 - delayedValue) * 50,
              slideOffset.dy * (1 - delayedValue) * 50,
            ),
            child: useScale
                ? Transform.scale(
                    scale: 0.5 + (delayedValue * 0.5),
                    child: child,
                  )
                : child,
          ),
        );
      },
      child: child,
    );
  }
}

// Alternative mit echtem Delay
class StaggeredLandingPageV2 extends StatefulWidget {
  const StaggeredLandingPageV2({super.key});

  @override
  State<StaggeredLandingPageV2> createState() => _StaggeredLandingPageV2State();
}

class _StaggeredLandingPageV2State extends State<StaggeredLandingPageV2> {
  final _visible = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _startAnimations();
  }

  void _startAnimations() async {
    for (int i = 0; i < _visible.length; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _visible[i] = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _visible[0] ? 1.0 : 0.0,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 500),
                scale: _visible[0] ? 1.0 : 0.5,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.flutter_dash,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            AnimatedSlide(
              duration: const Duration(milliseconds: 500),
              offset: _visible[1] ? Offset.zero : const Offset(0, 0.5),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _visible[1] ? 1.0 : 0.0,
                child: const Text(
                  'Willkommen!',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Subtitle
            AnimatedOpacity(
              duration: const Duration(milliseconds: 500),
              opacity: _visible[2] ? 1.0 : 0.0,
              child: Text(
                'Entdecke unsere App',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 48),

            // Button
            AnimatedScale(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              scale: _visible[3] ? 1.0 : 0.0,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                child: const Text("Los geht's", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
