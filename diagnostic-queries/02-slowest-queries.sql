-- Find Slowest Queries by Total Execution Time
-- This identifies queries consuming the most database resources

SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms,
    ROUND((100 * total_exec_time / SUM(total_exec_time) OVER())::numeric, 2) AS percent_of_total
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY total_exec_time DESC
LIMIT 20;

-- Find queries with most calls (potential N+1 problems)
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(total_exec_time::numeric, 2) AS total_time_ms
FROM pg_stat_statements
WHERE query NOT LIKE '%pg_stat_statements%'
ORDER BY calls DESC
LIMIT 20;

-- Find queries with high average execution time
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_time_ms,
    ROUND(max_exec_time::numeric, 2) AS max_time_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- queries averaging over 100ms
    AND query NOT LIKE '%pg_stat_statements%'
ORDER BY mean_exec_time DESC
LIMIT 20;