# Übung 9.5: Backend-Abschlussprojekt

## Task Management API

Entwickle eine vollständige Task-Management-API mit allen Features aus dem Backend-Curriculum.

**Geschätzter Zeitaufwand:** 8-12 Stunden

---

## Vorbereitung

### 1. Projekt erstellen

```bash
mkdir task_api
cd task_api
dart create -t server-shelf .
```

### 2. Dependencies

```yaml
# pubspec.yaml
name: task_api
description: Task Management API
version: 1.0.0

environment:
  sdk: ^3.0.0

dependencies:
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_web_socket: ^2.0.0
  postgres: ^3.0.0
  redis: ^3.0.0
  bcrypt: ^1.1.0
  dart_jsonwebtoken: ^2.8.0
  uuid: ^4.0.0
  dotenv: ^4.1.0

dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

### 3. Docker-Umgebung

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: taskapi
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./migrations:/docker-entrypoint-initdb.d:ro

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

```bash
docker compose up -d
```

---

## Phase 1: Grundgerüst

### Aufgabe 1.1: Konfiguration (30 min)

```dart
// lib/config/config.dart

class AppConfig {
  final int port;
  final String databaseUrl;
  final String redisUrl;
  final String jwtSecret;
  final Duration jwtAccessDuration;
  final Duration jwtRefreshDuration;
  final LogLevel logLevel;

  AppConfig({
    required this.port,
    required this.databaseUrl,
    required this.redisUrl,
    required this.jwtSecret,
    this.jwtAccessDuration = const Duration(minutes: 15),
    this.jwtRefreshDuration = const Duration(days: 7),
    this.logLevel = LogLevel.info,
  });

  factory AppConfig.fromEnvironment() {
    // TODO: Aus Environment Variables laden
    // TODO: Defaults für Entwicklung
  }
}
```

### Aufgabe 1.2: Logger (20 min)

```dart
// lib/utils/logger.dart

// TODO: Logger aus Einheit 9.3 implementieren
// - Log Level (debug, info, warning, error)
// - JSON-Format für Produktion
// - Request-ID Context
```

### Aufgabe 1.3: Datenbank-Setup (30 min)

```sql
-- migrations/001_initial.sql

-- TODO: Schema erstellen
-- - users
-- - projects
-- - project_members
-- - tasks
-- - comments
-- - refresh_tokens

-- TODO: Indizes

-- TODO: Trigger für updated_at
```

### Aufgabe 1.4: Health Check (20 min)

```dart
// lib/handlers/health_handler.dart

class HealthHandler {
  final Connection db;
  final RedisConnection? redis;

  // TODO: /health Endpoint
  // TODO: /health/ready Endpoint
  // TODO: /health/live Endpoint
}
```

---

## Phase 2: Authentifizierung

### Aufgabe 2.1: User Model (20 min)

```dart
// lib/models/user.dart

class User {
  final int id;
  final String email;
  final String passwordHash;
  final String name;
  final String role;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // TODO: Konstruktor
  // TODO: fromRow (DB Row)
  // TODO: toJson (ohne passwordHash!)
  // TODO: copyWith
}

class CreateUserDto {
  final String email;
  final String password;
  final String name;

  // TODO: Validation
}
```

### Aufgabe 2.2: Password & JWT Service (30 min)

```dart
// lib/services/password_service.dart
// TODO: hash(), verify(), needsRehash()

// lib/services/jwt_service.dart
// TODO: generateAccessToken(), generateRefreshToken()
// TODO: verifyToken(), extractFromHeader()
```

### Aufgabe 2.3: User Repository (30 min)

```dart
// lib/repositories/user_repository.dart

class UserRepository {
  final Connection db;

  // TODO: create(CreateUserDto)
  // TODO: findById(int id)
  // TODO: findByEmail(String email)
  // TODO: update(int id, UpdateUserDto)
  // TODO: delete(int id)
  // TODO: exists(String email)
}
```

### Aufgabe 2.4: Auth Service (45 min)

```dart
// lib/services/auth_service.dart

class AuthService {
  // TODO: register(email, password, name) -> User
  // TODO: login(email, password) -> TokenPair
  // TODO: refreshToken(refreshToken) -> TokenPair
  // TODO: logout(refreshToken) -> void
  // TODO: getCurrentUser(accessToken) -> User
}
```

### Aufgabe 2.5: Auth Handler (30 min)

```dart
// lib/handlers/auth_handler.dart

class AuthHandler {
  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refresh);
    router.post('/logout', _logout);
    router.get('/me', _me);

    return router;
  }

  // TODO: Implementiere alle Handler
}
```

### Aufgabe 2.6: Auth Middleware (20 min)

```dart
// lib/middleware/auth_middleware.dart

// TODO: authMiddleware - Token validieren, User in Context
// TODO: requireRole(String role) - Rollen-Check
// TODO: optionalAuth - Auth optional (für öffentliche Endpoints)
```

---

## Phase 3: Projekte & Tasks

### Aufgabe 3.1: Project Model & Repository (30 min)

```dart
// lib/models/project.dart

class Project {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // TODO: Implementieren
}

// lib/repositories/project_repository.dart

class ProjectRepository {
  // TODO: create, findById, findByUser, update, delete
  // TODO: addMember, removeMember, getMembers
  // TODO: getUserRole(projectId, userId)
}
```

### Aufgabe 3.2: Task Model & Repository (30 min)

```dart
// lib/models/task.dart

enum TaskStatus { todo, inProgress, review, done }
enum TaskPriority { low, medium, high, urgent }

class Task {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int projectId;
  final int? assigneeId;
  final int createdBy;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // TODO: Implementieren
}

// lib/repositories/task_repository.dart

class TaskRepository {
  // TODO: create, findById, findByProject, update, delete
  // TODO: updateStatus, assign
  // TODO: findByAssignee, findOverdue
}
```

### Aufgabe 3.3: Comment Model & Repository (20 min)

```dart
// lib/models/comment.dart
// lib/repositories/comment_repository.dart

// TODO: Analog zu Task
```

### Aufgabe 3.4: Project Service (45 min)

```dart
// lib/services/project_service.dart

class ProjectService {
  // TODO: Berechtigungsprüfung einbauen
  // - Nur Mitglieder sehen Projekte
  // - Nur Owner/Admin können bearbeiten
  // - Nur Owner kann löschen
}
```

### Aufgabe 3.5: Task Service (45 min)

```dart
// lib/services/task_service.dart

class TaskService {
  // TODO: Task-Logik
  // - Nur Projekt-Mitglieder können Tasks erstellen
  // - Benachrichtigung bei Zuweisung
  // - completedAt setzen bei Status=done
}
```

### Aufgabe 3.6: Handler (60 min)

```dart
// lib/handlers/project_handler.dart
// lib/handlers/task_handler.dart
// lib/handlers/comment_handler.dart

// TODO: CRUD Endpoints für alle Entitäten
```

---

## Phase 4: Real-time

### Aufgabe 4.1: WebSocket Handler (45 min)

```dart
// lib/handlers/websocket_handler.dart

class WebSocketHandler {
  final ConnectionManager _connections;
  final JwtService _jwtService;

  // TODO: handleConnection(WebSocketChannel)
  // TODO: Authentifizierung via Token
  // TODO: Subscription zu Projekten
}
```

### Aufgabe 4.2: Notification Service (30 min)

```dart
// lib/services/notification_service.dart

class NotificationService {
  // TODO: notifyTaskCreated(task)
  // TODO: notifyTaskUpdated(task, changes)
  // TODO: notifyTaskAssigned(task, assignee)
  // TODO: notifyCommentAdded(comment)
}
```

### Aufgabe 4.3: Integration (30 min)

```dart
// TODO: NotificationService in TaskService integrieren
// TODO: Bei Task-Änderungen WebSocket-Updates senden
```

---

## Phase 5: Produktion

### Aufgabe 5.1: Security (45 min)

```dart
// lib/middleware/rate_limit_middleware.dart
// TODO: Rate Limiting implementieren

// lib/middleware/security_middleware.dart
// TODO: Security Headers

// lib/utils/validator.dart
// TODO: Input Validation
```

### Aufgabe 5.2: Caching (30 min)

```dart
// lib/services/cache_service.dart

class CacheService {
  final RedisConnection redis;

  // TODO: get, set, delete
  // TODO: Cache für häufige Queries (z.B. User-Profil)
}
```

### Aufgabe 5.3: Docker (30 min)

```dockerfile
# Dockerfile

# TODO: Multi-Stage Build
# TODO: Non-root User
# TODO: Health Check
```

### Aufgabe 5.4: Tests (60 min)

```dart
// test/services/auth_service_test.dart
// test/handlers/auth_handler_test.dart
// test/integration/auth_flow_test.dart

// TODO: Mindestens:
// - Auth Service Unit Tests
// - Ein Integration Test für Login-Flow
```

### Aufgabe 5.5: Dokumentation (30 min)

```markdown
# README.md

## Setup
## API Endpoints
## Environment Variables
## Development
## Deployment
```

---

## Abgabe

### Funktionale Anforderungen

- [ ] User Registration & Login
- [ ] JWT Access/Refresh Token Flow
- [ ] Projekte erstellen, bearbeiten, löschen
- [ ] Projekt-Mitglieder verwalten
- [ ] Tasks mit Status und Priorität
- [ ] Task-Zuweisung
- [ ] Kommentare zu Tasks
- [ ] WebSocket für Live-Updates
- [ ] Health Checks

### Technische Anforderungen

- [ ] PostgreSQL Datenbank
- [ ] Redis (mindestens für Rate Limiting)
- [ ] Strukturiertes Logging
- [ ] Input Validation
- [ ] Error Handling
- [ ] Docker Compose funktioniert
- [ ] Mindestens 5 Tests

### Bonus

- [ ] Pagination für Listen
- [ ] Task-Filter (Status, Assignee, etc.)
- [ ] File Uploads für Avatare
- [ ] Email-Benachrichtigungen
- [ ] API-Dokumentation (OpenAPI)
- [ ] CI/CD Pipeline

---

## Hilfestellung

### Wenn du nicht weiterkommst

1. Schaue in die entsprechende Lerneinheit
2. Prüfe die Lösungsdatei dieser Übung
3. Vereinfache das Problem
4. Teste mit Postman/curl

### Debugging

```bash
# Logs
docker compose logs -f

# DB Shell
docker compose exec db psql -U postgres -d taskapi

# Redis CLI
docker compose exec redis redis-cli
```

### API Testen

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123","name":"Test"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"test123"}'

# Mit Token
curl http://localhost:8080/api/projects \
  -H "Authorization: Bearer <token>"
```
