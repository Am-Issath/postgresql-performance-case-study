-- Alert Threshold Queries
-- Use these with monitoring tools (Grafana, Datadog, etc.)

-- ALERT: Queries running longer than 60 seconds
SELECT 
    COUNT(*) AS long_running_queries
FROM pg_stat_activity
WHERE state = 'active'
    AND (NOW() - query_start) > interval '60 seconds'
    AND query NOT LIKE '%pg_stat_activity%';
-- Alert if count > 0

-- ALERT: High percentage of dead tuples
SELECT 
    relname,
    ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) AS dead_percent
FROM pg_stat_user_tables
WHERE ROUND(100.0 * n_dead_tup / NULLIF(n_live_tup + n_dead_tup, 0), 2) > 25
    AND n_live_tup > 10000;
-- Alert if any rows returned

-- ALERT: Cache hit ratio below threshold
SELECT 
    ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2) AS cache_hit_ratio
FROM pg_statio_user_tables;
-- Alert if < 95%

-- ALERT: Queries with high average execution time
SELECT 
    COUNT(*) AS slow_query_count
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- 100ms threshold
    AND calls > 100;  -- Only queries called frequently
-- Alert if count > 10

-- ALERT: Autovacuum not running
SELECT 
    relname,
    last_autovacuum,
    n_dead_tup
FROM pg_stat_user_tables
WHERE last_autovacuum < NOW() - interval '7 days'
    AND n_dead_tup > 10000;
-- Alert if any rows returned

-- ALERT: Connection pool saturation
SELECT 
    COUNT(*) AS active_connections,
    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') AS max_connections
FROM pg_stat_activity
WHERE state = 'active';
-- Alert if active_connections / max_connections > 0.8

-- ALERT: Excessive sequential scans
SELECT 
    relname,
    seq_scan
FROM pg_stat_user_tables
WHERE seq_scan > 10000  -- More than 10k scans
    AND n_live_tup > 100000  -- On tables with significant data
    AND seq_scan > idx_scan;  -- More sequential than index scans
-- Alert if any rows returned