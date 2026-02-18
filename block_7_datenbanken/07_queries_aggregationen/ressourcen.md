# Ressourcen: Komplexe Queries & Aggregationen

## SQL Dokumentation

- [PostgreSQL Window Functions](https://www.postgresql.org/docs/current/tutorial-window.html)
- [PostgreSQL CTEs](https://www.postgresql.org/docs/current/queries-with.html)
- [MongoDB Aggregation](https://www.mongodb.com/docs/manual/aggregation/)

## Cheat Sheet: Subqueries

```sql
-- Scalar Subquery
SELECT name FROM products WHERE price > (SELECT AVG(price) FROM products);

-- IN Subquery
SELECT * FROM customers WHERE id IN (SELECT customer_id FROM orders);

-- EXISTS Subquery
SELECT * FROM customers c WHERE EXISTS (SELECT 1 FROM orders WHERE customer_id = c.id);

-- Correlated Subquery
SELECT name, (SELECT COUNT(*) FROM orders WHERE customer_id = c.id) AS order_count
FROM customers c;
```

## Cheat Sheet: CTEs

```sql
-- Simple CTE
WITH stats AS (
    SELECT category_id, AVG(price) AS avg_price
    FROM products GROUP BY category_id
)
SELECT * FROM stats;

-- Multiple CTEs
WITH cte1 AS (...), cte2 AS (...)
SELECT * FROM cte1 JOIN cte2 ON ...;

-- Recursive CTE
WITH RECURSIVE tree AS (
    SELECT id, name, parent_id, 0 AS depth FROM categories WHERE parent_id IS NULL
    UNION ALL
    SELECT c.id, c.name, c.parent_id, t.depth + 1
    FROM categories c JOIN tree t ON c.parent_id = t.id
)
SELECT * FROM tree;
```

## Cheat Sheet: Window Functions

```sql
-- Ranking
ROW_NUMBER() OVER (ORDER BY price)           -- 1,2,3,4,5
RANK() OVER (ORDER BY price)                 -- 1,2,2,4,5 (gaps)
DENSE_RANK() OVER (ORDER BY price)           -- 1,2,2,3,4 (no gaps)
NTILE(4) OVER (ORDER BY price)               -- Quartiles 1-4

-- Partition
RANK() OVER (PARTITION BY category_id ORDER BY price)

-- Running Aggregates
SUM(total) OVER (ORDER BY date)              -- Running total
AVG(total) OVER (ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)  -- 7-day average

-- Offset Functions
LAG(price) OVER (ORDER BY date)              -- Previous row
LEAD(price) OVER (ORDER BY date)             -- Next row
LAG(price, 7) OVER (ORDER BY date)           -- 7 rows back
FIRST_VALUE(price) OVER (ORDER BY date)      -- First in window
LAST_VALUE(price) OVER (ORDER BY date)       -- Last in window
```

## Cheat Sheet: MongoDB Aggregation

```dart
// $match (Filter)
{r'$match': {'status': 'active'}}

// $group (Aggregation)
{r'$group': {
  '_id': r'$category',
  'total': {r'$sum': r'$price'},
  'count': {r'$sum': 1},
  'avg': {r'$avg': r'$price'},
}}

// $sort
{r'$sort': {'total': -1}}

// $limit / $skip
{r'$limit': 10}
{r'$skip': 20}

// $project (Select fields)
{r'$project': {'name': 1, 'price': 1, '_id': 0}}

// $lookup (JOIN)
{r'$lookup': {
  'from': 'categories',
  'localField': 'categoryId',
  'foreignField': '_id',
  'as': 'category',
}}

// $unwind (Array -> Documents)
{r'$unwind': r'$items'}

// $addFields (Computed fields)
{r'$addFields': {
  'total': {r'$multiply': [r'$price', r'$quantity']}
}}
```

## Performance Tips

### SQL

```sql
-- EXPLAIN für Query-Analyse
EXPLAIN ANALYZE SELECT ...;

-- Indizes für WHERE und JOIN
CREATE INDEX idx_name ON table(column);

-- Partial Index
CREATE INDEX idx_active ON users(email) WHERE active = true;

-- Covering Index
CREATE INDEX idx_cover ON products(category_id) INCLUDE (name, price);
```

### MongoDB

```dart
// Index erstellen
await collection.createIndex(keys: {'category': 1, 'price': -1});

// explain()
final result = await collection.aggregate(pipeline, explain: true);
```
