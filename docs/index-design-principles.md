# Index Design Principles

## When to Create an Index

### Good Candidates

#### ✅ Columns frequently used in WHERE clauses

```sql
-- If you frequently query:
SELECT * FROM orders WHERE customer_id = 123;
-- Create index on customer_id
```

#### ✅ Columns used in JOIN conditions

```sql
-- If you frequently join:
SELECT * FROM orders o
JOIN customers c ON o.customer_id = c.id;
-- Index on orders.customer_id improves join performance
```

#### ✅ Columns used in ORDER BY clauses

```sql
-- If you frequently sort:
SELECT * FROM orders
WHERE status = 'pending'
ORDER BY created_at DESC;
-- Index on (status, created_at) helps both filter and sort
```

#### ✅ Foreign key columns

```sql
-- Always index foreign keys for:
-- - Faster joins
-- - Faster DELETE cascades
-- - Improved constraint checking
```

#### ✅ Columns with high selectivity (many unique values)

```sql
-- Good: email addresses, UUIDs, phone numbers
-- Bad: boolean flags, status fields with few values
```

---

### Poor Candidates

#### ❌ Columns with very few distinct values

```sql
-- Bad: boolean with 50/50 distribution
CREATE INDEX idx_is_active ON users(is_active);
-- Only 2 values, index won't help much

-- Exception: if you mostly query one value, use partial index
CREATE INDEX idx_active_only ON users(is_active)
WHERE is_active = true;
```

#### ❌ Small tables (< 1,000 rows)

```sql
-- PostgreSQL will use sequential scan anyway
-- Index overhead not worth it
```

#### ❌ Columns rarely queried

```sql
-- Don't index just because you can
-- Only index what you actually query
```

#### ❌ Tables with very high write-to-read ratios

```sql
-- If you write 1000x more than you read,
-- index maintenance cost may exceed benefits
```

#### ❌ Columns that change frequently

```sql
-- Bad: last_updated timestamp
-- Every UPDATE rewrites the index
-- Only index if you query by this column
```

---

## Index Types in PostgreSQL

### B-tree (Default)

**Best for:** Equality and range queries

```sql
CREATE INDEX idx_name ON table_name(column_name);
```

**Use cases:**

- `WHERE col = value`
- `WHERE col > value`
- `WHERE col BETWEEN x AND y`
- `ORDER BY col`

**Example:**

```sql
-- Good for date ranges
CREATE INDEX idx_orders_created ON orders(created_at);

-- Query benefits:
SELECT * FROM orders
WHERE created_at >= '2024-01-01'
AND created_at < '2024-02-01';
```

---

### Partial Index

**Best for:** Queries that filter on specific values

```sql
CREATE INDEX idx_name ON table_name(column)
WHERE condition = true;
```

**Advantages:**

- Smaller index size (30-80% reduction typical)
- Faster to scan
- Lower maintenance overhead
- Better cache utilization
- Reduced write amplification

**Example:**

```sql
-- Instead of indexing all orders:
CREATE INDEX idx_orders_status ON orders(status);
-- 100% of rows indexed

-- Only index active orders (20% of data):
CREATE INDEX idx_active_orders ON orders(status, customer_id)
WHERE status = 'active';
-- 80% smaller, only indexes what you query
```

**When to use:**

```sql
-- If 80%+ of queries filter for same value
SELECT * FROM orders WHERE status = 'pending';
-- Use: WHERE status = 'pending'

-- If you never query deleted records
SELECT * FROM users WHERE is_deleted = false;
-- Use: WHERE is_deleted = false
```

---

### Composite Index

**Best for:** Queries filtering on multiple columns

```sql
CREATE INDEX idx_name ON table_name(col1, col2, col3);
```

#### Column Order Rules:

**1. Most selective column first (highest cardinality)**

```sql
-- Bad: low selectivity first
CREATE INDEX idx_bad ON users(is_active, email);
-- is_active: only 2 values (true/false)

-- Good: high selectivity first
CREATE INDEX idx_good ON users(email, is_active);
-- email: millions of unique values
```

**2. Equality conditions before range conditions**

```sql
-- Bad: range condition first
CREATE INDEX idx_bad ON orders(created_at, status);

-- Good: equality first
CREATE INDEX idx_good ON orders(status, created_at);
-- Query: WHERE status = 'pending' AND created_at > '2024-01-01'
```

**3. Most frequently queried columns first**

```sql
-- If you often query by country alone, but rarely by city alone:
CREATE INDEX idx_location ON users(country, city);
-- Can use index for: WHERE country = 'US'
-- Cannot use for: WHERE city = 'New York' (without country)
```

#### Index Prefix Usage:

```sql
CREATE INDEX idx_abc ON table(a, b, c);

-- Can use index for:
WHERE a = 1                          ✓
WHERE a = 1 AND b = 2                ✓
WHERE a = 1 AND b = 2 AND c = 3      ✓

-- Cannot efficiently use index for:
WHERE b = 2                          ✗
WHERE c = 3                          ✗
WHERE b = 2 AND c = 3                ✗
```

---

### Covering Index (Index-Only Scans)

**Best for:** Avoiding table lookups

```sql
-- PostgreSQL 11+
CREATE INDEX idx_name ON table_name(filter_col)
INCLUDE (additional_cols);

-- Older versions: include all columns in index
CREATE INDEX idx_name ON table_name(filter_col, additional_cols);
```

**Example:**

```sql
-- Query needs: user_id, email, status
SELECT user_id, email, status
FROM users
WHERE email = 'user@example.com';

-- Covering index:
CREATE INDEX idx_users_email_covering
ON users(email)
INCLUDE (user_id, status);

-- Result: Index-only scan (no table access needed)
```

**Benefits:**

- Eliminates heap fetch (table lookup)
- 2-10x faster for selective queries
- Reduces I/O significantly

**Trade-offs:**

- Larger index size
- Slower writes (more data to maintain)

---

## Index Maintenance Costs

Every index you create increases:

| Operation   | Overhead              | Notes                          |
| ----------- | --------------------- | ------------------------------ |
| INSERT      | +5-15% per index      | Must update all indexes        |
| UPDATE      | +5-15% per index      | Only if indexed columns change |
| DELETE      | +5-10% per index      | Must update all indexes        |
| Disk space  | +20-50% of table size | Per index                      |
| VACUUM time | +10-30%               | More indexes to maintain       |
| Backup time | Proportional          | Larger database                |

**Example:**

```sql
-- Table: 10GB, 5 indexes averaging 2GB each
-- Total size: 10GB + (5 × 2GB) = 20GB
-- Backup time: 2x longer
-- INSERT performance: ~40% slower than no indexes
```

**Golden Rule:** Only create indexes you actually need.

---

## Common Mistakes

### Mistake #1: Over-Indexing

#### ❌ Bad: Too many single-column indexes

```sql
CREATE INDEX idx_col1 ON table(col1);
CREATE INDEX idx_col2 ON table(col2);
CREATE INDEX idx_col3 ON table(col3);

-- Problems:
-- - 3 indexes to maintain
-- - Can't use multiple simultaneously
-- - Wastes space
```

#### ✅ Good: One composite index

```sql
CREATE INDEX idx_composite ON table(col1, col2, col3);

-- Benefits:
-- - 1 index to maintain
-- - Handles queries on (col1), (col1,col2), (col1,col2,col3)
-- - More efficient
```

---

### Mistake #2: Wrong Column Order

#### ❌ Bad: Low selectivity column first

```sql
CREATE INDEX idx_bad ON users(is_active, email);
-- is_active: only 2 values (true/false)
-- Index needs to scan 50% of entries before using email

-- Query:
SELECT * FROM users WHERE is_active = true AND email = 'user@example.com';
-- Still scans millions of "active" entries
```

#### ✅ Good: High selectivity column first

```sql
CREATE INDEX idx_good ON users(email, is_active);
-- email: millions of unique values
-- Index finds exact email immediately

-- Same query, now finds 1 entry instantly
```

**How to determine selectivity:**

```sql
-- Check distinct values
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT column_name) AS distinct_values,
    ROUND(100.0 * COUNT(DISTINCT column_name) / COUNT(*), 2) AS selectivity_percent
FROM table_name;

-- High selectivity (> 50%): Good for first column
-- Low selectivity (< 10%): Consider partial index or place later
```

---

### Mistake #3: Indexing Everything

#### ❌ Bad: "Just in case" indexes

```sql
-- Don't do this:
CREATE INDEX idx_created_at ON orders(created_at);
-- "Maybe someone will query by date someday"

-- Result:
-- - Index never used (0 scans in 6 months)
-- - Slows down every INSERT
-- - Wastes 500MB of disk
```

#### ✅ Good: Index only what's frequently queried

```sql
-- Check usage first:
SELECT idx_scan
FROM pg_stat_user_indexes
WHERE indexname = 'idx_created_at';

-- If idx_scan = 0 after 30 days, drop it
DROP INDEX idx_created_at;
```

---

### Mistake #4: Ignoring Partial Indexes

#### ❌ Bad: Full index when you only query active records

```sql
CREATE INDEX idx_status ON orders(status);
-- Indexes all statuses: 'active', 'completed', 'cancelled', 'refunded'
-- Size: 800MB

-- But 80% of queries are:
SELECT * FROM orders WHERE status = 'active';
-- Only need 20% of the index
```

#### ✅ Good: Partial index for only active orders

```sql
CREATE INDEX idx_active_orders ON orders(status)
WHERE status = 'active';
-- Only indexes active orders (20% of data)
-- Size: 160MB (80% smaller)

-- Benefits:
-- - 5x smaller
-- - Faster to scan
-- - Less write overhead
-- - Better cache hit ratio
```

---

### Mistake #5: Duplicate Indexes

#### ❌ Bad: Redundant indexes

```sql
CREATE INDEX idx_user_id ON orders(user_id);
CREATE INDEX idx_user_created ON orders(user_id, created_at);

-- Problem: idx_user_id is redundant
-- idx_user_created can handle queries on just user_id
```

#### ✅ Good: Keep only the composite

```sql
-- Drop the single-column index
DROP INDEX idx_user_id;

-- Keep composite (handles both use cases)
CREATE INDEX idx_user_created ON orders(user_id, created_at);
```

**Find duplicate indexes:**

```sql
SELECT
    indrelid::regclass AS table_name,
    array_agg(indexrelid::regclass) AS indexes
FROM pg_index
GROUP BY indrelid, indkey
HAVING COUNT(*) > 1;
```

---

## Analyzing Query Performance

### Step 1: Identify Problem

```sql
-- Find slow queries
SELECT
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_ms,
    ROUND(total_exec_time::numeric, 2) AS total_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries averaging > 100ms
ORDER BY total_exec_time DESC
LIMIT 20;
```

### Step 2: Examine Execution Plan

```sql
EXPLAIN ANALYZE
SELECT * FROM table WHERE condition;
```

**What to look for:**

🔴 **Sequential Scan on large table → Needs index**

```
Seq Scan on orders (cost=0.00..45891.00 rows=234)
  Filter: (status = 'pending')
  Rows Removed by Filter: 1299766
```

🔴 **High "Rows Removed by Filter" → Poor selectivity**

```
-- 99.9% of rows filtered out = needs better index
Rows Removed by Filter: 1299766
rows=234
```

🔴 **Sort operation → Consider index with ORDER BY column**

```
Sort (cost=45891.00..45893.50 rows=1000)
  Sort Key: created_at
  Sort Method: external merge Disk: 89MB
```

🟢 **Index Scan → Good**

```
Index Scan using idx_orders_status on orders
  Index Cond: (status = 'pending')
```

🟢 **Index Only Scan → Excellent (best case)**

```
Index Only Scan using idx_orders_covering on orders
  Index Cond: (status = 'pending')
  Heap Fetches: 0
```

### Step 3: Test Index Impact

```sql
-- Before: Note the execution time
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending';
-- Execution Time: 2847.291 ms

-- Create test index
CREATE INDEX CONCURRENTLY idx_test ON orders(status);

-- After: Check improvement
EXPLAIN ANALYZE
SELECT * FROM orders WHERE status = 'pending';
-- Execution Time: 12.891 ms
-- Improvement: 99.5%
```

### Step 4: Monitor in Production

```sql
-- Check if index is being used (after 1 week)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS scans,
    idx_tup_read AS tuples_read,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE indexname = 'idx_test';

-- If idx_scan = 0 → Index not used, drop it
-- If idx_scan > 1000 → Valuable index, keep it
```

---

## Index Design Checklist

Before creating an index, ask yourself:

- [ ] Is this query actually slow? (> 100ms average)
- [ ] Is it called frequently? (> 1,000 times/day minimum)
- [ ] Will an index help? (Check with EXPLAIN - look for Seq Scan)
- [ ] Can I use a partial index instead of full? (Query filters on specific value?)
- [ ] Should this be composite with other columns? (Multi-column WHERE clause?)
- [ ] What's the write penalty? (High-write table = think twice)
- [ ] Do we have disk space? (Index = 20-50% of table size typically)
- [ ] Can we drop an unused index first? (Make space, reduce write overhead)
- [ ] Is there already an index that can handle this? (Check for duplicates)
- [ ] Is the column selectivity high enough? (> 10% unique values)

---

## Real-World Example

### Scenario

- **Table:** orders (5 million rows)
- **Query:** `SELECT * FROM orders WHERE user_id = ? AND status = 'active'`
- **Frequency:** 50,000 times/day
- **Current time:** 2,847 ms average

### Analysis

```sql
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE user_id = 123
AND status = 'active';
```

**Result:**

```
Seq Scan on orders (cost=0.00..125847.00 rows=234)
  Filter: ((user_id = 123) AND (status = 'active'))
  Rows Removed by Filter: 4999766
Planning Time: 0.143 ms
Execution Time: 2847.291 ms
```

**Problem:** Sequential scan removing 99.995% of rows

### Solution Options

#### Option 1: Full composite index

```sql
CREATE INDEX CONCURRENTLY idx_orders_user_status
ON orders(user_id, status);

-- Size: 980 MB
-- Performance: 2,847ms → 1.2ms
-- Write penalty: 12%
```

#### Option 2: Partial composite index (BETTER)

```sql
CREATE INDEX CONCURRENTLY idx_orders_active_user
ON orders(user_id, status)
WHERE status = 'active';

-- Size: 294 MB (70% smaller)
-- Performance: 2,847ms → 1.2ms (same speed)
-- Write penalty: 4% (only updates when status = 'active')
```

### Result

**Winner:** Option 2 (partial index)

**Why:**

- Same query performance
- 70% less disk space
- 66% lower write overhead
- Better cache utilization
- Only indexes data we actually query

**Verification:**

```sql
EXPLAIN ANALYZE
SELECT * FROM orders
WHERE user_id = 123
AND status = 'active';
```

**New plan:**

```
Index Scan using idx_orders_active_user on orders
  (cost=0.43..8.45 rows=1 width=237)
  (actual time=0.891..1.123 rows=234 loops=1)

  Index Cond: ((user_id = 123) AND (status = 'active'))

Planning Time: 0.247 ms
Execution Time: 1.234 ms
```

**Improvement:** 99.96% faster (2,307x speedup)

---

## Advanced Techniques

### Expression Indexes

For queries on computed values:

```sql
-- Query:
SELECT * FROM users WHERE LOWER(email) = 'user@example.com';

-- Index:
CREATE INDEX idx_users_email_lower
ON users(LOWER(email));
```

### Multi-Column GIN Indexes

For full-text search or array operations:

```sql
-- For JSONB columns
CREATE INDEX idx_data_gin ON table USING GIN (jsonb_column);

-- For text search
CREATE INDEX idx_content_search ON articles
USING GIN (to_tsvector('english', content));
```

### Conditional Unique Indexes

Enforce uniqueness only in specific cases:

```sql
-- Allow multiple soft-deleted users with same email
-- But only one active user per email
CREATE UNIQUE INDEX idx_users_email_unique
ON users(email)
WHERE is_deleted = false;
```

---

## Resources

- [PostgreSQL Index Types Documentation](https://www.postgresql.org/docs/current/indexes-types.html)
- [Index-Only Scans](https://www.postgresql.org/docs/current/indexes-index-only-scans.html)
- [Use The Index, Luke!](https://use-the-index-luke.com/) - Comprehensive indexing guide
- [PostgreSQL Wiki - Don't Do This](https://wiki.postgresql.org/wiki/Don't_Do_This)

---

## Summary

### Key Principles:

1. Index columns in WHERE, JOIN, and ORDER BY clauses
2. Put high-selectivity columns first in composite indexes
3. Use partial indexes when querying specific values frequently
4. Monitor index usage and drop unused indexes
5. Consider write penalties for high-traffic tables
6. Test with EXPLAIN ANALYZE before creating in production
7. Quality over quantity - fewer good indexes beat many mediocre ones

**Remember:** The best index is often the one you don't create. Every index has a cost. Only index what you actually need.
