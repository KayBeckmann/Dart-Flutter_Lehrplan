# Einheit 3.10: Formular-Validierung

## Lernziele

Nach dieser Einheit kannst du:
- Validatoren für verschiedene Eingabetypen schreiben
- Regex-Validierung anwenden
- Cross-Field-Validierung implementieren
- AutovalidateMode sinnvoll einsetzen
- Async-Validierung durchführen

---

## 1. Validator Grundlagen

### Validator Signatur

```dart
String? validator(String? value) {
  // Gibt null zurück wenn gültig
  // Gibt Fehlermeldung zurück wenn ungültig
}
```

### Einfache Validatoren

```dart
// Pflichtfeld
String? requiredValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Dieses Feld ist erforderlich';
  }
  return null;
}

// Mindestlänge
String? minLengthValidator(String? value, int minLength) {
  if (value == null || value.length < minLength) {
    return 'Mindestens $minLength Zeichen';
  }
  return null;
}

// Maximallänge
String? maxLengthValidator(String? value, int maxLength) {
  if (value != null && value.length > maxLength) {
    return 'Maximal $maxLength Zeichen';
  }
  return null;
}
```

---

## 2. Regex-Validierung

### E-Mail Validierung

```dart
String? emailValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'E-Mail ist erforderlich';
  }

  // Einfache Regex
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  if (!emailRegex.hasMatch(value)) {
    return 'Ungültige E-Mail Adresse';
  }

  return null;
}
```

### Passwort Validierung

```dart
String? passwordValidator(String? value) {
  if (value == null || value.isEmpty) {
    return 'Passwort ist erforderlich';
  }

  final errors = <String>[];

  if (value.length < 8) {
    errors.add('mindestens 8 Zeichen');
  }
  if (!value.contains(RegExp(r'[A-Z]'))) {
    errors.add('einen Großbuchstaben');
  }
  if (!value.contains(RegExp(r'[a-z]'))) {
    errors.add('einen Kleinbuchstaben');
  }
  if (!value.contains(RegExp(r'[0-9]'))) {
    errors.add('eine Zahl');
  }
  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
    errors.add('ein Sonderzeichen');
  }

  if (errors.isNotEmpty) {
    return 'Passwort benötigt: ${errors.join(', ')}';
  }

  return null;
}
```

### Telefonnummer

```dart
String? phoneValidator(String? value) {
  if (value == null || value.isEmpty) return null;  // Optional

  // Nur Ziffern, Leerzeichen, +, -, ()
  final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

  if (!RegExp(r'^\+?[0-9]{6,15}$').hasMatch(cleaned)) {
    return 'Ungültige Telefonnummer';
  }

  return null;
}
```

### URL Validierung

```dart
String? urlValidator(String? value) {
  if (value == null || value.isEmpty) return null;

  final urlRegex = RegExp(
    r'^https?://'
    r'([\w-]+\.)+[\w-]+'
    r'(/[\w-./?%&=]*)?$',
    caseSensitive: false,
  );

  if (!urlRegex.hasMatch(value)) {
    return 'Ungültige URL';
  }

  return null;
}
```

---

## 3. Validator Kombinieren

### Validator-Chain

```dart
class Validators {
  static String? Function(String?) combine(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  static String? required(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pflichtfeld';
    }
    return null;
  }

  static String? Function(String?) minLength(int length) {
    return (value) {
      if (value != null && value.length < length) {
        return 'Mindestens $length Zeichen';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int length) {
    return (value) {
      if (value != null && value.length > length) {
        return 'Maximal $length Zeichen';
      }
      return null;
    };
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Ungültige E-Mail';
    }
    return null;
  }

  static String? Function(String?) pattern(RegExp regex, String message) {
    return (value) {
      if (value != null && !regex.hasMatch(value)) {
        return message;
      }
      return null;
    };
  }
}

// Verwendung
TextFormField(
  validator: Validators.combine([
    Validators.required,
    Validators.minLength(3),
    Validators.maxLength(20),
    Validators.pattern(
      RegExp(r'^[a-zA-Z]+$'),
      'Nur Buchstaben erlaubt',
    ),
  ]),
);
```

---

## 4. Cross-Field Validierung

### Passwort Bestätigung

```dart
class PasswordForm extends StatefulWidget {
  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: 'Passwort'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 8) {
                return 'Mindestens 8 Zeichen';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _confirmController,
            decoration: const InputDecoration(labelText: 'Passwort bestätigen'),
            obscureText: true,
            validator: (value) {
              if (value != _passwordController.text) {
                return 'Passwörter stimmen nicht überein';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
```

### Datum-Validierung (Start < Ende)

```dart
class DateRangeForm extends StatefulWidget {
  @override
  State<DateRangeForm> createState() => _DateRangeFormState();
}

class _DateRangeFormState extends State<DateRangeForm> {
  DateTime? _startDate;
  DateTime? _endDate;

  String? _validateStartDate(DateTime? value) {
    if (value == null) return 'Startdatum erforderlich';
    if (_endDate != null && value.isAfter(_endDate!)) {
      return 'Startdatum muss vor Enddatum liegen';
    }
    return null;
  }

  String? _validateEndDate(DateTime? value) {
    if (value == null) return 'Enddatum erforderlich';
    if (_startDate != null && value.isBefore(_startDate!)) {
      return 'Enddatum muss nach Startdatum liegen';
    }
    return null;
  }
}
```

---

## 5. AutovalidateMode

```dart
Form(
  // Nie automatisch validieren
  autovalidateMode: AutovalidateMode.disabled,

  // Immer validieren (bei jeder Eingabe)
  autovalidateMode: AutovalidateMode.always,

  // Nach erster User-Interaktion
  autovalidateMode: AutovalidateMode.onUserInteraction,
)
```

### Dynamisch umschalten

```dart
class SmartForm extends StatefulWidget {
  @override
  State<SmartForm> createState() => _SmartFormState();
}

class _SmartFormState extends State<SmartForm> {
  final _formKey = GlobalKey<FormState>();
  var _autovalidate = AutovalidateMode.disabled;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Success
    } else {
      // Nach erstem Submit: Autovalidierung aktivieren
      setState(() {
        _autovalidate = AutovalidateMode.onUserInteraction;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: _autovalidate,
      child: Column(
        children: [
          TextFormField(
            validator: (v) => v!.isEmpty ? 'Erforderlich' : null,
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. Async Validierung

### Benutzername Verfügbarkeit

```dart
class UsernameField extends StatefulWidget {
  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  final _controller = TextEditingController();
  String? _asyncError;
  bool _isChecking = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkUsername(String username) async {
    setState(() {
      _isChecking = true;
      _asyncError = null;
    });

    // Simuliere API-Call
    await Future.delayed(const Duration(milliseconds: 500));

    // Beispiel: "admin" ist vergeben
    final isAvailable = username.toLowerCase() != 'admin';

    setState(() {
      _isChecking = false;
      _asyncError = isAvailable ? null : 'Benutzername bereits vergeben';
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Benutzername',
        errorText: _asyncError,
        suffixIcon: _isChecking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : _asyncError == null && _controller.text.isNotEmpty
                ? const Icon(Icons.check, color: Colors.green)
                : null,
      ),
      onChanged: (value) {
        _debounce?.cancel();
        if (value.length >= 3) {
          _debounce = Timer(
            const Duration(milliseconds: 500),
            () => _checkUsername(value),
          );
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Benutzername erforderlich';
        }
        if (value.length < 3) {
          return 'Mindestens 3 Zeichen';
        }
        // Async-Fehler in Standard-Validator einbeziehen
        if (_asyncError != null) {
          return _asyncError;
        }
        return null;
      },
    );
  }
}
```

---

## 7. Form-Level Validierung

```dart
class PaymentForm extends StatefulWidget {
  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  String? _formError;

  String _cardNumber = '';
  String _expiry = '';
  String _cvv = '';

  void _submit() {
    setState(() => _formError = null);

    if (!_formKey.currentState!.validate()) return;

    // Form-Level Validierung
    if (_cardNumber.startsWith('4') && _cvv.length != 3) {
      setState(() => _formError = 'Visa-Karten benötigen 3-stelligen CVV');
      return;
    }

    // Expiry-Datum prüfen
    final parts = _expiry.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse('20${parts[1]}');

    if (month != null && year != null) {
      final expiry = DateTime(year, month + 1, 0);
      if (expiry.isBefore(DateTime.now())) {
        setState(() => _formError = 'Karte ist abgelaufen');
        return;
      }
    }

    // Alles OK
    print('Payment valid!');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_formError != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red[100],
              child: Text(
                _formError!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Kartennummer'),
            onChanged: (v) => _cardNumber = v,
            validator: (v) =>
                v!.length < 16 ? 'Ungültige Kartennummer' : null,
          ),
          // Weitere Felder...
          ElevatedButton(onPressed: _submit, child: const Text('Zahlen')),
        ],
      ),
    );
  }
}
```

---

## 8. Validator-Klasse Pattern

```dart
abstract class FormValidator<T> {
  String? validate(T? value);
}

class RequiredValidator implements FormValidator<String> {
  final String message;
  RequiredValidator([this.message = 'Pflichtfeld']);

  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return message;
    return null;
  }
}

class EmailValidator implements FormValidator<String> {
  @override
  String? validate(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!value.contains('@')) return 'Ungültige E-Mail';
    return null;
  }
}

class CompositeValidator implements FormValidator<String> {
  final List<FormValidator<String>> validators;

  CompositeValidator(this.validators);

  @override
  String? validate(String? value) {
    for (final v in validators) {
      final error = v.validate(value);
      if (error != null) return error;
    }
    return null;
  }
}

// Verwendung
final emailValidator = CompositeValidator([
  RequiredValidator('E-Mail erforderlich'),
  EmailValidator(),
]);

TextFormField(
  validator: emailValidator.validate,
);
```

---

## Zusammenfassung

| Konzept | Verwendung |
|---------|-----------|
| Einfache Validatoren | Pflichtfeld, Länge, Format |
| Regex | E-Mail, Telefon, Passwort-Regeln |
| Validator.combine | Mehrere Regeln kombinieren |
| Cross-Field | Passwort-Bestätigung, Datum-Bereiche |
| AutovalidateMode | Wann validiert wird |
| Async-Validierung | Server-Checks (Username, etc.) |
| Form-Level | Komplexe Abhängigkeiten |

**Best Practices:**
1. Wiederverwendbare Validator-Funktionen
2. User-freundliche Fehlermeldungen
3. Autovalidate erst nach erstem Submit
4. Async-Validierung mit Debounce
5. Form-Level für komplexe Logik
