# Lösung 6.5: Input-Validierung

## Vollständige Lösung

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Aufgabe 1: Validation Classes
// ============================================

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
}

class Validator {
  final List<ValidationError> _errors = [];
  final Map<String, dynamic> data;
  final String _prefix;

  Validator(this.data, {String prefix = ''}) : _prefix = prefix;

  String _fieldName(String field) => _prefix.isEmpty ? field : '$_prefix.$field';

  // Pflichtfeld
  Validator required(String field, {String? message}) {
    final value = data[field];
    if (value == null || (value is String && value.isEmpty)) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} is required',
        code: 'REQUIRED',
      ));
    }
    return this;
  }

  // String-Länge
  Validator minLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty && value.length < length) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} must be at least $length characters',
        code: 'MIN_LENGTH',
      ));
    }
    return this;
  }

  Validator maxLength(String field, int length, {String? message}) {
    final value = data[field];
    if (value is String && value.length > length) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} must be at most $length characters',
        code: 'MAX_LENGTH',
      ));
    }
    return this;
  }

  // E-Mail
  Validator email(String field, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty) {
      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!regex.hasMatch(value)) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: message ?? '${_fieldName(field)} must be a valid email',
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
          field: _fieldName(field),
          message: message ?? '${_fieldName(field)} must be at least $min',
          code: 'MIN_VALUE',
        ));
      }
      if (max != null && value > max) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: message ?? '${_fieldName(field)} must be at most $max',
          code: 'MAX_VALUE',
        ));
      }
    }
    return this;
  }

  // Erlaubte Werte
  Validator oneOf(String field, List<String> values, {String? message}) {
    final value = data[field];
    if (value is String && value.isNotEmpty && !values.contains(value)) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} must be one of: ${values.join(', ')}',
        code: 'INVALID_VALUE',
      ));
    }
    return this;
  }

  // Regex-Pattern
  Validator pattern(String field, RegExp regex, {String? message, String code = 'INVALID_FORMAT'}) {
    final value = data[field];
    if (value is String && value.isNotEmpty && !regex.hasMatch(value)) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} has invalid format',
        code: code,
      ));
    }
    return this;
  }

  // ============================================
  // Aufgabe 3: Passwort-Validierung
  // ============================================

  Validator password(String field, {
    int minLength = 8,
    bool requireUppercase = true,
    bool requireLowercase = true,
    bool requireDigit = true,
    bool requireSpecial = false,
  }) {
    final value = data[field];
    if (value is String && value.isNotEmpty) {
      if (value.length < minLength) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must be at least $minLength characters',
          code: 'WEAK_PASSWORD',
        ));
      }
      if (requireUppercase && !RegExp(r'[A-Z]').hasMatch(value)) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must contain at least one uppercase letter',
          code: 'WEAK_PASSWORD',
        ));
      }
      if (requireLowercase && !RegExp(r'[a-z]').hasMatch(value)) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must contain at least one lowercase letter',
          code: 'WEAK_PASSWORD',
        ));
      }
      if (requireDigit && !RegExp(r'\d').hasMatch(value)) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must contain at least one digit',
          code: 'WEAK_PASSWORD',
        ));
      }
      if (requireSpecial && !RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must contain at least one special character',
          code: 'WEAK_PASSWORD',
        ));
      }
    }
    return this;
  }

  // ============================================
  // Aufgabe 4: Custom Validators
  // ============================================

  Validator matches(String field, String otherField, {String? message}) {
    final value = data[field];
    final otherValue = data[otherField];
    if (value != null && otherValue != null && value != otherValue) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} must match ${_fieldName(otherField)}',
        code: 'MISMATCH',
      ));
    }
    return this;
  }

  Validator custom(
    String field,
    bool Function(dynamic) validator, {
    String? message,
    String code = 'CUSTOM',
  }) {
    final value = data[field];
    if (value != null && !validator(value)) {
      _errors.add(ValidationError(
        field: _fieldName(field),
        message: message ?? '${_fieldName(field)} is invalid',
        code: code,
      ));
    }
    return this;
  }

  // ============================================
  // Aufgabe 5: Verschachtelte Validierung
  // ============================================

  Validator nested(String field, void Function(Validator) validateNested) {
    final value = data[field];
    if (value is Map<String, dynamic>) {
      final nestedValidator = Validator(value, prefix: _fieldName(field));
      validateNested(nestedValidator);
      _errors.addAll(nestedValidator._errors);
    }
    return this;
  }

  Validator array(String field, void Function(Validator, int) validateItem, {int? minItems}) {
    final value = data[field];
    if (value is List) {
      if (minItems != null && value.length < minItems) {
        _errors.add(ValidationError(
          field: _fieldName(field),
          message: '${_fieldName(field)} must have at least $minItems items',
          code: 'MIN_ITEMS',
        ));
      }
      for (var i = 0; i < value.length; i++) {
        final item = value[i];
        if (item is Map<String, dynamic>) {
          final itemValidator = Validator(item, prefix: '${_fieldName(field)}[$i]');
          validateItem(itemValidator, i);
          _errors.addAll(itemValidator._errors);
        }
      }
    }
    return this;
  }

  ValidationResult validate() {
    return ValidationResult.fromErrors(_errors);
  }
}

// ============================================
// Helper Functions
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Response validationError(ValidationResult result) {
  return Response(400,
    body: jsonEncode({
      'error': 'Validation failed',
      'details': result.errors.map((e) => e.toJson()).toList(),
    }),
    headers: {'content-type': 'application/json'},
  );
}

extension RequestJson on Request {
  Map<String, dynamic> get json {
    final body = context['body'];
    return body is Map<String, dynamic> ? body : {};
  }
}

Middleware jsonBodyParser() {
  return (Handler handler) {
    return (Request request) async {
      if (!['POST', 'PUT', 'PATCH'].contains(request.method)) {
        return handler(request);
      }
      final contentType = request.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return handler(request);
      }
      final body = await request.readAsString();
      if (body.isEmpty) {
        return handler(request.change(context: {...request.context, 'body': <String, dynamic>{}}));
      }
      try {
        final json = jsonDecode(body);
        return handler(request.change(context: {...request.context, 'body': json}));
      } on FormatException {
        return Response(400, body: '{"error": "Invalid JSON"}', headers: {'content-type': 'application/json'});
      }
    };
  };
}

// ============================================
// Storage
// ============================================

final _users = <String, Map<String, dynamic>>{};
var _nextUserId = 1;

// ============================================
// Aufgabe 2: User Registration
// ============================================

Response registerUser(Request request) {
  final body = request.json;

  // Username Pattern: alphanumerisch + underscore
  final usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');

  final result = Validator(body)
      .required('username')
      .minLength('username', 3)
      .maxLength('username', 20)
      .pattern('username', usernamePattern,
          message: 'username must contain only letters, numbers, and underscores',
          code: 'INVALID_USERNAME')
      .required('email')
      .email('email')
      .required('password')
      .password('password',
          minLength: 8,
          requireUppercase: true,
          requireLowercase: true,
          requireDigit: true)
      .required('confirmPassword')
      .matches('confirmPassword', 'password', message: 'Passwords must match')
      .range('age', min: 13, max: 120)
      .oneOf('role', ['user', 'admin'])
      .validate();

  if (!result.isValid) {
    return validationError(result);
  }

  // User erstellen
  final id = 'user-${_nextUserId++}';
  final user = {
    'id': id,
    'username': body['username'],
    'email': body['email'],
    'age': body['age'],
    'role': body['role'] ?? 'user',
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  };

  _users[id] = user;

  return Response(201,
    body: jsonEncode(user),
    headers: {
      'content-type': 'application/json',
      'location': '/api/users/$id',
    },
  );
}

// ============================================
// Aufgabe 5: Verschachtelte Validierung
// ============================================

Response createCompany(Request request) {
  final body = request.json;

  // Tax ID Pattern: 2 Buchstaben + 9 Ziffern
  final taxIdPattern = RegExp(r'^[A-Z]{2}\d{9}$');
  // ZIP Pattern: 5 Ziffern
  final zipPattern = RegExp(r'^\d{5}$');
  // Country Pattern: 2 Buchstaben
  final countryPattern = RegExp(r'^[A-Z]{2}$');

  final result = Validator(body)
      .required('company')
      .nested('company', (v) {
        v.required('name')
          .minLength('name', 2)
          .maxLength('name', 100)
          .required('taxId')
          .pattern('taxId', taxIdPattern,
              message: 'taxId must be 2 letters followed by 9 digits')
          .required('address')
          .nested('address', (addr) {
            addr.required('city')
              .required('zip')
              .pattern('zip', zipPattern, message: 'zip must be 5 digits')
              .required('country')
              .pattern('country', countryPattern, message: 'country must be 2 letter ISO code');
          });
      })
      .required('contact')
      .nested('contact', (v) {
        v.required('name')
          .required('email')
          .email('email');
      })
      .required('employees')
      .array('employees', (v, i) {
        v.required('name')
          .required('role')
          .oneOf('role', ['developer', 'designer', 'manager']);
      }, minItems: 1)
      .validate();

  if (!result.isValid) {
    return validationError(result);
  }

  return jsonResponse({
    'message': 'Company created successfully',
    'data': body,
  }, statusCode: 201);
}

// ============================================
// Aufgabe 6: Validator Middleware (Bonus)
// ============================================

typedef ValidationRule = ValidationError? Function(String field, dynamic value);

ValidationRule requiredRule({String? message}) {
  return (field, value) {
    if (value == null || (value is String && value.isEmpty)) {
      return ValidationError(
        field: field,
        message: message ?? '$field is required',
        code: 'REQUIRED',
      );
    }
    return null;
  };
}

ValidationRule minLengthRule(int length, {String? message}) {
  return (field, value) {
    if (value is String && value.isNotEmpty && value.length < length) {
      return ValidationError(
        field: field,
        message: message ?? '$field must be at least $length characters',
        code: 'MIN_LENGTH',
      );
    }
    return null;
  };
}

ValidationRule emailRule({String? message}) {
  return (field, value) {
    if (value is String && value.isNotEmpty) {
      final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!regex.hasMatch(value)) {
        return ValidationError(
          field: field,
          message: message ?? '$field must be a valid email',
          code: 'INVALID_EMAIL',
        );
      }
    }
    return null;
  };
}

Middleware validateSchema(Map<String, List<ValidationRule>> schema) {
  return (Handler handler) {
    return (Request request) async {
      final body = request.json;
      final errors = <ValidationError>[];

      for (final entry in schema.entries) {
        final field = entry.key;
        final rules = entry.value;

        for (final rule in rules) {
          final error = rule(field, body[field]);
          if (error != null) {
            errors.add(error);
            break; // First error per field
          }
        }
      }

      if (errors.isNotEmpty) {
        return validationError(ValidationResult.invalid(errors));
      }

      return handler(request);
    };
  };
}

// ============================================
// Main
// ============================================

void main() async {
  final router = Router();

  // User Registration
  router.post('/api/register', registerUser);

  // Company mit verschachtelter Validierung
  router.post('/api/companies', createCompany);

  // Bonus: Schema-basierte Validierung
  final productSchema = {
    'name': [requiredRule(), minLengthRule(2)],
    'email': [requiredRule(), emailRule()],
  };

  router.post('/api/products', Pipeline()
      .addMiddleware(validateSchema(productSchema))
      .addHandler((request) {
        return jsonResponse({'message': 'Product created'}, statusCode: 201);
      }));

  // Users auflisten
  router.get('/api/users', (request) {
    return jsonResponse({
      'data': _users.values.toList(),
      'total': _users.length,
    });
  });

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(jsonBodyParser())
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('');
  print('Endpoints:');
  print('  POST /api/register - User Registration');
  print('  POST /api/companies - Company with nested validation');
  print('  POST /api/products - Schema-based validation (bonus)');
  print('  GET  /api/users - List users');
}
```

---

## Test-Befehle

```bash
# ========== Erfolgreiche Registrierung ==========
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "max_mustermann",
    "email": "max@example.com",
    "password": "SecurePass1",
    "confirmPassword": "SecurePass1",
    "age": 25
  }'

# ========== Validierungsfehler ==========

# Username zu kurz + ungültige E-Mail
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ab",
    "email": "invalid-email",
    "password": "SecurePass1",
    "confirmPassword": "SecurePass1"
  }'

# Schwaches Passwort (keine Großbuchstaben, keine Ziffern)
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "max_m",
    "email": "max@test.de",
    "password": "weakpass",
    "confirmPassword": "weakpass"
  }'

# Passwörter stimmen nicht überein
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "max_m",
    "email": "max@test.de",
    "password": "SecurePass1",
    "confirmPassword": "DifferentPass"
  }'

# Ungültiger Role-Wert
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "max_m",
    "email": "max@test.de",
    "password": "SecurePass1",
    "confirmPassword": "SecurePass1",
    "role": "superadmin"
  }'

# ========== Verschachtelte Validierung ==========

# Erfolgreiche Company
curl -X POST http://localhost:8080/api/companies \
  -H "Content-Type: application/json" \
  -d '{
    "company": {
      "name": "Acme Corp",
      "taxId": "DE123456789",
      "address": {
        "street": "Hauptstraße 1",
        "city": "Berlin",
        "zip": "10115",
        "country": "DE"
      }
    },
    "contact": {
      "name": "Max Mustermann",
      "email": "max@acme.com"
    },
    "employees": [
      {"name": "Anna", "role": "developer"},
      {"name": "Bob", "role": "designer"}
    ]
  }'

# Fehler in verschachtelten Feldern
curl -X POST http://localhost:8080/api/companies \
  -H "Content-Type: application/json" \
  -d '{
    "company": {
      "name": "A",
      "taxId": "invalid",
      "address": {
        "city": "Berlin",
        "zip": "123",
        "country": "Germany"
      }
    },
    "contact": {
      "email": "invalid"
    },
    "employees": []
  }'

# ========== Bonus: Schema-Validierung ==========
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{"name": "A", "email": "invalid"}'
```

---

## Ausgabe-Beispiele

### Erfolgreiche Registrierung (201)

```json
{
  "id": "user-1",
  "username": "max_mustermann",
  "email": "max@example.com",
  "age": 25,
  "role": "user",
  "createdAt": "2024-01-15T10:00:00.000Z"
}
```

### Validierungsfehler (400)

```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "username",
      "message": "username must be at least 3 characters",
      "code": "MIN_LENGTH"
    },
    {
      "field": "email",
      "message": "email must be a valid email",
      "code": "INVALID_EMAIL"
    }
  ]
}
```

### Verschachtelte Fehler (400)

```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "company.name",
      "message": "company.name must be at least 2 characters",
      "code": "MIN_LENGTH"
    },
    {
      "field": "company.taxId",
      "message": "taxId must be 2 letters followed by 9 digits",
      "code": "INVALID_FORMAT"
    },
    {
      "field": "company.address.zip",
      "message": "zip must be 5 digits",
      "code": "INVALID_FORMAT"
    },
    {
      "field": "contact.name",
      "message": "contact.name is required",
      "code": "REQUIRED"
    },
    {
      "field": "employees",
      "message": "employees must have at least 1 items",
      "code": "MIN_ITEMS"
    }
  ]
}
```

---

## Wichtige Patterns

### Fluent API für Validierung

```dart
final result = Validator(body)
    .required('name')
    .minLength('name', 2)
    .required('email')
    .email('email')
    .validate();
```

### Prefix für verschachtelte Felder

```dart
Validator(data, prefix: 'company.address')
// Fehler-Feld wird: company.address.city
```

### Passwort-Validierung mit mehreren Regeln

```dart
.password('password',
    minLength: 8,
    requireUppercase: true,
    requireDigit: true)
```
