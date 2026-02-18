# Übung 5.2: Shelf Framework Basics

## Ziel

Erstelle einen HTTP-Server mit dem Shelf-Framework, der verschiedene Endpunkte bereitstellt und Middleware verwendet.

---

## Aufgabe 1: Projekt-Setup (10 min)

### Schritte:

1. Erstelle ein neues Dart-Projekt:
   ```bash
   dart create -t server-shelf shelf_basics
   cd shelf_basics
   ```

2. Überprüfe die `pubspec.yaml`:
   ```yaml
   dependencies:
     shelf: ^1.4.0
     shelf_router: ^1.1.0
   ```

3. Ersetze `bin/server.dart` mit einem minimalen Shelf-Server:
   ```dart
   import 'package:shelf/shelf.dart';
   import 'package:shelf/shelf_io.dart' as shelf_io;

   void main() async {
     Response handler(Request request) {
       return Response.ok('Hello Shelf!');
     }

     final server = await shelf_io.serve(handler, 'localhost', 8080);
     print('Server running on http://${server.address.host}:${server.port}');
   }
   ```

4. Starte und teste:
   ```bash
   dart run bin/server.dart
   curl http://localhost:8080
   ```

---

## Aufgabe 2: Request-Handler (20 min)

Implementiere verschiedene Handler für unterschiedliche Endpunkte.

### Anforderungen:

Erstelle einen Handler, der basierend auf dem Pfad verschiedene Responses zurückgibt:

| Pfad | Methode | Response |
|------|---------|----------|
| `/` | GET | HTML-Willkommensseite |
| `/api/status` | GET | JSON mit Server-Status |
| `/api/headers` | GET | JSON mit allen Request-Headers |
| `/api/echo` | POST | JSON-Echo des Request-Bodys |
| Alles andere | * | 404 Not Found |

### Erwartete Responses:

**GET /**
```html
<!DOCTYPE html>
<html>
<head><title>Shelf Server</title></head>
<body><h1>Willkommen!</h1></body>
</html>
```
(Content-Type: text/html)

**GET /api/status**
```json
{
  "status": "running",
  "version": "1.0.0",
  "timestamp": "2024-01-15T14:30:00.000Z"
}
```

**GET /api/headers**
```json
{
  "headers": {
    "host": "localhost:8080",
    "user-agent": "curl/8.0.0",
    "accept": "*/*"
  }
}
```

**POST /api/echo** (mit Body)
```json
{
  "method": "POST",
  "path": "/api/echo",
  "body": { ... },
  "timestamp": "2024-01-15T14:30:00.000Z"
}
```

---

## Aufgabe 3: JSON-Helper (10 min)

Erstelle eine Hilfsfunktion für JSON-Responses.

### Anforderungen:

```dart
Response jsonResponse(Object? data, {int statusCode = 200});
```

Die Funktion soll:
- Den Body als JSON encodieren
- Den Content-Type auf `application/json; charset=utf-8` setzen
- Den angegebenen Statuscode verwenden

### Verwendungsbeispiel:

```dart
return jsonResponse({'status': 'ok'});
return jsonResponse({'error': 'Not found'}, statusCode: 404);
```

---

## Aufgabe 4: Custom Middleware (15 min)

Implementiere zwei eigene Middleware-Funktionen.

### Middleware 1: Request-Timer

Misst die Verarbeitungszeit jedes Requests und fügt sie als Header hinzu.

```dart
Middleware requestTimer();
```

Der Response soll einen `X-Response-Time`-Header enthalten:
```
X-Response-Time: 5ms
```

### Middleware 2: API-Key-Prüfung

Prüft, ob ein gültiger API-Key im Header vorhanden ist.

```dart
Middleware apiKeyAuth(String validApiKey);
```

- Wenn `X-API-Key` Header fehlt oder falsch: 401 Unauthorized
- Wenn korrekt: Request durchlassen
- Nur für `/api/*` Pfade prüfen, `/` soll ohne Key funktionieren

---

## Aufgabe 5: Pipeline zusammenbauen (5 min)

Kombiniere alles in einer Pipeline.

### Anforderungen:

```dart
final pipeline = Pipeline()
    .addMiddleware(logRequests())      // Eingebaut
    .addMiddleware(requestTimer())      // Aufgabe 4
    .addMiddleware(apiKeyAuth('secret-key-123'))  // Aufgabe 4
    .addHandler(router);                // Aufgabe 2
```

---

## Testen

```bash
# Aufgabe 2: Endpunkte
curl http://localhost:8080/
curl http://localhost:8080/api/status
curl http://localhost:8080/api/headers
curl -X POST http://localhost:8080/api/echo \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# 404
curl http://localhost:8080/unknown

# Aufgabe 4: Ohne API-Key (sollte 401 sein)
curl http://localhost:8080/api/status

# Mit API-Key
curl -H "X-API-Key: secret-key-123" http://localhost:8080/api/status

# Root ohne API-Key (sollte funktionieren)
curl http://localhost:8080/

# Response-Time Header prüfen
curl -v -H "X-API-Key: secret-key-123" http://localhost:8080/api/status
```

---

## Bonus-Aufgabe: Request-Context

Erweitere die API-Key-Middleware, um bei erfolgreicher Authentifizierung Informationen im Request-Context zu speichern.

### Anforderungen:

1. Bei gültigem API-Key: Setze `request.context['authenticated'] = true`
2. Erstelle einen neuen Endpunkt `GET /api/whoami`:
   ```json
   {
     "authenticated": true,
     "api_key_prefix": "secr..."
   }
   ```

---

## Abgabe-Checkliste

- [ ] Server startet auf Port 8080
- [ ] Alle Endpunkte aus Aufgabe 2 funktionieren
- [ ] JSON-Helper-Funktion implementiert
- [ ] Request-Timer-Middleware funktioniert
- [ ] API-Key-Middleware funktioniert
- [ ] Pipeline ist korrekt aufgebaut
- [ ] (Bonus) Request-Context wird genutzt
