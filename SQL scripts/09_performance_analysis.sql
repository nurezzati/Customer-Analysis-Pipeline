-- =============================================================
-- Script  : 09_performance_analysis.sql
-- Purpose : Measure performance of products, customers, and
--           branches over time. Benchmark entities and track
--           yearly and monthly growth trends.
-- SQL Functions Used: LAG(), AVG() OVER(), CASE
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Month-over-Month (MoM) performance — overall
--    Track volume change and flag growth vs decline
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATEPART(YEAR,  [date])             AS yr,
        DATEPART(MONTH, [date])             AS mn,
        FORMAT([date], 'MMM yyyy')          AS month_label,
        COUNT(*)                            AS txn_count,
        SUM(amount)                         AS monthly_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    month_label                             AS [Month],
    txn_count                               AS [Transactions],
    monthly_volume                          AS [Volume (RM)],
    LAG(monthly_volume) OVER
        (ORDER BY yr, mn)                   AS [Prev Month Volume (RM)],
    monthly_volume
        - LAG(monthly_volume) OVER
            (ORDER BY yr, mn)               AS [MoM Change (RM)],
    ROUND(
        (monthly_volume
            - LAG(monthly_volume) OVER (ORDER BY yr, mn))
        / NULLIF(LAG(monthly_volume) OVER
            (ORDER BY yr, mn), 0) * 100, 2) AS [MoM Change (%)],
    CASE
        WHEN LAG(monthly_volume) OVER (ORDER BY yr, mn) IS NULL
            THEN 'Baseline'
        WHEN monthly_volume > LAG(monthly_volume) OVER (ORDER BY yr, mn)
            THEN 'Growth'
        WHEN monthly_volume < LAG(monthly_volume) OVER (ORDER BY yr, mn)
            THEN 'Decline'
        ELSE 'Flat'
    END                                     AS [MoM Trend]
FROM monthly
ORDER BY yr, mn;


-- -------------------------------------------------------------
-- 2. Year-over-Year (YoY) performance — by month
--    Compare Jan 2024 vs Jan 2023, Feb 2024 vs Feb 2023, etc.
--    (Placeholder ready — populate with multi-year data)
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATEPART(YEAR,  [date])             AS yr,
        DATEPART(MONTH, [date])             AS mn,
        DATENAME(MONTH, [date])             AS month_name,
        SUM(amount)                         AS monthly_volume,
        COUNT(*)                            AS txn_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        DATENAME(MONTH, [date])
)
SELECT
    month_name                              AS [Month],
    yr                                      AS [Year],
    monthly_volume                          AS [Volume (RM)],
    LAG(monthly_volume) OVER
        (PARTITION BY mn ORDER BY yr)       AS [Prev Year Volume (RM)],
    monthly_volume
        - LAG(monthly_volume) OVER
            (PARTITION BY mn ORDER BY yr)   AS [YoY Change (RM)],
    ROUND(
        (monthly_volume
            - LAG(monthly_volume) OVER (PARTITION BY mn ORDER BY yr))
        / NULLIF(LAG(monthly_volume) OVER
            (PARTITION BY mn ORDER BY yr), 0) * 100, 2)
                                            AS [YoY Change (%)],
    CASE
        WHEN LAG(monthly_volume) OVER (PARTITION BY mn ORDER BY yr) IS NULL
            THEN 'Baseline'
        WHEN monthly_volume > LAG(monthly_volume) OVER (PARTITION BY mn ORDER BY yr)
            THEN 'Growth'
        WHEN monthly_volume < LAG(monthly_volume) OVER (PARTITION BY mn ORDER BY yr)
            THEN 'Decline'
        ELSE 'Flat'
    END                                     AS [YoY Trend]
FROM monthly
ORDER BY mn, yr;


-- -------------------------------------------------------------
-- 3. Branch MoM performance with trend flag
--    Which branches are consistently growing?
-- -------------------------------------------------------------

WITH branch_monthly AS (
    SELECT
        branch,
        DATEPART(YEAR,  [date])             AS yr,
        DATEPART(MONTH, [date])             AS mn,
        FORMAT([date], 'MMM yyyy')          AS month_label,
        SUM(amount)                         AS monthly_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        branch,
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    branch                                  AS [Branch],
    month_label                             AS [Month],
    monthly_volume                          AS [Volume (RM)],
    LAG(monthly_volume) OVER
        (PARTITION BY branch ORDER BY yr, mn)
                                            AS [Prev Month (RM)],
    ROUND(
        (monthly_volume
            - LAG(monthly_volume) OVER (PARTITION BY branch ORDER BY yr, mn))
        / NULLIF(LAG(monthly_volume) OVER
            (PARTITION BY branch ORDER BY yr, mn), 0) * 100, 2)
                                            AS [MoM Change (%)],
    AVG(monthly_volume) OVER
        (PARTITION BY branch
         ORDER BY yr, mn
         ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)
                                            AS [3-Month Avg (RM)],
    CASE
        WHEN LAG(monthly_volume) OVER (PARTITION BY branch ORDER BY yr, mn) IS NULL
            THEN 'Baseline'
        WHEN monthly_volume > AVG(monthly_volume) OVER (PARTITION BY branch)
            THEN 'Above Average'
        WHEN monthly_volume < AVG(monthly_volume) OVER (PARTITION BY branch)
            THEN 'Below Average'
        ELSE 'Average'
    END                                     AS [Performance vs Branch Avg]
FROM branch_monthly
ORDER BY branch, yr, mn;


-- -------------------------------------------------------------
-- 4. Product MoM performance with trend flag
-- -------------------------------------------------------------

WITH prod_monthly AS (
    SELECT
        product,
        DATEPART(YEAR,  [date])             AS yr,
        DATEPART(MONTH, [date])             AS mn,
        FORMAT([date], 'MMM yyyy')          AS month_label,
        SUM(amount)                         AS monthly_volume,
        COUNT(*)                            AS txn_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        product,
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    product                                 AS [Product],
    month_label                             AS [Month],
    txn_count                               AS [Transactions],
    monthly_volume                          AS [Volume (RM)],
    LAG(monthly_volume) OVER
        (PARTITION BY product ORDER BY yr, mn)
                                            AS [Prev Month (RM)],
    ROUND(
        (monthly_volume
            - LAG(monthly_volume) OVER (PARTITION BY product ORDER BY yr, mn))
        / NULLIF(LAG(monthly_volume) OVER
            (PARTITION BY product ORDER BY yr, mn), 0) * 100, 2)
                                            AS [MoM Change (%)],
    AVG(monthly_volume) OVER
        (PARTITION BY product)              AS [Product Annual Avg (RM)],
    CASE
        WHEN monthly_volume > AVG(monthly_volume) OVER (PARTITION BY product)
            THEN 'Above Annual Avg'
        WHEN monthly_volume < AVG(monthly_volume) OVER (PARTITION BY product)
            THEN 'Below Annual Avg'
        ELSE 'At Annual Avg'
    END                                     AS [Performance vs Annual Avg]
FROM prod_monthly
ORDER BY product, yr, mn;


-- -------------------------------------------------------------
-- 5. Customer performance benchmarking
--    Flag customers above/below their segment average
-- -------------------------------------------------------------

WITH cust_summary AS (
    SELECT
        customer_id,
        segment,
        branch,
        COUNT(*)        AS txn_count,
        SUM(amount)     AS total_volume,
        AVG(amount)     AS avg_txn
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY customer_id, segment, branch
)
SELECT
    customer_id                             AS [Customer ID],
    segment                                 AS [Segment],
    branch                                  AS [Branch],
    txn_count                               AS [Transactions],
    total_volume                            AS [Total Volume (RM)],
    avg_txn                                 AS [Avg Transaction (RM)],
    AVG(total_volume) OVER
        (PARTITION BY segment)              AS [Segment Avg Volume (RM)],
    total_volume
        - AVG(total_volume) OVER
            (PARTITION BY segment)          AS [Diff from Segment Avg (RM)],
    CASE
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment) * 1.5
            THEN 'High Performer'
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment)
            THEN 'Above Average'
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment) * 0.5
            THEN 'Below Average'
        ELSE 'Low Performer'
    END                                     AS [Performance Band]
FROM cust_summary
ORDER BY segment, total_volume DESC;
