-- =============================================================
-- Script  : 10_data_segmentation_analysis.sql
-- Purpose : Group data into meaningful categories for targeted
--           insights. Customer segmentation, transaction
--           categorization, and regional analysis.
-- SQL Functions Used: CASE, GROUP BY
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. Customer value segmentation — RFM-style
--    Recency: last transaction, Frequency: count, Monetary: volume
-- -------------------------------------------------------------

WITH rfm_base AS (
    SELECT
        customer_id,
        segment,
        branch,
        MAX([date])             AS last_txn_date,
        COUNT(*)                AS frequency,
        SUM(amount)             AS monetary
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY customer_id, segment, branch
),
rfm_scored AS (
    SELECT
        customer_id,
        segment,
        branch,
        last_txn_date,
        frequency,
        monetary,
        DATEDIFF(DAY, last_txn_date, MAX(last_txn_date) OVER ()) AS recency_days,
        CASE
            WHEN DATEDIFF(DAY, last_txn_date,
                 MAX(last_txn_date) OVER ()) <= 30   THEN 'Active'
            WHEN DATEDIFF(DAY, last_txn_date,
                 MAX(last_txn_date) OVER ()) <= 90   THEN 'Lapsing'
            ELSE                                          'Dormant'
        END AS recency_band,
        CASE
            WHEN frequency >= 50    THEN 'High Frequency'
            WHEN frequency >= 20    THEN 'Medium Frequency'
            ELSE                         'Low Frequency'
        END AS frequency_band,
        CASE
            WHEN monetary >= 500000 THEN 'Platinum'
            WHEN monetary >= 100000 THEN 'Gold'
            WHEN monetary >= 20000  THEN 'Silver'
            ELSE                         'Bronze'
        END AS value_band
    FROM rfm_base
)
SELECT
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    branch                              AS [Branch],
    last_txn_date                       AS [Last Transaction],
    recency_days                        AS [Days Since Last Txn],
    frequency                           AS [Transaction Count],
    monetary                            AS [Total Volume (RM)],
    recency_band                        AS [Recency],
    frequency_band                      AS [Frequency],
    value_band                          AS [Value Tier],
    CASE
        WHEN recency_band = 'Active'
         AND value_band IN ('Platinum', 'Gold')    THEN 'Champion'
        WHEN recency_band = 'Active'
         AND frequency_band = 'High Frequency'     THEN 'Loyal Customer'
        WHEN recency_band = 'Lapsing'
         AND value_band IN ('Platinum', 'Gold')    THEN 'At Risk - High Value'
        WHEN recency_band = 'Dormant'              THEN 'Lost Customer'
        ELSE                                            'Regular Customer'
    END                                 AS [Customer Segment]
FROM rfm_scored
ORDER BY monetary DESC;


-- -------------------------------------------------------------
-- 2. Transaction risk segmentation
--    Categorize transactions by amount risk level
-- -------------------------------------------------------------

SELECT
    transaction_id                      AS [Transaction ID],
    [date]                              AS [Date],
    customer_id                         AS [Customer ID],
    segment                             AS [Segment],
    branch                              AS [Branch],
    transaction_type                    AS [Type],
    amount                              AS [Amount (RM)],
    is_anomaly                          AS [Flagged Anomaly],
    CASE
        WHEN is_anomaly = 1             THEN 'Critical — Statistical Outlier'
        WHEN amount >= 100000           THEN 'High Risk — Large Amount'
        WHEN amount >= 50000            THEN 'Medium Risk — Elevated Amount'
        WHEN amount >= 10000            THEN 'Low Risk — Standard Large'
        ELSE                                 'Normal — Routine Transaction'
    END                                 AS [Risk Category],
    CASE
        WHEN [status] = 'Failed'        THEN 'Review Failed'
        WHEN is_anomaly = 1
         AND amount >= 100000           THEN 'Escalate to Compliance'
        WHEN is_anomaly = 1             THEN 'Flag for Review'
        ELSE                                 'No Action Required'
    END                                 AS [Recommended Action]
FROM bank.fact_transactions
ORDER BY amount DESC;


-- -------------------------------------------------------------
-- 3. Customer tenure segmentation
--    Segment customers by how long they've been with the bank
-- -------------------------------------------------------------

SELECT
    c.customer_id                       AS [Customer ID],
    c.segment                           AS [Segment],
    c.branch                            AS [Branch],
    c.join_date                         AS [Join Date],
    DATEDIFF(YEAR, c.join_date, GETDATE())
                                        AS [Tenure (Years)],
    CASE
        WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 5
            THEN 'Veteran (5+ Years)'
        WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 3
            THEN 'Established (3–5 Years)'
        WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 1
            THEN 'Growing (1–3 Years)'
        ELSE
            'New (< 1 Year)'
    END                                 AS [Tenure Band],
    COUNT(f.transaction_id)             AS [Total Transactions],
    SUM(f.amount)                       AS [Total Volume (RM)],
    AVG(f.amount)                       AS [Avg Transaction (RM)]
FROM bank.dim_customers c
LEFT JOIN bank.fact_transactions f
    ON  c.customer_id = f.customer_id
    AND f.[status]   != 'Failed'
GROUP BY
    c.customer_id,
    c.segment,
    c.branch,
    c.join_date
ORDER BY
    DATEDIFF(YEAR, c.join_date, GETDATE()) DESC;


-- -------------------------------------------------------------
-- 4. Segment summary — count and volume per customer segment
-- -------------------------------------------------------------

WITH cust_segments AS (
    SELECT
        c.customer_id,
        c.segment,
        c.branch,
        c.join_date,
        CASE
            WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 5 THEN 'Veteran'
            WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 3 THEN 'Established'
            WHEN DATEDIFF(YEAR, c.join_date, GETDATE()) >= 1 THEN 'Growing'
            ELSE 'New'
        END AS tenure_band,
        SUM(f.amount)   AS total_volume,
        COUNT(f.transaction_id) AS txn_count
    FROM bank.dim_customers c
    LEFT JOIN bank.fact_transactions f
        ON  c.customer_id = f.customer_id
        AND f.[status]   != 'Failed'
    GROUP BY c.customer_id, c.segment, c.branch, c.join_date
)
SELECT
    segment                             AS [Segment],
    tenure_band                         AS [Tenure Band],
    COUNT(customer_id)                  AS [Customer Count],
    SUM(txn_count)                      AS [Total Transactions],
    SUM(total_volume)                   AS [Total Volume (RM)],
    AVG(total_volume)                   AS [Avg Volume per Customer (RM)]
FROM cust_segments
GROUP BY segment, tenure_band
ORDER BY segment, tenure_band;


-- -------------------------------------------------------------
-- 5. Monthly transaction pattern segmentation
--    Segment months as Peak, Normal, or Low activity
-- -------------------------------------------------------------

WITH monthly AS (
    SELECT
        FORMAT([date], 'MMM yyyy')          AS month_label,
        DATEPART(YEAR,  [date])             AS yr,
        DATEPART(MONTH, [date])             AS mn,
        SUM(amount)                         AS monthly_volume,
        COUNT(*)                            AS txn_count
    FROM bank.fact_transactions
    WHERE [status] != 'Failed'
    GROUP BY
        FORMAT([date], 'MMM yyyy'),
        DATEPART(YEAR,  [date]),
        DATEPART(MONTH, [date])
)
SELECT
    month_label                             AS [Month],
    txn_count                               AS [Transactions],
    monthly_volume                          AS [Volume (RM)],
    AVG(monthly_volume) OVER ()             AS [Annual Monthly Avg (RM)],
    CASE
        WHEN monthly_volume > AVG(monthly_volume) OVER () * 1.2
            THEN 'Peak Month'
        WHEN monthly_volume < AVG(monthly_volume) OVER () * 0.8
            THEN 'Low Month'
        ELSE
            'Normal Month'
    END                                     AS [Activity Level]
FROM monthly
ORDER BY yr, mn;
