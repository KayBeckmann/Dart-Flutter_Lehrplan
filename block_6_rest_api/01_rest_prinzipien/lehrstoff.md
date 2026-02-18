# Einheit 6.1: REST-Prinzipien & API-Design

## Lernziele

Nach dieser Einheit kannst du:
- Die REST-Architektur und ihre Prinzipien verstehen
- HTTP-Methoden korrekt einsetzen
- Ressourcen sinnvoll benennen
- API-Versionierung implementieren

---

## Was ist REST?

**REST** (Representational State Transfer) ist ein Architekturstil für verteilte Systeme. Eine REST-konforme API wird als **RESTful API** bezeichnet.

### Die 6 REST-Prinzipien

1. **Client-Server**: Klare Trennung zwischen Client und Server
2. **Stateless**: Jeder Request enthält alle nötigen Informationen
3. **Cacheable**: Responses können gecacht werden
4. **Uniform Interface**: Einheitliche Schnittstelle
5. **Layered System**: Schichten zwischen Client und Server möglich
6. **Code on Demand** (optional): Server kann Code zum Client senden

---

## Ressourcen und URIs

In REST dreht sich alles um **Ressourcen**. Eine Ressource ist ein Objekt oder eine Sammlung von Objekten.

### Ressourcen-Naming Best Practices

```
# RICHTIG: Nomen, Plural, lowercase
GET /api/users
GET /api/products
GET /api/orders

# FALSCH: Verben, Singular, CamelCase
GET /api/getUsers
GET /api/User
GET /api/fetchProducts
```

### Hierarchische Ressourcen

```
# Benutzer
GET /api/users              # Alle Benutzer
GET /api/users/123          # Benutzer mit ID 123

# Bestellungen eines Benutzers
GET /api/users/123/orders   # Alle Bestellungen von User 123
GET /api/users/123/orders/456  # Bestellung 456 von User 123

# Produkte in einer Kategorie
GET /api/categories/electronics/products
```

### Konsistente Namenskonventionen

| Konvention | Beispiel | Empfehlung |
|------------|----------|------------|
| kebab-case | `/user-profiles` | Empfohlen |
| snake_case | `/user_profiles` | Akzeptabel |
| camelCase | `/userProfiles` | Vermeiden |

---

## HTTP-Methoden

### CRUD-Operationen

| Operation | HTTP-Methode | Beispiel | Beschreibung |
|-----------|--------------|----------|--------------|
| Create | POST | `POST /users` | Neuen User erstellen |
| Read | GET | `GET /users/123` | User abrufen |
| Update (komplett) | PUT | `PUT /users/123` | User komplett ersetzen |
| Update (teilweise) | PATCH | `PATCH /users/123` | User teilweise ändern |
| Delete | DELETE | `DELETE /users/123` | User löschen |

### Methoden-Eigenschaften

| Methode | Safe | Idempotent | Request Body |
|---------|------|------------|--------------|
| GET | Ja | Ja | Nein |
| POST | Nein | Nein | Ja |
| PUT | Nein | Ja | Ja |
| PATCH | Nein | Nein | Ja |
| DELETE | Nein | Ja | Nein |

- **Safe**: Verändert keine Daten auf dem Server
- **Idempotent**: Mehrfaches Ausführen hat denselben Effekt wie einmaliges

### PUT vs. PATCH

```dart
// PUT: Komplettes Ersetzen
// Alle Felder müssen gesendet werden
PUT /api/users/123
{
  "name": "Max Mustermann",
  "email": "max@example.com",
  "age": 30,
  "city": "Berlin"
}

// PATCH: Teilweises Update
// Nur geänderte Felder senden
PATCH /api/users/123
{
  "city": "München"
}
```

---

## HTTP-Statuscodes

### 2xx - Erfolg

| Code | Name | Verwendung |
|------|------|------------|
| 200 | OK | Erfolgreiche GET, PUT, PATCH, DELETE |
| 201 | Created | Ressource erfolgreich erstellt (POST) |
| 204 | No Content | Erfolg ohne Response-Body |

### 4xx - Client-Fehler

| Code | Name | Verwendung |
|------|------|------------|
| 400 | Bad Request | Ungültige Anfrage (Validierungsfehler) |
| 401 | Unauthorized | Authentifizierung erforderlich |
| 403 | Forbidden | Keine Berechtigung |
| 404 | Not Found | Ressource nicht gefunden |
| 409 | Conflict | Konflikt (z.B. Duplikat) |
| 422 | Unprocessable Entity | Semantisch ungültig |

### 5xx - Server-Fehler

| Code | Name | Verwendung |
|------|------|------------|
| 500 | Internal Server Error | Unerwarteter Serverfehler |
| 502 | Bad Gateway | Upstream-Server-Fehler |
| 503 | Service Unavailable | Server überlastet/Wartung |

---

## Request/Response-Format

### JSON als Standard

```dart
// Request
POST /api/users
Content-Type: application/json

{
  "name": "Max Mustermann",
  "email": "max@example.com"
}

// Response
HTTP/1.1 201 Created
Content-Type: application/json
Location: /api/users/123

{
  "id": "123",
  "name": "Max Mustermann",
  "email": "max@example.com",
  "createdAt": "2024-01-15T10:30:00Z"
}
```

### Konsistente Response-Struktur

```dart
// Einzelne Ressource
{
  "id": "123",
  "name": "Max",
  "email": "max@example.com"
}

// Liste von Ressourcen
{
  "data": [
    {"id": "1", "name": "Max"},
    {"id": "2", "name": "Anna"}
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "perPage": 10
  }
}

// Fehler
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {"field": "email", "message": "Invalid email format"}
    ]
  }
}
```

---

## API-Versionierung

APIs entwickeln sich weiter. Versionierung ermöglicht Breaking Changes ohne bestehende Clients zu brechen.

### Strategien

#### 1. URL-Pfad (empfohlen)

```
GET /api/v1/users
GET /api/v2/users
```

```dart
final app = Router();
app.mount('/api/v1', v1Router().call);
app.mount('/api/v2', v2Router().call);
```

#### 2. Query-Parameter

```
GET /api/users?version=1
GET /api/users?version=2
```

#### 3. Header

```
GET /api/users
Accept: application/vnd.myapi.v1+json
```

### Versionierung in Dart

```dart
Router v1Router() {
  final router = Router();
  router.get('/users', (Request r) => Response.ok('v1 users'));
  return router;
}

Router v2Router() {
  final router = Router();
  router.get('/users', (Request r) => Response.ok('v2 users with pagination'));
  return router;
}

void main() async {
  final app = Router();

  // Beide Versionen verfügbar
  app.mount('/api/v1', v1Router().call);
  app.mount('/api/v2', v2Router().call);

  // Default auf neueste Version
  app.mount('/api', v2Router().call);

  await shelf_io.serve(app.call, 'localhost', 8080);
}
```

---

## HATEOAS (Hypermedia)

**HATEOAS** (Hypermedia as the Engine of Application State) bedeutet, dass Responses Links zu verwandten Ressourcen enthalten.

```dart
// Response mit HATEOAS
{
  "id": "123",
  "name": "Max",
  "email": "max@example.com",
  "_links": {
    "self": {"href": "/api/users/123"},
    "orders": {"href": "/api/users/123/orders"},
    "profile": {"href": "/api/users/123/profile"}
  }
}

// Collection mit Links
{
  "data": [...],
  "_links": {
    "self": {"href": "/api/users?page=2"},
    "first": {"href": "/api/users?page=1"},
    "prev": {"href": "/api/users?page=1"},
    "next": {"href": "/api/users?page=3"},
    "last": {"href": "/api/users?page=10"}
  }
}
```

---

## Best Practices

### 1. Konsistente Benennung

```dart
// GUT
/api/users
/api/user-profiles
/api/order-items

// SCHLECHT
/api/Users
/api/userProfile
/api/order_items
```

### 2. Keine Verben in URLs

```dart
// GUT: HTTP-Methode drückt Aktion aus
POST /api/users           # User erstellen
DELETE /api/users/123     # User löschen

// SCHLECHT: Verben in URL
POST /api/createUser
GET /api/deleteUser/123
```

### 3. Filter über Query-Parameter

```dart
// GUT
GET /api/users?status=active&role=admin

// SCHLECHT
GET /api/users/active/admin
GET /api/activeAdminUsers
```

### 4. HTTP-Statuscodes korrekt verwenden

```dart
// GUT
POST /api/users -> 201 Created
GET /api/users/999 -> 404 Not Found
DELETE /api/users/123 -> 204 No Content

// SCHLECHT
POST /api/users -> 200 OK (sollte 201 sein)
GET /api/users/999 -> 200 OK mit {"error": "not found"}
```

---

## Zusammenfassung

| Prinzip | Umsetzung |
|---------|-----------|
| Ressourcen | Nomen, Plural, lowercase |
| Aktionen | HTTP-Methoden (GET, POST, PUT, PATCH, DELETE) |
| Statuscodes | 2xx Erfolg, 4xx Client-Fehler, 5xx Server-Fehler |
| Format | JSON mit konsistenter Struktur |
| Versionierung | URL-Pfad (`/api/v1/...`) |

---

## Nächste Schritte

In der nächsten Einheit lernst du **JSON-Serialisierung** in Dart: Wie du Objekte in JSON umwandelst und umgekehrt.
