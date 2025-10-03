-- Drop Unused Indexes Safely
-- IMPORTANT: Review these carefully before dropping in production
-- Always test in staging environment first

-- ==============================================================================
-- STEP 1: IDENTIFY UNUSED INDEXES
-- ==============================================================================

-- Find indexes that have never been used
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan AS times_scanned,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_get_indexdef(indexrelid) AS index_definition
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND schemaname = 'public'
    AND indexrelid NOT IN (
        -- Exclude indexes used for constraints (primary keys, unique)
        SELECT indexrelid 
        FROM pg_index 
        WHERE indisprimary OR indisunique
    )
ORDER BY pg_relation_size(indexrelid) DESC;

-- Calculate total wasted space
SELECT
    COUNT(*) AS unused_index_count,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS total_wasted_space
FROM pg_stat_user_indexes
WHERE idx_scan = 0
    AND schemaname = 'public'
    AND indexrelid NOT IN (
        SELECT indexrelid FROM pg_index WHERE indisprimary OR indisunique
    );

-- ==============================================================================
-- STEP 2: VERIFY INDEXES ARE SAFE TO DROP
-- ==============================================================================

-- Check if index is used for foreign key constraint
SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    rel.relname AS table_name,
    idx.indexrelid::regclass AS index_name
FROM pg_constraint con
JOIN pg_class rel ON con.conrelid = rel.oid
JOIN pg_index idx ON con.conindid = idx.indexrelid
WHERE rel.relname = 'your_table_name'
AND con.contype = 'f';  -- Foreign key

-- Check index definition to understand what it does
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'your_table_name'
AND indexname = 'your_index_name';

-- ==============================================================================
-- STEP 3: DROP UNUSED INDEXES (ONE AT A TIME)
-- ==============================================================================

-- TEMPLATE: Replace 'index_name' with actual index name from Step 1
-- Using CONCURRENTLY to avoid locking the table

-- Example 1: Drop unused index
DROP INDEX CONCURRENTLY IF EXISTS idx_user_sessions_ip_address;

-- Example 2: Drop another unused index
DROP INDEX CONCURRENTLY IF EXISTS idx_user_sessions_device_type;

-- Example 3: Drop third unused index
DROP INDEX CONCURRENTLY IF EXISTS idx_user_sessions_country_code;

-- ==============================================================================
-- IMPORTANT NOTES BEFORE DROPPING
-- ==============================================================================

/*
1. ALWAYS use "CONCURRENTLY" to avoid table locks in production
   - Without CONCURRENTLY: Table is locked, writes blocked
   - With CONCURRENTLY: Index drops in background, safe for production

2. DROP INDEX CONCURRENTLY requires:
   - PostgreSQL 9.2 or higher
   - Cannot be run inside a transaction block
   - Takes longer but is production-safe

3. Check for dependencies:
   - Foreign key constraints may require specific indexes
   - Unique constraints create their own indexes (don't drop these)
   - Primary keys create their own indexes (don't drop these)

4. Monitor application after dropping:
   - Watch for slow queries that may have used the index
   - Check error logs for any issues
   - Have rollback plan ready (recreate index if needed)

5. Best practices:
   - Drop one index at a time
   - Monitor for 24-48 hours between drops
   - Keep track of index definitions for easy recreation
   - Test in staging first
*/

-- ==============================================================================
-- STEP 4: VERIFY INDEXES WERE DROPPED
-- ==============================================================================

-- List remaining indexes on table
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size,
    idx_scan
FROM pg_stat_user_indexes
WHERE tablename = 'your_table_name'
ORDER BY indexname;

-- Check total index size reduction
SELECT 
    tablename,
    COUNT(*) AS index_count,
    pg_size_pretty(SUM(pg_relation_size(indexrelid))) AS total_index_size
FROM pg_stat_user_indexes
WHERE tablename = 'your_table_name'
GROUP BY tablename;

-- ==============================================================================
-- STEP 5: SAVE INDEX DEFINITIONS (FOR ROLLBACK IF NEEDED)
-- ==============================================================================

-- Save index definitions before dropping (just in case)
SELECT 
    indexname,
    pg_get_indexdef(indexrelid) AS create_statement
FROM pg_stat_user_indexes
WHERE tablename = 'your_table_name'
AND idx_scan = 0;

-- Example output to save:
-- CREATE INDEX idx_user_sessions_ip_address ON user_sessions USING btree (ip_address)

-- ==============================================================================
-- ROLLBACK PLAN (IF SOMETHING GOES WRONG)
-- ==============================================================================

-- If you need to recreate a dropped index, use the saved definition:
-- CREATE INDEX CONCURRENTLY idx_user_sessions_ip_address 
-- ON user_sessions(ip_address);

-- ==============================================================================
-- MONITORING QUERIES (RUN AFTER DROPPING)
-- ==============================================================================

-- Monitor for slow queries that might have used the dropped index
SELECT 
    LEFT(query, 100) AS query_preview,
    calls,
    mean_exec_time,
    max_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 100  -- Queries slower than 100ms
ORDER BY mean_exec_time DESC
LIMIT 20;

-- Check for sequential scans that increased after dropping index
SELECT
    relname,
    seq_scan,
    idx_scan,
    n_live_tup
FROM pg_stat_user_tables
WHERE relname = 'your_table_name';

-- ==============================================================================
-- EXAMPLE: COMPLETE DROP WORKFLOW
-- ==============================================================================

/*
-- 1. Identify unused index
SELECT indexname, idx_scan, pg_size_pretty(pg_relation_size(indexrelid))
FROM pg_stat_user_indexes
WHERE tablename = 'user_sessions' AND idx_scan = 0;

-- 2. Save definition for rollback
SELECT pg_get_indexdef(indexrelid)
FROM pg_indexes
WHERE indexname = 'idx_user_sessions_ip_address';

-- 3. Drop the index
DROP INDEX CONCURRENTLY idx_user_sessions_ip_address;

-- 4. Monitor for 24 hours
-- Check application logs, slow query log, sequential scans

-- 5. If all good, proceed to next unused index
-- If problems occur, recreate using saved definition
*/

-- ==============================================================================
-- SAFETY CHECKLIST
-- ==============================================================================

/*
Before dropping any index, verify:

[ ] Index has idx_scan = 0 (never used)
[ ] Index has been monitored for at least 30 days
[ ] Index is not a primary key or unique constraint
[ ] Index is not supporting a foreign key
[ ] Index definition is saved for rollback
[ ] Tested in staging environment
[ ] Application code doesn't explicitly reference this index
[ ] Monitoring is in place to detect issues
[ ] Team is aware of the change
[ ] Rollback plan is documented

If all boxes checked, proceed with DROP INDEX CONCURRENTLY
*/