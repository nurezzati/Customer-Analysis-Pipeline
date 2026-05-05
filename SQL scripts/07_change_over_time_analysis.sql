-- =============================================================
-- Script  : 07_change_over_time_analysis.sql
-- Purpose : Track trends, growth, and changes in key metrics
--           over time. Identify seasonality and measure growth
--           or decline across specific time periods.
-- SQL Functions Used: DATEPART(), FORMAT()
--                     SUM(), COUNT(), AVG()
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Monthly transaction volume and count — full year trend
-- -------------------------------------------------------------

SELECT
    DATEPART(YEAR,  [date])             AS [Year],
    DATEPART(MONTH, [date])             AS [Month Num],
    FORMAT([date], 'MMM yyyy')          AS [Month],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]),
    FORMAT([date], 'MMM yyyy')
ORDER BY
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]);


-- -------------------------------------------------------------
-- 2. Month-over-Month (MoM) volume change
--    How much did volume grow or shrink vs previous month?
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        DATEPART(YEAR,  [date])         AS yr,
        DATEPART(MONTH, [date])         AS mn,
        FORMAT([date], 'MMM yyyy')      AS month_label,
        COUNT(*)                        AS txn_count,
        SUM(amount)                     AS total_volume
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date]),
        FORMAT([date], 'MMM yyyy')
)
SELECT
    month_label                         AS [Month],
    txn_count                           AS [Transactions],
    total_volume                        AS [Volume (RM)],
    LAG(total_volume) OVER (ORDER BY yr, mn)
                                        AS [Prev Month Volume (RM)],
    total_volume - LAG(total_volume) OVER (ORDER BY yr, mn)
                                        AS [MoM Change (RM)],
    CASE
        WHEN LAG(total_volume) OVER (ORDER BY yr, mn) IS NULL THEN NULL
        ELSE ROUND(
            (total_volume - LAG(total_volume) OVER (ORDER BY yr, mn))
            / LAG(total_volume) OVER (ORDER BY yr, mn) * 100, 2)
    END                                 AS [MoM Change (%)]
FROM monthly
ORDER BY yr, mn;


-- -------------------------------------------------------------
-- 3. Quarterly aggregates — are we growing quarter by quarter?
-- -------------------------------------------------------------

SELECT
    DATEPART(YEAR,    [date])           AS [Year],
    DATEPART(QUARTER, [date])           AS [Quarter],
    'Q' + CAST(DATEPART(QUARTER, [date]) AS VARCHAR)
        + ' ' + CAST(DATEPART(YEAR, [date]) AS VARCHAR)
                                        AS [Quarter Label],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    DATEPART(YEAR,    [date]),
    DATEPART(QUARTER, [date])
ORDER BY
    DATEPART(YEAR,    [date]),
    DATEPART(QUARTER, [date]);


-- -------------------------------------------------------------
-- 4. Day of week analysis — which days are busiest?
--    Identify weekly seasonality
-- -------------------------------------------------------------

SELECT
    DATEPART(WEEKDAY, [date])           AS [Day Num],
    DATENAME(WEEKDAY, [date])           AS [Day of Week],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)],
    AVG(amount)                         AS [Avg Transaction (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    DATEPART(WEEKDAY, [date]),
    DATENAME(WEEKDAY, [date])
ORDER BY
    DATEPART(WEEKDAY, [date]);


-- -------------------------------------------------------------
-- 5. Monthly trend broken down by segment
--    Is Retail growing faster than SME over time?
-- -------------------------------------------------------------

SELECT
    FORMAT([date], 'MMM yyyy')          AS [Month],
    DATEPART(YEAR,  [date])             AS [Year],
    DATEPART(MONTH, [date])             AS [Month Num],
    segment                             AS [Segment],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    FORMAT([date], 'MMM yyyy'),
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]),
    segment
ORDER BY
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]),
    segment;


-- -------------------------------------------------------------
-- 6. Monthly trend by branch
--    Which branch is growing the fastest month on month?
-- -------------------------------------------------------------

SELECT
    FORMAT([date], 'MMM yyyy')          AS [Month],
    DATEPART(YEAR,  [date])             AS [Year],
    DATEPART(MONTH, [date])             AS [Month Num],
    branch                              AS [Branch],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    FORMAT([date], 'MMM yyyy'),
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]),
    branch
ORDER BY
    DATEPART(YEAR,  [date]),
    DATEPART(MONTH, [date]),
    branch;


-- -------------------------------------------------------------
-- 7. Year-over-Year placeholder — ready when multi-year data exists
--    Compare same month across different years
-- -------------------------------------------------------------

SELECT
    DATEPART(MONTH, [date])             AS [Month Num],
    DATENAME(MONTH, [date])             AS [Month Name],
    DATEPART(YEAR,  [date])             AS [Year],
    COUNT(*)                            AS [Transactions],
    SUM(amount)                         AS [Total Volume (RM)]
FROM bank.fact_transactions
WHERE [status] != 'Failed'
GROUP BY
    DATEPART(MONTH, [date]),
    DATENAME(MONTH, [date]),
    DATEPART(YEAR,  [date])
ORDER BY
    DATEPART(MONTH, [date]),
    DATEPART(YEAR,  [date]);
