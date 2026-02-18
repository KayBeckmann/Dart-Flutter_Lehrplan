# Ressourcen: Pagination & Filtering

## Offizielle Dokumentation

- [REST API Pagination](https://restfulapi.net/pagination/)
- [JSON:API Pagination](https://jsonapi.org/format/#fetching-pagination)
- [Cursor Pagination](https://www.sitepoint.com/paginating-real-time-data-cursor-based-pagination/)

## Cheat Sheet: Offset Pagination

```dart
Response listItems(Request request) {
  final params = request.url.queryParameters;

  // Parameter mit Defaults
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final perPage = int.tryParse(params['perPage'] ?? '20') ?? 20;

  // Limits
  final safePage = page.clamp(1, 1000);
  final safePerPage = perPage.clamp(1, 100);

  // Daten holen
  final allItems = repo.findAll();
  final total = allItems.length;

  // Slice
  final offset = (safePage - 1) * safePerPage;
  final items = allItems.skip(offset).take(safePerPage).toList();

  // Metadaten
  final totalPages = (total / safePerPage).ceil();

  return jsonResponse({
    'data': items.map((i) => i.toJson()).toList(),
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

## Cheat Sheet: Cursor Pagination

```dart
Response listItems(Request request) {
  final params = request.url.queryParameters;
  final limit = (int.tryParse(params['limit'] ?? '20') ?? 20).clamp(1, 100);
  final cursor = params['cursor'];

  List<Item> items;
  if (cursor != null) {
    items = repo.findAfterId(cursor, limit);
  } else {
    items = repo.findAll().take(limit).toList();
  }

  final nextCursor = items.isNotEmpty ? items.last.id : null;
  final hasMore = items.length == limit;

  return jsonResponse({
    'data': items.map((i) => i.toJson()).toList(),
    'meta': {'limit': limit, 'hasMore': hasMore},
    'cursors': {
      if (cursor != null) 'before': cursor,
      if (hasMore && nextCursor != null) 'after': nextCursor,
    },
  });
}
```

## Cheat Sheet: Filtering

```dart
Response listProducts(Request request) {
  final params = request.url.queryParameters;
  var items = repo.findAll();

  // Exakter Match
  final category = params['category'];
  if (category != null) {
    items = items.where((i) => i.category == category).toList();
  }

  // Boolean
  if (params['active'] == 'true') {
    items = items.where((i) => i.active).toList();
  }

  // Bereich
  final minPrice = double.tryParse(params['minPrice'] ?? '');
  final maxPrice = double.tryParse(params['maxPrice'] ?? '');
  if (minPrice != null) {
    items = items.where((i) => i.price >= minPrice).toList();
  }
  if (maxPrice != null) {
    items = items.where((i) => i.price <= maxPrice).toList();
  }

  // Liste (z.B. ?tags=a,b,c)
  final tags = params['tags']?.split(',');
  if (tags != null && tags.isNotEmpty) {
    items = items.where((i) => tags.any((t) => i.tags.contains(t))).toList();
  }

  // ... pagination ...
}
```

## Cheat Sheet: Sortierung

```dart
Response listItems(Request request) {
  final params = request.url.queryParameters;
  var items = repo.findAll();

  final sort = params['sort'];
  final order = params['order'] ?? 'asc';

  if (sort != null) {
    items = [...items]..sort((a, b) {
      final cmp = switch (sort) {
        'name' => a.name.compareTo(b.name),
        'price' => a.price.compareTo(b.price),
        'createdAt' => a.createdAt.compareTo(b.createdAt),
        _ => 0,
      };
      return order == 'desc' ? -cmp : cmp;
    });
  }

  // ... pagination ...
}
```

## Cheat Sheet: Suche

```dart
Response searchItems(Request request) {
  final q = request.url.queryParameters['q']?.toLowerCase();

  if (q == null || q.isEmpty) {
    return badRequest('Search query required');
  }

  final items = repo.findAll().where((i) =>
    i.name.toLowerCase().contains(q) ||
    (i.description?.toLowerCase().contains(q) ?? false)
  ).toList();

  // ... pagination ...
}
```

## Cheat Sheet: HATEOAS Links

```dart
Map<String, String> buildLinks(String baseUrl, int page, int perPage, int totalPages) {
  return {
    'self': '$baseUrl?page=$page&perPage=$perPage',
    'first': '$baseUrl?page=1&perPage=$perPage',
    'last': '$baseUrl?page=$totalPages&perPage=$perPage',
    if (page > 1) 'prev': '$baseUrl?page=${page - 1}&perPage=$perPage',
    if (page < totalPages) 'next': '$baseUrl?page=${page + 1}&perPage=$perPage',
  };
}
```

## Cheat Sheet: PaginatedResponse Klasse

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
  bool get hasNext => page < totalPages;
  bool get hasPrev => page > 1;

  Map<String, dynamic> toJson(Object Function(T) toJsonFn) => {
    'data': data.map(toJsonFn).toList(),
    'meta': {
      'total': total,
      'page': page,
      'perPage': perPage,
      'totalPages': totalPages,
      'hasNextPage': hasNext,
      'hasPrevPage': hasPrev,
    },
  };
}
```

## Query-Parameter Übersicht

| Parameter | Beschreibung | Beispiel |
|-----------|--------------|----------|
| `page` | Aktuelle Seite | `?page=2` |
| `perPage` | Elemente pro Seite | `?perPage=50` |
| `limit` | Anzahl (Cursor) | `?limit=20` |
| `cursor` | Cursor-Position | `?cursor=abc` |
| `sort` | Sortierfeld | `?sort=price` |
| `order` | asc/desc | `?order=desc` |
| `q` | Suchbegriff | `?q=laptop` |
| `[field]` | Filter | `?category=tech` |
| `min[field]` | Minimum | `?minPrice=10` |
| `max[field]` | Maximum | `?maxPrice=100` |

## Offset vs. Cursor Pagination

| Aspekt | Offset | Cursor |
|--------|--------|--------|
| Einfachheit | Einfach | Komplexer |
| Performance | Bei großen Offsets langsam | Konsistent schnell |
| Echtzeit-Daten | Probleme bei Änderungen | Stabil |
| Beliebige Seiten | Möglich | Nicht möglich |
| Use Case | Klassische Listen | Feeds, Timelines |

## Test-Befehle

```bash
# Pagination
curl "http://localhost:8080/api/products?page=1&perPage=10"
curl "http://localhost:8080/api/products?page=2&perPage=10"

# Cursor
curl "http://localhost:8080/api/posts?limit=10"
curl "http://localhost:8080/api/posts?limit=10&cursor=post-10"

# Filter
curl "http://localhost:8080/api/products?category=electronics"
curl "http://localhost:8080/api/products?minPrice=50&maxPrice=200"
curl "http://localhost:8080/api/products?inStock=true"

# Sortierung
curl "http://localhost:8080/api/products?sort=price&order=asc"
curl "http://localhost:8080/api/products?sort=name&order=desc"

# Suche
curl "http://localhost:8080/api/products/search?q=laptop"

# Kombiniert
curl "http://localhost:8080/api/products?category=electronics&sort=price&order=asc&page=1&perPage=20"
```

## Best Practices

1. **Limits setzen**: Max perPage begrenzen (z.B. 100)
2. **Defaults definieren**: page=1, perPage=20
3. **Metadaten mitliefern**: total, totalPages, hasNext
4. **HATEOAS Links**: Navigation vereinfachen
5. **Konsistente Benennung**: camelCase oder snake_case
6. **Cursor für Feeds**: Bei Echtzeit-Daten bevorzugen
