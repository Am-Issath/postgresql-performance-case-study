-- Monthly Database Health Check
-- Run on first Sunday of each month

-- ===================================
-- 1. INDEX USAGE ANALYSIS
-- ===================================
SELECT 
    'Index Usage' AS check_type,
    tablename,
    indexname,
    idx_scan AS scans,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan ASC, pg_relation_size(indexrelid) DESC
LIMIT 20;

-- ===================================
-- 2. TABLE BLOAT CHECK
-- ===================================
SELECT
    'Table Bloat' AS check_type,
    relname AS table_name,
    n_live_tup,
    n_dead_tup,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_percent,
    CASE 
        WHEN ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) > 20 
        THEN 'ACTION NEEDED'
        ELSE 'OK'
    END AS status
FROM pg_stat_user_tables
WHERE n_live_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;

-- ===================================
-- 3. SLOWEST QUERIES
-- ===================================
SELECT 
    'Slow Queries' AS check_type,
    LEFT(query, 80) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_ms,
    ROUND(max_exec_time::numeric, 2) AS max_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY mean_exec_time DESC
LIMIT 20;

-- ===================================
-- 4. CACHE HIT RATIO
-- ===================================
SELECT 
    'Cache Performance' AS check_type,
    ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2) AS cache_hit_ratio,
    CASE 
        WHEN ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2) < 95 
        THEN 'ACTION NEEDED'
        ELSE 'OK'
    END AS status
FROM pg_statio_user_tables;

-- ===================================
-- 5. AUTOVACUUM EFFECTIVENESS
-- ===================================
SELECT
    'Autovacuum Status' AS check_type,
    relname,
    last_autovacuum,
    autovacuum_count,
    n_dead_tup,
    CASE 
        WHEN last_autovacuum < NOW() - interval '7 days' AND n_dead_tup > 10000 
        THEN 'ATTENTION NEEDED'
        ELSE 'OK'
    END AS status
FROM pg_stat_user_tables
WHERE n_live_tup > 1000
ORDER BY n_dead_tup DESC
LIMIT 20;

-- ===================================
-- 6. DATABASE SIZE GROWTH
-- ===================================
SELECT
    'Database Growth' AS check_type,
    pg_size_pretty(pg_database_size(current_database())) AS current_size,
    'Record this value monthly to track growth' AS note;

-- RECOMMENDED ACTIONS:
-- - If dead_percent > 20%: Schedule VACUUM
-- - If cache_hit_ratio < 95%: Investigate missing indexes or increase memory
-- - If idx_scan = 0 and size > 100MB: Consider dropping index
-- - If mean_exec_time > 1000ms: Investigate query optimization