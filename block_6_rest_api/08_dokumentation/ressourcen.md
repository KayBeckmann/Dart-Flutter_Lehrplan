# Ressourcen: API-Dokumentation

## Offizielle Dokumentation

- [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)
- [Swagger Documentation](https://swagger.io/docs/)
- [Swagger Editor](https://editor.swagger.io/) - Online-Editor
- [OpenAPI Generator](https://openapi-generator.tech/)

## Tools

### Editoren

- [Swagger Editor](https://editor.swagger.io/) - Browser-basiert
- [Stoplight Studio](https://stoplight.io/studio) - Desktop App
- [VS Code OpenAPI Extension](https://marketplace.visualstudio.com/items?itemName=42Crunch.vscode-openapi)

### UI-Generatoren

- [Swagger UI](https://swagger.io/tools/swagger-ui/) - Interaktive Dokumentation
- [ReDoc](https://redocly.github.io/redoc/) - Lesbare Dokumentation
- [RapiDoc](https://rapidocweb.com/) - Moderne Alternative

### Validierung

```bash
# swagger-cli installieren
npm install -g @apidevtools/swagger-cli

# Spec validieren
swagger-cli validate openapi.yaml
```

## Cheat Sheet: Grundstruktur

```yaml
openapi: 3.0.3
info:
  title: API Name
  description: API Beschreibung
  version: 1.0.0
  contact:
    name: Support
    email: api@example.com

servers:
  - url: http://localhost:8080
    description: Development

tags:
  - name: Resources
    description: Resource endpoints

paths:
  /api/resource:
    get:
      # ...

components:
  schemas:
    # ...
  parameters:
    # ...
  responses:
    # ...
  securitySchemes:
    # ...
```

## Cheat Sheet: Parameter

```yaml
parameters:
  # Query Parameter
  - name: page
    in: query
    description: Seitennummer
    required: false
    schema:
      type: integer
      default: 1
      minimum: 1

  # Path Parameter
  - name: id
    in: path
    description: Ressourcen-ID
    required: true
    schema:
      type: string

  # Header Parameter
  - name: X-API-Key
    in: header
    required: true
    schema:
      type: string

  # Cookie Parameter
  - name: session
    in: cookie
    schema:
      type: string
```

## Cheat Sheet: Request Body

```yaml
requestBody:
  required: true
  description: Daten zum Erstellen
  content:
    application/json:
      schema:
        $ref: '#/components/schemas/CreateRequest'
      examples:
        example1:
          summary: Beispiel 1
          value:
            name: "Test"
            price: 99.99
        example2:
          summary: Beispiel 2
          value:
            name: "Test 2"
```

## Cheat Sheet: Responses

```yaml
responses:
  '200':
    description: Erfolg
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/Resource'

  '201':
    description: Erstellt
    headers:
      Location:
        description: URL der neuen Ressource
        schema:
          type: string

  '204':
    description: Kein Inhalt

  '400':
    description: Ungültige Anfrage
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/Error'

  '401':
    description: Nicht authentifiziert

  '403':
    description: Keine Berechtigung

  '404':
    description: Nicht gefunden

  '409':
    description: Konflikt

  '422':
    description: Validierungsfehler
    content:
      application/json:
        schema:
          $ref: '#/components/schemas/ValidationError'

  '500':
    description: Serverfehler
```

## Cheat Sheet: Schemas

```yaml
components:
  schemas:
    # Einfaches Schema
    User:
      type: object
      required:
        - id
        - email
      properties:
        id:
          type: string
          readOnly: true
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 2
          maxLength: 100
        age:
          type: integer
          minimum: 0
          maximum: 150
        role:
          type: string
          enum: [user, admin, moderator]
          default: user
        tags:
          type: array
          items:
            type: string
        metadata:
          type: object
          additionalProperties: true
        createdAt:
          type: string
          format: date-time
          readOnly: true

    # Nullable
    NullableField:
      type: string
      nullable: true

    # OneOf (einer von)
    Response:
      oneOf:
        - $ref: '#/components/schemas/Success'
        - $ref: '#/components/schemas/Error'

    # AllOf (Kombination)
    DetailedUser:
      allOf:
        - $ref: '#/components/schemas/User'
        - type: object
          properties:
            address:
              $ref: '#/components/schemas/Address'
```

## Cheat Sheet: Authentifizierung

```yaml
components:
  securitySchemes:
    # API Key
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key

    # Bearer Token
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

    # Basic Auth
    BasicAuth:
      type: http
      scheme: basic

    # OAuth 2.0
    OAuth2:
      type: oauth2
      flows:
        authorizationCode:
          authorizationUrl: https://auth.example.com/authorize
          tokenUrl: https://auth.example.com/token
          scopes:
            read: Read access
            write: Write access

# Global anwenden
security:
  - BearerAuth: []

# Pro Endpoint
paths:
  /public:
    get:
      security: []  # Keine Auth

  /private:
    get:
      security:
        - BearerAuth: []
```

## Cheat Sheet: Wiederverwendung

```yaml
components:
  # Parameter
  parameters:
    PageParam:
      name: page
      in: query
      schema:
        type: integer
        default: 1

  # Responses
  responses:
    NotFound:
      description: Not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

# Verwendung mit $ref
paths:
  /items:
    get:
      parameters:
        - $ref: '#/components/parameters/PageParam'
      responses:
        '404':
          $ref: '#/components/responses/NotFound'
```

## Cheat Sheet: Swagger UI in Dart

```dart
// Inline Swagger UI
Response serveSwaggerUI(Request request) {
  return Response.ok('''
<!DOCTYPE html>
<html>
<head>
  <title>API Docs</title>
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script>
    SwaggerUIBundle({
      url: '/openapi.yaml',
      dom_id: '#swagger-ui',
    });
  </script>
</body>
</html>
''', headers: {'content-type': 'text/html'});
}

// OpenAPI Spec servieren
Future<Response> serveOpenApi(Request request) async {
  final content = await File('openapi.yaml').readAsString();
  return Response.ok(content, headers: {
    'content-type': 'application/x-yaml',
  });
}

// Router
router.get('/docs', serveSwaggerUI);
router.get('/openapi.yaml', serveOpenApi);
```

## Datentypen

| OpenAPI | Dart | Format |
|---------|------|--------|
| `string` | `String` | - |
| `string` | `String` | `date` (2024-01-15) |
| `string` | `String` | `date-time` (ISO 8601) |
| `string` | `String` | `email` |
| `string` | `String` | `uri` |
| `string` | `String` | `uuid` |
| `string` | `String` | `password` |
| `integer` | `int` | `int32` |
| `integer` | `int` | `int64` |
| `number` | `double` | `float` |
| `number` | `double` | `double` |
| `boolean` | `bool` | - |
| `array` | `List` | - |
| `object` | `Map` / Class | - |

## Best Practices

1. **Konsistente Benennung**: camelCase für Felder
2. **Aussagekräftige Beschreibungen**: Jedes Feld dokumentieren
3. **Beispiele überall**: examples für Requests und Responses
4. **Fehler dokumentieren**: Alle möglichen Fehlercodes
5. **Wiederverwendung**: Components nutzen
6. **Tags**: Endpoints logisch gruppieren
7. **Versionierung**: Im Info-Block und URL
8. **Validierung**: Schema mit Constraints

## Validierung der Spec

```bash
# Online
# https://editor.swagger.io

# CLI
npm install -g @apidevtools/swagger-cli
swagger-cli validate openapi.yaml

# Spectral (Linting)
npm install -g @stoplight/spectral-cli
spectral lint openapi.yaml
```

## Code-Generierung

```bash
# Dart Client generieren
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g dart \
  -o ./generated/client

# Server Stub generieren
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g dart-shelf \
  -o ./generated/server
```

## Alternative UIs

### ReDoc

```html
<!DOCTYPE html>
<html>
<head>
  <title>API Docs</title>
  <link href="https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700" rel="stylesheet">
  <style>body { margin: 0; padding: 0; }</style>
</head>
<body>
  <redoc spec-url='/openapi.yaml'></redoc>
  <script src="https://cdn.redoc.ly/redoc/latest/bundles/redoc.standalone.js"></script>
</body>
</html>
```

### RapiDoc

```html
<!DOCTYPE html>
<html>
<head>
  <title>API Docs</title>
  <script type="module" src="https://unpkg.com/rapidoc/dist/rapidoc-min.js"></script>
</head>
<body>
  <rapi-doc spec-url="/openapi.yaml" theme="dark"></rapi-doc>
</body>
</html>
```
