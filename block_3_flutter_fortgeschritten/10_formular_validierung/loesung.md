# Lösung 3.10: Formular-Validierung

## Aufgabe 1: Validators Klasse

```dart
class Validators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Dieses Feld ist erforderlich';
    }
    return null;
  }

  static String? Function(String?) minLength(int length) {
    return (value) {
      if (value != null && value.length < length) {
        return 'Mindestens $length Zeichen erforderlich';
      }
      return null;
    };
  }

  static String? Function(String?) maxLength(int length) {
    return (value) {
      if (value != null && value.length > length) {
        return 'Maximal $length Zeichen erlaubt';
      }
      return null;
    };
  }

  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;

    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) {
      return 'Ungültige E-Mail Adresse';
    }
    return null;
  }

  static String? numeric(String? value) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Nur Zahlen erlaubt';
    }
    return null;
  }

  static String? alpha(String? value) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value)) {
      return 'Nur Buchstaben erlaubt';
    }
    return null;
  }

  static String? alphanumeric(String? value) {
    if (value == null || value.isEmpty) return null;

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'Nur Buchstaben und Zahlen erlaubt';
    }
    return null;
  }

  static String? Function(String?) pattern(RegExp regex, String message) {
    return (value) {
      if (value != null && value.isNotEmpty && !regex.hasMatch(value)) {
        return message;
      }
      return null;
    };
  }

  static String? Function(String?) combine(
      List<String? Function(String?)> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
```

---

## Aufgabe 2: Passwort-Validierung mit Live-Feedback

```dart
class PasswordRequirement {
  final String label;
  final bool Function(String) check;

  PasswordRequirement(this.label, this.check);
}

class PasswordFieldWithRequirements extends StatefulWidget {
  final TextEditingController controller;

  const PasswordFieldWithRequirements({
    super.key,
    required this.controller,
  });

  @override
  State<PasswordFieldWithRequirements> createState() =>
      _PasswordFieldWithRequirementsState();
}

class _PasswordFieldWithRequirementsState
    extends State<PasswordFieldWithRequirements> {
  bool _obscure = true;
  String _password = '';

  final _requirements = [
    PasswordRequirement('Mindestens 8 Zeichen', (p) => p.length >= 8),
    PasswordRequirement('Großbuchstabe', (p) => p.contains(RegExp(r'[A-Z]'))),
    PasswordRequirement('Kleinbuchstabe', (p) => p.contains(RegExp(r'[a-z]'))),
    PasswordRequirement('Zahl', (p) => p.contains(RegExp(r'[0-9]'))),
    PasswordRequirement(
        'Sonderzeichen', (p) => p.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
  ];

  int get _fulfilledCount =>
      _requirements.where((r) => r.check(_password)).length;

  double get _strength => _requirements.isEmpty
      ? 0
      : _fulfilledCount / _requirements.length;

  String get _strengthLabel {
    if (_strength < 0.4) return 'Schwach';
    if (_strength < 0.8) return 'Mittel';
    return 'Stark';
  }

  Color get _strengthColor {
    if (_strength < 0.4) return Colors.red;
    if (_strength < 0.8) return Colors.orange;
    return Colors.green;
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() => _password = widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Passwort',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: (value) {
            if (_fulfilledCount < _requirements.length) {
              return 'Nicht alle Anforderungen erfüllt';
            }
            return null;
          },
        ),
        if (_password.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Anforderungen:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._requirements.map((req) {
            final fulfilled = req.check(_password);
            return Row(
              children: [
                Icon(
                  fulfilled ? Icons.check_circle : Icons.cancel,
                  color: fulfilled ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(req.label),
              ],
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: _strength,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(_strengthColor),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stärke: $_strengthLabel',
                style: TextStyle(
                  color: _strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
```

---

## Aufgabe 3: Registrierungsformular

```dart
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  DateTime? _birthDate;
  bool _acceptTerms = false;

  String? _usernameAsyncError;
  bool _checkingUsername = false;
  Timer? _debounce;

  Future<void> _checkUsername(String username) async {
    setState(() {
      _checkingUsername = true;
      _usernameAsyncError = null;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final taken = ['admin', 'test', 'user'].contains(username.toLowerCase());

    setState(() {
      _checkingUsername = false;
      _usernameAsyncError = taken ? 'Benutzername bereits vergeben' : null;
    });
  }

  void _submit() {
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte AGBs akzeptieren')),
      );
      return;
    }

    if (_formKey.currentState!.validate() && _usernameAsyncError == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung erfolgreich!')),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrierung')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Benutzername
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Benutzername',
                  border: const OutlineInputBorder(),
                  errorText: _usernameAsyncError,
                  suffixIcon: _checkingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _usernameAsyncError == null &&
                              _usernameController.text.length >= 3
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
                validator: Validators.combine([
                  Validators.required,
                  Validators.minLength(3),
                  Validators.maxLength(20),
                  Validators.pattern(
                    RegExp(r'^[a-zA-Z0-9_]+$'),
                    'Nur Buchstaben, Zahlen und Unterstriche',
                  ),
                ]),
              ),
              const SizedBox(height: 16),

              // E-Mail
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: Validators.combine([
                  Validators.required,
                  Validators.email,
                ]),
              ),
              const SizedBox(height: 16),

              // Passwort
              PasswordFieldWithRequirements(controller: _passwordController),
              const SizedBox(height: 16),

              // Passwort bestätigen
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(
                  labelText: 'Passwort bestätigen',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _passwordController.text) {
                    return 'Passwörter stimmen nicht überein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Geburtsdatum
              ListTile(
                title: Text(_birthDate == null
                    ? 'Geburtsdatum wählen'
                    : 'Geburtsdatum: ${_birthDate!.day}.${_birthDate!.month}.${_birthDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(
                      const Duration(days: 365 * 18),
                    ),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _birthDate = date);
                  }
                },
              ),
              if (_birthDate != null)
                Builder(
                  builder: (context) {
                    final age = DateTime.now().year - _birthDate!.year;
                    if (age < 13) {
                      return const Text(
                        'Du musst mindestens 13 Jahre alt sein',
                        style: TextStyle(color: Colors.red),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              const SizedBox(height: 16),

              // AGBs
              CheckboxListTile(
                title: const Text('Ich akzeptiere die AGBs'),
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() => _acceptTerms = value ?? false);
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('Registrieren'),
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

## Aufgabe 5: AutovalidateMode Vergleich

| Modus | Verhalten | Beste Verwendung |
|-------|-----------|------------------|
| `disabled` | Validiert nur bei `validate()` Aufruf | Standard-Formulare, Fehler erst bei Submit zeigen |
| `always` | Validiert bei jeder Eingabe sofort | Echtzeit-Feedback wichtig, aber kann störend sein |
| `onUserInteraction` | Validiert nach erster Interaktion | Bester Kompromiss - keine Fehler bei leerem Formular, aber Feedback nach Eingabe |

**Empfehlung:** Start mit `disabled`, nach erstem Submit auf `onUserInteraction` wechseln:

```dart
var _autovalidate = AutovalidateMode.disabled;

void _submit() {
  if (_formKey.currentState!.validate()) {
    // Success
  } else {
    setState(() {
      _autovalidate = AutovalidateMode.onUserInteraction;
    });
  }
}
```
