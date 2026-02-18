# Lösung 5.5: Konfiguration & Umgebungsvariablen

## Vollständige Lösung

### lib/config/env_loader.dart

```dart
import 'dart:io';

/// Lädt eine .env-Datei und gibt die Werte als Map zurück
Future<Map<String, String>> loadEnvFile(String path) async {
  final file = File(path);
  final env = <String, String>{};

  if (!await file.exists()) {
    return env;
  }

  final lines = await file.readAsLines();

  for (final line in lines) {
    final trimmed = line.trim();

    // Kommentare und leere Zeilen überspringen
    if (trimmed.isEmpty || trimmed.startsWith('#')) {
      continue;
    }

    // KEY=VALUE Format parsen
    final equalsIndex = trimmed.indexOf('=');
    if (equalsIndex == -1) {
      continue; // Ungültige Zeile
    }

    final key = trimmed.substring(0, equalsIndex).trim();
    var value = trimmed.substring(equalsIndex + 1).trim();

    // Quotes entfernen
    if (value.length >= 2) {
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
    }

    env[key] = value;
  }

  return env;
}
```

### lib/config/app_config.dart

```dart
import 'dart:io';

class AppConfig {
  // Server
  final String host;
  final int port;

  // Database
  final String databaseUrl;
  final int databasePoolSize;

  // Auth
  final String jwtSecret;
  final Duration jwtExpiry;

  // Features
  final bool debugMode;
  final String logLevel;

  // Environment
  final String environment;

  AppConfig({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.databasePoolSize,
    required this.jwtSecret,
    required this.jwtExpiry,
    required this.debugMode,
    required this.logLevel,
    required this.environment,
  });

  // Environment-Getter
  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  /// Erstellt Config aus Environment-Map
  factory AppConfig.fromEnvironment(Map<String, String> env) {
    // Pflichtfelder prüfen
    final databaseUrl = env['DATABASE_URL'];
    if (databaseUrl == null || databaseUrl.isEmpty) {
      throw ConfigurationException('Required: DATABASE_URL is not set');
    }

    final jwtSecret = env['JWT_SECRET'];
    if (jwtSecret == null || jwtSecret.isEmpty) {
      throw ConfigurationException('Required: JWT_SECRET is not set');
    }

    return AppConfig(
      host: env['HOST'] ?? 'localhost',
      port: int.tryParse(env['PORT'] ?? '') ?? 8080,
      databaseUrl: databaseUrl,
      databasePoolSize: int.tryParse(env['DATABASE_POOL_SIZE'] ?? '') ?? 10,
      jwtSecret: jwtSecret,
      jwtExpiry: Duration(
        seconds: int.tryParse(env['JWT_EXPIRY'] ?? '') ?? 3600,
      ),
      debugMode: env['DEBUG']?.toLowerCase() == 'true',
      logLevel: env['LOG_LEVEL'] ?? 'info',
      environment: env['ENVIRONMENT'] ?? 'development',
    );
  }

  /// Validiert die Konfiguration
  void validate() {
    final errors = <String>[];

    // JWT Secret Länge
    if (jwtSecret.length < 32) {
      errors.add('JWT_SECRET must be at least 32 characters (got ${jwtSecret.length})');
    }

    // Database URL Format
    if (!databaseUrl.startsWith('postgres://') &&
        !databaseUrl.startsWith('postgresql://')) {
      errors.add('DATABASE_URL must start with postgres:// or postgresql://');
    }

    // Port Range
    if (port < 1 || port > 65535) {
      errors.add('PORT must be between 1 and 65535 (got $port)');
    }

    // Log Level
    final validLogLevels = ['debug', 'info', 'warning', 'error'];
    if (!validLogLevels.contains(logLevel.toLowerCase())) {
      errors.add('LOG_LEVEL must be one of: ${validLogLevels.join(', ')} (got $logLevel)');
    }

    // Production-spezifische Regeln
    if (isProduction) {
      if (debugMode) {
        errors.add('DEBUG must be false in production');
      }
      if (jwtSecret.toLowerCase().contains('development') ||
          jwtSecret.toLowerCase().contains('dev') ||
          jwtSecret.toLowerCase().contains('test')) {
        errors.add('JWT_SECRET must not contain "development", "dev", or "test" in production');
      }
    }

    if (errors.isNotEmpty) {
      throw ConfigValidationException(errors);
    }
  }

  @override
  String toString() {
    return 'AppConfig('
        'environment: $environment, '
        'host: $host, '
        'port: $port, '
        'debugMode: $debugMode, '
        'logLevel: $logLevel'
        ')';
  }
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}

class ConfigValidationException implements Exception {
  final List<String> errors;
  ConfigValidationException(this.errors);

  @override
  String toString() =>
      'ConfigValidationException:\n  - ${errors.join('\n  - ')}';
}
```

### lib/config/config_loader.dart

```dart
import 'dart:io';
import 'app_config.dart';
import 'env_loader.dart';

/// Lädt die Konfiguration aus Umgebungsvariablen und .env-Dateien
Future<AppConfig> loadConfig() async {
  // 1. Starte mit System-Umgebungsvariablen (höchste Priorität)
  final env = Map<String, String>.from(Platform.environment);

  // 2. Environment ermitteln
  final environment = env['ENVIRONMENT'] ?? 'development';

  // 3. Umgebungsspezifische .env laden (mittlere Priorität)
  final envSpecificPath = '.env.$environment';
  final envSpecific = await loadEnvFile(envSpecificPath);
  for (final entry in envSpecific.entries) {
    env.putIfAbsent(entry.key, () => entry.value);
  }

  // 4. Standard .env laden (niedrigste Priorität)
  final dotenv = await loadEnvFile('.env');
  for (final entry in dotenv.entries) {
    env.putIfAbsent(entry.key, () => entry.value);
  }

  // 5. Config erstellen
  final config = AppConfig.fromEnvironment(env);

  // 6. Validieren
  config.validate();

  return config;
}
```

### bin/server.dart

```dart
import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// Config importieren (Pfade anpassen je nach Projektstruktur)
import '../lib/config/app_config.dart';
import '../lib/config/config_loader.dart';

void main() async {
  try {
    // Config laden
    final config = await loadConfig();

    print('='.padRight(50, '='));
    print('Starting server...');
    print('Environment: ${config.environment}');
    print('Host: ${config.host}');
    print('Port: ${config.port}');
    print('Debug Mode: ${config.debugMode}');
    print('Log Level: ${config.logLevel}');
    print('='.padRight(50, '='));

    // Handler aufbauen
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router(config).call);

    // Server starten
    final server = await shelf_io.serve(handler, config.host, config.port);
    print('\nServer running on http://${server.address.host}:${server.port}');

    // Graceful Shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      print('\nShutting down...');
      await server.close();
      exit(0);
    });
  } on ConfigurationException catch (e) {
    print('\n❌ Configuration Error:');
    print('   $e');
    exit(1);
  } on ConfigValidationException catch (e) {
    print('\n❌ Configuration Validation Failed:');
    print('   ${e.errors.join('\n   ')}');
    exit(1);
  } catch (e, stack) {
    print('\n❌ Failed to start server:');
    print('   $e');
    if (Platform.environment['DEBUG'] == 'true') {
      print('\nStack trace:');
      print(stack);
    }
    exit(1);
  }
}

Router _router(AppConfig config) {
  final router = Router();

  // Health Check
  router.get('/health', (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'environment': config.environment,
        'debug': config.debugMode,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // Config Endpoint (nur Development!)
  router.get('/config', (Request request) {
    if (!config.isDevelopment) {
      return Response.forbidden(
        jsonEncode({'error': 'Not allowed in ${config.environment}'}),
        headers: {'content-type': 'application/json'},
      );
    }

    // NIEMALS Secrets ausgeben!
    return Response.ok(
      jsonEncode({
        'host': config.host,
        'port': config.port,
        'environment': config.environment,
        'debugMode': config.debugMode,
        'logLevel': config.logLevel,
        'databasePoolSize': config.databasePoolSize,
        'jwtExpirySeconds': config.jwtExpiry.inSeconds,
        // Secrets werden NICHT ausgegeben
      }),
      headers: {'content-type': 'application/json'},
    );
  });

  // 404
  router.all('/<path|.*>', (Request request, String path) {
    return Response.notFound(
      jsonEncode({'error': 'Not Found', 'path': '/$path'}),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}
```

---

## Test-Dateien

### .env

```env
# Development Environment
PORT=8080
HOST=localhost
DATABASE_URL=postgres://dev:devpass@localhost:5432/devdb
JWT_SECRET=development-secret-key-that-is-long-enough-32chars
DATABASE_POOL_SIZE=5
JWT_EXPIRY=3600
DEBUG=true
LOG_LEVEL=debug
ENVIRONMENT=development
```

### .env.production

```env
# Production Environment
PORT=80
HOST=0.0.0.0
DATABASE_POOL_SIZE=50
DEBUG=false
LOG_LEVEL=warning
ENVIRONMENT=production
# DATABASE_URL und JWT_SECRET müssen als System-Env gesetzt werden!
```

### .env.example

```env
# Copy this file to .env and fill in your values
PORT=8080
HOST=localhost
DATABASE_URL=postgres://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-key-at-least-32-characters-long
DATABASE_POOL_SIZE=10
JWT_EXPIRY=3600
DEBUG=true
LOG_LEVEL=debug
ENVIRONMENT=development
```

---

## Test-Befehle

```bash
# Development (Standard)
dart run bin/server.dart

# Output:
# ==================================================
# Starting server...
# Environment: development
# Host: localhost
# Port: 8080
# Debug Mode: true
# Log Level: debug
# ==================================================
# Server running on http://localhost:8080

# Endpunkte testen
curl http://localhost:8080/health
curl http://localhost:8080/config

# Mit überschriebenen Variablen
PORT=3000 LOG_LEVEL=info dart run bin/server.dart

# Production simulieren
ENVIRONMENT=production \
DATABASE_URL=postgres://prod:prod@db:5432/proddb \
JWT_SECRET=production-secret-key-that-is-definitely-long-enough \
dart run bin/server.dart

# Validation-Fehler testen
JWT_SECRET=short DATABASE_URL=invalid dart run bin/server.dart
# Output:
# ❌ Configuration Validation Failed:
#    JWT_SECRET must be at least 32 characters (got 5)
#    DATABASE_URL must start with postgres:// or postgresql://

# Debug in Production testen
ENVIRONMENT=production \
DEBUG=true \
DATABASE_URL=postgres://x:x@x:5432/x \
JWT_SECRET=development-secret-which-is-long-enough-32chars \
dart run bin/server.dart
# Output:
# ❌ Configuration Validation Failed:
#    DEBUG must be false in production
#    JWT_SECRET must not contain "development", "dev", or "test" in production
```

---

## Wichtige Erkenntnisse

### 1. Priorität der Konfiguration

```
System-Env > .env.{environment} > .env
```

### 2. Secrets niemals ausgeben

```dart
// FALSCH
return Response.ok(jsonEncode({
  'jwtSecret': config.jwtSecret,  // NIEMALS!
  'databaseUrl': config.databaseUrl,  // Enthält Passwort!
}));

// RICHTIG
return Response.ok(jsonEncode({
  'environment': config.environment,
  'debugMode': config.debugMode,
  // Keine Secrets
}));
```

### 3. putIfAbsent vs. direkte Zuweisung

```dart
// putIfAbsent: Überschreibt NICHT existierende Werte
env.putIfAbsent('KEY', () => 'value');

// Direkte Zuweisung: Überschreibt immer
env['KEY'] = 'value';
```

### 4. Frühe Validierung

Validiere die Konfiguration beim Start, nicht erst bei Verwendung:

```dart
void main() async {
  try {
    final config = await loadConfig();
    config.validate();  // Früh validieren!
    // ...
  } on ConfigValidationException catch (e) {
    print('Config invalid: $e');
    exit(1);
  }
}
```
