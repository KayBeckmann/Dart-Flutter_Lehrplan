# Ressourcen: Logging & Monitoring

## Offizielle Dokumentation

- [Dart logging Package](https://pub.dev/packages/logging)
- [Prometheus Data Model](https://prometheus.io/docs/concepts/data_model/)
- [OpenTelemetry](https://opentelemetry.io/docs/)
- [12 Factor App - Logs](https://12factor.net/logs)

## Cheat Sheet: Log Levels

```dart
// Wann welches Level?

// DEBUG - Detaillierte Debugging-Infos
logger.debug('Query executed', {'sql': query, 'params': params, 'duration_ms': 5});

// INFO - Normale Geschäftsereignisse
logger.info('User logged in', {'user_id': 123});
logger.info('Order created', {'order_id': 456, 'total': 99.99});

// WARNING - Unerwartetes, aber behandeltes Verhalten
logger.warning('Cache miss', {'key': 'user:123'});
logger.warning('Retry attempt', {'attempt': 2, 'max': 3});

// ERROR - Fehler die behandelt wurden
logger.error('Payment failed', exception, stackTrace);
logger.error('External API error', {'status': 503, 'service': 'stripe'});

// FATAL - Kritische Fehler, System instabil
logger.fatal('Database connection lost');
logger.fatal('Out of memory');
```

## Cheat Sheet: Strukturierte Logs

```dart
// JSON Format (für Produktion)
{
  "timestamp": "2024-01-15T10:30:00.123Z",
  "level": "INFO",
  "logger": "auth",
  "message": "User logged in",
  "request_id": "abc123",
  "user_id": "456",
  "ip": "192.168.1.1",
  "duration_ms": 45
}

// Text Format (für Entwicklung)
[10:30:00.123] INFO  [auth] User logged in (req=abc123 user=456)
```

## Cheat Sheet: Health Checks

```dart
// Kubernetes Probes
// Liveness: Ist der Prozess am Leben?
GET /health/live
Response: 200 OK

// Readiness: Kann der Service Traffic annehmen?
GET /health/ready
Response: 200 OK oder 503 Service Unavailable

// Startup: Ist der Service gestartet? (für langsame Starts)
GET /health/startup
Response: 200 OK

// Vollständiger Health Check
GET /health
{
  "status": "healthy",
  "checks": [
    {"name": "database", "status": "healthy", "duration_ms": 5},
    {"name": "redis", "status": "healthy", "duration_ms": 2},
    {"name": "memory", "status": "healthy", "used_mb": 150}
  ]
}
```

## Cheat Sheet: Metriken

```dart
// Counter (nur aufwärts)
http_requests_total
errors_total
users_created_total

// Gauge (auf/ab)
http_requests_active
memory_used_bytes
queue_size

// Histogram (Verteilung)
http_request_duration_seconds
response_size_bytes

// Prometheus Format
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total 1234

# HELP http_request_duration_seconds Request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.01"} 100
http_request_duration_seconds_bucket{le="0.05"} 200
http_request_duration_seconds_bucket{le="0.1"} 250
http_request_duration_seconds_bucket{le="+Inf"} 300
http_request_duration_seconds_sum 15.5
http_request_duration_seconds_count 300
```

## Cheat Sheet: Request Context

```dart
// Request-ID durch alle Logs
Middleware requestContext() {
  return (Handler inner) {
    return (Request request) async {
      final requestId = request.headers['x-request-id']
          ?? Uuid().v4().substring(0, 8);

      Logger.currentRequestId = requestId;

      try {
        final response = await inner(request);
        return response.change(headers: {'x-request-id': requestId});
      } finally {
        Logger.currentRequestId = null;
      }
    };
  };
}
```

## Cheat Sheet: Error Logging

```dart
// Fehler mit Kontext
try {
  await riskyOperation();
} catch (e, stack) {
  logger.error('Operation failed', e, stack);

  // Oder mit mehr Kontext
  logger.error('Operation failed', {
    'error': e.toString(),
    'stack': stack.toString().split('\n').take(10).toList(),
    'user_id': currentUserId,
    'operation': 'riskyOperation',
  });

  rethrow;
}
```

## Cheat Sheet: Performance Logging

```dart
// Timing messen
Future<T> timed<T>(String name, Future<T> Function() fn) async {
  final stopwatch = Stopwatch()..start();
  try {
    return await fn();
  } finally {
    stopwatch.stop();
    logger.debug('$name completed', {
      'duration_ms': stopwatch.elapsedMilliseconds,
    });
    metrics.histogram('operation_duration_seconds').observe(
      stopwatch.elapsedMilliseconds / 1000,
    );
  }
}

// Verwendung
final user = await timed('fetch_user', () => db.findUser(id));
```

## Best Practices

### DO

1. **Strukturierte Logs** - JSON für maschinelle Verarbeitung
2. **Request-ID** - Durch alle Services tracken
3. **Sensitive Daten maskieren** - Passwörter, Tokens
4. **Log-Level nach Umgebung** - DEBUG in Dev, INFO in Prod
5. **Health Checks** - Liveness + Readiness trennen
6. **Timeouts** - Für Health Checks
7. **Metriken für wichtige Operationen** - Request-Zeit, Fehlerrate

### DON'T

1. **print() in Produktion** - Unstrukturiert, kein Level
2. **Sensitive Daten loggen** - Passwörter, API Keys
3. **Zu viel loggen** - Performance-Impact
4. **Blocking I/O** - Logs asynchron schreiben
5. **Health Check = Geschäftslogik** - Nur Infrastruktur prüfen

## Sensitive Daten maskieren

```dart
String maskSensitive(String input, {int visibleChars = 4}) {
  if (input.length <= visibleChars) return '***';
  return '${input.substring(0, visibleChars)}${'*' * (input.length - visibleChars)}';
}

Map<String, dynamic> sanitizeForLogging(Map<String, dynamic> data) {
  final sanitized = Map<String, dynamic>.from(data);

  final sensitiveKeys = ['password', 'token', 'secret', 'api_key', 'authorization'];

  for (final key in sensitized.keys.toList()) {
    if (sensitiveKeys.any((s) => key.toLowerCase().contains(s))) {
      sanitized[key] = '***REDACTED***';
    }
  }

  return sanitized;
}
```

## Log Aggregation

```yaml
# docker-compose.yml mit ELK Stack
services:
  app:
    build: .
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  # Logs sammeln mit Filebeat
  filebeat:
    image: elastic/filebeat:8.0.0
    volumes:
      - /var/lib/docker/containers:/var/lib/docker/containers:ro
```

## Alerting Beispiele

```dart
// Fehlerrate > 5%
if (errors / requests > 0.05) {
  alert('High error rate', AlertSeverity.critical);
}

// Response Zeit > 1s
if (histogram.percentile(0.95) > 1.0) {
  alert('Slow responses', AlertSeverity.warning);
}

// Memory > 80%
if (memoryUsedPercent > 80) {
  alert('High memory usage', AlertSeverity.warning);
}

// Service unhealthy
if (health.status == HealthStatus.unhealthy) {
  alert('Service unhealthy', AlertSeverity.critical);
}
```

## Tools

- **Prometheus** - Metrics Collection
- **Grafana** - Dashboards
- **ELK Stack** - Log Aggregation (Elasticsearch, Logstash, Kibana)
- **Loki** - Log Aggregation (leichtgewichtig)
- **Jaeger/Zipkin** - Distributed Tracing
- **PagerDuty/Opsgenie** - Alerting
