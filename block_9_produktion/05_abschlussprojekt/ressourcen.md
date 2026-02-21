# Ressourcen: Backend-Abschlussprojekt

## Referenz zu allen Lerneinheiten

| Thema | Einheit | Wichtige Konzepte |
|-------|---------|-------------------|
| HTTP Server | 5.1-5.2 | dart:io, Shelf, Handler |
| Routing | 5.3 | shelf_router, URL-Parameter |
| Middleware | 5.4 | Pipeline, CORS, Logging |
| Konfiguration | 5.5 | Environment Variables, .env |
| Architektur | 5.6 | Layered Architecture, DI |
| REST Design | 6.1-6.4 | HTTP Methoden, CRUD, Status Codes |
| Validierung | 6.5 | Input Validation, Error Handling |
| Pagination | 6.7 | Offset/Limit, Cursor |
| PostgreSQL | 7.1-7.2 | SQL, postgres Package |
| Repository | 7.3 | Repository Pattern |
| Relationen | 7.4 | JOINs, Foreign Keys |
| Migrations | 7.5 | Schema Versionierung |
| Redis | 7.8 | Caching, Sessions |
| Passwörter | 8.1 | bcrypt, Hashing |
| JWT | 8.2 | Access/Refresh Tokens |
| Auth Middleware | 8.3 | RBAC, Guards |
| API Security | 8.5 | Rate Limiting, CORS, Headers |
| Testing | 8.6 | Unit Tests, Mocks |
| WebSockets | 9.1 | Real-time, shelf_web_socket |
| Background Jobs | 9.2 | Queues, Scheduling |
| Logging | 9.3 | Strukturierte Logs, Metriken |
| Docker | 9.4 | Container, Compose, CI/CD |

---

## Cheat Sheet: Projekt-Setup

```bash
# Projekt erstellen
dart create -t server-shelf task_api
cd task_api

# Dependencies hinzufügen
# pubspec.yaml bearbeiten...
dart pub get

# Docker starten
docker compose up -d

# Server starten
dart run bin/server.dart
```

## Cheat Sheet: API Response Format

```dart
// Erfolg (200, 201)
{
  "data": { ... },
  "meta": {
    "page": 1,
    "limit": 10,
    "total": 100
  }
}

// Fehler (4xx, 5xx)
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": {
      "email": "Invalid email format"
    }
  }
}
```

## Cheat Sheet: Berechtigungen

```dart
// Projekt-Rollen
enum ProjectRole { owner, admin, member, viewer }

// Berechtigungsmatrix
//                  owner  admin  member  viewer
// projekt.update     ✓      ✓       -       -
// projekt.delete     ✓      -       -       -
// member.add         ✓      ✓       -       -
// member.remove      ✓      ✓       -       -
// task.create        ✓      ✓       ✓       -
// task.update        ✓      ✓       ✓       -
// task.delete        ✓      ✓       -       -
// task.view          ✓      ✓       ✓       ✓
// comment.add        ✓      ✓       ✓       ✓
```

## Cheat Sheet: WebSocket Messages

```dart
// Client → Server
{"type": "auth", "token": "..."}
{"type": "subscribe", "project_id": 1}
{"type": "unsubscribe", "project_id": 1}

// Server → Client
{"type": "auth_success", "user_id": 1}
{"type": "task_created", "task": {...}}
{"type": "task_updated", "task": {...}, "changes": [...]}
{"type": "task_deleted", "task_id": 1}
{"type": "comment_added", "comment": {...}}
```

## Cheat Sheet: Test-Befehle

```bash
# Register
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123","name":"Test User"}'

# Login
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"password123"}'

# Token speichern
TOKEN="eyJ..."

# Projekte auflisten
curl http://localhost:8080/api/projects \
  -H "Authorization: Bearer $TOKEN"

# Projekt erstellen
curl -X POST http://localhost:8080/api/projects \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"My Project","description":"A test project"}'

# Task erstellen
curl -X POST http://localhost:8080/api/projects/1/tasks \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"First Task","priority":"high"}'

# Task Status ändern
curl -X PATCH http://localhost:8080/api/tasks/1/status \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status":"in_progress"}'
```

## Cheat Sheet: Debugging

```bash
# Server Logs
docker compose logs -f api

# Database Shell
docker compose exec db psql -U postgres -d taskapi

# Alle Tables anzeigen
\dt

# Table Schema
\d users
\d tasks

# Query testen
SELECT * FROM users;
SELECT t.*, u.name as assignee_name
FROM tasks t
LEFT JOIN users u ON t.assignee_id = u.id;

# Redis CLI
docker compose exec redis redis-cli
KEYS *
GET key
```

## Best Practices Checklist

### Code-Qualität
- [ ] Separation of Concerns (Handler → Service → Repository)
- [ ] Keine Business-Logik in Handlern
- [ ] Keine Datenbankzugriffe in Handlern
- [ ] DTOs für Input/Output
- [ ] Aussagekräftige Variablennamen

### Sicherheit
- [ ] Passwörter mit bcrypt hashen
- [ ] JWT mit sicherem Secret
- [ ] Input validieren
- [ ] SQL Injection verhindern (Prepared Statements)
- [ ] Rate Limiting
- [ ] CORS konfiguriert
- [ ] Security Headers

### API Design
- [ ] RESTful Endpoints
- [ ] Konsistente Response-Struktur
- [ ] Korrekte HTTP Status Codes
- [ ] Aussagekräftige Fehlermeldungen
- [ ] Pagination für Listen

### Infrastruktur
- [ ] Docker Compose funktioniert
- [ ] Health Checks implementiert
- [ ] Strukturiertes Logging
- [ ] Environment Variables für Secrets
- [ ] Graceful Shutdown

## Häufige Fehler

### 1. Token nicht im Header
```bash
# Falsch
curl http://localhost:8080/api/projects

# Richtig
curl http://localhost:8080/api/projects \
  -H "Authorization: Bearer $TOKEN"
```

### 2. Content-Type vergessen
```bash
# Falsch
curl -X POST http://localhost:8080/api/auth/login \
  -d '{"email":"..."}'

# Richtig
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"..."}'
```

### 3. Datenbank nicht bereit
```bash
# Warten bis DB healthy
docker compose up -d
docker compose exec db pg_isready -U postgres
```

### 4. Migrations nicht ausgeführt
```bash
# SQL manuell ausführen
docker compose exec db psql -U postgres -d taskapi -f /docker-entrypoint-initdb.d/001_initial.sql
```

## Hilfreiche Links

- [Shelf Documentation](https://pub.dev/packages/shelf)
- [postgres Package](https://pub.dev/packages/postgres)
- [JWT.io](https://jwt.io/) - Token debuggen
- [HTTP Status Codes](https://httpstatuses.com/)
- [REST API Design](https://restfulapi.net/)
