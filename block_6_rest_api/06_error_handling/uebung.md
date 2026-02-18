# Übung 6.6: Error Handling & HTTP-Statuscodes

## Ziel

Implementiere ein robustes Error Handling System für eine REST-API.

---

## Aufgabe 1: Exception-Klassen (15 min)

Erstelle eine Hierarchie von API-Exceptions.

### Basis-Klasse

```dart
abstract class ApiException implements Exception {
  int get statusCode;
  String get code;
  String get message;
  Map<String, dynamic>? get details => null;

  Response toResponse({String? traceId});
}
```

### Zu implementierende Exceptions

| Exception | Status | Code | Beispiel |
|-----------|--------|------|----------|
| `NotFoundException` | 404 | NOT_FOUND | User nicht gefunden |
| `BadRequestException` | 400 | BAD_REQUEST | Ungültige Anfrage |
| `ValidationException` | 400 | VALIDATION_ERROR | Felder ungültig |
| `UnauthorizedException` | 401 | UNAUTHORIZED | Nicht eingeloggt |
| `ForbiddenException` | 403 | FORBIDDEN | Keine Berechtigung |
| `ConflictException` | 409 | CONFLICT | Email existiert |

### Beispiel-Verwendung

```dart
throw NotFoundException('User', '123');
// → {"error": {"code": "NOT_FOUND", "message": "User with ID '123' not found"}}

throw ConflictException('A user with this email already exists');
// → {"error": {"code": "CONFLICT", "message": "A user with this email already exists"}}
```

---

## Aufgabe 2: Error Handler Middleware (15 min)

Erstelle eine Middleware, die alle Exceptions abfängt.

### Anforderungen

1. `ApiException` → entsprechender Statuscode
2. `FormatException` → 400 Bad Request
3. Andere Exceptions → 500 Internal Server Error
4. Trace-ID für jede Fehler-Response generieren
5. Alle Fehler loggen

### Template

```dart
Middleware errorHandler({bool isDevelopment = false}) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        // TODO: Bekannte API-Fehler behandeln
      } on FormatException catch (e) {
        // TODO: JSON-Parsing-Fehler behandeln
      } catch (e, stackTrace) {
        // TODO: Unbekannte Fehler behandeln
        // In Development: Stack Trace einschließen
        // In Production: Nur generische Meldung
      }
    };
  };
}
```

---

## Aufgabe 3: Fehler-Response Helpers (10 min)

Erstelle Helper-Funktionen für häufige Fehler.

### Zu implementieren

```dart
Response notFound(String resource, String id);
Response badRequest(String message);
Response unauthorized({String? message});
Response forbidden({String? message});
Response conflict(String message);
Response validationError(List<ValidationError> errors);
Response internalError({String? traceId});
```

### Erwartete Responses

```json
// notFound('User', '123')
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User with ID '123' not found"
  }
}

// validationError([...])
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Validation failed",
    "details": {
      "fields": [
        {"field": "email", "message": "Invalid email format", "code": "INVALID_EMAIL"}
      ]
    }
  }
}
```

---

## Aufgabe 4: Vollständiger API-Server (20 min)

Baue eine API mit korrektem Error Handling.

### Endpoints

| Methode | Pfad | Beschreibung |
|---------|------|--------------|
| GET | /api/users | Alle User listen |
| GET | /api/users/:id | User abrufen (404 wenn nicht gefunden) |
| POST | /api/users | User erstellen (400 bei Validierung, 409 bei Duplikat) |
| PUT | /api/users/:id | User aktualisieren (404 wenn nicht gefunden) |
| DELETE | /api/users/:id | User löschen (404 wenn nicht gefunden) |

### Validierungsregeln für POST/PUT

- `name`: Pflicht, 2-100 Zeichen
- `email`: Pflicht, gültiges Format, eindeutig
- `age`: Optional, 0-150

### Test-Szenarien

```bash
# 200 OK
curl http://localhost:8080/api/users

# 201 Created
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max", "email": "max@test.de"}'

# 400 Bad Request (Validierung)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "A"}'

# 404 Not Found
curl http://localhost:8080/api/users/not-exists

# 409 Conflict (Duplikat)
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max2", "email": "max@test.de"}'
```

---

## Aufgabe 5: 404 Fallback Handler (5 min)

Erstelle einen Handler für unbekannte Routen.

### Anforderung

Alle Requests, die keiner Route entsprechen, sollen eine JSON-Fehler-Response bekommen.

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Endpoint GET /api/unknown not found"
  }
}
```

### Tipp: Cascade

```dart
final handler = Cascade()
    .add(router.call)
    .add(notFoundHandler())
    .handler;
```

---

## Aufgabe 6: Request Logging mit Fehlern (Bonus, 10 min)

Erweitere das Logging um Fehlerinformationen.

### Format

```
[2024-01-15T10:30:00Z] INFO GET /api/users 200 45ms
[2024-01-15T10:30:01Z] ERROR POST /api/users 400 12ms {"code": "VALIDATION_ERROR"}
[2024-01-15T10:30:02Z] ERROR GET /api/users/999 404 5ms {"code": "NOT_FOUND"}
[2024-01-15T10:30:03Z] ERROR POST /api/users 500 123ms {"code": "INTERNAL_ERROR", "traceId": "abc123"}
```

### Middleware

```dart
Middleware requestLogger() {
  return (Handler handler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      final response = await handler(request);
      stopwatch.stop();

      final level = response.statusCode >= 400 ? 'ERROR' : 'INFO';
      // TODO: Logging implementieren

      return response;
    };
  };
}
```

---

## Testen

```bash
# Erfolgreiche Requests
curl http://localhost:8080/api/users
curl http://localhost:8080/api/users/user-1

# Fehler-Szenarien
curl http://localhost:8080/api/users/not-exists  # 404
curl http://localhost:8080/api/unknown  # 404 (Route nicht gefunden)
curl -X POST http://localhost:8080/api/users -d '{}'  # 400

# Ungültiges JSON
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{invalid}'  # 400

# Mit Response-Headers
curl -i http://localhost:8080/api/users/not-exists
```

---

## Abgabe-Checkliste

- [ ] Alle Exception-Klassen implementiert
- [ ] Error Handler Middleware funktioniert
- [ ] ApiException → korrekter Statuscode
- [ ] FormatException → 400
- [ ] Unbekannte Fehler → 500 (ohne Details in Produktion)
- [ ] Trace-ID wird generiert
- [ ] Fehler werden geloggt
- [ ] 404 Handler für unbekannte Routen
- [ ] API-Endpoints mit korrektem Error Handling
- [ ] (Bonus) Request Logging mit Fehlerinfos
