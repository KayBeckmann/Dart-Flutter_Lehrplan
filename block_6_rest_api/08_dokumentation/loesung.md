# Lösung 6.8: API-Dokumentation

## openapi.yaml

```yaml
openapi: 3.0.3
info:
  title: Product API
  description: |
    REST API für Produktverwaltung.

    ## Features
    - CRUD-Operationen für Produkte
    - Pagination und Filtering
    - Volltextsuche
    - Kategorien und Marken

    ## Authentifizierung
    Schreibende Operationen (POST, PUT, DELETE) erfordern einen JWT-Token.
    Token über POST /api/auth/login erhalten.
  version: 1.0.0
  contact:
    name: API Support
    email: api@example.com

servers:
  - url: http://localhost:8080
    description: Development Server

tags:
  - name: Products
    description: Produktverwaltung (CRUD)
  - name: Search
    description: Produktsuche
  - name: Meta
    description: Metadaten (Kategorien, Marken)
  - name: Auth
    description: Authentifizierung

paths:
  # ==========================================
  # Products
  # ==========================================
  /api/products:
    get:
      tags: [Products]
      summary: Produkte auflisten
      description: Gibt eine paginierte Liste aller Produkte zurück. Unterstützt Filtering und Sortierung.
      operationId: listProducts
      parameters:
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/PerPageParam'
        - name: category
          in: query
          description: Nach Kategorie filtern
          schema:
            type: string
            enum: [electronics, clothing, home, sports, books]
        - name: brand
          in: query
          description: Nach Marke filtern
          schema:
            type: string
        - name: inStock
          in: query
          description: Nur verfügbare Produkte
          schema:
            type: boolean
        - name: minPrice
          in: query
          description: Mindestpreis
          schema:
            type: number
            minimum: 0
        - name: maxPrice
          in: query
          description: Höchstpreis
          schema:
            type: number
        - name: sort
          in: query
          description: Sortierfeld
          schema:
            type: string
            enum: [name, price, createdAt, rating, stock]
            default: createdAt
        - name: order
          in: query
          description: Sortierrichtung
          schema:
            type: string
            enum: [asc, desc]
            default: desc
      responses:
        '200':
          description: Liste der Produkte
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ProductList'
              examples:
                withProducts:
                  summary: Mit Produkten
                  value:
                    data:
                      - id: "product-1"
                        name: "Laptop Pro"
                        price: 1299.99
                        category: "electronics"
                        inStock: true
                    meta:
                      total: 50
                      page: 1
                      perPage: 20
                      totalPages: 3
                      hasNextPage: true
                      hasPrevPage: false
                    links:
                      self: "/api/products?page=1&perPage=20"
                      next: "/api/products?page=2&perPage=20"
                empty:
                  summary: Keine Produkte
                  value:
                    data: []
                    meta:
                      total: 0
                      page: 1
                      perPage: 20
                      totalPages: 0
                      hasNextPage: false
                      hasPrevPage: false
        '400':
          $ref: '#/components/responses/BadRequest'

    post:
      tags: [Products]
      summary: Produkt erstellen
      description: Erstellt ein neues Produkt. Erfordert Authentifizierung.
      operationId: createProduct
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductCreate'
            examples:
              laptop:
                summary: Laptop erstellen
                value:
                  name: "Gaming Laptop X"
                  description: "High-End Gaming Laptop mit RTX 4080"
                  price: 2499.99
                  category: "electronics"
                  brand: "TechBrand"
                  stock: 25
              shirt:
                summary: T-Shirt erstellen
                value:
                  name: "Basic Cotton T-Shirt"
                  description: "100% Baumwolle, verschiedene Farben"
                  price: 24.99
                  category: "clothing"
                  brand: "FashionCo"
                  stock: 100
      responses:
        '201':
          description: Produkt erstellt
          headers:
            Location:
              description: URL des neuen Produkts
              schema:
                type: string
                example: /api/products/product-123
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '409':
          description: Produkt existiert bereits
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

  /api/products/{id}:
    parameters:
      - $ref: '#/components/parameters/ProductId'

    get:
      tags: [Products]
      summary: Produkt abrufen
      description: Gibt ein einzelnes Produkt anhand seiner ID zurück
      operationId: getProduct
      responses:
        '200':
          description: Produkt gefunden
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
              example:
                id: "product-123"
                name: "Gaming Laptop X"
                description: "High-End Gaming Laptop"
                price: 2499.99
                category: "electronics"
                brand: "TechBrand"
                stock: 25
                inStock: true
                rating: 4.5
                createdAt: "2024-01-15T10:30:00Z"
        '404':
          $ref: '#/components/responses/NotFound'

    put:
      tags: [Products]
      summary: Produkt aktualisieren
      description: Aktualisiert ein bestehendes Produkt. Nur geänderte Felder senden.
      operationId: updateProduct
      security:
        - BearerAuth: []
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ProductUpdate'
            examples:
              priceUpdate:
                summary: Preis ändern
                value:
                  price: 1999.99
              fullUpdate:
                summary: Mehrere Felder ändern
                value:
                  name: "Gaming Laptop X Pro"
                  price: 2799.99
                  stock: 15
      responses:
        '200':
          description: Produkt aktualisiert
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Product'
        '400':
          $ref: '#/components/responses/ValidationError'
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'

    delete:
      tags: [Products]
      summary: Produkt löschen
      description: Löscht ein Produkt permanent
      operationId: deleteProduct
      security:
        - BearerAuth: []
      responses:
        '204':
          description: Produkt gelöscht
        '401':
          $ref: '#/components/responses/Unauthorized'
        '404':
          $ref: '#/components/responses/NotFound'

  # ==========================================
  # Search
  # ==========================================
  /api/products/search:
    get:
      tags: [Search]
      summary: Produkte suchen
      description: |
        Volltextsuche in Produkten.
        Durchsucht: name, description, brand
      operationId: searchProducts
      parameters:
        - name: q
          in: query
          required: true
          description: Suchbegriff (mindestens 2 Zeichen)
          schema:
            type: string
            minLength: 2
          example: laptop
        - $ref: '#/components/parameters/PageParam'
        - $ref: '#/components/parameters/PerPageParam'
        - name: category
          in: query
          description: Zusätzlicher Kategorie-Filter
          schema:
            type: string
        - name: minPrice
          in: query
          schema:
            type: number
        - name: maxPrice
          in: query
          schema:
            type: number
      responses:
        '200':
          description: Suchergebnisse
          content:
            application/json:
              schema:
                allOf:
                  - $ref: '#/components/schemas/ProductList'
                  - type: object
                    properties:
                      meta:
                        type: object
                        properties:
                          query:
                            type: string
                            example: "laptop"
              example:
                data:
                  - id: "product-1"
                    name: "Gaming Laptop"
                    price: 1499.99
                meta:
                  query: "laptop"
                  total: 5
                  page: 1
                  perPage: 20
        '400':
          description: Suchbegriff fehlt oder zu kurz
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
              example:
                error: "Search query (q) is required"
                code: "MISSING_QUERY"

  # ==========================================
  # Meta
  # ==========================================
  /api/categories:
    get:
      tags: [Meta]
      summary: Kategorien abrufen
      description: Liste aller verfügbaren Produktkategorien
      operationId: getCategories
      responses:
        '200':
          description: Liste der Kategorien
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      type: string
                  total:
                    type: integer
              example:
                data: ["books", "clothing", "electronics", "home", "sports"]
                total: 5

  /api/brands:
    get:
      tags: [Meta]
      summary: Marken abrufen
      description: Liste aller verfügbaren Marken
      operationId: getBrands
      responses:
        '200':
          description: Liste der Marken
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items:
                      type: string
                  total:
                    type: integer
              example:
                data: ["Adidas", "Apple", "Nike", "Samsung", "Sony"]
                total: 5

  # ==========================================
  # Auth
  # ==========================================
  /api/auth/login:
    post:
      tags: [Auth]
      summary: Einloggen
      description: JWT Token erhalten für authentifizierte Requests
      operationId: login
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
                  example: admin@example.com
                password:
                  type: string
                  format: password
                  example: secret123
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
              example:
                token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
                expiresIn: 3600
        '401':
          description: Ungültige Anmeldedaten
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'
              example:
                error: "Invalid credentials"
                code: "INVALID_CREDENTIALS"

# ==========================================
# Components
# ==========================================
components:
  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT
      description: |
        JWT Token im Authorization Header.
        Format: `Authorization: Bearer <token>`

        Token über POST /api/auth/login erhalten.

  parameters:
    ProductId:
      name: id
      in: path
      required: true
      description: Eindeutige Produkt-ID
      schema:
        type: string
      example: product-123

    PageParam:
      name: page
      in: query
      description: Seitennummer (ab 1)
      schema:
        type: integer
        default: 1
        minimum: 1
      example: 1

    PerPageParam:
      name: perPage
      in: query
      description: Elemente pro Seite
      schema:
        type: integer
        default: 20
        minimum: 1
        maximum: 100
      example: 20

  responses:
    NotFound:
      description: Ressource nicht gefunden
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "Product not found"
            code: "NOT_FOUND"

    BadRequest:
      description: Ungültige Anfrage
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "Invalid parameters"
            code: "BAD_REQUEST"

    ValidationError:
      description: Validierungsfehler
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/ValidationError'
          example:
            error: "Validation failed"
            code: "VALIDATION_ERROR"
            details:
              - field: "price"
                message: "Price must be greater than 0"
              - field: "name"
                message: "Name is required"

    Unauthorized:
      description: Nicht authentifiziert
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'
          example:
            error: "Authentication required"
            code: "UNAUTHORIZED"

  schemas:
    Product:
      type: object
      description: Vollständiges Produktobjekt
      required:
        - id
        - name
        - price
        - category
      properties:
        id:
          type: string
          description: Eindeutige Produkt-ID
          readOnly: true
          example: product-123
        name:
          type: string
          description: Produktname
          minLength: 2
          maxLength: 100
          example: "Gaming Laptop X"
        description:
          type: string
          description: Produktbeschreibung
          nullable: true
          example: "High-End Gaming Laptop mit RTX 4080"
        price:
          type: number
          format: double
          description: Preis in Euro
          minimum: 0.01
          example: 2499.99
        category:
          type: string
          description: Produktkategorie
          enum: [electronics, clothing, home, sports, books]
          example: electronics
        brand:
          type: string
          description: Markenname
          example: TechBrand
        stock:
          type: integer
          description: Lagerbestand
          minimum: 0
          default: 0
          example: 25
        inStock:
          type: boolean
          description: Ob auf Lager (berechnet aus stock > 0)
          readOnly: true
          example: true
        rating:
          type: number
          description: Durchschnittliche Bewertung (1-5)
          minimum: 1
          maximum: 5
          example: 4.5
        createdAt:
          type: string
          format: date-time
          description: Erstellungsdatum
          readOnly: true
          example: "2024-01-15T10:30:00Z"

    ProductCreate:
      type: object
      description: Daten zum Erstellen eines Produkts
      required:
        - name
        - price
        - category
      properties:
        name:
          type: string
          minLength: 2
          maxLength: 100
          example: "Neues Produkt"
        description:
          type: string
          nullable: true
          example: "Produktbeschreibung"
        price:
          type: number
          minimum: 0.01
          example: 99.99
        category:
          type: string
          enum: [electronics, clothing, home, sports, books]
          example: electronics
        brand:
          type: string
          example: "BrandName"
        stock:
          type: integer
          minimum: 0
          default: 0
          example: 10

    ProductUpdate:
      type: object
      description: Daten zum Aktualisieren eines Produkts. Alle Felder optional.
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
      description: Paginierte Liste von Produkten
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
      description: Pagination-Metadaten
      properties:
        total:
          type: integer
          description: Gesamtanzahl der Elemente
          example: 150
        page:
          type: integer
          description: Aktuelle Seite
          example: 1
        perPage:
          type: integer
          description: Elemente pro Seite
          example: 20
        totalPages:
          type: integer
          description: Gesamtanzahl der Seiten
          example: 8
        hasNextPage:
          type: boolean
          description: Gibt es eine nächste Seite?
          example: true
        hasPrevPage:
          type: boolean
          description: Gibt es eine vorherige Seite?
          example: false
        filtered:
          type: boolean
          description: Wurden Filter angewendet?
          example: false
        appliedFilters:
          type: object
          description: Angewendete Filter
          additionalProperties: true

    PaginationLinks:
      type: object
      description: HATEOAS Navigation-Links
      properties:
        self:
          type: string
          description: Link zur aktuellen Seite
          example: "/api/products?page=1&perPage=20"
        first:
          type: string
          description: Link zur ersten Seite
          example: "/api/products?page=1&perPage=20"
        last:
          type: string
          description: Link zur letzten Seite
          example: "/api/products?page=8&perPage=20"
        prev:
          type: string
          nullable: true
          description: Link zur vorherigen Seite (null wenn erste Seite)
        next:
          type: string
          nullable: true
          description: Link zur nächsten Seite (null wenn letzte Seite)
          example: "/api/products?page=2&perPage=20"

    Error:
      type: object
      description: Fehlerobjekt
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
      description: Validierungsfehler mit Details
      properties:
        error:
          type: string
          example: "Validation failed"
        code:
          type: string
          example: "VALIDATION_ERROR"
        details:
          type: array
          items:
            type: object
            properties:
              field:
                type: string
                description: Feldname
                example: "email"
              message:
                type: string
                description: Fehlerbeschreibung
                example: "Invalid email format"
```

---

## Dart Server mit Swagger UI

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Models (gekürzt)
// ============================================

class Product {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String category;
  final String brand;
  final int stock;
  final double rating;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.brand,
    required this.stock,
    required this.rating,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'price': price,
    'category': category,
    'brand': brand,
    'stock': stock,
    'inStock': stock > 0,
    'rating': rating,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ============================================
// Storage
// ============================================

final _products = <String, Product>{};

void _seedData() {
  final random = Random(42);
  final categories = ['electronics', 'clothing', 'home', 'sports', 'books'];
  final brands = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Sony'];

  for (var i = 1; i <= 50; i++) {
    _products['product-$i'] = Product(
      id: 'product-$i',
      name: '${brands[i % brands.length]} Product $i',
      description: 'Description for product $i',
      price: (random.nextDouble() * 1000 + 10).roundToDouble(),
      category: categories[i % categories.length],
      brand: brands[i % brands.length],
      stock: random.nextInt(100),
      rating: 1 + random.nextDouble() * 4,
      createdAt: DateTime.now().subtract(Duration(days: i)),
    );
  }
}

// ============================================
// Helpers
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

// ============================================
// API Handlers (vereinfacht)
// ============================================

Response listProducts(Request request) {
  final params = request.url.queryParameters;
  final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 1000);
  final perPage = (int.tryParse(params['perPage'] ?? '20') ?? 20).clamp(1, 100);

  var products = _products.values.toList();

  // Filter
  final category = params['category'];
  if (category != null) {
    products = products.where((p) => p.category == category).toList();
  }

  // Sortierung
  final sort = params['sort'] ?? 'createdAt';
  final order = params['order'] ?? 'desc';

  products = [...products]..sort((a, b) {
    int cmp = switch (sort) {
      'name' => a.name.compareTo(b.name),
      'price' => a.price.compareTo(b.price),
      _ => a.createdAt.compareTo(b.createdAt),
    };
    return order == 'desc' ? -cmp : cmp;
  });

  // Pagination
  final total = products.length;
  final totalPages = total > 0 ? (total / perPage).ceil() : 1;
  final offset = (page - 1) * perPage;
  final pagedProducts = products.skip(offset).take(perPage).toList();

  return jsonResponse({
    'data': pagedProducts.map((p) => p.toJson()).toList(),
    'meta': {
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
      'hasNextPage': page < totalPages,
      'hasPrevPage': page > 1,
    },
    'links': {
      'self': '/api/products?page=$page&perPage=$perPage',
      'first': '/api/products?page=1&perPage=$perPage',
      'last': '/api/products?page=$totalPages&perPage=$perPage',
      if (page > 1) 'prev': '/api/products?page=${page - 1}&perPage=$perPage',
      if (page < totalPages) 'next': '/api/products?page=${page + 1}&perPage=$perPage',
    },
  });
}

Response getProduct(Request request, String id) {
  final product = _products[id];
  if (product == null) {
    return jsonResponse({'error': 'Product not found', 'code': 'NOT_FOUND'}, statusCode: 404);
  }
  return jsonResponse(product.toJson());
}

Response getCategories(Request request) {
  final categories = _products.values.map((p) => p.category).toSet().toList()..sort();
  return jsonResponse({'data': categories, 'total': categories.length});
}

Response getBrands(Request request) {
  final brands = _products.values.map((p) => p.brand).toSet().toList()..sort();
  return jsonResponse({'data': brands, 'total': brands.length});
}

// ============================================
// OpenAPI & Swagger UI
// ============================================

Future<Response> serveOpenApi(Request request) async {
  try {
    final file = File('openapi.yaml');
    if (!await file.exists()) {
      return Response.notFound('openapi.yaml not found');
    }
    final content = await file.readAsString();
    return Response.ok(content, headers: {
      'content-type': 'application/x-yaml',
      'access-control-allow-origin': '*',
    });
  } catch (e) {
    return Response.internalServerError(body: 'Error reading openapi.yaml');
  }
}

Response serveSwaggerUI(Request request) {
  const html = '''
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Product API - Documentation</title>
  <link rel="stylesheet" type="text/css" href="https://unpkg.com/swagger-ui-dist@5/swagger-ui.css">
  <style>
    html { box-sizing: border-box; overflow-y: scroll; }
    *, *:before, *:after { box-sizing: inherit; }
    body { margin: 0; background: #fafafa; }
    .swagger-ui .topbar { display: none; }
  </style>
</head>
<body>
  <div id="swagger-ui"></div>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
  <script src="https://unpkg.com/swagger-ui-dist@5/swagger-ui-standalone-preset.js"></script>
  <script>
    window.onload = function() {
      window.ui = SwaggerUIBundle({
        url: "/openapi.yaml",
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        plugins: [
          SwaggerUIBundle.plugins.DownloadUrl
        ],
        layout: "StandaloneLayout",
        defaultModelsExpandDepth: 1,
        defaultModelExpandDepth: 1,
        docExpansion: "list",
        filter: true,
        showExtensions: true,
        showCommonExtensions: true
      });
    };
  </script>
</body>
</html>
''';

  return Response.ok(html, headers: {'content-type': 'text/html; charset=utf-8'});
}

// ============================================
// Main
// ============================================

void main() async {
  _seedData();

  final router = Router();

  // API Endpoints
  router.get('/api/products', listProducts);
  router.get('/api/products/<id>', getProduct);
  router.get('/api/categories', getCategories);
  router.get('/api/brands', getBrands);

  // OpenAPI Spec
  router.get('/openapi.yaml', serveOpenApi);
  router.get('/openapi.json', serveOpenApi);  // Auch als JSON-Pfad

  // Swagger UI
  router.get('/docs', serveSwaggerUI);
  router.get('/docs/', serveSwaggerUI);

  // CORS für Swagger UI
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware((handler) {
        return (request) async {
          if (request.method == 'OPTIONS') {
            return Response.ok('', headers: {
              'access-control-allow-origin': '*',
              'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
              'access-control-allow-headers': 'Content-Type, Authorization',
            });
          }
          final response = await handler(request);
          return response.change(headers: {
            ...response.headers,
            'access-control-allow-origin': '*',
          });
        };
      })
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);

  print('');
  print('╔════════════════════════════════════════════╗');
  print('║       Product API Server Running           ║');
  print('╠════════════════════════════════════════════╣');
  print('║  API:     http://localhost:8080/api        ║');
  print('║  Docs:    http://localhost:8080/docs       ║');
  print('║  OpenAPI: http://localhost:8080/openapi.yaml ║');
  print('╚════════════════════════════════════════════╝');
  print('');
}
```

---

## Test-Befehle

```bash
# Server starten
dart run bin/server.dart

# OpenAPI Spec abrufen
curl http://localhost:8080/openapi.yaml

# Swagger UI öffnen
open http://localhost:8080/docs

# API testen
curl http://localhost:8080/api/products
curl http://localhost:8080/api/products/product-1
curl http://localhost:8080/api/categories
curl http://localhost:8080/api/brands

# Mit Filtern
curl "http://localhost:8080/api/products?category=electronics&sort=price&order=asc"
```

---

## Projektstruktur

```
project/
├── bin/
│   └── server.dart       # Server-Code
├── openapi.yaml          # OpenAPI Spezifikation
└── pubspec.yaml
```

### pubspec.yaml

```yaml
name: product_api
description: Product API with OpenAPI documentation

environment:
  sdk: ^3.0.0

dependencies:
  shelf: ^1.4.1
  shelf_router: ^1.1.4
```

---

## Wichtige Patterns

### Wiederverwendbare Parameter

```yaml
# Definition
components:
  parameters:
    PageParam:
      name: page
      in: query
      schema:
        type: integer
        default: 1

# Verwendung
paths:
  /api/products:
    get:
      parameters:
        - $ref: '#/components/parameters/PageParam'
```

### Wiederverwendbare Responses

```yaml
# Definition
components:
  responses:
    NotFound:
      description: Not found
      content:
        application/json:
          schema:
            $ref: '#/components/schemas/Error'

# Verwendung
responses:
  '404':
    $ref: '#/components/responses/NotFound'
```

### Schema-Vererbung

```yaml
ProductList:
  allOf:
    - $ref: '#/components/schemas/PaginatedResponse'
    - type: object
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/Product'
```
