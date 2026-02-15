# Lösung 3.8: Lokale Datenbanken

## sqflite Lösung

### database_helper.dart

```dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT,
        color INTEGER DEFAULT 0,
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');
  }
}
```

### note.dart

```dart
class Note {
  final int? id;
  final String title;
  final String content;
  final int color;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    this.id,
    required this.title,
    this.content = '',
    this.color = 0,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      title: map['title'] as String,
      content: map['content'] as String? ?? '',
      color: map['color'] as int? ?? 0,
      isPinned: map['is_pinned'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? color,
    bool? isPinned,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
```

### note_repository.dart

```dart
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import 'note.dart';

class NoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<int> insert(Note note) async {
    final db = await _dbHelper.database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAll() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<Note?> getById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<int> update(Note note) async {
    final db = await _dbHelper.database;
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'notes',
      updatedNote.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Note>> search(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<List<Note>> getPinned() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'is_pinned = 1',
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Note.fromMap(map)).toList();
  }

  Future<void> togglePinned(int id) async {
    final db = await _dbHelper.database;
    await db.rawUpdate(
      'UPDATE notes SET is_pinned = 1 - is_pinned WHERE id = ?',
      [id],
    );
  }
}
```

### notes_page.dart

```dart
import 'package:flutter/material.dart';
import 'note.dart';
import 'note_repository.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final _repository = NoteRepository();
  List<Note> _notes = [];
  String _searchQuery = '';
  bool _isLoading = true;

  static const _colors = [
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    final notes = _searchQuery.isEmpty
        ? await _repository.getAll()
        : await _repository.search(_searchQuery);

    setState(() {
      _notes = notes;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinnedNotes = _notes.where((n) => n.isPinned).toList();
    final otherNotes = _notes.where((n) => !n.isPinned).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notizen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(child: Text('Keine Notizen'))
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    if (pinnedNotes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Angepinnt',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...pinnedNotes.map((note) => _NoteCard(
                            note: note,
                            color: _colors[note.color],
                            onTap: () => _editNote(note),
                            onDelete: () => _deleteNote(note),
                            onTogglePin: () => _togglePin(note),
                          )),
                      const Divider(),
                    ],
                    if (otherNotes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Alle Notizen',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...otherNotes.map((note) => _NoteCard(
                            note: note,
                            color: _colors[note.color],
                            onTap: () => _editNote(note),
                            onDelete: () => _deleteNote(note),
                            onTogglePin: () => _togglePin(note),
                          )),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNote() async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const NoteEditPage()),
    );

    if (result != null) {
      await _repository.insert(result);
      _loadNotes();
    }
  }

  Future<void> _editNote(Note note) async {
    final result = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => NoteEditPage(note: note)),
    );

    if (result != null) {
      await _repository.update(result);
      _loadNotes();
    }
  }

  Future<void> _deleteNote(Note note) async {
    await _repository.delete(note.id!);
    _loadNotes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${note.title}" gelöscht')),
      );
    }
  }

  Future<void> _togglePin(Note note) async {
    await _repository.togglePinned(note.id!);
    _loadNotes();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suchen'),
          content: TextField(
            onChanged: (value) {
              _searchQuery = value;
              _loadNotes();
            },
            decoration: const InputDecoration(hintText: 'Suchbegriff...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _searchQuery = '';
                _loadNotes();
                Navigator.pop(context);
              },
              child: const Text('Zurücksetzen'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Schließen'),
            ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final Note note;
  final Color color;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const _NoteCard({
    required this.note,
    required this.color,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        color: color,
        child: ListTile(
          leading: note.isPinned
              ? const Icon(Icons.push_pin, size: 20)
              : null,
          title: Text(note.title),
          subtitle: note.content.isNotEmpty
              ? Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          onTap: onTap,
          onLongPress: onTogglePin,
        ),
      ),
    );
  }
}
```

---

## Hive Lösung

### note.dart (Hive)

```dart
import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  late int color;

  @HiveField(4)
  late bool isPinned;

  @HiveField(5)
  late DateTime createdAt;

  @HiveField(6)
  late DateTime updatedAt;

  Note({
    String? id,
    required this.title,
    this.content = '',
    this.color = 0,
    this.isPinned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    this.createdAt = createdAt ?? DateTime.now();
    this.updatedAt = updatedAt ?? DateTime.now();
  }
}
```

### note_repository.dart (Hive)

```dart
import 'package:hive/hive.dart';
import 'note.dart';

class NoteRepository {
  static const _boxName = 'notes';

  Box<Note> get _box => Hive.box<Note>(_boxName);

  Future<void> add(Note note) async {
    await _box.put(note.id, note);
  }

  List<Note> getAll() {
    final notes = _box.values.toList();
    notes.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return notes;
  }

  Note? getById(String id) => _box.get(id);

  Future<void> update(Note note) async {
    note.updatedAt = DateTime.now();
    await note.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<Note> search(String query) {
    final lowerQuery = query.toLowerCase();
    return _box.values.where((note) {
      return note.title.toLowerCase().contains(lowerQuery) ||
          note.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<Note> getPinned() {
    return _box.values.where((note) => note.isPinned).toList();
  }
}
```

### Reactive UI mit Hive

```dart
class NotesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notizen')),
      body: ValueListenableBuilder<Box<Note>>(
        valueListenable: Hive.box<Note>('notes').listenable(),
        builder: (context, box, _) {
          final notes = box.values.toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(note: note);
            },
          );
        },
      ),
    );
  }
}
```

---

## Aufgabe 5: Vergleich

| Kriterium | sqflite | Hive |
|-----------|---------|------|
| Setup-Aufwand | Mittel (SQL Schema) | Niedrig (Annotations) |
| Code-Menge | Mehr (SQL Queries) | Weniger (Dart API) |
| Performance | Gut | Sehr gut |
| Flexibilität | Hoch (SQL) | Mittel |
| Reaktive UI | Manuell | `listenable()` |
| Lernkurve | Mittel (SQL) | Niedrig |

**Empfehlung für diese App:** Hive, wegen einfacherem Setup und reaktiver UI.
