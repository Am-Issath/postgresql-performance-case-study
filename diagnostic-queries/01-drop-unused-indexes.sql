-- Drop Unused Indexes Safely
-- IMPORTANT: Review these carefully before dropping in production

-- Step 1: Identify indexes to drop (review output first!)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_get_indexdef(indexrelid) AS index_definition
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND schemaname = 'public'
    AND indexrelid NOT IN (
        -- Exclude indexes used for constraints
        SELECT indexrelid 
        FROM pg_index 
        WHERE indisprimary OR indisunique
    )
ORDER BY pg_relation_size(indexrelid) DESC;

-- Step 2: Drop specific unused indexes
-- Replace 'index_name' with actual index name from above query
-- Using CONCURRENTLY to avoid locking the table

-- DROP INDEX CONCURRENTLY IF EXISTS index_name_1;
-- DROP INDEX CONCURRENTLY IF EXISTS index_name_2;
-- DROP INDEX CONCURRENTLY IF EXISTS index_name_3;

-- Step 3: Verify indexes were dropped
SELECT 
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname = 'public'
    AND tablename = 'your_table_name'
ORDER BY indexname;

-- SAFETY NOTES:
-- 1. Always use DROP INDEX CONCURRENTLY in production
-- 2. Test in staging environment first
-- 3. Have a backup plan to recreate if needed
-- 4. Monitor application after dropping
-- 5. Never drop primary key or unique constraint indexes