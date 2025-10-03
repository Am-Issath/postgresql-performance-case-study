-- Check Table Bloat and Dead Tuples
-- High percentage of dead tuples indicates need for VACUUM

SELECT
    schemaname,
    relname AS table_name,
    n_live_tup AS live_tuples,
    n_dead_tup AS dead_tuples,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
    last_vacuum,
    last_autovacuum,
    last_analyze,
    last_autoanalyze
FROM pg_stat_user_tables
WHERE n_live_tup > 1000  -- Only tables with significant data
ORDER BY n_dead_tup DESC
LIMIT 20;

-- Detailed bloat analysis for specific table
-- Replace 'your_table_name' with actual table name
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
    pg_size_pretty(pg_relation_size(relname::regclass)) AS table_size,
    last_vacuum,
    last_autovacuum
FROM pg_stat_user_tables
WHERE relname = 'your_table_name';