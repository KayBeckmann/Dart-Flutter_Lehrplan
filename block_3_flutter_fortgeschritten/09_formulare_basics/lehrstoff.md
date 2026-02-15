# Einheit 3.9: Formulare Basics

## Lernziele

Nach dieser Einheit kannst du:
- `Form` und `GlobalKey<FormState>` verwenden
- `TextFormField` mit `InputDecoration` gestalten
- `TextEditingController` für Eingabekontrolle nutzen
- Formulardaten auslesen und verarbeiten

---

## 1. Form Widget Grundlagen

### Einfaches Formular

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  // GlobalKey für Formular-Zugriff
  final _formKey = GlobalKey<FormState>();

  // Controller für Eingabefelder
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Wichtig: Controller freigeben
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Validierung auslösen
    if (_formKey.currentState!.validate()) {
      // Formular ist gültig
      final email = _emailController.text;
      final password = _passwordController.text;

      print('Login: $email / $password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'E-Mail',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte E-Mail eingeben';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Passwort',
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte Passwort eingeben';
              }
              return null;
            },
          ),
          ElevatedButton(
            onPressed: _submit,
            child: const Text('Anmelden'),
          ),
        ],
      ),
    );
  }
}
```

---

## 2. TextEditingController

### Grundlegende Verwendung

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialer Wert
    _controller.text = 'Startwert';

    // Auf Änderungen reagieren
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    print('Text: ${_controller.text}');
    print('Cursor: ${_controller.selection}');
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: (value) {
        // Alternative zu addListener
        print('Geändert: $value');
      },
    );
  }
}
```

### Controller Methoden

```dart
// Text setzen
_controller.text = 'Neuer Text';

// Text lesen
final text = _controller.text;

// Text leeren
_controller.clear();

// Cursor-Position setzen
_controller.selection = TextSelection.fromPosition(
  TextPosition(offset: _controller.text.length),
);

// Bereich selektieren
_controller.selection = TextSelection(
  baseOffset: 0,
  extentOffset: 5,
);
```

---

## 3. InputDecoration im Detail

```dart
TextFormField(
  decoration: InputDecoration(
    // Labels
    labelText: 'E-Mail',
    hintText: 'name@example.com',
    helperText: 'Deine geschäftliche E-Mail',

    // Icons
    prefixIcon: const Icon(Icons.email),
    suffixIcon: IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => _controller.clear(),
    ),

    // Prefix/Suffix Text
    prefixText: 'https://',
    suffixText: '.com',

    // Rahmen
    border: const OutlineInputBorder(),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red),
    ),

    // Styling
    filled: true,
    fillColor: Colors.grey[100],

    // Counter
    counterText: '0/100',

    // Constraints
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 12,
    ),
  ),
);
```

### Underline vs. Outline

```dart
// Underline (Standard)
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Standard',
  ),
);

// Outline
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Outlined',
    border: OutlineInputBorder(),
  ),
);

// Ohne Rahmen
TextFormField(
  decoration: const InputDecoration(
    labelText: 'Borderless',
    border: InputBorder.none,
    filled: true,
  ),
);
```

---

## 4. Keyboard Types

```dart
// E-Mail
TextFormField(
  keyboardType: TextInputType.emailAddress,
);

// Zahlen
TextFormField(
  keyboardType: TextInputType.number,
);

// Telefon
TextFormField(
  keyboardType: TextInputType.phone,
);

// URL
TextFormField(
  keyboardType: TextInputType.url,
);

// Multiline
TextFormField(
  keyboardType: TextInputType.multiline,
  maxLines: 5,
);

// Dezimalzahlen
TextFormField(
  keyboardType: const TextInputType.numberWithOptions(decimal: true),
);
```

---

## 5. TextInputAction

```dart
// Standard Enter-Taste Verhalten ändern
TextFormField(
  textInputAction: TextInputAction.next,  // Zum nächsten Feld
  onFieldSubmitted: (_) {
    FocusScope.of(context).nextFocus();
  },
);

TextFormField(
  textInputAction: TextInputAction.done,  // Tastatur schließen
  onFieldSubmitted: (_) {
    FocusScope.of(context).unfocus();
  },
);

TextFormField(
  textInputAction: TextInputAction.search,  // Suche starten
  onFieldSubmitted: (query) {
    _performSearch(query);
  },
);

TextFormField(
  textInputAction: TextInputAction.send,  // Nachricht senden
  onFieldSubmitted: (_) {
    _sendMessage();
  },
);
```

---

## 6. FocusNode

```dart
class FocusDemo extends StatefulWidget {
  @override
  State<FocusDemo> createState() => _FocusDemoState();
}

class _FocusDemoState extends State<FocusDemo> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          focusNode: _emailFocus,
          textInputAction: TextInputAction.next,
          onFieldSubmitted: (_) {
            // Fokus zum nächsten Feld
            FocusScope.of(context).requestFocus(_passwordFocus);
          },
          decoration: const InputDecoration(labelText: 'E-Mail'),
        ),
        TextFormField(
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Passwort'),
        ),
        ElevatedButton(
          onPressed: () {
            // Fokus auf E-Mail Feld setzen
            _emailFocus.requestFocus();
          },
          child: const Text('E-Mail fokussieren'),
        ),
      ],
    );
  }
}
```

---

## 7. Formular speichern und zurücksetzen

```dart
class ContactForm extends StatefulWidget {
  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Formular speichern (für onSaved Callbacks)
      _formKey.currentState!.save();

      // Daten verarbeiten
      _sendMessage();
    }
  }

  void _reset() {
    // Formular zurücksetzen
    _formKey.currentState!.reset();

    // Controller leeren
    _nameController.clear();
    _emailController.clear();
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (value) => value!.isEmpty ? 'Pflichtfeld' : null,
            onSaved: (value) {
              // Wird bei save() aufgerufen
              print('Name gespeichert: $value');
            },
          ),
          // Weitere Felder...
          Row(
            children: [
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Senden'),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('Zurücksetzen'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 8. AutovalidateMode

```dart
Form(
  key: _formKey,
  // Validierung nur bei Submit
  autovalidateMode: AutovalidateMode.disabled,

  // Validierung sofort bei Eingabe
  // autovalidateMode: AutovalidateMode.always,

  // Validierung nach erstem Submit
  // autovalidateMode: AutovalidateMode.onUserInteraction,

  child: // ...
);
```

---

## 9. Vollständiges Beispiel

```dart
class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key});

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simuliere API-Call
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung erfolgreich!')),
      );
    }
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
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_emailFocus);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name ist erforderlich';
                  }
                  if (value.length < 2) {
                    return 'Name muss mindestens 2 Zeichen haben';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // E-Mail
              TextFormField(
                controller: _emailController,
                focusNode: _emailFocus,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocus);
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-Mail ist erforderlich';
                  }
                  if (!value.contains('@')) {
                    return 'Ungültige E-Mail';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Passwort
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Passwort ist erforderlich';
                  }
                  if (value.length < 8) {
                    return 'Mindestens 8 Zeichen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Registrieren'),
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

## Zusammenfassung

| Element | Verwendung |
|---------|-----------|
| `Form` | Container für Formularfelder |
| `GlobalKey<FormState>` | Zugriff auf `validate()`, `save()`, `reset()` |
| `TextFormField` | Eingabefeld mit Validierung |
| `TextEditingController` | Text lesen/schreiben, Cursor |
| `FocusNode` | Fokus-Steuerung |
| `InputDecoration` | Styling des Eingabefelds |

**Merke:**
- Controller und FocusNodes immer in `dispose()` freigeben
- `validate()` vor Verarbeitung aufrufen
- `textInputAction` für bessere UX
