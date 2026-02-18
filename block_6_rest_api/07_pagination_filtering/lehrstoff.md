# Einheit 6.7: Pagination & Filtering

## Lernziele

Nach dieser Einheit kannst du:
- Große Datenmengen in Seiten aufteilen (Pagination)
- Daten nach Kriterien filtern
- Sortierung implementieren
- Suchfunktionen bereitstellen

---

## Warum Pagination?

### Problem ohne Pagination

```dart
// Alle 1.000.000 Produkte laden
GET /api/products

// Probleme:
// - Sehr lange Ladezeit
// - Hoher Speicherverbrauch (Server & Client)
// - Netzwerk-Überlastung
// - Schlechte User Experience
```

### Lösung mit Pagination

```dart
// Nur 20 Produkte pro Seite
GET /api/products?page=1&perPage=20

// Vorteile:
// - Schnelle Antwortzeiten
// - Geringer Speicherverbrauch
// - Bessere UX
```

---

## Offset-basierte Pagination

### Implementierung

```dart
Response listProducts(Request request) {
  // Parameter aus Query String
  final params = request.url.queryParameters;
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final perPage = int.tryParse(params['perPage'] ?? '20') ?? 20;

  // Limits setzen
  final safePerPage = perPage.clamp(1, 100);  // Max 100 pro Seite
  final safePage = page.clamp(1, 1000);       // Max Seite 1000

  // Daten abrufen
  final allProducts = productRepo.findAll();
  final total = allProducts.length;

  // Offset berechnen
  final offset = (safePage - 1) * safePerPage;
  final products = allProducts.skip(offset).take(safePerPage).toList();

  // Pagination-Metadaten
  final totalPages = (total / safePerPage).ceil();

  return jsonResponse({
    'data': products.map((p) => p.toJson()).toList(),
    'meta': {
      'total': total,
      'page': safePage,
      'perPage': safePerPage,
      'totalPages': totalPages,
      'hasNextPage': safePage < totalPages,
      'hasPrevPage': safePage > 1,
    },
  });
}
```

### Response-Format

```json
{
  "data": [
    {"id": "1", "name": "Product 1", ...},
    {"id": "2", "name": "Product 2", ...}
  ],
  "meta": {
    "total": 150,
    "page": 1,
    "perPage": 20,
    "totalPages": 8,
    "hasNextPage": true,
    "hasPrevPage": false
  }
}
```

---

## HATEOAS Links

### Navigation-Links

```dart
Response listProducts(Request request) {
  // ... Pagination wie oben ...

  final baseUrl = '/api/products';

  return jsonResponse({
    'data': products.map((p) => p.toJson()).toList(),
    'meta': {
      'total': total,
      'page': safePage,
      'perPage': safePerPage,
      'totalPages': totalPages,
    },
    'links': {
      'self': '$baseUrl?page=$safePage&perPage=$safePerPage',
      'first': '$baseUrl?page=1&perPage=$safePerPage',
      'last': '$baseUrl?page=$totalPages&perPage=$safePerPage',
      if (safePage > 1)
        'prev': '$baseUrl?page=${safePage - 1}&perPage=$safePerPage',
      if (safePage < totalPages)
        'next': '$baseUrl?page=${safePage + 1}&perPage=$safePerPage',
    },
  });
}
```

### Response mit Links

```json
{
  "data": [...],
  "meta": {...},
  "links": {
    "self": "/api/products?page=2&perPage=20",
    "first": "/api/products?page=1&perPage=20",
    "last": "/api/products?page=8&perPage=20",
    "prev": "/api/products?page=1&perPage=20",
    "next": "/api/products?page=3&perPage=20"
  }
}
```

---

## Cursor-basierte Pagination

Besser für Echtzeit-Daten und sehr große Datensätze.

### Implementierung

```dart
Response listPosts(Request request) {
  final params = request.url.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
  final cursor = params['cursor'];  // ID des letzten Elements

  // Limit begrenzen
  final safeLimit = limit.clamp(1, 100);

  List<Post> posts;

  if (cursor != null) {
    // Nach dem Cursor-Element holen
    final cursorIndex = postRepo.findIndexById(cursor);
    posts = postRepo.findAll()
        .skip(cursorIndex + 1)
        .take(safeLimit)
        .toList();
  } else {
    // Von Anfang
    posts = postRepo.findAll().take(safeLimit).toList();
  }

  // Nächster Cursor
  final nextCursor = posts.isNotEmpty ? posts.last.id : null;
  final hasMore = posts.length == safeLimit;

  return jsonResponse({
    'data': posts.map((p) => p.toJson()).toList(),
    'meta': {
      'limit': safeLimit,
      'hasMore': hasMore,
    },
    'cursors': {
      if (cursor != null) 'before': cursor,
      if (nextCursor != null && hasMore) 'after': nextCursor,
    },
  });
}
```

### Verwendung

```bash
# Erste Seite
GET /api/posts?limit=20

# Nächste Seite mit Cursor
GET /api/posts?limit=20&cursor=post-20
```

---

## Filtering

### Einfache Filter

```dart
Response listProducts(Request request) {
  final params = request.url.queryParameters;

  var products = productRepo.findAll();

  // Filter: ?category=electronics
  final category = params['category'];
  if (category != null) {
    products = products.where((p) => p.category == category).toList();
  }

  // Filter: ?inStock=true
  final inStock = params['inStock'];
  if (inStock == 'true') {
    products = products.where((p) => p.stock > 0).toList();
  }

  // Filter: ?minPrice=10&maxPrice=100
  final minPrice = double.tryParse(params['minPrice'] ?? '');
  final maxPrice = double.tryParse(params['maxPrice'] ?? '');

  if (minPrice != null) {
    products = products.where((p) => p.price >= minPrice).toList();
  }
  if (maxPrice != null) {
    products = products.where((p) => p.price <= maxPrice).toList();
  }

  // ... Pagination ...
}
```

### Request

```bash
GET /api/products?category=electronics&minPrice=50&maxPrice=200&inStock=true
```

---

## Sortierung

### Implementierung

```dart
Response listProducts(Request request) {
  final params = request.url.queryParameters;

  var products = productRepo.findAll();

  // Sortierung: ?sort=price&order=asc
  final sortField = params['sort'];
  final sortOrder = params['order'] ?? 'asc';

  if (sortField != null) {
    products = _sortProducts(products, sortField, sortOrder);
  }

  // ... Pagination ...
}

List<Product> _sortProducts(List<Product> products, String field, String order) {
  final sorted = [...products];

  sorted.sort((a, b) {
    int comparison;

    switch (field) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'price':
        comparison = a.price.compareTo(b.price);
        break;
      case 'createdAt':
        comparison = a.createdAt.compareTo(b.createdAt);
        break;
      case 'stock':
        comparison = a.stock.compareTo(b.stock);
        break;
      default:
        comparison = 0;
    }

    return order == 'desc' ? -comparison : comparison;
  });

  return sorted;
}
```

### Request

```bash
# Nach Preis aufsteigend
GET /api/products?sort=price&order=asc

# Nach Name absteigend
GET /api/products?sort=name&order=desc

# Mehrere Sortierungen (optional)
GET /api/products?sort=category,price&order=asc,desc
```

---

## Suche

### Einfache Textsuche

```dart
Response searchProducts(Request request) {
  final params = request.url.queryParameters;
  final query = params['q']?.toLowerCase();

  if (query == null || query.isEmpty) {
    return badRequest('Search query is required');
  }

  var products = productRepo.findAll();

  // Suche in Name und Beschreibung
  products = products.where((p) =>
      p.name.toLowerCase().contains(query) ||
      (p.description?.toLowerCase().contains(query) ?? false)
  ).toList();

  // ... Pagination ...
}
```

### Request

```bash
GET /api/products/search?q=laptop
```

### Erweiterte Suche

```dart
Response advancedSearch(Request request) {
  final params = request.url.queryParameters;

  var products = productRepo.findAll();

  // Textsuche
  final q = params['q']?.toLowerCase();
  if (q != null && q.isNotEmpty) {
    products = products.where((p) =>
        p.name.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  // Kategorie
  final category = params['category'];
  if (category != null) {
    products = products.where((p) => p.category == category).toList();
  }

  // Preisbereich
  final minPrice = double.tryParse(params['minPrice'] ?? '');
  final maxPrice = double.tryParse(params['maxPrice'] ?? '');
  if (minPrice != null) {
    products = products.where((p) => p.price >= minPrice).toList();
  }
  if (maxPrice != null) {
    products = products.where((p) => p.price <= maxPrice).toList();
  }

  // Rating
  final minRating = double.tryParse(params['minRating'] ?? '');
  if (minRating != null) {
    products = products.where((p) => p.rating >= minRating).toList();
  }

  // Tags (mehrere möglich)
  final tags = params['tags']?.split(',');
  if (tags != null && tags.isNotEmpty) {
    products = products.where((p) =>
        tags.any((tag) => p.tags.contains(tag))
    ).toList();
  }

  // ... Sortierung und Pagination ...
}
```

### Request

```bash
GET /api/products/search?q=laptop&category=electronics&minPrice=500&maxPrice=1500&minRating=4&tags=gaming,portable
```

---

## Wiederverwendbare Pagination-Klasse

```dart
class PaginatedResponse<T> {
  final List<T> data;
  final int total;
  final int page;
  final int perPage;

  PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.perPage,
  });

  int get totalPages => (total / perPage).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPrevPage => page > 1;

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) itemToJson) => {
    'data': data.map(itemToJson).toList(),
    'meta': {
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
      'hasNextPage': hasNextPage,
      'hasPrevPage': hasPrevPage,
    },
  };
}

// Verwendung
final paginated = PaginatedResponse(
  data: products,
  total: totalCount,
  page: page,
  perPage: perPage,
);

return jsonResponse(paginated.toJson((p) => p.toJson()));
```

---

## Zusammenfassung

| Feature | Query-Parameter | Beispiel |
|---------|-----------------|----------|
| Seite | `page` | `?page=2` |
| Pro Seite | `perPage` | `?perPage=50` |
| Sortierfeld | `sort` | `?sort=price` |
| Sortierrichtung | `order` | `?order=desc` |
| Filter | Feldname | `?category=electronics` |
| Bereich | `min/max` | `?minPrice=10&maxPrice=100` |
| Suche | `q` | `?q=laptop` |
| Cursor | `cursor` | `?cursor=abc123` |

---

## Nächste Schritte

In der nächsten Einheit lernst du **API-Dokumentation**: Wie du deine API mit OpenAPI/Swagger dokumentierst.
