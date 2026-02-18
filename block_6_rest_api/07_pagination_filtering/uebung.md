# Übung 6.7: Pagination & Filtering

## Ziel

Implementiere eine Product-API mit vollständiger Pagination, Filtering und Suche.

---

## Aufgabe 1: Basis-Pagination (15 min)

Erstelle einen Endpoint mit Offset-basierter Pagination.

### Endpoint

GET `/api/products`

### Query-Parameter

| Parameter | Default | Beschreibung |
|-----------|---------|--------------|
| `page` | 1 | Aktuelle Seite |
| `perPage` | 20 | Elemente pro Seite (max 100) |

### Response

```json
{
  "data": [
    {"id": "1", "name": "Laptop", "price": 999.99, ...}
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

### Anforderungen

- `page` muss mindestens 1 sein
- `perPage` muss zwischen 1 und 100 liegen
- Bei leerer Liste: leeres Array, total: 0

---

## Aufgabe 2: HATEOAS Links (10 min)

Erweitere die Response um Navigation-Links.

### Response

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

### Regeln

- `prev` nur wenn `page > 1`
- `next` nur wenn `page < totalPages`
- Filter/Sort-Parameter in Links übernehmen

---

## Aufgabe 3: Filtering (15 min)

Implementiere Filter für die Product-Liste.

### Filter

| Parameter | Typ | Beispiel |
|-----------|-----|----------|
| `category` | string | `?category=electronics` |
| `inStock` | boolean | `?inStock=true` |
| `minPrice` | number | `?minPrice=50` |
| `maxPrice` | number | `?maxPrice=200` |
| `brand` | string | `?brand=Apple` |

### Kombinierte Filter

```bash
# Alle Apple-Produkte zwischen 100€ und 500€, die auf Lager sind
GET /api/products?brand=Apple&minPrice=100&maxPrice=500&inStock=true
```

### Response

Filter-Infos in Meta aufnehmen:

```json
{
  "data": [...],
  "meta": {
    "total": 15,
    "filtered": true,
    "appliedFilters": {
      "brand": "Apple",
      "minPrice": 100,
      "maxPrice": 500,
      "inStock": true
    },
    ...
  }
}
```

---

## Aufgabe 4: Sortierung (10 min)

Implementiere Sortierung.

### Parameter

| Parameter | Werte | Default |
|-----------|-------|---------|
| `sort` | name, price, createdAt, rating | createdAt |
| `order` | asc, desc | desc |

### Beispiele

```bash
# Nach Preis aufsteigend
GET /api/products?sort=price&order=asc

# Nach Name absteigend
GET /api/products?sort=name&order=desc

# Neueste zuerst (Default)
GET /api/products
```

### Validierung

- Unbekannte Sort-Felder ignorieren oder Fehler
- Ungültige Order-Werte auf `asc` setzen

---

## Aufgabe 5: Suche (15 min)

Implementiere einen Such-Endpoint.

### Endpoint

GET `/api/products/search`

### Parameter

| Parameter | Beschreibung |
|-----------|--------------|
| `q` | Suchbegriff (Pflicht) |
| Alle Filter | Wie bei List |
| Pagination | Wie bei List |

### Suchlogik

- Suche in: `name`, `description`, `brand`
- Case-insensitive
- Partial Match (enthält)

### Response

```json
{
  "data": [...],
  "meta": {
    "query": "laptop",
    "total": 25,
    ...
  }
}
```

### Fehler

- 400 wenn `q` fehlt oder leer

---

## Aufgabe 6: Cursor Pagination (Bonus, 15 min)

Implementiere Cursor-basierte Pagination für einen Feed-Endpoint.

### Endpoint

GET `/api/feed`

### Parameter

| Parameter | Beschreibung |
|-----------|--------------|
| `limit` | Anzahl (default 20, max 100) |
| `cursor` | ID des letzten Elements |

### Response

```json
{
  "data": [
    {"id": "post-50", ...},
    {"id": "post-49", ...}
  ],
  "meta": {
    "limit": 20,
    "hasMore": true
  },
  "cursors": {
    "before": "post-50",
    "after": "post-31"
  }
}
```

### Verwendung

```bash
# Erste Seite
curl http://localhost:8080/api/feed?limit=20

# Nächste Seite
curl http://localhost:8080/api/feed?limit=20&cursor=post-31
```

---

## Test-Daten

Erstelle Seed-Daten für mindestens 50 Produkte:

```dart
void _seedProducts() {
  final categories = ['electronics', 'clothing', 'home', 'sports'];
  final brands = ['Apple', 'Samsung', 'Nike', 'Adidas', 'Sony'];

  for (var i = 1; i <= 50; i++) {
    _products['product-$i'] = Product(
      id: 'product-$i',
      name: 'Product $i',
      description: 'Description for product $i',
      price: (Random().nextDouble() * 1000).roundToDouble(),
      category: categories[i % categories.length],
      brand: brands[i % brands.length],
      stock: Random().nextInt(100),
      rating: 1 + Random().nextDouble() * 4,
      createdAt: DateTime.now().subtract(Duration(days: i)),
    );
  }
}
```

---

## Testen

```bash
# Basis-Pagination
curl "http://localhost:8080/api/products"
curl "http://localhost:8080/api/products?page=2&perPage=10"

# Filter
curl "http://localhost:8080/api/products?category=electronics"
curl "http://localhost:8080/api/products?minPrice=100&maxPrice=500"
curl "http://localhost:8080/api/products?inStock=true&brand=Apple"

# Sortierung
curl "http://localhost:8080/api/products?sort=price&order=asc"
curl "http://localhost:8080/api/products?sort=rating&order=desc"

# Suche
curl "http://localhost:8080/api/products/search?q=laptop"
curl "http://localhost:8080/api/products/search?q=phone&category=electronics"

# Kombiniert
curl "http://localhost:8080/api/products?category=electronics&sort=price&order=asc&page=1&perPage=5"

# Cursor (Bonus)
curl "http://localhost:8080/api/feed?limit=10"
curl "http://localhost:8080/api/feed?limit=10&cursor=post-41"
```

---

## Abgabe-Checkliste

- [ ] Offset Pagination funktioniert
- [ ] Meta-Daten korrekt (total, totalPages, hasNext, hasPrev)
- [ ] HATEOAS Links vorhanden
- [ ] Filter: category, inStock, minPrice, maxPrice, brand
- [ ] Filter können kombiniert werden
- [ ] Sortierung: sort + order Parameter
- [ ] Suche: /search?q= Endpoint
- [ ] Suche durchsucht name, description, brand
- [ ] Filter in Links übernommen
- [ ] (Bonus) Cursor Pagination implementiert
