# Einheit 3.6: FutureBuilder & StreamBuilder

## Lernziele

Nach dieser Einheit kannst du:
- `FutureBuilder` für einmalige async Operationen verwenden
- `StreamBuilder` für kontinuierliche Datenströme einsetzen
- Loading und Error States korrekt anzeigen
- Skeleton Screens für bessere UX implementieren
- Häufige Fehler vermeiden

---

## 1. FutureBuilder Grundlagen

`FutureBuilder` baut Widgets basierend auf dem Zustand eines `Future`.

### Einfaches Beispiel

```dart
class UserProfile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: fetchUser(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        // Error State
        if (snapshot.hasError) {
          return Text('Fehler: ${snapshot.error}');
        }

        // Success State
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return Text('Hallo, ${user.name}!');
        }

        // Kein Zustand (sollte nicht vorkommen)
        return const SizedBox.shrink();
      },
    );
  }
}
```

### AsyncSnapshot verstehen

```dart
builder: (context, AsyncSnapshot<User> snapshot) {
  // ConnectionState
  snapshot.connectionState;  // none, waiting, active, done

  // Daten
  snapshot.hasData;          // true wenn data != null
  snapshot.data;             // Die Daten (nullable)

  // Fehler
  snapshot.hasError;         // true wenn error != null
  snapshot.error;            // Die Exception

  // Hilfreich für Debugging
  print('State: ${snapshot.connectionState}');
  print('Data: ${snapshot.data}');
  print('Error: ${snapshot.error}');
}
```

### ConnectionState Werte

| State | Bedeutung |
|-------|-----------|
| `none` | Kein Future zugewiesen |
| `waiting` | Future läuft noch |
| `active` | Stream aktiv (nur bei StreamBuilder) |
| `done` | Future abgeschlossen |

---

## 2. FutureBuilder Best Practices

### Problem: Future wird bei jedem Build neu erstellt

```dart
// ❌ FALSCH: Future wird bei jedem setState() neu ausgeführt
class BadExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: fetchUser(),  // Wird bei jedem Build aufgerufen!
      builder: (context, snapshot) => ...,
    );
  }
}
```

### Lösung: Future im State speichern

```dart
// ✅ RICHTIG: Future wird einmal erstellt
class GoodExample extends StatefulWidget {
  @override
  State<GoodExample> createState() => _GoodExampleState();
}

class _GoodExampleState extends State<GoodExample> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = fetchUser();  // Nur einmal!
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: _userFuture,  // Gleiche Referenz
      builder: (context, snapshot) => ...,
    );
  }

  // Für Refresh
  void _refresh() {
    setState(() {
      _userFuture = fetchUser();
    });
  }
}
```

### Vollständiges Pattern

```dart
class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late Future<User> _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    _userFuture = UserService().fetchCurrentUser();
  }

  void _refresh() {
    setState(() {
      _loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<User>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorWidget(
              error: snapshot.error!,
              onRetry: _refresh,
            );
          }

          final user = snapshot.data!;
          return _UserContent(user: user);
        },
      ),
    );
  }
}

class _ErrorWidget extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _ErrorWidget({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Fehler: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. StreamBuilder Grundlagen

`StreamBuilder` reagiert auf jeden neuen Wert eines Streams.

### Einfaches Beispiel

```dart
class MessageList extends StatelessWidget {
  final Stream<List<Message>> messagesStream;

  const MessageList({required this.messagesStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Message>>(
      stream: messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Fehler: ${snapshot.error}');
        }

        final messages = snapshot.data ?? [];

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            return MessageTile(message: messages[index]);
          },
        );
      },
    );
  }
}
```

### Mit initialData

```dart
StreamBuilder<int>(
  stream: counterStream,
  initialData: 0,  // Startwert während wir auf ersten Stream-Wert warten
  builder: (context, snapshot) {
    final count = snapshot.data!;  // Sicher, da initialData gesetzt
    return Text('Count: $count');
  },
);
```

### Timer-Beispiel

```dart
class Clock extends StatefulWidget {
  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _timeStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Text('--:--:--');
        }

        final time = snapshot.data!;
        final formatted =
            '${time.hour.toString().padLeft(2, '0')}:'
            '${time.minute.toString().padLeft(2, '0')}:'
            '${time.second.toString().padLeft(2, '0')}';

        return Text(
          formatted,
          style: const TextStyle(fontSize: 48),
        );
      },
    );
  }
}
```

---

## 4. Skeleton Screens

Skeleton Screens zeigen Platzhalter während des Ladens - bessere UX als Spinner.

### Einfaches Skeleton

```dart
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonBox({
    this.width = double.infinity,
    this.height = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class SkeletonListTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          SkeletonBox(width: 48, height: 48),  // Avatar
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16),  // Title
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 12),  // Subtitle
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### Animiertes Skeleton (Shimmer)

```dart
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;

  const ShimmerBox({this.width = double.infinity, this.height = 16});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: LinearGradient(
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
        );
      },
    );
  }
}
```

### shimmer Package verwenden

```yaml
dependencies:
  shimmer: ^3.0.0
```

```dart
import 'package:shimmer/shimmer.dart';

class SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const ListTile(
          leading: CircleAvatar(backgroundColor: Colors.white),
          title: SkeletonBox(height: 16),
          subtitle: SkeletonBox(height: 12, width: 100),
        ),
      ),
    );
  }
}
```

### In FutureBuilder integrieren

```dart
FutureBuilder<List<Post>>(
  future: _postsFuture,
  builder: (context, snapshot) {
    // Skeleton während Loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return ListView.builder(
        itemCount: 5,
        itemBuilder: (_, __) => const SkeletonPostCard(),
      );
    }

    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error!);
    }

    final posts = snapshot.data!;
    return ListView.builder(
      itemCount: posts.length,
      itemBuilder: (_, index) => PostCard(post: posts[index]),
    );
  },
);
```

---

## 5. Fortgeschrittene Patterns

### Kombinierte Futures

```dart
class DashboardPage extends StatefulWidget {
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<(User, List<Post>, Stats)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = (
      fetchUser(),
      fetchPosts(),
      fetchStats(),
    ).wait;  // Dart 3 Records + Future.wait
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DashboardSkeleton();
        }

        if (snapshot.hasError) {
          return ErrorWidget(error: snapshot.error!);
        }

        final (user, posts, stats) = snapshot.data!;

        return DashboardContent(
          user: user,
          posts: posts,
          stats: stats,
        );
      },
    );
  }
}
```

### Stream mit Fehlerbehandlung

```dart
StreamBuilder<Result<List<Message>>>(
  stream: messageService.messagesStream,
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const LoadingIndicator();
    }

    return snapshot.data!.when(
      success: (messages) => MessageList(messages: messages),
      error: (error) => ErrorWidget(error: error),
    );
  },
);

// Result Sealed Class
sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(Object error) error,
  });
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Object error) error,
  }) => success(data);
}

class Error<T> extends Result<T> {
  final Object exception;
  const Error(this.exception);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Object error) error,
  }) => error(exception);
}
```

---

## 6. Häufige Fehler

### Future in build() erstellen

```dart
// ❌ FALSCH
Widget build(BuildContext context) {
  return FutureBuilder(
    future: api.fetchData(),  // Jedes Mal neu!
    builder: ...,
  );
}

// ✅ RICHTIG
late Future<Data> _future;

@override
void initState() {
  super.initState();
  _future = api.fetchData();
}
```

### Stream nicht disposen

```dart
// ❌ FALSCH: Stream läuft weiter
class BadWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final stream = StreamController<int>();
    // Stream wird nie geschlossen!
    return StreamBuilder(stream: stream.stream, ...);
  }
}

// ✅ RICHTIG: Cleanup in dispose
class GoodWidget extends StatefulWidget {
  @override
  State<GoodWidget> createState() => _GoodWidgetState();
}

class _GoodWidgetState extends State<GoodWidget> {
  final _controller = StreamController<int>();

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}
```

---

## Zusammenfassung

| Widget | Use Case |
|--------|----------|
| `FutureBuilder` | Einmalige async Operation (API Call, File Read) |
| `StreamBuilder` | Kontinuierlicher Datenstrom (Real-time, Timer) |

**Best Practices:**
1. Future/Stream im `initState` erstellen, nicht in `build`
2. Alle drei States behandeln: Loading, Error, Data
3. Skeleton Screens für bessere UX
4. Streams in `dispose` schließen
5. `initialData` für sofortige Anzeige nutzen
