# Einheit 9.2: Background Jobs & Scheduling

## Lernziele

- Asynchrone Hintergrundaufgaben verstehen
- Job Queues implementieren
- Scheduled Tasks mit Cron-ähnlicher Syntax
- Worker-Pattern für skalierbare Verarbeitung

---

## Warum Background Jobs?

### Probleme mit synchroner Verarbeitung

```dart
// ❌ Schlecht: Blockiert den Request
router.post('/api/orders', (Request request) async {
  final order = await parseOrder(request);
  await saveOrder(order);

  // Diese Operationen blockieren die Response:
  await sendConfirmationEmail(order);      // 2-5 Sekunden
  await generateInvoicePdf(order);         // 3-10 Sekunden
  await notifyWarehouse(order);            // 1-3 Sekunden
  await updateAnalytics(order);            // 1-2 Sekunden

  return Response.ok('Order created');     // Nutzer wartet 7-20 Sekunden!
});

// ✅ Besser: Jobs in Queue
router.post('/api/orders', (Request request) async {
  final order = await parseOrder(request);
  await saveOrder(order);

  // Jobs zur späteren Verarbeitung einreihen
  await jobQueue.enqueue(SendEmailJob(order.id));
  await jobQueue.enqueue(GenerateInvoiceJob(order.id));
  await jobQueue.enqueue(NotifyWarehouseJob(order.id));

  return Response.ok('Order created');     // Sofortige Response!
});
```

### Anwendungsfälle

| Kategorie | Beispiele |
|-----------|-----------|
| **Email** | Bestätigungen, Newsletter, Reports |
| **Verarbeitung** | PDF-Generierung, Bildkonvertierung |
| **Integration** | Webhook-Aufrufe, API-Synchronisation |
| **Cleanup** | Alte Daten löschen, Temp-Files |
| **Scheduled** | Tägliche Backups, Reports, Erinnerungen |

---

## Einfache Job Queue

### Job-Klasse

```dart
// lib/jobs/job.dart

enum JobStatus { pending, running, completed, failed }

abstract class Job {
  final String id;
  final DateTime createdAt;
  JobStatus status;
  int attempts;
  final int maxAttempts;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;

  Job({
    String? id,
    this.maxAttempts = 3,
  })  : id = id ?? Uuid().v4(),
        createdAt = DateTime.now(),
        status = JobStatus.pending,
        attempts = 0;

  /// Job-Typ für Serialisierung
  String get type;

  /// Job ausführen
  Future<void> execute();

  /// Zu JSON konvertieren
  Map<String, dynamic> toJson();

  /// Sollte bei Fehler wiederholt werden?
  bool get shouldRetry => attempts < maxAttempts;

  /// Delay vor Retry (exponential backoff)
  Duration get retryDelay => Duration(seconds: 1 << attempts);
}
```

### Konkrete Jobs

```dart
// lib/jobs/email_job.dart

class SendEmailJob extends Job {
  final String to;
  final String subject;
  final String body;

  SendEmailJob({
    required this.to,
    required this.subject,
    required this.body,
    super.maxAttempts = 3,
  });

  @override
  String get type => 'send_email';

  @override
  Future<void> execute() async {
    print('Sending email to $to: $subject');
    // Email-Service aufrufen
    await EmailService.send(
      to: to,
      subject: subject,
      body: body,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'to': to,
        'subject': subject,
        'body': body,
        'attempts': attempts,
        'maxAttempts': maxAttempts,
      };

  factory SendEmailJob.fromJson(Map<String, dynamic> json) {
    final job = SendEmailJob(
      to: json['to'],
      subject: json['subject'],
      body: json['body'],
      maxAttempts: json['maxAttempts'] ?? 3,
    );
    job.attempts = json['attempts'] ?? 0;
    return job;
  }
}

// lib/jobs/pdf_job.dart

class GeneratePdfJob extends Job {
  final int orderId;
  final String outputPath;

  GeneratePdfJob({
    required this.orderId,
    required this.outputPath,
    super.maxAttempts = 2,
  });

  @override
  String get type => 'generate_pdf';

  @override
  Future<void> execute() async {
    print('Generating PDF for order $orderId');

    final order = await OrderRepository.findById(orderId);
    if (order == null) {
      throw Exception('Order not found: $orderId');
    }

    await PdfService.generateInvoice(order, outputPath);
  }

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        'id': id,
        'orderId': orderId,
        'outputPath': outputPath,
      };
}
```

### In-Memory Queue

```dart
// lib/queue/memory_queue.dart

import 'dart:async';
import 'dart:collection';

class MemoryJobQueue {
  final Queue<Job> _pending = Queue();
  final List<Job> _completed = [];
  final List<Job> _failed = [];

  bool _isProcessing = false;
  final _controller = StreamController<Job>.broadcast();

  Stream<Job> get onJobCompleted => _controller.stream;

  /// Job zur Queue hinzufügen
  Future<void> enqueue(Job job) async {
    _pending.add(job);
    print('Job enqueued: ${job.type} (${job.id})');

    // Verarbeitung starten falls nicht aktiv
    if (!_isProcessing) {
      _processQueue();
    }
  }

  /// Queue verarbeiten
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    while (_pending.isNotEmpty) {
      final job = _pending.removeFirst();
      await _executeJob(job);
    }

    _isProcessing = false;
  }

  /// Einzelnen Job ausführen
  Future<void> _executeJob(Job job) async {
    job.status = JobStatus.running;
    job.startedAt = DateTime.now();
    job.attempts++;

    try {
      await job.execute();

      job.status = JobStatus.completed;
      job.completedAt = DateTime.now();
      _completed.add(job);
      _controller.add(job);

      print('Job completed: ${job.type} (${job.id})');
    } catch (e) {
      job.error = e.toString();
      print('Job failed: ${job.type} (${job.id}) - $e');

      if (job.shouldRetry) {
        // Zurück in Queue mit Delay
        print('Retrying in ${job.retryDelay.inSeconds}s...');
        Future.delayed(job.retryDelay, () {
          job.status = JobStatus.pending;
          _pending.add(job);
          _processQueue();
        });
      } else {
        job.status = JobStatus.failed;
        _failed.add(job);
      }
    }
  }

  /// Statistiken
  Map<String, int> get stats => {
        'pending': _pending.length,
        'completed': _completed.length,
        'failed': _failed.length,
      };
}
```

---

## Persistente Queue mit Redis

### Redis-basierte Queue

```dart
// lib/queue/redis_queue.dart

import 'package:redis/redis.dart';

class RedisJobQueue {
  final RedisConnection _redis;
  final String _queueName;
  final JobRegistry _registry;

  RedisJobQueue(this._redis, this._queueName, this._registry);

  /// Job einreihen
  Future<void> enqueue(Job job) async {
    final json = jsonEncode(job.toJson());
    await _redis.execute(['RPUSH', _queueName, json]);
    print('Job enqueued: ${job.type} (${job.id})');
  }

  /// Job mit Verzögerung einreihen
  Future<void> enqueueDelayed(Job job, Duration delay) async {
    final executeAt = DateTime.now().add(delay).millisecondsSinceEpoch;
    final json = jsonEncode(job.toJson());
    await _redis.execute([
      'ZADD',
      '$_queueName:delayed',
      executeAt.toString(),
      json,
    ]);
  }

  /// Nächsten Job holen (blockierend)
  Future<Job?> dequeue({Duration timeout = const Duration(seconds: 5)}) async {
    final result = await _redis.execute([
      'BLPOP',
      _queueName,
      timeout.inSeconds.toString(),
    ]);

    if (result == null || result.isEmpty) return null;

    final json = jsonDecode(result[1] as String);
    return _registry.createJob(json);
  }

  /// Verzögerte Jobs prüfen
  Future<void> processDelayed() async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Jobs holen die fällig sind
    final result = await _redis.execute([
      'ZRANGEBYSCORE',
      '$_queueName:delayed',
      '0',
      now.toString(),
    ]);

    if (result == null || result.isEmpty) return;

    for (final json in result) {
      // In Hauptqueue verschieben
      await _redis.execute(['RPUSH', _queueName, json]);
      await _redis.execute(['ZREM', '$_queueName:delayed', json]);
    }
  }

  /// Queue-Länge
  Future<int> get length async {
    final result = await _redis.execute(['LLEN', _queueName]);
    return result as int;
  }
}
```

### Job Registry für Deserialisierung

```dart
// lib/queue/job_registry.dart

typedef JobFactory = Job Function(Map<String, dynamic> json);

class JobRegistry {
  final Map<String, JobFactory> _factories = {};

  void register(String type, JobFactory factory) {
    _factories[type] = factory;
  }

  Job createJob(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final factory = _factories[type];

    if (factory == null) {
      throw Exception('Unknown job type: $type');
    }

    return factory(json);
  }
}

// Verwendung
final registry = JobRegistry()
  ..register('send_email', SendEmailJob.fromJson)
  ..register('generate_pdf', GeneratePdfJob.fromJson)
  ..register('notify_webhook', WebhookJob.fromJson);
```

---

## Worker Pattern

### Worker-Klasse

```dart
// lib/worker/worker.dart

class Worker {
  final String id;
  final RedisJobQueue queue;
  final int concurrency;

  bool _isRunning = false;
  final List<Future<void>> _activeTasks = [];

  Worker({
    required this.queue,
    this.concurrency = 1,
    String? id,
  }) : id = id ?? 'worker-${Uuid().v4().substring(0, 8)}';

  /// Worker starten
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    print('Worker $id started (concurrency: $concurrency)');

    while (_isRunning) {
      // Auf freien Slot warten
      while (_activeTasks.length >= concurrency) {
        await Future.any(_activeTasks);
        _activeTasks.removeWhere((f) => f == Future.value());
      }

      // Verzögerte Jobs prüfen
      await queue.processDelayed();

      // Job holen
      final job = await queue.dequeue();
      if (job == null) continue;

      // Job asynchron verarbeiten
      final task = _processJob(job);
      _activeTasks.add(task);
      task.then((_) => _activeTasks.remove(task));
    }
  }

  Future<void> _processJob(Job job) async {
    print('[$id] Processing: ${job.type} (${job.id})');
    job.status = JobStatus.running;
    job.attempts++;

    try {
      await job.execute();
      job.status = JobStatus.completed;
      print('[$id] Completed: ${job.type} (${job.id})');
    } catch (e, stack) {
      print('[$id] Failed: ${job.type} (${job.id}) - $e');

      if (job.shouldRetry) {
        print('[$id] Scheduling retry in ${job.retryDelay.inSeconds}s');
        await queue.enqueueDelayed(job, job.retryDelay);
      } else {
        // In Dead Letter Queue
        await _moveToDeadLetter(job, e.toString());
      }
    }
  }

  Future<void> _moveToDeadLetter(Job job, String error) async {
    // Job mit Fehlerinfo speichern
    final deadJob = {
      ...job.toJson(),
      'error': error,
      'failedAt': DateTime.now().toIso8601String(),
    };
    // In Redis speichern für manuelle Überprüfung
    print('[$id] Moved to dead letter: ${job.id}');
  }

  /// Worker stoppen
  Future<void> stop() async {
    _isRunning = false;
    // Aktive Tasks abwarten
    if (_activeTasks.isNotEmpty) {
      print('[$id] Waiting for ${_activeTasks.length} tasks to complete...');
      await Future.wait(_activeTasks);
    }
    print('[$id] Stopped');
  }
}
```

### Worker-Pool

```dart
// lib/worker/worker_pool.dart

class WorkerPool {
  final List<Worker> _workers = [];
  final RedisJobQueue queue;
  final int workerCount;
  final int concurrencyPerWorker;

  WorkerPool({
    required this.queue,
    this.workerCount = 4,
    this.concurrencyPerWorker = 2,
  });

  /// Pool starten
  Future<void> start() async {
    for (var i = 0; i < workerCount; i++) {
      final worker = Worker(
        queue: queue,
        concurrency: concurrencyPerWorker,
        id: 'worker-$i',
      );
      _workers.add(worker);
      worker.start(); // Non-blocking
    }

    print('Worker pool started: $workerCount workers');
  }

  /// Pool stoppen
  Future<void> stop() async {
    print('Stopping worker pool...');
    await Future.wait(_workers.map((w) => w.stop()));
    _workers.clear();
    print('Worker pool stopped');
  }

  /// Statistiken
  Map<String, dynamic> get stats => {
        'workers': _workers.length,
        'totalConcurrency': workerCount * concurrencyPerWorker,
      };
}
```

---

## Scheduled Tasks (Cron)

### Cron Parser

```dart
// lib/scheduler/cron.dart

class CronExpression {
  final String expression;
  final List<int>? minutes;
  final List<int>? hours;
  final List<int>? daysOfMonth;
  final List<int>? months;
  final List<int>? daysOfWeek;

  CronExpression._(
    this.expression, {
    this.minutes,
    this.hours,
    this.daysOfMonth,
    this.months,
    this.daysOfWeek,
  });

  /// Cron-Ausdruck parsen
  /// Format: minute hour dayOfMonth month dayOfWeek
  /// Beispiele:
  ///   "0 * * * *"     - Jede Stunde
  ///   "0 0 * * *"     - Täglich um Mitternacht
  ///   "0 9 * * 1-5"   - Werktags um 9 Uhr
  ///   "*/15 * * * *"  - Alle 15 Minuten
  factory CronExpression.parse(String expression) {
    final parts = expression.split(' ');
    if (parts.length != 5) {
      throw FormatException('Invalid cron expression: $expression');
    }

    return CronExpression._(
      expression,
      minutes: _parseField(parts[0], 0, 59),
      hours: _parseField(parts[1], 0, 23),
      daysOfMonth: _parseField(parts[2], 1, 31),
      months: _parseField(parts[3], 1, 12),
      daysOfWeek: _parseField(parts[4], 0, 6),
    );
  }

  static List<int>? _parseField(String field, int min, int max) {
    if (field == '*') return null; // Alle Werte

    final values = <int>{};

    for (final part in field.split(',')) {
      if (part.contains('/')) {
        // Step: */5 oder 0-30/5
        final stepParts = part.split('/');
        final step = int.parse(stepParts[1]);
        final range = stepParts[0] == '*'
            ? [min, max]
            : stepParts[0].split('-').map(int.parse).toList();

        for (var i = range[0]; i <= (range.length > 1 ? range[1] : max); i += step) {
          values.add(i);
        }
      } else if (part.contains('-')) {
        // Range: 1-5
        final rangeParts = part.split('-').map(int.parse).toList();
        for (var i = rangeParts[0]; i <= rangeParts[1]; i++) {
          values.add(i);
        }
      } else {
        // Einzelwert
        values.add(int.parse(part));
      }
    }

    return values.toList()..sort();
  }

  /// Prüft ob DateTime zum Ausdruck passt
  bool matches(DateTime dt) {
    if (minutes != null && !minutes!.contains(dt.minute)) return false;
    if (hours != null && !hours!.contains(dt.hour)) return false;
    if (daysOfMonth != null && !daysOfMonth!.contains(dt.day)) return false;
    if (months != null && !months!.contains(dt.month)) return false;
    if (daysOfWeek != null && !daysOfWeek!.contains(dt.weekday % 7)) return false;
    return true;
  }

  /// Nächste Ausführungszeit berechnen
  DateTime nextRun([DateTime? from]) {
    var dt = from ?? DateTime.now();
    dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute + 1);

    // Maximal 2 Jahre suchen
    final maxDate = dt.add(Duration(days: 730));

    while (dt.isBefore(maxDate)) {
      if (matches(dt)) return dt;
      dt = dt.add(Duration(minutes: 1));
    }

    throw StateError('No matching date found');
  }
}
```

### Scheduled Task

```dart
// lib/scheduler/scheduled_task.dart

typedef TaskCallback = Future<void> Function();

class ScheduledTask {
  final String name;
  final CronExpression schedule;
  final TaskCallback callback;
  DateTime? lastRun;
  DateTime? nextRun;
  bool isRunning = false;

  ScheduledTask({
    required this.name,
    required String cron,
    required this.callback,
  }) : schedule = CronExpression.parse(cron) {
    nextRun = schedule.nextRun();
  }

  Future<void> execute() async {
    if (isRunning) {
      print('Task $name already running, skipping');
      return;
    }

    isRunning = true;
    lastRun = DateTime.now();

    try {
      print('Executing scheduled task: $name');
      await callback();
      print('Scheduled task completed: $name');
    } catch (e) {
      print('Scheduled task failed: $name - $e');
    } finally {
      isRunning = false;
      nextRun = schedule.nextRun();
    }
  }
}
```

### Scheduler

```dart
// lib/scheduler/scheduler.dart

class Scheduler {
  final List<ScheduledTask> _tasks = [];
  Timer? _timer;
  bool _isRunning = false;

  /// Task hinzufügen
  void schedule(String name, String cron, TaskCallback callback) {
    _tasks.add(ScheduledTask(
      name: name,
      cron: cron,
      callback: callback,
    ));
    print('Scheduled: $name ($cron)');
  }

  /// Scheduler starten
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Jede Minute prüfen
    _timer = Timer.periodic(Duration(minutes: 1), (_) => _tick());
    print('Scheduler started with ${_tasks.length} tasks');

    // Einmal initial
    _tick();
  }

  void _tick() {
    final now = DateTime.now();

    for (final task in _tasks) {
      if (task.nextRun != null &&
          now.isAfter(task.nextRun!) &&
          !task.isRunning) {
        task.execute();
      }
    }
  }

  /// Scheduler stoppen
  void stop() {
    _timer?.cancel();
    _isRunning = false;
    print('Scheduler stopped');
  }

  /// Nächste Ausführungen anzeigen
  void printSchedule() {
    print('\nScheduled Tasks:');
    for (final task in _tasks) {
      print('  ${task.name}: next run at ${task.nextRun}');
    }
  }
}
```

### Verwendung

```dart
void main() {
  final scheduler = Scheduler();

  // Täglich um Mitternacht
  scheduler.schedule('cleanup', '0 0 * * *', () async {
    await cleanupOldFiles();
  });

  // Alle 15 Minuten
  scheduler.schedule('health_check', '*/15 * * * *', () async {
    await checkExternalServices();
  });

  // Werktags um 9 Uhr
  scheduler.schedule('daily_report', '0 9 * * 1-5', () async {
    await generateDailyReport();
  });

  // Jeden Sonntag um 2 Uhr (Backup)
  scheduler.schedule('weekly_backup', '0 2 * * 0', () async {
    await performBackup();
  });

  scheduler.printSchedule();
  scheduler.start();
}
```

---

## Kombinierte Architektur

### Vollständiges Setup

```dart
// bin/worker.dart

import 'dart:io';

void main() async {
  // Redis-Verbindung
  final redis = await RedisConnection.connect('localhost', 6379);

  // Job Registry
  final registry = JobRegistry()
    ..register('send_email', SendEmailJob.fromJson)
    ..register('generate_pdf', GeneratePdfJob.fromJson)
    ..register('sync_data', SyncDataJob.fromJson);

  // Job Queue
  final queue = RedisJobQueue(redis, 'jobs', registry);

  // Worker Pool
  final workerPool = WorkerPool(
    queue: queue,
    workerCount: int.parse(Platform.environment['WORKERS'] ?? '4'),
    concurrencyPerWorker: 2,
  );

  // Scheduler
  final scheduler = Scheduler()
    ..schedule('process_delayed', '* * * * *', () async {
      await queue.processDelayed();
    })
    ..schedule('cleanup_completed', '0 * * * *', () async {
      // Abgeschlossene Jobs aufräumen
    });

  // Starten
  await workerPool.start();
  scheduler.start();

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    scheduler.stop();
    await workerPool.stop();
    await redis.close();
    exit(0);
  });

  print('Worker service running. Press Ctrl+C to stop.');
}
```

### API zum Einreihen von Jobs

```dart
// In der Haupt-API

router.post('/api/orders', (Request request) async {
  final order = await createOrder(request);

  // Jobs einreihen
  await jobQueue.enqueue(SendEmailJob(
    to: order.customerEmail,
    subject: 'Order Confirmation',
    body: 'Your order ${order.id} has been received.',
  ));

  await jobQueue.enqueue(GeneratePdfJob(
    orderId: order.id,
    outputPath: '/invoices/${order.id}.pdf',
  ));

  // Mit Verzögerung
  await jobQueue.enqueueDelayed(
    FollowUpEmailJob(orderId: order.id),
    Duration(days: 7),
  );

  return Response.ok(jsonEncode(order.toJson()));
});
```

---

## Zusammenfassung

- **Background Jobs** entkoppeln langsame Operationen vom Request
- **Job Queue** speichert Jobs zur späteren Verarbeitung
- **Worker** verarbeiten Jobs parallel
- **Retry-Logik** mit Exponential Backoff für Fehlertoleranz
- **Scheduler** für zeitgesteuerte wiederkehrende Aufgaben
- **Redis** für persistente, skalierbare Queues

### Nächste Schritte

In der nächsten Einheit behandeln wir Logging & Monitoring.
