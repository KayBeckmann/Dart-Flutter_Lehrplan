# Ressourcen: Background Jobs & Scheduling

## Offizielle Dokumentation

- [Dart Isolates](https://dart.dev/guides/language/concurrency)
- [Redis Pub/Sub](https://redis.io/docs/manual/pubsub/)
- [Cron Expression Format](https://crontab.guru/)

## Cheat Sheet: Job Pattern

```dart
// Basis Job
abstract class Job {
  String get type;
  Future<void> execute();
  Map<String, dynamic> toJson();

  // Retry-Logik
  int attempts = 0;
  int maxAttempts = 3;
  bool get shouldRetry => attempts < maxAttempts;
  Duration get retryDelay => Duration(seconds: 1 << attempts);
}

// Konkreter Job
class EmailJob extends Job {
  final String to, subject, body;

  EmailJob({required this.to, required this.subject, required this.body});

  @override
  String get type => 'email';

  @override
  Future<void> execute() async {
    await sendEmail(to, subject, body);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type, 'to': to, 'subject': subject, 'body': body
  };

  factory EmailJob.fromJson(Map<String, dynamic> json) => EmailJob(
    to: json['to'], subject: json['subject'], body: json['body']
  );
}
```

## Cheat Sheet: Queue Operations

```dart
class JobQueue {
  final Queue<Job> _queue = Queue();

  // Einreihen
  void enqueue(Job job) => _queue.add(job);

  // Mit Delay
  void enqueueDelayed(Job job, Duration delay) {
    Timer(delay, () => enqueue(job));
  }

  // Abrufen
  Job? dequeue() => _queue.isNotEmpty ? _queue.removeFirst() : null;

  // Priorisiert
  void enqueuePriority(Job job) => _queue.addFirst(job);

  // Batch
  void enqueueBatch(List<Job> jobs) => _queue.addAll(jobs);
}
```

## Cheat Sheet: Worker

```dart
class Worker {
  final JobQueue queue;
  final int concurrency;
  bool _running = false;
  int _active = 0;

  Worker(this.queue, {this.concurrency = 1});

  Future<void> start() async {
    _running = true;
    while (_running) {
      if (_active >= concurrency || queue.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }

      final job = queue.dequeue();
      if (job != null) {
        _active++;
        _processJob(job).then((_) => _active--);
      }
    }
  }

  Future<void> _processJob(Job job) async {
    job.attempts++;
    try {
      await job.execute();
    } catch (e) {
      if (job.shouldRetry) {
        queue.enqueueDelayed(job, job.retryDelay);
      }
    }
  }

  void stop() => _running = false;
}
```

## Cheat Sheet: Cron Expressions

```
┌───────────── Minute (0-59)
│ ┌─────────── Stunde (0-23)
│ │ ┌───────── Tag des Monats (1-31)
│ │ │ ┌─────── Monat (1-12)
│ │ │ │ ┌───── Wochentag (0-6, 0=Sonntag)
│ │ │ │ │
* * * * *
```

| Expression | Bedeutung |
|------------|-----------|
| `* * * * *` | Jede Minute |
| `0 * * * *` | Jede Stunde |
| `0 0 * * *` | Täglich Mitternacht |
| `0 9 * * 1-5` | Werktags 9 Uhr |
| `*/15 * * * *` | Alle 15 Minuten |
| `0 0 1 * *` | Monatlich am 1. |
| `0 2 * * 0` | Sonntags 2 Uhr |

## Cheat Sheet: Scheduler

```dart
class Scheduler {
  final List<(String, CronExpression, Function)> _tasks = [];
  Timer? _timer;

  void schedule(String name, String cron, Function callback) {
    _tasks.add((name, CronExpression.parse(cron), callback));
  }

  void start() {
    _timer = Timer.periodic(Duration(minutes: 1), (_) {
      final now = DateTime.now();
      for (final (name, cron, callback) in _tasks) {
        if (cron.matches(now)) {
          callback();
        }
      }
    });
  }

  void stop() => _timer?.cancel();
}
```

## Cheat Sheet: Redis Queue

```dart
class RedisQueue {
  final RedisConnection redis;
  final String name;

  // Einreihen (FIFO)
  Future<void> enqueue(Job job) async {
    await redis.execute(['RPUSH', name, jsonEncode(job.toJson())]);
  }

  // Abrufen (blockierend)
  Future<String?> dequeue({int timeout = 5}) async {
    final result = await redis.execute(['BLPOP', name, timeout.toString()]);
    return result?[1] as String?;
  }

  // Verzögert (Sorted Set)
  Future<void> enqueueAt(Job job, DateTime when) async {
    await redis.execute([
      'ZADD', '$name:delayed',
      when.millisecondsSinceEpoch.toString(),
      jsonEncode(job.toJson())
    ]);
  }

  // Fällige Jobs verschieben
  Future<void> processDelayed() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final jobs = await redis.execute([
      'ZRANGEBYSCORE', '$name:delayed', '0', now.toString()
    ]);
    for (final job in jobs ?? []) {
      await redis.execute(['RPUSH', name, job]);
      await redis.execute(['ZREM', '$name:delayed', job]);
    }
  }
}
```

## Cheat Sheet: Priority Queue

```dart
class PriorityQueue {
  final Map<int, Queue<Job>> _queues = {};

  void enqueue(Job job, {int priority = 0}) {
    _queues.putIfAbsent(priority, () => Queue()).add(job);
  }

  Job? dequeue() {
    // Höchste Priorität zuerst
    final priorities = _queues.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final p in priorities) {
      final queue = _queues[p]!;
      if (queue.isNotEmpty) {
        return queue.removeFirst();
      }
    }
    return null;
  }
}
```

## Cheat Sheet: Dead Letter Queue

```dart
class DeadLetterHandler {
  final List<(Job, String, DateTime)> _deadLetters = [];

  void add(Job job, String error) {
    _deadLetters.add((job, error, DateTime.now()));
  }

  List<Map<String, dynamic>> getAll() {
    return _deadLetters.map((entry) => {
      'job': entry.$1.toJson(),
      'error': entry.$2,
      'failedAt': entry.$3.toIso8601String(),
    }).toList();
  }

  // Retry einzelner Job
  Future<void> retry(String jobId, JobQueue queue) async {
    final index = _deadLetters.indexWhere((e) => e.$1.id == jobId);
    if (index >= 0) {
      final job = _deadLetters.removeAt(index).$1;
      job.attempts = 0;
      queue.enqueue(job);
    }
  }
}
```

## Best Practices

### DO

1. **Idempotente Jobs** - Mehrfache Ausführung = gleiches Ergebnis
2. **Exponential Backoff** - Bei Retries warten
3. **Timeouts** - Jobs nicht ewig laufen lassen
4. **Dead Letter Queue** - Fehlgeschlagene Jobs aufbewahren
5. **Logging** - Start, Ende, Fehler loggen
6. **Graceful Shutdown** - Aktive Jobs beenden lassen
7. **Health Checks** - Queue-Größe überwachen

### DON'T

1. **Synchrone Queue-Operationen** im Request
2. **Zu viele Retries** - Max 3-5
3. **Große Payloads** - Job-Daten klein halten
4. **Zustand in Job** - Immer aus DB laden
5. **Silent Failures** - Fehler immer loggen

## Monitoring

```dart
class QueueMetrics {
  int enqueued = 0;
  int processed = 0;
  int failed = 0;
  int pending = 0;

  Map<String, dynamic> toJson() => {
    'enqueued': enqueued,
    'processed': processed,
    'failed': failed,
    'pending': pending,
    'successRate': processed > 0
      ? ((processed - failed) / processed * 100).toStringAsFixed(1)
      : '0.0',
  };
}
```

## Isolates für CPU-intensive Jobs

```dart
import 'dart:isolate';

class IsolateWorker {
  Future<R> run<R>(Future<R> Function() work) async {
    return await Isolate.run(work);
  }
}

// Verwendung
final result = await IsolateWorker().run(() async {
  // CPU-intensive Arbeit
  return heavyComputation();
});
```

## Tools

- **Redis** - Persistente Queue
- **BullMQ** (Node.js Equivalent) - Referenz für Features
- **Crontab Guru** - Cron Expression Builder
- **Grafana** - Queue Monitoring
