# Übung 9.3: Logging & Monitoring

## Ziel

Implementiere ein Logging- und Monitoring-System für einen Produktions-Server.

---

## Aufgabe 1: Logger-Klasse (20 min)

Erstelle einen strukturierten Logger.

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
}

class Logger {
  final String name;
  final LogLevel minLevel;
  final bool jsonOutput;

  // Context für Request-Tracking
  static String? currentRequestId;
  static String? currentUserId;

  Logger({
    required this.name,
    this.minLevel = LogLevel.info,
    this.jsonOutput = true,
  });

  void debug(String message, [Map<String, dynamic>? data]) {
    // TODO
  }

  void info(String message, [Map<String, dynamic>? data]) {
    // TODO
  }

  void warning(String message, [Map<String, dynamic>? data]) {
    // TODO
  }

  void error(String message, [Object? error, StackTrace? stack]) {
    // TODO: Error und Stack in data einfügen
  }

  void fatal(String message, [Object? error, StackTrace? stack]) {
    // TODO
  }

  void _log(LogLevel level, String message, Map<String, dynamic>? data) {
    // TODO: Level-Filter
    // TODO: LogEntry erstellen
    // TODO: JSON oder Text ausgeben
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

  Map<String, dynamic> toJson() {
    // TODO: Alle Felder als JSON
  }

  String toText() {
    // TODO: Human-readable Format
    // [10:30:45.123] INFO  [auth] User logged in (req=abc123)
  }
}
```

---

## Aufgabe 2: Request Logging Middleware (15 min)

Erstelle eine Middleware die alle Requests loggt.

```dart
// lib/logging/request_logger.dart

import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

Middleware requestLoggingMiddleware(Logger logger) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO: Request-ID generieren
      // TODO: Logger.currentRequestId setzen
      // TODO: Stopwatch starten
      // TODO: Request-Start loggen

      try {
        final response = await innerHandler(request);

        // TODO: Request-Ende loggen mit Status und Duration
        // TODO: X-Request-ID Header hinzufügen

        return response;
      } catch (e, stack) {
        // TODO: Error loggen
        rethrow;
      } finally {
        // TODO: Context zurücksetzen
      }
    };
  };
}
```

---

## Aufgabe 3: Health Check System (25 min)

Implementiere Health Checks für verschiedene Komponenten.

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

  Map<String, dynamic> toJson() {
    // TODO
  }
}

abstract class HealthCheck {
  String get name;
  Future<HealthCheckResult> check();
}

// Ping Check - prüft ob ein Service erreichbar ist
class PingHealthCheck implements HealthCheck {
  final String serviceName;
  final Future<void> Function() pingFn;

  PingHealthCheck(this.serviceName, this.pingFn);

  @override
  String get name => serviceName;

  @override
  Future<HealthCheckResult> check() async {
    // TODO: Stopwatch starten
    // TODO: pingFn aufrufen
    // TODO: Bei Erfolg: healthy
    // TODO: Bei Fehler: unhealthy mit Message
  }
}

// Memory Check - prüft Speicherverbrauch
class MemoryHealthCheck implements HealthCheck {
  final int warningMb;
  final int criticalMb;

  MemoryHealthCheck({
    this.warningMb = 500,
    this.criticalMb = 800,
  });

  @override
  String get name => 'memory';

  @override
  Future<HealthCheckResult> check() async {
    // TODO: ProcessInfo.currentRss abfragen
    // TODO: Mit Thresholds vergleichen
    // TODO: Status und Details zurückgeben
  }
}

// Uptime Check
class UptimeHealthCheck implements HealthCheck {
  final DateTime startTime;

  UptimeHealthCheck() : startTime = DateTime.now();

  @override
  String get name => 'uptime';

  @override
  Future<HealthCheckResult> check() async {
    // TODO: Uptime berechnen und als healthy zurückgeben
  }
}
```

---

## Aufgabe 4: Health Service (15 min)

Aggregiere alle Health Checks.

```dart
// lib/health/health_service.dart

class HealthService {
  final List<HealthCheck> _checks = [];
  final Logger _logger;

  HealthService(this._logger);

  void register(HealthCheck check) {
    // TODO
  }

  Future<OverallHealth> checkAll() async {
    // TODO: Alle Checks parallel ausführen
    // TODO: Mit Timeout (5 Sekunden)
    // TODO: Gesamtstatus berechnen (unhealthy wenn einer unhealthy)
  }

  Future<HealthCheckResult?> checkOne(String name) async {
    // TODO: Einzelnen Check ausführen
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

  Map<String, dynamic> toJson() {
    // TODO
  }

  int get httpStatusCode => status == HealthStatus.unhealthy ? 503 : 200;
}
```

---

## Aufgabe 5: Metriken (25 min)

Implementiere Counter, Gauge und Histogram.

```dart
// lib/metrics/metrics.dart

/// Counter: Zählt nur aufwärts
class Counter {
  final String name;
  final String? help;
  int _value = 0;

  Counter(this.name, {this.help});

  void increment([int amount = 1]) {
    // TODO
  }

  int get value => _value;

  void reset() {
    // TODO
  }
}

/// Gauge: Kann auf- und abwärts
class Gauge {
  final String name;
  final String? help;
  double _value = 0;

  Gauge(this.name, {this.help});

  void set(double value) {
    // TODO
  }

  void increment([double amount = 1]) {
    // TODO
  }

  void decrement([double amount = 1]) {
    // TODO
  }

  double get value => _value;
}

/// Histogram: Verteilung von Werten
class Histogram {
  final String name;
  final String? help;
  final List<double> buckets;
  final Map<double, int> _bucketCounts = {};
  double _sum = 0;
  int _count = 0;

  Histogram(
    this.name, {
    this.help,
    this.buckets = const [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  }) {
    // TODO: _bucketCounts initialisieren
  }

  void observe(double value) {
    // TODO: _count und _sum aktualisieren
    // TODO: Alle Buckets <= value inkrementieren
  }

  int get count => _count;
  double get sum => _sum;
  double get mean => _count > 0 ? _sum / _count : 0;

  /// Perzentil berechnen (approximiert)
  double percentile(double p) {
    // TODO: Aus Bucket-Daten approximieren
  }
}
```

---

## Aufgabe 6: Metrics Registry (15 min)

Zentrale Verwaltung aller Metriken.

```dart
// lib/metrics/registry.dart

class MetricsRegistry {
  final Map<String, Counter> _counters = {};
  final Map<String, Gauge> _gauges = {};
  final Map<String, Histogram> _histograms = {};

  Counter counter(String name, {String? help}) {
    // TODO: Existierenden zurückgeben oder neuen erstellen
  }

  Gauge gauge(String name, {String? help}) {
    // TODO
  }

  Histogram histogram(String name, {String? help, List<double>? buckets}) {
    // TODO
  }

  /// Export als JSON
  Map<String, dynamic> toJson() {
    // TODO: Alle Metriken als JSON
  }

  /// Export im Prometheus-Format
  String toPrometheus() {
    // TODO: Prometheus Text-Format
    // # HELP counter_name Description
    // # TYPE counter_name counter
    // counter_name 42
  }
}
```

---

## Aufgabe 7: Metrics Middleware (15 min)

Sammle HTTP-Metriken automatisch.

```dart
// lib/metrics/http_metrics.dart

import 'package:shelf/shelf.dart';

class HttpMetrics {
  final Counter requestsTotal;
  final Counter errorsTotal;
  final Histogram requestDuration;
  final Gauge activeRequests;

  HttpMetrics(MetricsRegistry registry)
      : requestsTotal = registry.counter('http_requests_total',
            help: 'Total HTTP requests'),
        errorsTotal = registry.counter('http_errors_total',
            help: 'Total HTTP errors (5xx)'),
        requestDuration = registry.histogram('http_request_duration_seconds',
            help: 'HTTP request duration'),
        activeRequests = registry.gauge('http_requests_active',
            help: 'Currently active requests');
}

Middleware httpMetricsMiddleware(HttpMetrics metrics) {
  return (Handler innerHandler) {
    return (Request request) async {
      // TODO: activeRequests.increment()
      // TODO: requestsTotal.increment()
      // TODO: Stopwatch starten

      try {
        final response = await innerHandler(request);

        // TODO: Duration messen und observieren
        // TODO: Bei 5xx: errorsTotal.increment()

        return response;
      } catch (e) {
        // TODO: errorsTotal.increment()
        rethrow;
      } finally {
        // TODO: activeRequests.decrement()
      }
    };
  };
}
```

---

## Aufgabe 8: Server Assembly (20 min)

Baue alles zusammen.

```dart
// bin/server.dart

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main() async {
  // Logger
  final logger = Logger(
    name: 'server',
    minLevel: LogLevel.debug,
    jsonOutput: false, // Für Entwicklung
  );

  // Metrics
  final metrics = MetricsRegistry();
  final httpMetrics = HttpMetrics(metrics);

  // Health Checks
  final health = HealthService(logger);
  health.register(UptimeHealthCheck());
  health.register(MemoryHealthCheck());

  // Router
  final router = Router();

  // Business Endpoints
  router.get('/api/hello', (Request request) {
    logger.info('Hello endpoint called');
    return Response.ok(jsonEncode({'message': 'Hello World'}));
  });

  router.get('/api/error', (Request request) {
    logger.warning('Error endpoint called');
    throw Exception('Test error');
  });

  // Health Endpoints
  router.get('/health', (Request request) async {
    // TODO: Alle Checks ausführen
    // TODO: JSON Response mit richtigem Status Code
  });

  router.get('/health/live', (Request request) {
    // TODO: Einfaches 200 OK
  });

  router.get('/health/ready', (Request request) async {
    // TODO: Prüfen ob alle Checks healthy
  });

  // Metrics Endpoint
  router.get('/metrics', (Request request) {
    // TODO: Prometheus-Format zurückgeben
  });

  router.get('/metrics/json', (Request request) {
    // TODO: JSON-Format zurückgeben
  });

  // Pipeline
  final handler = const Pipeline()
      .addMiddleware(requestLoggingMiddleware(logger))
      .addMiddleware(httpMetricsMiddleware(httpMetrics))
      .addMiddleware(_errorHandler(logger))
      .addHandler(router.call);

  // Server starten
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);

  logger.info('Server started', {'port': port});

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('Shutting down...');
    await server.close();
    exit(0);
  });
}

Middleware _errorHandler(Logger logger) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } catch (e, stack) {
        logger.error('Unhandled error', e, stack);
        return Response.internalServerError(
          body: jsonEncode({'error': 'Internal Server Error'}),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
```

---

## Testen

### Server starten

```bash
dart run bin/server.dart
```

### Endpoints testen

```bash
# Hello
curl http://localhost:8080/api/hello

# Error erzeugen
curl http://localhost:8080/api/error

# Health Check
curl http://localhost:8080/health

# Liveness
curl http://localhost:8080/health/live

# Readiness
curl http://localhost:8080/health/ready

# Metriken (Prometheus)
curl http://localhost:8080/metrics

# Metriken (JSON)
curl http://localhost:8080/metrics/json
```

### Last erzeugen

```bash
# 100 Requests
for i in {1..100}; do curl -s http://localhost:8080/api/hello > /dev/null; done

# Metriken prüfen
curl http://localhost:8080/metrics/json | jq
```

---

## Bonus: Simple Dashboard (Optional)

```dart
// Einfaches HTML Dashboard
router.get('/dashboard', (Request request) {
  final html = '''
  <!DOCTYPE html>
  <html>
  <head>
    <title>Server Dashboard</title>
    <script>
      async function refresh() {
        const metrics = await fetch('/metrics/json').then(r => r.json());
        const health = await fetch('/health').then(r => r.json());
        document.getElementById('metrics').textContent = JSON.stringify(metrics, null, 2);
        document.getElementById('health').textContent = JSON.stringify(health, null, 2);
      }
      setInterval(refresh, 5000);
      refresh();
    </script>
  </head>
  <body>
    <h1>Server Dashboard</h1>
    <h2>Health</h2>
    <pre id="health">Loading...</pre>
    <h2>Metrics</h2>
    <pre id="metrics">Loading...</pre>
  </body>
  </html>
  ''';
  return Response.ok(html, headers: {'content-type': 'text/html'});
});
```

---

## Abgabe-Checkliste

- [ ] Logger mit allen Log-Levels
- [ ] LogEntry mit JSON und Text-Format
- [ ] Request Logging Middleware mit Request-ID
- [ ] Health Check Interface und Implementierungen
- [ ] HealthService mit Aggregation
- [ ] Counter, Gauge, Histogram Metriken
- [ ] MetricsRegistry mit Export
- [ ] HTTP Metrics Middleware
- [ ] Health Endpoints (/health, /health/live, /health/ready)
- [ ] Metrics Endpoints (/metrics, /metrics/json)
- [ ] Error Handler Middleware
- [ ] Graceful Shutdown
