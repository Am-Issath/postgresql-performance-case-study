-- Find Indexes That Are Never or Rarely Used
-- These are candidates for removal

SELECT
    schemaname,
    tablename AS table_name,
    indexname AS index_name,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_get_indexdef(indexrelid) AS index_definition
FROM pg_stat_user_indexes
WHERE idx_scan < 50  -- Used fewer than 50 times
    AND schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Summary of total wasted space from unused indexes
SELECT
    SUM(pg_relation_size(indexrelid)) AS total_bytes,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS total_size,
    COUNT(*) AS unused_index_count
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND schemaname = 'public';