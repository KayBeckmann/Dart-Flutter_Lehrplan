# Übung 6.8: API-Dokumentation

## Ziel

Erstelle eine vollständige OpenAPI-Dokumentation für die Produkt-API und stelle sie mit Swagger UI bereit.

---

## Aufgabe 1: OpenAPI-Grundstruktur (10 min)

Erstelle eine Datei `openapi.yaml` mit der Grundstruktur.

### Anforderungen

- OpenAPI Version 3.0.3
- API-Titel: "Product API"
- Version: 1.0.0
- Beschreibung: Kurze API-Beschreibung
- Server: localhost:8080 (Development)

### Erwartete Struktur

```yaml
openapi: 3.0.3
info:
  title: ...
  description: ...
  version: ...
servers:
  - url: ...
    description: ...
```

---

## Aufgabe 2: Schemas definieren (15 min)

Definiere die Schemas für Product, ProductCreate und Error.

### Product-Schema

| Feld | Typ | Required | Beschreibung |
|------|-----|----------|--------------|
| id | string | Ja | Eindeutige ID |
| name | string | Ja | Produktname (2-100 Zeichen) |
| description | string | Nein | Beschreibung |
| price | number | Ja | Preis (min 0.01) |
| category | string | Ja | Enum: electronics, clothing, home |
| stock | integer | Nein | Lagerbestand (min 0, default 0) |
| inStock | boolean | ReadOnly | Automatisch berechnet |
| createdAt | date-time | ReadOnly | Erstellungsdatum |

### ProductCreate-Schema

Wie Product, aber ohne `id`, `inStock`, `createdAt`

### Error-Schema

```yaml
properties:
  error:
    type: string
  code:
    type: string
```

---

## Aufgabe 3: GET /api/products dokumentieren (15 min)

Dokumentiere den List-Endpoint mit allen Query-Parametern.

### Parameter

| Parameter | Typ | Default | Beschreibung |
|-----------|-----|---------|--------------|
| page | integer | 1 | Seitennummer (min 1) |
| perPage | integer | 20 | Pro Seite (1-100) |
| category | string | - | Kategorie-Filter |
| sort | string | createdAt | Sortierfeld |
| order | string | desc | asc oder desc |

### Response 200

Definiere `ProductList`-Schema mit:
- `data`: Array von Product
- `meta`: PaginationMeta (total, page, perPage, totalPages)
- `links`: PaginationLinks (self, first, last, prev, next)

### Response 400

Verwende Error-Schema

---

## Aufgabe 4: CRUD-Endpoints dokumentieren (20 min)

Dokumentiere alle Product-Endpoints.

### POST /api/products

- Summary: Produkt erstellen
- Request Body: ProductCreate
- Response 201: Product + Location Header
- Response 400: Validierungsfehler

### GET /api/products/{id}

- Path Parameter: id (required)
- Response 200: Product
- Response 404: Nicht gefunden

### PUT /api/products/{id}

- Path Parameter: id
- Request Body: ProductUpdate (alle Felder optional)
- Response 200: Product
- Response 404: Nicht gefunden

### DELETE /api/products/{id}

- Path Parameter: id
- Response 204: Kein Content
- Response 404: Nicht gefunden

---

## Aufgabe 5: Such-Endpoint dokumentieren (10 min)

### GET /api/products/search

- Query Parameter: `q` (required, minLength 2)
- Zusätzlich: page, perPage, category (wie bei List)
- Response 200: ProductList
- Response 400: Wenn `q` fehlt

---

## Aufgabe 6: Wiederverwendbare Components (10 min)

Refactore die Spec mit `$ref`:

### Parameters

```yaml
components:
  parameters:
    ProductId:
      name: id
      in: path
      required: true
      schema:
        type: string

    PageParam:
      name: page
      in: query
      schema:
        type: integer
        default: 1

    PerPageParam:
      name: perPage
      in: query
      schema:
        type: integer
        default: 20
        maximum: 100
```

### Responses

```yaml
components:
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
```

### Verwendung

```yaml
paths:
  /api/products/{id}:
    parameters:
      - $ref: '#/components/parameters/ProductId'
    get:
      responses:
        '404':
          $ref: '#/components/responses/NotFound'
```

---

## Aufgabe 7: Tags hinzufügen (5 min)

Gruppiere Endpoints mit Tags:

- `Products`: Alle CRUD-Endpoints
- `Search`: Such-Endpoint
- `Meta`: Kategorien und Brands

```yaml
tags:
  - name: Products
    description: Produktverwaltung (CRUD)
  - name: Search
    description: Produktsuche
  - name: Meta
    description: Metadaten (Kategorien, Marken)
```

---

## Aufgabe 8: Swagger UI einrichten (15 min)

Stelle die Dokumentation mit Swagger UI bereit.

### Schritte

1. OpenAPI-Spec als Endpoint bereitstellen:

```dart
router.get('/openapi.yaml', (Request r) async {
  final content = await File('openapi.yaml').readAsString();
  return Response.ok(content, headers: {
    'content-type': 'application/x-yaml',
  });
});
```

2. Swagger UI einbinden (Option A - CDN):

```dart
router.get('/docs', (Request r) {
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
});
```

3. Server starten und testen:

```bash
curl http://localhost:8080/openapi.yaml
# Browser: http://localhost:8080/docs
```

---

## Aufgabe 9: Beispiele hinzufügen (10 min)

Füge Beispiele für Request und Response hinzu.

### Request-Beispiele

```yaml
requestBody:
  content:
    application/json:
      examples:
        laptop:
          summary: Laptop erstellen
          value:
            name: "Gaming Laptop"
            description: "RTX 4080, 32GB RAM"
            price: 2499.99
            category: "electronics"
            stock: 10
        shirt:
          summary: T-Shirt erstellen
          value:
            name: "Basic T-Shirt"
            price: 19.99
            category: "clothing"
```

### Response-Beispiele

```yaml
responses:
  '200':
    content:
      application/json:
        examples:
          singleProduct:
            summary: Einzelnes Produkt
            value:
              id: "product-123"
              name: "Gaming Laptop"
              price: 2499.99
              inStock: true
```

---

## Aufgabe 10: Authentifizierung dokumentieren (Bonus, 10 min)

Füge JWT-Authentifizierung hinzu.

### Security Scheme

```yaml
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: JWT Token aus /api/auth/login
```

### Auf Endpoints anwenden

```yaml
paths:
  /api/products:
    get:
      # Öffentlich - kein security
      security: []

    post:
      # Erfordert Auth
      security:
        - BearerAuth: []

  /api/products/{id}:
    put:
      security:
        - BearerAuth: []
    delete:
      security:
        - BearerAuth: []
```

### Login-Endpoint

```yaml
/api/auth/login:
  post:
    tags: [Auth]
    summary: JWT Token erhalten
    security: []
    requestBody:
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
                expiresIn:
                  type: integer
      '401':
        description: Ungültige Anmeldedaten
```

---

## Testen

### OpenAPI Spec validieren

```bash
# Online Validator
# https://editor.swagger.io - Spec einfügen

# Oder mit CLI
npm install -g @apidevtools/swagger-cli
swagger-cli validate openapi.yaml
```

### Swagger UI prüfen

1. Server starten: `dart run bin/server.dart`
2. Browser öffnen: `http://localhost:8080/docs`
3. Endpoints durchklicken
4. "Try it out" testen

---

## Abgabe-Checkliste

- [ ] openapi.yaml mit korrekter Grundstruktur
- [ ] Product, ProductCreate, ProductUpdate Schemas
- [ ] Error und ValidationError Schemas
- [ ] GET /api/products mit Pagination-Parametern
- [ ] POST /api/products dokumentiert
- [ ] GET/PUT/DELETE /api/products/{id} dokumentiert
- [ ] GET /api/products/search dokumentiert
- [ ] Wiederverwendbare Parameters und Responses
- [ ] Tags für Gruppierung
- [ ] Swagger UI funktioniert
- [ ] Mindestens 2 Request/Response-Beispiele
- [ ] (Bonus) JWT-Authentifizierung dokumentiert
