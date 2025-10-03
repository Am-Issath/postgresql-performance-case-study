-- REINDEX to Fix Index Bloat
-- Use when indexes become fragmented over time

-- Check index bloat
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS current_size,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes
WHERE tablename = 'your_table_name'
ORDER BY pg_relation_size(indexrelid) DESC;

-- REINDEX specific index
-- Using CONCURRENTLY to avoid locking
REINDEX INDEX CONCURRENTLY idx_user_sessions_token_active;

-- REINDEX entire table (all indexes)
-- WARNING: This can take a long time on large tables
-- REINDEX TABLE CONCURRENTLY your_table_name;

-- Alternative: Drop and recreate index
-- Sometimes faster than REINDEX for very bloated indexes
-- DROP INDEX CONCURRENTLY old_bloated_index;
-- CREATE INDEX CONCURRENTLY new_index ON table_name(columns);

-- Monitor REINDEX progress (in separate session)
SELECT 
    pid,
    phase,
    blocks_done,
    blocks_total,
    ROUND(100.0 * blocks_done / NULLIF(blocks_total, 0), 2) AS percent_complete,
    tuples_done,
    tuples_total
FROM pg_stat_progress_create_index
WHERE relid = 'your_table_name'::regclass;

-- WHEN TO REINDEX:
-- 1. Index size grows significantly without table growth
-- 2. Query performance degrades over time
-- 3. After major bulk operations (mass deletes/updates)
-- 4. Every 6-12 months for high-write tables

-- NOTE: REINDEX CONCURRENTLY requires PostgreSQL 12+