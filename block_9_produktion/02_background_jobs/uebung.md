# Übung 9.2: Background Jobs & Scheduling

## Ziel

Implementiere ein Job-System mit Queue, Worker und Scheduler.

---

## Vorbereitung

### Dependencies

```yaml
# pubspec.yaml
dependencies:
  uuid: ^4.0.0
  redis: ^3.0.0  # Optional für Redis-Queue
```

### Redis (Optional)

```bash
docker run -d -p 6379:6379 redis:7
```

---

## Aufgabe 1: Job-Basisklasse (15 min)

Erstelle die abstrakte Job-Klasse.

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
  })  : id = id ?? Uuid().v4(),
        createdAt = DateTime.now(),
        status = JobStatus.pending,
        attempts = 0;

  /// Job-Typ für Serialisierung
  String get type;

  /// Job ausführen - implementieren in Subklassen
  Future<void> execute();

  /// Zu JSON konvertieren
  Map<String, dynamic> toJson();

  /// Sollte bei Fehler wiederholt werden?
  bool get shouldRetry {
    // TODO: Implementieren
  }

  /// Delay vor Retry (exponential backoff)
  Duration get retryDelay {
    // TODO: 2^attempts Sekunden
  }

  /// Job-Dauer berechnen
  Duration? get duration {
    // TODO: Differenz zwischen completedAt und startedAt
  }
}
```

---

## Aufgabe 2: Konkrete Jobs (20 min)

Implementiere verschiedene Job-Typen.

```dart
// lib/jobs/email_job.dart

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
    // TODO: Simuliere Email-Versand (500ms delay)
    // TODO: 10% Fehlerrate simulieren für Retry-Tests
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO: Alle Felder serialisieren
  }

  factory SendEmailJob.fromJson(Map<String, dynamic> json) {
    // TODO: Aus JSON erstellen
  }
}

// lib/jobs/webhook_job.dart

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
    // TODO: HTTP POST an URL mit payload
    // TODO: Bei nicht-2xx Status Exception werfen
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO
  }

  factory WebhookJob.fromJson(Map<String, dynamic> json) {
    // TODO
  }
}

// lib/jobs/cleanup_job.dart

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
    // TODO: Dateien älter als maxAgeDays löschen
    // TODO: Anzahl gelöschter Dateien loggen
  }

  @override
  Map<String, dynamic> toJson() {
    // TODO
  }
}
```

---

## Aufgabe 3: Job Registry (10 min)

Implementiere die Factory für Job-Deserialisierung.

```dart
// lib/queue/job_registry.dart

typedef JobFactory = Job Function(Map<String, dynamic> json);

class JobRegistry {
  final Map<String, JobFactory> _factories = {};

  /// Job-Typ registrieren
  void register(String type, JobFactory factory) {
    // TODO
  }

  /// Job aus JSON erstellen
  Job createJob(Map<String, dynamic> json) {
    // TODO: type aus JSON lesen
    // TODO: passende Factory finden
    // TODO: Job erstellen oder Exception werfen
  }

  /// Alle registrierten Typen
  List<String> get registeredTypes {
    // TODO
  }
}
```

---

## Aufgabe 4: In-Memory Queue (25 min)

Implementiere eine einfache Queue mit Priority-Support.

```dart
// lib/queue/memory_queue.dart

import 'dart:async';
import 'dart:collection';

class MemoryJobQueue {
  // Priority Queues (high priority first)
  final Map<JobPriority, Queue<Job>> _queues = {
    for (final p in JobPriority.values) p: Queue<Job>(),
  };

  final List<Job> _completed = [];
  final List<Job> _failed = [];
  final _completedController = StreamController<Job>.broadcast();

  Stream<Job> get onJobCompleted => _completedController.stream;

  /// Job einreihen
  void enqueue(Job job) {
    // TODO: In richtige Priority-Queue einfügen
    // TODO: Log ausgeben
  }

  /// Job mit Verzögerung einreihen
  void enqueueDelayed(Job job, Duration delay) {
    // TODO: Timer erstellen der Job später einreiht
  }

  /// Nächsten Job holen (höchste Priority zuerst)
  Job? dequeue() {
    // TODO: Von critical nach low durchgehen
    // TODO: Ersten verfügbaren Job zurückgeben
  }

  /// Job als abgeschlossen markieren
  void markCompleted(Job job) {
    // TODO: Status setzen
    // TODO: In completed-Liste
    // TODO: Event auslösen
  }

  /// Job als fehlgeschlagen markieren
  void markFailed(Job job, String error) {
    // TODO: Error setzen
    // TODO: In failed-Liste oder retry
  }

  /// Statistiken
  Map<String, dynamic> get stats {
    // TODO: Pending pro Priority, completed, failed
  }

  /// Queue leeren
  void clear() {
    // TODO
  }
}
```

---

## Aufgabe 5: Worker (25 min)

Implementiere den Worker der Jobs verarbeitet.

```dart
// lib/worker/worker.dart

class Worker {
  final String id;
  final MemoryJobQueue queue;
  final int concurrency;

  bool _isRunning = false;
  int _activeJobs = 0;
  int _processedJobs = 0;

  final _statusController = StreamController<WorkerStatus>.broadcast();
  Stream<WorkerStatus> get status => _statusController.stream;

  Worker({
    required this.queue,
    this.concurrency = 1,
    String? id,
  }) : id = id ?? 'worker-${DateTime.now().millisecondsSinceEpoch}';

  /// Worker starten
  Future<void> start() async {
    // TODO: _isRunning setzen
    // TODO: Loop der Jobs verarbeitet
    // TODO: Concurrency beachten
    // TODO: Bei leerem Queue kurz warten
  }

  /// Einzelnen Job verarbeiten
  Future<void> _processJob(Job job) async {
    // TODO: Job-Status auf running
    // TODO: attempts erhöhen
    // TODO: startedAt setzen
    // TODO: execute() aufrufen
    // TODO: Bei Erfolg: markCompleted
    // TODO: Bei Fehler: Retry oder markFailed
  }

  /// Worker stoppen
  Future<void> stop() async {
    // TODO: _isRunning = false
    // TODO: Auf aktive Jobs warten
  }

  /// Status-Info
  WorkerStatus getStatus() {
    // TODO
  }
}

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
```

---

## Aufgabe 6: Cron Parser (20 min)

Implementiere einen einfachen Cron-Parser.

```dart
// lib/scheduler/cron.dart

class CronExpression {
  final String expression;
  final List<int>? minutes;    // 0-59
  final List<int>? hours;      // 0-23
  final List<int>? daysOfWeek; // 0-6 (0 = Sonntag)

  CronExpression._({
    required this.expression,
    this.minutes,
    this.hours,
    this.daysOfWeek,
  });

  /// Vereinfachter Parser für:
  /// - "* * *" (minute hour dayOfWeek)
  /// - "*" = jeder Wert
  /// - "5" = genau dieser Wert
  /// - "1,3,5" = Liste
  /// - "1-5" = Range
  /// - "*/15" = Alle 15
  factory CronExpression.parse(String expression) {
    final parts = expression.split(' ');
    if (parts.length != 3) {
      throw FormatException('Expected 3 parts: minute hour dayOfWeek');
    }

    return CronExpression._(
      expression: expression,
      minutes: _parseField(parts[0], 0, 59),
      hours: _parseField(parts[1], 0, 23),
      daysOfWeek: _parseField(parts[2], 0, 6),
    );
  }

  static List<int>? _parseField(String field, int min, int max) {
    // TODO: "*" → null (alle)
    // TODO: "5" → [5]
    // TODO: "1,3,5" → [1, 3, 5]
    // TODO: "1-5" → [1, 2, 3, 4, 5]
    // TODO: "*/15" → [0, 15, 30, 45] (bei min=0, max=59)
  }

  /// Prüft ob DateTime zum Ausdruck passt
  bool matches(DateTime dt) {
    // TODO: Alle Felder prüfen
  }

  /// Nächste Ausführungszeit
  DateTime nextRun([DateTime? from]) {
    // TODO: Von jetzt (oder from) aus suchen
    // TODO: Minutenweise prüfen bis Match
  }
}
```

---

## Aufgabe 7: Scheduler (20 min)

Implementiere den Task-Scheduler.

```dart
// lib/scheduler/scheduler.dart

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

  ScheduledTask({
    required this.name,
    required String cron,
    required this.callback,
  })  : schedule = CronExpression.parse(cron),
        isRunning = false,
        runCount = 0,
        errorCount = 0 {
    nextRun = schedule.nextRun();
  }

  Future<void> execute() async {
    // TODO: Guard gegen doppelte Ausführung
    // TODO: Status aktualisieren
    // TODO: Callback ausführen
    // TODO: Error handling
    // TODO: nextRun berechnen
  }
}

class Scheduler {
  final List<ScheduledTask> _tasks = [];
  Timer? _timer;
  bool _isRunning = false;

  /// Task hinzufügen
  void schedule(String name, String cron, TaskCallback callback) {
    // TODO: ScheduledTask erstellen und speichern
  }

  /// Scheduler starten
  void start() {
    // TODO: Timer alle 60 Sekunden
    // TODO: Bei jedem Tick prüfen welche Tasks fällig sind
  }

  void _tick() {
    // TODO: Aktuelle Zeit
    // TODO: Für jeden Task prüfen ob nextRun erreicht
    // TODO: Falls ja und nicht running: execute()
  }

  /// Scheduler stoppen
  void stop() {
    // TODO
  }

  /// Alle Tasks auflisten
  List<Map<String, dynamic>> getTaskInfo() {
    // TODO: Name, lastRun, nextRun, runCount, errorCount
  }
}
```

---

## Aufgabe 8: Integration & API (20 min)

Erstelle einen Server mit Job-Queue und Scheduler.

```dart
// bin/server.dart

import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  // TODO: Queue und Registry erstellen
  final registry = JobRegistry()
    ..register('send_email', SendEmailJob.fromJson)
    ..register('webhook', WebhookJob.fromJson);

  final queue = MemoryJobQueue();

  // TODO: Worker starten
  final worker = Worker(queue: queue, concurrency: 3);
  worker.start();

  // TODO: Scheduler erstellen
  final scheduler = Scheduler();

  scheduler.schedule('health_log', '* * *', () async {
    print('Health check: ${DateTime.now()}');
  });

  scheduler.schedule('queue_stats', '*/5 * *', () async {
    print('Queue stats: ${queue.stats}');
  });

  scheduler.start();

  // API Router
  final router = Router();

  // POST /jobs - Job einreihen
  router.post('/jobs', (Request request) async {
    // TODO: Body parsen
    // TODO: Job über Registry erstellen
    // TODO: In Queue einreihen
    // TODO: Job-ID zurückgeben
  });

  // GET /jobs/stats - Queue-Statistiken
  router.get('/jobs/stats', (Request request) {
    // TODO: queue.stats und worker.getStatus() zurückgeben
  });

  // GET /scheduler - Scheduled Tasks
  router.get('/scheduler', (Request request) {
    // TODO: scheduler.getTaskInfo() zurückgeben
  });

  // POST /scheduler/:name/run - Task manuell ausführen
  router.post('/scheduler/<name>/run', (Request request, String name) async {
    // TODO: Task finden und ausführen
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  final server = await io.serve(handler, 'localhost', 8080);
  print('Job server running on http://localhost:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    scheduler.stop();
    await worker.stop();
    await server.close();
    exit(0);
  });
}
```

---

## Testen

### Jobs einreihen

```bash
# Email Job
curl -X POST http://localhost:8080/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "type": "send_email",
    "to": "test@example.com",
    "subject": "Test",
    "body": "Hello World"
  }'

# Webhook Job mit hoher Priorität
curl -X POST http://localhost:8080/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "type": "webhook",
    "url": "https://httpbin.org/post",
    "payload": {"event": "test"},
    "priority": "high"
  }'
```

### Stats abrufen

```bash
curl http://localhost:8080/jobs/stats
curl http://localhost:8080/scheduler
```

### Task manuell ausführen

```bash
curl -X POST http://localhost:8080/scheduler/health_log/run
```

---

## Bonus: Redis Queue (Optional)

```dart
// lib/queue/redis_queue.dart

class RedisJobQueue {
  final RedisConnection redis;
  final String queueName;
  final JobRegistry registry;

  RedisJobQueue(this.redis, this.queueName, this.registry);

  Future<void> enqueue(Job job) async {
    // TODO: RPUSH mit JSON
  }

  Future<Job?> dequeue() async {
    // TODO: BLPOP mit Timeout
  }

  Future<void> enqueueDelayed(Job job, Duration delay) async {
    // TODO: ZADD in sorted set mit Timestamp
  }

  Future<void> processDelayed() async {
    // TODO: ZRANGEBYSCORE für fällige Jobs
    // TODO: In Hauptqueue verschieben
  }
}
```

---

## Abgabe-Checkliste

- [ ] Job-Basisklasse mit Retry-Logik
- [ ] Mindestens 2 konkrete Job-Typen
- [ ] JobRegistry für Deserialisierung
- [ ] MemoryJobQueue mit Priority-Support
- [ ] Worker mit Concurrency
- [ ] CronExpression Parser
- [ ] Scheduler mit Tasks
- [ ] REST API für Jobs und Scheduler
- [ ] Graceful Shutdown
- [ ] Bonus: Redis Queue
