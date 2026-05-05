-- =============================================================
-- Script  : 05_magnitude_analysis.sql
-- Purpose : Quantify data and group results by specific
--           dimensions. Understand data distribution and volume
--           across categories like branch, segment, product,
--           transaction type.
-- SQL Functions Used: SUM(), COUNT(), AVG(), GROUP BY, ORDER BY
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Total transaction volume and count by branch
--    Which branch is moving the most money?
-- -------------------------------------------------------------

SELECT
    branch                                      AS [Branch],
    COUNT(*)                                    AS [Total Transactions],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)],
    SUM(amount) / SUM(SUM(amount)) OVER ()* 100 AS [Volume Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 2. Total volume and count by customer segment
--    Where is the bulk of banking activity concentrated?
-- -------------------------------------------------------------

SELECT
    segment                                     AS [Segment],
    COUNT(*)                                    AS [Total Transactions],
    COUNT(DISTINCT customer_id)                 AS [Unique Customers],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)],
    SUM(amount) / SUM(SUM(amount)) OVER ()* 100 AS [Volume Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 3. Total volume and count by product
--    Which banking products drive the most transaction value?
-- -------------------------------------------------------------

SELECT
    product                                     AS [Product],
    COUNT(*)                                    AS [Total Transactions],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)],
    MIN(amount)                                 AS [Min (RM)],
    MAX(amount)                                 AS [Max (RM)],
    SUM(amount) / SUM(SUM(amount)) OVER ()* 100 AS [Volume Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY product
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 4. Total volume and count by transaction type
--    Are customers mostly depositing, withdrawing, or paying?
-- -------------------------------------------------------------

SELECT
    transaction_type                            AS [Transaction Type],
    COUNT(*)                                    AS [Total Transactions],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)],
    SUM(amount) / SUM(SUM(amount)) OVER ()* 100 AS [Volume Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY transaction_type
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 5. Volume distribution by segment AND branch
--    Two-dimensional view — which segment dominates each branch?
-- -------------------------------------------------------------

SELECT
    segment                                     AS [Segment],
    branch                                      AS [Branch],
    COUNT(*)                                    AS [Transactions],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment, branch
ORDER BY segment, SUM(amount) DESC;


-- -------------------------------------------------------------
-- 6. Volume distribution by segment AND product
--    What products do Retail vs SME vs Wealth prefer?
-- -------------------------------------------------------------

SELECT
    segment                                     AS [Segment],
    product                                     AS [Product],
    COUNT(*)                                    AS [Transactions],
    SUM(amount)                                 AS [Total Volume (RM)],
    AVG(amount)                                 AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment, product
ORDER BY segment, SUM(amount) DESC;


-- -------------------------------------------------------------
-- 7. Transaction size buckets — distribution across amount bands
--    Understand if most transactions are small or large
-- -------------------------------------------------------------

SELECT
    CASE
        WHEN amount <  1000            THEN '1. Below RM 1,000'
        WHEN amount <  10000           THEN '2. RM 1,000 – 9,999'
        WHEN amount <  50000           THEN '3. RM 10,000 – 49,999'
        WHEN amount <  100000          THEN '4. RM 50,000 – 99,999'
        ELSE                                '5. RM 100,000 and above'
    END                                     AS [Amount Band],
    COUNT(*)                                AS [Transaction Count],
    SUM(amount)                             AS [Total Volume (RM)],
    AVG(amount)                             AS [Avg Amount (RM)],
    COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS [Count Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    CASE
        WHEN amount <  1000            THEN '1. Below RM 1,000'
        WHEN amount <  10000           THEN '2. RM 1,000 – 9,999'
        WHEN amount <  50000           THEN '3. RM 10,000 – 49,999'
        WHEN amount <  100000          THEN '4. RM 50,000 – 99,999'
        ELSE                                '5. RM 100,000 and above'
    END
ORDER BY [Amount Band];


-- -------------------------------------------------------------
-- 8. Customer activity magnitude — how active are customers?
--    Group customers by number of transactions they've made
-- -------------------------------------------------------------

SELECT
    CASE
        WHEN txn_count = 1          THEN '1 Transaction'
        WHEN txn_count BETWEEN 2 AND 5  THEN '2–5 Transactions'
        WHEN txn_count BETWEEN 6 AND 10 THEN '6–10 Transactions'
        WHEN txn_count BETWEEN 11 AND 20 THEN '11–20 Transactions'
        ELSE '20+ Transactions'
    END                                     AS [Activity Band],
    COUNT(*)                                AS [Customer Count],
    AVG(CAST(txn_count AS FLOAT))           AS [Avg Transactions],
    SUM(total_volume)                       AS [Group Total Volume (RM)],
    AVG(total_volume)                       AS [Avg Volume per Customer (RM)]
FROM (
    SELECT
        customer_id,
        COUNT(*)        AS txn_count,
        SUM(amount)     AS total_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY customer_id
) AS customer_summary
GROUP BY
    CASE
        WHEN txn_count = 1          THEN '1 Transaction'
        WHEN txn_count BETWEEN 2 AND 5  THEN '2–5 Transactions'
        WHEN txn_count BETWEEN 6 AND 10 THEN '6–10 Transactions'
        WHEN txn_count BETWEEN 11 AND 20 THEN '11–20 Transactions'
        ELSE '20+ Transactions'
    END
ORDER BY [Activity Band];
