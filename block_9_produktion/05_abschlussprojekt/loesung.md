# Lösung 9.5: Backend-Abschlussprojekt

Diese Lösung zeigt die wichtigsten Komponenten. Der vollständige Code wäre zu umfangreich für eine einzelne Datei.

---

## Projektstruktur

```
task_api/
├── bin/
│   └── server.dart
├── lib/
│   ├── config/
│   │   └── config.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── project.dart
│   │   └── task.dart
│   ├── repositories/
│   │   ├── user_repository.dart
│   │   ├── project_repository.dart
│   │   └── task_repository.dart
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── password_service.dart
│   │   ├── jwt_service.dart
│   │   └── project_service.dart
│   ├── handlers/
│   │   ├── auth_handler.dart
│   │   ├── project_handler.dart
│   │   └── task_handler.dart
│   ├── middleware/
│   │   ├── auth_middleware.dart
│   │   └── error_middleware.dart
│   └── app.dart
├── migrations/
│   └── 001_initial.sql
├── docker-compose.yml
├── Dockerfile
└── pubspec.yaml
```

---

## Konfiguration

```dart
// lib/config/config.dart

import 'dart:io';

class AppConfig {
  final int port;
  final String databaseUrl;
  final String? redisUrl;
  final String jwtSecret;
  final Duration jwtAccessDuration;
  final Duration jwtRefreshDuration;
  final bool isDevelopment;

  AppConfig({
    required this.port,
    required this.databaseUrl,
    this.redisUrl,
    required this.jwtSecret,
    this.jwtAccessDuration = const Duration(minutes: 15),
    this.jwtRefreshDuration = const Duration(days: 7),
    this.isDevelopment = false,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      port: int.parse(Platform.environment['PORT'] ?? '8080'),
      databaseUrl: Platform.environment['DATABASE_URL'] ??
          'postgres://postgres:postgres@localhost:5432/taskapi',
      redisUrl: Platform.environment['REDIS_URL'],
      jwtSecret: Platform.environment['JWT_SECRET'] ?? 'dev-secret-change-me',
      isDevelopment: Platform.environment['ENV'] != 'production',
    );
  }
}
```

---

## Models

```dart
// lib/models/user.dart

class User {
  final int id;
  final String email;
  final String passwordHash;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    this.role = 'user',
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] as int,
      email: row['email'] as String,
      passwordHash: row['password_hash'] as String,
      name: row['name'] as String,
      role: row['role'] as String? ?? 'user',
      isActive: row['is_active'] as bool? ?? true,
      createdAt: row['created_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
      };
}

// lib/models/project.dart

class Project {
  final int id;
  final String name;
  final String? description;
  final int ownerId;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Project.fromRow(Map<String, dynamic> row) {
    return Project(
      id: row['id'] as int,
      name: row['name'] as String,
      description: row['description'] as String?,
      ownerId: row['owner_id'] as int,
      isArchived: row['is_archived'] as bool? ?? false,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'ownerId': ownerId,
        'isArchived': isArchived,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

// lib/models/task.dart

enum TaskStatus { todo, inProgress, review, done }
enum TaskPriority { low, medium, high, urgent }

class Task {
  final int id;
  final String title;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final int projectId;
  final int? assigneeId;
  final int createdBy;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    required this.projectId,
    this.assigneeId,
    required this.createdBy,
    this.dueDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromRow(Map<String, dynamic> row) {
    return Task(
      id: row['id'] as int,
      title: row['title'] as String,
      description: row['description'] as String?,
      status: TaskStatus.values.byName(row['status'] as String? ?? 'todo'),
      priority: TaskPriority.values.byName(row['priority'] as String? ?? 'medium'),
      projectId: row['project_id'] as int,
      assigneeId: row['assignee_id'] as int?,
      createdBy: row['created_by'] as int,
      dueDate: row['due_date'] as DateTime?,
      completedAt: row['completed_at'] as DateTime?,
      createdAt: row['created_at'] as DateTime,
      updatedAt: row['updated_at'] as DateTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.name,
        'priority': priority.name,
        'projectId': projectId,
        'assigneeId': assigneeId,
        'createdBy': createdBy,
        'dueDate': dueDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
```

---

## Services

```dart
// lib/services/password_service.dart

import 'package:bcrypt/bcrypt.dart';

class PasswordService {
  final int costFactor;

  PasswordService({this.costFactor = 12});

  String hash(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt(logRounds: costFactor));
  }

  bool verify(String password, String hash) {
    return BCrypt.checkpw(password, hash);
  }
}

// lib/services/jwt_service.dart

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtService {
  final String secret;
  final Duration accessDuration;
  final Duration refreshDuration;

  JwtService({
    required this.secret,
    this.accessDuration = const Duration(minutes: 15),
    this.refreshDuration = const Duration(days: 7),
  });

  String generateAccessToken(User user) {
    final jwt = JWT({
      'sub': user.id.toString(),
      'email': user.email,
      'name': user.name,
      'role': user.role,
      'type': 'access',
    });
    return jwt.sign(SecretKey(secret), expiresIn: accessDuration);
  }

  String generateRefreshToken(User user) {
    final jwt = JWT({
      'sub': user.id.toString(),
      'type': 'refresh',
    });
    return jwt.sign(SecretKey(secret), expiresIn: refreshDuration);
  }

  Map<String, dynamic>? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, SecretKey(secret));
      return jwt.payload as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  String? extractFromHeader(String? header) {
    if (header == null || !header.startsWith('Bearer ')) return null;
    return header.substring(7);
  }
}

// lib/services/auth_service.dart

class AuthService {
  final UserRepository _userRepo;
  final RefreshTokenRepository _tokenRepo;
  final PasswordService _password;
  final JwtService _jwt;

  AuthService(this._userRepo, this._tokenRepo, this._password, this._jwt);

  Future<User> register(String email, String password, String name) async {
    if (await _userRepo.existsByEmail(email)) {
      throw AuthException('Email already exists');
    }

    final hash = _password.hash(password);
    return await _userRepo.create(email: email, passwordHash: hash, name: name);
  }

  Future<TokenPair> login(String email, String password) async {
    final user = await _userRepo.findByEmail(email);

    if (user == null || !user.isActive) {
      // Timing attack prevention
      _password.hash(password);
      throw AuthException('Invalid credentials');
    }

    if (!_password.verify(password, user.passwordHash)) {
      throw AuthException('Invalid credentials');
    }

    return _generateTokens(user);
  }

  Future<TokenPair> refreshToken(String refreshToken) async {
    final payload = _jwt.verifyToken(refreshToken);
    if (payload == null || payload['type'] != 'refresh') {
      throw AuthException('Invalid refresh token');
    }

    final userId = int.parse(payload['sub'] as String);
    final storedToken = await _tokenRepo.findByUserAndHash(userId, _hashToken(refreshToken));

    if (storedToken == null || storedToken.isRevoked) {
      throw AuthException('Token revoked');
    }

    final user = await _userRepo.findById(userId);
    if (user == null || !user.isActive) {
      throw AuthException('User not found');
    }

    // Rotate token
    await _tokenRepo.revoke(storedToken.id);

    return _generateTokens(user);
  }

  Future<void> logout(String refreshToken) async {
    final payload = _jwt.verifyToken(refreshToken);
    if (payload != null) {
      final userId = int.parse(payload['sub'] as String);
      final hash = _hashToken(refreshToken);
      final token = await _tokenRepo.findByUserAndHash(userId, hash);
      if (token != null) {
        await _tokenRepo.revoke(token.id);
      }
    }
  }

  Future<TokenPair> _generateTokens(User user) async {
    final accessToken = _jwt.generateAccessToken(user);
    final refreshToken = _jwt.generateRefreshToken(user);

    await _tokenRepo.create(
      userId: user.id,
      tokenHash: _hashToken(refreshToken),
      expiresAt: DateTime.now().add(_jwt.refreshDuration),
    );

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: _jwt.accessDuration.inSeconds,
    );
  }

  String _hashToken(String token) {
    return sha256.convert(utf8.encode(token)).toString();
  }
}

class TokenPair {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_in': expiresIn,
        'token_type': 'Bearer',
      };
}
```

---

## Handlers

```dart
// lib/handlers/auth_handler.dart

import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthHandler {
  final AuthService _authService;

  AuthHandler(this._authService);

  Router get router {
    final router = Router();

    router.post('/register', _register);
    router.post('/login', _login);
    router.post('/refresh', _refresh);
    router.post('/logout', _logout);
    router.get('/me', _me);

    return router;
  }

  Future<Response> _register(Request request) async {
    final body = jsonDecode(await request.readAsString());

    final email = body['email'] as String?;
    final password = body['password'] as String?;
    final name = body['name'] as String?;

    if (email == null || password == null || name == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'email, password, and name required'}),
      );
    }

    try {
      final user = await _authService.register(email, password, name);
      return Response(201,
          body: jsonEncode(user.toJson()),
          headers: {'content-type': 'application/json'});
    } on AuthException catch (e) {
      return Response(409,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _login(Request request) async {
    final body = jsonDecode(await request.readAsString());

    final email = body['email'] as String?;
    final password = body['password'] as String?;

    if (email == null || password == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'email and password required'}),
      );
    }

    try {
      final tokens = await _authService.login(email, password);
      return Response.ok(
        jsonEncode(tokens.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } on AuthException catch (e) {
      return Response(401,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _refresh(Request request) async {
    final body = jsonDecode(await request.readAsString());
    final refreshToken = body['refresh_token'] as String?;

    if (refreshToken == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'refresh_token required'}),
      );
    }

    try {
      final tokens = await _authService.refreshToken(refreshToken);
      return Response.ok(
        jsonEncode(tokens.toJson()),
        headers: {'content-type': 'application/json'},
      );
    } on AuthException catch (e) {
      return Response(401,
          body: jsonEncode({'error': e.message}),
          headers: {'content-type': 'application/json'});
    }
  }

  Future<Response> _logout(Request request) async {
    final body = jsonDecode(await request.readAsString());
    final refreshToken = body['refresh_token'] as String?;

    if (refreshToken != null) {
      await _authService.logout(refreshToken);
    }

    return Response.ok(jsonEncode({'message': 'Logged out'}));
  }

  Future<Response> _me(Request request) async {
    final user = request.context['user'] as User?;
    if (user == null) {
      return Response(401, body: jsonEncode({'error': 'Not authenticated'}));
    }
    return Response.ok(
      jsonEncode(user.toJson()),
      headers: {'content-type': 'application/json'},
    );
  }
}
```

---

## Middleware

```dart
// lib/middleware/auth_middleware.dart

import 'package:shelf/shelf.dart';

Middleware authMiddleware(JwtService jwt, UserRepository userRepo) {
  return (Handler innerHandler) {
    return (Request request) async {
      final token = jwt.extractFromHeader(request.headers['authorization']);

      if (token == null) {
        return Response(401,
            body: jsonEncode({'error': 'Authorization required'}),
            headers: {'content-type': 'application/json'});
      }

      final payload = jwt.verifyToken(token);
      if (payload == null || payload['type'] != 'access') {
        return Response(401,
            body: jsonEncode({'error': 'Invalid token'}),
            headers: {'content-type': 'application/json'});
      }

      final userId = int.parse(payload['sub'] as String);
      final user = await userRepo.findById(userId);

      if (user == null || !user.isActive) {
        return Response(401,
            body: jsonEncode({'error': 'User not found'}),
            headers: {'content-type': 'application/json'});
      }

      return innerHandler(request.change(context: {'user': user}));
    };
  };
}

Middleware requireRole(String role) {
  return (Handler innerHandler) {
    return (Request request) async {
      final user = request.context['user'] as User?;

      if (user == null) {
        return Response(401, body: jsonEncode({'error': 'Not authenticated'}));
      }

      if (user.role != role && user.role != 'admin') {
        return Response(403, body: jsonEncode({'error': 'Insufficient permissions'}));
      }

      return innerHandler(request);
    };
  };
}
```

---

## App Assembly

```dart
// lib/app.dart

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class App {
  final AppConfig config;
  final Connection db;
  final RedisConnection? redis;

  // Repositories
  late final UserRepository userRepo;
  late final ProjectRepository projectRepo;
  late final TaskRepository taskRepo;
  late final RefreshTokenRepository tokenRepo;

  // Services
  late final PasswordService passwordService;
  late final JwtService jwtService;
  late final AuthService authService;
  late final ProjectService projectService;
  late final TaskService taskService;

  // Handlers
  late final AuthHandler authHandler;
  late final ProjectHandler projectHandler;
  late final TaskHandler taskHandler;
  late final HealthHandler healthHandler;

  App(this.config, this.db, this.redis);

  void init() {
    // Init repositories
    userRepo = UserRepository(db);
    projectRepo = ProjectRepository(db);
    taskRepo = TaskRepository(db);
    tokenRepo = RefreshTokenRepository(db);

    // Init services
    passwordService = PasswordService();
    jwtService = JwtService(
      secret: config.jwtSecret,
      accessDuration: config.jwtAccessDuration,
      refreshDuration: config.jwtRefreshDuration,
    );
    authService = AuthService(userRepo, tokenRepo, passwordService, jwtService);
    projectService = ProjectService(projectRepo, userRepo);
    taskService = TaskService(taskRepo, projectService);

    // Init handlers
    authHandler = AuthHandler(authService);
    projectHandler = ProjectHandler(projectService);
    taskHandler = TaskHandler(taskService);
    healthHandler = HealthHandler(db, redis);
  }

  Handler get handler {
    final router = Router();

    // Public routes
    router.mount('/api/auth/', authHandler.router.call);

    // Health
    router.get('/health', healthHandler.check);
    router.get('/health/ready', healthHandler.ready);
    router.get('/health/live', healthHandler.live);

    // Protected routes
    final protectedRouter = Router();
    protectedRouter.mount('/projects/', projectHandler.router.call);
    protectedRouter.mount('/tasks/', taskHandler.router.call);

    router.mount(
      '/api/',
      const Pipeline()
          .addMiddleware(authMiddleware(jwtService, userRepo))
          .addHandler(protectedRouter.call),
    );

    // Pipeline
    return const Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsMiddleware())
        .addMiddleware(errorMiddleware())
        .addHandler(router.call);
  }
}
```

---

## Server

```dart
// bin/server.dart

import 'dart:io';
import 'package:shelf/shelf_io.dart' as io;
import 'package:postgres/postgres.dart';

void main() async {
  final config = AppConfig.fromEnvironment();

  // Database
  final db = await Connection.open(
    Endpoint.parse(config.databaseUrl),
    settings: ConnectionSettings(sslMode: SslMode.disable),
  );

  // Redis (optional)
  RedisConnection? redis;
  if (config.redisUrl != null) {
    redis = await RedisConnection.connect(config.redisUrl!);
  }

  // App
  final app = App(config, db, redis);
  app.init();

  // Server
  final server = await io.serve(
    app.handler,
    InternetAddress.anyIPv4,
    config.port,
  );

  print('Server running on http://localhost:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('Shutting down...');
    await server.close();
    await db.close();
    await redis?.close();
    exit(0);
  });
}
```

---

## Migration

```sql
-- migrations/001_initial.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(100) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE projects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    owner_id INTEGER REFERENCES users(id),
    is_archived BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE project_members (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'member',
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(project_id, user_id)
);

CREATE TABLE tasks (
    id SERIAL PRIMARY KEY,
    title VARCHAR(300) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'todo',
    priority VARCHAR(50) DEFAULT 'medium',
    project_id INTEGER REFERENCES projects(id) ON DELETE CASCADE,
    assignee_id INTEGER REFERENCES users(id),
    created_by INTEGER REFERENCES users(id),
    due_date TIMESTAMP,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES tasks(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE refresh_tokens (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indices
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_tasks_project ON tasks(project_id);
CREATE INDEX idx_tasks_assignee ON tasks(assignee_id);
CREATE INDEX idx_comments_task ON comments(task_id);
CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
```

---

## Docker

```dockerfile
# Dockerfile

FROM dart:stable AS build
WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
RUN useradd -r -u 1001 appuser
USER appuser
WORKDIR /app
COPY --from=build /app/bin/server /app/bin/server
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/health || exit 1
ENTRYPOINT ["/app/bin/server"]
```

```yaml
# docker-compose.yml

services:
  api:
    build: .
    ports:
      - "8080:8080"
    environment:
      - DATABASE_URL=postgres://postgres:postgres@db:5432/taskapi
      - JWT_SECRET=dev-secret
    depends_on:
      db:
        condition: service_healthy

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: taskapi
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    volumes:
      - ./migrations:/docker-entrypoint-initdb.d:ro
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: pg_isready -U postgres
      interval: 5s

volumes:
  postgres_data:
```
