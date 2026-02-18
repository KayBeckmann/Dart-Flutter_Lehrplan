# Einheit 7.7: Komplexe Queries & Aggregationen

## Lernziele

Nach dieser Einheit kannst du:
- Komplexe SQL-Abfragen mit Subqueries schreiben
- Window Functions für Analysen nutzen
- Aggregation Pipelines in MongoDB erstellen
- Performance-Optimierung für Queries

---

## SQL: Subqueries

### Scalar Subquery

```sql
-- Produkte teurer als Durchschnitt
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- Letzter Besteller
SELECT name,
       (SELECT MAX(created_at) FROM orders WHERE customer_id = c.id) AS last_order
FROM customers c;
```

### IN Subquery

```sql
-- Kunden mit Bestellungen
SELECT name, email
FROM customers
WHERE id IN (SELECT DISTINCT customer_id FROM orders);

-- Produkte ohne Bestellungen
SELECT name
FROM products
WHERE id NOT IN (SELECT DISTINCT product_id FROM order_items);
```

### EXISTS Subquery

```sql
-- Kunden mit mindestens einer Bestellung
SELECT name
FROM customers c
WHERE EXISTS (
    SELECT 1 FROM orders WHERE customer_id = c.id
);
```

### FROM Subquery (Derived Table)

```sql
-- Top-Kategorien mit Statistiken
SELECT category_stats.*
FROM (
    SELECT
        c.name AS category,
        COUNT(p.id) AS product_count,
        AVG(p.price) AS avg_price,
        SUM(p.stock) AS total_stock
    FROM categories c
    LEFT JOIN products p ON c.id = p.category_id
    GROUP BY c.id, c.name
) AS category_stats
WHERE product_count > 5;
```

---

## SQL: Common Table Expressions (CTE)

```sql
-- CTE für bessere Lesbarkeit
WITH category_sales AS (
    SELECT
        p.category_id,
        SUM(oi.quantity * oi.unit_price) AS total_sales
    FROM order_items oi
    JOIN products p ON oi.product_id = p.id
    GROUP BY p.category_id
),
category_info AS (
    SELECT id, name FROM categories
)
SELECT
    ci.name AS category,
    COALESCE(cs.total_sales, 0) AS sales
FROM category_info ci
LEFT JOIN category_sales cs ON ci.id = cs.category_id
ORDER BY sales DESC;
```

### Recursive CTE

```sql
-- Kategorie-Hierarchie
WITH RECURSIVE category_tree AS (
    -- Basis: Root-Kategorien
    SELECT id, name, parent_id, 0 AS depth, name AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Rekursion
    SELECT c.id, c.name, c.parent_id, ct.depth + 1,
           ct.path || ' > ' || c.name
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree ORDER BY path;
```

---

## SQL: Window Functions

### ROW_NUMBER, RANK, DENSE_RANK

```sql
-- Produkte mit Rang pro Kategorie
SELECT
    name,
    category_id,
    price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY price DESC) AS row_num,
    RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS rank,
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY price DESC) AS dense_rank
FROM products;
```

### Running Total

```sql
-- Kumulativer Umsatz
SELECT
    DATE(created_at) AS date,
    SUM(total) AS daily_total,
    SUM(SUM(total)) OVER (ORDER BY DATE(created_at)) AS running_total
FROM orders
GROUP BY DATE(created_at)
ORDER BY date;
```

### LAG / LEAD

```sql
-- Vergleich mit vorherigem Tag
SELECT
    DATE(created_at) AS date,
    SUM(total) AS daily_sales,
    LAG(SUM(total)) OVER (ORDER BY DATE(created_at)) AS prev_day,
    SUM(total) - LAG(SUM(total)) OVER (ORDER BY DATE(created_at)) AS diff
FROM orders
GROUP BY DATE(created_at);
```

### NTILE (Quartile)

```sql
-- Produkte in Preisquartile einteilen
SELECT
    name,
    price,
    NTILE(4) OVER (ORDER BY price) AS price_quartile
FROM products;
```

---

## MongoDB: Aggregation Pipeline

### Grundstruktur

```dart
final pipeline = AggregationPipelineBuilder()
    .addStage(Match(where.eq('category', 'electronics')))
    .addStage(Sort({'price': -1}))
    .addStage(Limit(10))
    .build();

final results = await collection.aggregateToStream(pipeline).toList();
```

### $match (Filter)

```dart
// Äquivalent zu WHERE
final pipeline = [
  {
    r'$match': {
      'category': 'electronics',
      'price': {r'$gte': 100},
    }
  }
];
```

### $group (Aggregation)

```dart
// Verkäufe pro Kategorie
final pipeline = [
  {
    r'$group': {
      '_id': r'$category',
      'totalSales': {r'$sum': r'$price'},
      'avgPrice': {r'$avg': r'$price'},
      'count': {r'$sum': 1},
    }
  }
];
```

### $project (Felder auswählen/transformieren)

```dart
final pipeline = [
  {
    r'$project': {
      'name': 1,
      'price': 1,
      'discountedPrice': {r'$multiply': [r'$price', 0.9]},
      '_id': 0,
    }
  }
];
```

### $lookup (JOIN)

```dart
// Produkte mit Kategorie-Details
final pipeline = [
  {
    r'$lookup': {
      'from': 'categories',
      'localField': 'categoryId',
      'foreignField': '_id',
      'as': 'category',
    }
  },
  {
    r'$unwind': r'$category'
  }
];
```

### Komplettes Beispiel

```dart
Future<List<Map<String, dynamic>>> getCategorySales() async {
  final pipeline = [
    // Filter: Nur abgeschlossene Bestellungen
    {
      r'$match': {'status': 'completed'}
    },
    // Unwind: Array von Items auflösen
    {
      r'$unwind': r'$items'
    },
    // Lookup: Produkt-Details laden
    {
      r'$lookup': {
        'from': 'products',
        'localField': 'items.productId',
        'foreignField': '_id',
        'as': 'product',
      }
    },
    {
      r'$unwind': r'$product'
    },
    // Group: Nach Kategorie gruppieren
    {
      r'$group': {
        '_id': r'$product.category',
        'totalRevenue': {
          r'$sum': {
            r'$multiply': [r'$items.quantity', r'$items.price']
          }
        },
        'totalQuantity': {r'$sum': r'$items.quantity'},
        'orderCount': {r'$sum': 1},
      }
    },
    // Sort: Nach Umsatz absteigend
    {
      r'$sort': {'totalRevenue': -1}
    },
    // Project: Felder umbenennen
    {
      r'$project': {
        '_id': 0,
        'category': r'$_id',
        'totalRevenue': 1,
        'totalQuantity': 1,
        'orderCount': 1,
      }
    }
  ];

  return await orders.aggregateToStream(pipeline).toList();
}
```

---

## Performance-Optimierung

### SQL: EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE
SELECT p.*, c.name AS category
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE p.price > 100;
```

### Indizes für häufige Queries

```sql
-- Index für WHERE-Klauseln
CREATE INDEX idx_products_price ON products(price);

-- Index für JOINs
CREATE INDEX idx_products_category ON products(category_id);

-- Composite Index für Filter + Sort
CREATE INDEX idx_products_cat_price ON products(category_id, price DESC);
```

### MongoDB: explain()

```dart
final explanation = await collection.aggregate(
  pipeline,
  explain: true,
).toList();
print(explanation);
```

---

## Dart Integration

```dart
class AnalyticsRepository {
  final Pool _pool;

  AnalyticsRepository(this._pool);

  /// Top-Produkte pro Kategorie
  Future<List<Map<String, dynamic>>> getTopProductsByCategory({
    int topN = 5,
  }) async {
    final result = await _pool.execute(Sql.named('''
      WITH ranked_products AS (
        SELECT
          p.*,
          c.name AS category_name,
          ROW_NUMBER() OVER (
            PARTITION BY p.category_id
            ORDER BY p.price DESC
          ) AS rank
        FROM products p
        LEFT JOIN categories c ON p.category_id = c.id
      )
      SELECT *
      FROM ranked_products
      WHERE rank <= @topN
      ORDER BY category_name, rank
    '''), parameters: {'topN': topN});

    return result.map((r) => r.toColumnMap()).toList();
  }

  /// Umsatzentwicklung
  Future<List<Map<String, dynamic>>> getSalesTimeline({
    required DateTime from,
    required DateTime to,
  }) async {
    final result = await _pool.execute(Sql.named('''
      SELECT
        DATE(created_at) AS date,
        COUNT(*) AS order_count,
        SUM(total) AS daily_revenue,
        SUM(SUM(total)) OVER (ORDER BY DATE(created_at)) AS cumulative_revenue
      FROM orders
      WHERE created_at >= @from AND created_at <= @to
      GROUP BY DATE(created_at)
      ORDER BY date
    '''), parameters: {'from': from, 'to': to});

    return result.map((r) => r.toColumnMap()).toList();
  }
}
```

---

## Zusammenfassung

| Konzept | SQL | MongoDB |
|---------|-----|---------|
| Filter | WHERE | $match |
| Gruppieren | GROUP BY | $group |
| Sortieren | ORDER BY | $sort |
| Limit | LIMIT | $limit |
| JOIN | JOIN | $lookup |
| Projektion | SELECT | $project |
| Subquery | (SELECT...) | Pipeline Stage |

---

## Nächste Schritte

In der nächsten Einheit lernst du **Redis & Caching**: Wie du häufige Abfragen cachst und die Performance verbesserst.
