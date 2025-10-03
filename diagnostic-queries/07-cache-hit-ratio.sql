-- Check Cache Hit Ratio
-- Low cache hit ratio may indicate missing indexes or insufficient memory

SELECT
    schemaname,
    relname AS table_name,
    heap_blks_read AS disk_reads,
    heap_blks_hit AS cache_hits,
    CASE 
        WHEN (heap_blks_hit + heap_blks_read) > 0
        THEN ROUND(100.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2)
        ELSE 0
    END AS cache_hit_ratio_percent
FROM pg_statio_user_tables
WHERE (heap_blks_hit + heap_blks_read) > 0
ORDER BY cache_hit_ratio_percent ASC
LIMIT 20;

-- Overall database cache hit ratio
SELECT 
    SUM(heap_blks_read) AS total_disk_reads,
    SUM(heap_blks_hit) AS total_cache_hits,
    ROUND(100.0 * SUM(heap_blks_hit) / NULLIF(SUM(heap_blks_hit) + SUM(heap_blks_read), 0), 2) AS overall_cache_hit_ratio
FROM pg_statio_user_tables;

-- Target: 99%+ cache hit ratio is ideal
-- Below 95% may indicate performance issues