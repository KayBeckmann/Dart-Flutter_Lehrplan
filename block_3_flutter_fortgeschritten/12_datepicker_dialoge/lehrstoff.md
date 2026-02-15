# Einheit 3.12: DatePicker, TimePicker & Dialoge

## Lernziele

Nach dieser Einheit kannst du:
- `showDatePicker` und `showTimePicker` verwenden
- Verschiedene Dialog-Typen einsetzen
- `BottomSheet` für mobile UX nutzen
- Debouncing für Input-Felder implementieren

---

## 1. DatePicker

### Einfacher DatePicker

```dart
class DatePickerDemo extends StatefulWidget {
  @override
  State<DatePickerDemo> createState() => _DatePickerDemoState();
}

class _DatePickerDemoState extends State<DatePickerDemo> {
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_selectedDate == null
          ? 'Datum auswählen'
          : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'),
      trailing: const Icon(Icons.calendar_today),
      onTap: _pickDate,
    );
  }
}
```

### DatePicker Optionen

```dart
final date = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),

  // Lokalisierung
  locale: const Locale('de', 'DE'),

  // Initiale Ansicht
  initialDatePickerMode: DatePickerMode.year,  // oder .day

  // Hilfetext
  helpText: 'Geburtsdatum auswählen',
  cancelText: 'Abbrechen',
  confirmText: 'OK',

  // Bestimmte Tage deaktivieren
  selectableDayPredicate: (date) {
    // Wochenenden deaktivieren
    return date.weekday != DateTime.saturday &&
           date.weekday != DateTime.sunday;
  },

  // Stil anpassen
  builder: (context, child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.blue,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
        ),
      ),
      child: child!,
    );
  },
);
```

### Date Range Picker

```dart
Future<void> _pickDateRange() async {
  final range = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    initialDateRange: DateTimeRange(
      start: DateTime.now(),
      end: DateTime.now().add(const Duration(days: 7)),
    ),
    helpText: 'Zeitraum auswählen',
    saveText: 'Speichern',
  );

  if (range != null) {
    print('Von: ${range.start} bis ${range.end}');
  }
}
```

---

## 2. TimePicker

### Einfacher TimePicker

```dart
class TimePickerDemo extends StatefulWidget {
  @override
  State<TimePickerDemo> createState() => _TimePickerDemoState();
}

class _TimePickerDemoState extends State<TimePickerDemo> {
  TimeOfDay? _selectedTime;

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  String get _formattedTime {
    if (_selectedTime == null) return 'Zeit auswählen';
    final hour = _selectedTime!.hour.toString().padLeft(2, '0');
    final minute = _selectedTime!.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(_formattedTime),
      trailing: const Icon(Icons.access_time),
      onTap: _pickTime,
    );
  }
}
```

### TimePicker Optionen

```dart
final time = await showTimePicker(
  context: context,
  initialTime: TimeOfDay.now(),

  // 24h Format erzwingen
  builder: (context, child) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        alwaysUse24HourFormat: true,
      ),
      child: child!,
    );
  },

  // Hilfetext
  helpText: 'Uhrzeit wählen',
  cancelText: 'Abbrechen',
  confirmText: 'OK',

  // Einstiegsmodus
  initialEntryMode: TimePickerEntryMode.input,  // oder .dial
);
```

---

## 3. AlertDialog

### Einfacher Alert

```dart
void _showAlert() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Hinweis'),
      content: const Text('Das ist eine wichtige Nachricht.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

### Bestätigungsdialog

```dart
Future<bool> _showConfirmDialog() async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,  // Muss mit Button geschlossen werden
    builder: (context) => AlertDialog(
      title: const Text('Löschen bestätigen'),
      content: const Text('Möchtest du dieses Element wirklich löschen?'),
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

  return result ?? false;
}

// Verwendung
void _deleteItem() async {
  final confirmed = await _showConfirmDialog();
  if (confirmed) {
    // Löschen durchführen
  }
}
```

### Dialog mit Eingabefeld

```dart
Future<String?> _showInputDialog() async {
  final controller = TextEditingController();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Name eingeben'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Dein Name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  return result;
}
```

---

## 4. SimpleDialog

### Auswahlliste

```dart
Future<String?> _showSelectionDialog() async {
  return await showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Kategorie wählen'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'arbeit'),
          child: const ListTile(
            leading: Icon(Icons.work),
            title: Text('Arbeit'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'privat'),
          child: const ListTile(
            leading: Icon(Icons.home),
            title: Text('Privat'),
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, 'einkauf'),
          child: const ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Einkauf'),
          ),
        ),
      ],
    ),
  );
}
```

---

## 5. BottomSheet

### Modal Bottom Sheet

```dart
void _showBottomSheet() {
  showModalBottomSheet(
    context: context,
    builder: (context) => Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Teilen'),
            onTap: () {
              Navigator.pop(context);
              // Teilen-Logik
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Bearbeiten'),
            onTap: () {
              Navigator.pop(context);
              // Bearbeiten-Logik
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Löschen'),
            onTap: () {
              Navigator.pop(context);
              // Löschen-Logik
            },
          ),
        ],
      ),
    ),
  );
}
```

### Scrollbares Bottom Sheet

```dart
void _showScrollableBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // Wichtig für DraggableScrollableSheet
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView.builder(
            controller: scrollController,
            itemCount: 50,
            itemBuilder: (context, index) => ListTile(
              title: Text('Item $index'),
            ),
          ),
        );
      },
    ),
  );
}
```

### Bottom Sheet mit Formular

```dart
void _showFormBottomSheet() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,  // Keyboard-aware
    builder: (context) => Padding(
      // Keyboard-Abstand
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Neue Notiz',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Titel',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Inhalt',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Speichern'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

---

## 6. Snackbar

```dart
// Einfache Snackbar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Gespeichert!')),
);

// Mit Action
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Element gelöscht'),
    action: SnackBarAction(
      label: 'Rückgängig',
      onPressed: () {
        // Rückgängig-Logik
      },
    ),
    duration: const Duration(seconds: 5),
  ),
);

// Mit Styling
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Fehler aufgetreten'),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    margin: const EdgeInsets.all(16),
  ),
);
```

---

## 7. Debouncing

### Für Suchfelder

```dart
class SearchField extends StatefulWidget {
  final void Function(String) onSearch;

  const SearchField({super.key, required this.onSearch});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Suchen...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
      ),
      onChanged: _onChanged,
    );
  }
}
```

### Debounce Utility

```dart
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() {
    _timer?.cancel();
  }
}

// Verwendung
final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

void _onTextChanged(String value) {
  _debouncer.run(() {
    // API-Call oder Filterung
    _performSearch(value);
  });
}

@override
void dispose() {
  _debouncer.cancel();
  super.dispose();
}
```

---

## 8. DatePicker als FormField

```dart
class DateFormField extends FormField<DateTime> {
  DateFormField({
    super.key,
    DateTime? initialValue,
    required BuildContext context,
    InputDecoration? decoration,
    String? Function(DateTime?)? validator,
    void Function(DateTime?)? onSaved,
  }) : super(
          initialValue: initialValue,
          validator: validator,
          onSaved: onSaved,
          builder: (state) {
            return InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: state.value ?? DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  state.didChange(date);
                }
              },
              child: InputDecorator(
                decoration: (decoration ?? const InputDecoration()).copyWith(
                  errorText: state.errorText,
                ),
                child: Text(
                  state.value == null
                      ? 'Datum auswählen'
                      : '${state.value!.day}.${state.value!.month}.${state.value!.year}',
                ),
              ),
            );
          },
        );
}
```

---

## Zusammenfassung

| Widget/Funktion | Verwendung |
|-----------------|-----------|
| `showDatePicker` | Datum auswählen |
| `showDateRangePicker` | Zeitraum auswählen |
| `showTimePicker` | Uhrzeit auswählen |
| `AlertDialog` | Hinweise, Bestätigungen |
| `SimpleDialog` | Einfache Auswahllisten |
| `showModalBottomSheet` | Mobile-freundliche Optionen |
| `SnackBar` | Kurzfristige Benachrichtigungen |
| `Debouncer` | Verzögerte Aktionen (Suche) |

**Best Practices:**
- Bottom Sheet für mobile UX bevorzugen
- Debounce für Suchfelder (300-500ms)
- Dialoge kurz halten
- `barrierDismissible: false` für wichtige Bestätigungen
