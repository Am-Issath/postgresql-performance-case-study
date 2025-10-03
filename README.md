# 929 Billion Rows Scanned: PostgreSQL Performance Crisis Case Study

![PostgreSQL Performance](https://img.shields.io/badge/PostgreSQL-14.x-blue.svg)
![Performance](https://img.shields.io/badge/Performance-99.997%25%20Faster-brightgreen.svg)
![ROI](https://img.shields.io/badge/ROI-2281%25-orange.svg)

A real production case study of diagnosing and fixing severe PostgreSQL performance issues where two queries consumed 99% of database resources, causing 60-second timeouts and site-wide failures.

## 📖 Read the Full Article

**[Read on Medium](https://medium.com/@anas-issath/929-billion-rows-scanned-how-we-killed-our-database-performance-81298cde4304)** - Complete write-up with detailed analysis and lessons learned

---

## 🔥 The Crisis

At 3 AM, our e-commerce platform ground to a halt:

- **Query Performance:** 60+ second response times
- **Database Load:** 99% of resources consumed by just 2 query patterns
- **Sequential Scans:** 929 billion rows scanned daily
- **Table Bloat:** 32% dead tuples accumulating
- **Business Impact:** Site-wide timeouts, failed checkouts, angry customers

### The Numbers

| Metric                | Before    | After  | Improvement |
| --------------------- | --------- | ------ | ----------- |
| Avg Query Time        | 45,913 ms | 1.2 ms | 99.997%     |
| Sequential Scans/hour | 8,900     | 12     | 99.87%      |
| Timeout Errors        | 847/hour  | 0      | 100%        |
| Checkout Completion   | 64%       | 96%    | +50%        |

---

## 💡 The Solution

### 1. Dropped Unused Indexes

- Identified 2.2 GB of indexes with zero scans
- Removed write overhead and freed disk space
- Made room for what actually matters

### 2. Created Strategic Partial Indexes

```sql
-- Instead of full index on 2.1M rows
CREATE INDEX CONCURRENTLY idx_user_sessions_token_active
ON user_sessions(session_token, is_active)
WHERE is_active = true;  -- Only indexes 20% of data
```

### 3. Tuned Autovacuum

```sql
ALTER TABLE user_sessions SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_vacuum_threshold = 1000
);
```

### 4. Implemented Monitoring

- Monthly index usage audits
- Dead tuple percentage tracking
- Query performance trending

---

## 📁 Repository Contents

```
📦 postgres-performance-case-study
├── 📄 README.md                    # This file
├── 📄 CONTRIBUTING.md
├── 📂 diagnostic-queries/          # SQL for problem identification
│   ├── 01-enable-pg-stat-statements.sql
│   ├── 02-slowest-queries.sql
│   ├── 03-table-bloat.sql
│   ├── 04-sequential-scans.sql
│   ├── 05-unused-indexes.sql
│   ├── 06-currently-running-queries.sql
│   └── 07-cache-hit-ratio.sql
├── 📂 solutions/                   # Implementation scripts
│   ├── 01-drop-unused-indexes.sql
│   ├── 02-create-strategic-indexes.sql
│   ├── 03-vacuum-and-maintenance.sql
│   └── 04-reindex-for-bloat.sql
├── 📂 monitoring/                  # Ongoing health checks
│   ├── monthly-health-check.sql
│   └── alert-thresholds.sql
├── 📂 benchmarks/                  # Performance data
│   └── before-after-metrics.md
└── 📂 docs/                        # Additional documentation
    ├── index-design-principles.md
```

---

## 🚀 Quick Start

### Prerequisites

- PostgreSQL 12 or higher
- `pg_stat_statements` extension enabled
- Appropriate database privileges (SUPERUSER or database owner)

### Step 1: Enable Query Statistics

```bash
psql -U your_user -d your_database -f diagnostic-queries/01-enable-pg-stat-statements.sql
```

### Step 2: Identify Slow Queries

```bash
psql -U your_user -d your_database -f diagnostic-queries/02-slowest-queries.sql
```

### Step 3: Check Table Health

```bash
# Check for bloat
psql -U your_user -d your_database -f diagnostic-queries/03-table-bloat.sql

# Check for excessive sequential scans
psql -U your_user -d your_database -f diagnostic-queries/04-sequential-scans.sql

# Find unused indexes
psql -U your_user -d your_database -f diagnostic-queries/05-unused-indexes.sql
```

### Step 4: Implement Fixes

```bash
# Review and customize the solution scripts for your environment
# Then execute them one at a time with monitoring

psql -U your_user -d your_database -f solutions/01-drop-unused-indexes.sql
psql -U your_user -d your_database -f solutions/02-create-strategic-indexes.sql
```

---

## 📊 Expected Results

Based on our production experience:

### Query Performance

- 60 seconds → 1.2 milliseconds (99.997% improvement)
- 47,000x speedup on COUNT queries
- 32,000x speedup on SELECT queries

### Resource Utilization

- CPU: 87% → 23% (73.6% reduction)
- I/O Wait: 45% → 8% (82.2% reduction)
- Active Connections: 198 → 34 (82.8% reduction)

### Business Impact

- Checkout completion: 64% → 96%
- Support tickets: 293/day → 4/day
- User satisfaction: 2.1/5 → 4.7/5

---

## 📚 Key Learnings

### 1. Monitor pg_stat_statements Religiously

Early detection prevents crises. The data was there for weeks—we just weren't watching.

### 2. Dead Tuples Are Silent Killers

Table bloat accumulates quietly, making everything slightly slower until you cross a threshold and the system collapses.

### 3. Not All Indexes Are Worth Creating

Every index has a maintenance cost. We planned for three indexes but only created one—and performance was perfect.

### 4. Drop Before You Build

Remove unused indexes before adding new ones. We saved 2.2 GB and reduced write overhead.

### 5. Production Is Different From Theory

Our VACUUM timed out. The "correct" approach failed. Pragmatism over perfection won the day.

---

## 🛠️ Tools Used

- **PostgreSQL Built-in Views:** `pg_stat_statements`, `pg_stat_user_tables`, `pg_stat_user_indexes`
- **EXPLAIN ANALYZE:** Query execution plan analysis
- **pg_stat_activity:** Real-time query monitoring
- **pgAdmin:** Database management and visualization

---

## 📖 Article Sections

The full Medium article covers:

1. **The Crisis Moment** - How a 3 AM alert revealed the problem
2. **The Diagnostic Process** - Systematic troubleshooting with SQL
3. **Understanding Root Causes** - Multiple converging issues
4. **The Counter-Intuitive First Step** - Why we dropped indexes first
5. **Building the Right Indexes** - Strategic design decisions
6. **Implementation Challenges** - Real production constraints and trade-offs
7. **Results and Ongoing Maintenance** - Long-term sustainability

---

## 🎯 Who This Is For

- **Database Administrators** dealing with performance issues
- **Backend Engineers** optimizing PostgreSQL queries
- **DevOps Teams** managing production databases
- **Engineering Managers** understanding database maintenance costs
- **Anyone learning** PostgreSQL performance optimization

---

## 🤝 Contributing

Found this helpful? Have suggestions or similar experiences?

- **Share your story:** Open a discussion with your PostgreSQL performance tale
- **Improve diagnostics:** Submit better queries or techniques
- **Add examples:** Real-world case studies welcome
- **Fix errors:** Found a bug in the SQL? Open an issue or PR

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📈 Performance Benchmarks

Detailed before/after metrics available in [benchmarks/before-after-metrics.md](benchmarks/before-after-metrics.md):

- Complete execution time comparisons
- Resource utilization graphs
- Cost-benefit analysis (2,281% ROI)
- 6-month performance trends
- Query execution plan analysis

---

## 📝 Additional Documentation

### Index Design Guide

[docs/index-design-principles.md](docs/index-design-principles.md)

- When to create indexes (and when not to)
- B-tree, partial, composite, and covering indexes
- Common mistakes and how to avoid them
- Real-world examples with benchmarks

### Troubleshooting Guide

[docs/troubleshooting-guide.md](docs/troubleshooting-guide.md)

- Diagnostic flowchart for common issues
- Emergency procedures for production
- Prevention checklist (daily/weekly/monthly)
- Tools and monitoring recommendations

---

## ⚠️ Important Notes

### Use CONCURRENTLY in Production

```sql
-- Safe: Doesn't lock table
CREATE INDEX CONCURRENTLY idx_name ON table(column);

-- Dangerous: Locks table for writes
CREATE INDEX idx_name ON table(column);
```

### Test in Staging First

- Verify index effectiveness with `EXPLAIN ANALYZE`
- Monitor resource usage during creation
- Have a rollback plan

### Monitor After Implementation

```sql
-- Check if index is being used (after 1 week)
SELECT idx_scan FROM pg_stat_user_indexes
WHERE indexname = 'your_new_index';

-- If idx_scan = 0, consider dropping it
```

---

## 💰 ROI Analysis

Based on our real production numbers:

| Category                 | Annual Impact |
| ------------------------ | ------------- |
| Reduced server costs     | $18,000       |
| Support burden reduction | $32,000       |
| Improved conversion rate | $340,000      |
| Reduced hosting costs    | $12,000       |
| **Total Annual Benefit** | **$406,000**  |
| **Implementation Cost**  | **$8,050**    |
| **ROI**                  | **2,281%**    |
| **Payback Period**       | **15.3 days** |

---

## 🌟 Star History

If you found this repository helpful:

- ⭐ Star this repo to bookmark it
- 🔄 Share with colleagues facing similar issues
- 💬 Open discussions to share your experience
- 🐛 Report issues to help improve the content

---

## 📬 Contact & Support

**Questions?** Open a [GitHub Issue](https://github.com/Am-Issath/postgresql-performance-case-study/issues)

**Connect with me:**

- Medium: [@anas-issath](https://medium.com/@anas-issath)
- LinkedIn: [Mohamed Issath](https://www.linkedin.com/in/mohamed-issath-424b85168/)

---

## 🙏 Acknowledgments

- PostgreSQL community for excellent documentation
- The team that worked through the 3 AM crisis with me
- Everyone who reviewed and improved these diagnostic queries
- [Use The Index, Luke!](https://use-the-index-luke.com/) for indexing insights

---

## 📌 Related Resources

- [PostgreSQL Documentation - Performance Tips](https://www.postgresql.org/docs/current/performance-tips.html)
- [PostgreSQL Wiki - Performance Optimization](https://wiki.postgresql.org/wiki/Performance_Optimization)
- [PGTune - PostgreSQL Configuration Wizard](https://pgtune.leopard.in.ua/)
- [Explain.depesz.com - Query Plan Analyzer](https://explain.depesz.com/)

---

<div align="center">

## ⚡ From 60 seconds to 1.2 milliseconds

## 🎯 99.997% performance improvement

## 💡 One strategic index changed everything

---

_This case study uses anonymized production data. Specific table names, query patterns, and business context have been modified for privacy while maintaining technical accuracy._

**Last Updated:** October 2025

</div>
