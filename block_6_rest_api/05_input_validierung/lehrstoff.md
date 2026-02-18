# Einheit 6.5: Input-Validierung

## Lernziele

Nach dieser Einheit kannst du:
- Eingabedaten systematisch validieren
- Validierungsregeln definieren und anwenden
- Aussagekräftige Fehlermeldungen zurückgeben
- Wiederverwendbare Validatoren erstellen

---

## Warum Input-Validierung?

### Gefahren ohne Validierung

```dart
// Ohne Validierung
Future<Response> createUser(Request request) async {
  final body = request.json;

  // Was passiert hier wenn...
  // - email ist keine gültige E-Mail?
  // - age ist negativ?
  // - password hat nur 1 Zeichen?
  // - name enthält <script>-Tags?

  final user = User(
    name: body['name'],
    email: body['email'],
    age: body['age'],
    password: body['password'],
  );

  // Speichern mit ungültigen Daten!
  await db.save(user);
}
```

### Validierung schützt vor

1. **Ungültigen Daten** in der Datenbank
2. **Security-Problemen** (SQL Injection, XSS)
3. **Unerwarteten Fehlern** im Backend
4. **Schlechter Benutzererfahrung** (späte Fehlermeldungen)

---

## Einfache Validierung

### Inline-Validierung

```dart
Future<Response> createUser(Request request) async {
  final body = request.json;

  // Pflichtfelder
  final name = body['name'] as String?;
  if (name == null || name.isEmpty) {
    return badRequest('name is required');
  }

  final email = body['email'] as String?;
  if (email == null || email.isEmpty) {
    return badRequest('email is required');
  }

  // Format-Validierung
  if (!email.contains('@')) {
    return badRequest('email must be a valid email address');
  }

  // Längen-Validierung
  final password = body['password'] as String?;
  if (password == null || password.length < 8) {
    return badRequest('password must be at least 8 characters');
  }

  // Bereichs-Validierung
  final age = body['age'] as int?;
  if (age != null && (age < 0 || age > 150)) {
    return badRequest('age must be between 0 and 150');
  }

  // ... User erstellen
}
```

**Problem**: Code wird schnell unübersichtlich!

---

## Strukturierte Validierung

### ValidationResult Klasse

```dart
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;

  ValidationResult.valid()
      : isValid = true,
        errors = const [];

  ValidationResult.invalid(this.errors) : isValid = false;

  factory ValidationResult.fromErrors(List<ValidationError> errors) {
    if (errors.isEmpty) {
      return ValidationResult.valid();
    }
    return ValidationResult.invalid(errors);
  }

  Map<String, dynamic> toJson() => {
    'valid': isValid,
    'errors': errors.map((e) => e.toJson()).toList(),
  };
}

class ValidationError {
  final String field;
  final String message;
  final String code;

  ValidationError({
    required this.field,
    required this.message,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
    'field': field,
    'message': message,
    'code': code,
  };
}
```

### Validator-Klasse

```dart
class Validator {
  final List<ValidationError> _errors = [];
  final Map<String, dynamic> data;

  Validator(this.data);

  // Pflichtfeld
  Validator required(String field, {String? message}) {
    final value = data[field];
    if (value == null || (value is String && value.isEmpty)) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field is required',
        code: 'REQUIRED',
      ));
    }
    return this;
  }

  // String-Länge
  Validator minLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.length < length) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field must be at least $length characters',
        code: 'MIN_LENGTH',
      ));
    }
    return this;
  }

  Validator maxLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.length > length) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field must be at most $length characters',
        code: 'MAX_LENGTH',
      ));
    }
    return this;
  }

  // E-Mail Format
  Validator email(String field, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        _errors.add(ValidationError(
          field: field,
          message: message ?? '$field must be a valid email',
          code: 'INVALID_EMAIL',
        ));
      }
    }
    return this;
  }

  // Zahlenbereich
  Validator range(String field, {int? min, int? max, String? message}) {
    final value = data[field];
    if (value is num) {
      if (min != null && value < min) {
        _errors.add(ValidationError(
          field: field,
          message: message ?? '$field must be at least $min',
          code: 'MIN_VALUE',
        ));
      }
      if (max != null && value > max) {
        _errors.add(ValidationError(
          field: field,
          message: message ?? '$field must be at most $max',
          code: 'MAX_VALUE',
        ));
      }
    }
    return this;
  }

  // Enum-Werte
  Validator oneOf(String field, List<String> values, {String? message}) {
    final value = data[field];
    if (value is String && !values.contains(value)) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field must be one of: ${values.join(', ')}',
        code: 'INVALID_VALUE',
      ));
    }
    return this;
  }

  // Regex-Pattern
  Validator pattern(String field, RegExp regex, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty && !regex.hasMatch(value)) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field has invalid format',
        code: 'INVALID_FORMAT',
      ));
    }
    return this;
  }

  // Custom Validation
  Validator custom(String field, bool Function(dynamic) validator, {String? message, String code = 'CUSTOM'}) {
    final value = data[field];
    if (value != null && !validator(value)) {
      _errors.add(ValidationError(
        field: field,
        message: message ?? '$field is invalid',
        code: code,
      ));
    }
    return this;
  }

  ValidationResult validate() {
    return ValidationResult.fromErrors(_errors);
  }
}
```

### Verwendung

```dart
Future<Response> createUser(Request request) async {
  final body = request.json;

  final result = Validator(body)
      .required('name')
      .minLength('name', 2)
      .maxLength('name', 100)
      .required('email')
      .email('email')
      .required('password')
      .minLength('password', 8)
      .range('age', min: 0, max: 150)
      .oneOf('role', ['user', 'admin', 'moderator'])
      .validate();

  if (!result.isValid) {
    return Response(400,
      body: jsonEncode({
        'error': 'Validation failed',
        'details': result.errors.map((e) => e.toJson()).toList(),
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  // Validierte Daten verwenden
  final user = User(
    name: body['name'],
    email: body['email'],
    password: body['password'],
    age: body['age'],
    role: body['role'] ?? 'user',
  );

  // ...
}
```

---

## Request-spezifische Validierung

### Unterschiedliche Regeln für Create/Update

```dart
class UserValidator {
  static ValidationResult validateCreate(Map<String, dynamic> data) {
    return Validator(data)
        .required('name')
        .minLength('name', 2)
        .required('email')
        .email('email')
        .required('password')
        .minLength('password', 8)
        .validate();
  }

  static ValidationResult validateUpdate(Map<String, dynamic> data) {
    // Bei Update: Felder optional, aber wenn vorhanden dann validieren
    final v = Validator(data);

    if (data.containsKey('name')) {
      v.minLength('name', 2).maxLength('name', 100);
    }

    if (data.containsKey('email')) {
      v.email('email');
    }

    if (data.containsKey('password')) {
      v.minLength('password', 8);
    }

    return v.validate();
  }
}

// Verwendung
router.post('/users', (Request request) {
  final result = UserValidator.validateCreate(request.json);
  if (!result.isValid) {
    return validationError(result);
  }
  // ...
});

router.patch('/users/<id>', (Request request, String id) {
  final result = UserValidator.validateUpdate(request.json);
  if (!result.isValid) {
    return validationError(result);
  }
  // ...
});
```

---

## Fehler-Response Format

### RFC 7807 Problem Details

```dart
Response validationError(ValidationResult result) {
  return Response(400,
    body: jsonEncode({
      'type': 'https://api.example.com/errors/validation',
      'title': 'Validation Error',
      'status': 400,
      'detail': 'One or more fields failed validation',
      'errors': result.errors.map((e) => {
        return {
          'field': e.field,
          'message': e.message,
          'code': e.code,
        };
      }).toList(),
    }),
    headers: {
      'content-type': 'application/problem+json',
    },
  );
}
```

### Beispiel-Response

```json
{
  "type": "https://api.example.com/errors/validation",
  "title": "Validation Error",
  "status": 400,
  "detail": "One or more fields failed validation",
  "errors": [
    {
      "field": "email",
      "message": "email must be a valid email",
      "code": "INVALID_EMAIL"
    },
    {
      "field": "password",
      "message": "password must be at least 8 characters",
      "code": "MIN_LENGTH"
    }
  ]
}
```

---

## Verschachtelte Objekte validieren

```dart
Validator nestedValidator(String parentField, Map<String, dynamic>? nested) {
  return Validator(nested ?? {});
}

Future<Response> createOrder(Request request) async {
  final body = request.json;

  // Haupt-Validierung
  final mainResult = Validator(body)
      .required('customer')
      .required('items')
      .validate();

  if (!mainResult.isValid) {
    return validationError(mainResult);
  }

  // Verschachtelte Validierung: Customer
  final customer = body['customer'] as Map<String, dynamic>?;
  final customerResult = Validator(customer ?? {})
      .required('name')
      .required('email')
      .email('email')
      .validate();

  if (!customerResult.isValid) {
    // Fehler mit Prefix versehen
    final prefixedErrors = customerResult.errors.map((e) => ValidationError(
      field: 'customer.${e.field}',
      message: e.message,
      code: e.code,
    )).toList();
    return validationError(ValidationResult.invalid(prefixedErrors));
  }

  // Array-Validierung: Items
  final items = body['items'] as List<dynamic>?;
  if (items == null || items.isEmpty) {
    return badRequest('items must not be empty');
  }

  for (var i = 0; i < items.length; i++) {
    final item = items[i] as Map<String, dynamic>?;
    final itemResult = Validator(item ?? {})
        .required('productId')
        .required('quantity')
        .range('quantity', min: 1)
        .validate();

    if (!itemResult.isValid) {
      final prefixedErrors = itemResult.errors.map((e) => ValidationError(
        field: 'items[$i].${e.field}',
        message: e.message,
        code: e.code,
      )).toList();
      return validationError(ValidationResult.invalid(prefixedErrors));
    }
  }

  // Alle Validierungen bestanden
  // ...
}
```

---

## Zusammenfassung

| Regel | Code |
|-------|------|
| Pflichtfeld | `.required('field')` |
| Min-Länge | `.minLength('field', 8)` |
| Max-Länge | `.maxLength('field', 100)` |
| E-Mail | `.email('field')` |
| Zahlenbereich | `.range('field', min: 0, max: 100)` |
| Erlaubte Werte | `.oneOf('field', ['a', 'b', 'c'])` |
| Regex-Pattern | `.pattern('field', regex)` |
| Custom | `.custom('field', (v) => v > 0)` |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Error Handling & HTTP-Statuscodes**: Wie du Fehler systematisch behandelst und die richtigen HTTP-Codes verwendest.
