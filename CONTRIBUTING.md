# Contributing to PostgreSQL Performance Case Study

Thank you for your interest in contributing to this project! This repository documents real-world PostgreSQL performance optimization experiences to help others facing similar challenges.

---

## How You Can Contribute

### 1. Share Your Experience

Have a similar PostgreSQL performance story? We'd love to hear it!

**To add your case study:**

1. Fork the repository
2. Create a new branch: `git checkout -b case-study/your-scenario-name`
3. Add your case study following the existing format
4. Include:
   - Problem description with metrics
   - Diagnostic process
   - Root cause analysis
   - Solutions implemented
   - Results with before/after data
5. Submit a Pull Request

**Example structure:**

```markdown
# Case Study: [Your Title]

## Problem

- Symptoms observed
- Business impact
- Key metrics

## Diagnosis

- Queries used
- Findings

## Solution

- What you did
- Why you did it

## Results

- Performance improvements
- Lessons learned
```

---

### 2. Improve SQL Queries

Found a better diagnostic query or more efficient solution?

**To contribute queries:**

1. Test your query thoroughly on PostgreSQL 12+
2. Document what it does and when to use it
3. Include example output
4. Explain advantages over existing approaches
5. Submit a PR with:
   - The query file in appropriate directory
   - Comments explaining parameters
   - Before/after examples if relevant

**Example:**

```sql
-- Better way to find table bloat
-- Advantage: More accurate than count-based methods
-- Works on PostgreSQL 9.4+
SELECT ...
```

---

### 3. Report Issues

Found an error or have a question?

**Open an issue for:**

- Errors in SQL syntax
- Incorrect explanations or concepts
- Broken links or formatting
- Requests for clarification
- Feature suggestions

**Good issue example:**

```
Title: Query in 02-slowest-queries.sql fails on PostgreSQL 11

Description:
The query on line 15 uses a function only available in PostgreSQL 12+.
Error message: function pg_stat_statements_info() does not exist

Suggested fix: Add version check or provide alternative for PostgreSQL 11
```

---

### 4. Improve Documentation

Help make the documentation clearer and more useful!

**Documentation contributions:**

- Fix typos or grammatical errors
- Clarify confusing explanations
- Add more examples
- Improve formatting
- Translate to other languages (future)

---

### 5. Add Tools or Scripts

Have a useful script for PostgreSQL monitoring or optimization?

**To contribute tools:**

1. Ensure it's well-documented
2. Include usage examples
3. Specify dependencies
4. Add it to appropriate section
5. Update relevant README

---

## Contribution Guidelines

### SQL Query Standards

**Format:**

```sql
-- Clear description of what query does
-- When to use it
-- Expected output format

SELECT
    column1,
    column2,
    ROUND(calculation, 2) AS readable_name
FROM table_name
WHERE condition = true
ORDER BY column1 DESC
LIMIT 20;

-- Explanation of results
-- How to interpret the output
```

**Requirements:**

- PostgreSQL 12+ compatible (note if requires newer version)
- Include comments explaining logic
- Use readable column aliases
- Format consistently (2-space indentation)
- Test on sample data before submitting
- No hardcoded values without explanation

**Safety:**

- Use `CONCURRENTLY` for production-impacting operations
- Include warnings for destructive operations
- Provide rollback procedures where applicable
- Note any locks or performance impacts

---

### Documentation Standards

**Writing style:**

- Clear and concise
- Avoid jargon (or explain it)
- Include real-world examples
- Provide context for decisions
- Use code blocks for commands
- Format consistently with existing docs

**Structure:**

- Use descriptive headers
- Include table of contents for long docs
- Add links to related sections
- Provide "Quick Start" where appropriate

---

### Code Style

**SQL:**

```sql
-- Good
SELECT
    user_id,
    COUNT(*) AS total_orders,
    SUM(amount) AS total_amount
FROM orders
WHERE created_at >= '2024-01-01'
GROUP BY user_id
ORDER BY total_amount DESC;

-- Avoid
SELECT user_id,COUNT(*) total_orders,SUM(amount) total_amount FROM orders WHERE created_at>='2024-01-01' GROUP BY user_id ORDER BY total_amount DESC;
```

**Markdown:**

- Use ATX-style headers (`#` not underlines)
- Fence code blocks with language specifier
- Use tables for structured data
- Include alt text for images

---

## What We're Looking For

### High Priority

- Additional diagnostic queries for common scenarios
- Alternative optimization strategies
- Monitoring and alerting scripts
- Real-world performance case studies
- PostgreSQL best practices
- Troubleshooting guides for specific scenarios

### Examples

**Good contributions:**

- "Added query to detect index bloat with percentage calculation"
- "Case study: Optimizing e-commerce checkout flow (99% improvement)"
- "Script to automate monthly index usage audit"
- "Guide for debugging replication lag issues"

**Not suitable:**

- "General database tips" (not PostgreSQL-specific)
- "Here's my company's entire database schema" (too specific)
- Promotional content for products/services
- Theoretical discussions without practical applications

---

## What We're NOT Looking For

- Content unrelated to PostgreSQL performance
- Database-agnostic advice (unless clearly marked as such)
- Promotional or marketing content
- Duplicate content already covered
- Unrelated database technologies (MySQL, MongoDB, etc.)
- Theoretical discussions without practical examples
- Solutions without explanation of why they work

---

## Pull Request Process

### 1. Fork the repository

```bash
git clone https://github.com/your-username/postgres-performance-case-study.git
cd postgres-performance-case-study
```

### 2. Create a branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-fix-name
```

### 3. Make your changes

- Follow the style guides above
- Test SQL queries
- Update documentation if needed

### 4. Commit with clear messages

```bash
git add .
git commit -m "Add query to detect foreign key without indexes"
```

### 5. Push to your fork

```bash
git push origin feature/your-feature-name
```

### 6. Submit Pull Request

- Provide clear description of changes
- Reference related issues if applicable
- Include before/after examples if relevant

---

## PR Template

```markdown
## Description

Brief description of what this PR does

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Case study
- [ ] Query improvement

## Testing

How was this tested?

## Checklist

- [ ] Code follows project style guidelines
- [ ] SQL tested on PostgreSQL 12+
- [ ] Documentation updated if needed
- [ ] No breaking changes
- [ ] Commit messages are clear
```

---

## Code Review Process

All submissions require review:

1. Maintainer will review within 1 week
2. May request changes or clarifications
3. Once approved, will be merged
4. You'll be credited in release notes

**Review criteria:**

- Correctness and accuracy
- Code quality and style
- Documentation completeness
- Usefulness to community
- No security issues

---

## Community Guidelines

### Be Respectful

- Treat all contributors with respect
- Provide constructive feedback
- Welcome newcomers
- No harassment or discrimination

### Be Collaborative

- Share knowledge openly
- Give credit where due
- Help others learn
- Ask questions when unclear

### Be Professional

- Stay on topic
- No spam or self-promotion
- Respect intellectual property
- Follow the code of conduct

---

## Questions?

Not sure about something? Have questions before contributing?

- **Open a Discussion:** For general questions or ideas
- **Open an Issue:** For specific bugs or feature requests
- **Contact:** [your-email@example.com] for sensitive matters

---

## Recognition

All contributors will be:

- Listed in CONTRIBUTORS.md
- Credited in release notes
- Mentioned in related documentation

Significant contributions may result in:

- Co-author recognition
- Maintainer status invitation
- Featured in blog posts or articles

---

## License

By contributing to this repository, you agree that your contributions will be licensed under the MIT License. See [LICENSE](LICENSE) file for details.

---

## Getting Started Checklist

Ready to contribute? Follow this checklist:

- [ ] Read this CONTRIBUTING guide
- [ ] Review existing issues and PRs
- [ ] Fork the repository
- [ ] Set up local development environment
- [ ] Make your changes
- [ ] Test thoroughly
- [ ] Submit Pull Request
- [ ] Respond to review feedback

---

**Thank you for contributing to make PostgreSQL performance optimization more accessible to everyone!**
