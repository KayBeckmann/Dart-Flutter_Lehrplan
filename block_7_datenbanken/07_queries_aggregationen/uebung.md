# Übung 7.7: Komplexe Queries & Aggregationen

## Ziel

Schreibe komplexe Abfragen für Analysen und Reporting.

---

## Vorbereitung

Verwende die Shop-Datenbank aus den vorherigen Einheiten mit:
- customers, products, categories
- orders, order_items

---

## Aufgabe 1: Subqueries (15 min)

### 1.1 Produkte über Durchschnittspreis

```sql
-- TODO: Produkte die teurer als der Durchschnitt sind
SELECT name, price
FROM products
WHERE price > (...)
```

### 1.2 Kunden ohne Bestellungen

```sql
-- TODO: Kunden die noch nie bestellt haben
SELECT name, email
FROM customers
WHERE id NOT IN (...)
```

### 1.3 Bestseller pro Kategorie

```sql
-- TODO: Das meistverkaufte Produkt pro Kategorie
-- Hint: Subquery mit GROUP BY
```

---

## Aufgabe 2: CTEs (15 min)

### 2.1 Kategorie-Statistiken

```sql
WITH category_stats AS (
    -- TODO: Pro Kategorie: count, avg_price, total_stock
)
SELECT * FROM category_stats
WHERE count > 0
ORDER BY avg_price DESC;
```

### 2.2 Kunden-Übersicht

```sql
WITH customer_orders AS (
    -- TODO: Pro Kunde: order_count, total_spent, avg_order_value
)
SELECT
    c.name,
    c.email,
    COALESCE(co.order_count, 0) AS orders,
    COALESCE(co.total_spent, 0) AS spent
FROM customers c
LEFT JOIN customer_orders co ON c.id = co.customer_id
ORDER BY spent DESC;
```

---

## Aufgabe 3: Recursive CTE (10 min)

```sql
-- Kategorie-Hierarchie mit Pfad und Tiefe
WITH RECURSIVE category_tree AS (
    -- Basis
    -- TODO

    UNION ALL

    -- Rekursion
    -- TODO
)
SELECT
    id,
    name,
    depth,
    path
FROM category_tree
ORDER BY path;
```

Erwartete Ausgabe:
```
id | name         | depth | path
---|--------------|-------|---------------------------
1  | Electronics  | 0     | Electronics
4  | Laptops      | 1     | Electronics > Laptops
5  | Smartphones  | 1     | Electronics > Smartphones
2  | Clothing     | 0     | Clothing
6  | T-Shirts     | 1     | Clothing > T-Shirts
```

---

## Aufgabe 4: Window Functions (20 min)

### 4.1 Ranking

```sql
-- Top 3 Produkte pro Kategorie nach Preis
SELECT
    name,
    category_id,
    price,
    -- TODO: RANK() OVER (...)
FROM products
WHERE rank <= 3;
```

### 4.2 Running Total

```sql
-- Kumulativer Umsatz pro Tag
SELECT
    DATE(created_at) AS date,
    SUM(total) AS daily_revenue,
    -- TODO: SUM() OVER (ORDER BY ...) AS running_total
FROM orders
GROUP BY DATE(created_at);
```

### 4.3 Vergleich mit Vortag

```sql
-- Tagesumsatz mit Differenz zum Vortag
SELECT
    DATE(created_at) AS date,
    SUM(total) AS revenue,
    -- TODO: LAG() für Vortag
    -- TODO: Differenz berechnen
FROM orders
GROUP BY DATE(created_at);
```

### 4.4 Perzentile

```sql
-- Produkte in Preisquartile einteilen
SELECT
    name,
    price,
    -- TODO: NTILE(4)
    CASE
        WHEN quartile = 1 THEN 'Budget'
        WHEN quartile = 4 THEN 'Premium'
        ELSE 'Standard'
    END AS segment
FROM (
    SELECT name, price, NTILE(4) OVER (ORDER BY price) AS quartile
    FROM products
) ranked;
```

---

## Aufgabe 5: MongoDB Aggregation (20 min)

### 5.1 Umsatz pro Kategorie

```dart
Future<List<Map<String, dynamic>>> getSalesByCategory() async {
  final pipeline = [
    // TODO: $unwind items
    // TODO: $group by category
    // TODO: $sort by revenue
  ];

  return await orders.aggregateToStream(pipeline).toList();
}
```

### 5.2 Top-Kunden

```dart
Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
  final pipeline = [
    // TODO: $group by customerId
    // TODO: Calculate totalSpent, orderCount
    // TODO: $sort by totalSpent desc
    // TODO: $limit
    // TODO: $lookup customer details
  ];

  return await orders.aggregateToStream(pipeline).toList();
}
```

### 5.3 Produkt-Performance

```dart
Future<List<Map<String, dynamic>>> getProductPerformance() async {
  // Pro Produkt:
  // - totalSold (quantity)
  // - totalRevenue
  // - avgOrderSize
  // - orderCount

  final pipeline = [
    // TODO: Build pipeline
  ];

  return await orderItems.aggregateToStream(pipeline).toList();
}
```

---

## Aufgabe 6: Analytics Repository (Bonus, 15 min)

```dart
class AnalyticsRepository {
  final Pool _pool;

  AnalyticsRepository(this._pool);

  /// Dashboard-Statistiken
  Future<DashboardStats> getDashboardStats() async {
    // TODO: In einer Query:
    // - totalRevenue
    // - orderCount
    // - avgOrderValue
    // - topCategory
    // - lowStockCount
  }

  /// Sales Trend (letzte 30 Tage)
  Future<List<DailySales>> getSalesTrend() async {
    // TODO: Window Function für Running Total
  }

  /// ABC-Analyse (Produkte nach Umsatzanteil)
  Future<List<ProductABC>> getABCAnalysis() async {
    // TODO:
    // A: Top 20% (80% Umsatz)
    // B: Nächste 30%
    // C: Restliche 50%
  }
}
```

---

## Abgabe-Checkliste

- [ ] Subquery: Produkte über Durchschnitt
- [ ] Subquery: Kunden ohne Bestellungen
- [ ] CTE: Kategorie-Statistiken
- [ ] Recursive CTE: Kategorie-Hierarchie
- [ ] Window: Ranking pro Kategorie
- [ ] Window: Running Total
- [ ] Window: LAG für Vortagsvergleich
- [ ] MongoDB: Umsatz pro Kategorie
- [ ] MongoDB: Top-Kunden
- [ ] (Bonus) Analytics Repository
