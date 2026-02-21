# Lösung 9.3: Logging & Monitoring

## Aufgabe 1: Logger-Klasse

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
  final IOSink _sink;

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

  void error(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.error, message, {
      if (error != null) 'error': error.toString(),
      if (stack != null) 'stack_trace': stack.toString().split('\n').take(10).join('\n'),
    });
  }

  void fatal(String message, [Object? error, StackTrace? stack]) {
    _log(LogLevel.fatal, message, {
      if (error != null) 'error': error.toString(),
      if (stack != null) 'stack_trace': stack.toString(),
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

  /// Child Logger mit Prefix
  Logger child(String childName) {
    return Logger(
      name: '$name.$childName',
      minLevel: minLevel,
      jsonOutput: jsonOutput,
      sink: _sink,
    );
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
    final json = <String, dynamic>{
      'timestamp': timestamp.toUtc().toIso8601String(),
      'level': level.label,
      'logger': logger,
      'message': message,
    };

    if (requestId != null) json['request_id'] = requestId;
    if (userId != null) json['user_id'] = userId;
    if (data != null && data!.isNotEmpty) {
      json.addAll(data!);
    }

    return json;
  }

  String toText() {
    final time = timestamp.toIso8601String().substring(11, 23);
    final levelStr = level.label.padRight(5);
    final loggerStr = '[$logger]'.padRight(15);

    final contextParts = <String>[];
    if (requestId != null) contextParts.add('req=$requestId');
    if (userId != null) contextParts.add('user=$userId');
    final context = contextParts.isNotEmpty ? ' (${contextParts.join(' ')})' : '';

    final dataStr = data != null && data!.isNotEmpty ? ' $data' : '';

    return '[$time] $levelStr $loggerStr $message$context$dataStr';
  }
}
```

---

## Aufgabe 2: Request Logging Middleware

```dart
// lib/logging/request_logger.dart

import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';
import 'logger.dart';

Middleware requestLoggingMiddleware(Logger logger) {
  final uuid = Uuid();

  return (Handler innerHandler) {
    return (Request request) async {
      final requestId = uuid.v4().substring(0, 8);
      final stopwatch = Stopwatch()..start();

      // Context setzen
      Logger.currentRequestId = requestId;

      // User ID aus Auth extrahieren (falls vorhanden)
      final authHeader = request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        // In echtem Code: Token parsen und User ID extrahieren
      }

      logger.info('Request started', {
        'method': request.method,
        'path': request.url.path,
        'query': request.url.query.isNotEmpty ? request.url.queryParameters : null,
        'remote_ip': request.headers['x-forwarded-for'] ?? 'unknown',
        'user_agent': request.headers['user-agent'],
      });

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        final logLevel = response.statusCode >= 500
            ? LogLevel.error
            : response.statusCode >= 400
                ? LogLevel.warning
                : LogLevel.info;

        logger._log(logLevel, 'Request completed', {
          'method': request.method,
          'path': request.url.path,
          'status': response.statusCode,
          'duration_ms': stopwatch.elapsedMilliseconds,
        });

        return response.change(headers: {
          'X-Request-ID': requestId,
        });
      } catch (e, stack) {
        stopwatch.stop();

        logger.error('Request failed', e, stack);

        rethrow;
      } finally {
        Logger.currentRequestId = null;
        Logger.currentUserId = null;
      }
    };
  };
}
```

---

## Aufgabe 3: Health Check System

```dart
// lib/health/health_check.dart

import 'dart:io';

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

/// Ping Check - prüft ob ein Service erreichbar ist
class PingHealthCheck implements HealthCheck {
  final String serviceName;
  final Future<void> Function() pingFn;

  PingHealthCheck(this.serviceName, this.pingFn);

  @override
  String get name => serviceName;

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();

    try {
      await pingFn();
      stopwatch.stop();

      return HealthCheckResult(
        name: name,
        status: HealthStatus.healthy,
        duration: stopwatch.elapsed,
        message: 'OK',
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

/// Memory Check - prüft Speicherverbrauch
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
    final stopwatch = Stopwatch()..start();

    final rss = ProcessInfo.currentRss;
    final usedMb = rss ~/ (1024 * 1024);

    stopwatch.stop();

    final status = usedMb >= criticalMb
        ? HealthStatus.unhealthy
        : usedMb >= warningMb
            ? HealthStatus.degraded
            : HealthStatus.healthy;

    return HealthCheckResult(
      name: name,
      status: status,
      duration: stopwatch.elapsed,
      message: '$usedMb MB used',
      details: {
        'used_mb': usedMb,
        'warning_threshold_mb': warningMb,
        'critical_threshold_mb': criticalMb,
      },
    );
  }
}

/// Uptime Check
class UptimeHealthCheck implements HealthCheck {
  final DateTime startTime;

  UptimeHealthCheck() : startTime = DateTime.now();

  @override
  String get name => 'uptime';

  @override
  Future<HealthCheckResult> check() async {
    final uptime = DateTime.now().difference(startTime);

    return HealthCheckResult(
      name: name,
      status: HealthStatus.healthy,
      duration: Duration.zero,
      message: _formatDuration(uptime),
      details: {
        'started_at': startTime.toIso8601String(),
        'uptime_seconds': uptime.inSeconds,
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}

/// HTTP Endpoint Check
class HttpHealthCheck implements HealthCheck {
  final String serviceName;
  final String url;
  final Duration timeout;

  HttpHealthCheck(this.serviceName, this.url, {this.timeout = const Duration(seconds: 5)});

  @override
  String get name => serviceName;

  @override
  Future<HealthCheckResult> check() async {
    final stopwatch = Stopwatch()..start();

    try {
      final client = HttpClient();
      client.connectionTimeout = timeout;

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close().timeout(timeout);

      stopwatch.stop();
      client.close();

      final status = response.statusCode < 400
          ? HealthStatus.healthy
          : response.statusCode < 500
              ? HealthStatus.degraded
              : HealthStatus.unhealthy;

      return HealthCheckResult(
        name: name,
        status: status,
        duration: stopwatch.elapsed,
        message: 'Status ${response.statusCode}',
        details: {'status_code': response.statusCode},
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
```

---

## Aufgabe 4: Health Service

```dart
// lib/health/health_service.dart

import 'dart:async';
import 'health_check.dart';
import '../logging/logger.dart';

class HealthService {
  final List<HealthCheck> _checks = [];
  final Logger _logger;
  final Duration timeout;

  HealthService(this._logger, {this.timeout = const Duration(seconds: 5)});

  void register(HealthCheck check) {
    _checks.add(check);
    _logger.debug('Health check registered', {'name': check.name});
  }

  Future<OverallHealth> checkAll() async {
    final results = await Future.wait(
      _checks.map((check) => _runWithTimeout(check)),
    );

    final status = _calculateOverallStatus(results);

    return OverallHealth(
      status: status,
      checks: results,
      timestamp: DateTime.now(),
    );
  }

  Future<HealthCheckResult> _runWithTimeout(HealthCheck check) async {
    try {
      return await check.check().timeout(timeout);
    } on TimeoutException {
      return HealthCheckResult(
        name: check.name,
        status: HealthStatus.unhealthy,
        duration: timeout,
        message: 'Health check timed out',
      );
    } catch (e) {
      return HealthCheckResult(
        name: check.name,
        status: HealthStatus.unhealthy,
        duration: Duration.zero,
        message: 'Health check error: $e',
      );
    }
  }

  HealthStatus _calculateOverallStatus(List<HealthCheckResult> results) {
    if (results.any((r) => r.status == HealthStatus.unhealthy)) {
      return HealthStatus.unhealthy;
    }
    if (results.any((r) => r.status == HealthStatus.degraded)) {
      return HealthStatus.degraded;
    }
    return HealthStatus.healthy;
  }

  Future<HealthCheckResult?> checkOne(String name) async {
    final check = _checks.where((c) => c.name == name).firstOrNull;
    if (check == null) return null;
    return await _runWithTimeout(check);
  }

  List<String> get checkNames => _checks.map((c) => c.name).toList();
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

  int get httpStatusCode => status == HealthStatus.unhealthy ? 503 : 200;
}
```

---

## Aufgabe 5: Metriken

```dart
// lib/metrics/metrics.dart

/// Counter: Zählt nur aufwärts
class Counter {
  final String name;
  final String? help;
  int _value = 0;

  Counter(this.name, {this.help});

  void increment([int amount = 1]) {
    if (amount < 0) throw ArgumentError('Counter can only increment');
    _value += amount;
  }

  int get value => _value;

  void reset() {
    _value = 0;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': 'counter',
        'value': _value,
        if (help != null) 'help': help,
      };
}

/// Gauge: Kann auf- und abwärts
class Gauge {
  final String name;
  final String? help;
  double _value = 0;

  Gauge(this.name, {this.help});

  void set(double value) {
    _value = value;
  }

  void increment([double amount = 1]) {
    _value += amount;
  }

  void decrement([double amount = 1]) {
    _value -= amount;
  }

  double get value => _value;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': 'gauge',
        'value': _value,
        if (help != null) 'help': help,
      };
}

/// Histogram: Verteilung von Werten
class Histogram {
  final String name;
  final String? help;
  final List<double> buckets;
  final Map<double, int> _bucketCounts = {};
  double _sum = 0;
  int _count = 0;
  double _min = double.infinity;
  double _max = double.negativeInfinity;

  Histogram(
    this.name, {
    this.help,
    this.buckets = const [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  }) {
    for (final b in buckets) {
      _bucketCounts[b] = 0;
    }
    _bucketCounts[double.infinity] = 0; // +Inf bucket
  }

  void observe(double value) {
    _count++;
    _sum += value;
    if (value < _min) _min = value;
    if (value > _max) _max = value;

    for (final bucket in buckets) {
      if (value <= bucket) {
        _bucketCounts[bucket] = (_bucketCounts[bucket] ?? 0) + 1;
      }
    }
    _bucketCounts[double.infinity] = _count; // +Inf always contains all
  }

  int get count => _count;
  double get sum => _sum;
  double get mean => _count > 0 ? _sum / _count : 0;
  double get min => _count > 0 ? _min : 0;
  double get max => _count > 0 ? _max : 0;

  /// Perzentil approximieren
  double percentile(double p) {
    if (_count == 0) return 0;
    if (p < 0 || p > 1) throw ArgumentError('Percentile must be between 0 and 1');

    final target = (p * _count).ceil();
    int cumulative = 0;

    for (final bucket in buckets) {
      cumulative = _bucketCounts[bucket] ?? 0;
      if (cumulative >= target) {
        return bucket;
      }
    }

    return buckets.last;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': 'histogram',
        'count': _count,
        'sum': _sum,
        'mean': mean,
        'min': _count > 0 ? _min : null,
        'max': _count > 0 ? _max : null,
        'p50': percentile(0.5),
        'p90': percentile(0.9),
        'p99': percentile(0.99),
        if (help != null) 'help': help,
      };

  String toPrometheus() {
    final buffer = StringBuffer();
    if (help != null) {
      buffer.writeln('# HELP $name $help');
    }
    buffer.writeln('# TYPE $name histogram');

    for (final bucket in buckets) {
      buffer.writeln('${name}_bucket{le="$bucket"} ${_bucketCounts[bucket]}');
    }
    buffer.writeln('${name}_bucket{le="+Inf"} $_count');
    buffer.writeln('${name}_sum $sum');
    buffer.writeln('${name}_count $count');

    return buffer.toString();
  }
}
```

---

## Aufgabe 6: Metrics Registry

```dart
// lib/metrics/registry.dart

import 'metrics.dart';

class MetricsRegistry {
  final Map<String, Counter> _counters = {};
  final Map<String, Gauge> _gauges = {};
  final Map<String, Histogram> _histograms = {};

  Counter counter(String name, {String? help}) {
    return _counters.putIfAbsent(name, () => Counter(name, help: help));
  }

  Gauge gauge(String name, {String? help}) {
    return _gauges.putIfAbsent(name, () => Gauge(name, help: help));
  }

  Histogram histogram(String name, {String? help, List<double>? buckets}) {
    return _histograms.putIfAbsent(
      name,
      () => Histogram(name, help: help, buckets: buckets ?? const [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10]),
    );
  }

  Map<String, dynamic> toJson() => {
        'counters': {
          for (final c in _counters.values) c.name: c.value,
        },
        'gauges': {
          for (final g in _gauges.values) g.name: g.value,
        },
        'histograms': {
          for (final h in _histograms.values) h.name: h.toJson(),
        },
      };

  String toPrometheus() {
    final buffer = StringBuffer();

    // Counters
    for (final counter in _counters.values) {
      if (counter.help != null) {
        buffer.writeln('# HELP ${counter.name} ${counter.help}');
      }
      buffer.writeln('# TYPE ${counter.name} counter');
      buffer.writeln('${counter.name} ${counter.value}');
      buffer.writeln();
    }

    // Gauges
    for (final gauge in _gauges.values) {
      if (gauge.help != null) {
        buffer.writeln('# HELP ${gauge.name} ${gauge.help}');
      }
      buffer.writeln('# TYPE ${gauge.name} gauge');
      buffer.writeln('${gauge.name} ${gauge.value}');
      buffer.writeln();
    }

    // Histograms
    for (final histogram in _histograms.values) {
      buffer.write(histogram.toPrometheus());
      buffer.writeln();
    }

    return buffer.toString();
  }

  void reset() {
    for (final c in _counters.values) {
      c.reset();
    }
    _gauges.clear();
    _histograms.clear();
  }
}
```

---

## Aufgabe 7: HTTP Metrics Middleware

```dart
// lib/metrics/http_metrics.dart

import 'package:shelf/shelf.dart';
import 'metrics.dart';
import 'registry.dart';

class HttpMetrics {
  final Counter requestsTotal;
  final Counter errorsTotal;
  final Histogram requestDuration;
  final Gauge activeRequests;

  HttpMetrics(MetricsRegistry registry)
      : requestsTotal = registry.counter(
          'http_requests_total',
          help: 'Total number of HTTP requests',
        ),
        errorsTotal = registry.counter(
          'http_errors_total',
          help: 'Total number of HTTP errors (5xx)',
        ),
        requestDuration = registry.histogram(
          'http_request_duration_seconds',
          help: 'HTTP request duration in seconds',
          buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
        ),
        activeRequests = registry.gauge(
          'http_requests_active',
          help: 'Number of currently active HTTP requests',
        );
}

Middleware httpMetricsMiddleware(HttpMetrics metrics) {
  return (Handler innerHandler) {
    return (Request request) async {
      metrics.activeRequests.increment();
      metrics.requestsTotal.increment();

      final stopwatch = Stopwatch()..start();

      try {
        final response = await innerHandler(request);
        stopwatch.stop();

        // Duration in Sekunden
        metrics.requestDuration.observe(stopwatch.elapsedMilliseconds / 1000);

        // 5xx Errors zählen
        if (response.statusCode >= 500) {
          metrics.errorsTotal.increment();
        }

        return response;
      } catch (e) {
        stopwatch.stop();
        metrics.requestDuration.observe(stopwatch.elapsedMilliseconds / 1000);
        metrics.errorsTotal.increment();
        rethrow;
      } finally {
        metrics.activeRequests.decrement();
      }
    };
  };
}
```

---

## Aufgabe 8: Server Assembly

```dart
// bin/server.dart

import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import '../lib/logging/logger.dart';
import '../lib/logging/request_logger.dart';
import '../lib/health/health_check.dart';
import '../lib/health/health_service.dart';
import '../lib/metrics/metrics.dart';
import '../lib/metrics/registry.dart';
import '../lib/metrics/http_metrics.dart';

void main() async {
  // Logger
  final logger = Logger(
    name: 'server',
    minLevel: LogLevel.values.byName(
      Platform.environment['LOG_LEVEL'] ?? 'debug',
    ),
    jsonOutput: Platform.environment['LOG_FORMAT'] == 'json',
  );

  // Metrics
  final metrics = MetricsRegistry();
  final httpMetrics = HttpMetrics(metrics);

  // Custom Business Metrics
  final usersCreated = metrics.counter('users_created_total', help: 'Total users created');
  final cacheHits = metrics.counter('cache_hits_total');
  final cacheMisses = metrics.counter('cache_misses_total');

  // Health Checks
  final health = HealthService(logger);
  health.register(UptimeHealthCheck());
  health.register(MemoryHealthCheck(warningMb: 200, criticalMb: 400));

  // Router
  final router = Router();

  // Business Endpoints
  router.get('/api/hello', (Request request) {
    logger.info('Hello endpoint called');
    return Response.ok(
      jsonEncode({'message': 'Hello World', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.post('/api/users', (Request request) async {
    logger.info('Creating user');
    usersCreated.increment();

    // Simuliere User-Erstellung
    await Future.delayed(Duration(milliseconds: 100));

    return Response.ok(
      jsonEncode({'id': 1, 'created': true}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/api/slow', (Request request) async {
    logger.debug('Slow endpoint called');
    await Future.delayed(Duration(seconds: 2));
    return Response.ok(jsonEncode({'message': 'Finally done'}));
  });

  router.get('/api/error', (Request request) {
    logger.warning('Error endpoint called');
    throw Exception('Intentional test error');
  });

  // Health Endpoints
  router.get('/health', (Request request) async {
    final result = await health.checkAll();
    return Response(
      result.httpStatusCode,
      body: jsonEncode(result.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/health/live', (Request request) {
    return Response.ok(
      jsonEncode({'status': 'alive', 'timestamp': DateTime.now().toIso8601String()}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/health/ready', (Request request) async {
    final result = await health.checkAll();
    if (result.status == HealthStatus.unhealthy) {
      return Response(
        503,
        body: jsonEncode({'status': 'not_ready', 'checks': result.toJson()}),
        headers: {'content-type': 'application/json'},
      );
    }
    return Response.ok(
      jsonEncode({'status': 'ready'}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/health/<check>', (Request request, String check) async {
    final result = await health.checkOne(check);
    if (result == null) {
      return Response.notFound(jsonEncode({'error': 'Check not found'}));
    }
    return Response(
      result.status == HealthStatus.unhealthy ? 503 : 200,
      body: jsonEncode(result.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  // Metrics Endpoints
  router.get('/metrics', (Request request) {
    return Response.ok(
      metrics.toPrometheus(),
      headers: {'content-type': 'text/plain; charset=utf-8'},
    );
  });

  router.get('/metrics/json', (Request request) {
    return Response.ok(
      jsonEncode(metrics.toJson()),
      headers: {'content-type': 'application/json'},
    );
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

  logger.info('Server started', {
    'port': port,
    'pid': pid,
    'dart_version': Platform.version.split(' ').first,
  });

  print('');
  print('╔══════════════════════════════════════════════════════════╗');
  print('║           Monitoring Server on port $port                 ║');
  print('╠══════════════════════════════════════════════════════════╣');
  print('║ Endpoints:                                               ║');
  print('║   GET /api/hello        - Hello World                    ║');
  print('║   POST /api/users       - Create user                    ║');
  print('║   GET /api/slow         - Slow endpoint (2s)             ║');
  print('║   GET /api/error        - Error endpoint                 ║');
  print('║   GET /health           - Full health check              ║');
  print('║   GET /health/live      - Liveness probe                 ║');
  print('║   GET /health/ready     - Readiness probe                ║');
  print('║   GET /metrics          - Prometheus metrics             ║');
  print('║   GET /metrics/json     - JSON metrics                   ║');
  print('╚══════════════════════════════════════════════════════════╝');
  print('');

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    logger.info('Shutdown signal received');
    await server.close();
    logger.info('Server stopped');
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
          body: jsonEncode({
            'error': 'Internal Server Error',
            'request_id': Logger.currentRequestId,
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}
```

---

## Projektstruktur

```
monitoring_server/
├── bin/
│   └── server.dart
├── lib/
│   ├── logging/
│   │   ├── logger.dart
│   │   └── request_logger.dart
│   ├── health/
│   │   ├── health_check.dart
│   │   └── health_service.dart
│   └── metrics/
│       ├── metrics.dart
│       ├── registry.dart
│       └── http_metrics.dart
├── pubspec.yaml
└── README.md
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# Verschiedene Endpoints aufrufen
curl http://localhost:8080/api/hello
curl -X POST http://localhost:8080/api/users
curl http://localhost:8080/api/slow
curl http://localhost:8080/api/error

# Health Checks
curl http://localhost:8080/health | jq
curl http://localhost:8080/health/live
curl http://localhost:8080/health/ready
curl http://localhost:8080/health/memory

# Metrics
curl http://localhost:8080/metrics
curl http://localhost:8080/metrics/json | jq

# Last erzeugen
for i in {1..50}; do
  curl -s http://localhost:8080/api/hello &
done
wait

# Metrics nach Last prüfen
curl http://localhost:8080/metrics/json | jq
```
