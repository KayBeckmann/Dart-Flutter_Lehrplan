# Einheit 9.5: Backend-Abschlussprojekt

## Projektübersicht

### Task Management API

Du entwickelst eine vollständige Task-Management-API, die alle gelernten Konzepte aus dem Backend-Teil zusammenführt.

### Features

```
┌─────────────────────────────────────────────────────────────┐
│                    Task Management API                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  👤 Benutzer                    📋 Projekte                 │
│  ├── Registrierung             ├── CRUD                    │
│  ├── Login/Logout              ├── Mitglieder              │
│  ├── JWT Auth                  └── Berechtigungen          │
│  └── Profil                                                 │
│                                                             │
│  ✅ Tasks                       🔔 Real-time                │
│  ├── CRUD                      ├── WebSocket               │
│  ├── Zuweisung                 ├── Live-Updates            │
│  ├── Status                    └── Notifications           │
│  ├── Priorität                                              │
│  └── Kommentare                                             │
│                                                             │
│  🔒 Sicherheit                  📊 Infrastruktur            │
│  ├── Rate Limiting             ├── PostgreSQL              │
│  ├── Input Validation          ├── Redis Caching           │
│  ├── CORS                      ├── Docker                  │
│  └── Security Headers          └── Health Checks           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Architektur

### Layered Architecture

```
┌─────────────────────────────────────────────┐
│                  Handlers                    │
│         (HTTP Endpoints, WebSocket)          │
├─────────────────────────────────────────────┤
│                  Services                    │
│            (Business Logic)                  │
├─────────────────────────────────────────────┤
│                Repositories                  │
│              (Data Access)                   │
├─────────────────────────────────────────────┤
│                 Database                     │
│         (PostgreSQL, Redis)                  │
└─────────────────────────────────────────────┘
```

### Projektstruktur

```
task_api/
├── bin/
│   ├── server.dart           # Hauptserver
│   ├── migrate.dart          # DB Migrationen
│   └── seed.dart             # Test-Daten
├── lib/
│   ├── config/
│   │   ├── config.dart       # Konfiguration
│   │   └── dependencies.dart # DI Container
│   ├── models/
│   │   ├── user.dart
│   │   ├── project.dart
│   │   ├── task.dart
│   │   └── comment.dart
│   ├── repositories/
│   │   ├── user_repository.dart
│   │   ├── project_repository.dart
│   │   ├── task_repository.dart
│   │   └── comment_repository.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── project_service.dart
│   │   ├── task_service.dart
│   │   └── notification_service.dart
│   ├── handlers/
│   │   ├── auth_handler.dart
│   │   ├── project_handler.dart
│   │   ├── task_handler.dart
│   │   └── websocket_handler.dart
│   ├── middleware/
│   │   ├── auth_middleware.dart
│   │   ├── rate_limit_middleware.dart
│   │   ├── cors_middleware.dart
│   │   └── error_middleware.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── validator.dart
│   │   └── jwt_utils.dart
│   └── app.dart              # App zusammenbauen
├── test/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
├── .env.example
├── pubspec.yaml
└── README.md
```

---

## Datenmodell

### Entity-Relationship-Diagramm

```
┌─────────────┐       ┌─────────────────┐       ┌─────────────┐
│   users     │       │ project_members │       │  projects   │
├─────────────┤       ├─────────────────┤       ├─────────────┤
│ id          │──┐    │ user_id    (FK) │    ┌──│ id          │
│ email       │  └───>│ project_id (FK) │<───┘  │ name        │
│ password    │       │ role            │       │ description │
│ name        │       │ joined_at       │       │ owner_id(FK)│
│ role        │       └─────────────────┘       │ created_at  │
│ created_at  │                                 │ updated_at  │
└─────────────┘                                 └─────────────┘
       │                                               │
       │                                               │
       │          ┌─────────────┐                      │
       │          │   tasks     │                      │
       │          ├─────────────┤                      │
       └─────────>│ id          │<─────────────────────┘
                  │ title       │
                  │ description │
                  │ status      │
                  │ priority    │
                  │ project_id  │
                  │ assignee_id │
                  │ created_by  │
                  │ due_date    │
                  │ created_at  │
                  │ updated_at  │
                  └─────────────┘
                         │
                         │
                  ┌──────┴──────┐
                  │  comments   │
                  ├─────────────┤
                  │ id          │
                  │ task_id(FK) │
                  │ user_id(FK) │
                  │ content     │
                  │ created_at  │
                  └─────────────┘
```

### SQL Schema

```sql
-- users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    avatar_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- projects
CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES users(id),
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- project_members
CREATE TABLE project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',  -- owner, admin, member, viewer
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

-- tasks
CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'todo',  -- todo, in_progress, review, done
    priority VARCHAR(50) DEFAULT 'medium',  -- low, medium, high, urgent
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    assignee_id INTEGER REFERENCES users(id),
    created_by INTEGER REFERENCES users(id),
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- comments
CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- refresh_tokens
CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## API Endpoints

### Authentication

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| POST | /api/auth/register | Registrierung |
| POST | /api/auth/login | Login |
| POST | /api/auth/refresh | Token erneuern |
| POST | /api/auth/logout | Logout |
| GET | /api/auth/me | Aktueller User |

### Users

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| GET | /api/users | Alle User (Admin) |
| GET | /api/users/:id | User Details |
| PUT | /api/users/:id | User aktualisieren |
| DELETE | /api/users/:id | User löschen (Admin) |

### Projects

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| GET | /api/projects | Meine Projekte |
| POST | /api/projects | Projekt erstellen |
| GET | /api/projects/:id | Projekt Details |
| PUT | /api/projects/:id | Projekt aktualisieren |
| DELETE | /api/projects/:id | Projekt löschen |
| GET | /api/projects/:id/members | Mitglieder |
| POST | /api/projects/:id/members | Mitglied hinzufügen |
| DELETE | /api/projects/:id/members/:userId | Mitglied entfernen |

### Tasks

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| GET | /api/projects/:id/tasks | Tasks eines Projekts |
| POST | /api/projects/:id/tasks | Task erstellen |
| GET | /api/tasks/:id | Task Details |
| PUT | /api/tasks/:id | Task aktualisieren |
| PATCH | /api/tasks/:id/status | Status ändern |
| PATCH | /api/tasks/:id/assign | Zuweisen |
| DELETE | /api/tasks/:id | Task löschen |

### Comments

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| GET | /api/tasks/:id/comments | Kommentare |
| POST | /api/tasks/:id/comments | Kommentar hinzufügen |
| PUT | /api/comments/:id | Kommentar bearbeiten |
| DELETE | /api/comments/:id | Kommentar löschen |

### System

| Method | Endpoint | Beschreibung |
|--------|----------|--------------|
| GET | /health | Health Check |
| GET | /health/ready | Readiness Check |
| GET | /metrics | Prometheus Metrics |
| WS | /ws | WebSocket Connection |

---

## Implementierungs-Roadmap

### Phase 1: Grundgerüst (Tag 1)

```
[ ] Projektstruktur erstellen
[ ] pubspec.yaml konfigurieren
[ ] Basis-Konfiguration (Config-Klasse)
[ ] Logger einrichten
[ ] Datenbank-Connection
[ ] Basis-Middleware (CORS, Logging)
[ ] Health Check Endpoint
```

### Phase 2: Authentifizierung (Tag 1-2)

```
[ ] User Model
[ ] User Repository
[ ] Password Service (bcrypt)
[ ] JWT Service
[ ] Auth Service
[ ] Auth Handler (Register, Login, Logout)
[ ] Auth Middleware
[ ] Refresh Token Flow
```

### Phase 3: Projekte & Tasks (Tag 2-3)

```
[ ] Project Model & Repository
[ ] Task Model & Repository
[ ] Comment Model & Repository
[ ] Project Service mit Berechtigungen
[ ] Task Service
[ ] CRUD Handler für Projekte
[ ] CRUD Handler für Tasks
[ ] Kommentar-Funktionalität
```

### Phase 4: Real-time (Tag 3)

```
[ ] WebSocket Handler
[ ] Connection Manager
[ ] Notification Service
[ ] Live Updates bei Task-Änderungen
[ ] Präsenz-Anzeige (optional)
```

### Phase 5: Produktion (Tag 4)

```
[ ] Rate Limiting
[ ] Input Validation
[ ] Security Headers
[ ] Redis Caching
[ ] Docker Setup
[ ] Tests schreiben
[ ] Dokumentation
```

---

## Technologie-Stack

### Packages

```yaml
dependencies:
  # Server
  shelf: ^1.4.0
  shelf_router: ^1.1.0
  shelf_web_socket: ^2.0.0

  # Database
  postgres: ^3.0.0

  # Cache
  redis: ^3.0.0

  # Auth
  bcrypt: ^1.1.0
  dart_jsonwebtoken: ^2.8.0

  # Utilities
  uuid: ^4.0.0
  dotenv: ^4.1.0

dev_dependencies:
  test: ^1.24.0
  mocktail: ^1.0.0
```

### Infrastruktur

- **PostgreSQL 15** - Primäre Datenbank
- **Redis 7** - Caching & Sessions
- **Docker** - Containerisierung
- **GitHub Actions** - CI/CD

---

## Bewertungskriterien

### Funktionalität (40%)

- [ ] Vollständige Auth-Flows
- [ ] CRUD für alle Entitäten
- [ ] Korrekte Berechtigungen
- [ ] WebSocket-Updates
- [ ] Fehlerbehandlung

### Code-Qualität (30%)

- [ ] Saubere Architektur
- [ ] Separation of Concerns
- [ ] Keine Code-Duplikation
- [ ] Aussagekräftige Benennung
- [ ] Dokumentation

### Sicherheit (15%)

- [ ] Sichere Passwort-Speicherung
- [ ] JWT korrekt implementiert
- [ ] Input Validation
- [ ] SQL Injection geschützt
- [ ] Rate Limiting

### Infrastruktur (15%)

- [ ] Docker funktioniert
- [ ] Health Checks
- [ ] Logging strukturiert
- [ ] Metriken vorhanden
- [ ] Tests vorhanden

---

## Tipps

### Starte klein

```dart
// Erst ein Endpoint, dann erweitern
router.get('/api/projects', (Request request) async {
  return Response.ok('[]');
});
```

### Nutze Dependency Injection

```dart
class Dependencies {
  late final Connection db;
  late final UserRepository userRepo;
  late final AuthService authService;

  Future<void> init() async {
    db = await Connection.open(...);
    userRepo = UserRepository(db);
    authService = AuthService(userRepo, ...);
  }
}
```

### Teste früh

```dart
test('login returns tokens', () async {
  final result = await authService.login('test@test.com', 'password');
  expect(result.accessToken, isNotEmpty);
});
```

### Dokumentiere während du entwickelst

```dart
/// Erstellt einen neuen Task im angegebenen Projekt.
///
/// Erfordert Projekt-Mitgliedschaft.
/// Sendet WebSocket-Notification an alle Projekt-Mitglieder.
Future<Task> createTask(CreateTaskDto dto, int userId) async {
  // ...
}
```

---

## Ressourcen

- Alle Lehrstoffe aus Block 5-9
- [Shelf Dokumentation](https://pub.dev/packages/shelf)
- [PostgreSQL Dokumentation](https://www.postgresql.org/docs/)
- [JWT.io](https://jwt.io/) - Token debuggen
- [Postman](https://www.postman.com/) - API testen
