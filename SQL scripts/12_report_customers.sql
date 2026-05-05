-- =============================================================
-- Script  : 12_report_customers.sql
-- Purpose : Consolidate key customer metrics and behaviours
--           tailored for banking analytics (Customer context).
--           Segments customers, aggregates transaction metrics,
--           and calculates banking KPIs.
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO

-- =============================================================
-- FINAL CUSTOMER REPORT VIEW
-- =============================================================

WITH

-- -------------------------------------------------------------
-- BASE: Core customer transaction aggregates
-- -------------------------------------------------------------
customer_base AS (
    SELECT
        f.customer_id,
        f.segment,
        f.branch,
        c.join_date,

        -- Transaction volume metrics
        COUNT(f.transaction_id)                     AS total_transactions,
        SUM(f.amount)                               AS total_volume,
        AVG(f.amount)                               AS avg_transaction_value,
        MIN(f.amount)                               AS min_transaction,
        MAX(f.amount)                               AS max_transaction,

        -- Product diversity
        COUNT(DISTINCT f.product)                   AS total_products_used,
        COUNT(DISTINCT f.transaction_type)          AS total_txn_types_used,

        -- Time boundaries
        MIN(f.[date])                               AS first_transaction_date,
        MAX(f.[date])                               AS last_transaction_date,

        -- Anomaly exposure
        SUM(CAST(f.is_anomaly AS INT))              AS anomaly_count

    FROM bank.fact_transactions f
    JOIN bank.dim_customers c
        ON f.customer_id = c.customer_id
    WHERE f.[status] != 'Failed'
    GROUP BY
        f.customer_id,
        f.segment,
        f.branch,
        c.join_date
),

-- -------------------------------------------------------------
-- KPI CALCULATIONS
-- -------------------------------------------------------------
customer_kpis AS (
    SELECT
        customer_id,
        segment,
        branch,
        join_date,
        total_transactions,
        total_volume,
        avg_transaction_value,
        min_transaction,
        max_transaction,
        total_products_used,
        total_txn_types_used,
        first_transaction_date,
        last_transaction_date,
        anomaly_count,

        -- Lifespan: months between first and last transaction
        DATEDIFF(MONTH, first_transaction_date, last_transaction_date)
                                                    AS lifespan_months,

        -- Recency: months since last transaction
        DATEDIFF(MONTH, last_transaction_date, GETDATE())
                                                    AS recency_months,

        -- Customer tenure: months since joining the bank
        DATEDIFF(MONTH, join_date, GETDATE())
                                                    AS tenure_months,

        -- Average monthly spend
        CASE
            WHEN DATEDIFF(MONTH, first_transaction_date, last_transaction_date) = 0
            THEN total_volume
            ELSE ROUND(total_volume /
                 DATEDIFF(MONTH, first_transaction_date, last_transaction_date), 2)
        END                                         AS avg_monthly_spend,

        -- Average order value (avg per transaction)
        ROUND(total_volume / NULLIF(total_transactions, 0), 2)
                                                    AS avg_transaction_amount

    FROM customer_base
)

-- =============================================================
-- FINAL SELECT — with segmentation and all KPIs
-- =============================================================
SELECT

    -- ── IDENTIFIERS ──────────────────────────────────────────
    customer_id                                     AS [Customer ID],
    segment                                         AS [Bank Segment],
    branch                                          AS [Branch],
    join_date                                       AS [Join Date],

    -- ── CUSTOMER TIER SEGMENTATION ───────────────────────────
    -- Based on total transaction volume
    CASE
        WHEN total_volume >= 500000                 THEN 'VIP'
        WHEN total_volume >= 100000                 THEN 'Premium'
        WHEN total_volume >= 20000                  THEN 'Regular'
        ELSE                                             'New / Low Activity'
    END                                             AS [Customer Tier],

    -- ── TENURE BAND ──────────────────────────────────────────
    CASE
        WHEN tenure_months >= 60                    THEN 'Veteran (5+ Yrs)'
        WHEN tenure_months >= 36                    THEN 'Established (3–5 Yrs)'
        WHEN tenure_months >= 12                    THEN 'Growing (1–3 Yrs)'
        ELSE                                             'New (< 1 Yr)'
    END                                             AS [Tenure Band],

    -- ── ACTIVITY STATUS ──────────────────────────────────────
    CASE
        WHEN recency_months = 0                     THEN 'Active This Month'
        WHEN recency_months <= 3                    THEN 'Active (< 3 Months)'
        WHEN recency_months <= 6                    THEN 'Lapsing (3–6 Months)'
        ELSE                                             'Dormant (6+ Months)'
    END                                             AS [Activity Status],

    -- ── TRANSACTION METRICS ──────────────────────────────────
    total_transactions                              AS [Total Transactions],
    total_products_used                             AS [Products Used],
    total_txn_types_used                            AS [Transaction Types Used],
    first_transaction_date                          AS [First Transaction Date],
    last_transaction_date                           AS [Last Transaction Date],

    -- ── VOLUME METRICS ───────────────────────────────────────
    ROUND(total_volume, 2)                          AS [Total Volume (RM)],
    ROUND(min_transaction, 2)                       AS [Min Transaction (RM)],
    ROUND(max_transaction, 2)                       AS [Max Transaction (RM)],

    -- ── KPIs ─────────────────────────────────────────────────
    tenure_months                                   AS [Tenure (Months)],
    lifespan_months                                 AS [Active Lifespan (Months)],
    recency_months                                  AS [Recency (Months Since Last Txn)],
    ROUND(avg_transaction_amount, 2)                AS [Avg Transaction Value (RM)],
    ROUND(avg_monthly_spend, 2)                     AS [Avg Monthly Spend (RM)],

    -- ── RISK INDICATOR ───────────────────────────────────────
    anomaly_count                                   AS [Anomaly Transactions],
    CASE
        WHEN anomaly_count >= 3                     THEN 'High Risk'
        WHEN anomaly_count >= 1                     THEN 'Monitor'
        ELSE                                             'Clean'
    END                                             AS [Risk Flag],

    -- ── BENCHMARKS vs ALL CUSTOMERS ──────────────────────────
    ROUND(AVG(total_volume) OVER (), 2)             AS [Bank Avg Volume (RM)],
    ROUND(AVG(avg_monthly_spend) OVER (), 2)        AS [Bank Avg Monthly Spend (RM)],
    ROUND(total_volume
        - AVG(total_volume) OVER (), 2)             AS [Diff from Bank Avg (RM)],

    -- ── SEGMENT BENCHMARKS ───────────────────────────────────
    ROUND(AVG(total_volume) OVER
        (PARTITION BY segment), 2)                  AS [Segment Avg Volume (RM)],
    CASE
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment) * 1.5
                                                    THEN 'Top Performer'
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment)
                                                    THEN 'Above Segment Avg'
        WHEN total_volume > AVG(total_volume) OVER (PARTITION BY segment) * 0.5
                                                    THEN 'Below Segment Avg'
        ELSE                                             'Low Performer'
    END                                             AS [Performance vs Segment],

    -- ── RANKING ──────────────────────────────────────────────
    RANK() OVER (ORDER BY total_volume DESC)        AS [Overall Rank],
    RANK() OVER (
        PARTITION BY segment
        ORDER BY total_volume DESC)                 AS [Rank Within Segment]

FROM customer_kpis
ORDER BY total_volume DESC;
