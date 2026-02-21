# Einheit 9.4: Deployment & Docker

## Lernziele

- Docker-Container für Dart-Anwendungen erstellen
- Multi-Stage Builds für optimale Images
- Docker Compose für lokale Entwicklung
- Cloud-Deployment (Railway, Fly.io)
- CI/CD Pipeline Grundlagen

---

## Docker Grundlagen

### Warum Docker?

```
"Es funktioniert auf meinem Rechner"
              ↓
        Docker Container
              ↓
"Es funktioniert überall gleich"
```

### Vorteile

| Aspekt | Ohne Docker | Mit Docker |
|--------|-------------|------------|
| Umgebung | "Installiere Dart 3.2, Redis, PostgreSQL..." | `docker compose up` |
| Konsistenz | Unterschiede Dev/Prod | Identische Container |
| Isolation | Konflikte zwischen Projekten | Isolierte Umgebungen |
| Deployment | Manuelle Server-Konfiguration | Container starten |

---

## Dockerfile für Dart

### Einfaches Dockerfile

```dockerfile
# Dockerfile

# Basis-Image mit Dart SDK
FROM dart:stable AS build

# Arbeitsverzeichnis
WORKDIR /app

# Dependencies zuerst (Cache-Optimierung)
COPY pubspec.* ./
RUN dart pub get

# Quellcode kopieren
COPY . .

# Kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# Runtime-Image (minimal)
FROM scratch

# Kompilierte Binary kopieren
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# Port freigeben
EXPOSE 8080

# Startbefehl
CMD ["/app/bin/server"]
```

### Multi-Stage Build erklärt

```
┌─────────────────────────────────────────┐
│ Stage 1: build (dart:stable ~800MB)     │
│ ├── dart pub get                        │
│ ├── dart compile exe                    │
│ └── Ergebnis: /app/bin/server           │
└─────────────────────────────────────────┘
                    │
                    ▼ Nur Binary kopieren
┌─────────────────────────────────────────┐
│ Stage 2: runtime (scratch ~0MB)         │
│ ├── /app/bin/server                     │
│ └── Finale Größe: ~10-20MB              │
└─────────────────────────────────────────┘
```

### Optimiertes Dockerfile

```dockerfile
# Dockerfile.optimized

# ===== BUILD STAGE =====
FROM dart:stable AS build

WORKDIR /app

# Dependencies cachen
COPY pubspec.* ./
RUN dart pub get --no-precompile

# Code kopieren und kompilieren
COPY . .
RUN dart pub get --offline
RUN dart compile exe bin/server.dart -o bin/server

# ===== RUNTIME STAGE =====
FROM debian:bookworm-slim AS runtime

# Nur notwendige Runtime-Dateien
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Non-root User
RUN useradd -r -u 1001 appuser
USER appuser

WORKDIR /app

# Binary kopieren
COPY --from=build /app/bin/server /app/bin/server

# Environment
ENV PORT=8080
EXPOSE 8080

# Health Check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
    CMD curl -f http://localhost:8080/health || exit 1

# Startbefehl
ENTRYPOINT ["/app/bin/server"]
```

### .dockerignore

```dockerignore
# .dockerignore

# Dart/Pub
.dart_tool/
.packages
pubspec.lock
build/

# IDE
.idea/
.vscode/
*.iml

# Git
.git/
.gitignore

# Docs
*.md
LICENSE

# Tests
test/
coverage/

# Local files
.env
.env.local
docker-compose.override.yml
```

---

## Docker Compose

### Lokale Entwicklungsumgebung

```yaml
# docker-compose.yml

services:
  # Dart API Server
  api:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - DATABASE_URL=postgres://postgres:postgres@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=dev-secret-change-in-prod
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    volumes:
      # Hot-reload für Entwicklung (optional)
      - .:/app:delegated
    restart: unless-stopped

  # PostgreSQL Datenbank
  db:
    image: postgres:15-alpine
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: myapp
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # Adminer (DB UI)
  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - db

volumes:
  postgres_data:
  redis_data:
```

### Compose-Befehle

```bash
# Starten
docker compose up -d

# Logs anzeigen
docker compose logs -f api

# Stoppen
docker compose down

# Mit Volumes löschen
docker compose down -v

# Neu bauen
docker compose build --no-cache

# In Container ausführen
docker compose exec api dart run bin/migrate.dart
```

### Entwicklung vs. Produktion

```yaml
# docker-compose.override.yml (automatisch geladen)

services:
  api:
    build:
      target: build  # Verwende Build-Stage für Dev
    command: dart run bin/server.dart
    volumes:
      - .:/app
    environment:
      - LOG_LEVEL=debug
```

```yaml
# docker-compose.prod.yml

services:
  api:
    image: myapp/api:${VERSION:-latest}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
    environment:
      - LOG_LEVEL=info
      - LOG_FORMAT=json
```

```bash
# Produktion starten
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

---

## Cloud Deployment

### Railway

Railway ist eine einfache PaaS für Container-Deployment.

```yaml
# railway.toml

[build]
builder = "dockerfile"
dockerfilePath = "Dockerfile"

[deploy]
healthcheckPath = "/health"
healthcheckTimeout = 100
restartPolicyType = "ON_FAILURE"
restartPolicyMaxRetries = 3

[[services]]
name = "api"
```

```bash
# Railway CLI installieren
npm install -g @railway/cli

# Login
railway login

# Projekt erstellen
railway init

# Deployen
railway up

# Umgebungsvariablen setzen
railway variables set JWT_SECRET=my-secret
railway variables set DATABASE_URL=${{Postgres.DATABASE_URL}}
```

### Fly.io

Fly.io deployed Container weltweit.

```toml
# fly.toml

app = "my-dart-api"
primary_region = "fra"  # Frankfurt

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"
  LOG_FORMAT = "json"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.tcp_checks]]
    grace_period = "5s"
    interval = "15s"
    timeout = "2s"
```

```bash
# Fly CLI installieren
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# App erstellen
fly launch

# Secrets setzen
fly secrets set JWT_SECRET=my-secret
fly secrets set DATABASE_URL=postgres://...

# Deployen
fly deploy

# Logs anzeigen
fly logs

# Skalieren
fly scale count 3
```

### Datenbank-Provisioning

```bash
# Fly.io - PostgreSQL
fly postgres create
fly postgres attach my-dart-api

# Railway - PostgreSQL hinzufügen
# (Im Web UI: New → Database → PostgreSQL)
```

---

## CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/deploy.yml

name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Analyze
        run: dart analyze

      - name: Test
        run: dart test

  build:
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch
            type=semver,pattern={{version}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Fly.io
        uses: superfly/flyctl-actions/setup-flyctl@master

      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

### GitLab CI

```yaml
# .gitlab-ci.yml

stages:
  - test
  - build
  - deploy

variables:
  DOCKER_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

test:
  stage: test
  image: dart:stable
  script:
    - dart pub get
    - dart analyze
    - dart test

build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $DOCKER_IMAGE .
    - docker push $DOCKER_IMAGE
  only:
    - main

deploy:
  stage: deploy
  image: alpine:latest
  script:
    - apk add --no-cache curl
    - curl -L https://fly.io/install.sh | sh
    - flyctl deploy --image $DOCKER_IMAGE
  environment:
    name: production
  only:
    - main
```

---

## Best Practices

### Security

```dockerfile
# Non-root User
RUN useradd -r -u 1001 appuser
USER appuser

# Keine Secrets im Image
# Stattdessen: Environment Variables

# Minimales Base Image
FROM debian:bookworm-slim
# oder: FROM distroless/base
```

### Secrets Management

```bash
# NIE im Dockerfile oder docker-compose.yml:
ENV JWT_SECRET=my-super-secret  # ❌

# Stattdessen:
# 1. .env Datei (nicht committen!)
# 2. Docker Secrets
# 3. Cloud Provider Secrets (Railway, Fly.io)
```

```yaml
# docker-compose.yml
services:
  api:
    env_file:
      - .env  # Gitignored!
    secrets:
      - jwt_secret

secrets:
  jwt_secret:
    file: ./secrets/jwt_secret.txt
```

### Logging

```dockerfile
# Logs nach stdout/stderr (nicht in Dateien)
# Docker/Kubernetes sammeln diese automatisch

# In Dart:
// Nicht: File('app.log').writeAsStringSync(...)
// Sondern: print(...) oder stdout.writeln(...)
```

### Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1
```

---

## Zusammenfassung

- **Docker** für konsistente Umgebungen
- **Multi-Stage Builds** für kleine Images
- **Docker Compose** für lokale Entwicklung
- **Railway/Fly.io** für einfaches Cloud-Deployment
- **CI/CD** für automatisierte Deployments

### Deployment-Checkliste

```markdown
## Pre-Deployment

- [ ] Tests grün
- [ ] Dockerfile optimiert
- [ ] .dockerignore vorhanden
- [ ] Health Checks implementiert
- [ ] Environment Variables dokumentiert
- [ ] Secrets sicher gespeichert

## Deployment

- [ ] Container baut erfolgreich
- [ ] Health Check erfolgreich
- [ ] Logs verfügbar
- [ ] Metriken verfügbar
- [ ] Rollback-Plan vorhanden

## Post-Deployment

- [ ] Smoke Tests durchgeführt
- [ ] Monitoring prüfen
- [ ] Alerting aktiv
```
