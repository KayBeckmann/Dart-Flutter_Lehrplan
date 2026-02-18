# Übung 5.4: Middleware

## Ziel

Implementiere verschiedene Middleware-Komponenten für einen REST API Server: Logging, CORS, Authentication und Error Handling.

---

## Aufgabe 1: Logging Middleware (15 min)

Erstelle eine Logging-Middleware, die alle Requests protokolliert.

### Anforderungen

Die Middleware soll für jeden Request folgendes ausgeben:

```
[2024-01-15 14:30:00] GET    /api/users     200  12ms
[2024-01-15 14:30:05] POST   /api/users     201   8ms
[2024-01-15 14:30:10] GET    /api/unknown   404   2ms
```

Format: `[Timestamp] Methode Pfad Status Dauer`

### Bonus-Anforderungen

- Methode auf 6 Zeichen padden
- Pfad auf 20 Zeichen padden (oder kürzen mit `...`)
- Farbige Ausgabe: Grün für 2xx, Gelb für 4xx, Rot für 5xx

```dart
Middleware requestLogger();
```

---

## Aufgabe 2: CORS Middleware (15 min)

Erstelle eine konfigurierbare CORS-Middleware.

### Anforderungen

```dart
Middleware corsMiddleware({
  String origin = '*',
  List<String> methods = const ['GET', 'POST', 'PUT', 'DELETE'],
  List<String> allowedHeaders = const ['Content-Type', 'Authorization'],
  int maxAge = 86400,
});
```

Die Middleware soll:

1. Bei OPTIONS-Requests (Preflight) direkt mit 200 antworten
2. CORS-Headers an alle Responses anhängen:
   - `Access-Control-Allow-Origin`
   - `Access-Control-Allow-Methods`
   - `Access-Control-Allow-Headers`
   - `Access-Control-Max-Age`

### Test

```bash
# Preflight-Request
curl -X OPTIONS http://localhost:8080/api/test \
  -H "Origin: http://example.com" \
  -H "Access-Control-Request-Method: POST"

# Normaler Request
curl http://localhost:8080/api/test -v
# Prüfe Response-Headers
```

---

## Aufgabe 3: Rate Limiting Middleware (15 min)

Erstelle eine Rate-Limiting-Middleware, die zu viele Requests ablehnt.

### Anforderungen

```dart
Middleware rateLimiter({
  int maxRequests = 100,
  Duration window = const Duration(minutes: 1),
});
```

Die Middleware soll:

1. Requests pro IP-Adresse zählen
2. Bei Überschreitung des Limits: 429 Too Many Requests
3. Header hinzufügen:
   - `X-RateLimit-Limit`: Max. Requests
   - `X-RateLimit-Remaining`: Verbleibende Requests
   - `X-RateLimit-Reset`: Unix-Timestamp wann Reset

### Beispiel-Response bei Limit erreicht

```json
{
  "error": "Too Many Requests",
  "message": "Rate limit exceeded. Try again later.",
  "retryAfter": 45
}
```

### Hinweis

Verwende eine Map zur Speicherung:

```dart
final _requests = <String, List<DateTime>>{};
```

---

## Aufgabe 4: Authentication Middleware (15 min)

Erstelle eine JWT-ähnliche Authentication-Middleware.

### Anforderungen

```dart
Middleware authMiddleware({
  required String secret,
  List<String> publicPaths = const ['/health', '/api/auth/login'],
});
```

Die Middleware soll:

1. Public Paths ohne Authentifizierung durchlassen
2. `Authorization: Bearer <token>` Header prüfen
3. Token validieren (vereinfacht: `base64(userId:secret)` Format)
4. Bei gültigem Token: User-ID in Context speichern
5. Bei ungültigem Token: 401 Unauthorized

### Token-Format (vereinfacht)

```dart
// Token generieren
final token = base64Encode(utf8.encode('user123:$secret'));

// Token validieren
final decoded = utf8.decode(base64Decode(token));
final parts = decoded.split(':');
if (parts[1] == secret) {
  return parts[0]; // userId
}
```

### Test

```bash
# Ohne Token
curl http://localhost:8080/api/users
# 401 Unauthorized

# Mit Token
TOKEN=$(echo -n "user123:mysecret" | base64)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/users
# 200 OK

# Public Path
curl http://localhost:8080/health
# 200 OK (ohne Token)
```

---

## Aufgabe 5: Error Handler Middleware (10 min)

Erstelle eine Error-Handling-Middleware.

### Anforderungen

```dart
Middleware errorHandler();
```

Die Middleware soll:

1. Alle Exceptions abfangen
2. Verschiedene Exception-Typen unterschiedlich behandeln:
   - `NotFoundException` → 404
   - `ValidationException` → 400
   - `UnauthorizedException` → 401
   - `ForbiddenException` → 403
   - Alle anderen → 500
3. JSON-Error-Response zurückgeben
4. Bei 500: Fehler loggen (aber nicht an Client senden)

### Custom Exceptions

```dart
class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends ApiException {
  ValidationException(String message) : super(message, 400);
}
```

### Error-Response Format

```json
{
  "error": "Not Found",
  "message": "User with ID 42 not found",
  "statusCode": 404
}
```

---

## Aufgabe 6: Alles zusammenbauen (10 min)

Kombiniere alle Middleware-Komponenten in einer Pipeline.

### Anforderungen

```dart
final handler = Pipeline()
    .addMiddleware(errorHandler())
    .addMiddleware(requestLogger())
    .addMiddleware(corsMiddleware())
    .addMiddleware(rateLimiter(maxRequests: 10, window: Duration(seconds: 30)))
    .addMiddleware(authMiddleware(secret: 'mysecret'))
    .addHandler(router);
```

Erstelle einen einfachen Router mit Test-Endpunkten:

- `GET /health` - Health Check (public)
- `GET /api/users` - User-Liste (auth required)
- `GET /api/error` - Wirft Exception zum Testen

---

## Testen

```bash
# Server starten
dart run bin/server.dart

# Health (public)
curl http://localhost:8080/health

# Ohne Auth (401)
curl http://localhost:8080/api/users

# Mit Auth
TOKEN=$(echo -n "user123:mysecret" | base64)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/users

# CORS Preflight
curl -X OPTIONS http://localhost:8080/api/users -v

# Rate Limit testen (schnell viele Requests)
for i in {1..15}; do curl http://localhost:8080/health; done

# Error testen
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/error
```

---

## Abgabe-Checkliste

- [ ] Logging-Middleware zeigt alle Requests
- [ ] CORS-Middleware setzt korrekte Header
- [ ] Rate-Limiter blockiert bei zu vielen Requests
- [ ] Auth-Middleware validiert Tokens korrekt
- [ ] Error-Handler fängt Exceptions ab
- [ ] Pipeline ist korrekt aufgebaut
