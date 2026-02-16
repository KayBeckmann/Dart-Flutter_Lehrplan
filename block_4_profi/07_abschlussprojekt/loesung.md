# Referenzlösung: Abschlussprojekt NoteFlow

Diese Lösung zeigt die wichtigsten Code-Abschnitte. Eine vollständige Implementierung findest du im begleitenden Repository.

---

## Projektstruktur

```
noteflow/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── routes.dart
│   │   └── theme.dart
│   ├── models/
│   │   ├── note.dart
│   │   └── category.dart
│   ├── providers/
│   │   ├── notes_provider.dart
│   │   └── settings_provider.dart
│   ├── services/
│   │   └── storage_service.dart
│   ├── screens/
│   │   ├── home/
│   │   └── editor/
│   └── widgets/
│       └── note_card.dart
└── test/
    └── ...
```

---

## Models

### lib/models/note.dart

```dart
import 'package:hive/hive.dart';

part 'note.g.dart';

@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime updatedAt;

  @HiveField(5)
  String? categoryId;

  @HiveField(6)
  bool isPinned;

  @HiveField(7)
  bool isArchived;

  Note({
    required this.id,
    required this.title,
    this.content = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.categoryId,
    this.isPinned = false,
    this.isArchived = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? title,
    String? content,
    String? categoryId,
    bool? isPinned,
    bool? isArchived,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      categoryId: categoryId ?? this.categoryId,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'categoryId': categoryId,
        'isPinned': isPinned,
        'isArchived': isArchived,
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        title: json['title'],
        content: json['content'] ?? '',
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        categoryId: json['categoryId'],
        isPinned: json['isPinned'] ?? false,
        isArchived: json['isArchived'] ?? false,
      );
}
```

---

## Services

### lib/services/storage_service.dart

```dart
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';
import '../models/category.dart';

class StorageService {
  static const String _notesBox = 'notes';
  static const String _categoriesBox = 'categories';
  static const String _settingsBox = 'settings';

  late Box<Note> _notesBoxInstance;
  late Box<Category> _categoriesBoxInstance;
  late Box _settingsBoxInstance;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(NoteAdapter());
    Hive.registerAdapter(CategoryAdapter());

    _notesBoxInstance = await Hive.openBox<Note>(_notesBox);
    _categoriesBoxInstance = await Hive.openBox<Category>(_categoriesBox);
    _settingsBoxInstance = await Hive.openBox(_settingsBox);
  }

  // Notes
  List<Note> getAllNotes() {
    return _notesBoxInstance.values.toList();
  }

  Future<void> saveNote(Note note) async {
    await _notesBoxInstance.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBoxInstance.delete(id);
  }

  Note? getNote(String id) {
    return _notesBoxInstance.get(id);
  }

  // Categories
  List<Category> getAllCategories() {
    return _categoriesBoxInstance.values.toList();
  }

  Future<void> saveCategory(Category category) async {
    await _categoriesBoxInstance.put(category.id, category);
  }

  Future<void> deleteCategory(String id) async {
    await _categoriesBoxInstance.delete(id);
  }

  // Settings
  T? getSetting<T>(String key) {
    return _settingsBoxInstance.get(key) as T?;
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBoxInstance.put(key, value);
  }
}
```

---

## Providers

### lib/providers/notes_provider.dart

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());

final notesProvider =
    StateNotifierProvider<NotesNotifier, AsyncValue<List<Note>>>((ref) {
  return NotesNotifier(ref.read(storageServiceProvider));
});

class NotesNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final StorageService _storage;
  final _uuid = const Uuid();

  String? _searchQuery;
  String? _categoryFilter;

  NotesNotifier(this._storage) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  List<Note> _allNotes = [];

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      _allNotes = _storage.getAllNotes();
      _applyFilters();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _applyFilters() {
    var filtered = _allNotes.where((n) => !n.isArchived).toList();

    // Search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((n) {
        return n.title.toLowerCase().contains(query) ||
            n.content.toLowerCase().contains(query);
      }).toList();
    }

    // Category filter
    if (_categoryFilter != null) {
      filtered = filtered.where((n) => n.categoryId == _categoryFilter).toList();
    }

    // Sort: pinned first, then by updatedAt
    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    state = AsyncValue.data(filtered);
  }

  Future<Note> addNote({String? title, String? content}) async {
    final note = Note(
      id: _uuid.v4(),
      title: title ?? 'Neue Notiz',
      content: content ?? '',
    );

    await _storage.saveNote(note);
    _allNotes.add(note);
    _applyFilters();

    return note;
  }

  Future<void> updateNote(Note note) async {
    final updated = note.copyWith();
    await _storage.saveNote(updated);

    final index = _allNotes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _allNotes[index] = updated;
    }
    _applyFilters();
  }

  Future<void> deleteNote(String id) async {
    await _storage.deleteNote(id);
    _allNotes.removeWhere((n) => n.id == id);
    _applyFilters();
  }

  void togglePin(String id) {
    final index = _allNotes.indexWhere((n) => n.id == id);
    if (index != -1) {
      final note = _allNotes[index];
      updateNote(note.copyWith(isPinned: !note.isPinned));
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void filterByCategory(String? categoryId) {
    _categoryFilter = categoryId;
    _applyFilters();
  }
}
```

---

## Screens

### lib/screens/home/home_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(notesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NoteFlow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Fehler: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const _EmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(notesProvider.notifier).loadNotes(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notes.length,
              itemBuilder: (context, index) {
                final note = notes[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: NoteCard(
                    note: note,
                    onTap: () => context.push('/note/${note.id}'),
                    onTogglePin: () =>
                        ref.read(notesProvider.notifier).togglePin(note.id),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final note = await ref.read(notesProvider.notifier).addNote();
          if (context.mounted) {
            context.push('/note/${note.id}');
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.note_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Notizen',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tippe auf + um eine neue Notiz zu erstellen',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }
}
```

### lib/screens/editor/editor_screen.dart

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String noteId;

  const EditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Timer? _debounce;
  Note? _note;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  void _loadNote() {
    final storage = ref.read(storageServiceProvider);
    _note = storage.getNote(widget.noteId);

    if (_note != null) {
      _titleController.text = _note!.title;
      _contentController.text = _note!.content;
    }
  }

  void _onChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }

    _debounce?.cancel();
    _debounce = Timer(const Duration(seconds: 2), _save);
  }

  Future<void> _save() async {
    if (_note == null || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final updated = _note!.copyWith(
      title: _titleController.text,
      content: _contentController.text,
    );

    await ref.read(notesProvider.notifier).updateNote(updated);

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
      _note = updated;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Du hast ungespeicherte Änderungen. Möchtest du sie verwerfen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notiz löschen?'),
        content: Text('Möchtest du "${_note?.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(notesProvider.notifier).deleteNote(widget.noteId);
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_note == null ? 'Neue Notiz' : 'Bearbeiten'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_hasUnsavedChanges)
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _save,
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _delete,
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Titel',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Titel ist erforderlich';
                  }
                  if (value.length > 100) {
                    return 'Maximal 100 Zeichen';
                  }
                  return null;
                },
                onChanged: (_) => _onChanged(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Inhalt',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                minLines: 10,
                onChanged: (_) => _onChanged(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Widgets

### lib/widgets/note_card.dart

```dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onTogglePin;

  const NoteCard({
    super.key,
    required this.note,
    required this.onTap,
    required this.onTogglePin,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Heute, ${DateFormat.Hm().format(date)}';
    } else if (diff.inDays == 1) {
      return 'Gestern';
    } else if (diff.inDays < 7) {
      return DateFormat.EEEE('de').format(date);
    } else {
      return DateFormat.yMd('de').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: note.isPinned ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (note.isPinned)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 20,
                    ),
                    onPressed: onTogglePin,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              if (note.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _formatDate(note.updatedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Tests

### test/models/note_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/models/note.dart';

void main() {
  group('Note', () {
    test('creates with required fields', () {
      final note = Note(id: '1', title: 'Test');

      expect(note.id, '1');
      expect(note.title, 'Test');
      expect(note.content, '');
      expect(note.isPinned, false);
    });

    test('copyWith updates fields', () {
      final note = Note(id: '1', title: 'Original');
      final updated = note.copyWith(title: 'Updated', isPinned: true);

      expect(updated.title, 'Updated');
      expect(updated.isPinned, true);
      expect(updated.id, '1');
    });

    test('toJson and fromJson', () {
      final note = Note(
        id: '1',
        title: 'Test',
        content: 'Content',
        isPinned: true,
      );

      final json = note.toJson();
      final restored = Note.fromJson(json);

      expect(restored.id, note.id);
      expect(restored.title, note.title);
      expect(restored.isPinned, note.isPinned);
    });
  });
}
```

### test/widgets/note_card_test.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteflow/models/note.dart';
import 'package:noteflow/widgets/note_card.dart';

void main() {
  group('NoteCard', () {
    testWidgets('displays note title', (tester) async {
      final note = Note(id: '1', title: 'Test Title');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () {},
            onTogglePin: () {},
          ),
        ),
      ));

      expect(find.text('Test Title'), findsOneWidget);
    });

    testWidgets('shows pin icon when pinned', (tester) async {
      final note = Note(id: '1', title: 'Test', isPinned: true);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () {},
            onTogglePin: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      final note = Note(id: '1', title: 'Test');

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () => tapped = true,
            onTogglePin: () {},
          ),
        ),
      ));

      await tester.tap(find.byType(NoteCard));
      expect(tapped, true);
    });
  });
}
```
