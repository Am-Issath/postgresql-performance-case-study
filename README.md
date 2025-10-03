# PostgreSQL Performance Case Study: 929 Billion Rows Scanned

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-blue.svg)](https://www.postgresql.org/)

> A real-world production case study of diagnosing and fixing PostgreSQL performance issues that caused 60-second query timeouts.

## 📖 Overview

This repository contains SQL scripts, diagnostic tools, and documentation from a real production incident where two query patterns consumed 99% of database execution time, causing system-wide performance degradation.

**Key Metrics:**
- Query time improvement: 52,847ms → 1.2ms (99.998% faster)
- Sequential scans eliminated: 213,847 per day → 12 per day
- Business impact: Checkout completion rate increased from 64% to 96%

**Read the full article:** [929 Billion Rows Scanned: How We Killed Our Database Performance](link-to-medium-article)

## 🎯 What You'll Learn

- How to systematically diagnose PostgreSQL performance problems using `pg_stat_statements`
- Identifying missing indexes through query pattern analysis
- Understanding table bloat and dead tuples
- Strategic index creation in production without downtime
- Ongoing database maintenance best practices
- Real-world trade-offs and decision-making under pressure

## 🚀 Quick Start

### Prerequisites

- PostgreSQL 12 or higher
- `pg_stat_statements` extension enabled
- Superuser or database owner privileges

### Enable Query Monitoring

```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Reset statistics (optional)
SELECT pg_stat_statements_reset();
```

### Run Diagnostics

```sql
-- Find your slowest queries
\i sql/01-diagnostics/find-slow-queries.sql

-- Check for table bloat
\i sql/01-diagnostics/check-table-bloat.sql

-- Analyze sequential scan patterns
\i sql/01-diagnostics/analyze-sequential-scans.sql
```

## 📂 Repository Contents

### `/sql` - Production SQL Scripts

- **01-diagnostics/** - Query analysis and performance diagnostics
- **02-maintenance/** - Cleanup and optimization scripts
- **03-indexes/** - Index creation and management
- **04-monitoring/** - Ongoing health checks and alerts

### `/examples` - Reproducible Test Environment

- Sample schema matching the case study
- Test data generation scripts
- Scripts to simulate the performance problem

### `/docs` - Detailed Guides

- Diagnostic methodology
- Index design principles
- Maintenance scheduling templates

### `/article` - Full Medium Article

The complete article in Markdown format with all sections.

## 🔍 The Problem

Our `user_sessions` table with 2.1 million rows was experiencing:

- **Query Pattern 1:** COUNT queries averaging 45.9ms, spiking to 58 seconds
  - 18,450 calls consuming 847 seconds (14 minutes) of total database time
  
- **Query Pattern 2:** SELECT with ORDER BY averaging 45.5ms, spiking to 57 seconds
  - 11,280 calls consuming 512 seconds (8.5 minutes) of total database time

**Root causes identified:**
1. Missing indexes on `session_token` column
2. 32% table bloat from dead tuples
3. 2.2 GB of unused indexes consuming resources
4. Under-tuned autovacuum settings

## ✅ The Solution

### 1. Drop Unused Indexes
```sql
DROP INDEX CONCURRENTLY idx_user_sessions_ip_address;     -- 892 MB
DROP INDEX CONCURRENTLY idx_user_sessions_device_type;    -- 743 MB
DROP INDEX CONCURRENTLY idx_user_sessions_country_code;   -- 621 MB
```

### 2. Create Strategic Partial Index
```sql
CREATE INDEX CONCURRENTLY idx_user_sessions_token_active
ON user_sessions(session_token, is_active)
WHERE is_active = true;
```

### 3. Tune Autovacuum
```sql
ALTER TABLE user_sessions SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_vacuum_threshold = 1000
);
```

## 📊 Results

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Avg Query Time | 52,847ms | 1.2ms | 99.998% |
| P99 Query Time | 60,903ms | 4.8ms | 99.992% |
| Timeout Errors | 847/hour | 0 | 100% |
| Sequential Scans | 8,900/hour | 12/hour | 99.87% |
| Dead Tuples | 32% | 5% | 84% reduction |

## 🛠️ Use These Scripts in Your Environment

All SQL scripts are parameterized and include:
- Safety checks to prevent accidental data loss
- Comments explaining each step
- Expected output examples
- Rollback procedures where applicable

### Example: Finding Your Slowest Queries

```bash
psql -d your_database -f sql/01-diagnostics/find-slow-queries.sql
```

## 📚 Documentation

- [Diagnostic Guide](docs/diagnostic-guide.md) - Step-by-step troubleshooting methodology
- [Index Strategy](docs/index-strategy.md) - When and how to create indexes
- [Maintenance Schedule](docs/maintenance-schedule.md) - Monthly checklist

## 🤝 Contributing

Found this helpful? Have suggestions or improvements? Contributions welcome!

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## ⚠️ Important Notes

- **Test in non-production first:** These scripts can cause downtime if used incorrectly
- **Backup before maintenance:** Always have a recent backup before running maintenance operations
- **Monitor during changes:** Use `pg_stat_activity` to monitor long-running operations
- **Read comments carefully:** Each script includes safety warnings and context

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details

## 🔗 Related Resources

- [PostgreSQL Documentation - Indexes](https://www.postgresql.org/docs/current/indexes.html)
- [pg_stat_statements Documentation](https://www.postgresql.org/docs/current/pgstatstatements.html)
- [Understanding VACUUM](https://www.postgresql.org/docs/current/routine-vacuuming.html)

## 📬 Contact

Questions or feedback? Open an issue or reach out on [Twitter/LinkedIn/etc].

---

**⭐ If this helped you solve a production issue, please star the repo!**
