# Lösung 3.6: FutureBuilder & StreamBuilder

## Aufgabe 1: QuotePage

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Quote {
  final String content;
  final String author;

  Quote({required this.content, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      content: json['content'] as String,
      author: json['author'] as String,
    );
  }
}

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  late Future<Quote> _quoteFuture;

  @override
  void initState() {
    super.initState();
    _loadQuote();
  }

  void _loadQuote() {
    _quoteFuture = _fetchQuote();
  }

  Future<Quote> _fetchQuote() async {
    final response = await http.get(
      Uri.parse('https://api.quotable.io/random'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load quote');
    }

    return Quote.fromJson(jsonDecode(response.body));
  }

  void _refresh() {
    setState(() {
      _loadQuote();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quote of the Day'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<Quote>(
        future: _quoteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Fehler: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                  ),
                ],
              ),
            );
          }

          final quote = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.format_quote, size: 48, color: Colors.grey),
                  const SizedBox(height: 24),
                  Text(
                    '"${quote.content}"',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '- ${quote.author}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
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

## Aufgabe 2: Skeleton Components

```dart
class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}

class SkeletonUserTile extends StatelessWidget {
  const SkeletonUserTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SkeletonCircle(size: 48),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 150, height: 16),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Integration
class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  late Future<List<User>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    await Future.delayed(const Duration(seconds: 2)); // Simulate network
    // ... fetch from API
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: FutureBuilder<List<User>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (_, __) => const SkeletonUserTile(),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, index) => UserTile(user: users[index]),
          );
        },
      ),
    );
  }
}
```

---

## Aufgabe 3: Live Clock

```dart
class LiveClock extends StatefulWidget {
  const LiveClock({super.key});

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime time) {
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];

    return '${weekdays[time.weekday - 1]}, '
        '${time.day}. ${months[time.month - 1]} ${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: _timeStream,
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final time = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formatTime(time),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(time),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        );
      },
    );
  }
}
```

---

## Aufgabe 4: Counter mit StreamController

```dart
import 'dart:async';

class CounterController {
  final _controller = StreamController<int>.broadcast();
  int _count = 0;

  Stream<int> get stream => _controller.stream;
  int get currentValue => _count;

  void increment() {
    _count++;
    _controller.add(_count);
  }

  void decrement() {
    _count--;
    _controller.add(_count);
  }

  void reset() {
    _count = 0;
    _controller.add(_count);
  }

  void dispose() {
    _controller.close();
  }
}

class StreamCounterPage extends StatefulWidget {
  const StreamCounterPage({super.key});

  @override
  State<StreamCounterPage> createState() => _StreamCounterPageState();
}

class _StreamCounterPageState extends State<StreamCounterPage> {
  final _counterController = CounterController();

  @override
  void dispose() {
    _counterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Counter')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StreamBuilder<int>(
              stream: _counterController.stream,
              initialData: 0,
              builder: (context, snapshot) {
                return Text(
                  '${snapshot.data}',
                  style: Theme.of(context).textTheme.displayLarge,
                );
              },
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton(
                  onPressed: _counterController.decrement,
                  heroTag: 'decrement',
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _counterController.reset,
                  heroTag: 'reset',
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(width: 16),
                FloatingActionButton(
                  onPressed: _counterController.increment,
                  heroTag: 'increment',
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 5: Dashboard mit kombinierten Futures

```dart
class DashboardData {
  final int userCount;
  final int orderCount;
  final double revenue;

  DashboardData({
    required this.userCount,
    required this.orderCount,
    required this.revenue,
  });
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<DashboardData> _dataFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _dataFuture = _fetchAllData();
  }

  Future<DashboardData> _fetchAllData() async {
    // Parallel ausführen
    final results = await Future.wait([
      _fetchUserCount(),
      _fetchOrderCount(),
      _fetchRevenue(),
    ]);

    return DashboardData(
      userCount: results[0] as int,
      orderCount: results[1] as int,
      revenue: results[2] as double,
    );
  }

  Future<int> _fetchUserCount() async {
    await Future.delayed(const Duration(seconds: 1));
    return 1234;
  }

  Future<int> _fetchOrderCount() async {
    await Future.delayed(const Duration(seconds: 2));
    return 567;
  }

  Future<double> _fetchRevenue() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return 12345.67;
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _DashboardSkeleton();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          return _DashboardContent(data: data);
        },
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonCard()),
              const SizedBox(width: 16),
              Expanded(child: _SkeletonCard()),
            ],
          ),
          const SizedBox(height: 16),
          _SkeletonCard(height: 120),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  final double height;

  const _SkeletonCard({this.height = 100});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardData data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Users',
                  value: data.userCount.toString(),
                  icon: Icons.people,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Orders',
                  value: data.orderCount.toString(),
                  icon: Icons.shopping_cart,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: 'Revenue',
            value: '€${data.revenue.toStringAsFixed(2)}',
            icon: Icons.euro,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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

## Verständnisfragen - Antworten

1. **Warum Future nicht in build()?**
   - `build()` wird bei jedem `setState()` aufgerufen
   - Ein neues Future würde jedes Mal den API-Call erneut starten
   - Das führt zu unnötigen Requests und Flackern

2. **hasData vs. data != null?**
   - `hasData` prüft `data != null` UND ob ein Wert angekommen ist
   - Bei `initialData` ist `hasData` sofort `true`
   - Für die meisten Fälle ist `hasData` die bessere Wahl

3. **Wann initialData?**
   - Wenn ein Default-Wert sofort angezeigt werden soll
   - Um den initialen `waiting`-State zu überspringen
   - Bei Streams mit bekanntem Startwert

4. **Memory Leaks verhindern?**
   - `StreamController.close()` in `dispose()` aufrufen
   - `StreamSubscription.cancel()` bei manuellen Subscriptions
   - Bei Provider/Riverpod: automatisches Lifecycle-Management

5. **Stream-Fehler?**
   - `snapshot.hasError` wird `true`
   - `snapshot.error` enthält die Exception
   - Stream kann danach keine weiteren Events senden (bei Single-Subscription)
