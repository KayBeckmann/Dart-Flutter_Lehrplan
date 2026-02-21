# Ressourcen: Deployment & Docker

## Offizielle Dokumentation

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Fly.io Documentation](https://fly.io/docs/)
- [Railway Documentation](https://docs.railway.app/)
- [GitHub Actions](https://docs.github.com/en/actions)

## Cheat Sheet: Dockerfile

```dockerfile
# Base Images
FROM dart:stable          # Volle Dart SDK (~800MB)
FROM dart:stable-sdk      # Nur SDK
FROM debian:bookworm-slim # Minimales Debian (~80MB)
FROM alpine:3.18          # Noch kleiner (~5MB)
FROM scratch              # Leer (nur für statische Binaries)

# Arbeitsverzeichnis
WORKDIR /app

# Dateien kopieren
COPY . .                  # Alles
COPY pubspec.* ./         # Nur pubspec
COPY --from=build /app/bin/server .  # Aus anderem Stage

# Befehle ausführen
RUN dart pub get
RUN dart compile exe bin/server.dart -o server

# User
RUN useradd -r -u 1001 appuser
USER appuser

# Environment
ENV PORT=8080
EXPOSE 8080

# Health Check
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost:8080/health || exit 1

# Start
CMD ["./server"]
ENTRYPOINT ["./server"]   # Unveränderlich
```

## Cheat Sheet: Multi-Stage Build

```dockerfile
# Stage 1: Build
FROM dart:stable AS build
WORKDIR /app
COPY . .
RUN dart compile exe bin/server.dart -o server

# Stage 2: Runtime (nur Binary)
FROM debian:bookworm-slim
COPY --from=build /app/server /app/server
CMD ["/app/server"]

# Ergebnis: ~20MB statt ~800MB
```

## Cheat Sheet: Docker Compose

```yaml
services:
  app:
    build: .                    # Dockerfile im aktuellen Verzeichnis
    build:
      context: .
      dockerfile: Dockerfile.prod
    image: myapp:latest         # Fertiges Image verwenden
    ports:
      - "8080:8080"             # host:container
    environment:
      - KEY=value
    env_file:
      - .env
    volumes:
      - ./data:/app/data        # Bind Mount
      - myvolume:/app/storage   # Named Volume
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - backend

volumes:
  myvolume:

networks:
  backend:
```

## Cheat Sheet: Docker Befehle

```bash
# Images
docker build -t name:tag .
docker build -f Dockerfile.prod -t name:prod .
docker images
docker rmi image:tag

# Container
docker run -d -p 8080:8080 --name myapp image:tag
docker ps
docker ps -a
docker logs -f myapp
docker exec -it myapp sh
docker stop myapp
docker rm myapp

# Compose
docker compose up -d
docker compose down
docker compose logs -f
docker compose exec app sh
docker compose build --no-cache
docker compose ps

# Cleanup
docker system prune -f
docker volume prune -f
docker image prune -a
```

## Cheat Sheet: Fly.io

```bash
# Setup
fly auth login
fly launch                      # Neue App erstellen
fly deploy                      # Deployen

# Status
fly status
fly logs
fly logs -f

# Secrets
fly secrets set KEY=value
fly secrets list

# Database
fly postgres create
fly postgres attach app-db

# Skalierung
fly scale count 3               # 3 Instanzen
fly scale vm shared-cpu-1x      # VM-Größe
fly scale memory 512            # RAM

# SSH
fly ssh console
fly ssh console -C "ls -la"

# Rollback
fly releases list
fly deploy --image registry/app:v1
```

## Cheat Sheet: fly.toml

```toml
app = "my-app"
primary_region = "fra"

[build]
  dockerfile = "Dockerfile"

[env]
  PORT = "8080"

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
  min_machines_running = 1

[[services]]
  protocol = "tcp"
  internal_port = 8080

  [[services.ports]]
    port = 443
    handlers = ["tls", "http"]

  [[services.http_checks]]
    interval = "15s"
    timeout = "5s"
    path = "/health"
```

## Cheat Sheet: GitHub Actions

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart analyze
      - run: dart test

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: docker/build-push-action@v5
        with:
          push: true
          tags: ghcr.io/${{ github.repository }}:latest

  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

## Best Practices

### DO

1. **Multi-Stage Builds** - Kleine Images
2. **Non-root User** - Security
3. **Layer-Optimierung** - COPY pubspec.* vor COPY .
4. **Health Checks** - Für Orchestrierung
5. **.dockerignore** - Unnötiges ausschließen
6. **Secrets extern** - Nicht im Image
7. **Immutable Tags** - SHA statt :latest in Prod
8. **Graceful Shutdown** - SIGTERM behandeln

### DON'T

1. **Secrets im Dockerfile** - ENV SECRET=xxx
2. **:latest in Produktion** - Nicht reproduzierbar
3. **Root User** - Security-Risiko
4. **Große Base Images** - Langsamer, mehr CVEs
5. **Volumes für Code** - Nur für persistente Daten
6. **docker-compose.override.yml committen** - Lokal only

## Troubleshooting

```bash
# Build-Probleme
docker build --no-cache -t app .
docker build --progress=plain -t app .

# Container-Probleme
docker logs myapp
docker exec -it myapp sh
docker inspect myapp

# Netzwerk-Probleme
docker network ls
docker network inspect bridge

# Speicher-Probleme
docker system df
docker system prune -a
```

## Security Checklist

```markdown
- [ ] Non-root User im Container
- [ ] Minimales Base Image (debian-slim, alpine)
- [ ] Keine Secrets im Image
- [ ] HEALTHCHECK definiert
- [ ] Nur notwendige Ports exposed
- [ ] Read-only Filesystem wo möglich
- [ ] Security Scan durchgeführt (docker scout, trivy)
- [ ] Keine hardcoded Credentials
```
