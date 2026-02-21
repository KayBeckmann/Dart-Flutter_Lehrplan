# Lösung 9.4: Deployment & Docker

## Aufgabe 1: Einfaches Dockerfile

```dockerfile
# Dockerfile

FROM dart:stable

WORKDIR /app

# Dependencies zuerst (Cache-Optimierung)
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Code kopieren
COPY . .

# Kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# Port
EXPOSE 8080

# Start
CMD ["./bin/server"]
```

---

## Aufgabe 2: Multi-Stage Build

```dockerfile
# Dockerfile.optimized

# ===== BUILD STAGE =====
FROM dart:stable AS build

WORKDIR /app

# Dependencies cachen
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get

# Code kopieren
COPY . .

# Dependencies erneut (für AOT)
RUN dart pub get --offline

# Kompilieren
RUN dart compile exe bin/server.dart -o bin/server

# ===== RUNTIME STAGE =====
FROM debian:bookworm-slim

# CA-Zertifikate für HTTPS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Non-root User
RUN useradd -r -u 1001 -s /sbin/nologin appuser
USER appuser

WORKDIR /app

# Nur Binary kopieren
COPY --from=build /app/bin/server /app/bin/server

# Environment
ENV PORT=8080

# Port
EXPOSE 8080

# Health Check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start
ENTRYPOINT ["/app/bin/server"]
```

---

## Aufgabe 3: .dockerignore

```dockerignore
# .dockerignore

# Dart/Pub
.dart_tool/
.packages
build/
.pub-cache/
pubspec.lock

# IDE
.idea/
.vscode/
*.iml
*.ipr
*.iws

# Git
.git/
.gitignore
.gitattributes

# Tests
test/
coverage/
.test_runner.yaml

# Dokumentation
*.md
!README.md
LICENSE
docs/
CHANGELOG

# Lokale Konfiguration
.env
.env.local
.env.*.local
docker-compose.override.yml
*.local.yml

# CI/CD
.github/
.gitlab-ci.yml
Makefile

# Misc
*.log
*.tmp
.DS_Store
Thumbs.db
```

---

## Aufgabe 4: Docker Compose Setup

```yaml
# docker-compose.yml

services:
  api:
    build:
      context: .
      dockerfile: Dockerfile.optimized
    ports:
      - "8080:8080"
    environment:
      - PORT=8080
      - DATABASE_URL=postgres://postgres:postgres@db:5432/myapp
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET:-dev-secret-change-in-prod}
      - LOG_LEVEL=${LOG_LEVEL:-info}
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    restart: unless-stopped
    networks:
      - app-network

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
      test: ["CMD-SHELL", "pg_isready -U postgres -d myapp"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    networks:
      - app-network

  adminer:
    image: adminer
    ports:
      - "8081:8080"
    depends_on:
      - db
    networks:
      - app-network

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

```yaml
# docker-compose.override.yml (für lokale Entwicklung)

services:
  api:
    build:
      target: build
    command: dart run bin/server.dart
    volumes:
      - .:/app:delegated
      - dart_packages:/app/.dart_tool
    environment:
      - LOG_LEVEL=debug
      - LOG_FORMAT=text

volumes:
  dart_packages:
```

---

## Aufgabe 5: Init-Script

```sql
-- init.sql

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users Tabelle
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Refresh Tokens Tabelle
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    revoked_at TIMESTAMP
);

-- Index für häufige Queries
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- Updated At Trigger
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Test-Admin (nur für Entwicklung)
-- Password: admin123 (bcrypt hash)
INSERT INTO users (email, password_hash, name, role)
VALUES (
    'admin@example.com',
    '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.nqYBFqJWvyYGiS',
    'Admin',
    'admin'
) ON CONFLICT (email) DO NOTHING;
```

---

## Aufgabe 6: Environment-Konfiguration

```bash
# .env.example

# Server
PORT=8080
HOST=0.0.0.0
LOG_LEVEL=info
LOG_FORMAT=json

# Database
DATABASE_URL=postgres://user:password@host:5432/database
DATABASE_POOL_SIZE=10
DATABASE_TIMEOUT=30

# Redis
REDIS_URL=redis://host:6379
REDIS_PREFIX=myapp:

# Authentication
JWT_SECRET=change-this-to-a-secure-random-string
JWT_ACCESS_TOKEN_DURATION=15m
JWT_REFRESH_TOKEN_DURATION=7d

# Email (optional)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=noreply@example.com

# External APIs (optional)
SENTRY_DSN=
```

```bash
# .env (lokale Entwicklung - NICHT committen!)

PORT=8080
HOST=0.0.0.0
LOG_LEVEL=debug
LOG_FORMAT=text

DATABASE_URL=postgres://postgres:postgres@db:5432/myapp
DATABASE_POOL_SIZE=5

REDIS_URL=redis://redis:6379

JWT_SECRET=dev-secret-for-local-development-only
JWT_ACCESS_TOKEN_DURATION=1h
JWT_REFRESH_TOKEN_DURATION=30d
```

---

## Aufgabe 7: Fly.io Deployment

```toml
# fly.toml

app = "my-dart-api"
primary_region = "fra"

[build]
  dockerfile = "Dockerfile.optimized"

[env]
  PORT = "8080"
  LOG_LEVEL = "info"
  LOG_FORMAT = "json"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

  [http_service.concurrency]
    type = "requests"
    hard_limit = 250
    soft_limit = 200

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.http_checks]]
    interval = "15s"
    timeout = "5s"
    grace_period = "10s"
    path = "/health"
    method = "GET"

[[vm]]
  cpu_kind = "shared"
  cpus = 1
  memory_mb = 512
```

### Deployment-Befehle

```bash
# 1. Fly CLI installieren
curl -L https://fly.io/install.sh | sh

# Oder via npm
npm install -g flyctl

# 2. Login
fly auth login

# 3. App erstellen (interaktiv)
fly launch

# Oder manuell
fly apps create my-dart-api

# 4. PostgreSQL erstellen
fly postgres create --name my-dart-api-db

# PostgreSQL mit App verbinden
fly postgres attach my-dart-api-db

# 5. Secrets setzen
fly secrets set JWT_SECRET="$(openssl rand -base64 32)"
fly secrets set REDIS_URL="redis://..."  # Falls Redis benötigt

# Secrets auflisten
fly secrets list

# 6. Deployen
fly deploy

# Mit bestimmtem Image
fly deploy --image ghcr.io/user/repo:tag

# 7. Status prüfen
fly status
fly logs
fly logs --app my-dart-api

# 8. Skalieren
fly scale count 2  # 2 Instanzen
fly scale vm shared-cpu-1x  # VM-Größe

# 9. SSH in Container
fly ssh console

# 10. Rollback
fly releases list
fly deploy --image <previous-image>
```

---

## Aufgabe 8: GitHub Actions CI/CD

```yaml
# .github/workflows/ci.yml

name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}
  FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

jobs:
  test:
    name: Test
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Dart
        uses: dart-lang/setup-dart@v1
        with:
          sdk: stable

      - name: Install dependencies
        run: dart pub get

      - name: Analyze
        run: dart analyze --fatal-infos

      - name: Format check
        run: dart format --set-exit-if-changed .

      - name: Run tests
        run: dart test --coverage=coverage
        env:
          DATABASE_URL: postgres://test:test@localhost:5432/test

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info

  build:
    name: Build
    needs: test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    outputs:
      image: ${{ steps.meta.outputs.tags }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

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
            type=raw,value=latest,enable={{is_default_branch}}

      - name: Build and push
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile.optimized
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy:
    name: Deploy
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    environment:
      name: production
      url: https://my-dart-api.fly.dev

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Fly
        uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy to Fly.io
        run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}

      - name: Smoke Test
        run: |
          sleep 10
          curl -f https://my-dart-api.fly.dev/health || exit 1
```

---

## Bonus: Makefile

```makefile
# Makefile

.PHONY: help dev build test lint deploy clean

# Default target
help:
	@echo "Available commands:"
	@echo "  make dev      - Start development environment"
	@echo "  make build    - Build Docker image"
	@echo "  make test     - Run tests"
	@echo "  make lint     - Run linter"
	@echo "  make deploy   - Deploy to Fly.io"
	@echo "  make clean    - Clean up"

# Entwicklung
dev:
	docker compose up -d
	docker compose logs -f api

dev-down:
	docker compose down

dev-restart:
	docker compose restart api

# Build
build:
	docker build -t my-api:latest -f Dockerfile.optimized .

build-no-cache:
	docker build --no-cache -t my-api:latest -f Dockerfile.optimized .

# Tests
test:
	dart test

test-coverage:
	dart test --coverage=coverage
	dart pub global run coverage:format_coverage \
		--lcov --in=coverage --out=coverage/lcov.info

# Linting
lint:
	dart analyze
	dart format --set-exit-if-changed .

lint-fix:
	dart format .

# Deployment
deploy:
	flyctl deploy

deploy-staging:
	flyctl deploy --config fly.staging.toml

# Secrets
secrets:
	flyctl secrets list

set-secret:
	@read -p "Secret name: " name; \
	read -p "Secret value: " value; \
	flyctl secrets set $$name=$$value

# Logs
logs:
	flyctl logs

logs-follow:
	flyctl logs -f

# Database
db-shell:
	docker compose exec db psql -U postgres -d myapp

db-migrate:
	dart run bin/migrate.dart

# Cleanup
clean:
	docker compose down -v
	docker system prune -f
	rm -rf coverage/ .dart_tool/ build/

# CI lokall testen
ci:
	act -j test
```

---

## Projektstruktur

```
my-api/
├── .github/
│   └── workflows/
│       └── ci.yml
├── bin/
│   ├── server.dart
│   └── migrate.dart
├── lib/
│   └── ...
├── test/
│   └── ...
├── .dockerignore
├── .env.example
├── .gitignore
├── Dockerfile
├── Dockerfile.optimized
├── docker-compose.yml
├── docker-compose.override.yml
├── fly.toml
├── init.sql
├── Makefile
├── pubspec.yaml
└── README.md
```

---

## README.md Template

```markdown
# My Dart API

## Lokale Entwicklung

### Voraussetzungen

- Docker & Docker Compose
- Dart SDK (für Tests ohne Docker)

### Starten

```bash
# Umgebungsvariablen kopieren
cp .env.example .env

# Services starten
docker compose up -d

# Logs verfolgen
docker compose logs -f api
```

### Endpoints

- API: http://localhost:8080
- Adminer (DB UI): http://localhost:8081
- Health: http://localhost:8080/health

## Tests

```bash
dart test
```

## Deployment

Deployment erfolgt automatisch bei Push auf `main` via GitHub Actions.

Manuelles Deployment:

```bash
flyctl deploy
```

## Umgebungsvariablen

Siehe `.env.example` für alle verfügbaren Variablen.
```
