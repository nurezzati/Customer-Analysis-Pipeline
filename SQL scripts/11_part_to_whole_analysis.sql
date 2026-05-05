-- =============================================================
-- Script  : 11_part_to_whole_analysis.sql
-- Purpose : Compare performance and metrics across dimensions.
--           Evaluate each category's contribution to the total.
--           Useful for understanding share, mix, and composition.
-- SQL Functions Used: SUM(), AVG(), SUM() OVER()
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Each branch's share of total transaction volume
--    What % of total bank volume does each branch represent?
-- -------------------------------------------------------------

SELECT
    branch                                          AS [Branch],
    COUNT(*)                                        AS [Transactions],
    SUM(amount)                                     AS [Branch Volume (RM)],
    SUM(SUM(amount)) OVER ()                        AS [Total Bank Volume (RM)],
    ROUND(
        SUM(amount) / SUM(SUM(amount)) OVER () * 100
    , 2)                                            AS [Volume Share (%)],
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
    , 2)                                            AS [Transaction Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch
ORDER BY [Volume Share (%)] DESC;


-- -------------------------------------------------------------
-- 2. Each segment's share of total volume
-- -------------------------------------------------------------

SELECT
    segment                                         AS [Segment],
    COUNT(*)                                        AS [Transactions],
    COUNT(DISTINCT customer_id)                     AS [Customers],
    SUM(amount)                                     AS [Segment Volume (RM)],
    SUM(SUM(amount)) OVER ()                        AS [Total Volume (RM)],
    ROUND(
        SUM(amount) / SUM(SUM(amount)) OVER () * 100
    , 2)                                            AS [Volume Share (%)],
    ROUND(
        COUNT(DISTINCT customer_id) * 100.0
        / SUM(COUNT(DISTINCT customer_id)) OVER ()
    , 2)                                            AS [Customer Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment
ORDER BY [Volume Share (%)] DESC;


-- -------------------------------------------------------------
-- 3. Each product's share of total volume
-- -------------------------------------------------------------

SELECT
    product                                         AS [Product],
    COUNT(*)                                        AS [Transactions],
    SUM(amount)                                     AS [Product Volume (RM)],
    SUM(SUM(amount)) OVER ()                        AS [Total Volume (RM)],
    ROUND(
        SUM(amount) / SUM(SUM(amount)) OVER () * 100
    , 2)                                            AS [Volume Share (%)],
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
    , 2)                                            AS [Transaction Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY product
ORDER BY [Volume Share (%)] DESC;


-- -------------------------------------------------------------
-- 4. Transaction type share within each branch
--    What % of KL volume is Deposits vs Transfers vs Payments?
-- -------------------------------------------------------------

SELECT
    branch                                          AS [Branch],
    transaction_type                                AS [Transaction Type],
    SUM(amount)                                     AS [Volume (RM)],
    SUM(SUM(amount)) OVER (PARTITION BY branch)     AS [Branch Total (RM)],
    ROUND(
        SUM(amount) /
        SUM(SUM(amount)) OVER (PARTITION BY branch) * 100
    , 2)                                            AS [Share Within Branch (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch, transaction_type
ORDER BY branch, [Share Within Branch (%)] DESC;


-- -------------------------------------------------------------
-- 5. Segment share within each branch
--    In Penang branch — is it mostly Retail or SME?
-- -------------------------------------------------------------

SELECT
    branch                                          AS [Branch],
    segment                                         AS [Segment],
    COUNT(DISTINCT customer_id)                     AS [Customers],
    SUM(amount)                                     AS [Volume (RM)],
    SUM(SUM(amount)) OVER (PARTITION BY branch)     AS [Branch Total (RM)],
    ROUND(
        SUM(amount) /
        SUM(SUM(amount)) OVER (PARTITION BY branch) * 100
    , 2)                                            AS [Share of Branch Volume (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY branch, segment
ORDER BY branch, [Share of Branch Volume (%)] DESC;


-- -------------------------------------------------------------
-- 6. Monthly share of annual volume
--    Which months contribute the most to the full year?
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        FORMAT([date], 'MMM yyyy')                  AS month_label,
        DATEPART(YEAR,  [date])                     AS yr,
        DATEPART(MONTH, [date])                     AS mn,
        SUM(amount)                                 AS monthly_volume,
        COUNT(*)                                    AS txn_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        FORMAT([date], 'MMM yyyy'),
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date])
)
SELECT
    month_label                                     AS [Month],
    txn_count                                       AS [Transactions],
    monthly_volume                                  AS [Monthly Volume (RM)],
    SUM(monthly_volume) OVER ()                     AS [Annual Total (RM)],
    ROUND(
        monthly_volume / SUM(monthly_volume) OVER () * 100
    , 2)                                            AS [Share of Annual Volume (%)],
    ROUND(
        txn_count * 100.0 / SUM(txn_count) OVER ()
    , 2)                                            AS [Share of Annual Txns (%)]
FROM monthly
ORDER BY yr, mn;


-- -------------------------------------------------------------
-- 7. Product mix within each customer segment
--    Do SME customers prefer loans or current accounts?
-- -------------------------------------------------------------

SELECT
    segment                                         AS [Segment],
    product                                         AS [Product],
    COUNT(*)                                        AS [Transactions],
    SUM(amount)                                     AS [Volume (RM)],
    SUM(SUM(amount)) OVER (PARTITION BY segment)    AS [Segment Total (RM)],
    ROUND(
        SUM(amount) /
        SUM(SUM(amount)) OVER (PARTITION BY segment) * 100
    , 2)                                            AS [Share Within Segment (%)],
    AVG(amount)                                     AS [Avg Transaction (RM)],
    AVG(AVG(amount)) OVER (PARTITION BY segment)    AS [Segment Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY segment, product
ORDER BY segment, [Share Within Segment (%)] DESC;


-- -------------------------------------------------------------
-- 8. Anomaly share — what % of volume comes from flagged txns?
--    Understand how much of the bank's money moves through
--    statistically outlier transactions
-- -------------------------------------------------------------

SELECT
    CASE
        WHEN is_anomaly = 1 THEN 'Anomaly'
        ELSE                     'Normal'
    END                                             AS [Transaction Type],
    COUNT(*)                                        AS [Count],
    SUM(amount)                                     AS [Volume (RM)],
    SUM(SUM(amount)) OVER ()                        AS [Total Volume (RM)],
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER ()
    , 2)                                            AS [Count Share (%)],
    ROUND(
        SUM(amount) / SUM(SUM(amount)) OVER () * 100
    , 2)                                            AS [Volume Share (%)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY is_anomaly
ORDER BY is_anomaly;
