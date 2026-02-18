# Lösung 7.7: Komplexe Queries & Aggregationen

## SQL Lösungen

### 1.1 Produkte über Durchschnittspreis

```sql
SELECT name, price
FROM products
WHERE price > (SELECT AVG(price) FROM products)
ORDER BY price DESC;
```

### 1.2 Kunden ohne Bestellungen

```sql
SELECT name, email
FROM customers
WHERE id NOT IN (
    SELECT DISTINCT customer_id FROM orders
);

-- Alternativ mit NOT EXISTS (oft effizienter)
SELECT name, email
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 FROM orders WHERE customer_id = c.id
);
```

### 1.3 Bestseller pro Kategorie

```sql
WITH product_sales AS (
    SELECT
        p.id,
        p.name,
        p.category_id,
        SUM(oi.quantity) AS total_sold
    FROM products p
    JOIN order_items oi ON p.id = oi.product_id
    GROUP BY p.id, p.name, p.category_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY total_sold DESC) AS rank
    FROM product_sales
)
SELECT
    c.name AS category,
    r.name AS product,
    r.total_sold
FROM ranked r
JOIN categories c ON r.category_id = c.id
WHERE rank = 1;
```

### 2.1 Kategorie-Statistiken

```sql
WITH category_stats AS (
    SELECT
        c.id,
        c.name,
        COUNT(p.id) AS product_count,
        COALESCE(AVG(p.price), 0) AS avg_price,
        COALESCE(SUM(p.stock), 0) AS total_stock,
        COALESCE(MIN(p.price), 0) AS min_price,
        COALESCE(MAX(p.price), 0) AS max_price
    FROM categories c
    LEFT JOIN products p ON c.id = p.category_id
    GROUP BY c.id, c.name
)
SELECT *
FROM category_stats
WHERE product_count > 0
ORDER BY avg_price DESC;
```

### 2.2 Kunden-Übersicht

```sql
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS order_count,
        SUM(total) AS total_spent,
        AVG(total) AS avg_order_value,
        MAX(created_at) AS last_order
    FROM orders
    GROUP BY customer_id
)
SELECT
    c.id,
    c.name,
    c.email,
    COALESCE(co.order_count, 0) AS orders,
    COALESCE(co.total_spent, 0) AS spent,
    COALESCE(co.avg_order_value, 0) AS avg_order,
    co.last_order
FROM customers c
LEFT JOIN customer_orders co ON c.id = co.customer_id
ORDER BY spent DESC;
```

### 3. Recursive CTE

```sql
WITH RECURSIVE category_tree AS (
    -- Basis: Root-Kategorien
    SELECT
        id,
        name,
        parent_id,
        0 AS depth,
        name::TEXT AS path
    FROM categories
    WHERE parent_id IS NULL

    UNION ALL

    -- Rekursion: Unterkategorien
    SELECT
        c.id,
        c.name,
        c.parent_id,
        ct.depth + 1,
        ct.path || ' > ' || c.name
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT id, name, depth, path
FROM category_tree
ORDER BY path;
```

### 4.1 Ranking

```sql
WITH ranked_products AS (
    SELECT
        p.id,
        p.name,
        c.name AS category,
        p.price,
        RANK() OVER (PARTITION BY p.category_id ORDER BY p.price DESC) AS rank
    FROM products p
    LEFT JOIN categories c ON p.category_id = c.id
)
SELECT category, name, price, rank
FROM ranked_products
WHERE rank <= 3
ORDER BY category, rank;
```

### 4.2 Running Total

```sql
SELECT
    DATE(created_at) AS date,
    COUNT(*) AS order_count,
    SUM(total) AS daily_revenue,
    SUM(SUM(total)) OVER (ORDER BY DATE(created_at)) AS running_total
FROM orders
GROUP BY DATE(created_at)
ORDER BY date;
```

### 4.3 Vergleich mit Vortag

```sql
WITH daily_stats AS (
    SELECT
        DATE(created_at) AS date,
        SUM(total) AS revenue
    FROM orders
    GROUP BY DATE(created_at)
)
SELECT
    date,
    revenue,
    LAG(revenue) OVER (ORDER BY date) AS prev_day,
    revenue - LAG(revenue) OVER (ORDER BY date) AS diff,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY date)) /
        NULLIF(LAG(revenue) OVER (ORDER BY date), 0) * 100,
        2
    ) AS change_percent
FROM daily_stats
ORDER BY date;
```

### 4.4 Preisquartile

```sql
SELECT
    name,
    price,
    quartile,
    CASE
        WHEN quartile = 1 THEN 'Budget'
        WHEN quartile = 2 THEN 'Standard'
        WHEN quartile = 3 THEN 'Premium'
        WHEN quartile = 4 THEN 'Luxury'
    END AS segment
FROM (
    SELECT
        name,
        price,
        NTILE(4) OVER (ORDER BY price) AS quartile
    FROM products
) ranked
ORDER BY price;
```

---

## MongoDB Lösungen

### 5.1 Umsatz pro Kategorie

```dart
Future<List<Map<String, dynamic>>> getSalesByCategory() async {
  final pipeline = [
    // Nur abgeschlossene Bestellungen
    {r'$match': {'status': 'completed'}},

    // Items-Array auflösen
    {r'$unwind': r'$items'},

    // Nach Kategorie gruppieren
    {
      r'$group': {
        '_id': r'$items.category',
        'totalRevenue': {
          r'$sum': {r'$multiply': [r'$items.price', r'$items.quantity']}
        },
        'totalQuantity': {r'$sum': r'$items.quantity'},
        'orderCount': {r'$sum': 1},
      }
    },

    // Sortieren
    {r'$sort': {'totalRevenue': -1}},

    // Felder umbenennen
    {
      r'$project': {
        '_id': 0,
        'category': r'$_id',
        'revenue': r'$totalRevenue',
        'quantity': r'$totalQuantity',
        'orders': r'$orderCount',
      }
    }
  ];

  return await orders.aggregateToStream(pipeline).toList();
}
```

### 5.2 Top-Kunden

```dart
Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
  final pipeline = [
    // Nach Kunde gruppieren
    {
      r'$group': {
        '_id': r'$customerId',
        'totalSpent': {r'$sum': r'$total'},
        'orderCount': {r'$sum': 1},
        'avgOrder': {r'$avg': r'$total'},
        'lastOrder': {r'$max': r'$createdAt'},
      }
    },

    // Sortieren
    {r'$sort': {'totalSpent': -1}},

    // Limit
    {r'$limit': limit},

    // Kunden-Details laden
    {
      r'$lookup': {
        'from': 'customers',
        'localField': '_id',
        'foreignField': '_id',
        'as': 'customer',
      }
    },
    {r'$unwind': r'$customer'},

    // Finales Format
    {
      r'$project': {
        '_id': 0,
        'customerId': r'$_id',
        'name': r'$customer.name',
        'email': r'$customer.email',
        'totalSpent': 1,
        'orderCount': 1,
        'avgOrder': {r'$round': [r'$avgOrder', 2]},
        'lastOrder': 1,
      }
    }
  ];

  return await orders.aggregateToStream(pipeline).toList();
}
```

### 5.3 Produkt-Performance

```dart
Future<List<Map<String, dynamic>>> getProductPerformance() async {
  final pipeline = [
    // Items auflösen
    {r'$unwind': r'$items'},

    // Nach Produkt gruppieren
    {
      r'$group': {
        '_id': r'$items.productId',
        'totalSold': {r'$sum': r'$items.quantity'},
        'totalRevenue': {
          r'$sum': {r'$multiply': [r'$items.price', r'$items.quantity']}
        },
        'orderCount': {r'$sum': 1},
      }
    },

    // Durchschnitt berechnen
    {
      r'$addFields': {
        'avgOrderSize': {r'$divide': [r'$totalSold', r'$orderCount']},
        'avgOrderValue': {r'$divide': [r'$totalRevenue', r'$orderCount']},
      }
    },

    // Produkt-Details laden
    {
      r'$lookup': {
        'from': 'products',
        'localField': '_id',
        'foreignField': '_id',
        'as': 'product',
      }
    },
    {r'$unwind': r'$product'},

    // Sortieren nach Umsatz
    {r'$sort': {'totalRevenue': -1}},

    // Finales Format
    {
      r'$project': {
        '_id': 0,
        'productId': r'$_id',
        'name': r'$product.name',
        'category': r'$product.category',
        'totalSold': 1,
        'totalRevenue': {r'$round': [r'$totalRevenue', 2]},
        'orderCount': 1,
        'avgOrderSize': {r'$round': [r'$avgOrderSize', 2]},
      }
    }
  ];

  return await orderItems.aggregateToStream(pipeline).toList();
}
```

---

## Analytics Repository

```dart
class AnalyticsRepository {
  final Pool _pool;

  AnalyticsRepository(this._pool);

  Future<Map<String, dynamic>> getDashboardStats() async {
    final result = await _pool.execute('''
      SELECT
        (SELECT COUNT(*) FROM orders) AS total_orders,
        (SELECT COALESCE(SUM(total), 0) FROM orders) AS total_revenue,
        (SELECT COALESCE(AVG(total), 0) FROM orders) AS avg_order_value,
        (SELECT COUNT(*) FROM customers) AS total_customers,
        (SELECT COUNT(*) FROM products WHERE stock < 10) AS low_stock_count,
        (
          SELECT c.name
          FROM categories c
          JOIN products p ON c.id = p.category_id
          JOIN order_items oi ON p.id = oi.product_id
          GROUP BY c.id, c.name
          ORDER BY SUM(oi.quantity * oi.unit_price) DESC
          LIMIT 1
        ) AS top_category
    ''');

    return result.first.toColumnMap();
  }

  Future<List<Map<String, dynamic>>> getSalesTrend({int days = 30}) async {
    final result = await _pool.execute(Sql.named('''
      WITH daily_sales AS (
        SELECT
          DATE(created_at) AS date,
          COUNT(*) AS orders,
          SUM(total) AS revenue
        FROM orders
        WHERE created_at >= NOW() - INTERVAL '@days days'
        GROUP BY DATE(created_at)
      )
      SELECT
        date,
        orders,
        revenue,
        SUM(revenue) OVER (ORDER BY date) AS cumulative_revenue,
        AVG(revenue) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS moving_avg_7d
      FROM daily_sales
      ORDER BY date
    '''), parameters: {'days': days});

    return result.map((r) => r.toColumnMap()).toList();
  }
}
```
