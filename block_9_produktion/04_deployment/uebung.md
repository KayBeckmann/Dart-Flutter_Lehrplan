# Übung 9.4: Deployment & Docker

## Ziel

Erstelle ein produktionsreifes Docker-Setup für eine Dart API.

---

## Aufgabe 1: Einfaches Dockerfile (15 min)

Erstelle ein Dockerfile für eine Dart-Anwendung.

```dockerfile
# Dockerfile

# TODO: Dart Base Image verwenden
FROM ???

# TODO: Arbeitsverzeichnis setzen
WORKDIR ???

# TODO: pubspec.yaml und pubspec.lock kopieren
COPY ???

# TODO: Dependencies installieren
RUN ???

# TODO: Restlichen Code kopieren
COPY ???

# TODO: Anwendung kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# TODO: Port freigeben
EXPOSE ???

# TODO: Startbefehl
CMD ???
```

**Test:**
```bash
docker build -t my-api .
docker run -p 8080:8080 my-api
curl http://localhost:8080/health
```

---

## Aufgabe 2: Multi-Stage Build (20 min)

Optimiere das Dockerfile mit Multi-Stage Build.

```dockerfile
# Dockerfile.optimized

# ===== BUILD STAGE =====
FROM dart:stable AS build

WORKDIR /app

# Dependencies cachen (Layer-Optimierung)
COPY pubspec.* ./
RUN dart pub get

# Code kopieren
COPY . .

# Kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# ===== RUNTIME STAGE =====
# TODO: Minimales Base Image wählen
FROM ???

# TODO: CA-Zertifikate für HTTPS installieren (falls debian-slim)
RUN ???

# TODO: Non-root User erstellen
RUN ???
USER ???

WORKDIR /app

# TODO: Nur die kompilierte Binary kopieren
COPY --from=build ???

# TODO: Environment Variable für Port
ENV ???

# TODO: Port freigeben
EXPOSE ???

# TODO: Health Check hinzufügen
HEALTHCHECK ???

# TODO: Startbefehl
ENTRYPOINT ???
```

**Test:**
```bash
# Image-Größe vergleichen
docker build -t my-api:simple -f Dockerfile .
docker build -t my-api:optimized -f Dockerfile.optimized .
docker images | grep my-api
```

---

## Aufgabe 3: .dockerignore (10 min)

Erstelle eine .dockerignore Datei.

```dockerignore
# .dockerignore

# TODO: Dart-spezifische Dateien/Ordner ausschließen
# (.dart_tool, .packages, build, etc.)

# TODO: IDE-Dateien ausschließen
# (.idea, .vscode, etc.)

# TODO: Git-Dateien ausschließen

# TODO: Test-Dateien ausschließen

# TODO: Dokumentation ausschließen

# TODO: Lokale Konfiguration ausschließen
# (.env, docker-compose.override.yml, etc.)
```

---

## Aufgabe 4: Docker Compose Setup (25 min)

Erstelle ein docker-compose.yml für die komplette Entwicklungsumgebung.

```yaml
# docker-compose.yml

services:
  # TODO: API Service
  api:
    build:
      context: .
      dockerfile: Dockerfile.optimized
    ports:
      # TODO: Port-Mapping
    environment:
      # TODO: Environment Variables
      # PORT, DATABASE_URL, REDIS_URL, JWT_SECRET
    depends_on:
      # TODO: Abhängigkeiten mit health condition
    restart: unless-stopped

  # TODO: PostgreSQL Service
  db:
    image: postgres:15-alpine
    ports:
      # TODO: Port-Mapping
    environment:
      # TODO: Postgres Environment
    volumes:
      # TODO: Daten-Volume
      # TODO: Init-Script mounten
    healthcheck:
      # TODO: pg_isready Check

  # TODO: Redis Service
  redis:
    image: redis:7-alpine
    ports:
      # TODO: Port-Mapping
    volumes:
      # TODO: Daten-Volume

  # Optional: Adminer für DB-Management
  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - db

# TODO: Volumes definieren
volumes:
  ???
```

**Test:**
```bash
docker compose up -d
docker compose ps
docker compose logs api
curl http://localhost:8080/health
```

---

## Aufgabe 5: Init-Script für Datenbank (10 min)

Erstelle ein SQL-Script für die Datenbank-Initialisierung.

```sql
-- init.sql

-- TODO: Datenbank erstellen (falls nicht existiert)
-- CREATE DATABASE IF NOT EXISTS ...

-- TODO: Users-Tabelle erstellen
CREATE TABLE IF NOT EXISTS users (
    -- TODO: Spalten definieren
);

-- TODO: Weitere Tabellen erstellen

-- TODO: Test-Daten einfügen (optional, nur für Entwicklung)
INSERT INTO users (email, password_hash, name)
VALUES ('admin@example.com', '$2a$12$...', 'Admin')
ON CONFLICT DO NOTHING;
```

---

## Aufgabe 6: Environment-Konfiguration (15 min)

Erstelle Konfigurationsdateien für verschiedene Umgebungen.

```bash
# .env.example (committen, als Vorlage)

PORT=8080
LOG_LEVEL=info
LOG_FORMAT=json

# Database
DATABASE_URL=postgres://user:pass@host:5432/db
DATABASE_POOL_SIZE=10

# Redis
REDIS_URL=redis://host:6379

# Auth
JWT_SECRET=change-me-in-production
JWT_ACCESS_TOKEN_DURATION=15m
JWT_REFRESH_TOKEN_DURATION=7d

# External Services
SMTP_HOST=
SMTP_PORT=
SMTP_USER=
SMTP_PASS=
```

```bash
# .env (NICHT committen!)
# Kopiere .env.example und passe an

PORT=8080
DATABASE_URL=postgres://postgres:postgres@db:5432/myapp
REDIS_URL=redis://redis:6379
JWT_SECRET=dev-secret-for-local-development
```

```yaml
# docker-compose.override.yml (für lokale Entwicklung)

services:
  api:
    # TODO: Entwicklungs-spezifische Konfiguration
    # - Source Code mounten für Hot-Reload
    # - Debug Log Level
    # - Build Target auf 'build' Stage setzen
```

---

## Aufgabe 7: Fly.io Deployment (20 min)

Konfiguriere Deployment auf Fly.io.

```toml
# fly.toml

# TODO: App-Name
app = "???"

# TODO: Region
primary_region = "???"

[build]
  # TODO: Dockerfile referenzieren

[env]
  # TODO: Nicht-sensitive Environment Variables

[http_service]
  # TODO: Port konfigurieren
  # TODO: HTTPS erzwingen
  # TODO: Auto-Scaling

[[services]]
  # TODO: TCP Service konfigurieren

  [[services.ports]]
    # TODO: HTTP Port

  [[services.ports]]
    # TODO: HTTPS Port

  [[services.http_checks]]
    # TODO: Health Check konfigurieren
```

```bash
# Deployment-Schritte dokumentieren

# 1. Fly CLI installieren
# TODO: Befehl

# 2. Login
# TODO: Befehl

# 3. App erstellen
# TODO: Befehl

# 4. PostgreSQL erstellen und verbinden
# TODO: Befehle

# 5. Secrets setzen
# TODO: Befehle

# 6. Deployen
# TODO: Befehl

# 7. Logs prüfen
# TODO: Befehl
```

---

## Aufgabe 8: GitHub Actions CI/CD (20 min)

Erstelle eine GitHub Actions Pipeline.

```yaml
# .github/workflows/ci.yml

name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  # TODO: Test Job
  test:
    runs-on: ubuntu-latest
    steps:
      # TODO: Checkout
      # TODO: Dart Setup
      # TODO: Dependencies installieren
      # TODO: Analyze
      # TODO: Tests

  # TODO: Build Job
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      # TODO: Checkout
      # TODO: Docker Login (zu GitHub Container Registry)
      # TODO: Docker Build & Push

  # TODO: Deploy Job (nur auf main)
  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      # TODO: Checkout
      # TODO: Fly CLI Setup
      # TODO: Deploy
```

---

## Bonus: Makefile (Optional)

```makefile
# Makefile

.PHONY: dev build test deploy

# Lokale Entwicklung starten
dev:
	docker compose up -d
	docker compose logs -f api

# Image bauen
build:
	docker build -t my-api:latest -f Dockerfile.optimized .

# Tests ausführen
test:
	dart test

# Linting
lint:
	dart analyze

# Deployment
deploy:
	flyctl deploy

# Cleanup
clean:
	docker compose down -v
	docker system prune -f
```

---

## Testen

### Lokale Entwicklung

```bash
# Compose starten
docker compose up -d

# Status prüfen
docker compose ps

# API testen
curl http://localhost:8080/health
curl http://localhost:8080/api/hello

# Logs
docker compose logs -f api

# In Container shell
docker compose exec api sh

# Stoppen
docker compose down
```

### Image-Optimierung prüfen

```bash
# Größen vergleichen
docker images | grep my-api

# Layer inspizieren
docker history my-api:optimized

# Security Scan (optional)
docker scout cves my-api:optimized
```

---

## Abgabe-Checkliste

- [ ] Einfaches Dockerfile funktioniert
- [ ] Multi-Stage Dockerfile mit kleinem Image
- [ ] .dockerignore vorhanden
- [ ] Docker Compose mit API, DB, Redis
- [ ] Volumes für Persistenz
- [ ] Health Checks konfiguriert
- [ ] Init-Script für Datenbank
- [ ] Environment-Konfiguration (.env.example)
- [ ] fly.toml für Cloud-Deployment
- [ ] GitHub Actions Pipeline
- [ ] README mit Deployment-Anleitung
