# Lösung 3.9: Formulare Basics

## Aufgabe 3 & 4: Kontaktformular

```dart
import 'package:flutter/material.dart';

class ContactFormData {
  final String name;
  final String email;
  final String? phone;
  final String subject;
  final String message;

  ContactFormData({
    required this.name,
    required this.email,
    this.phone,
    required this.subject,
    required this.message,
  });
}

class ContactFormPage extends StatefulWidget {
  const ContactFormPage({super.key});

  @override
  State<ContactFormPage> createState() => _ContactFormPageState();
}

class _ContactFormPageState extends State<ContactFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _subjectFocus = FocusNode();
  final _messageFocus = FocusNode();

  int _messageLength = 0;
  static const _maxMessageLength = 500;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        _messageLength = _messageController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _subjectFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final data = ContactFormData(
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      _showConfirmDialog(data);
    }
  }

  void _showConfirmDialog(ContactFormData data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nachricht senden?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${data.name}'),
            Text('E-Mail: ${data.email}'),
            if (data.phone != null) Text('Telefon: ${data.phone}'),
            Text('Betreff: ${data.subject}'),
            const Divider(),
            Text(data.message),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bearbeiten'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reset();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Nachricht gesendet!')),
              );
            },
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  void _reset() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _subjectController.clear();
    _messageController.clear();
    _nameFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kontakt')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocus,
                decoration: const InputDecoration(
                  labelText: 'Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Name ist erforderlich';
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
                  labelText: 'E-Mail *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_phoneFocus),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'E-Mail ist erforderlich';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ungültige E-Mail Adresse';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Telefon
              TextFormField(
                controller: _phoneController,
                focusNode: _phoneFocus,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '+49 123 456789',
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_subjectFocus),
              ),
              const SizedBox(height: 16),

              // Betreff
              TextFormField(
                controller: _subjectController,
                focusNode: _subjectFocus,
                decoration: const InputDecoration(
                  labelText: 'Betreff *',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_messageFocus),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Betreff ist erforderlich';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nachricht
              TextFormField(
                controller: _messageController,
                focusNode: _messageFocus,
                decoration: InputDecoration(
                  labelText: 'Nachricht *',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  counterText: '$_messageLength/$_maxMessageLength',
                ),
                maxLines: 5,
                maxLength: _maxMessageLength,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nachricht ist erforderlich';
                  }
                  if (value.length < 10) {
                    return 'Mindestens 10 Zeichen';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Zurücksetzen'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Absenden'),
                    ),
                  ),
                ],
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

## Aufgabe 5: Passwort mit Toggle und Stärke

```dart
class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({super.key, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            labelText: 'Passwort *',
            prefixIcon: const Icon(Icons.lock),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          obscureText: _obscure,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Passwort ist erforderlich';
            }
            if (value.length < 8) {
              return 'Mindestens 8 Zeichen';
            }
            if (!value.contains(RegExp(r'[0-9]'))) {
              return 'Mindestens eine Zahl';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        _PasswordStrengthIndicator(password: widget.controller.text),
      ],
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  int get _strength {
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  String get _label {
    switch (_strength) {
      case 0:
      case 1:
        return 'Schwach';
      case 2:
      case 3:
        return 'Mittel';
      default:
        return 'Stark';
    }
  }

  Color get _color {
    switch (_strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
      case 3:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: _strength / 5,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation(_color),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Stärke: $_label',
          style: TextStyle(color: _color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
```

---

## Verständnisfragen - Antworten

1. **Wann TextEditingController?**
   - Wenn man den Text programmatisch setzen will
   - Wenn man auf Änderungen reagieren will (addListener)
   - Wenn man die Cursor-Position steuern will
   - Wenn man den Text außerhalb von onChanged lesen will

2. **TextField vs. TextFormField?**
   - `TextField`: Basis-Widget ohne Validierung
   - `TextFormField`: Kann in `Form` verwendet werden, hat `validator`, `onSaved`
   - `TextFormField` ist ein `TextField` mit `FormField` gewrappt

3. **Warum dispose()?**
   - Controller/FocusNodes registrieren Listener
   - Ohne dispose: Memory Leaks
   - Flutter Framework verlangt Cleanup

4. **AutovalidateMode.onUserInteraction?**
   - Validiert erst nachdem User das Feld berührt hat
   - Keine Fehler beim ersten Render
   - Bessere UX als `always`

5. **Fokus programmatisch setzen?**
   ```dart
   // Mit FocusNode
   myFocusNode.requestFocus();

   // Mit FocusScope
   FocusScope.of(context).requestFocus(otherNode);

   // Zum nächsten Feld
   FocusScope.of(context).nextFocus();

   // Fokus entfernen
   FocusScope.of(context).unfocus();
   ```
