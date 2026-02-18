# Ressourcen: Konfiguration & Umgebungsvariablen

## Packages

| Package | Beschreibung | Link |
|---------|--------------|------|
| `dotenv` | .env-Dateien laden | [pub.dev](https://pub.dev/packages/dotenv) |
| `envied` | Type-safe env mit Code-Gen | [pub.dev](https://pub.dev/packages/envied) |
| `args` | Command-Line Arguments | [pub.dev](https://pub.dev/packages/args) |

## Cheat Sheet: Umgebungsvariablen

```dart
import 'dart:io';

// Variable lesen
final value = Platform.environment['KEY'];

// Mit Default
final port = Platform.environment['PORT'] ?? '8080';

// Zu int konvertieren
final portInt = int.parse(Platform.environment['PORT'] ?? '8080');

// Pflichtfeld
final required = Platform.environment['KEY'] ??
    (throw Exception('KEY not set'));

// Boolean
final debug = Platform.environment['DEBUG'] == 'true';
```

## Cheat Sheet: .env Format

```env
# Kommentar
KEY=value
PORT=8080
DATABASE_URL=postgres://user:pass@host:5432/db

# Mit Quotes (für Leerzeichen)
MESSAGE="Hello World"
PATH='some/path with/spaces'

# Mehrzeilige Werte (mit \n)
PRIVATE_KEY="-----BEGIN KEY-----\nbase64data\n-----END KEY-----"
```

## Cheat Sheet: Config-Klasse

```dart
class Config {
  final int port;
  final String dbUrl;

  Config({required this.port, required this.dbUrl});

  factory Config.fromEnv() {
    return Config(
      port: int.parse(Platform.environment['PORT'] ?? '8080'),
      dbUrl: Platform.environment['DATABASE_URL'] ?? '',
    );
  }
}
```

## Cheat Sheet: .env laden (manuell)

```dart
Future<Map<String, String>> loadEnv([String path = '.env']) async {
  final file = File(path);
  if (!await file.exists()) return {};

  final env = <String, String>{};
  for (final line in await file.readAsLines()) {
    final l = line.trim();
    if (l.isEmpty || l.startsWith('#')) continue;
    final i = l.indexOf('=');
    if (i == -1) continue;
    env[l.substring(0, i).trim()] = l.substring(i + 1).trim();
  }
  return env;
}
```

## Best Practices

### 1. .env.example verwenden

```env
# .env.example (im Git)
PORT=8080
DATABASE_URL=postgres://user:password@localhost:5432/dbname
JWT_SECRET=your-secret-here
```

### 2. Validierung

```dart
void validateConfig(Config config) {
  if (config.jwtSecret.length < 32) {
    throw Exception('JWT_SECRET too short');
  }
  if (config.isProduction && config.jwtSecret.contains('dev')) {
    throw Exception('Development secret in production!');
  }
}
```

### 3. Typsichere Defaults

```dart
class Config {
  static int _intEnv(String key, int def) =>
      int.tryParse(Platform.environment[key] ?? '') ?? def;

  static bool _boolEnv(String key, bool def) =>
      Platform.environment[key]?.toLowerCase() == 'true' || def;

  static Duration _durationEnv(String key, Duration def) =>
      Duration(seconds: _intEnv(key, def.inSeconds));
}
```

### 4. .gitignore

```gitignore
# Umgebungsvariablen
.env
.env.local
.env.*.local

# Secrets
*.pem
*.key
secrets/

# Behalte Example
!.env.example
```

## Projektstruktur

```
project/
├── .env                 # Nicht im Git
├── .env.example         # Im Git
├── lib/
│   └── config/
│       ├── config.dart
│       ├── database_config.dart
│       └── auth_config.dart
└── bin/
    └── server.dart
```

## Shell-Befehle

```bash
# Variable setzen
export PORT=8080

# Inline für einen Befehl
PORT=8080 dart run bin/server.dart

# Mehrere Variablen
export PORT=8080 HOST=0.0.0.0

# .env manuell laden (Bash)
export $(cat .env | xargs)

# Variable prüfen
echo $PORT
printenv PORT
```

## Docker & Deployment

```dockerfile
# Dockerfile
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart compile exe bin/server.dart -o server

FROM scratch
COPY --from=build /runtime/ /
COPY --from=build /app/server /app/server
# ENV wird beim Container-Start gesetzt
CMD ["/app/server"]
```

```bash
# Docker run mit Env
docker run -e PORT=8080 -e DATABASE_URL=... myapp

# Docker Compose
# docker-compose.yml
services:
  app:
    environment:
      - PORT=8080
      - DATABASE_URL=postgres://...
    env_file:
      - .env.production
```
