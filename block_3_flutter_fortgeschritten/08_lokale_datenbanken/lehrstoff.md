# Einheit 3.8: Lokale Datenbanken

## Lernziele

Nach dieser Einheit kannst du:
- `sqflite` für SQLite-Datenbanken verwenden
- `hive` als NoSQL-Alternative einsetzen
- CRUD-Operationen implementieren
- Die richtige Datenbank für deinen Use Case wählen

---

## 1. Übersicht: sqflite vs. Hive

| Feature | sqflite (SQLite) | Hive (NoSQL) |
|---------|------------------|--------------|
| Typ | Relational | Key-Value / Document |
| Query-Sprache | SQL | Dart API |
| Schema | Ja (Tabellen) | Schema-frei |
| Performance | Gut | Sehr schnell |
| Komplexe Queries | Ja (JOINs, etc.) | Begrenzt |
| Learning Curve | Mittel | Niedrig |
| Best für | Strukturierte, relationale Daten | Einfache Objekte, schneller Zugriff |

---

## 2. sqflite - Setup

### Installation

```yaml
dependencies:
  sqflite: ^2.3.2
  path: ^1.8.3
```

### Datenbank öffnen

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE todos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE todos ADD COLUMN priority INTEGER DEFAULT 0');
    }
  }
}
```

---

## 3. sqflite - CRUD Operationen

### Model-Klasse

```dart
class Todo {
  final int? id;
  final String title;
  final String? description;
  final bool completed;
  final DateTime createdAt;

  Todo({
    this.id,
    required this.title,
    this.description,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      completed: map['completed'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Todo copyWith({
    int? id,
    String? title,
    String? description,
    bool? completed,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      createdAt: createdAt,
    );
  }
}
```

### Repository Pattern

```dart
class TodoRepository {
  final DatabaseHelper _dbHelper;

  TodoRepository(this._dbHelper);

  // CREATE
  Future<int> insert(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.insert('todos', todo.toMap());
  }

  // READ ALL
  Future<List<Todo>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query('todos', orderBy: 'created_at DESC');
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  // READ ONE
  Future<Todo?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  // UPDATE
  Future<int> update(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.update(
      'todos',
      todo.toMap(),
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  // DELETE
  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // QUERY mit Filter
  Future<List<Todo>> getByCompleted(bool completed) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todos',
      where: 'completed = ?',
      whereArgs: [completed ? 1 : 0],
    );
    return maps.map((map) => Todo.fromMap(map)).toList();
  }

  // COUNT
  Future<int> count() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
    return result.first['count'] as int;
  }
}
```

---

## 4. sqflite - Komplexe Queries

```dart
// Raw Query
Future<List<Todo>> search(String query) async {
  final db = await _dbHelper.database;
  final maps = await db.rawQuery(
    'SELECT * FROM todos WHERE title LIKE ? OR description LIKE ?',
    ['%$query%', '%$query%'],
  );
  return maps.map((map) => Todo.fromMap(map)).toList();
}

// Aggregationen
Future<Map<String, int>> getStats() async {
  final db = await _dbHelper.database;
  final result = await db.rawQuery('''
    SELECT
      COUNT(*) as total,
      SUM(CASE WHEN completed = 1 THEN 1 ELSE 0 END) as completed
    FROM todos
  ''');

  return {
    'total': result.first['total'] as int,
    'completed': result.first['completed'] as int? ?? 0,
  };
}

// Transaction
Future<void> completeAll() async {
  final db = await _dbHelper.database;
  await db.transaction((txn) async {
    await txn.update('todos', {'completed': 1});
  });
}

// Batch Operations
Future<void> insertMany(List<Todo> todos) async {
  final db = await _dbHelper.database;
  final batch = db.batch();

  for (final todo in todos) {
    batch.insert('todos', todo.toMap());
  }

  await batch.commit(noResult: true);
}
```

---

## 5. Hive - Setup

### Installation

```yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

### Initialisierung

```dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Adapter registrieren (nach Code-Generierung)
  Hive.registerAdapter(TodoAdapter());

  // Box öffnen
  await Hive.openBox<Todo>('todos');

  runApp(const MyApp());
}
```

---

## 6. Hive - Model mit TypeAdapter

```dart
import 'package:hive/hive.dart';

part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  bool completed;

  @HiveField(4)
  DateTime createdAt;

  Todo({
    required this.id,
    required this.title,
    this.description,
    this.completed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
```

Nach `flutter pub run build_runner build` wird `todo.g.dart` generiert.

---

## 7. Hive - CRUD Operationen

```dart
class TodoRepository {
  static const _boxName = 'todos';

  Box<Todo> get _box => Hive.box<Todo>(_boxName);

  // CREATE
  Future<void> add(Todo todo) async {
    await _box.put(todo.id, todo);
  }

  // READ ALL
  List<Todo> getAll() {
    return _box.values.toList();
  }

  // READ ONE
  Todo? getById(String id) {
    return _box.get(id);
  }

  // UPDATE
  Future<void> update(Todo todo) async {
    await todo.save();  // HiveObject bietet save()
    // Oder: await _box.put(todo.id, todo);
  }

  // DELETE
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  // DELETE ALL
  Future<void> deleteAll() async {
    await _box.clear();
  }

  // Filter
  List<Todo> getCompleted() {
    return _box.values.where((todo) => todo.completed).toList();
  }

  List<Todo> getPending() {
    return _box.values.where((todo) => !todo.completed).toList();
  }

  // Count
  int get count => _box.length;

  // Listen to changes
  Stream<BoxEvent> watch() {
    return _box.watch();
  }
}
```

---

## 8. Hive - Reactive mit ValueListenableBuilder

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: ValueListenableBuilder<Box<Todo>>(
        valueListenable: Hive.box<Todo>('todos').listenable(),
        builder: (context, box, _) {
          final todos = box.values.toList();

          if (todos.isEmpty) {
            return const Center(child: Text('Keine Todos'));
          }

          return ListView.builder(
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return ListTile(
                title: Text(todo.title),
                leading: Checkbox(
                  value: todo.completed,
                  onChanged: (value) {
                    todo.completed = value!;
                    todo.save();
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => todo.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

---

## 9. path_provider

Für Custom-Pfade:

```yaml
dependencies:
  path_provider: ^2.1.2
```

```dart
import 'package:path_provider/path_provider.dart';

// App-Dokumente (persistent)
final docDir = await getApplicationDocumentsDirectory();
final dbPath = '${docDir.path}/my_database.db';

// Temporäre Dateien
final tempDir = await getTemporaryDirectory();

// App-Support (iOS: Nicht sichtbar für User)
final supportDir = await getApplicationSupportDirectory();
```

---

## 10. Vergleich der Ansätze

### Wann sqflite?

- Komplexe Datenstrukturen mit Relationen
- SQL-Kenntnisse vorhanden
- Komplexe Queries (JOINs, Aggregationen)
- Migration von anderen SQL-Datenbanken
- Große Datenmengen mit Indizes

```dart
// Beispiel: Relationale Daten
// Users -> Posts -> Comments
await db.rawQuery('''
  SELECT p.*, u.name as author_name
  FROM posts p
  JOIN users u ON p.user_id = u.id
  WHERE p.id = ?
''', [postId]);
```

### Wann Hive?

- Einfache Objekt-Speicherung
- Schneller Zugriff ohne Queries
- Kein SQL-Wissen nötig
- Reactive UI mit listenable()
- Offline-Cache

```dart
// Beispiel: Cache
final box = Hive.box<User>('userCache');
box.put('current_user', user);
final cachedUser = box.get('current_user');
```

---

## 11. Alternativen

| Package | Beschreibung |
|---------|--------------|
| `isar` | Schnelle NoSQL DB, ersetzt Hive |
| `drift` | Type-safe SQL mit Code-Gen |
| `objectbox` | NoSQL, sehr performant |
| `floor` | Room-ähnlich (Android), Type-safe |
| `sembast` | Simple NoSQL |

---

## Zusammenfassung

| Operation | sqflite | Hive |
|-----------|---------|------|
| Setup | `openDatabase()` | `Hive.initFlutter()` |
| Insert | `db.insert()` | `box.put()` |
| Read | `db.query()` | `box.get()` / `box.values` |
| Update | `db.update()` | `object.save()` |
| Delete | `db.delete()` | `box.delete()` |
| Watch | Nicht eingebaut | `box.listenable()` |

**Empfehlung:**
- Einfache Apps: **Hive**
- Komplexe Daten/Queries: **sqflite**
- Modern mit Type-Safety: **drift** oder **isar**
