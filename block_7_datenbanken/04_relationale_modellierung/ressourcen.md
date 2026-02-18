# Ressourcen: Relationale Modellierung

## Konzepte

- [Database Normalization](https://www.guru99.com/database-normalization.html)
- [SQL Joins Visualizer](https://sql-joins.leopard.in.ua/)
- [PostgreSQL Constraints](https://www.postgresql.org/docs/current/ddl-constraints.html)

## Cheat Sheet: Beziehungen

```sql
-- 1:1 (One-to-One)
CREATE TABLE user_profiles (
    user_id INTEGER UNIQUE REFERENCES users(id)
);

-- 1:n (One-to-Many)
CREATE TABLE products (
    category_id INTEGER REFERENCES categories(id)
);

-- n:m (Many-to-Many)
CREATE TABLE product_tags (
    product_id INTEGER REFERENCES products(id),
    tag_id INTEGER REFERENCES tags(id),
    PRIMARY KEY (product_id, tag_id)
);

-- Selbstreferenz (Hierarchie)
CREATE TABLE categories (
    parent_id INTEGER REFERENCES categories(id)
);
```

## Cheat Sheet: Foreign Key Options

```sql
-- ON DELETE
REFERENCES table(id) ON DELETE CASCADE    -- Löscht verknüpfte
REFERENCES table(id) ON DELETE SET NULL   -- Setzt NULL
REFERENCES table(id) ON DELETE RESTRICT   -- Verhindert Löschen
REFERENCES table(id) ON DELETE SET DEFAULT

-- ON UPDATE
REFERENCES table(id) ON UPDATE CASCADE    -- Übernimmt Änderung
REFERENCES table(id) ON UPDATE RESTRICT   -- Verhindert Änderung
```

## Cheat Sheet: JOINs

```sql
-- INNER JOIN
SELECT * FROM a INNER JOIN b ON a.b_id = b.id;

-- LEFT JOIN
SELECT * FROM a LEFT JOIN b ON a.b_id = b.id;

-- RIGHT JOIN
SELECT * FROM a RIGHT JOIN b ON a.b_id = b.id;

-- FULL OUTER JOIN
SELECT * FROM a FULL OUTER JOIN b ON a.b_id = b.id;

-- Multiple JOINs
SELECT *
FROM orders o
JOIN customers c ON o.customer_id = c.id
JOIN order_items oi ON o.id = oi.order_id
JOIN products p ON oi.product_id = p.id;

-- Self JOIN
SELECT c.name, parent.name AS parent
FROM categories c
LEFT JOIN categories parent ON c.parent_id = parent.id;
```

## Cheat Sheet: Aggregation mit JOIN

```sql
-- Gruppieren nach Parent
SELECT
    c.name AS category,
    COUNT(p.id) AS product_count,
    AVG(p.price) AS avg_price
FROM categories c
LEFT JOIN products p ON c.id = p.category_id
GROUP BY c.id, c.name;

-- STRING_AGG für Listen
SELECT
    p.name,
    STRING_AGG(t.name, ', ') AS tags
FROM products p
LEFT JOIN product_tags pt ON p.id = pt.product_id
LEFT JOIN tags t ON pt.tag_id = t.id
GROUP BY p.id, p.name;
```

## Cheat Sheet: Recursive CTE

```sql
-- Hierarchie traversieren
WITH RECURSIVE category_tree AS (
    -- Basis
    SELECT id, name, parent_id, 0 AS depth
    FROM categories WHERE parent_id IS NULL

    UNION ALL

    -- Rekursion
    SELECT c.id, c.name, c.parent_id, ct.depth + 1
    FROM categories c
    JOIN category_tree ct ON c.parent_id = ct.id
)
SELECT * FROM category_tree;
```

## Normalformen

| Form | Regel |
|------|-------|
| 1NF | Atomare Werte, keine Wiederholungen |
| 2NF | 1NF + volle funktionale Abhängigkeit |
| 3NF | 2NF + keine transitiven Abhängigkeiten |

## Best Practices

1. **Foreign Keys immer definieren**
2. **ON DELETE CASCADE nur bei echten Abhängigkeiten**
3. **Indizes auf Foreign Keys**
4. **Zwischentabellen für n:m**
5. **Normalisierung bis 3NF**
6. **Denormalisierung nur für Performance**
