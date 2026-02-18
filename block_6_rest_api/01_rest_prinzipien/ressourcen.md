# Ressourcen: REST-Prinzipien & API-Design

## Offizielle Dokumentation & Standards

- [HTTP/1.1 Specification (RFC 7231)](https://tools.ietf.org/html/rfc7231) - HTTP-Methoden
- [HTTP Status Codes (MDN)](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)
- [REST API Tutorial](https://restfulapi.net/) - Umfassende Einführung

## Best Practice Guides

- [Microsoft REST API Guidelines](https://github.com/microsoft/api-guidelines)
- [Google API Design Guide](https://cloud.google.com/apis/design)
- [JSON API Specification](https://jsonapi.org/)

## Cheat Sheet: HTTP-Methoden

| Methode | CRUD | Idempotent | Safe | Body |
|---------|------|------------|------|------|
| GET | Read | Ja | Ja | Nein |
| POST | Create | Nein | Nein | Ja |
| PUT | Replace | Ja | Nein | Ja |
| PATCH | Update | Nein | Nein | Ja |
| DELETE | Delete | Ja | Nein | Nein |

## Cheat Sheet: Statuscodes

```
2xx Erfolg:
  200 OK              - Erfolgreiche Anfrage
  201 Created         - Ressource erstellt
  204 No Content      - Erfolg ohne Body

4xx Client-Fehler:
  400 Bad Request     - Ungültige Anfrage
  401 Unauthorized    - Nicht authentifiziert
  403 Forbidden       - Keine Berechtigung
  404 Not Found       - Nicht gefunden
  409 Conflict        - Konflikt/Duplikat
  422 Unprocessable   - Semantisch ungültig

5xx Server-Fehler:
  500 Internal Error  - Serverfehler
  503 Unavailable     - Service nicht verfügbar
```

## Cheat Sheet: URL-Design

```
# Ressourcen (Nomen, Plural)
GET    /users           # Liste
GET    /users/123       # Einzeln
POST   /users           # Erstellen
PUT    /users/123       # Ersetzen
PATCH  /users/123       # Aktualisieren
DELETE /users/123       # Löschen

# Verschachtelte Ressourcen
GET /users/123/orders
GET /users/123/orders/456

# Filter (Query-Parameter)
GET /users?status=active&sort=name

# Versionierung
GET /api/v1/users
GET /api/v2/users
```

## Cheat Sheet: Response-Struktur

```json
// Einzelne Ressource
{
  "id": "123",
  "name": "Max",
  "email": "max@example.com"
}

// Liste
{
  "data": [...],
  "meta": {
    "total": 100,
    "page": 1,
    "perPage": 10
  }
}

// Fehler
{
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found"
  }
}
```

## Naming Conventions

```
# GUT
/api/users
/api/user-profiles
/api/order-items

# SCHLECHT
/api/getUsers        (Verb)
/api/User            (Singular, CamelCase)
/api/user_profile    (snake_case mit Singular)
```

## Dart: Basis-Router

```dart
Router apiRouter() {
  final router = Router();

  // CRUD für Users
  router.get('/users', listUsers);
  router.get('/users/<id>', getUser);
  router.post('/users', createUser);
  router.put('/users/<id>', replaceUser);
  router.patch('/users/<id>', updateUser);
  router.delete('/users/<id>', deleteUser);

  return router;
}
```

## Tools

- [Postman](https://www.postman.com/) - API Testing
- [Insomnia](https://insomnia.rest/) - REST Client
- [Swagger Editor](https://editor.swagger.io/) - API Design
- [JSON Formatter](https://jsonformatter.org/) - JSON validieren
