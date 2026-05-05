-- =============================================================
-- Script  : 02_dimensions_exploration.sql
-- Purpose : Explore all dimension tables to understand the
--           unique values, categories, and lookup data available
--           for analysis and filtering.
-- SQL Functions Used: DISTINCT, ORDER BY
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. DIM_CUSTOMERS — Unique customer segments
-- -------------------------------------------------------------

-- What customer segments exist?
SELECT DISTINCT
    segment                 AS [Customer Segment]
FROM bank.dim_customers
ORDER BY segment;


-- Which branches are customers distributed across?
SELECT DISTINCT
    branch                  AS [Branch]
FROM bank.dim_customers
ORDER BY branch;


-- Unique combinations of segment and branch
SELECT DISTINCT
    segment                 AS [Segment],
    branch                  AS [Branch]
FROM bank.dim_customers
ORDER BY segment, branch;


-- -------------------------------------------------------------
-- 2. FACT_TRANSACTIONS — Unique dimension values
-- -------------------------------------------------------------

-- What transaction types exist?
SELECT DISTINCT
    transaction_type        AS [Transaction Type]
FROM bank.fact_transactions
ORDER BY transaction_type;


-- What products are recorded in transactions?
SELECT DISTINCT
    product                 AS [Product]
FROM bank.fact_transactions
ORDER BY product;


-- What categories exist per transaction type?
SELECT DISTINCT
    transaction_type        AS [Transaction Type],
    category                AS [Category]
FROM bank.fact_transactions
ORDER BY transaction_type, category;


-- What statuses are used?
SELECT DISTINCT
    [status]                AS [Status]
FROM bank.fact_transactions
ORDER BY [status];


-- What branches appear in transactions?
SELECT DISTINCT
    branch                  AS [Branch]
FROM bank.fact_transactions
ORDER BY branch;


-- -------------------------------------------------------------
-- 3. Full distinct lookup — all dimension values at a glance
-- -------------------------------------------------------------

-- Combined view: all unique segments, branches, products, types
SELECT DISTINCT
    f.segment               AS [Segment],
    f.branch                AS [Branch],
    f.product               AS [Product],
    f.transaction_type      AS [Transaction Type]
FROM bank.fact_transactions f
ORDER BY
    f.segment,
    f.branch,
    f.product,
    f.transaction_type;
