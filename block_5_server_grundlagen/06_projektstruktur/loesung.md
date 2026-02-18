# Lösung 5.6: Projekt-Struktur & Architektur

## Vollständige Lösung

### lib/models/task.dart

```dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.createdAt,
    this.completedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  Task copyWith({
    String? title,
    String? description,
    bool? completed,
    DateTime? completedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
```

### lib/dto/create_task_dto.dart

```dart
import '../utils/exceptions.dart';

class CreateTaskDto {
  final String title;
  final String? description;

  CreateTaskDto({
    required this.title,
    this.description,
  });

  factory CreateTaskDto.fromJson(Map<String, dynamic> json) {
    return CreateTaskDto(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  void validate() {
    final errors = <String>[];

    if (title.isEmpty) {
      errors.add('Title is required');
    }
    if (title.length > 200) {
      errors.add('Title must be at most 200 characters');
    }

    if (errors.isNotEmpty) {
      throw ValidationException('Invalid task data', errors: errors);
    }
  }
}
```

### lib/dto/update_task_dto.dart

```dart
class UpdateTaskDto {
  final String? title;
  final String? description;
  final bool? completed;

  UpdateTaskDto({
    this.title,
    this.description,
    this.completed,
  });

  factory UpdateTaskDto.fromJson(Map<String, dynamic> json) {
    return UpdateTaskDto(
      title: json['title'] as String?,
      description: json['description'] as String?,
      completed: json['completed'] as bool?,
    );
  }
}
```

### lib/repositories/task_repository.dart

```dart
import '../models/task.dart';

abstract class TaskRepository {
  Future<List<Task>> findAll();
  Future<Task?> findById(String id);
  Future<List<Task>> findByCompleted(bool completed);
  Future<Task> create(Task task);
  Future<Task> update(Task task);
  Future<void> delete(String id);
}

class InMemoryTaskRepository implements TaskRepository {
  final _tasks = <String, Task>{};
  var _nextId = 1;

  @override
  Future<List<Task>> findAll() async {
    return _tasks.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Task?> findById(String id) async {
    return _tasks[id];
  }

  @override
  Future<List<Task>> findByCompleted(bool completed) async {
    return _tasks.values
        .where((t) => t.completed == completed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<Task> create(Task task) async {
    final id = '${_nextId++}';
    final newTask = Task(
      id: id,
      title: task.title,
      description: task.description,
      completed: task.completed,
      createdAt: DateTime.now(),
    );
    _tasks[id] = newTask;
    return newTask;
  }

  @override
  Future<Task> update(Task task) async {
    _tasks[task.id] = task;
    return task;
  }

  @override
  Future<void> delete(String id) async {
    _tasks.remove(id);
  }
}
```

### lib/services/task_service.dart

```dart
import '../models/task.dart';
import '../dto/create_task_dto.dart';
import '../dto/update_task_dto.dart';
import '../repositories/task_repository.dart';
import '../utils/exceptions.dart';

class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  Future<List<Task>> getAllTasks({bool? completed}) async {
    if (completed != null) {
      return _repository.findByCompleted(completed);
    }
    return _repository.findAll();
  }

  Future<Task> getTaskById(String id) async {
    final task = await _repository.findById(id);
    if (task == null) {
      throw NotFoundException('Task $id not found');
    }
    return task;
  }

  Future<Task> createTask(CreateTaskDto dto) async {
    // Validierung
    dto.validate();

    // Task erstellen
    final task = Task(
      id: '', // Wird vom Repository gesetzt
      title: dto.title,
      description: dto.description ?? '',
      createdAt: DateTime.now(),
    );

    return _repository.create(task);
  }

  Future<Task> updateTask(String id, UpdateTaskDto dto) async {
    final task = await getTaskById(id);

    // Validierung
    if (dto.title != null) {
      if (dto.title!.isEmpty) {
        throw ValidationException('Title cannot be empty');
      }
      if (dto.title!.length > 200) {
        throw ValidationException('Title must be at most 200 characters');
      }
    }

    final updated = task.copyWith(
      title: dto.title,
      description: dto.description,
      completed: dto.completed,
      completedAt: dto.completed == true && !task.completed
          ? DateTime.now()
          : task.completedAt,
    );

    return _repository.update(updated);
  }

  Future<Task> completeTask(String id) async {
    final task = await getTaskById(id);

    if (task.completed) {
      throw ValidationException('Task is already completed');
    }

    final completed = task.copyWith(
      completed: true,
      completedAt: DateTime.now(),
    );

    return _repository.update(completed);
  }

  Future<void> deleteTask(String id) async {
    await getTaskById(id); // Prüft ob Task existiert
    await _repository.delete(id);
  }
}
```

### lib/controllers/task_controller.dart

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../services/task_service.dart';
import '../dto/create_task_dto.dart';
import '../dto/update_task_dto.dart';
import '../utils/json_response.dart';

class TaskController {
  final TaskService _service;

  TaskController(this._service);

  Router get router {
    final router = Router();

    router.get('/', _list);
    router.get('/<id>', _getById);
    router.post('/', _create);
    router.put('/<id>', _update);
    router.patch('/<id>/complete', _complete);
    router.delete('/<id>', _delete);

    return router;
  }

  Future<Response> _list(Request request) async {
    // Query-Parameter für Filter
    final completedParam = request.url.queryParameters['completed'];
    bool? completed;
    if (completedParam == 'true') {
      completed = true;
    } else if (completedParam == 'false') {
      completed = false;
    }

    final tasks = await _service.getAllTasks(completed: completed);

    return jsonResponse({
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'total': tasks.length,
      if (completed != null) 'filter': {'completed': completed},
    });
  }

  Future<Response> _getById(Request request, String id) async {
    final task = await _service.getTaskById(id);
    return jsonResponse(task.toJson());
  }

  Future<Response> _create(Request request) async {
    final body = await _parseJson(request);
    final dto = CreateTaskDto.fromJson(body);
    final task = await _service.createTask(dto);
    return jsonResponse(task.toJson(), statusCode: 201);
  }

  Future<Response> _update(Request request, String id) async {
    final body = await _parseJson(request);
    final dto = UpdateTaskDto.fromJson(body);
    final task = await _service.updateTask(id, dto);
    return jsonResponse(task.toJson());
  }

  Future<Response> _complete(Request request, String id) async {
    final task = await _service.completeTask(id);
    return jsonResponse(task.toJson());
  }

  Future<Response> _delete(Request request, String id) async {
    await _service.deleteTask(id);
    return Response(204);
  }

  Future<Map<String, dynamic>> _parseJson(Request request) async {
    final body = await request.readAsString();
    if (body.isEmpty) return {};
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
```

### lib/utils/exceptions.dart

```dart
abstract class AppException implements Exception {
  final String message;
  final int statusCode;

  AppException(this.message, this.statusCode);

  @override
  String toString() => message;
}

class NotFoundException extends AppException {
  NotFoundException(String message) : super(message, 404);
}

class ValidationException extends AppException {
  final List<String>? errors;

  ValidationException(String message, {this.errors}) : super(message, 400);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      return '$message: ${errors!.join(', ')}';
    }
    return message;
  }
}

class UnauthorizedException extends AppException {
  UnauthorizedException([String message = 'Unauthorized'])
      : super(message, 401);
}
```

### lib/utils/json_response.dart

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json; charset=utf-8'},
  );
}
```

### lib/config/config.dart

```dart
import 'dart:io';

class AppConfig {
  final String host;
  final int port;
  final String environment;

  AppConfig({
    required this.host,
    required this.port,
    required this.environment,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      host: Platform.environment['HOST'] ?? 'localhost',
      port: int.parse(Platform.environment['PORT'] ?? '8080'),
      environment: Platform.environment['ENVIRONMENT'] ?? 'development',
    );
  }

  bool get isDevelopment => environment == 'development';
}
```

### lib/app.dart

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'config/config.dart';
import 'controllers/task_controller.dart';
import 'services/task_service.dart';
import 'repositories/task_repository.dart';
import 'utils/exceptions.dart';
import 'utils/json_response.dart';

class App {
  final AppConfig config;
  late final TaskRepository taskRepository;
  late final TaskService taskService;
  late final TaskController taskController;

  App(this.config) {
    // Repositories (Data Layer)
    taskRepository = InMemoryTaskRepository();

    // Services (Business Layer)
    taskService = TaskService(taskRepository);

    // Controllers (Presentation Layer)
    taskController = TaskController(taskService);
  }

  Handler get handler {
    final router = Router();

    // Health Check
    router.get('/health', _healthCheck);

    // API Routes
    router.mount('/api/tasks', taskController.router.call);

    // 404
    router.all('/<path|.*>', _notFound);

    // Pipeline mit Middleware
    return Pipeline()
        .addMiddleware(_errorHandler())
        .addMiddleware(logRequests())
        .addHandler(router.call);
  }

  Response _healthCheck(Request request) {
    return jsonResponse({
      'status': 'ok',
      'environment': config.environment,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Response _notFound(Request request, String path) {
    return jsonResponse({
      'error': 'Not Found',
      'path': '/$path',
    }, statusCode: 404);
  }

  Middleware _errorHandler() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } on AppException catch (e) {
          return jsonResponse({
            'error': _getErrorName(e.statusCode),
            'message': e.message,
            if (e is ValidationException && e.errors != null)
              'errors': e.errors,
          }, statusCode: e.statusCode);
        } on FormatException catch (e) {
          return jsonResponse({
            'error': 'Bad Request',
            'message': 'Invalid JSON: ${e.message}',
          }, statusCode: 400);
        } catch (e, stack) {
          print('Unhandled error: $e\n$stack');
          return jsonResponse({
            'error': 'Internal Server Error',
            'message': 'An unexpected error occurred',
          }, statusCode: 500);
        }
      };
    };
  }

  String _getErrorName(int statusCode) {
    switch (statusCode) {
      case 400: return 'Bad Request';
      case 401: return 'Unauthorized';
      case 403: return 'Forbidden';
      case 404: return 'Not Found';
      case 409: return 'Conflict';
      default: return 'Error';
    }
  }
}
```

### bin/server.dart

```dart
import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;

import '../lib/app.dart';
import '../lib/config/config.dart';

void main() async {
  final config = AppConfig.fromEnvironment();
  final app = App(config);

  final server = await shelf_io.serve(app.handler, config.host, config.port);

  print('Task API Server');
  print('Environment: ${config.environment}');
  print('Running on http://${server.address.host}:${server.port}');

  // Graceful Shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    print('\nShutting down...');
    await server.close();
    exit(0);
  });
}
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# Tasks erstellen
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Dart", "description": "Study Dart basics"}'

curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Build API"}'

# Alle Tasks
curl http://localhost:8080/api/tasks

# Einzelner Task
curl http://localhost:8080/api/tasks/1

# Task abschließen
curl -X PATCH http://localhost:8080/api/tasks/1/complete

# Nur abgeschlossene
curl "http://localhost:8080/api/tasks?completed=true"

# Nur offene
curl "http://localhost:8080/api/tasks?completed=false"

# Task aktualisieren
curl -X PUT http://localhost:8080/api/tasks/2 \
  -H "Content-Type: application/json" \
  -d '{"title": "Build REST API", "description": "Using Shelf"}'

# Task löschen
curl -X DELETE http://localhost:8080/api/tasks/1

# Fehler: Leerer Titel
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": ""}'

# Fehler: Task nicht gefunden
curl http://localhost:8080/api/tasks/999

# Health Check
curl http://localhost:8080/health
```

---

## Architektur-Übersicht

```
Request → Router → Controller → Service → Repository → Data
                                  ↓            ↓
                           Validation    CRUD Operations
                                  ↓
Response ← Controller ← Service ← Model
```

Die klare Trennung ermöglicht:
- **Unit-Tests**: Services mit Mock-Repositories testen
- **Austauschbarkeit**: InMemory → PostgreSQL ohne Controller-Änderung
- **Wartbarkeit**: Jede Datei hat einen klaren Zweck
