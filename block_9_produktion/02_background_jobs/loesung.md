# Lösung 9.2: Background Jobs & Scheduling

## Aufgabe 1: Job-Basisklasse

```dart
// lib/jobs/job.dart

import 'package:uuid/uuid.dart';

enum JobStatus { pending, running, completed, failed }
enum JobPriority { low, normal, high, critical }

abstract class Job {
  final String id;
  final DateTime createdAt;
  final JobPriority priority;
  JobStatus status;
  int attempts;
  final int maxAttempts;
  DateTime? startedAt;
  DateTime? completedAt;
  String? error;

  Job({
    String? id,
    this.maxAttempts = 3,
    this.priority = JobPriority.normal,
  })  : id = id ?? const Uuid().v4(),
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

  /// Job-Dauer berechnen
  Duration? get duration {
    if (startedAt == null || completedAt == null) return null;
    return completedAt!.difference(startedAt!);
  }

  /// Basis-JSON mit gemeinsamen Feldern
  Map<String, dynamic> baseToJson() => {
        'id': id,
        'type': type,
        'priority': priority.name,
        'status': status.name,
        'attempts': attempts,
        'maxAttempts': maxAttempts,
        'createdAt': createdAt.toIso8601String(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        if (error != null) 'error': error,
      };
}
```

---

## Aufgabe 2: Konkrete Jobs

```dart
// lib/jobs/email_job.dart

import 'dart:math';
import 'job.dart';

class SendEmailJob extends Job {
  final String to;
  final String subject;
  final String body;
  final List<String>? cc;

  SendEmailJob({
    required this.to,
    required this.subject,
    required this.body,
    this.cc,
    super.maxAttempts = 3,
    super.priority = JobPriority.normal,
  });

  @override
  String get type => 'send_email';

  @override
  Future<void> execute() async {
    print('  Sending email to $to: "$subject"');

    // Simuliere Verarbeitung
    await Future.delayed(Duration(milliseconds: 300 + Random().nextInt(400)));

    // 10% Fehlerrate für Tests
    if (Random().nextDouble() < 0.1) {
      throw Exception('SMTP connection failed');
    }

    print('  Email sent successfully');
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'to': to,
        'subject': subject,
        'body': body,
        if (cc != null) 'cc': cc,
      };

  factory SendEmailJob.fromJson(Map<String, dynamic> json) {
    final job = SendEmailJob(
      to: json['to'] as String,
      subject: json['subject'] as String,
      body: json['body'] as String,
      cc: (json['cc'] as List?)?.cast<String>(),
      maxAttempts: json['maxAttempts'] as int? ?? 3,
      priority: JobPriority.values.byName(json['priority'] as String? ?? 'normal'),
    );
    job.attempts = json['attempts'] as int? ?? 0;
    return job;
  }
}

// lib/jobs/webhook_job.dart

import 'dart:convert';
import 'dart:math';
import 'job.dart';

class WebhookJob extends Job {
  final String url;
  final Map<String, dynamic> payload;
  final Map<String, String>? headers;

  WebhookJob({
    required this.url,
    required this.payload,
    this.headers,
    super.maxAttempts = 5,
    super.priority = JobPriority.high,
  });

  @override
  String get type => 'webhook';

  @override
  Future<void> execute() async {
    print('  Calling webhook: $url');

    // Simuliere HTTP Call
    await Future.delayed(Duration(milliseconds: 200 + Random().nextInt(300)));

    // 15% Fehlerrate
    if (Random().nextDouble() < 0.15) {
      throw Exception('Webhook returned 503');
    }

    print('  Webhook called successfully');
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'url': url,
        'payload': payload,
        if (headers != null) 'headers': headers,
      };

  factory WebhookJob.fromJson(Map<String, dynamic> json) {
    final job = WebhookJob(
      url: json['url'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      headers: (json['headers'] as Map?)?.cast<String, String>(),
      maxAttempts: json['maxAttempts'] as int? ?? 5,
      priority: JobPriority.values.byName(json['priority'] as String? ?? 'high'),
    );
    job.attempts = json['attempts'] as int? ?? 0;
    return job;
  }
}

// lib/jobs/cleanup_job.dart

import 'dart:io';
import 'job.dart';

class CleanupJob extends Job {
  final String directory;
  final int maxAgeDays;

  CleanupJob({
    required this.directory,
    this.maxAgeDays = 30,
    super.maxAttempts = 1,
    super.priority = JobPriority.low,
  });

  @override
  String get type => 'cleanup';

  @override
  Future<void> execute() async {
    print('  Cleaning up $directory (files older than $maxAgeDays days)');

    final dir = Directory(directory);
    if (!await dir.exists()) {
      print('  Directory does not exist, skipping');
      return;
    }

    final cutoff = DateTime.now().subtract(Duration(days: maxAgeDays));
    int deletedCount = 0;

    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
          deletedCount++;
        }
      }
    }

    print('  Deleted $deletedCount files');
  }

  @override
  Map<String, dynamic> toJson() => {
        ...baseToJson(),
        'directory': directory,
        'maxAgeDays': maxAgeDays,
      };

  factory CleanupJob.fromJson(Map<String, dynamic> json) {
    return CleanupJob(
      directory: json['directory'] as String,
      maxAgeDays: json['maxAgeDays'] as int? ?? 30,
    );
  }
}
```

---

## Aufgabe 3: Job Registry

```dart
// lib/queue/job_registry.dart

import '../jobs/job.dart';

typedef JobFactory = Job Function(Map<String, dynamic> json);

class JobRegistry {
  final Map<String, JobFactory> _factories = {};

  /// Job-Typ registrieren
  void register(String type, JobFactory factory) {
    _factories[type] = factory;
    print('Registered job type: $type');
  }

  /// Job aus JSON erstellen
  Job createJob(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == null) {
      throw ArgumentError('Job JSON must contain "type" field');
    }

    final factory = _factories[type];
    if (factory == null) {
      throw ArgumentError('Unknown job type: $type');
    }

    return factory(json);
  }

  /// Alle registrierten Typen
  List<String> get registeredTypes => _factories.keys.toList();

  /// Prüfen ob Typ registriert ist
  bool hasType(String type) => _factories.containsKey(type);
}
```

---

## Aufgabe 4: In-Memory Queue

```dart
// lib/queue/memory_queue.dart

import 'dart:async';
import 'dart:collection';
import '../jobs/job.dart';

class MemoryJobQueue {
  // Priority Queues
  final Map<JobPriority, Queue<Job>> _queues = {
    JobPriority.critical: Queue<Job>(),
    JobPriority.high: Queue<Job>(),
    JobPriority.normal: Queue<Job>(),
    JobPriority.low: Queue<Job>(),
  };

  final List<Job> _completed = [];
  final List<Job> _failed = [];
  final List<Timer> _delayedTimers = [];

  final _completedController = StreamController<Job>.broadcast();
  Stream<Job> get onJobCompleted => _completedController.stream;

  /// Job einreihen
  void enqueue(Job job) {
    _queues[job.priority]!.add(job);
    print('Enqueued: ${job.type} (${job.id}) [${job.priority.name}]');
  }

  /// Job mit Verzögerung einreihen
  void enqueueDelayed(Job job, Duration delay) {
    print('Scheduling ${job.type} in ${delay.inSeconds}s');
    final timer = Timer(delay, () => enqueue(job));
    _delayedTimers.add(timer);
  }

  /// Nächsten Job holen (höchste Priority zuerst)
  Job? dequeue() {
    // Von höchster zu niedrigster Priorität
    for (final priority in [
      JobPriority.critical,
      JobPriority.high,
      JobPriority.normal,
      JobPriority.low,
    ]) {
      final queue = _queues[priority]!;
      if (queue.isNotEmpty) {
        return queue.removeFirst();
      }
    }
    return null;
  }

  /// Job als abgeschlossen markieren
  void markCompleted(Job job) {
    job.status = JobStatus.completed;
    job.completedAt = DateTime.now();
    _completed.add(job);
    _completedController.add(job);
  }

  /// Job als fehlgeschlagen markieren
  void markFailed(Job job, String error) {
    job.error = error;

    if (job.shouldRetry) {
      print('Retry ${job.attempts}/${job.maxAttempts} in ${job.retryDelay.inSeconds}s');
      job.status = JobStatus.pending;
      enqueueDelayed(job, job.retryDelay);
    } else {
      job.status = JobStatus.failed;
      _failed.add(job);
      print('Job failed permanently: ${job.type} (${job.id})');
    }
  }

  /// Anzahl wartender Jobs
  int get pendingCount {
    return _queues.values.fold(0, (sum, q) => sum + q.length);
  }

  /// Ist leer?
  bool get isEmpty => pendingCount == 0;

  /// Statistiken
  Map<String, dynamic> get stats => {
        'pending': {
          'total': pendingCount,
          'critical': _queues[JobPriority.critical]!.length,
          'high': _queues[JobPriority.high]!.length,
          'normal': _queues[JobPriority.normal]!.length,
          'low': _queues[JobPriority.low]!.length,
        },
        'completed': _completed.length,
        'failed': _failed.length,
      };

  /// Abgeschlossene Jobs
  List<Job> get completedJobs => List.unmodifiable(_completed);

  /// Fehlgeschlagene Jobs
  List<Job> get failedJobs => List.unmodifiable(_failed);

  /// Queue leeren
  void clear() {
    for (final queue in _queues.values) {
      queue.clear();
    }
    _completed.clear();
    _failed.clear();
    for (final timer in _delayedTimers) {
      timer.cancel();
    }
    _delayedTimers.clear();
  }

  void dispose() {
    clear();
    _completedController.close();
  }
}
```

---

## Aufgabe 5: Worker

```dart
// lib/worker/worker.dart

import 'dart:async';
import '../jobs/job.dart';
import '../queue/memory_queue.dart';

class WorkerStatus {
  final String workerId;
  final bool isRunning;
  final int activeJobs;
  final int processedJobs;
  final DateTime timestamp;

  WorkerStatus({
    required this.workerId,
    required this.isRunning,
    required this.activeJobs,
    required this.processedJobs,
  }) : timestamp = DateTime.now();

  Map<String, dynamic> toJson() => {
        'workerId': workerId,
        'isRunning': isRunning,
        'activeJobs': activeJobs,
        'processedJobs': processedJobs,
        'timestamp': timestamp.toIso8601String(),
      };
}

class Worker {
  final String id;
  final MemoryJobQueue queue;
  final int concurrency;

  bool _isRunning = false;
  int _activeJobs = 0;
  int _processedJobs = 0;
  final List<Future<void>> _runningTasks = [];

  final _statusController = StreamController<WorkerStatus>.broadcast();
  Stream<WorkerStatus> get status => _statusController.stream;

  Worker({
    required this.queue,
    this.concurrency = 1,
    String? id,
  }) : id = id ?? 'worker-${DateTime.now().millisecondsSinceEpoch}';

  bool get isRunning => _isRunning;

  /// Worker starten
  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    print('Worker $id started (concurrency: $concurrency)');
    _emitStatus();

    while (_isRunning) {
      // Warte wenn Queue leer
      if (queue.isEmpty) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }

      // Warte wenn max concurrency erreicht
      if (_activeJobs >= concurrency) {
        await Future.delayed(Duration(milliseconds: 50));
        continue;
      }

      // Job holen und verarbeiten
      final job = queue.dequeue();
      if (job != null) {
        _activeJobs++;
        _emitStatus();

        final task = _processJob(job).then((_) {
          _activeJobs--;
          _processedJobs++;
          _emitStatus();
        });

        _runningTasks.add(task);
        task.then((_) => _runningTasks.remove(task));
      }
    }
  }

  /// Einzelnen Job verarbeiten
  Future<void> _processJob(Job job) async {
    print('[$id] Processing: ${job.type} (${job.id}) - Attempt ${job.attempts + 1}');

    job.status = JobStatus.running;
    job.attempts++;
    job.startedAt = DateTime.now();

    try {
      await job.execute();
      queue.markCompleted(job);
      print('[$id] Completed: ${job.type} (${job.id}) in ${job.duration?.inMilliseconds}ms');
    } catch (e) {
      print('[$id] Failed: ${job.type} (${job.id}) - $e');
      queue.markFailed(job, e.toString());
    }
  }

  /// Worker stoppen
  Future<void> stop() async {
    print('[$id] Stopping...');
    _isRunning = false;

    // Auf aktive Tasks warten
    if (_runningTasks.isNotEmpty) {
      print('[$id] Waiting for ${_runningTasks.length} active jobs...');
      await Future.wait(_runningTasks);
    }

    print('[$id] Stopped (processed: $_processedJobs jobs)');
    _statusController.close();
  }

  void _emitStatus() {
    if (!_statusController.isClosed) {
      _statusController.add(getStatus());
    }
  }

  WorkerStatus getStatus() => WorkerStatus(
        workerId: id,
        isRunning: _isRunning,
        activeJobs: _activeJobs,
        processedJobs: _processedJobs,
      );
}
```

---

## Aufgabe 6: Cron Parser

```dart
// lib/scheduler/cron.dart

class CronExpression {
  final String expression;
  final List<int>? minutes;
  final List<int>? hours;
  final List<int>? daysOfWeek;

  CronExpression._({
    required this.expression,
    this.minutes,
    this.hours,
    this.daysOfWeek,
  });

  factory CronExpression.parse(String expression) {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (parts.length != 3) {
      throw FormatException(
        'Expected 3 parts (minute hour dayOfWeek), got ${parts.length}',
      );
    }

    return CronExpression._(
      expression: expression,
      minutes: _parseField(parts[0], 0, 59),
      hours: _parseField(parts[1], 0, 23),
      daysOfWeek: _parseField(parts[2], 0, 6),
    );
  }

  static List<int>? _parseField(String field, int min, int max) {
    // Wildcard - alle Werte
    if (field == '*') return null;

    final values = <int>{};

    for (final part in field.split(',')) {
      if (part.contains('/')) {
        // Step: */5 oder 0-30/5
        final stepParts = part.split('/');
        final step = int.parse(stepParts[1]);

        int start = min;
        int end = max;

        if (stepParts[0] != '*') {
          if (stepParts[0].contains('-')) {
            final range = stepParts[0].split('-');
            start = int.parse(range[0]);
            end = int.parse(range[1]);
          } else {
            start = int.parse(stepParts[0]);
          }
        }

        for (var i = start; i <= end; i += step) {
          values.add(i);
        }
      } else if (part.contains('-')) {
        // Range: 1-5
        final range = part.split('-');
        final start = int.parse(range[0]);
        final end = int.parse(range[1]);

        for (var i = start; i <= end; i++) {
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
    if (daysOfWeek != null && !daysOfWeek!.contains(dt.weekday % 7)) return false;
    return true;
  }

  /// Nächste Ausführungszeit
  DateTime nextRun([DateTime? from]) {
    var dt = from ?? DateTime.now();
    // Nächste Minute
    dt = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute + 1);

    // Maximal 7 Tage suchen
    final maxDate = dt.add(Duration(days: 7));

    while (dt.isBefore(maxDate)) {
      if (matches(dt)) return dt;
      dt = dt.add(Duration(minutes: 1));
    }

    throw StateError('No matching time found within 7 days');
  }

  @override
  String toString() => 'CronExpression($expression)';
}
```

---

## Aufgabe 7: Scheduler

```dart
// lib/scheduler/scheduler.dart

import 'dart:async';
import 'cron.dart';

typedef TaskCallback = Future<void> Function();

class ScheduledTask {
  final String name;
  final CronExpression schedule;
  final TaskCallback callback;
  DateTime? lastRun;
  DateTime? nextRun;
  bool isRunning;
  int runCount;
  int errorCount;
  String? lastError;

  ScheduledTask({
    required this.name,
    required String cron,
    required this.callback,
  })  : schedule = CronExpression.parse(cron),
        isRunning = false,
        runCount = 0,
        errorCount = 0 {
    _updateNextRun();
  }

  void _updateNextRun() {
    try {
      nextRun = schedule.nextRun();
    } catch (e) {
      nextRun = null;
    }
  }

  Future<void> execute() async {
    if (isRunning) {
      print('Task "$name" already running, skipping');
      return;
    }

    isRunning = true;
    lastRun = DateTime.now();
    lastError = null;

    try {
      print('Executing task: $name');
      await callback();
      runCount++;
      print('Task completed: $name');
    } catch (e) {
      errorCount++;
      lastError = e.toString();
      print('Task failed: $name - $e');
    } finally {
      isRunning = false;
      _updateNextRun();
    }
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'schedule': schedule.expression,
        'isRunning': isRunning,
        'runCount': runCount,
        'errorCount': errorCount,
        'lastRun': lastRun?.toIso8601String(),
        'nextRun': nextRun?.toIso8601String(),
        if (lastError != null) 'lastError': lastError,
      };
}

class Scheduler {
  final List<ScheduledTask> _tasks = [];
  Timer? _timer;
  bool _isRunning = false;

  /// Task hinzufügen
  void schedule(String name, String cron, TaskCallback callback) {
    final task = ScheduledTask(name: name, cron: cron, callback: callback);
    _tasks.add(task);
    print('Scheduled: "$name" (${task.schedule.expression}) - next: ${task.nextRun}');
  }

  /// Scheduler starten
  void start() {
    if (_isRunning) return;
    _isRunning = true;

    // Alle 30 Sekunden prüfen
    _timer = Timer.periodic(Duration(seconds: 30), (_) => _tick());
    print('Scheduler started with ${_tasks.length} tasks');

    // Initial tick
    _tick();
  }

  void _tick() {
    final now = DateTime.now();

    for (final task in _tasks) {
      if (task.nextRun != null &&
          now.isAfter(task.nextRun!) &&
          !task.isRunning) {
        // Asynchron ausführen
        task.execute();
      }
    }
  }

  /// Task manuell ausführen
  Future<bool> runTask(String name) async {
    final task = _tasks.where((t) => t.name == name).firstOrNull;
    if (task == null) return false;

    await task.execute();
    return true;
  }

  /// Scheduler stoppen
  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    print('Scheduler stopped');
  }

  /// Task finden
  ScheduledTask? getTask(String name) {
    return _tasks.where((t) => t.name == name).firstOrNull;
  }

  /// Alle Tasks auflisten
  List<Map<String, dynamic>> getTaskInfo() {
    return _tasks.map((t) => t.toJson()).toList();
  }

  bool get isRunning => _isRunning;
  int get taskCount => _tasks.length;
}
```

---

## Aufgabe 8: Server Integration

```dart
// bin/server.dart

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/jobs/job.dart';
import '../lib/jobs/email_job.dart';
import '../lib/jobs/webhook_job.dart';
import '../lib/jobs/cleanup_job.dart';
import '../lib/queue/job_registry.dart';
import '../lib/queue/memory_queue.dart';
import '../lib/worker/worker.dart';
import '../lib/scheduler/scheduler.dart';

void main() async {
  // Registry
  final registry = JobRegistry()
    ..register('send_email', SendEmailJob.fromJson)
    ..register('webhook', WebhookJob.fromJson)
    ..register('cleanup', CleanupJob.fromJson);

  // Queue
  final queue = MemoryJobQueue();

  // Worker
  final worker = Worker(queue: queue, concurrency: 3);
  worker.start();

  // Scheduler
  final scheduler = Scheduler();

  scheduler.schedule('health_log', '* * *', () async {
    print('[Health] System OK at ${DateTime.now()}');
  });

  scheduler.schedule('queue_stats', '*/5 * *', () async {
    print('[Stats] Queue: ${queue.stats}');
  });

  scheduler.start();

  // Router
  final router = Router();

  // POST /jobs - Job einreihen
  router.post('/jobs', (Request request) async {
    try {
      final body = await request.readAsString();
      final json = jsonDecode(body) as Map<String, dynamic>;

      if (!registry.hasType(json['type'] as String? ?? '')) {
        return Response.badRequest(
          body: jsonEncode({
            'error': 'Unknown job type',
            'registeredTypes': registry.registeredTypes,
          }),
          headers: {'content-type': 'application/json'},
        );
      }

      final job = registry.createJob(json);
      queue.enqueue(job);

      return Response.ok(
        jsonEncode({
          'success': true,
          'jobId': job.id,
          'type': job.type,
          'priority': job.priority.name,
        }),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // POST /jobs/batch - Mehrere Jobs einreihen
  router.post('/jobs/batch', (Request request) async {
    try {
      final body = await request.readAsString();
      final jobs = (jsonDecode(body) as List).cast<Map<String, dynamic>>();

      final results = <Map<String, dynamic>>[];

      for (final json in jobs) {
        try {
          final job = registry.createJob(json);
          queue.enqueue(job);
          results.add({'jobId': job.id, 'status': 'enqueued'});
        } catch (e) {
          results.add({'error': e.toString(), 'status': 'failed'});
        }
      }

      return Response.ok(
        jsonEncode({'jobs': results}),
        headers: {'content-type': 'application/json'},
      );
    } catch (e) {
      return Response.badRequest(
        body: jsonEncode({'error': e.toString()}),
        headers: {'content-type': 'application/json'},
      );
    }
  });

  // GET /jobs/stats - Statistiken
  router.get('/jobs/stats', (Request request) {
    return Response.ok(
      jsonEncode({
        'queue': queue.stats,
        'worker': worker.getStatus().toJson(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /jobs/completed - Abgeschlossene Jobs
  router.get('/jobs/completed', (Request request) {
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
    final jobs = queue.completedJobs.reversed.take(limit).map((j) => j.toJson());

    return Response.ok(
      jsonEncode({'jobs': jobs.toList()}),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /jobs/failed - Fehlgeschlagene Jobs
  router.get('/jobs/failed', (Request request) {
    final jobs = queue.failedJobs.map((j) => j.toJson());

    return Response.ok(
      jsonEncode({'jobs': jobs.toList()}),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /scheduler - Tasks
  router.get('/scheduler', (Request request) {
    return Response.ok(
      jsonEncode({
        'isRunning': scheduler.isRunning,
        'taskCount': scheduler.taskCount,
        'tasks': scheduler.getTaskInfo(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // POST /scheduler/:name/run - Manuell ausführen
  router.post('/scheduler/<name>/run', (Request request, String name) async {
    final success = await scheduler.runTask(name);

    if (!success) {
      return Response.notFound(
        jsonEncode({'error': 'Task not found: $name'}),
        headers: {'content-type': 'application/json'},
      );
    }

    return Response.ok(
      jsonEncode({'success': true, 'task': name}),
      headers: {'content-type': 'application/json'},
    );
  });

  // GET /types - Registrierte Job-Typen
  router.get('/types', (Request request) {
    return Response.ok(
      jsonEncode({'types': registry.registeredTypes}),
      headers: {'content-type': 'application/json'},
    );
  });

  // Handler mit Middleware
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware())
      .addHandler(router.call);

  // Server starten
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  print('');
  print('╔══════════════════════════════════════════════════════════╗');
  print('║             Job Server Running on port $port              ║');
  print('╠══════════════════════════════════════════════════════════╣');
  print('║ Endpoints:                                               ║');
  print('║   POST /jobs          - Enqueue a job                    ║');
  print('║   POST /jobs/batch    - Enqueue multiple jobs            ║');
  print('║   GET  /jobs/stats    - Queue and worker stats           ║');
  print('║   GET  /jobs/completed - List completed jobs             ║');
  print('║   GET  /jobs/failed   - List failed jobs                 ║');
  print('║   GET  /scheduler     - List scheduled tasks             ║');
  print('║   POST /scheduler/:name/run - Run task manually          ║');
  print('║   GET  /types         - List registered job types        ║');
  print('╚══════════════════════════════════════════════════════════╝');
  print('');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    scheduler.stop();
    await worker.stop();
    queue.dispose();
    await server.close();
    exit(0);
  });
}

Middleware _corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  return (Handler inner) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await inner(request);
      return response.change(headers: headers);
    };
  };
}
```

---

## Projektstruktur

```
job_server/
├── bin/
│   └── server.dart
├── lib/
│   ├── jobs/
│   │   ├── job.dart
│   │   ├── email_job.dart
│   │   ├── webhook_job.dart
│   │   └── cleanup_job.dart
│   ├── queue/
│   │   ├── job_registry.dart
│   │   └── memory_queue.dart
│   ├── worker/
│   │   └── worker.dart
│   └── scheduler/
│       ├── cron.dart
│       └── scheduler.dart
├── pubspec.yaml
└── README.md
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# Email Job einreihen
curl -X POST http://localhost:8080/jobs \
  -H "Content-Type: application/json" \
  -d '{"type": "send_email", "to": "test@example.com", "subject": "Hello", "body": "World"}'

# Mehrere Jobs (Batch)
curl -X POST http://localhost:8080/jobs/batch \
  -H "Content-Type: application/json" \
  -d '[
    {"type": "send_email", "to": "a@test.com", "subject": "Test 1", "body": "Body 1"},
    {"type": "send_email", "to": "b@test.com", "subject": "Test 2", "body": "Body 2"},
    {"type": "webhook", "url": "https://httpbin.org/post", "payload": {"test": true}}
  ]'

# Stats abrufen
curl http://localhost:8080/jobs/stats | jq

# Scheduler-Tasks
curl http://localhost:8080/scheduler | jq

# Task manuell ausführen
curl -X POST http://localhost:8080/scheduler/health_log/run

# Job-Typen anzeigen
curl http://localhost:8080/types
```
