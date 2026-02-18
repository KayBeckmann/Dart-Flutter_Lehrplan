# Übung 5.5: Konfiguration & Umgebungsvariablen

## Ziel

Erstelle ein konfigurierbares Server-Projekt mit Umgebungsvariablen, .env-Dateien und einer typsicheren Konfigurationsklasse.

---

## Aufgabe 1: .env-Loader implementieren (15 min)

Erstelle eine Funktion, die .env-Dateien lädt.

### Anforderungen

```dart
Future<Map<String, String>> loadEnvFile(String path);
```

Die Funktion soll:
1. Die Datei lesen (falls vorhanden)
2. Kommentarzeilen (`#`) ignorieren
3. Leere Zeilen ignorieren
4. `KEY=VALUE` Format parsen
5. Quotes (`"` und `'`) von Werten entfernen
6. Leere Map zurückgeben wenn Datei nicht existiert

### Test-Datei (.env.test)

```env
# Server
PORT=3000
HOST=localhost

# Database
DATABASE_URL="postgres://user:pass@localhost:5432/testdb"

# Feature Flags
DEBUG=true
ENABLE_LOGGING='true'

# Leerzeile ignorieren

# Ungültige Zeile ohne = sollte ignoriert werden
INVALID_LINE
```

---

## Aufgabe 2: Config-Klasse erstellen (20 min)

Erstelle eine typsichere Konfigurationsklasse.

### Anforderungen

```dart
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

  // Getter
  bool get isDevelopment;
  bool get isProduction;
  bool get isStaging;
}
```

### Factory-Konstruktor

```dart
factory AppConfig.fromEnvironment(Map<String, String> env);
```

### Anforderungen an fromEnvironment:

1. Pflichtfelder: `DATABASE_URL`, `JWT_SECRET`
2. Optionale Felder mit Defaults:
   - `HOST`: `localhost`
   - `PORT`: `8080`
   - `DATABASE_POOL_SIZE`: `10`
   - `JWT_EXPIRY`: `3600` (Sekunden)
   - `DEBUG`: `false`
   - `LOG_LEVEL`: `info`
   - `ENVIRONMENT`: `development`

3. Bei fehlendem Pflichtfeld: Exception werfen

---

## Aufgabe 3: Config-Validation (10 min)

Füge eine `validate()`-Methode zur Config-Klasse hinzu.

### Regeln

1. `jwtSecret` muss mindestens 32 Zeichen haben
2. `databaseUrl` muss mit `postgres://` oder `postgresql://` beginnen
3. `port` muss zwischen 1 und 65535 liegen
4. `logLevel` muss einer von: `debug`, `info`, `warning`, `error` sein
5. In Production darf `debugMode` nicht `true` sein
6. In Production darf `jwtSecret` nicht "development" enthalten

### Validation-Fehler sammeln

```dart
class ConfigValidationException implements Exception {
  final List<String> errors;
  ConfigValidationException(this.errors);

  @override
  String toString() => 'ConfigValidationException:\n${errors.join('\n')}';
}
```

---

## Aufgabe 4: Environment-Loader (15 min)

Erstelle eine Funktion, die Umgebung und .env zusammenführt.

### Anforderungen

```dart
Future<AppConfig> loadConfig() async {
  // 1. Basis-Environment laden
  final env = Map<String, String>.from(Platform.environment);

  // 2. .env-Datei laden (überschreibt nicht)
  final dotenv = await loadEnvFile('.env');
  for (final entry in dotenv.entries) {
    env.putIfAbsent(entry.key, () => entry.value);
  }

  // 3. Umgebungsspezifische .env laden
  // Wenn ENVIRONMENT=staging, lade .env.staging
  final environment = env['ENVIRONMENT'] ?? 'development';
  final envSpecific = await loadEnvFile('.env.$environment');
  // ...

  // 4. Config erstellen und validieren
  final config = AppConfig.fromEnvironment(env);
  config.validate();

  return config;
}
```

### Priorität (höchste zuerst)

1. System-Umgebungsvariablen (`Platform.environment`)
2. `.env.{environment}`
3. `.env`

---

## Aufgabe 5: Server mit Config starten (10 min)

Erstelle einen Server, der die Konfiguration nutzt.

### main.dart

```dart
void main() async {
  try {
    final config = await loadConfig();

    print('Starting server...');
    print('Environment: ${config.environment}');
    print('Debug Mode: ${config.debugMode}');
    print('Log Level: ${config.logLevel}');

    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router(config));

    await shelf_io.serve(handler, config.host, config.port);
    print('Server running on http://${config.host}:${config.port}');
  } on ConfigValidationException catch (e) {
    print('Configuration Error:');
    print(e);
    exit(1);
  } catch (e) {
    print('Failed to start server: $e');
    exit(1);
  }
}

Router _router(AppConfig config) {
  final router = Router();

  router.get('/health', (Request r) => Response.ok(jsonEncode({
    'status': 'ok',
    'environment': config.environment,
    'debug': config.debugMode,
  })));

  router.get('/config', (Request r) {
    // Nur in Development!
    if (!config.isDevelopment) {
      return Response.forbidden('Not allowed in production');
    }
    return Response.ok(jsonEncode({
      'host': config.host,
      'port': config.port,
      'environment': config.environment,
      'logLevel': config.logLevel,
      // NIEMALS Secrets ausgeben!
    }));
  });

  return router;
}
```

---

## Test-Setup

### .env

```env
PORT=8080
HOST=localhost
DATABASE_URL=postgres://dev:dev@localhost:5432/devdb
JWT_SECRET=development-secret-key-that-is-long-enough
DEBUG=true
LOG_LEVEL=debug
ENVIRONMENT=development
```

### .env.production

```env
PORT=80
HOST=0.0.0.0
DATABASE_POOL_SIZE=50
DEBUG=false
LOG_LEVEL=warning
ENVIRONMENT=production
```

---

## Testen

```bash
# Development (Standard)
dart run bin/server.dart

# Mit Umgebungsvariablen
PORT=3000 DEBUG=false dart run bin/server.dart

# Production simulieren
ENVIRONMENT=production \
DATABASE_URL=postgres://prod:prod@db:5432/proddb \
JWT_SECRET=production-secret-key-that-is-at-least-32-chars \
dart run bin/server.dart

# Validation-Fehler testen
JWT_SECRET=short dart run bin/server.dart
# Sollte Fehler zeigen

# Endpunkte testen
curl http://localhost:8080/health
curl http://localhost:8080/config  # Nur in Development
```

---

## Abgabe-Checkliste

- [ ] .env-Loader funktioniert korrekt
- [ ] Config-Klasse mit allen Feldern
- [ ] Pflichtfeld-Prüfung funktioniert
- [ ] Validation mit sinnvollen Regeln
- [ ] Environment-spezifische Dateien werden geladen
- [ ] Server nutzt Konfiguration
- [ ] /config Endpunkt nur in Development
