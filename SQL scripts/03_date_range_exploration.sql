-- =============================================================
-- Script  : 03_date_range_exploration.sql
-- Purpose : Determine the temporal boundaries of transaction
--           data and customer records. Understand historical
--           range and identify any data gaps.
-- SQL Functions Used: MIN(), MAX(), DATEDIFF()
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Transaction date range — overall boundaries
-- -------------------------------------------------------------

SELECT
    MIN([date])                             AS [Earliest Transaction],
    MAX([date])                             AS [Latest Transaction],
    DATEDIFF(DAY,  MIN([date]), MAX([date])) AS [Total Days Covered],
    DATEDIFF(MONTH,MIN([date]), MAX([date])) AS [Total Months Covered],
    DATEDIFF(YEAR, MIN([date]), MAX([date])) AS [Total Years Covered]
FROM bank.fact_transactions;


-- -------------------------------------------------------------
-- 2. Customer join date range — when did customers onboard?
-- -------------------------------------------------------------

SELECT
    MIN(join_date)                                  AS [Earliest Join Date],
    MAX(join_date)                                  AS [Latest Join Date],
    DATEDIFF(DAY,  MIN(join_date), MAX(join_date))  AS [Onboarding Span (Days)],
    DATEDIFF(YEAR, MIN(join_date), MAX(join_date))  AS [Onboarding Span (Years)]
FROM bank.dim_customers;


-- -------------------------------------------------------------
-- 3. Date range breakdown by customer segment
-- -------------------------------------------------------------

SELECT
    segment                                             AS [Segment],
    MIN([date])                                         AS [First Transaction],
    MAX([date])                                         AS [Last Transaction],
    DATEDIFF(DAY, MIN([date]), MAX([date]))              AS [Active Days]
FROM bank.fact_transactions
GROUP BY segment
ORDER BY segment;


-- -------------------------------------------------------------
-- 4. Date range breakdown by branch
-- -------------------------------------------------------------

SELECT
    branch                                              AS [Branch],
    MIN([date])                                         AS [First Transaction],
    MAX([date])                                         AS [Last Transaction],
    DATEDIFF(MONTH, MIN([date]), MAX([date]))            AS [Active Months]
FROM bank.fact_transactions
GROUP BY branch
ORDER BY branch;


-- -------------------------------------------------------------
-- 5. Monthly activity — are all months represented?
--    Helps identify gaps in historical data
-- -------------------------------------------------------------

SELECT
    YEAR([date])                AS [Year],
    MONTH([date])               AS [Month Num],
    DATENAME(MONTH, [date])     AS [Month Name],
    COUNT(*)                    AS [Transaction Count],
    MIN([date])                 AS [First Date in Month],
    MAX([date])                 AS [Last Date in Month],
    DATEDIFF(DAY,
        MIN([date]),
        MAX([date]))            AS [Days with Activity]
FROM bank.fact_transactions
GROUP BY
    YEAR([date]),
    MONTH([date]),
    DATENAME(MONTH, [date])
ORDER BY
    YEAR([date]),
    MONTH([date]);


-- -------------------------------------------------------------
-- 6. How old are existing customers? (tenure analysis)
-- -------------------------------------------------------------

SELECT
    customer_id                                         AS [Customer ID],
    segment                                             AS [Segment],
    join_date                                           AS [Join Date],
    DATEDIFF(YEAR,  join_date, GETDATE())               AS [Tenure (Years)],
    DATEDIFF(MONTH, join_date, GETDATE())               AS [Tenure (Months)]
FROM bank.dim_customers
ORDER BY join_date ASC;
