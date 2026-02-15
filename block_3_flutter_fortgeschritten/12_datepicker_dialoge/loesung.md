# Lösung 3.12: DatePicker, TimePicker & Dialoge

## Aufgabe 1: DatePicker Integration

```dart
class AppointmentForm extends StatefulWidget {
  const AppointmentForm({super.key});

  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String _duration = '1 Stunde';

  final _durations = ['30 Minuten', '1 Stunde', '1.5 Stunden', '2 Stunden'];

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      selectableDayPredicate: (date) {
        // Wochenenden deaktivieren
        return date.weekday != DateTime.saturday &&
               date.weekday != DateTime.sunday;
      },
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (time != null) {
      // Auf 15-Minuten-Schritte runden
      final roundedMinute = (time.minute / 15).round() * 15;
      setState(() {
        _selectedTime = TimeOfDay(
          hour: time.hour,
          minute: roundedMinute % 60,
        );
      });
    }
  }

  String get _formattedDate {
    if (_selectedDate == null) return 'Datum auswählen';
    return '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}';
  }

  String get _formattedTime {
    if (_selectedTime == null) return 'Zeit auswählen';
    return '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
           '${_selectedTime!.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Neuer Termin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Datum
            ListTile(
              title: const Text('Datum'),
              trailing: Text(_formattedDate),
              leading: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),

            // Uhrzeit
            ListTile(
              title: const Text('Uhrzeit'),
              trailing: Text(_formattedTime),
              leading: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),

            // Dauer
            ListTile(
              title: const Text('Dauer'),
              leading: const Icon(Icons.timelapse),
              trailing: DropdownButton<String>(
                value: _duration,
                underline: const SizedBox(),
                items: _durations.map((d) {
                  return DropdownMenuItem(value: d, child: Text(d));
                }).toList(),
                onChanged: (v) => setState(() => _duration = v!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Aufgabe 4: Debounced Search

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

class ContactSearch extends StatefulWidget {
  const ContactSearch({super.key});

  @override
  State<ContactSearch> createState() => _ContactSearchState();
}

class _ContactSearchState extends State<ContactSearch> {
  final _controller = TextEditingController();
  final _debouncer = Debouncer();

  List<String> _results = [];
  bool _isLoading = false;
  String _query = '';

  Future<List<String>> _searchContacts(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final contacts = [
      'Max Mustermann', 'Maria Müller', 'Michael Meyer',
      'Anna Schmidt', 'Andreas Fischer', 'Petra Wagner',
    ];

    if (query.isEmpty) return [];

    return contacts
        .where((c) => c.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _onSearchChanged(String value) {
    _query = value;

    if (value.isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    _debouncer.run(() async {
      final results = await _searchContacts(value);
      if (_query == value) {  // Nur wenn noch aktuell
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _debouncer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Kontakt suchen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? const Center(child: Text('Suchbegriff eingeben'))
              : _results.isEmpty && !_isLoading
                  ? const Center(child: Text('Keine Ergebnisse'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(_results[index]),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
```

---

## Aufgabe 5: Custom Rating Dialog

```dart
Future<(int, String?)?> showRatingDialog(BuildContext context) async {
  return await showDialog<(int, String?)>(
    context: context,
    builder: (context) => const _RatingDialog(),
  );
}

class _RatingDialog extends StatefulWidget {
  const _RatingDialog();

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bewertung', textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sterne
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 36,
                ),
                onPressed: () {
                  setState(() => _rating = index + 1);
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          // Kommentar
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              hintText: 'Dein Kommentar (optional)...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _rating > 0
              ? () {
                  final comment = _commentController.text.trim();
                  Navigator.pop(
                    context,
                    (_rating, comment.isEmpty ? null : comment),
                  );
                }
              : null,
          child: const Text('Bewerten'),
        ),
      ],
    );
  }
}

// Verwendung
void _showRating() async {
  final result = await showRatingDialog(context);
  if (result != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Danke für deine ${result.$1}-Sterne Bewertung!'),
      ),
    );
  }
}
```

---

## Aufgabe 6: Snackbar Actions

```dart
class SnackbarExamples {
  static void showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Termin gespeichert'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void showWarning(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Offline-Modus aktiv'),
        backgroundColor: Colors.orange,
        duration: const Duration(days: 1),  // Persistent
        action: SnackBarAction(
          label: 'Einstellungen',
          textColor: Colors.white,
          onPressed: () {
            // Öffne Einstellungen
          },
        ),
      ),
    );
  }

  static void showError(BuildContext context, VoidCallback onRetry) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Speichern fehlgeschlagen'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Erneut versuchen',
          textColor: Colors.white,
          onPressed: onRetry,
        ),
      ),
    );
  }

  static void showUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Rückgängig',
          onPressed: onUndo,
        ),
      ),
    );
  }
}

// Verwendung
void _deleteAppointment(Appointment apt) {
  // Temporär entfernen
  setState(() => _appointments.remove(apt));

  SnackbarExamples.showUndo(
    context,
    'Termin gelöscht',
    () {
      // Rückgängig machen
      setState(() => _appointments.add(apt));
    },
  );
}
```

---

## Aufgabe 2: Bottom Sheet für Aktionen

```dart
void _showAppointmentActions(Appointment appointment) {
  showModalBottomSheet(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Details anzeigen'),
            onTap: () {
              Navigator.pop(context);
              _showDetails(appointment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Bearbeiten'),
            onTap: () {
              Navigator.pop(context);
              _editAppointment(appointment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Verschieben'),
            onTap: () {
              Navigator.pop(context);
              _rescheduleAppointment(appointment);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Löschen', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(appointment);
            },
          ),
        ],
      ),
    ),
  );
}

Future<void> _confirmDelete(Appointment appointment) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Termin löschen?'),
      content: Text('Möchtest du "${appointment.title}" wirklich löschen?'),
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

  if (confirmed == true) {
    _deleteAppointment(appointment);
  }
}
```
