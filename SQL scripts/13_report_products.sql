-- =============================================================
-- Script  : 13_report_products.sql
-- Purpose : Consolidate key product metrics and behaviours
--           tailored for banking analytics (Customer context).
--           Products = bank products (Savings, Credit Card, etc.)
--           Segments products by revenue performance and
--           calculates banking-specific product KPIs.
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO

-- =============================================================
-- FINAL PRODUCT REPORT VIEW
-- =============================================================

WITH

-- -------------------------------------------------------------
-- BASE: Core product transaction aggregates
-- -------------------------------------------------------------
product_base AS (
    SELECT
        product,

        -- Transaction volume metrics
        COUNT(transaction_id)                       AS total_transactions,
        SUM(amount)                                 AS total_revenue,
        AVG(amount)                                 AS avg_transaction_value,
        MIN(amount)                                 AS min_transaction,
        MAX(amount)                                 AS max_transaction,

        -- Customer reach
        COUNT(DISTINCT customer_id)                 AS total_unique_customers,
        COUNT(DISTINCT branch)                      AS branches_active,
        COUNT(DISTINCT segment)                     AS segments_served,

        -- Transaction type diversity within product
        COUNT(DISTINCT transaction_type)            AS txn_types_used,

        -- Time boundaries
        MIN([date])                                 AS first_sale_date,
        MAX([date])                                 AS last_sale_date,

        -- Anomaly exposure
        SUM(CAST(is_anomaly AS INT))                AS anomaly_count,

        -- Status breakdown
        SUM(CASE WHEN [status] = 'Completed' THEN 1 ELSE 0 END)
                                                    AS completed_txns,
        SUM(CASE WHEN [status] = 'Pending'   THEN 1 ELSE 0 END)
                                                    AS pending_txns,
        SUM(CASE WHEN [status] = 'Failed'    THEN 1 ELSE 0 END)
                                                    AS failed_txns

    FROM bank.fact_transactions
    GROUP BY product
),

-- -------------------------------------------------------------
-- KPI CALCULATIONS
-- -------------------------------------------------------------
product_kpis AS (
    SELECT
        product,
        total_transactions,
        total_revenue,
        avg_transaction_value,
        min_transaction,
        max_transaction,
        total_unique_customers,
        branches_active,
        segments_served,
        txn_types_used,
        first_sale_date,
        last_sale_date,
        anomaly_count,
        completed_txns,
        pending_txns,
        failed_txns,

        -- Lifespan: months from first to last transaction
        DATEDIFF(MONTH, first_sale_date, last_sale_date)
                                                    AS lifespan_months,

        -- Recency: months since last transaction on this product
        DATEDIFF(MONTH, last_sale_date, GETDATE())
                                                    AS recency_months,

        -- Average Order Revenue (AOR): revenue per transaction
        ROUND(total_revenue / NULLIF(total_transactions, 0), 2)
                                                    AS avg_order_revenue,

        -- Average Monthly Revenue
        CASE
            WHEN DATEDIFF(MONTH, first_sale_date, last_sale_date) = 0
            THEN total_revenue
            ELSE ROUND(total_revenue /
                 DATEDIFF(MONTH, first_sale_date, last_sale_date), 2)
        END                                         AS avg_monthly_revenue,

        -- Revenue per customer
        ROUND(total_revenue / NULLIF(total_unique_customers, 0), 2)
                                                    AS revenue_per_customer,

        -- Transaction success rate
        ROUND(
            completed_txns * 100.0
            / NULLIF(total_transactions, 0)
        , 2)                                        AS completion_rate_pct

    FROM product_base
)

-- =============================================================
-- FINAL SELECT — with segmentation and all KPIs
-- =============================================================
SELECT

    -- ── IDENTIFIERS ──────────────────────────────────────────
    product                                         AS [Product],

    -- ── PRODUCT PERFORMANCE TIER ─────────────────────────────
    -- Segment by total revenue contribution
    CASE
        WHEN total_revenue >= SUM(total_revenue) OVER () * 0.25
                                                    THEN 'High Performer'
        WHEN total_revenue >= SUM(total_revenue) OVER () * 0.10
                                                    THEN 'Mid-Range'
        ELSE                                             'Low Performer'
    END                                             AS [Performance Tier],

    -- ── PRODUCT ADOPTION BAND ────────────────────────────────
    CASE
        WHEN total_unique_customers >= 100          THEN 'Widely Adopted'
        WHEN total_unique_customers >= 50           THEN 'Moderately Adopted'
        WHEN total_unique_customers >= 20           THEN 'Niche'
        ELSE                                             'Low Adoption'
    END                                             AS [Adoption Band],

    -- ── PRODUCT HEALTH STATUS ────────────────────────────────
    CASE
        WHEN recency_months = 0
         AND completion_rate_pct >= 90              THEN 'Healthy'
        WHEN recency_months <= 1
         AND completion_rate_pct >= 75              THEN 'Active'
        WHEN completion_rate_pct < 60               THEN 'High Failure Rate'
        ELSE                                             'Monitor'
    END                                             AS [Product Health],

    -- ── TRANSACTION METRICS ──────────────────────────────────
    total_transactions                              AS [Total Transactions],
    completed_txns                                  AS [Completed],
    pending_txns                                    AS [Pending],
    failed_txns                                     AS [Failed],
    ROUND(completion_rate_pct, 2)                   AS [Completion Rate (%)],

    -- ── CUSTOMER REACH ───────────────────────────────────────
    total_unique_customers                          AS [Unique Customers],
    branches_active                                 AS [Branches Active],
    segments_served                                 AS [Segments Served],

    -- ── TIME METRICS ─────────────────────────────────────────
    first_sale_date                                 AS [First Transaction Date],
    last_sale_date                                  AS [Last Transaction Date],
    lifespan_months                                 AS [Lifespan (Months)],
    recency_months                                  AS [Recency (Months Since Last Txn)],

    -- ── REVENUE METRICS ──────────────────────────────────────
    ROUND(total_revenue, 2)                         AS [Total Revenue (RM)],
    ROUND(min_transaction, 2)                       AS [Min Transaction (RM)],
    ROUND(max_transaction, 2)                       AS [Max Transaction (RM)],

    -- ── KPIs ─────────────────────────────────────────────────
    ROUND(avg_order_revenue, 2)                     AS [Avg Order Revenue / AOR (RM)],
    ROUND(avg_monthly_revenue, 2)                   AS [Avg Monthly Revenue (RM)],
    ROUND(revenue_per_customer, 2)                  AS [Revenue per Customer (RM)],

    -- ── RISK INDICATOR ───────────────────────────────────────
    anomaly_count                                   AS [Anomaly Transactions],
    CASE
        WHEN anomaly_count >= 10                    THEN 'High Risk'
        WHEN anomaly_count >= 5                     THEN 'Monitor'
        ELSE                                             'Clean'
    END                                             AS [Risk Flag],

    -- ── BANK-WIDE BENCHMARKS ─────────────────────────────────
    ROUND(SUM(total_revenue) OVER (), 2)            AS [Total Bank Revenue (RM)],
    ROUND(
        total_revenue / SUM(total_revenue) OVER () * 100
    , 2)                                            AS [Revenue Share (%)],
    ROUND(AVG(total_revenue) OVER (), 2)            AS [Bank Avg Product Revenue (RM)],
    ROUND(AVG(avg_monthly_revenue) OVER (), 2)      AS [Bank Avg Monthly Revenue (RM)],

    -- ── RANKING ──────────────────────────────────────────────
    RANK() OVER (ORDER BY total_revenue DESC)       AS [Revenue Rank],
    RANK() OVER (ORDER BY total_unique_customers DESC)
                                                    AS [Adoption Rank],
    RANK() OVER (ORDER BY avg_order_revenue DESC)   AS [AOR Rank]

FROM product_kpis
ORDER BY total_revenue DESC;
