-- Create Strategic Indexes for Performance
-- Based on actual query patterns from pg_stat_statements
-- Always customize these for YOUR specific use case

-- ==============================================================================
-- PREPARATION
-- ==============================================================================

-- Set appropriate parameters for index creation
SET maintenance_work_mem = '2GB';  -- Use more memory for faster builds
SET statement_timeout = 0;          -- Disable timeout for long index creation

-- Verify settings
SHOW maintenance_work_mem;
SHOW statement_timeout;

-- ==============================================================================
-- ANALYZE YOUR QUERIES FIRST
-- ==============================================================================

-- Find your slowest queries
SELECT 
    LEFT(query, 150) AS query_preview,
    calls,
    ROUND(mean_exec_time::numeric, 2) AS avg_ms,
    ROUND(total_exec_time::numeric, 2) AS total_ms
FROM pg_stat_statements
WHERE mean_exec_time > 100
ORDER BY total_exec_time DESC
LIMIT 10;

-- Identify columns in WHERE clauses
-- Look at the output above and note which columns appear in WHERE, JOIN, ORDER BY

-- ==============================================================================
-- STRATEGY 1: PARTIAL INDEXES FOR FILTERED QUERIES
-- ==============================================================================

-- Use Case: Most queries filter for active/enabled records only
-- Example: 80% of queries have "WHERE is_active = true"

-- Before (full index - indexes ALL rows):
-- CREATE INDEX idx_user_sessions_token ON user_sessions(session_token);
-- Size: 1.2 GB, includes inactive sessions that are rarely queried

-- After (partial index - indexes only what you query):
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_token_active
ON user_sessions(session_token, is_active)
WHERE is_active = true;
-- Size: ~400 MB (67% smaller), only indexes active sessions

-- Benefits:
-- - 60-80% smaller index size
-- - Faster to scan (fewer entries)
-- - Lower maintenance overhead (only updates when active)
-- - Better cache hit ratio

-- Verify it will be used:
EXPLAIN ANALYZE
SELECT * FROM user_sessions 
WHERE session_token = 'test123' 
AND is_active = true;
-- Look for: "Index Scan using idx_user_sessions_token_active"

-- ==============================================================================
-- STRATEGY 2: COMPOSITE INDEXES FOR MULTI-COLUMN FILTERS
-- ==============================================================================

-- Use Case: Queries that filter on multiple columns together
-- Example: "WHERE status = 'active' AND created_at > '2024-01-01'"

-- Wrong way (two separate indexes):
-- CREATE INDEX idx_status ON orders(status);
-- CREATE INDEX idx_created ON orders(created_at);
-- PostgreSQL can only use one efficiently

-- Right way (composite index):
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_status_created
ON orders(status, created_at)
WHERE status IN ('active', 'pending');  -- Partial for extra efficiency
-- Column order matters: most selective first (status), then created_at

-- Verify column order with selectivity check:
SELECT 
    COUNT(DISTINCT status) AS status_cardinality,
    COUNT(DISTINCT created_at) AS date_cardinality,
    COUNT(*) AS total_rows
FROM orders;
-- Higher cardinality = more selective = should be first

-- Test the index:
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE status = 'active' 
AND created_at >= NOW() - interval '7 days';
-- Look for: "Index Scan using idx_orders_status_created"

-- ==============================================================================
-- STRATEGY 3: INDEXES FOR ORDER BY QUERIES
-- ==============================================================================

-- Use Case: Queries that filter AND sort
-- Example: "WHERE user_id = ? ORDER BY created_at DESC LIMIT 10"

-- The index needs to match the query pattern exactly:
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orders_user_created_desc
ON orders(user_id, created_at DESC);
-- Note: DESC matters! It must match your ORDER BY

-- This enables sorted access without an additional sort step
EXPLAIN ANALYZE
SELECT * FROM orders 
WHERE user_id = 12345 
ORDER BY created_at DESC 
LIMIT 10;
-- Look for: "Index Scan" without "Sort" step

-- ==============================================================================
-- STRATEGY 4: COVERING INDEXES (INDEX-ONLY SCANS)
-- ==============================================================================

-- Use Case: Query needs specific columns, but filters on different column
-- Example: "SELECT id, email, status WHERE session_token = ?"

-- Basic index (requires table lookup):
-- CREATE INDEX idx_token ON users(session_token);
-- Still needs to fetch id, email, status from table

-- Covering index (no table lookup needed):
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_token_covering
ON users(session_token) 
INCLUDE (id, email, status)
WHERE is_deleted = false;
-- INCLUDE clause adds columns without affecting index order

-- Alternative for older PostgreSQL (< 11):
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_users_token_covering_old
ON users(session_token, id, email, status)
WHERE is_deleted = false;

-- Test for "Index Only Scan":
EXPLAIN ANALYZE
SELECT id, email, status FROM users 
WHERE session_token = 'abc123' 
AND is_deleted = false;
-- Look for: "Index Only Scan" + "Heap Fetches: 0"

-- ==============================================================================
-- REAL EXAMPLE: USER SESSION AUTHENTICATION
-- ==============================================================================

-- Problem Query (taking 45 seconds):
-- SELECT COUNT(*) FROM user_sessions 
-- WHERE is_active = true 
-- AND session_token = '...' 
-- AND user_id != ?

-- Analysis:
-- - 2.1M total rows
-- - 89% have is_active = true
-- - session_token is unique
-- - Called 18,450 times/day

-- Solution: Partial composite index
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_optimal
ON user_sessions(session_token, is_active)
WHERE is_active = true;

-- Why this design:
-- 1. session_token first (most selective - unique values)
-- 2. is_active second (for additional filtering)
-- 3. WHERE clause (only indexes 89% of rows we actually query)
-- 4. user_id NOT in index (NOT inequality, rarely helps)

-- Result: 45 seconds → 1.2 milliseconds

-- ==============================================================================
-- REAL EXAMPLE: ORDERED PAGINATION
-- ==============================================================================

-- Problem Query (taking 43 seconds):
-- SELECT * FROM user_sessions
-- WHERE is_active = true
-- AND session_token = '...'
-- ORDER BY last_accessed ASC
-- LIMIT 1

-- Solution: Index matching filter + sort order
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_sorted
ON user_sessions(session_token, last_accessed ASC)
WHERE is_active = true;

-- Why this design:
-- 1. session_token for filtering
-- 2. last_accessed with ASC for pre-sorted results
-- 3. WHERE clause for partial index efficiency
-- 4. Eliminates sort step entirely

-- Result: 43 seconds → 1.4 milliseconds

-- ==============================================================================
-- MONITORING INDEX CREATION PROGRESS
-- ==============================================================================

-- In a SEPARATE terminal/connection, monitor progress:
SELECT 
    now()::time AS current_time,
    pid,
    phase,
    ROUND(100.0 * blocks_done / NULLIF(blocks_total, 0), 2) AS percent_complete,
    blocks_done,
    blocks_total,
    tuples_done,
    tuples_total
FROM pg_stat_progress_create_index;

-- Check active index builds:
SELECT 
    pid,
    now() - query_start AS duration,
    state,
    LEFT(query, 100) AS query
FROM pg_stat_activity
WHERE query LIKE '%CREATE INDEX%';

-- ==============================================================================
-- VERIFY INDEXES WERE CREATED SUCCESSFULLY
-- ==============================================================================

-- Check all indexes on table
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS size,
    pg_get_indexdef(indexrelid) AS definition
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
LEFT JOIN pg_index ON pg_class.oid = pg_index.indexrelid
WHERE tablename = 'your_table_name'
    AND pg_index.indisvalid = true  -- Only valid indexes
ORDER BY indexname;

-- Verify index is valid and ready
SELECT 
    indexname,
    CASE 
        WHEN indisvalid THEN 'Valid ✓'
        ELSE 'Invalid ✗ (needs to be dropped)'
    END AS status
FROM pg_stat_user_indexes
JOIN pg_index ON pg_stat_user_indexes.indexrelid = pg_index.indexrelid
WHERE tablename = 'your_table_name';

-- ==============================================================================
-- TEST INDEX PERFORMANCE
-- ==============================================================================

-- Test with EXPLAIN ANALYZE (doesn't execute, just plans)
EXPLAIN 
SELECT * FROM user_sessions 
WHERE is_active = true 
AND session_token = 'test_token';
-- Should show: "Index Scan using idx_user_sessions_optimal"

-- Test with real execution
EXPLAIN ANALYZE
SELECT * FROM user_sessions 
WHERE is_active = true 
AND session_token = 'test_token';
-- Check "Execution Time" - should be < 10ms

-- Compare before/after
-- Before: "Seq Scan" + "Execution Time: 45000ms"
-- After: "Index Scan" + "Execution Time: 1.2ms"

-- ==============================================================================
-- HANDLING FAILED INDEX CREATION
-- ==============================================================================

-- If CREATE INDEX CONCURRENTLY fails, it leaves an invalid index
-- Find invalid indexes:
SELECT 
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS wasted_space
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
LEFT JOIN pg_index ON pg_class.oid = pg_index.indexrelid
WHERE schemaname = 'public'
AND NOT pg_index.indisvalid;

-- Drop invalid index and try again:
DROP INDEX CONCURRENTLY invalid_index_name;

-- Common reasons for failure:
-- 1. Statement timeout too short
-- 2. Deadlock with other operations
-- 3. Disk full
-- 4. Long-running transactions blocking

-- ==============================================================================
-- MAINTENANCE AFTER CREATION
-- ==============================================================================

-- Analyze table to update statistics
ANALYZE user_sessions;

-- Check index is being used (after 1 week)
SELECT 
    indexname,
    idx_scan AS times_used,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE tablename = 'user_sessions'
ORDER BY idx_scan DESC;

-- If idx_scan = 0 after a week, index may not be needed

-- ==============================================================================
-- ROLLBACK PLAN
-- ==============================================================================

-- If index causes problems, drop it:
DROP INDEX CONCURRENTLY IF EXISTS idx_user_sessions_optimal;

-- Monitor application for 24 hours after dropping

-- ==============================================================================
-- INDEX CREATION CHECKLIST
-- ==============================================================================

/*
Before creating any index:

[ ] Identified slow query from pg_stat_statements
[ ] Query is called frequently (>1000 times/day)
[ ] Query takes >100ms average
[ ] Verified with EXPLAIN that Seq Scan is the problem
[ ] Checked if existing index can be reused
[ ] Determined optimal column order (selectivity analysis)
[ ] Considered partial index with WHERE clause
[ ] Set maintenance_work_mem and statement_timeout
[ ] Planned for index size (20-50% of table size)
[ ] Scheduled during low-traffic window if possible
[ ] Have monitoring in place to verify usage
[ ] Tested in staging environment first
[ ] Team is aware of the deployment

If all checked, proceed with CREATE INDEX CONCURRENTLY
*/

-- ==============================================================================
-- COMMON PITFALLS TO AVOID
-- ==============================================================================

/*
DON'T:
❌ Create index without analyzing query patterns first
❌ Use multiple single-column indexes instead of one composite
❌ Forget the WHERE clause for partial indexes
❌ Put low-selectivity columns first in composite index
❌ Create covering indexes with too many INCLUDE columns
❌ Run CREATE INDEX without CONCURRENTLY in production
❌ Forget to test with EXPLAIN ANALYZE first

DO:
✓ Analyze pg_stat_statements first
✓ Use partial indexes for filtered queries
✓ Put most selective columns first
✓ Use CONCURRENTLY in production
✓ Monitor index usage after creation
✓ Drop unused indexes regularly
✓ Test in staging first
*/