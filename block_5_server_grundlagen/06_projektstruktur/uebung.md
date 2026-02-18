# Übung 5.6: Projekt-Struktur & Architektur

## Ziel

Refaktoriere eine bestehende "Monolith"-Anwendung in eine sauber strukturierte Layered Architecture mit Repositories, Services und Controllers.

---

## Ausgangssituation

Du hast folgenden Code in einer einzigen Datei:

```dart
// bin/server.dart (VORHER - alles in einer Datei)
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

final _tasks = <String, Map<String, dynamic>>{};
var _nextId = 1;

void main() async {
  final router = Router();

  router.get('/api/tasks', (Request request) {
    return Response.ok(
      jsonEncode({'tasks': _tasks.values.toList()}),
      headers: {'content-type': 'application/json'},
    );
  });

  router.get('/api/tasks/<id>', (Request request, String id) {
    final task = _tasks[id];
    if (task == null) {
      return Response.notFound(jsonEncode({'error': 'Not found'}));
    }
    return Response.ok(jsonEncode(task));
  });

  router.post('/api/tasks', (Request request) async {
    final body = jsonDecode(await request.readAsString());
    if (body['title'] == null || body['title'].isEmpty) {
      return Response.badRequest(body: jsonEncode({'error': 'Title required'}));
    }
    final id = '${_nextId++}';
    _tasks[id] = {
      'id': id,
      'title': body['title'],
      'description': body['description'] ?? '',
      'completed': false,
      'createdAt': DateTime.now().toIso8601String(),
    };
    return Response(201, body: jsonEncode(_tasks[id]));
  });

  // ... mehr Code

  await shelf_io.serve(router.call, 'localhost', 8080);
}
```

---

## Aufgabe 1: Projektstruktur anlegen (10 min)

Erstelle folgende Ordnerstruktur:

```
task_api/
├── bin/
│   └── server.dart
├── lib/
│   ├── app.dart
│   ├── config/
│   │   └── config.dart
│   ├── controllers/
│   │   └── task_controller.dart
│   ├── services/
│   │   └── task_service.dart
│   ├── repositories/
│   │   └── task_repository.dart
│   ├── models/
│   │   └── task.dart
│   ├── dto/
│   │   ├── create_task_dto.dart
│   │   └── update_task_dto.dart
│   └── utils/
│       ├── exceptions.dart
│       └── json_response.dart
└── pubspec.yaml
```

---

## Aufgabe 2: Model erstellen (10 min)

Erstelle das Task-Model in `lib/models/task.dart`.

### Anforderungen

```dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final DateTime createdAt;
  final DateTime? completedAt;

  // Konstruktor
  // fromJson factory
  // toJson method
  // copyWith method
}
```

---

## Aufgabe 3: Repository erstellen (15 min)

Erstelle das Repository in `lib/repositories/task_repository.dart`.

### Interface

```dart
abstract class TaskRepository {
  Future<List<Task>> findAll();
  Future<Task?> findById(String id);
  Future<List<Task>> findByCompleted(bool completed);
  Future<Task> create(Task task);
  Future<Task> update(Task task);
  Future<void> delete(String id);
}
```

### InMemoryTaskRepository

Implementiere eine In-Memory-Version des Repositories.

---

## Aufgabe 4: DTOs erstellen (10 min)

Erstelle die DTOs für Input-Daten.

### CreateTaskDto

```dart
class CreateTaskDto {
  final String title;
  final String? description;

  // fromJson
  // validate() method
}
```

### UpdateTaskDto

```dart
class UpdateTaskDto {
  final String? title;
  final String? description;
  final bool? completed;

  // fromJson
}
```

---

## Aufgabe 5: Service erstellen (15 min)

Erstelle den Service in `lib/services/task_service.dart`.

### Anforderungen

```dart
class TaskService {
  final TaskRepository _repository;

  TaskService(this._repository);

  Future<List<Task>> getAllTasks({bool? completed});
  Future<Task> getTaskById(String id);
  Future<Task> createTask(CreateTaskDto dto);
  Future<Task> updateTask(String id, UpdateTaskDto dto);
  Future<Task> completeTask(String id);
  Future<void> deleteTask(String id);
}
```

### Business-Logik

1. `createTask`: Validiere Title (nicht leer, max 200 Zeichen)
2. `completeTask`: Setze `completed = true` und `completedAt`
3. `getTaskById`: Werfe `NotFoundException` wenn nicht gefunden

---

## Aufgabe 6: Controller erstellen (15 min)

Erstelle den Controller in `lib/controllers/task_controller.dart`.

### Anforderungen

```dart
class TaskController {
  final TaskService _service;

  TaskController(this._service);

  Router get router {
    // GET    /           -> Liste aller Tasks
    // GET    /<id>       -> Einzelner Task
    // POST   /           -> Task erstellen
    // PUT    /<id>       -> Task aktualisieren
    // PATCH  /<id>/complete -> Task abschließen
    // DELETE /<id>       -> Task löschen
  }
}
```

### Query-Parameter für Liste

```
GET /api/tasks?completed=true   -> Nur abgeschlossene
GET /api/tasks?completed=false  -> Nur offene
GET /api/tasks                  -> Alle
```

---

## Aufgabe 7: App zusammenbauen (10 min)

Erstelle `lib/app.dart` mit Dependency Injection.

```dart
class App {
  final AppConfig config;
  late final TaskRepository taskRepository;
  late final TaskService taskService;
  late final TaskController taskController;

  App(this.config) {
    // Abhängigkeiten erstellen
  }

  Handler get handler {
    // Pipeline mit Middleware
    // Router mit gemounteten Controllers
  }
}
```

### bin/server.dart

```dart
void main() async {
  final config = AppConfig.fromEnvironment();
  final app = App(config);

  await shelf_io.serve(app.handler, config.host, config.port);
  print('Server running on http://${config.host}:${config.port}');
}
```

---

## Aufgabe 8: Utils erstellen (5 min)

### lib/utils/exceptions.dart

```dart
class NotFoundException extends AppException { ... }
class ValidationException extends AppException { ... }
```

### lib/utils/json_response.dart

```dart
Response jsonResponse(Object? data, {int statusCode = 200});
```

---

## Testen

```bash
# Server starten
dart run bin/server.dart

# Tasks erstellen
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Learn Dart"}'

curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Build API", "description": "REST API with Shelf"}'

# Alle Tasks
curl http://localhost:8080/api/tasks

# Nur offene
curl "http://localhost:8080/api/tasks?completed=false"

# Task abschließen
curl -X PATCH http://localhost:8080/api/tasks/1/complete

# Nur abgeschlossene
curl "http://localhost:8080/api/tasks?completed=true"

# Task aktualisieren
curl -X PUT http://localhost:8080/api/tasks/2 \
  -H "Content-Type: application/json" \
  -d '{"title": "Build REST API"}'

# Task löschen
curl -X DELETE http://localhost:8080/api/tasks/1

# Fehler testen
curl -X POST http://localhost:8080/api/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": ""}'

curl http://localhost:8080/api/tasks/999
```

---

## Abgabe-Checkliste

- [ ] Projektstruktur angelegt
- [ ] Task-Model mit JSON-Serialisierung
- [ ] TaskRepository Interface und InMemory-Implementierung
- [ ] DTOs für Create und Update
- [ ] TaskService mit Geschäftslogik
- [ ] TaskController mit allen Endpunkten
- [ ] App-Klasse mit Dependency Injection
- [ ] Error-Handler-Middleware
- [ ] Alle Endpunkte funktionieren
- [ ] Filter-Parameter funktioniert
