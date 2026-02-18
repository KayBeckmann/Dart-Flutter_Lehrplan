# Übung 6.5: Input-Validierung

## Ziel

Implementiere eine robuste Validierung für eine Benutzerregistrierung-API.

---

## Aufgabe 1: Validator-Klasse (20 min)

Erstelle eine wiederverwendbare Validator-Klasse.

### Anforderungen

```dart
class Validator {
  Validator required(String field, {String? message});
  Validator minLength(String field, int length, {String? message});
  Validator maxLength(String field, int length, {String? message});
  Validator email(String field, {String? message});
  Validator range(String field, {int? min, int? max, String? message});
  Validator oneOf(String field, List<String> values, {String? message});
  Validator pattern(String field, RegExp regex, {String? message});
  ValidationResult validate();
}

class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
}

class ValidationError {
  final String field;
  final String message;
  final String code;
}
```

### Test

```dart
final result = Validator({'name': '', 'age': 200})
    .required('name')
    .range('age', min: 0, max: 150)
    .validate();

print(result.isValid); // false
print(result.errors.length); // 2
```

---

## Aufgabe 2: User Registration (15 min)

Erstelle einen Registrierungs-Endpoint mit vollständiger Validierung.

### Endpoint

POST `/api/register`

### Request Body

```json
{
  "username": "max_mustermann",
  "email": "max@example.com",
  "password": "SecurePass123!",
  "confirmPassword": "SecurePass123!",
  "age": 25,
  "role": "user"
}
```

### Validierungsregeln

| Feld | Regeln |
|------|--------|
| username | Pflicht, 3-20 Zeichen, alphanumerisch + underscore |
| email | Pflicht, gültiges E-Mail-Format |
| password | Pflicht, min. 8 Zeichen, min. 1 Großbuchstabe, 1 Zahl |
| confirmPassword | Muss mit password übereinstimmen |
| age | Optional, 13-120 |
| role | Optional, default "user", erlaubt: user, admin |

### Erfolg (201)

```json
{
  "id": "user-1",
  "username": "max_mustermann",
  "email": "max@example.com",
  "age": 25,
  "role": "user",
  "createdAt": "2024-01-15T10:00:00Z"
}
```

### Fehler (400)

```json
{
  "error": "Validation failed",
  "details": [
    {
      "field": "username",
      "message": "username must be between 3 and 20 characters",
      "code": "LENGTH"
    },
    {
      "field": "password",
      "message": "password must contain at least one uppercase letter",
      "code": "WEAK_PASSWORD"
    }
  ]
}
```

---

## Aufgabe 3: Passwort-Validierung (10 min)

Erstelle einen speziellen Passwort-Validator.

### Anforderungen

```dart
Validator password(String field, {
  int minLength = 8,
  bool requireUppercase = true,
  bool requireLowercase = true,
  bool requireDigit = true,
  bool requireSpecial = false,
});
```

### Fehlermeldungen

- "password must be at least 8 characters"
- "password must contain at least one uppercase letter"
- "password must contain at least one lowercase letter"
- "password must contain at least one digit"
- "password must contain at least one special character"

---

## Aufgabe 4: Custom Validators (10 min)

Implementiere benutzerdefinierte Validierungsregeln.

### Beispiele

```dart
// Passwörter müssen übereinstimmen
Validator matches(String field, String otherField, {String? message});

// Feld darf nicht vorhanden sein wenn anderes Feld gesetzt
Validator excludesWith(String field, String otherField, {String? message});

// Datum muss in der Zukunft liegen
Validator futureDate(String field, {String? message});

// Eindeutigkeit (mit Callback)
Validator unique(String field, Future<bool> Function(String) checkExists, {String? message});
```

### Verwendung

```dart
final result = Validator(body)
    .required('password')
    .required('confirmPassword')
    .matches('confirmPassword', 'password', message: 'Passwords must match')
    .validate();
```

---

## Aufgabe 5: Verschachtelte Validierung (15 min)

Validiere komplexe, verschachtelte Objekte.

### Request Body

```json
{
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
    "email": "max@acme.com",
    "phone": "+49 30 12345678"
  },
  "employees": [
    {"name": "Anna", "role": "developer"},
    {"name": "Bob", "role": "designer"}
  ]
}
```

### Validierungsregeln

**Company:**
- name: Pflicht, 2-100 Zeichen
- taxId: Pflicht, Format: 2 Buchstaben + 9 Ziffern

**Address:**
- street: Optional
- city: Pflicht
- zip: Pflicht, 5 Ziffern
- country: Pflicht, 2 Buchstaben (ISO-Code)

**Contact:**
- name: Pflicht
- email: Pflicht, gültiges Format
- phone: Optional

**Employees:**
- Mindestens 1 Mitarbeiter
- Jeder braucht name (Pflicht) und role (Pflicht, oneOf: developer, designer, manager)

### Fehlermeldungen mit Pfaden

```json
{
  "errors": [
    {"field": "company.address.zip", "message": "zip must be 5 digits"},
    {"field": "employees[1].role", "message": "role must be one of: developer, designer, manager"}
  ]
}
```

---

## Aufgabe 6: Validator-Middleware (Bonus, 10 min)

Erstelle eine Middleware, die automatisch validiert.

### Verwendung

```dart
// Schema definieren
final userSchema = {
  'name': [required(), minLength(2)],
  'email': [required(), email()],
  'age': [range(min: 0, max: 150)],
};

// Middleware anwenden
router.post('/users',
  validate(userSchema),  // Middleware
  createUser,            // Handler
);
```

### Middleware

```dart
Middleware validate(Map<String, List<ValidationRule>> schema) {
  return (Handler handler) {
    return (Request request) async {
      final body = request.json;
      final errors = <ValidationError>[];

      for (final entry in schema.entries) {
        final field = entry.key;
        final rules = entry.value;

        for (final rule in rules) {
          final error = rule.validate(field, body[field]);
          if (error != null) {
            errors.add(error);
            break; // Stop at first error for this field
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
```

---

## Testen

```bash
# Erfolgreiche Registrierung
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "max_m",
    "email": "max@test.de",
    "password": "SecurePass1",
    "confirmPassword": "SecurePass1"
  }'

# Validierungsfehler
curl -X POST http://localhost:8080/api/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ab",
    "email": "invalid",
    "password": "weak"
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
```

---

## Abgabe-Checkliste

- [ ] Validator-Klasse mit allen Basis-Methoden
- [ ] ValidationResult und ValidationError implementiert
- [ ] User Registration Endpoint funktioniert
- [ ] Passwort-Validierung mit Komplexitätsregeln
- [ ] Custom Validator: matches() funktioniert
- [ ] Verschachtelte Objekte werden validiert
- [ ] Fehler-Response im korrekten Format
- [ ] (Bonus) Validator-Middleware
