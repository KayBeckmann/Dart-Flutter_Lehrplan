# Ressourcen: Input-Validierung

## Offizielle Dokumentation

- [RFC 7807 Problem Details](https://www.rfc-editor.org/rfc/rfc7807)
- [OWASP Input Validation](https://owasp.org/www-community/Input_Validation_Cheat_Sheet)

## Cheat Sheet: Inline-Validierung

```dart
// Pflichtfeld
final name = body['name'] as String?;
if (name == null || name.isEmpty) {
  return badRequest('name is required');
}

// E-Mail Format
final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
if (!emailRegex.hasMatch(email)) {
  return badRequest('invalid email format');
}

// String-Länge
if (password.length < 8) {
  return badRequest('password must be at least 8 characters');
}

// Zahlenbereich
if (age < 0 || age > 150) {
  return badRequest('age must be between 0 and 150');
}

// Erlaubte Werte
if (!['draft', 'published'].contains(status)) {
  return badRequest('status must be draft or published');
}
```

## Cheat Sheet: Validator-Klasse

```dart
class Validator {
  final List<ValidationError> _errors = [];
  final Map<String, dynamic> data;

  Validator(this.data);

  Validator required(String field, {String? message}) {
    final value = data[field];
    if (value == null || (value is String && value.isEmpty)) {
      _errors.add(ValidationError(field: field, message: message ?? '$field is required', code: 'REQUIRED'));
    }
    return this;
  }

  Validator minLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.length < length) {
      _errors.add(ValidationError(field: field, message: message ?? '$field must be at least $length characters', code: 'MIN_LENGTH'));
    }
    return this;
  }

  Validator maxLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.length > length) {
      _errors.add(ValidationError(field: field, message: message ?? '$field must be at most $length characters', code: 'MAX_LENGTH'));
    }
    return this;
  }

  Validator email(String field, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty) {
      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!regex.hasMatch(value)) {
        _errors.add(ValidationError(field: field, message: message ?? '$field must be a valid email', code: 'INVALID_EMAIL'));
      }
    }
    return this;
  }

  Validator range(String field, {int? min, int? max}) {
    final value = data[field];
    if (value is num) {
      if (min != null && value < min) {
        _errors.add(ValidationError(field: field, message: '$field must be at least $min', code: 'MIN_VALUE'));
      }
      if (max != null && value > max) {
        _errors.add(ValidationError(field: field, message: '$field must be at most $max', code: 'MAX_VALUE'));
      }
    }
    return this;
  }

  Validator oneOf(String field, List<String> values) {
    final value = data[field];
    if (value is String && !values.contains(value)) {
      _errors.add(ValidationError(field: field, message: '$field must be one of: ${values.join(', ')}', code: 'INVALID_VALUE'));
    }
    return this;
  }

  ValidationResult validate() => ValidationResult.fromErrors(_errors);
}
```

## Cheat Sheet: Verwendung

```dart
final result = Validator(body)
    .required('name')
    .minLength('name', 2)
    .maxLength('name', 100)
    .required('email')
    .email('email')
    .required('password')
    .minLength('password', 8)
    .range('age', min: 0, max: 150)
    .oneOf('role', ['user', 'admin'])
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
```

## Cheat Sheet: Fehler-Response

```dart
Response validationError(ValidationResult result) {
  return Response(400,
    body: jsonEncode({
      'type': 'validation_error',
      'title': 'Validation Error',
      'status': 400,
      'errors': result.errors.map((e) => {
        return {
          'field': e.field,
          'message': e.message,
          'code': e.code,
        };
      }).toList(),
    }),
    headers: {'content-type': 'application/json'},
  );
}
```

## Regex-Patterns

```dart
// E-Mail
final email = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

// URL
final url = RegExp(r'^https?:\/\/[\w\-]+(\.[\w\-]+)+[/#?]?.*$');

// Telefon (einfach)
final phone = RegExp(r'^\+?[\d\s\-]{10,}$');

// UUID
final uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

// Slug (URL-freundlich)
final slug = RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*$');

// Nur Buchstaben
final alpha = RegExp(r'^[a-zA-Z]+$');

// Alphanumerisch
final alphaNum = RegExp(r'^[a-zA-Z0-9]+$');

// Datum (YYYY-MM-DD)
final date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
```

## Validierungsregeln nach Feldtyp

### String-Felder

| Regel | Beschreibung |
|-------|--------------|
| required | Darf nicht leer sein |
| minLength | Mindestlänge |
| maxLength | Maximallänge |
| pattern | Regex-Match |
| email | E-Mail-Format |
| url | URL-Format |
| oneOf | Erlaubte Werte |

### Numerische Felder

| Regel | Beschreibung |
|-------|--------------|
| required | Muss vorhanden sein |
| min | Mindestwert |
| max | Maximalwert |
| integer | Muss Ganzzahl sein |
| positive | Muss > 0 sein |

### Array-Felder

| Regel | Beschreibung |
|-------|--------------|
| required | Darf nicht leer sein |
| minItems | Mindestanzahl Elemente |
| maxItems | Maximalanzahl Elemente |
| unique | Keine Duplikate |

## HTTP Statuscodes

| Code | Verwendung |
|------|------------|
| 400 | Bad Request - Syntaxfehler |
| 422 | Unprocessable Entity - Semantische Fehler |

## Beispiel: Vollständige Validierung

```dart
class ProductValidator {
  static ValidationResult validateCreate(Map<String, dynamic> data) {
    return Validator(data)
        .required('name')
        .minLength('name', 2)
        .maxLength('name', 200)
        .required('price')
        .range('price', min: 0)
        .required('category')
        .oneOf('category', ['electronics', 'clothing', 'food'])
        .maxLength('description', 2000)
        .range('stock', min: 0)
        .validate();
  }

  static ValidationResult validateUpdate(Map<String, dynamic> data) {
    final v = Validator(data);

    if (data.containsKey('name')) {
      v.minLength('name', 2).maxLength('name', 200);
    }
    if (data.containsKey('price')) {
      v.range('price', min: 0);
    }
    if (data.containsKey('category')) {
      v.oneOf('category', ['electronics', 'clothing', 'food']);
    }
    if (data.containsKey('description')) {
      v.maxLength('description', 2000);
    }
    if (data.containsKey('stock')) {
      v.range('stock', min: 0);
    }

    return v.validate();
  }
}
```

## Test-Beispiele

```bash
# Fehlende Pflichtfelder
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{}'

# Ungültige E-Mail
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max", "email": "invalid", "password": "12345678"}'

# Zu kurzes Passwort
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max", "email": "max@test.de", "password": "123"}'

# Ungültiger Enum-Wert
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Max", "email": "max@test.de", "password": "12345678", "role": "superadmin"}'
```
