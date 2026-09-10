<div align="center">

  <h3>AI & Data Science (NLP, ML, Analytics, Data Engineering)</h3>

  <h1><b>Online Retail Database System</b></h1>

</div>

A relational database design and query project for a simulated online retail company, covering schema design, sample data, and a set of advanced SQL queries in MySQL, along with the equivalent formal expressions in Relational Algebra and Tuple Relational Calculus.

## Repository Structure

```text
Online Retail Database System/
├── 1. OnlineRetailDB_schema.sql                      # DDL script for database schema & tables
├── 2. OnlineRetailDB_query_results_screenshots.pdf   # Visual query execution proofs (MySQL Workbench)
├── 3. OnlineRetailDB_formal_language.pdf             # Formal Relational Algebra & Calculus mapping
└── 4. OnlineRetailDB_queries.sql                     # Analytical SQL queries with inline explanations
```

The queries move beyond basic joins and aggregates into recursive CTEs (for modeling a hierarchical product category tree), set-based "for all" logic (customers who ordered every product in a category, products supplied by every regional supplier), and window functions (ranking each customer's top spending category). A few queries required catching and correcting an initial misread of the data –– for example, an early version of the "ordered every Electronics product" query only checked the parent category, but most products actually lived in child categories like Laptops and Smartphones, which required rethinking the query with a recursive category tree instead of a flat match.

The formal language section translates two of the SQL queries into Relational Algebra (including the DIVISION operator) and Tuple Relational Calculus, working through why a plain universal quantifier isn't sufficient for the "all suppliers in a region" case without pairing it with a logical implication.

<sub>[⬅ Back to Main Page](https://github.com/cryp-moh-graphy/ai-ds-portfolio/blob/main/README.md)</sub>
