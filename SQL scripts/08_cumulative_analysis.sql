-- =============================================================
-- Script  : 08_cumulative_analysis.sql
-- Purpose : Calculate running totals and moving averages for
--           key metrics. Track cumulative performance over time
--           and identify long-term growth trends.
-- SQL Functions Used: SUM() OVER(), AVG() OVER()
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Cumulative transaction volume by month
--    Running total — how much have we processed year to date?
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATEPART(YEAR,  [date])         AS yr,
        DATEPART(MONTH, [date])         AS mn,
        FORMAT([date], 'MMM yyyy')      AS month_label,
        COUNT(*)                        AS txn_count,
        SUM(amount)                     AS monthly_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    month_label                         AS [Month],
    txn_count                           AS [Monthly Transactions],
    monthly_volume                      AS [Monthly Volume (RM)],
    SUM(txn_count)    OVER (ORDER BY yr, mn ROWS UNBOUNDED PRECEDING)
                                        AS [Cumulative Transactions],
    SUM(monthly_volume) OVER (ORDER BY yr, mn ROWS UNBOUNDED PRECEDING)
                                        AS [Cumulative Volume (RM)]
FROM monthly
ORDER BY yr, mn;


-- -------------------------------------------------------------
-- 2. 3-month moving average on transaction volume
--    Smooths out spikes — shows the true underlying trend
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATEPART(YEAR,  [date])         AS yr,
        DATEPART(MONTH, [date])         AS mn,
        FORMAT([date], 'MMM yyyy')      AS month_label,
        SUM(amount)                     AS monthly_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    month_label                         AS [Month],
    monthly_volume                      AS [Monthly Volume (RM)],
    AVG(monthly_volume) OVER (
        ORDER BY yr, mn
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    )                                   AS [3-Month Moving Avg (RM)],
    AVG(monthly_volume) OVER (
        ORDER BY yr, mn
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    )                                   AS [6-Month Moving Avg (RM)]
FROM monthly
ORDER BY yr, mn;


-- -------------------------------------------------------------
-- 3. Cumulative volume by segment over time
--    Which segment crossed the RM 10M mark first?
-- -------------------------------------------------------------

WITH monthly_seg AS (
    SELECT
        DATEPART(YEAR,  [date])         AS yr,
        DATEPART(MONTH, [date])         AS mn,
        FORMAT([date], 'MMM yyyy')      AS month_label,
        segment,
        SUM(amount)                     AS monthly_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy'),
        segment
)
SELECT
    month_label                         AS [Month],
    segment                             AS [Segment],
    monthly_volume                      AS [Monthly Volume (RM)],
    SUM(monthly_volume) OVER (
        PARTITION BY segment
        ORDER BY yr, mn
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Cumulative Volume (RM)]
FROM monthly_seg
ORDER BY segment, yr, mn;


-- -------------------------------------------------------------
-- 4. Cumulative volume by branch over time
-- -------------------------------------------------------------

WITH monthly_branch AS (
    SELECT
        DATEPART(YEAR,  [date])         AS yr,
        DATEPART(MONTH, [date])         AS mn,
        FORMAT([date], 'MMM yyyy')      AS month_label,
        branch,
        SUM(amount)                     AS monthly_volume,
        COUNT(*)                        AS monthly_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy'),
        branch
)
SELECT
    month_label                         AS [Month],
    branch                              AS [Branch],
    monthly_volume                      AS [Monthly Volume (RM)],
    SUM(monthly_volume) OVER (
        PARTITION BY branch
        ORDER BY yr, mn
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Cumulative Volume (RM)],
    SUM(monthly_count) OVER (
        PARTITION BY branch
        ORDER BY yr, mn
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Cumulative Transactions]
FROM monthly_branch
ORDER BY branch, yr, mn;


-- -------------------------------------------------------------
-- 5. Running total per customer
--    Track how each customer's spend builds up over the year
-- -------------------------------------------------------------

SELECT
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    [date]                              AS [Date],
    amount                              AS [Transaction Amount (RM)],
    SUM(amount) OVER (
        PARTITION BY customer_id
        ORDER BY [date]
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Running Total per Customer (RM)],
    AVG(amount) OVER (
        PARTITION BY customer_id
        ORDER BY [date]
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Running Avg per Customer (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
ORDER BY customer_id, [date];


-- -------------------------------------------------------------
-- 6. Cumulative transaction count — milestone tracking
--    When did we hit 1000, 2000, 3000 transactions?
-- -------------------------------------------------------------

WITH daily AS (
    SELECT
        [date]                          AS txn_date,
        COUNT(*)                        AS daily_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY [date]
)
SELECT
    txn_date                            AS [Date],
    daily_count                         AS [Daily Transactions],
    SUM(daily_count) OVER (
        ORDER BY txn_date
        ROWS UNBOUNDED PRECEDING
    )                                   AS [Cumulative Transactions],
    AVG(CAST(daily_count AS FLOAT)) OVER (
        ORDER BY txn_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    )                                   AS [7-Day Moving Avg]
FROM daily
ORDER BY txn_date;
