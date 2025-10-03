-- Find Currently Running Slow Queries
-- Helps identify queries causing issues right now

SELECT 
    pid,
    NOW() - query_start AS duration,
    state,
    wait_event_type,
    wait_event,
    LEFT(query, 150) AS query_preview
FROM pg_stat_activity
WHERE state = 'active'
    AND query NOT ILIKE '%pg_stat_activity%'
    AND query_start IS NOT NULL
ORDER BY duration DESC;

-- Queries running longer than 1 minute
SELECT
    pid,
    usename AS user_name,
    application_name,
    client_addr,
    NOW() - query_start AS duration,
    state,
    LEFT(query, 200) AS query_preview
FROM pg_stat_activity
WHERE (NOW() - query_start) > interval '1 minute'
    AND state != 'idle'
    AND query NOT ILIKE '%pg_stat_activity%'
ORDER BY duration DESC;

-- Count of queries by state
SELECT 
    state,
    COUNT(*) AS query_count
FROM pg_stat_activity
GROUP BY state
ORDER BY query_count DESC;