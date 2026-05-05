-- =============================================================
-- Script  : 04_measures_exploration.sql
-- Purpose : Calculate key aggregated metrics for quick business
--           insights. Identify overall trends and spot anomalies
--           across transactions and customer data.
-- SQL Functions Used: COUNT(), SUM(), AVG()
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Overall transaction KPIs — top-level health check
-- -------------------------------------------------------------

SELECT
    COUNT(*)                            AS [Total Transactions],
    COUNT(DISTINCT customer_id)         AS [Unique Customers],
    COUNT(DISTINCT branch)              AS [Active Branches],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)],
    MIN(amount)                         AS [Min Transaction (RM)],
    MAX(amount)                         AS [Max Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed';


-- -------------------------------------------------------------
-- 2. Transaction volume by status
--    Understand how much is completed vs pending vs failed
-- -------------------------------------------------------------

SELECT
    [status]                            AS [Status],
    COUNT(*)                            AS [Transaction Count],
    SUM(amount)                         AS [Total Amount (RM)],
    AVG(amount)                         AS [Avg Amount (RM)]
FROM bank.fact_transactions
GROUP BY [status]
ORDER BY [Transaction Count] DESC;


-- -------------------------------------------------------------
-- 3. Volume and count by transaction type
-- -------------------------------------------------------------

SELECT
    transaction_type                    AS [Transaction Type],
    COUNT(*)                            AS [Count],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Amount (RM)],
    MIN(amount)                         AS [Min (RM)],
    MAX(amount)                         AS [Max (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY transaction_type
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 4. Volume and count by product
-- -------------------------------------------------------------

SELECT
    product                             AS [Product],
    COUNT(*)                            AS [Count],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Amount (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY product
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 5. Volume and count by customer segment
-- -------------------------------------------------------------

SELECT
    segment                             AS [Segment],
    COUNT(*)                            AS [Transactions],
    COUNT(DISTINCT customer_id)         AS [Unique Customers],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg per Transaction (RM)],
    SUM(amount) /
        COUNT(DISTINCT customer_id)     AS [Avg Volume per Customer (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 6. Volume and count by branch
-- -------------------------------------------------------------

SELECT
    branch                              AS [Branch],
    COUNT(*)                            AS [Transactions],
    COUNT(DISTINCT customer_id)         AS [Unique Customers],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch
ORDER BY SUM(amount) DESC;


-- -------------------------------------------------------------
-- 7. Monthly aggregates — quick trend overview
-- -------------------------------------------------------------

SELECT
    YEAR([date])                        AS [Year],
    DATENAME(MONTH, [date])             AS [Month],
    MONTH([date])                       AS [Month Num],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    YEAR([date]),
    MONTH([date]),
    DATENAME(MONTH, [date])
ORDER BY
    YEAR([date]),
    MONTH([date]);


-- -------------------------------------------------------------
-- 8. Anomaly summary — how many flagged transactions?
-- -------------------------------------------------------------

SELECT
    is_anomaly                          AS [Is Anomaly],
    COUNT(*)                            AS [Count],
    SUM(amount)                         AS [Total Amount (RM)],
    AVG(amount)                         AS [Avg Amount (RM)]
FROM bank.fact_transactions
GROUP BY is_anomaly
ORDER BY is_anomaly;
