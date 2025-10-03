-- Find Tables with Excessive Sequential Scans
-- High seq_scan with low index usage indicates missing indexes

SELECT
    schemaname,
    relname AS table_name,
    seq_scan AS sequential_scans,
    seq_tup_read AS rows_read_sequentially,
    idx_scan AS index_scans,
    CASE 
        WHEN seq_scan > 0 
        THEN ROUND(seq_tup_read::numeric / seq_scan, 0)
        ELSE 0
    END AS avg_rows_per_seq_scan,
    n_live_tup AS live_rows,
    CASE
        WHEN (seq_scan + idx_scan) > 0 
        THEN ROUND(100.0 * idx_scan / (seq_scan + idx_scan), 2)
        ELSE 0
    END AS index_usage_percent
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_scan DESC, seq_tup_read DESC
LIMIT 25;

-- Tables doing many sequential scans with low index usage
SELECT
    schemaname,
    relname AS table_name,
    seq_scan,
    idx_scan,
    n_live_tup,
    pg_size_pretty(pg_relation_size(relname::regclass)) AS table_size,
    CASE
        WHEN (seq_scan + idx_scan) > 0 
        THEN ROUND(100.0 * idx_scan / (seq_scan + idx_scan), 2)
        ELSE 0
    END AS index_usage_percent
FROM pg_stat_user_tables
WHERE seq_scan > 100  -- At least 100 sequential scans
    AND seq_scan > idx_scan  -- More sequential than index scans
ORDER BY seq_scan DESC
LIMIT 20;