# Lösung 6.1: REST-Prinzipien & API-Design

## Aufgabe 1: API-Design

### Produkte

| Aktion | Methode | Pfad | Statuscode |
|--------|---------|------|------------|
| Alle Produkte | GET | /api/v1/products | 200 |
| Ein Produkt | GET | /api/v1/products/:id | 200 / 404 |
| Erstellen | POST | /api/v1/products | 201 |
| Ersetzen | PUT | /api/v1/products/:id | 200 / 404 |
| Aktualisieren | PATCH | /api/v1/products/:id | 200 / 404 |
| Löschen | DELETE | /api/v1/products/:id | 204 / 404 |

### Kategorien

| Aktion | Methode | Pfad | Statuscode |
|--------|---------|------|------------|
| Alle Kategorien | GET | /api/v1/categories | 200 |
| Eine Kategorie | GET | /api/v1/categories/:id | 200 / 404 |
| Produkte einer Kategorie | GET | /api/v1/categories/:id/products | 200 / 404 |

### Bestellungen

| Aktion | Methode | Pfad | Statuscode |
|--------|---------|------|------------|
| Alle Bestellungen | GET | /api/v1/orders | 200 |
| Eine Bestellung | GET | /api/v1/orders/:id | 200 / 404 |
| Bestellung erstellen | POST | /api/v1/orders | 201 |
| Positionen einer Bestellung | GET | /api/v1/orders/:id/items | 200 / 404 |

---

## Vollständige Lösung

```dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Models
// ============================================

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final int stock;
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.description = '',
    required this.price,
    required this.categoryId,
    this.stock = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'price': price,
    'categoryId': categoryId,
    'stock': stock,
    'createdAt': createdAt.toIso8601String(),
  };

  Product copyWith({
    String? name,
    String? description,
    double? price,
    String? categoryId,
    int? stock,
  }) => Product(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    price: price ?? this.price,
    categoryId: categoryId ?? this.categoryId,
    stock: stock ?? this.stock,
    createdAt: createdAt,
  );
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

// ============================================
// Data Store
// ============================================

final _products = <String, Product>{};
final _categories = <String, Category>{};
var _nextProductId = 1;

void _seedData() {
  _categories['electronics'] = Category(id: 'electronics', name: 'Elektronik');
  _categories['clothing'] = Category(id: 'clothing', name: 'Kleidung');

  _products['1'] = Product(
    id: '1', name: 'Laptop', price: 999.99,
    categoryId: 'electronics', stock: 50, createdAt: DateTime.now(),
  );
  _products['2'] = Product(
    id: '2', name: 'Smartphone', price: 599.99,
    categoryId: 'electronics', stock: 100, createdAt: DateTime.now(),
  );
  _products['3'] = Product(
    id: '3', name: 'T-Shirt', price: 29.99,
    categoryId: 'clothing', stock: 200, createdAt: DateTime.now(),
  );
  _nextProductId = 4;
}

// ============================================
// Main
// ============================================

void main() async {
  _seedData();

  final app = Router();

  // API Versionen
  app.mount('/api/v1', v1Router().call);
  app.mount('/api/v2', v2Router().call);

  // Health
  app.get('/health', (r) => jsonResponse({'status': 'ok'}));

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(app.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
}

// ============================================
// API v1
// ============================================

Router v1Router() {
  final router = Router();

  // Products CRUD
  router.get('/products', _v1ListProducts);
  router.get('/products/<id>', _v1GetProduct);
  router.post('/products', _v1CreateProduct);
  router.put('/products/<id>', _v1ReplaceProduct);
  router.patch('/products/<id>', _v1UpdateProduct);
  router.delete('/products/<id>', _v1DeleteProduct);

  // Categories
  router.get('/categories', _listCategories);
  router.get('/categories/<id>', _getCategory);
  router.get('/categories/<id>/products', _getCategoryProducts);

  return router;
}

Response _v1ListProducts(Request request) {
  return jsonResponse({
    'products': _products.values.map((p) => p.toJson()).toList(),
  });
}

Response _v1GetProduct(Request request, String id) {
  final product = _products[id];
  if (product == null) {
    return jsonResponse({'error': 'Product not found'}, statusCode: 404);
  }
  return jsonResponse(product.toJson());
}

Future<Response> _v1CreateProduct(Request request) async {
  final body = jsonDecode(await request.readAsString());

  final id = '${_nextProductId++}';
  final product = Product(
    id: id,
    name: body['name'] ?? '',
    description: body['description'] ?? '',
    price: (body['price'] ?? 0).toDouble(),
    categoryId: body['categoryId'] ?? '',
    stock: body['stock'] ?? 0,
    createdAt: DateTime.now(),
  );

  _products[id] = product;

  // 201 Created mit Location-Header
  return Response(
    201,
    body: jsonEncode(product.toJson()),
    headers: {
      'content-type': 'application/json',
      'location': '/api/v1/products/$id',
    },
  );
}

Future<Response> _v1ReplaceProduct(Request request, String id) async {
  if (!_products.containsKey(id)) {
    return jsonResponse({'error': 'Product not found'}, statusCode: 404);
  }

  final body = jsonDecode(await request.readAsString());
  final existing = _products[id]!;

  // PUT: Komplettes Ersetzen - alle Felder müssen vorhanden sein
  final product = Product(
    id: id,
    name: body['name'] ?? '',
    description: body['description'] ?? '',
    price: (body['price'] ?? 0).toDouble(),
    categoryId: body['categoryId'] ?? '',
    stock: body['stock'] ?? 0,
    createdAt: existing.createdAt,
  );

  _products[id] = product;
  return jsonResponse(product.toJson());
}

Future<Response> _v1UpdateProduct(Request request, String id) async {
  final product = _products[id];
  if (product == null) {
    return jsonResponse({'error': 'Product not found'}, statusCode: 404);
  }

  final body = jsonDecode(await request.readAsString());

  // PATCH: Nur übergebene Felder aktualisieren
  final updated = product.copyWith(
    name: body['name'],
    description: body['description'],
    price: body['price']?.toDouble(),
    categoryId: body['categoryId'],
    stock: body['stock'],
  );

  _products[id] = updated;
  return jsonResponse(updated.toJson());
}

Response _v1DeleteProduct(Request request, String id) {
  if (!_products.containsKey(id)) {
    return jsonResponse({'error': 'Product not found'}, statusCode: 404);
  }

  _products.remove(id);
  return Response(204); // No Content
}

// Categories
Response _listCategories(Request request) {
  return jsonResponse({
    'categories': _categories.values.map((c) => c.toJson()).toList(),
  });
}

Response _getCategory(Request request, String id) {
  final category = _categories[id];
  if (category == null) {
    return jsonResponse({'error': 'Category not found'}, statusCode: 404);
  }
  return jsonResponse(category.toJson());
}

Response _getCategoryProducts(Request request, String id) {
  final category = _categories[id];
  if (category == null) {
    return jsonResponse({'error': 'Category not found'}, statusCode: 404);
  }

  final products = _products.values
      .where((p) => p.categoryId == id)
      .map((p) => p.toJson())
      .toList();

  return jsonResponse({
    'category': category.toJson(),
    'products': products,
    'total': products.length,
  });
}

// ============================================
// API v2 (mit Pagination)
// ============================================

Router v2Router() {
  final router = Router();
  router.get('/products', _v2ListProducts);
  // Weitere v2 Endpunkte...
  return router;
}

Response _v2ListProducts(Request request) {
  final params = request.url.queryParameters;
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final perPage = int.tryParse(params['perPage'] ?? '10') ?? 10;

  final allProducts = _products.values.toList();
  final total = allProducts.length;
  final totalPages = (total / perPage).ceil();

  final start = (page - 1) * perPage;
  final end = start + perPage;
  final pageProducts = allProducts
      .skip(start)
      .take(perPage)
      .map((p) => p.toJson())
      .toList();

  return jsonResponse({
    'data': pageProducts,
    'meta': {
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
    },
    'links': {
      'self': '/api/v2/products?page=$page&perPage=$perPage',
      if (page > 1) 'prev': '/api/v2/products?page=${page - 1}&perPage=$perPage',
      if (page < totalPages) 'next': '/api/v2/products?page=${page + 1}&perPage=$perPage',
      'first': '/api/v2/products?page=1&perPage=$perPage',
      'last': '/api/v2/products?page=$totalPages&perPage=$perPage',
    },
  });
}

// ============================================
// Helper
// ============================================

Response jsonResponse(Object? data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}
```

---

## Test-Befehle

```bash
# v1: Alle Produkte
curl http://localhost:8080/api/v1/products

# v1: Ein Produkt
curl http://localhost:8080/api/v1/products/1

# v1: Produkt erstellen (mit Location-Header)
curl -i -X POST http://localhost:8080/api/v1/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Tablet", "price": 399.99, "categoryId": "electronics"}'

# v1: PATCH (teilweise aktualisieren)
curl -X PATCH http://localhost:8080/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"price": 899.99}'

# v1: PUT (komplett ersetzen)
curl -X PUT http://localhost:8080/api/v1/products/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop Pro", "price": 1299.99, "categoryId": "electronics", "stock": 25}'

# v1: Löschen
curl -X DELETE http://localhost:8080/api/v1/products/3

# Kategorien
curl http://localhost:8080/api/v1/categories
curl http://localhost:8080/api/v1/categories/electronics/products

# v2: Mit Pagination
curl "http://localhost:8080/api/v2/products?page=1&perPage=2"

# 404 testen
curl http://localhost:8080/api/v1/products/999
```

---

## Wichtige Erkenntnisse

### PUT vs. PATCH

```dart
// PUT: Komplett ersetzen
// Alle Felder werden überschrieben (auch mit Default-Werten)
final product = Product(
  id: id,
  name: body['name'] ?? '',  // Leerer String wenn nicht angegeben!
  ...
);

// PATCH: Nur übergebene Felder
// copyWith überschreibt nur wenn Wert != null
final updated = product.copyWith(
  name: body['name'],  // null = keine Änderung
  ...
);
```

### Location-Header bei 201

```dart
return Response(
  201,  // Created
  body: jsonEncode(product.toJson()),
  headers: {
    'content-type': 'application/json',
    'location': '/api/v1/products/$id',  // URL der neuen Ressource
  },
);
```

### 204 No Content bei DELETE

```dart
// Kein Body bei erfolgreicher Löschung
return Response(204);
```
