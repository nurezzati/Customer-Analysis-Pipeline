# Automated Customer Transaction Analytics Pipeline

> A full end-to-end data analytics pipeline that automates the extraction, transformation, analysis, and reporting of bank transaction data — built as a personal project to mirror real-world banking analytics workflows.

---

## Project Overview

In a typical banking environment, analysts spend hours every week manually pulling data, cleaning it in Excel, and rebuilding the same report from scratch. This project eliminates that process entirely.

The pipeline ingests raw transaction and customer data from a SQL Server database, runs a full suite of SQL-based analytical queries, applies statistical analysis in Python, and automatically generates a professionally formatted multi-sheet Excel report — all triggered by a single command.

---

## Business Problem

**Audience:** Bank management, branch managers, business analysts, and compliance teams.

**Key Questions:**
- Which branches are driving the most transaction volume?
- Which customer segments and products are most valuable?
- How is monthly transaction volume trending — are we growing or declining?
- Which transactions are statistical outliers that require compliance review?
- Who are the top customers and how do they compare against their segment peers?

**Role:** End-to-end data analyst — responsible for database design, ETL pipeline, statistical analysis, and automated report delivery.

---

## Goals & Objectives

| Objective | Connected Business Decision |
|---|---|
| Automate weekly transaction reporting | Eliminate 2–3 hours of manual analyst work per week |
| Track MoM volume growth per branch | Identify underperforming branches for management action |
| Segment customers into tiers (VIP, Premium, Regular) | Prioritise relationship management and cross-sell campaigns |
| Flag statistical anomalies (>3σ) | Feed compliance team a ready-made watchlist |
| Calculate avg monthly spend per customer | Input for customer retention and churn prevention strategy |
| Rank products by revenue and adoption | Guide product development and marketing investment |

---

## Tech Stack

| Tool | Purpose |
|---|---|
| **Python** | ETL pipeline, anomaly detection, Excel report generation |
| **SQL Server** | Data storage, analytical queries, KPI calculation |
| **pandas** | Data cleaning, transformation, and analysis |
| **openpyxl** | Automated Excel report building with charts and formatting |
| **SQLAlchemy + pyodbc** | SQL Server connection and data extraction |
| **numpy** | Statistical calculations (z-score anomaly detection) |

---

## Project Structure

```
bank_report_pipeline/
├── data/
│   ├── transactions.csv          # Raw transaction data
│   └── customers.csv             # Customer profile data
├── output/
│   └── Maybank_Transaction_Report_YYYYMMDD.xlsx
├── scripts/
│   ├── generate_data.py          # Synthetic data generator (dev/testing)
│   ├── pipeline.py               # ETL + statistical analysis logic
│   ├── report_generator.py       # Automated Excel report builder
│   └── test.py                   # Data validation tests
├── sql/
│   ├── 00_init_database.sql      # Database, schema, fact & dim tables
│   ├── 01_database_exploration.sql
│   ├── 02_dimensions_exploration.sql
│   ├── 03_date_range_exploration.sql
│   ├── 04_measures_exploration.sql
│   ├── 05_magnitude_analysis.sql
│   ├── 06_ranking_analysis.sql
│   ├── 07_change_over_time_analysis.sql
│   ├── 08_cumulative_analysis.sql
│   ├── 09_performance_analysis.sql
│   ├── 10_data_segmentation_analysis.sql
│   ├── 11_part_to_whole_analysis.sql
│   ├── 12_report_customers.sql
│   └── 13_report_products.sql
├── load_to_sql.py                # One-time CSV → SQL Server loader
└── run_pipeline.py               # Main entry point
```

---

## SQL Analytics Layer (13 Scripts)

The SQL layer follows a structured analytical workflow — from raw data profiling through to production-ready reports.

| # | Script | Purpose | Key Functions |
|---|---|---|---|
| 00 | Init Database | Creates DB, schema, fact & dim tables, indexes | `CREATE TABLE`, `FOREIGN KEY` |
| 01 | Database Exploration | Tables, columns, data types, row counts | `INFORMATION_SCHEMA` |
| 02 | Dimensions Exploration | Unique values across all dimensions | `DISTINCT`, `ORDER BY` |
| 03 | Date Range Exploration | Temporal boundaries, data gaps, customer tenure | `MIN()`, `MAX()`, `DATEDIFF()` |
| 04 | Measures Exploration | Top-level KPIs and aggregated metrics | `COUNT()`, `SUM()`, `AVG()` |
| 05 | Magnitude Analysis | Volume distribution across branches, segments, products | `GROUP BY`, amount buckets via `CASE` |
| 06 | Ranking Analysis | Top/bottom performers globally and within segments | `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()` |
| 07 | Change Over Time | Monthly/quarterly trends, MoM growth, seasonality | `DATEPART()`, `FORMAT()`, `LAG()` |
| 08 | Cumulative Analysis | Running totals, 3/6-month moving averages | `SUM() OVER()`, `AVG() OVER()` |
| 09 | Performance Analysis | YoY/MoM benchmarking, trend flags | `LAG()`, `AVG() OVER()`, `CASE` |
| 10 | Data Segmentation | RFM segmentation, risk tiers, tenure bands | `CASE`, `GROUP BY` |
| 11 | Part-to-Whole | Revenue share % by branch, segment, product | `SUM() OVER()` as denominator |
| 12 | Customer Report | Full customer KPI report — recency, lifespan, avg monthly spend, tier | Multi-layer CTEs |
| 13 | Product Report | Full product KPI report — AOR, adoption rate, health status | Multi-layer CTEs |

---

## Python Pipeline

The Python layer handles automation — it connects to SQL Server, applies statistical logic, and produces the Excel report.

**pipeline.py — 3 stages:**

```
EXTRACT  →  Read from SQL Server (or CSV) using SQLAlchemy
TRANSFORM →  Clean data, enrich with time dimensions, flag anomalies
ANALYSE  →  Run 6 analyses: monthly, branch, type, product, segment, top customers
```

**Anomaly Detection Logic:**
Transactions are flagged if they exceed 3 standard deviations above the segment mean — calculated separately for Retail, SME, and Wealth Management to ensure fair comparison.

```python
# Core anomaly detection
df["is_anomaly"] = df["amount"] > (df["mean"] + 3 * df["std"])
```

---

## Excel Report Output

The automated report contains **8 sheets**:

| Sheet | Contents |
|---|---|
| **Monthly Trend** | Month-by-month table + MoM % change + bar chart |
| **Branch Analysis** | Volume, customers, avg transaction by branch + bar chart |
| **Transaction Breakdown** | By type and product with pie chart |
| **Segment Analysis** | Retail vs SME vs Wealth Management + grouped bar chart |
| **Top Customers** | Top 10 ranked with gold/silver/bronze styling |
| **Anomaly Report** | 75 flagged transactions highlighted in red for compliance review |

---

## Key KPIs Tracked

- **Month-on-Month (MoM) Growth Rate** — using `LAG()` window function
- **Average Transaction Value (ATV)** — total volume / transaction count
- **Average Monthly Spend** — proxy for Customer Lifetime Value
- **Recency** — months since last transaction (churn indicator)
- **Transaction Completion Rate** — operational health metric
- **Revenue Share (%)** — part-to-whole using `SUM() OVER()`
- **RFM Segmentation Score** — Champion, Loyal, At Risk, Lost
- **Anomaly Rate** — % of transactions beyond 3σ threshold
- **Cumulative YTD Volume** — running total using `ROWS UNBOUNDED PRECEDING`
- **Performance vs Segment Benchmark** — `PARTITION BY` segment average

---

## How to Run

**1. Install dependencies**
```bash
pip install pandas openpyxl sqlalchemy pyodbc numpy faker
```

**2. Configure your SQL Server connection in `run_pipeline.py`**
```python
CONNECTION_STRING = (
    "mssql+pyodbc://@YOUR_SERVER/databank"
    "?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
)
```

**3. Initialise the database**

Run `sql/00_init_database.sql` in SQL Server Management Studio (SSMS).

**4. Load data into SQL Server**
```bash
python load_to_sql.py
```

**5. Run the full pipeline**
```bash
python run_pipeline.py
```

Report is saved to `output/Maybank_Transaction_Report_YYYYMMDD.xlsx`.

**6. Run data validation tests**
```bash
python scripts/test.py
```

**Optional — Schedule weekly (Windows Task Scheduler)**
```
Action  : python C:\path\to\run_pipeline.py
Trigger : Weekly, Monday 8:00 AM
```

---

## Insights from the Data

**1. Anomaly concentration**
75 out of 4,853 transactions (1.5%) were flagged as statistical outliers — but these transactions represented a disproportionately high share of total volume, highlighting why compliance monitoring cannot rely on manual review alone.

**2. Segment value gap**
Wealth Management customers were significantly fewer in number than Retail customers but generated a much higher average transaction value per customer — confirming that segment-aware benchmarking is essential. A single Wealth customer lost is not equivalent to a single Retail customer lost.

**3. Seasonal patterns**
Monthly trend analysis revealed clear peak and low months across the year. The pipeline automatically classifies each month as Peak (>120% of annual average), Normal, or Low (<80%) — enabling proactive staffing and liquidity decisions rather than reactive ones.

---

## Business Impact

| Impact Area | Result |
|---|---|
| **Time saved** | 2–3 hours of manual weekly reporting eliminated |
| **Consistency** | Same KPI definitions applied every run — no human variation |
| **Compliance** | Automated anomaly watchlist delivered alongside the business report |
| **Scalability** | Pipeline handles 5,000 rows today — same code works on 5 million |
| **Auditability** | All SQL logic is version-controlled and readable by any analyst |
| **Decision speed** | Management receives insights Monday morning without any manual trigger |

---

## What I Would Add in Production

- Direct SQL Server scheduled job to replace manual pipeline trigger
- Email delivery of report via `smtplib` automatically after generation
- Historical report archiving for year-on-year comparison
- Power BI dashboard layer connected to the same SQL views
- Unit tests for each analytical function in `pipeline.py`

---

## Author

Built as a personal portfolio project to demonstrate end-to-end banking data analytics skills — covering database design, SQL analytics, Python automation, statistical analysis, and business reporting.
