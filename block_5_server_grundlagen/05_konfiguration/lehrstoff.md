# Einheit 5.5: Konfiguration & Umgebungsvariablen

## Lernziele

Nach dieser Einheit kannst du:
- Umgebungsvariablen in Dart lesen
- `.env`-Dateien für lokale Entwicklung nutzen
- Konfigurationsklassen erstellen
- Verschiedene Umgebungen (dev/staging/prod) verwalten

---

## Warum Konfiguration?

Anwendungen brauchen konfigurierbare Werte:
- **Datenbankverbindungen** (Host, Port, Credentials)
- **API-Keys** für externe Dienste
- **Server-Port** und -Host
- **Feature Flags**
- **Logging-Level**

Diese Werte sollten NICHT im Code stehen:
- Sicherheitsrisiko (Secrets im Git-Repository)
- Keine Flexibilität (Code-Änderung für neue Umgebung)
- Schlechte Wartbarkeit

---

## Umgebungsvariablen in Dart

### Lesen mit Platform.environment

```dart
import 'dart:io';

void main() {
  // Einzelne Variable lesen
  final port = Platform.environment['PORT'];
  print('PORT: $port');

  // Mit Default-Wert
  final host = Platform.environment['HOST'] ?? 'localhost';
  print('HOST: $host');

  // Alle Umgebungsvariablen
  Platform.environment.forEach((key, value) {
    print('$key: $value');
  });
}
```

### Variablen setzen

```bash
# Einzelne Variable
export PORT=8080
dart run bin/server.dart

# Inline
PORT=8080 HOST=0.0.0.0 dart run bin/server.dart

# Mehrere Variablen
export DATABASE_URL=postgres://localhost:5432/mydb
export JWT_SECRET=supersecret
dart run bin/server.dart
```

---

## .env-Dateien

Für lokale Entwicklung sind `.env`-Dateien praktisch. Sie werden NICHT ins Git-Repository committed.

### .env Datei Format

```env
# .env
PORT=8080
HOST=localhost

# Datenbank
DATABASE_URL=postgres://user:pass@localhost:5432/mydb
DATABASE_POOL_SIZE=10

# Auth
JWT_SECRET=my-super-secret-key
JWT_EXPIRY=3600

# Externe APIs
STRIPE_API_KEY=sk_test_abc123
SENDGRID_API_KEY=SG.xyz789
```

### .env laden mit dotenv Package

```yaml
# pubspec.yaml
dependencies:
  dotenv: ^4.2.0
```

```dart
import 'package:dotenv/dotenv.dart' as dotenv;
import 'dart:io';

void main() {
  // .env laden (nur in Development!)
  dotenv.load();

  // Jetzt sind Variablen verfügbar
  final port = dotenv.env['PORT'] ?? Platform.environment['PORT'] ?? '8080';

  print('Port: $port');
}
```

### Manuelle .env-Implementierung

Ohne externes Package:

```dart
import 'dart:io';

Future<Map<String, String>> loadEnvFile([String path = '.env']) async {
  final file = File(path);
  final env = <String, String>{};

  if (!await file.exists()) {
    return env;
  }

  final lines = await file.readAsLines();

  for (final line in lines) {
    // Kommentare und leere Zeilen überspringen
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

    // KEY=VALUE parsen
    final index = trimmed.indexOf('=');
    if (index == -1) continue;

    final key = trimmed.substring(0, index).trim();
    var value = trimmed.substring(index + 1).trim();

    // Quotes entfernen
    if ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))) {
      value = value.substring(1, value.length - 1);
    }

    env[key] = value;
  }

  return env;
}
```

---

## Konfigurationsklassen

Statt überall `Platform.environment['KEY']` zu schreiben, kapsle die Konfiguration in einer Klasse.

### Einfache Config-Klasse

```dart
class Config {
  final String host;
  final int port;
  final String databaseUrl;
  final String jwtSecret;
  final int jwtExpiry;
  final String environment;

  Config({
    required this.host,
    required this.port,
    required this.databaseUrl,
    required this.jwtSecret,
    this.jwtExpiry = 3600,
    this.environment = 'development',
  });

  /// Lädt Konfiguration aus Umgebungsvariablen
  factory Config.fromEnvironment() {
    return Config(
      host: _env('HOST', 'localhost'),
      port: int.parse(_env('PORT', '8080')),
      databaseUrl: _envRequired('DATABASE_URL'),
      jwtSecret: _envRequired('JWT_SECRET'),
      jwtExpiry: int.parse(_env('JWT_EXPIRY', '3600')),
      environment: _env('ENVIRONMENT', 'development'),
    );
  }

  bool get isDevelopment => environment == 'development';
  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';

  static String _env(String key, String defaultValue) {
    return Platform.environment[key] ?? defaultValue;
  }

  static String _envRequired(String key) {
    final value = Platform.environment[key];
    if (value == null || value.isEmpty) {
      throw Exception('Required environment variable $key is not set');
    }
    return value;
  }
}
```

### Verwendung

```dart
void main() async {
  final config = Config.fromEnvironment();

  print('Starting server...');
  print('Environment: ${config.environment}');
  print('Host: ${config.host}:${config.port}');

  if (config.isDevelopment) {
    print('Development mode - verbose logging enabled');
  }

  await shelf_io.serve(handler, config.host, config.port);
}
```

---

## Umgebungsspezifische Konfiguration

### Verschiedene .env-Dateien

```
project/
├── .env                 # Lokale Entwicklung (nicht im Git)
├── .env.example         # Template (im Git)
├── .env.staging         # Staging-Umgebung
└── .env.production      # Produktion
```

### .env.example

```env
# .env.example - Kopiere zu .env und fülle aus
PORT=8080
HOST=localhost
DATABASE_URL=postgres://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-here
ENVIRONMENT=development
```

### .gitignore

```gitignore
# Umgebungsvariablen
.env
.env.local
.env.*.local

# Behalte das Example
!.env.example
```

### Environment-Laden

```dart
Future<void> loadEnvironment() async {
  final env = Platform.environment['ENVIRONMENT'] ?? 'development';

  // Versuche umgebungsspezifische Datei zu laden
  final envFile = File('.env.$env');
  if (await envFile.exists()) {
    await _loadEnvFile('.env.$env');
  }

  // Dann die Standard .env (überschreibt nicht)
  await _loadEnvFile('.env');
}
```

---

## Secrets sicher verwalten

### Niemals in Git

```gitignore
# .gitignore
.env
*.pem
*.key
secrets/
```

### In Produktion

Produktions-Secrets sollten über die Plattform injiziert werden:

```bash
# Docker
docker run -e JWT_SECRET=secret -e DATABASE_URL=... myapp

# Kubernetes
kubectl create secret generic app-secrets \
  --from-literal=JWT_SECRET=secret \
  --from-literal=DATABASE_URL=...

# Cloud (z.B. Railway, Fly.io, Heroku)
# Über Web-Interface oder CLI setzen
```

### Secret-Validation

```dart
class Config {
  // ...

  void validate() {
    final errors = <String>[];

    if (jwtSecret.length < 32) {
      errors.add('JWT_SECRET should be at least 32 characters');
    }

    if (!databaseUrl.startsWith('postgres://')) {
      errors.add('DATABASE_URL must be a valid PostgreSQL URL');
    }

    if (isProduction && jwtSecret == 'development-secret') {
      errors.add('Cannot use development secret in production!');
    }

    if (errors.isNotEmpty) {
      throw ConfigurationException(errors.join('\n'));
    }
  }
}

class ConfigurationException implements Exception {
  final String message;
  ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
```

---

## Erweiterte Config-Klasse

### Mit Sub-Konfigurationen

```dart
class Config {
  final ServerConfig server;
  final DatabaseConfig database;
  final AuthConfig auth;
  final String environment;

  Config({
    required this.server,
    required this.database,
    required this.auth,
    required this.environment,
  });

  factory Config.fromEnvironment() {
    return Config(
      server: ServerConfig.fromEnvironment(),
      database: DatabaseConfig.fromEnvironment(),
      auth: AuthConfig.fromEnvironment(),
      environment: _env('ENVIRONMENT', 'development'),
    );
  }

  static String _env(String key, [String? defaultValue]) {
    return Platform.environment[key] ?? defaultValue ?? '';
  }
}

class ServerConfig {
  final String host;
  final int port;

  ServerConfig({required this.host, required this.port});

  factory ServerConfig.fromEnvironment() {
    return ServerConfig(
      host: Platform.environment['HOST'] ?? 'localhost',
      port: int.parse(Platform.environment['PORT'] ?? '8080'),
    );
  }
}

class DatabaseConfig {
  final String url;
  final int poolSize;
  final Duration connectionTimeout;

  DatabaseConfig({
    required this.url,
    this.poolSize = 10,
    this.connectionTimeout = const Duration(seconds: 30),
  });

  factory DatabaseConfig.fromEnvironment() {
    return DatabaseConfig(
      url: Platform.environment['DATABASE_URL'] ?? '',
      poolSize: int.parse(Platform.environment['DB_POOL_SIZE'] ?? '10'),
      connectionTimeout: Duration(
        seconds: int.parse(Platform.environment['DB_TIMEOUT'] ?? '30'),
      ),
    );
  }
}

class AuthConfig {
  final String jwtSecret;
  final Duration tokenExpiry;
  final Duration refreshExpiry;

  AuthConfig({
    required this.jwtSecret,
    this.tokenExpiry = const Duration(hours: 1),
    this.refreshExpiry = const Duration(days: 7),
  });

  factory AuthConfig.fromEnvironment() {
    return AuthConfig(
      jwtSecret: Platform.environment['JWT_SECRET'] ?? '',
      tokenExpiry: Duration(
        seconds: int.parse(Platform.environment['JWT_EXPIRY'] ?? '3600'),
      ),
      refreshExpiry: Duration(
        days: int.parse(Platform.environment['REFRESH_EXPIRY_DAYS'] ?? '7'),
      ),
    );
  }
}
```

---

## Zusammenfassung

- **Umgebungsvariablen** über `Platform.environment` lesen
- **.env-Dateien** für lokale Entwicklung
- **Konfigurationsklassen** für typsichere Konfiguration
- **.env.example** ins Git, echte `.env` in .gitignore
- **Validation** für Produktions-Konfiguration
- **Secrets** niemals in Git committen

---

## Nächste Schritte

In der nächsten Einheit lernst du **Projekt-Struktur & Architektur**: Wie du dein Backend-Projekt organisierst für bessere Wartbarkeit.
