# Übung 5.1: Dart auf dem Server

## Ziel

Erstelle einen einfachen HTTP-Server mit `dart:io`, der verschiedene Endpunkte bereitstellt und mit Requests umgehen kann.

---

## Aufgabe 1: Projekt-Setup (10 min)

Erstelle ein neues Dart-Projekt für deinen Server.

### Schritte:

1. Erstelle ein neues Dart-Projekt:
   ```bash
   dart create -t console simple_server
   cd simple_server
   ```

2. Ersetze den Inhalt von `bin/simple_server.dart` mit einem minimalen Server:
   ```dart
   import 'dart:io';

   Future<void> main() async {
     final server = await HttpServer.bind(
       InternetAddress.loopbackIPv4,
       8080,
     );

     print('Server läuft auf http://localhost:8080');

     await for (final request in server) {
       request.response
         ..write('Hello World')
         ..close();
     }
   }
   ```

3. Starte den Server:
   ```bash
   dart run
   ```

4. Teste mit curl oder Browser:
   ```bash
   curl http://localhost:8080
   ```

---

## Aufgabe 2: Einfaches Routing (20 min)

Erweitere den Server um verschiedene Endpunkte.

### Anforderungen:

Implementiere folgende Routen:

| Route | Methode | Response |
|-------|---------|----------|
| `/` | GET | Willkommensnachricht als Text |
| `/api/info` | GET | JSON mit Server-Infos |
| `/api/time` | GET | JSON mit aktueller Uhrzeit |
| `/api/echo` | POST | Echo des Request-Bodys als JSON |
| Alles andere | * | 404 Not Found |

### Erwartete Responses:

**GET /**
```
Willkommen beim Simple Server!
```

**GET /api/info**
```json
{
  "name": "Simple Server",
  "version": "1.0.0",
  "dart_version": "3.x.x"
}
```

**GET /api/time**
```json
{
  "timestamp": "2024-01-15T14:30:00.000Z",
  "timezone": "Europe/Berlin"
}
```

**POST /api/echo** (mit Body `{"message": "Hallo"}`)
```json
{
  "received": {"message": "Hallo"},
  "timestamp": "2024-01-15T14:30:00.000Z"
}
```

---

## Aufgabe 3: Query-Parameter (15 min)

Füge einen neuen Endpunkt hinzu, der Query-Parameter verarbeitet.

### Anforderungen:

**GET /api/greet**

| Parameter | Pflicht | Default | Beschreibung |
|-----------|---------|---------|--------------|
| `name` | Nein | "Gast" | Name der Person |
| `lang` | Nein | "de" | Sprache (de/en) |

### Erwartete Responses:

**GET /api/greet?name=Max&lang=de**
```json
{
  "greeting": "Hallo, Max!",
  "language": "de"
}
```

**GET /api/greet?name=Max&lang=en**
```json
{
  "greeting": "Hello, Max!",
  "language": "en"
}
```

**GET /api/greet** (ohne Parameter)
```json
{
  "greeting": "Hallo, Gast!",
  "language": "de"
}
```

---

## Aufgabe 4: Request-Logging (10 min)

Implementiere ein einfaches Logging für alle eingehenden Requests.

### Anforderungen:

Bei jedem Request soll folgendes in der Konsole ausgegeben werden:

```
[2024-01-15 14:30:00] GET /api/info - 200 (12ms)
[2024-01-15 14:30:05] POST /api/echo - 200 (5ms)
[2024-01-15 14:30:10] GET /unknown - 404 (1ms)
```

Format: `[Timestamp] Methode Pfad - Statuscode (Dauer)`

### Tipps:

- Speichere die Startzeit vor der Request-Verarbeitung
- Berechne die Dauer nach dem Senden der Response
- Nutze `DateTime.now()` für Timestamps

---

## Aufgabe 5: Graceful Shutdown (5 min)

Implementiere einen sauberen Server-Shutdown.

### Anforderungen:

1. Der Server soll bei SIGINT (Ctrl+C) sauber herunterfahren
2. Vor dem Beenden soll eine Nachricht ausgegeben werden
3. Laufende Requests sollen noch abgeschlossen werden können

### Erwartete Ausgabe:

```
Server läuft auf http://localhost:8080
Drücke Ctrl+C zum Beenden

^C
[Shutdown] Server wird heruntergefahren...
[Shutdown] Auf Wiedersehen!
```

---

## Bonus-Aufgabe: Health Check mit Statistiken

Implementiere einen `/health`-Endpunkt, der Statistiken über den Server liefert.

### Anforderungen:

**GET /health**
```json
{
  "status": "healthy",
  "uptime_seconds": 3600,
  "requests_total": 150,
  "requests_per_minute": 2.5,
  "memory_usage_mb": 45.2
}
```

### Tipps:

- Speichere die Startzeit des Servers
- Zähle alle eingehenden Requests
- Nutze `ProcessInfo.currentRss` für Speicherverbrauch

---

## Testen

Teste deinen Server mit curl:

```bash
# Aufgabe 2
curl http://localhost:8080/
curl http://localhost:8080/api/info
curl http://localhost:8080/api/time
curl -X POST http://localhost:8080/api/echo \
  -H "Content-Type: application/json" \
  -d '{"message": "Test"}'

# Aufgabe 3
curl "http://localhost:8080/api/greet"
curl "http://localhost:8080/api/greet?name=Max"
curl "http://localhost:8080/api/greet?name=Max&lang=en"

# 404 testen
curl http://localhost:8080/nicht-vorhanden

# Bonus
curl http://localhost:8080/health
```

---

## Abgabe-Checkliste

- [ ] Server startet auf Port 8080
- [ ] Alle Routen aus Aufgabe 2 funktionieren
- [ ] Query-Parameter werden korrekt verarbeitet
- [ ] Logging zeigt alle Requests mit Dauer
- [ ] Graceful Shutdown funktioniert
- [ ] (Bonus) Health-Endpunkt mit Statistiken
