-- =============================================================
-- Script  : 06_ranking_analysis.sql
-- Purpose : Rank items based on performance metrics.
--           Identify top performers and laggards across
--           customers, branches, and products.
-- SQL Functions Used: RANK(), DENSE_RANK(), ROW_NUMBER(), TOP
--                     GROUP BY, ORDER BY
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. TOP 10 customers by total transaction volume
--    Simple TOP approach — quick executive view
-- -------------------------------------------------------------

SELECT TOP 10
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    branch                              AS [Branch],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY customer_id, segment, branch
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 2. Customer ranking using RANK() and DENSE_RANK()
--    RANK()       — leaves gaps after ties (1,2,2,4)
--    DENSE_RANK() — no gaps after ties    (1,2,2,3)
--    ROW_NUMBER() — unique row always     (1,2,3,4)
-- -------------------------------------------------------------

SELECT
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    total_volume,
    RANK()       OVER (ORDER BY total_volume DESC) AS [Rank],
    DENSE_RANK() OVER (ORDER BY total_volume DESC) AS [Dense Rank],
    ROW_NUMBER() OVER (ORDER BY total_volume DESC) AS [Row Number]
FROM (
    SELECT
        customer_id,
        segment,
        SUM(amount) AS total_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY customer_id, segment
) AS cust_vol
ORDER BY [Rank];


-- -------------------------------------------------------------
-- 3. Rank customers WITHIN each segment
--    Who is the top customer in Retail? In SME? In Wealth?
-- -------------------------------------------------------------

SELECT
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    total_volume                        AS [Total Volume (RM)],
    txn_count                           AS [Transactions],
    RANK() OVER (
        PARTITION BY segment
        ORDER BY total_volume DESC
    )                                   AS [Rank Within Segment]
FROM (
    SELECT
        customer_id,
        segment,
        SUM(amount) AS total_volume,
        COUNT(*)    AS txn_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY customer_id, segment
) AS cust_vol
ORDER BY segment, [Rank Within Segment];


-- -------------------------------------------------------------
-- 4. Branch ranking by total volume
-- -------------------------------------------------------------

SELECT
    branch                              AS [Branch],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)],
    RANK()       OVER (ORDER BY SUM(amount) DESC) AS [Volume Rank],
    RANK()       OVER (ORDER BY COUNT(*) DESC)    AS [Count Rank]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch
ORDER BY [Volume Rank];


-- -------------------------------------------------------------
-- 5. Product ranking by volume and transaction count
-- -------------------------------------------------------------

SELECT
    product                             AS [Product],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)],
    DENSE_RANK() OVER (ORDER BY SUM(amount) DESC) AS [Volume Rank],
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC)    AS [Popularity Rank]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY product
ORDER BY [Volume Rank];


-- -------------------------------------------------------------
-- 6. Top 5 customers per branch using ROW_NUMBER()
--    Identify the most valuable customer in each branch
-- -------------------------------------------------------------

SELECT
    branch                              AS [Branch],
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    total_volume                        AS [Total Volume (RM)],
    branch_rank                         AS [Rank in Branch]
FROM (
    SELECT
        branch,
        customer_id,
        segment,
        SUM(amount) AS total_volume,
        ROW_NUMBER() OVER (
            PARTITION BY branch
            ORDER BY SUM(amount) DESC
        ) AS branch_rank
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY branch, customer_id, segment
) AS ranked
WHERE branch_rank <= 5
ORDER BY branch, branch_rank;


-- -------------------------------------------------------------
-- 7. Bottom 10 customers by volume — identify laggards
-- -------------------------------------------------------------

SELECT TOP 10
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    branch                              AS [Branch],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY customer_id, segment, branch
ORDER BY SUM(amount) ASC;


-- -------------------------------------------------------------
-- 8. Transaction type ranking within each branch
--    What is the #1 transaction type in each branch?
-- -------------------------------------------------------------

SELECT
    branch                              AS [Branch],
    transaction_type                    AS [Transaction Type],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    RANK() OVER (
        PARTITION BY branch
        ORDER BY SUM(amount) DESC
    )                                   AS [Rank in Branch]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch, transaction_type
ORDER BY branch, [Rank in Branch];
