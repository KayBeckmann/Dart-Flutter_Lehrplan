# Einheit 6.8: API-Dokumentation mit OpenAPI

## Lernziele

Nach dieser Einheit kannst du:
- OpenAPI/Swagger-Spezifikationen verstehen und schreiben
- API-Dokumentation automatisch generieren
- Interaktive API-Dokumentation bereitstellen
- Best Practices für API-Dokumentation anwenden

---

## Warum API-Dokumentation?

### Ohne Dokumentation

```
Entwickler: "Wie rufe ich den Login-Endpoint auf?"
Backend-Dev: "POST /api/auth mit email und password im Body"
Entwickler: "Welches Format? Was kommt zurück? Welche Fehler gibt es?"
Backend-Dev: "Moment, ich schau im Code nach..."
```

### Mit Dokumentation

- **Self-Service**: Entwickler finden alle Infos selbst
- **Konsistenz**: Eine zentrale Quelle der Wahrheit
- **Testbarkeit**: Endpoints direkt in der Doku testen
- **Onboarding**: Neue Teammitglieder schneller produktiv

---

## OpenAPI Spezifikation

**OpenAPI** (früher Swagger) ist der Industriestandard für REST-API-Dokumentation.

### Grundstruktur (YAML)

```yaml
openapi: 3.0.3
info:
  title: Produkt-API
  description: REST API für Produktverwaltung
  version: 1.0.0
  contact:
    name: API Support
    email: api@example.com

servers:
  - url: http://localhost:8080
    description: Lokaler Entwicklungsserver
  - url: https://api.example.com
    description: Produktionsserver

paths:
  /api/products:
    get:
      summary: Alle Produkte abrufen
      # ... Endpoint-Details
```

### Basis-Felder

| Feld | Beschreibung |
|------|--------------|
| `openapi` | Version der OpenAPI-Spezifikation |
| `info` | API-Metadaten (Titel, Version, Beschreibung) |
| `servers` | Verfügbare Server-URLs |
| `paths` | Alle API-Endpoints |
| `components` | Wiederverwendbare Schemas, Parameter |

---

## Endpoints dokumentieren

### GET-Endpoint mit Parametern

```yaml
paths:
  /api/products:
    get:
      summary: Produkte auflisten
      description: Gibt eine paginierte Liste aller Produkte zurück
      operationId: listProducts
      tags:
        - Products
      parameters:
        - name: page
          in: query
          description: Seitennummer
          required: false
          schema:
            type: integer
            default: 1
            minimum: 1
        - name: perPage
          in: query
          description: Elemente pro Seite
          required: false
          schema:
            type: integer
            default: 20
            minimum: 1
            maximum: 100
        - name: category
          in: query
          description: Nach Kategorie filtern
          required: false
          schema:
            type: string
            enum: [electronics, clothing, home, sports]
      responses:
        '200':
          description: Erfolgreiche Antwort
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'
        '400':
          description: Ungültige Parameter
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
```

### POST-Endpoint mit Request Body

```yaml
paths:
  /api/products:
    post:
      summary: Neues Produkt erstellen
      description: Erstellt ein neues Produkt und gibt es zurück
      operationId: createProduct
      tags:
        - Products
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductCreate'
            example:
              name: "Laptop Pro 15"
              description: "High-End Laptop mit 16GB RAM"
              price: 1299.99
              category: "electronics"
              brand: "TechBrand"
      responses:
        '201':
          description: Produkt erfolgreich erstellt
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
          headers:
            Location:
              description: URL des neuen Produkts
              schema:
                type: string
                example: /api/products/123
        '400':
          description: Validierungsfehler
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ValidationError'
        '409':
          description: Produkt existiert bereits
```

### Pfad-Parameter

```yaml
paths:
  /api/products/{id}:
    get:
      summary: Einzelnes Produkt abrufen
      operationId: getProduct
      tags:
        - Products
      parameters:
        - name: id
          in: path
          description: Produkt-ID
          required: true
          schema:
            type: string
            example: product-123
      responses:
        '200':
          description: Produkt gefunden
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '404':
          description: Produkt nicht gefunden
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

    put:
      summary: Produkt aktualisieren
      operationId: updateProduct
      tags:
        - Products
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductUpdate'
      responses:
        '200':
          description: Produkt aktualisiert
        '404':
          description: Produkt nicht gefunden

    delete:
      summary: Produkt löschen
      operationId: deleteProduct
      tags:
        - Products
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
      responses:
        '204':
          description: Produkt gelöscht
        '404':
          description: Produkt nicht gefunden
```

---

## Schemas definieren

### Components für Wiederverwendung

```yaml
components:
  schemas:
    Product:
      type: object
      required:
        - id
        - name
        - price
        - category
      properties:
        id:
          type: string
          description: Eindeutige Produkt-ID
          example: product-123
        name:
          type: string
          description: Produktname
          minLength: 2
          maxLength: 100
          example: "Laptop Pro 15"
        description:
          type: string
          description: Produktbeschreibung
          nullable: true
          example: "High-End Laptop mit 16GB RAM"
        price:
          type: number
          format: double
          description: Preis in Euro
          minimum: 0.01
          example: 1299.99
        category:
          type: string
          enum: [electronics, clothing, home, sports, books]
          example: electronics
        brand:
          type: string
          example: TechBrand
        stock:
          type: integer
          minimum: 0
          default: 0
          example: 42
        inStock:
          type: boolean
          readOnly: true
          example: true
        createdAt:
          type: string
          format: date-time
          readOnly: true
          example: "2024-01-15T10:30:00Z"

    ProductCreate:
      type: object
      required:
        - name
        - price
        - category
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
        description:
          type: string
          nullable: true
        price:
          type: number
          minimum: 0.01
        category:
          type: string
          enum: [electronics, clothing, home, sports, books]
        brand:
          type: string
        stock:
          type: integer
          minimum: 0
          default: 0

    ProductUpdate:
      type: object
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
        description:
          type: string
          nullable: true
        price:
          type: number
          minimum: 0.01
        category:
          type: string
          enum: [electronics, clothing, home, sports, books]
        brand:
          type: string
        stock:
          type: integer
          minimum: 0

    ProductList:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Product'
        meta:
          $ref: '#/components/schemas/PaginationMeta'
        links:
          $ref: '#/components/schemas/PaginationLinks'

    PaginationMeta:
      type: object
      properties:
        total:
          type: integer
          example: 150
        page:
          type: integer
          example: 1
        perPage:
          type: integer
          example: 20
        totalPages:
          type: integer
          example: 8
        hasNextPage:
          type: boolean
          example: true
        hasPrevPage:
          type: boolean
          example: false

    PaginationLinks:
      type: object
      properties:
        self:
          type: string
          example: "/api/products?page=1&perPage=20"
        first:
          type: string
          example: "/api/products?page=1&perPage=20"
        last:
          type: string
          example: "/api/products?page=8&perPage=20"
        prev:
          type: string
          nullable: true
        next:
          type: string
          nullable: true

    Error:
      type: object
      required:
        - error
      properties:
        error:
          type: string
          description: Fehlermeldung
          example: "Resource not found"
        code:
          type: string
          description: Fehlercode
          example: "NOT_FOUND"

    ValidationError:
      type: object
      properties:
        error:
          type: string
          example: "Validation failed"
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
                example: "email"
              message:
                type: string
                example: "Invalid email format"
```

---

## Authentifizierung dokumentieren

### API-Key

```yaml
components:
  securitySchemes:
    ApiKeyAuth:
      type: apiKey
      in: header
      name: X-API-Key
      description: API-Schlüssel im Header

security:
  - ApiKeyAuth: []

paths:
  /api/products:
    get:
      # Öffentlicher Endpoint (keine Auth nötig)
      security: []
      # ...

    post:
      # Erfordert API-Key
      security:
        - ApiKeyAuth: []
      # ...
```

### Bearer Token (JWT)

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT Token im Authorization Header

paths:
  /api/auth/login:
    post:
      summary: Benutzer einloggen
      security: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              required: [email, password]
              properties:
                email:
                  type: string
                  format: email
                password:
                  type: string
                  format: password
      responses:
        '200':
          description: Login erfolgreich
          content:
            application/json:
              schema:
                type: object
                properties:
                  token:
                    type: string
                    description: JWT Token
                  expiresIn:
                    type: integer
                    description: Gültigkeit in Sekunden
        '401':
          description: Ungültige Anmeldedaten

  /api/users/me:
    get:
      summary: Aktuellen Benutzer abrufen
      security:
        - BearerAuth: []
      responses:
        '200':
          description: Benutzerinfo
        '401':
          description: Nicht authentifiziert
```

---

## OpenAPI in Dart bereitstellen

### Statische OpenAPI-Datei

```dart
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_static/shelf_static.dart';

void main() async {
  final router = Router();

  // API-Endpoints
  router.mount('/api', apiRouter().call);

  // OpenAPI Spec als JSON/YAML
  router.get('/openapi.yaml', (Request r) async {
    final file = File('openapi.yaml');
    final content = await file.readAsString();
    return Response.ok(
      content,
      headers: {'content-type': 'application/x-yaml'},
    );
  });

  router.get('/openapi.json', (Request r) async {
    final file = File('openapi.json');
    final content = await file.readAsString();
    return Response.ok(
      content,
      headers: {'content-type': 'application/json'},
    );
  });

  // Swagger UI
  router.mount('/docs/', createStaticHandler('swagger-ui/'));

  await shelf_io.serve(router.call, 'localhost', 8080);
  print('API: http://localhost:8080/api');
  print('Docs: http://localhost:8080/docs/');
  print('Spec: http://localhost:8080/openapi.yaml');
}
```

### Inline OpenAPI Spec

```dart
const openApiSpec = '''
openapi: 3.0.3
info:
  title: Product API
  version: 1.0.0
paths:
  /api/products:
    get:
      summary: List products
      responses:
        '200':
          description: Success
''';

router.get('/openapi.yaml', (Request r) {
  return Response.ok(
    openApiSpec,
    headers: {'content-type': 'application/x-yaml'},
  );
});
```

---

## Swagger UI einbinden

### Download und Setup

```bash
# Swagger UI herunterladen
curl -L https://github.com/swagger-api/swagger-ui/archive/refs/tags/v5.11.0.tar.gz -o swagger-ui.tar.gz
tar -xzf swagger-ui.tar.gz
cp -r swagger-ui-5.11.0/dist swagger-ui

# Index.html anpassen (URL ändern)
sed -i 's|https://petstore.swagger.io/v2/swagger.json|/openapi.yaml|g' swagger-ui/swagger-initializer.js
```

### swagger-initializer.js anpassen

```javascript
window.onload = function() {
  window.ui = SwaggerUIBundle({
    url: "/openapi.yaml",
    dom_id: '#swagger-ui',
    presets: [
      SwaggerUIBundle.presets.apis,
      SwaggerUIStandalonePreset
    ],
    layout: "StandaloneLayout"
  });
};
```

### Mit Shelf Static

```dart
import 'package:shelf_static/shelf_static.dart';

// In pubspec.yaml:
// dependencies:
//   shelf_static: ^1.1.0

final router = Router();

// Swagger UI Dateien servieren
router.mount('/docs/', createStaticHandler(
  'swagger-ui',
  defaultDocument: 'index.html',
));
```

---

## Tags für Gruppierung

```yaml
tags:
  - name: Products
    description: Produktverwaltung
  - name: Categories
    description: Kategorieverwaltung
  - name: Auth
    description: Authentifizierung

paths:
  /api/products:
    get:
      tags: [Products]
      summary: Produkte auflisten

  /api/products/{id}:
    get:
      tags: [Products]
      summary: Einzelnes Produkt

  /api/categories:
    get:
      tags: [Categories]
      summary: Kategorien auflisten

  /api/auth/login:
    post:
      tags: [Auth]
      summary: Einloggen
```

---

## Beispiele hinzufügen

### Request/Response-Beispiele

```yaml
paths:
  /api/products:
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductCreate'
            examples:
              laptop:
                summary: Laptop erstellen
                value:
                  name: "MacBook Pro 14"
                  description: "Apple M3 Pro Chip"
                  price: 2499.00
                  category: "electronics"
                  brand: "Apple"
                  stock: 50
              shirt:
                summary: T-Shirt erstellen
                value:
                  name: "Basic T-Shirt"
                  price: 19.99
                  category: "clothing"
                  brand: "BasicBrand"
      responses:
        '201':
          content:
            application/json:
              examples:
                success:
                  summary: Erfolgreich erstellt
                  value:
                    id: "product-456"
                    name: "MacBook Pro 14"
                    price: 2499.00
                    category: "electronics"
                    inStock: true
                    createdAt: "2024-01-15T12:00:00Z"
```

---

## Vollständiges Beispiel

```yaml
openapi: 3.0.3
info:
  title: E-Commerce API
  description: |
    REST API für einen Online-Shop.

    ## Features
    - Produktverwaltung mit CRUD-Operationen
    - Pagination und Filtering
    - Volltextsuche
    - Authentifizierung via JWT

    ## Rate Limits
    - 100 Requests pro Minute für authentifizierte Benutzer
    - 20 Requests pro Minute für anonyme Benutzer
  version: 1.0.0
  contact:
    name: API Team
    email: api@shop.example.com
  license:
    name: MIT

servers:
  - url: http://localhost:8080
    description: Development
  - url: https://api.shop.example.com
    description: Production

tags:
  - name: Products
    description: Produkt-Endpoints
  - name: Search
    description: Such-Endpoints
  - name: Auth
    description: Authentifizierung

paths:
  /api/products:
    get:
      tags: [Products]
      summary: Produkte auflisten
      operationId: listProducts
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/PerPageParam'
        - name: category
          in: query
          schema:
            type: string
        - name: sort
          in: query
          schema:
            type: string
            enum: [name, price, createdAt]
        - name: order
          in: query
          schema:
            type: string
            enum: [asc, desc]
            default: asc
      responses:
        '200':
          description: Liste der Produkte
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'

    post:
      tags: [Products]
      summary: Produkt erstellen
      operationId: createProduct
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductCreate'
      responses:
        '201':
          description: Erstellt
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'

  /api/products/{id}:
    parameters:
      - $ref: '#/components/parameters/ProductId'
    get:
      tags: [Products]
      summary: Produkt abrufen
      operationId: getProduct
      responses:
        '200':
          description: Produkt gefunden
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '404':
          $ref: '#/components/responses/NotFound'

  /api/products/search:
    get:
      tags: [Search]
      summary: Produkte suchen
      operationId: searchProducts
      parameters:
        - name: q
          in: query
          required: true
          description: Suchbegriff
          schema:
            type: string
            minLength: 2
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/PerPageParam'
      responses:
        '200':
          description: Suchergebnisse
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'
        '400':
          description: Suchbegriff fehlt

components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

  parameters:
    ProductId:
      name: id
      in: path
      required: true
      schema:
        type: string
      example: product-123

    PageParam:
      name: page
      in: query
      schema:
        type: integer
        default: 1
        minimum: 1

    PerPageParam:
      name: perPage
      in: query
      schema:
        type: integer
        default: 20
        minimum: 1
        maximum: 100

  responses:
    NotFound:
      description: Ressource nicht gefunden
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

    ValidationError:
      description: Validierungsfehler
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ValidationError'

    Unauthorized:
      description: Nicht authentifiziert
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

  schemas:
    Product:
      type: object
      properties:
        id:
          type: string
        name:
          type: string
        price:
          type: number
        category:
          type: string
        inStock:
          type: boolean
        createdAt:
          type: string
          format: date-time

    ProductCreate:
      type: object
      required: [name, price, category]
      properties:
        name:
          type: string
        price:
          type: number
          minimum: 0.01
        category:
          type: string

    ProductList:
      type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Product'
        meta:
          $ref: '#/components/schemas/PaginationMeta'

    PaginationMeta:
      type: object
      properties:
        total:
          type: integer
        page:
          type: integer
        totalPages:
          type: integer

    Error:
      type: object
      properties:
        error:
          type: string

    ValidationError:
      type: object
      properties:
        error:
          type: string
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
              message:
                type: string
```

---

## Best Practices

### 1. Konsistente Benennung

```yaml
# GUT: camelCase für Parameter und Felder
parameters:
  - name: perPage
    in: query

# SCHLECHT: Inkonsistent
parameters:
  - name: per_page  # snake_case
  - name: PerPage   # PascalCase
```

### 2. Aussagekräftige Beschreibungen

```yaml
# GUT
parameters:
  - name: minPrice
    description: Mindestpreis in Euro (inklusive)
    schema:
      type: number
      minimum: 0
      example: 10.50

# SCHLECHT
parameters:
  - name: minPrice
    schema:
      type: number
```

### 3. Beispiele überall

```yaml
# GUT
properties:
  email:
    type: string
    format: email
    example: "max@example.com"
  createdAt:
    type: string
    format: date-time
    example: "2024-01-15T10:30:00Z"
```

### 4. Fehler-Responses dokumentieren

```yaml
# ALLE möglichen Fehler dokumentieren
responses:
  '200':
    description: Erfolg
  '400':
    description: Ungültige Eingabe
  '401':
    description: Nicht authentifiziert
  '403':
    description: Keine Berechtigung
  '404':
    description: Nicht gefunden
  '409':
    description: Konflikt (z.B. Duplikat)
  '500':
    description: Serverfehler
```

---

## Zusammenfassung

| Aspekt | Empfehlung |
|--------|------------|
| Format | OpenAPI 3.0 (YAML oder JSON) |
| UI | Swagger UI oder ReDoc |
| Schemas | In `components` definieren und referenzieren |
| Beispiele | Überall wo möglich hinzufügen |
| Tags | Endpoints logisch gruppieren |
| Auth | In `securitySchemes` dokumentieren |

---

## Nächste Schritte

Dies war die letzte Einheit von Block 6. Du hast nun alle Grundlagen für die Entwicklung professioneller REST-APIs mit Dart gelernt:

- REST-Prinzipien und API-Design
- JSON-Serialisierung
- Request Bodies verarbeiten
- CRUD-Operationen
- Input-Validierung
- Error Handling
- Pagination & Filtering
- API-Dokumentation

Setze dieses Wissen in deinem eigenen Projekt um!
