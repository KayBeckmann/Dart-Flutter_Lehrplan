# Lösung 2.4: Widget-Lifecycle & Keys

---

## Aufgabe 1

```dart
class LifecycleLogger extends StatefulWidget {
  final String name;
  const LifecycleLogger({super.key, required this.name});

  @override
  State<LifecycleLogger> createState() => _LifecycleLoggerState();
}

class _LifecycleLoggerState extends State<LifecycleLogger> {
  @override
  void initState() {
    super.initState();
    print('[${widget.name}] initState');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[${widget.name}] didChangeDependencies');
  }

  @override
  void didUpdateWidget(LifecycleLogger oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('[${widget.name}] didUpdateWidget');
  }

  @override
  Widget build(BuildContext context) {
    print('[${widget.name}] build');
    return Text(widget.name);
  }

  @override
  void dispose() {
    print('[${widget.name}] dispose');
    super.dispose();
  }
}
```

---

## Aufgabe 2

```dart
class CountdownTimer extends StatefulWidget {
  final int sekunden;
  final VoidCallback? onFinished;

  const CountdownTimer({super.key, required this.sekunden, this.onFinished});

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _verbleibend;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verbleibend = widget.sekunden;
    _starteTimer();
  }

  void _starteTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_verbleibend > 0) {
        setState(() => _verbleibend--);
      } else {
        timer.cancel();
        widget.onFinished?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '$_verbleibend',
      style: TextStyle(fontSize: 48),
    );
  }
}
```

---

## Aufgabe 3

```dart
class CounterItem extends StatefulWidget {
  final String label;
  const CounterItem({super.key, required this.label});

  @override
  State<CounterItem> createState() => _CounterItemState();
}

class _CounterItemState extends State<CounterItem> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${widget.label}: $_count'),
      trailing: IconButton(
        icon: Icon(Icons.add),
        onPressed: () => setState(() => _count++),
      ),
    );
  }
}

// Vergleich:
// OHNE Key: State bleibt an Position
// MIT Key: State folgt dem Widget
```
