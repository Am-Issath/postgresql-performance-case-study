-- Create Strategic Indexes for Performance
-- Based on actual query patterns from pg_stat_statements

-- IMPORTANT: Adjust these based on YOUR actual query patterns
-- These are examples from the case study

-- Preparation: Set appropriate parameters
SET maintenance_work_mem = '2GB';  -- Use more memory for faster index creation
SET statement_timeout = 0;          -- Disable timeout for index creation

-- Example 1: Partial Index for Active Sessions
-- Use when: You have a boolean flag and mostly query one value
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_token_active
ON user_sessions(session_token, is_active)
WHERE is_active = true;

-- Example 2: Composite Index with Sort Column
-- Use when: Query filters on multiple columns and sorts results
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_token_accessed
ON user_sessions(session_token, last_accessed)
WHERE is_active = true;

-- Example 3: Simple Partial Index for Fast Lookups
-- Use when: Simple equality check with filter condition
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_user_sessions_token_lookup
ON user_sessions(session_token)
WHERE is_active = true;

-- Verify indexes were created successfully
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size,
    pg_get_indexdef(indexrelid) AS definition
FROM pg_indexes
JOIN pg_class ON pg_class.relname = indexname
LEFT JOIN pg_index ON pg_class.oid = pg_index.indexrelid
WHERE tablename = 'user_sessions'
    AND pg_index.indisvalid = true  -- Only show valid indexes
ORDER BY indexname;

-- Test query performance with EXPLAIN ANALYZE
-- Replace with your actual query pattern
EXPLAIN ANALYZE
SELECT COUNT(*) 
FROM user_sessions 
WHERE is_active = true 
    AND session_token = 'test_token_123';

-- IMPLEMENTATION NOTES:
-- 1. Always use CONCURRENTLY to avoid table locks
-- 2. Monitor disk I/O during creation
-- 3. Index creation can take 15-30 minutes on large tables
-- 4. If creation fails, drop the invalid index before retrying
-- 5. Test with EXPLAIN ANALYZE before and after