# Einheit 9.3: Logging & Monitoring

## Lernziele

- Strukturiertes Logging implementieren
- Log-Level richtig einsetzen
- Health Checks erstellen
- Metriken sammeln und exponieren
- Alerting-Grundlagen verstehen

---

## Warum Logging & Monitoring?

### Die Realität in Produktion

```
"Es funktioniert auf meinem Rechner" → Produktion

Was passiert wirklich?
- Wie viele Requests/Sekunde?
- Welche Fehler treten auf?
- Wie lange dauern Requests?
- Ist die Datenbank erreichbar?
- Läuft der Speicher voll?
```

### Die drei Säulen der Observability

| Säule | Zweck | Beispiel |
|-------|-------|----------|
| **Logs** | Was ist passiert? | "User 123 hat sich eingeloggt" |
| **Metriken** | Wie performt das System? | "95% der Requests < 200ms" |
| **Traces** | Wie fließen Requests? | Request → Auth → DB → Response |

---

## Strukturiertes Logging

### Das Problem mit unstrukturierten Logs

```dart
// ❌ Schwer zu parsen und filtern
print('User logged in: john@example.com at 2024-01-15 10:30:00');
print('Error: Connection failed');
print('Request to /api/users took 150ms');

// ✅ Strukturiert (JSON)
{
  "timestamp": "2024-01-15T10:30:00Z",
  "level": "info",
  "message": "User logged in",
  "user_email": "john@example.com",
  "request_id": "abc-123"
}
```

### Logger-Klasse

```dart
// lib/logging/logger.dart

import 'dart:convert';
import 'dart:io';

enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warning(2, 'WARN'),
  error(3, 'ERROR'),
  fatal(4, 'FATAL');

  final int value;
  final String label;
  const LogLevel(this.value, this.label);

  bool operator >=(LogLevel other) => value >= other.value;
}

class Logger {
  final String name;
  final LogLevel minLevel;
  final bool jsonOutput;
  final IOSink _sink;

  // Globaler Request Context
  static String? currentRequestId;
  static String? currentUserId;

  Logger({
    required this.name,
    this.minLevel = LogLevel.info,
    this.jsonOutput = true,
    IOSink? sink,
  }) : _sink = sink ?? stdout;

  void debug(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.debug, message, data);
  }

  void info(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, message, data);
  }

  void warning(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.warning, message, data);
  }

  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    });
  }

  void _log(LogLevel level, String message, Map<String, dynamic>? data) {
    if (level.value < minLevel.value) return;

    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      logger: name,
      message: message,
      data: data,
      requestId: currentRequestId,
      userId: currentUserId,
    );

    if (jsonOutput) {
      _sink.writeln(jsonEncode(entry.toJson()));
    } else {
      _sink.writeln(entry.toText());
    }
  }
}

class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String logger;
  final String message;
  final Map<String, dynamic>? data;
  final String? requestId;
  final String? userId;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.logger,
    required this.message,
    this.data,
    this.requestId,
    this.userId,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toUtc().toIso8601String(),
        'level': level.label,
        'logger': logger,
        'message': message,
        if (requestId != null) 'request_id': requestId,
        if (userId != null) 'user_id': userId,
        if (data != null) ...data!,
      };

  String toText() {
    final time = timestamp.toIso8601String().substring(11, 23);
    final ctx = [
      if (requestId != null) 'req=$requestId',
      if (userId != null) 'user=$userId',
    ].join(' ');

    return '[$time] ${level.label.padRight(5)} [$logger] $message ${ctx.isNotEmpty ? '($ctx)' : ''}';
  }
}
```

### Request-Logging Middleware

```dart
// lib/logging/request_logger.dart

import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

Middleware requestLoggingMiddleware(Logger logger) {
  return (Handler innerHandler) {
    return (Request request) async {
      final requestId = const Uuid().v4().substring(0, 8);
      final stopwatch = Stopwatch()..start();

      // Request Context setzen
      Logger.currentRequestId = requestId;

      logger.info('Request started', {
        'method': request.method,
        'path': request.url.path,
        'query': request.url.queryParameters,
      });

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        logger.info('Request completed', {
          'method': request.method,
          'path': request.url.path,
          'status': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });

        // Request-ID im Response Header
        return response.change(headers: {
          'X-Request-ID': requestId,
        });
      } catch (e, stack) {
        stopwatch.stop();

        logger.error('Request failed', e, stack);

        rethrow;
      } finally {
        Logger.currentRequestId = null;
      }
    };
  };
}
```

---

## Log-Level Best Practices

### Wann welches Level?

```dart
// DEBUG: Detaillierte Infos für Entwicklung
logger.debug('SQL Query executed', {
  'query': 'SELECT * FROM users WHERE id = ?',
  'params': [123],
  'duration_ms': 5,
});

// INFO: Normale Geschäftsereignisse
logger.info('User registered', {
  'user_id': 456,
  'email': 'new@user.com',
});

// WARNING: Unerwartetes, aber behandeltes Verhalten
logger.warning('Rate limit approaching', {
  'user_id': 789,
  'requests': 95,
  'limit': 100,
});

// ERROR: Fehler die behandelt wurden
logger.error('Payment failed', PaymentException('Card declined'));

// FATAL: Kritische Fehler, System instabil
logger.fatal('Database connection lost', dbError);
```

### Level nach Umgebung

```dart
class AppConfig {
  final LogLevel logLevel;

  factory AppConfig.fromEnvironment() {
    final env = Platform.environment['ENV'] ?? 'development';

    return AppConfig(
      logLevel: switch (env) {
        'production' => LogLevel.info,
        'staging' => LogLevel.debug,
        _ => LogLevel.debug,
      },
    );
  }
}
```

---

## Health Checks

### Warum Health Checks?

```
Load Balancer / Kubernetes / Docker
        │
        ▼
   GET /health
        │
        ▼
┌───────────────┐
│   200 OK      │ → Traffic weiterleiten
│   503 Error   │ → Aus Rotation nehmen
└───────────────┘
```

### Health Check Service

```dart
// lib/health/health_check.dart

enum HealthStatus { healthy, degraded, unhealthy }

class HealthCheckResult {
  final String name;
  final HealthStatus status;
  final Duration duration;
  final String? message;
  final Map<String, dynamic>? details;

  HealthCheckResult({
    required this.name,
    required this.status,
    required this.duration,
    this.message,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'status': status.name,
        'duration_ms': duration.inMilliseconds,
        if (message != null) 'message': message,
        if (details != null) 'details': details,
      };
}

abstract class HealthCheck {
  String get name;
  Future<HealthCheckResult> check();
}

// Datenbank Health Check
class DatabaseHealthCheck implements HealthCheck {
  final Connection db;

  DatabaseHealthCheck(this.db);

  @override
  String get name => 'database';

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();

    try {
      await db.execute('SELECT 1');
      stopwatch.stop();

      return HealthCheckResult(
        name: name,
        status: HealthStatus.healthy,
        duration: stopwatch.elapsed,
        message: 'Connection OK',
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        name: name,
        status: HealthStatus.unhealthy,
        duration: stopwatch.elapsed,
        message: e.toString(),
      );
    }
  }
}

// Redis Health Check
class RedisHealthCheck implements HealthCheck {
  final RedisConnection redis;

  RedisHealthCheck(this.redis);

  @override
  String get name => 'redis';

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();

    try {
      final result = await redis.execute(['PING']);
      stopwatch.stop();

      return HealthCheckResult(
        name: name,
        status: result == 'PONG' ? HealthStatus.healthy : HealthStatus.degraded,
        duration: stopwatch.elapsed,
      );
    } catch (e) {
      stopwatch.stop();
      return HealthCheckResult(
        name: name,
        status: HealthStatus.unhealthy,
        duration: stopwatch.elapsed,
        message: e.toString(),
      );
    }
  }
}

// Disk Space Health Check
class DiskSpaceHealthCheck implements HealthCheck {
  final int warningThresholdPercent;
  final int criticalThresholdPercent;

  DiskSpaceHealthCheck({
    this.warningThresholdPercent = 80,
    this.criticalThresholdPercent = 95,
  });

  @override
  String get name => 'disk_space';

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();

    // Simuliert - in echtem Code: df -h parsen oder dart:ffi
    final usedPercent = 60; // Beispiel

    stopwatch.stop();

    final status = usedPercent >= criticalThresholdPercent
        ? HealthStatus.unhealthy
        : usedPercent >= warningThresholdPercent
            ? HealthStatus.degraded
            : HealthStatus.healthy;

    return HealthCheckResult(
      name: name,
      status: status,
      duration: stopwatch.elapsed,
      details: {'used_percent': usedPercent},
    );
  }
}
```

### Health Check Aggregator

```dart
// lib/health/health_service.dart

class HealthService {
  final List<HealthCheck> _checks = [];
  final Logger _logger;

  HealthService(this._logger);

  void register(HealthCheck check) {
    _checks.add(check);
    _logger.info('Health check registered', {'name': check.name});
  }

  Future<OverallHealth> checkAll() async {
    final results = await Future.wait(
      _checks.map((check) => _runCheck(check)),
    );

    final overallStatus = results.any((r) => r.status == HealthStatus.unhealthy)
        ? HealthStatus.unhealthy
        : results.any((r) => r.status == HealthStatus.degraded)
            ? HealthStatus.degraded
            : HealthStatus.healthy;

    return OverallHealth(
      status: overallStatus,
      checks: results,
      timestamp: DateTime.now(),
    );
  }

  Future<HealthCheckResult> _runCheck(HealthCheck check) async {
    try {
      return await check.check().timeout(Duration(seconds: 5));
    } catch (e) {
      return HealthCheckResult(
        name: check.name,
        status: HealthStatus.unhealthy,
        duration: Duration(seconds: 5),
        message: 'Health check timed out: $e',
      );
    }
  }
}

class OverallHealth {
  final HealthStatus status;
  final List<HealthCheckResult> checks;
  final DateTime timestamp;

  OverallHealth({
    required this.status,
    required this.checks,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'checks': checks.map((c) => c.toJson()).toList(),
      };

  int get httpStatusCode => switch (status) {
        HealthStatus.healthy => 200,
        HealthStatus.degraded => 200,
        HealthStatus.unhealthy => 503,
      };
}
```

### Health Endpoints

```dart
// Health Endpoints
router.get('/health', (Request request) async {
  final health = await healthService.checkAll();
  return Response(
    health.httpStatusCode,
    body: jsonEncode(health.toJson()),
    headers: {'content-type': 'application/json'},
  );
});

// Liveness: Prozess läuft?
router.get('/health/live', (Request request) {
  return Response.ok(jsonEncode({'status': 'alive'}));
});

// Readiness: Bereit für Traffic?
router.get('/health/ready', (Request request) async {
  final health = await healthService.checkAll();
  if (health.status == HealthStatus.unhealthy) {
    return Response(503, body: jsonEncode({'status': 'not ready'}));
  }
  return Response.ok(jsonEncode({'status': 'ready'}));
});
```

---

## Metriken

### Metrik-Typen

```dart
// lib/metrics/metrics.dart

/// Counter: Nur aufwärts (Requests, Errors)
class Counter {
  final String name;
  final Map<String, String> labels;
  int _value = 0;

  Counter(this.name, [this.labels = const {}]);

  void increment([int amount = 1]) => _value += amount;
  int get value => _value;
}

/// Gauge: Auf/Ab (Connections, Queue Size)
class Gauge {
  final String name;
  final Map<String, String> labels;
  double _value = 0;

  Gauge(this.name, [this.labels = const {}]);

  void set(double value) => _value = value;
  void increment([double amount = 1]) => _value += amount;
  void decrement([double amount = 1]) => _value -= amount;
  double get value => _value;
}

/// Histogram: Verteilung (Response Times)
class Histogram {
  final String name;
  final List<double> buckets;
  final Map<double, int> _bucketCounts = {};
  double _sum = 0;
  int _count = 0;

  Histogram(this.name, {this.buckets = const [0.01, 0.05, 0.1, 0.5, 1, 5]}) {
    for (final b in buckets) {
      _bucketCounts[b] = 0;
    }
  }

  void observe(double value) {
    _count++;
    _sum += value;

    for (final bucket in buckets) {
      if (value <= bucket) {
        _bucketCounts[bucket] = (_bucketCounts[bucket] ?? 0) + 1;
      }
    }
  }

  double get mean => _count > 0 ? _sum / _count : 0;
  int get count => _count;
  double get sum => _sum;
  Map<double, int> get bucketCounts => Map.unmodifiable(_bucketCounts);
}
```

### Metrics Registry

```dart
// lib/metrics/registry.dart

class MetricsRegistry {
  final Map<String, Counter> _counters = {};
  final Map<String, Gauge> _gauges = {};
  final Map<String, Histogram> _histograms = {};

  Counter counter(String name, [Map<String, String> labels = const {}]) {
    final key = _makeKey(name, labels);
    return _counters.putIfAbsent(key, () => Counter(name, labels));
  }

  Gauge gauge(String name, [Map<String, String> labels = const {}]) {
    final key = _makeKey(name, labels);
    return _gauges.putIfAbsent(key, () => Gauge(name, labels));
  }

  Histogram histogram(String name, {List<double>? buckets}) {
    return _histograms.putIfAbsent(
      name,
      () => Histogram(name, buckets: buckets ?? [0.01, 0.05, 0.1, 0.5, 1, 5]),
    );
  }

  String _makeKey(String name, Map<String, String> labels) {
    if (labels.isEmpty) return name;
    final labelStr = labels.entries.map((e) => '${e.key}="${e.value}"').join(',');
    return '$name{$labelStr}';
  }

  /// Prometheus-Format exportieren
  String exportPrometheus() {
    final buffer = StringBuffer();

    for (final counter in _counters.values) {
      buffer.writeln('# TYPE ${counter.name} counter');
      buffer.writeln('${counter.name} ${counter.value}');
    }

    for (final gauge in _gauges.values) {
      buffer.writeln('# TYPE ${gauge.name} gauge');
      buffer.writeln('${gauge.name} ${gauge.value}');
    }

    for (final hist in _histograms.values) {
      buffer.writeln('# TYPE ${hist.name} histogram');
      for (final entry in hist.bucketCounts.entries) {
        buffer.writeln('${hist.name}_bucket{le="${entry.key}"} ${entry.value}');
      }
      buffer.writeln('${hist.name}_sum ${hist.sum}');
      buffer.writeln('${hist.name}_count ${hist.count}');
    }

    return buffer.toString();
  }

  /// JSON-Format exportieren
  Map<String, dynamic> exportJson() => {
        'counters': {
          for (final c in _counters.values) c.name: c.value,
        },
        'gauges': {
          for (final g in _gauges.values) g.name: g.value,
        },
        'histograms': {
          for (final h in _histograms.values)
            h.name: {
              'count': h.count,
              'sum': h.sum,
              'mean': h.mean,
            },
        },
      };
}
```

### Metrics Middleware

```dart
// lib/metrics/middleware.dart

Middleware metricsMiddleware(MetricsRegistry metrics) {
  final requestCounter = metrics.counter('http_requests_total');
  final requestDuration = metrics.histogram('http_request_duration_seconds');
  final activeRequests = metrics.gauge('http_requests_active');

  return (Handler innerHandler) {
    return (Request request) async {
      activeRequests.increment();
      requestCounter.increment();

      final stopwatch = Stopwatch()..start();

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        requestDuration.observe(stopwatch.elapsedMilliseconds / 1000);

        // Zähler pro Status-Code
        metrics.counter('http_responses_total', {
          'status': (response.statusCode ~/ 100 * 100).toString(),
        }).increment();

        return response;
      } finally {
        activeRequests.decrement();
      }
    };
  };
}
```

### Metrics Endpoint

```dart
// Prometheus-Format
router.get('/metrics', (Request request) {
  return Response.ok(
    metrics.exportPrometheus(),
    headers: {'content-type': 'text/plain'},
  );
});

// JSON-Format
router.get('/metrics/json', (Request request) {
  return Response.ok(
    jsonEncode(metrics.exportJson()),
    headers: {'content-type': 'application/json'},
  );
});
```

---

## Alerting

### Alert-Regeln definieren

```dart
// lib/alerting/alert.dart

enum AlertSeverity { info, warning, critical }

class AlertRule {
  final String name;
  final AlertSeverity severity;
  final Duration checkInterval;
  final Future<bool> Function() condition;
  final String message;

  AlertRule({
    required this.name,
    required this.severity,
    required this.condition,
    required this.message,
    this.checkInterval = const Duration(minutes: 1),
  });
}

class AlertManager {
  final List<AlertRule> _rules = [];
  final List<AlertNotifier> _notifiers = [];
  final Logger _logger;
  final Map<String, DateTime> _lastFired = {};

  AlertManager(this._logger);

  void addRule(AlertRule rule) => _rules.add(rule);
  void addNotifier(AlertNotifier notifier) => _notifiers.add(notifier);

  Future<void> check() async {
    for (final rule in _rules) {
      try {
        final triggered = await rule.condition();

        if (triggered) {
          await _fireAlert(rule);
        } else {
          _lastFired.remove(rule.name);
        }
      } catch (e) {
        _logger.error('Alert check failed: ${rule.name}', e);
      }
    }
  }

  Future<void> _fireAlert(AlertRule rule) async {
    // Cooldown: Nicht öfter als alle 5 Minuten feuern
    final lastFired = _lastFired[rule.name];
    if (lastFired != null &&
        DateTime.now().difference(lastFired) < Duration(minutes: 5)) {
      return;
    }

    _lastFired[rule.name] = DateTime.now();

    final alert = Alert(
      name: rule.name,
      severity: rule.severity,
      message: rule.message,
      timestamp: DateTime.now(),
    );

    _logger.warning('Alert fired: ${rule.name}', {
      'severity': rule.severity.name,
      'message': rule.message,
    });

    for (final notifier in _notifiers) {
      try {
        await notifier.notify(alert);
      } catch (e) {
        _logger.error('Failed to send alert notification', e);
      }
    }
  }
}

class Alert {
  final String name;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;

  Alert({
    required this.name,
    required this.severity,
    required this.message,
    required this.timestamp,
  });
}

abstract class AlertNotifier {
  Future<void> notify(Alert alert);
}

// Slack Notifier
class SlackNotifier implements AlertNotifier {
  final String webhookUrl;

  SlackNotifier(this.webhookUrl);

  @override
  Future<void> notify(Alert alert) async {
    final emoji = switch (alert.severity) {
      AlertSeverity.info => ':information_source:',
      AlertSeverity.warning => ':warning:',
      AlertSeverity.critical => ':rotating_light:',
    };

    // HTTP POST an Slack Webhook
    // await http.post(webhookUrl, body: {...});
  }
}

// Email Notifier
class EmailNotifier implements AlertNotifier {
  final String smtpHost;
  final List<String> recipients;

  EmailNotifier(this.smtpHost, this.recipients);

  @override
  Future<void> notify(Alert alert) async {
    // Email senden
  }
}
```

### Alert-Regeln konfigurieren

```dart
void setupAlerts(AlertManager alerts, MetricsRegistry metrics, HealthService health) {
  // Hohe Fehlerrate
  alerts.addRule(AlertRule(
    name: 'high_error_rate',
    severity: AlertSeverity.critical,
    message: 'Error rate exceeded 5%',
    condition: () async {
      final errors = metrics.counter('http_responses_total', {'status': '500'}).value;
      final total = metrics.counter('http_requests_total').value;
      return total > 100 && errors / total > 0.05;
    },
  ));

  // Langsame Responses
  alerts.addRule(AlertRule(
    name: 'slow_responses',
    severity: AlertSeverity.warning,
    message: 'Average response time > 1s',
    condition: () async {
      final hist = metrics.histogram('http_request_duration_seconds');
      return hist.mean > 1.0;
    },
  ));

  // Unhealthy Services
  alerts.addRule(AlertRule(
    name: 'service_unhealthy',
    severity: AlertSeverity.critical,
    message: 'One or more services are unhealthy',
    condition: () async {
      final health = await health.checkAll();
      return health.status == HealthStatus.unhealthy;
    },
  ));
}
```

---

## Zusammenfassung

- **Strukturiertes Logging** mit JSON für maschinelle Verarbeitung
- **Log-Level** sinnvoll einsetzen (Debug → Fatal)
- **Health Checks** für Load Balancer und Orchestrierung
- **Metriken** für Performance-Überwachung
- **Alerting** für proaktive Fehlererkennung

### Nächste Schritte

In der nächsten Einheit behandeln wir Deployment & Docker.
