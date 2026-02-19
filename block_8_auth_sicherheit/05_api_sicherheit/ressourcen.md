# Ressourcen: API-Sicherheit

## Offizielle Dokumentation

- [OWASP Top 10](https://owasp.org/Top10/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [MDN CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Security Headers](https://securityheaders.com/)

## Cheat Sheet: CORS Headers

```dart
// Preflight Response (OPTIONS)
headers = {
  'Access-Control-Allow-Origin': 'https://example.com',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
  'Access-Control-Allow-Credentials': 'true',
  'Access-Control-Max-Age': '3600',  // 1 Stunde cachen
};

// Wichtig: Bei Credentials niemals '*' als Origin!
// FALSCH:
'Access-Control-Allow-Origin': '*',
'Access-Control-Allow-Credentials': 'true',

// RICHTIG:
'Access-Control-Allow-Origin': 'https://myapp.com',
'Access-Control-Allow-Credentials': 'true',
'Vary': 'Origin',  // Wichtig für Caching
```

## Cheat Sheet: Rate Limiting

```dart
// Response Headers
'X-RateLimit-Limit': '100',           // Max Requests
'X-RateLimit-Remaining': '95',        // Verbleibend
'X-RateLimit-Reset': '1672531200',    // Unix Timestamp

// Bei 429 Too Many Requests
'Retry-After': '60',  // Sekunden bis Retry

// Algorithmen:
// - Fixed Window: Einfach, aber Burst am Window-Ende
// - Sliding Window: Glatter, aber mehr Speicher
// - Token Bucket: Erlaubt Bursts bis zu Limit
// - Leaky Bucket: Konstante Rate
```

## Cheat Sheet: Security Headers

```dart
// Basis-Set für APIs
headers = {
  // Verhindert MIME-Type Sniffing
  'X-Content-Type-Options': 'nosniff',

  // Verhindert Clickjacking
  'X-Frame-Options': 'DENY',

  // XSS-Filter (Legacy)
  'X-XSS-Protection': '1; mode=block',

  // Referrer einschränken
  'Referrer-Policy': 'strict-origin-when-cross-origin',

  // Content Security Policy
  'Content-Security-Policy': "default-src 'none'",

  // Kein Caching für API-Responses
  'Cache-Control': 'no-store',
  'Pragma': 'no-cache',
};

// Für HTTPS (nach TLS-Setup)
'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
```

## Cheat Sheet: Input Validation

```dart
// String
final name = validator.string('name', data['name'],
  required: true,
  minLength: 2,
  maxLength: 100,
  pattern: RegExp(r'^[\w\s\-]+$'),
);

// Email
final email = validator.email('email', data['email']);

// Integer mit Range
final age = validator.integer('age', data['age'],
  min: 0,
  max: 150,
);

// Enum
final status = validator.enumValue('status', data['status'],
  Status.values,
);

// Liste
final tags = validator.list<String>('tags', data['tags'],
  minLength: 1,
  maxLength: 10,
);
```

## Cheat Sheet: SQL Injection Prevention

```dart
// ✅ SICHER: Prepared Statements
await db.execute(
  Sql.named('SELECT * FROM users WHERE email = @email'),
  parameters: {'email': userInput},
);

// ✅ SICHER: LIKE mit Escaping
final escaped = input
    .replaceAll('\\', '\\\\')
    .replaceAll('%', '\\%')
    .replaceAll('_', '\\_');
await db.execute(
  Sql.named('SELECT * FROM products WHERE name ILIKE @pattern'),
  parameters: {'pattern': '%$escaped%'},
);

// ✅ SICHER: Whitelist für dynamische Spalten
const allowed = {'id', 'name', 'created_at'};
final column = allowed.contains(input) ? input : 'created_at';
await db.execute('SELECT * FROM users ORDER BY $column');

// ❌ UNSICHER: String Concatenation
await db.execute("SELECT * FROM users WHERE email = '$userInput'");
```

## Cheat Sheet: XSS Prevention

```dart
// HTML escapen (für HTML-Output)
String escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
}

// HTML-Tags entfernen
String stripHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}

// Content-Type richtig setzen
Response.ok(
  jsonEncode(data),
  headers: {'content-type': 'application/json'},  // Nicht text/html!
);
```

## Cheat Sheet: HTTP Status Codes für Errors

| Code | Name | Verwendung |
|------|------|------------|
| 400 | Bad Request | Ungültige Anfrage/Validierung |
| 401 | Unauthorized | Nicht authentifiziert |
| 403 | Forbidden | Keine Berechtigung |
| 404 | Not Found | Ressource nicht gefunden |
| 409 | Conflict | Konflikt (Duplikat) |
| 422 | Unprocessable | Semantisch ungültig |
| 429 | Too Many Requests | Rate Limit |
| 500 | Internal Error | Server-Fehler |

## Best Practices

### DO

1. **Prepared Statements** - Immer für SQL
2. **Input validieren** - Serverseitig, nie nur Client
3. **Output escapen** - Kontextabhängig (HTML, JSON, SQL)
4. **Rate Limiting** - Pro User und global
5. **Security Headers** - Für alle Responses
6. **HTTPS** - In Produktion Pflicht
7. **Generische Fehler** - Keine internen Details leaken
8. **Logging** - Aber sensitive Daten maskieren

### DON'T

1. **String Concatenation für SQL** - Nie!
2. **Sensitive Daten in URLs** - Tokens, Passwörter
3. **Detaillierte Fehlermeldungen** - In Produktion
4. **CORS *mit Credentials** - Sicherheitslücke
5. **Secrets im Code** - Environment Variables nutzen
6. **User-Input vertrauen** - Nie!
7. **Security by Obscurity** - Kein Ersatz für echte Sicherheit

## Sicherheits-Checkliste

```markdown
## Vor dem Deployment

- [ ] Alle Environment Variables gesetzt
- [ ] Secrets sicher gespeichert (nicht im Repo)
- [ ] HTTPS konfiguriert
- [ ] CORS auf erlaubte Origins beschränkt
- [ ] Rate Limiting aktiviert
- [ ] Security Headers gesetzt
- [ ] Alle SQL-Queries nutzen Prepared Statements
- [ ] Input-Validierung für alle Endpoints
- [ ] Fehler-Responses ohne interne Details
- [ ] Logging ohne sensitive Daten
- [ ] Dependencies auf Vulnerabilities geprüft
```

