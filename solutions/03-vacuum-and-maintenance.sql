-- VACUUM and Table Maintenance
-- Essential for long-term performance

-- Check if VACUUM is needed
SELECT
    schemaname,
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_tuple_percent,
    last_autovacuum
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;

-- Manual VACUUM (verbose for monitoring progress)
-- Replace 'your_table_name' with actual table
SET statement_timeout = '30min';
VACUUM (VERBOSE, ANALYZE) your_table_name;

-- If regular VACUUM isn't enough, use VACUUM FULL
-- WARNING: VACUUM FULL locks the table and rewrites it completely
-- Only use during maintenance windows
-- VACUUM FULL VERBOSE your_table_name;

-- Tune autovacuum for specific high-write tables
ALTER TABLE your_table_name SET (
    autovacuum_vacuum_scale_factor = 0.05,  -- Vacuum at 5% changes instead of 20%
    autovacuum_vacuum_threshold = 1000,      -- Vacuum after 1000 row changes
    autovacuum_vacuum_cost_delay = 10,       -- Slower but less disruptive
    autovacuum_vacuum_cost_limit = 1000      -- More work per round
);

-- Verify autovacuum settings for table
SELECT 
    relname,
    reloptions
FROM pg_class
WHERE relname = 'your_table_name';

-- Monitor autovacuum activity
SELECT 
    schemaname,
    relname,
    last_vacuum,
    last_autovacuum,
    vacuum_count,
    autovacuum_count
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY autovacuum_count DESC;

-- MAINTENANCE SCHEDULE RECOMMENDATION:
-- Daily: Let autovacuum run automatically
-- Weekly: Check dead tuple percentages
-- Monthly: Review vacuum effectiveness
-- Quarterly: Consider REINDEX if bloat is high