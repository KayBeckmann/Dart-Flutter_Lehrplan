# Lösung 6.7: Pagination & Filtering

## Vollständige Lösung

```dart
import 'dart:convert';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

// ============================================
// Model
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
    'rating': rating,
    'inStock': stock > 0,
    'createdAt': createdAt.toIso8601String(),
  };
}

class Post {
  final String id;
  final String content;
  final DateTime createdAt;

  Post({required this.id, required this.content, required this.createdAt});

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'createdAt': createdAt.toIso8601String(),
  };
}

// ============================================
// Storage & Seed Data
// ============================================

final _products = <String, Product>{};
final _posts = <String, Post>{};

void _seedData() {
  final random = Random(42);
  final categories = ['electronics', 'clothing', 'home', 'sports', 'books'];
  final brands = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Sony', 'LG', 'Puma'];
  final adjectives = ['Premium', 'Classic', 'Pro', 'Ultra', 'Mega', 'Super'];

  for (var i = 1; i <= 50; i++) {
    final category = categories[i % categories.length];
    final brand = brands[i % brands.length];
    final adj = adjectives[random.nextInt(adjectives.length)];

    _products['product-$i'] = Product(
      id: 'product-$i',
      name: '$brand $adj ${category.substring(0, 1).toUpperCase()}${category.substring(1)} $i',
      description: 'High-quality $category product from $brand. Model number $i.',
      price: (random.nextDouble() * 1000 + 10).roundToDouble(),
      category: category,
      brand: brand,
      stock: random.nextInt(100),
      rating: 1 + random.nextDouble() * 4,
      createdAt: DateTime.now().subtract(Duration(days: i)),
    );
  }

  for (var i = 1; i <= 100; i++) {
    _posts['post-$i'] = Post(
      id: 'post-$i',
      content: 'This is post number $i with some interesting content.',
      createdAt: DateTime.now().subtract(Duration(hours: i)),
    );
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

Response badRequest(String message) {
  return jsonResponse({'error': message}, statusCode: 400);
}

// ============================================
// Aufgabe 1-4: Product List mit Pagination, Filter, Sort
// ============================================

Response listProducts(Request request) {
  final params = request.url.queryParameters;

  // ===== Aufgabe 1: Pagination =====
  final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 1000);
  final perPage = (int.tryParse(params['perPage'] ?? '20') ?? 20).clamp(1, 100);

  // ===== Aufgabe 3: Filtering =====
  var products = _products.values.toList();
  final appliedFilters = <String, dynamic>{};

  // Filter: category
  final category = params['category'];
  if (category != null) {
    products = products.where((p) => p.category == category).toList();
    appliedFilters['category'] = category;
  }

  // Filter: brand
  final brand = params['brand'];
  if (brand != null) {
    products = products.where((p) => p.brand == brand).toList();
    appliedFilters['brand'] = brand;
  }

  // Filter: inStock
  final inStock = params['inStock'];
  if (inStock == 'true') {
    products = products.where((p) => p.stock > 0).toList();
    appliedFilters['inStock'] = true;
  } else if (inStock == 'false') {
    products = products.where((p) => p.stock == 0).toList();
    appliedFilters['inStock'] = false;
  }

  // Filter: minPrice
  final minPrice = double.tryParse(params['minPrice'] ?? '');
  if (minPrice != null) {
    products = products.where((p) => p.price >= minPrice).toList();
    appliedFilters['minPrice'] = minPrice;
  }

  // Filter: maxPrice
  final maxPrice = double.tryParse(params['maxPrice'] ?? '');
  if (maxPrice != null) {
    products = products.where((p) => p.price <= maxPrice).toList();
    appliedFilters['maxPrice'] = maxPrice;
  }

  // Filter: minRating
  final minRating = double.tryParse(params['minRating'] ?? '');
  if (minRating != null) {
    products = products.where((p) => p.rating >= minRating).toList();
    appliedFilters['minRating'] = minRating;
  }

  // ===== Aufgabe 4: Sortierung =====
  final sort = params['sort'] ?? 'createdAt';
  final order = params['order'] ?? 'desc';

  final validSortFields = ['name', 'price', 'createdAt', 'rating', 'stock'];
  if (validSortFields.contains(sort)) {
    products = [...products]..sort((a, b) {
      int cmp;
      switch (sort) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'price':
          cmp = a.price.compareTo(b.price);
          break;
        case 'rating':
          cmp = a.rating.compareTo(b.rating);
          break;
        case 'stock':
          cmp = a.stock.compareTo(b.stock);
          break;
        case 'createdAt':
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return order == 'desc' ? -cmp : cmp;
    });
  }

  // ===== Pagination berechnen =====
  final total = products.length;
  final totalPages = total > 0 ? (total / perPage).ceil() : 1;
  final offset = (page - 1) * perPage;
  final pagedProducts = products.skip(offset).take(perPage).toList();

  // ===== Aufgabe 2: HATEOAS Links =====
  final baseUrl = '/api/products';
  final queryParams = <String, String>{};

  // Filter/Sort in Links übernehmen
  if (category != null) queryParams['category'] = category;
  if (brand != null) queryParams['brand'] = brand;
  if (inStock != null) queryParams['inStock'] = inStock;
  if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
  if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
  if (sort != 'createdAt') queryParams['sort'] = sort;
  if (order != 'desc') queryParams['order'] = order;

  String buildUrl(int p) {
    final params = {...queryParams, 'page': p.toString(), 'perPage': perPage.toString()};
    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '$baseUrl?$query';
  }

  final links = <String, String>{
    'self': buildUrl(page),
    'first': buildUrl(1),
    'last': buildUrl(totalPages),
  };
  if (page > 1) links['prev'] = buildUrl(page - 1);
  if (page < totalPages) links['next'] = buildUrl(page + 1);

  // ===== Response =====
  return jsonResponse({
    'data': pagedProducts.map((p) => p.toJson()).toList(),
    'meta': {
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
      'hasNextPage': page < totalPages,
      'hasPrevPage': page > 1,
      if (appliedFilters.isNotEmpty) 'filtered': true,
      if (appliedFilters.isNotEmpty) 'appliedFilters': appliedFilters,
      'sort': sort,
      'order': order,
    },
    'links': links,
  });
}

// ============================================
// Aufgabe 5: Suche
// ============================================

Response searchProducts(Request request) {
  final params = request.url.queryParameters;

  // Suchbegriff (Pflicht)
  final query = params['q']?.toLowerCase();
  if (query == null || query.isEmpty) {
    return badRequest('Search query (q) is required');
  }

  // Pagination
  final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 1000);
  final perPage = (int.tryParse(params['perPage'] ?? '20') ?? 20).clamp(1, 100);

  // Suche in name, description, brand
  var products = _products.values.where((p) =>
      p.name.toLowerCase().contains(query) ||
      (p.description?.toLowerCase().contains(query) ?? false) ||
      p.brand.toLowerCase().contains(query)
  ).toList();

  // Zusätzliche Filter
  final category = params['category'];
  if (category != null) {
    products = products.where((p) => p.category == category).toList();
  }

  final brand = params['brand'];
  if (brand != null) {
    products = products.where((p) => p.brand == brand).toList();
  }

  final inStock = params['inStock'];
  if (inStock == 'true') {
    products = products.where((p) => p.stock > 0).toList();
  }

  final minPrice = double.tryParse(params['minPrice'] ?? '');
  if (minPrice != null) {
    products = products.where((p) => p.price >= minPrice).toList();
  }

  final maxPrice = double.tryParse(params['maxPrice'] ?? '');
  if (maxPrice != null) {
    products = products.where((p) => p.price <= maxPrice).toList();
  }

  // Sortierung (Relevanz standardmäßig = nach Name-Match zuerst)
  final sort = params['sort'];
  final order = params['order'] ?? 'asc';

  if (sort != null) {
    products = [...products]..sort((a, b) {
      int cmp;
      switch (sort) {
        case 'name':
          cmp = a.name.compareTo(b.name);
          break;
        case 'price':
          cmp = a.price.compareTo(b.price);
          break;
        case 'rating':
          cmp = a.rating.compareTo(b.rating);
          break;
        default:
          cmp = a.createdAt.compareTo(b.createdAt);
      }
      return order == 'desc' ? -cmp : cmp;
    });
  }

  // Pagination
  final total = products.length;
  final totalPages = total > 0 ? (total / perPage).ceil() : 1;
  final offset = (page - 1) * perPage;
  final pagedProducts = products.skip(offset).take(perPage).toList();

  return jsonResponse({
    'data': pagedProducts.map((p) => p.toJson()).toList(),
    'meta': {
      'query': query,
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
      'hasNextPage': page < totalPages,
      'hasPrevPage': page > 1,
    },
  });
}

// ============================================
// Aufgabe 6: Cursor Pagination (Bonus)
// ============================================

Response listFeed(Request request) {
  final params = request.url.queryParameters;

  // Parameter
  final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
  final cursor = params['cursor'];

  // Posts nach createdAt sortiert (neueste zuerst)
  var allPosts = _posts.values.toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Post> posts;
  String? beforeCursor;

  if (cursor != null) {
    // Finde Index des Cursor-Posts
    final cursorIndex = allPosts.indexWhere((p) => p.id == cursor);
    if (cursorIndex == -1) {
      return badRequest('Invalid cursor');
    }
    beforeCursor = cursor;
    posts = allPosts.skip(cursorIndex + 1).take(limit).toList();
  } else {
    posts = allPosts.take(limit).toList();
  }

  final hasMore = posts.length == limit;
  final afterCursor = posts.isNotEmpty ? posts.last.id : null;

  return jsonResponse({
    'data': posts.map((p) => p.toJson()).toList(),
    'meta': {
      'limit': limit,
      'hasMore': hasMore,
      'count': posts.length,
    },
    'cursors': {
      if (beforeCursor != null) 'before': beforeCursor,
      if (hasMore && afterCursor != null) 'after': afterCursor,
    },
  });
}

// ============================================
// Zusätzliche Endpoints
// ============================================

Response getCategories(Request request) {
  final categories = _products.values.map((p) => p.category).toSet().toList()..sort();
  return jsonResponse({
    'data': categories,
    'total': categories.length,
  });
}

Response getBrands(Request request) {
  final brands = _products.values.map((p) => p.brand).toSet().toList()..sort();
  return jsonResponse({
    'data': brands,
    'total': brands.length,
  });
}

Response getProduct(Request request, String id) {
  final product = _products[id];
  if (product == null) {
    return jsonResponse({'error': 'Product not found'}, statusCode: 404);
  }
  return jsonResponse(product.toJson());
}

// ============================================
// Main
// ============================================

void main() async {
  _seedData();

  final router = Router();

  // Products
  router.get('/api/products', listProducts);
  router.get('/api/products/search', searchProducts);
  router.get('/api/products/<id>', getProduct);

  // Meta-Endpoints
  router.get('/api/categories', getCategories);
  router.get('/api/brands', getBrands);

  // Feed (Cursor Pagination)
  router.get('/api/feed', listFeed);

  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router.call);

  await shelf_io.serve(handler, 'localhost', 8080);
  print('Server: http://localhost:8080');
  print('');
  print('Endpoints:');
  print('  GET /api/products');
  print('  GET /api/products/search?q=...');
  print('  GET /api/products/:id');
  print('  GET /api/categories');
  print('  GET /api/brands');
  print('  GET /api/feed (Cursor Pagination)');
  print('');
  print('Test-Befehle:');
  print('  curl "http://localhost:8080/api/products?page=1&perPage=5"');
  print('  curl "http://localhost:8080/api/products?category=electronics&sort=price&order=asc"');
  print('  curl "http://localhost:8080/api/products/search?q=apple"');
  print('  curl "http://localhost:8080/api/feed?limit=10"');
}
```

---

## Test-Befehle

```bash
# ========== Basis Pagination ==========
curl "http://localhost:8080/api/products"
curl "http://localhost:8080/api/products?page=1&perPage=5"
curl "http://localhost:8080/api/products?page=2&perPage=5"
curl "http://localhost:8080/api/products?page=10&perPage=10"

# ========== Filtering ==========
curl "http://localhost:8080/api/products?category=electronics"
curl "http://localhost:8080/api/products?brand=Apple"
curl "http://localhost:8080/api/products?inStock=true"
curl "http://localhost:8080/api/products?minPrice=100&maxPrice=500"
curl "http://localhost:8080/api/products?minRating=4"

# Kombinierte Filter
curl "http://localhost:8080/api/products?category=electronics&brand=Apple&inStock=true"
curl "http://localhost:8080/api/products?minPrice=50&maxPrice=200&inStock=true"

# ========== Sortierung ==========
curl "http://localhost:8080/api/products?sort=price&order=asc"
curl "http://localhost:8080/api/products?sort=price&order=desc"
curl "http://localhost:8080/api/products?sort=name&order=asc"
curl "http://localhost:8080/api/products?sort=rating&order=desc"

# Filter + Sort + Pagination
curl "http://localhost:8080/api/products?category=electronics&sort=price&order=asc&page=1&perPage=5"

# ========== Suche ==========
curl "http://localhost:8080/api/products/search?q=apple"
curl "http://localhost:8080/api/products/search?q=premium"
curl "http://localhost:8080/api/products/search?q=electronics"
curl "http://localhost:8080/api/products/search?q=apple&category=electronics"
curl "http://localhost:8080/api/products/search?q=product&minPrice=100&maxPrice=300"

# ========== Cursor Pagination ==========
# Erste Seite
curl "http://localhost:8080/api/feed?limit=10"

# Nächste Seite (Cursor aus vorheriger Response verwenden)
curl "http://localhost:8080/api/feed?limit=10&cursor=post-10"
curl "http://localhost:8080/api/feed?limit=10&cursor=post-20"

# ========== Meta-Endpoints ==========
curl "http://localhost:8080/api/categories"
curl "http://localhost:8080/api/brands"
```

---

## Ausgabe-Beispiele

### Pagination Response

```json
{
  "data": [
    {
      "id": "product-1",
      "name": "Apple Premium Electronics 1",
      "price": 523.0,
      "category": "electronics",
      "brand": "Apple",
      "stock": 42,
      "rating": 3.8,
      "inStock": true,
      "createdAt": "2024-01-14T10:00:00.000Z"
    }
  ],
  "meta": {
    "total": 50,
    "page": 1,
    "perPage": 5,
    "totalPages": 10,
    "hasNextPage": true,
    "hasPrevPage": false,
    "sort": "createdAt",
    "order": "desc"
  },
  "links": {
    "self": "/api/products?page=1&perPage=5",
    "first": "/api/products?page=1&perPage=5",
    "last": "/api/products?page=10&perPage=5",
    "next": "/api/products?page=2&perPage=5"
  }
}
```

### Filtered Response

```json
{
  "data": [...],
  "meta": {
    "total": 8,
    "page": 1,
    "perPage": 20,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPrevPage": false,
    "filtered": true,
    "appliedFilters": {
      "category": "electronics",
      "brand": "Apple",
      "inStock": true
    },
    "sort": "createdAt",
    "order": "desc"
  },
  "links": {...}
}
```

### Search Response

```json
{
  "data": [
    {"id": "product-1", "name": "Apple Premium Electronics 1", ...}
  ],
  "meta": {
    "query": "apple",
    "total": 8,
    "page": 1,
    "perPage": 20,
    "totalPages": 1,
    "hasNextPage": false,
    "hasPrevPage": false
  }
}
```

### Cursor Pagination Response

```json
{
  "data": [
    {"id": "post-1", "content": "...", "createdAt": "..."},
    {"id": "post-2", "content": "...", "createdAt": "..."}
  ],
  "meta": {
    "limit": 10,
    "hasMore": true,
    "count": 10
  },
  "cursors": {
    "after": "post-10"
  }
}
```

---

## Wichtige Patterns

### Filter in Links übernehmen

```dart
// Alle Filter/Sort Parameter sammeln
final queryParams = <String, String>{};
if (category != null) queryParams['category'] = category;
if (sort != 'createdAt') queryParams['sort'] = sort;

// URL mit Parametern bauen
String buildUrl(int page) {
  final params = {...queryParams, 'page': page.toString()};
  final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
  return '$baseUrl?$query';
}
```

### Sichere Parameter-Extraktion

```dart
final page = (int.tryParse(params['page'] ?? '1') ?? 1).clamp(1, 1000);
final perPage = (int.tryParse(params['perPage'] ?? '20') ?? 20).clamp(1, 100);
```

### Cursor-Position finden

```dart
final cursorIndex = allPosts.indexWhere((p) => p.id == cursor);
if (cursorIndex == -1) {
  return badRequest('Invalid cursor');
}
posts = allPosts.skip(cursorIndex + 1).take(limit).toList();
```
