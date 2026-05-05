"""
pipeline.py
ETL + analysis pipeline for bank transaction data.
Reads raw CSV → cleans → runs analysis → returns structured summary dict.
"""

import pandas as pd
import numpy as np
from datetime import datetime
import os


# ── 1. EXTRACT ────────────────────────────────────────────────────────────────

from sqlalchemy import create_engine

def extract(connection_string: str):
    engine = create_engine(connection_string)

    txn = pd.read_sql("""
        SELECT *
        FROM bank.fact_transactions
        WHERE [status] != 'Failed'
          AND [date] >= '2024-01-01'
          AND [date] <= '2024-12-31'
    """, engine, parse_dates=["date"])

    cust = pd.read_sql("SELECT * FROM bank.dim_customers", engine,
                       parse_dates=["join_date"])

    print(f"Extracted {len(txn)} transactions from SQL.")
    return txn, cust


# ── 2. TRANSFORM / CLEAN ──────────────────────────────────────────────────────

def transform(txn: pd.DataFrame, cust: pd.DataFrame) -> pd.DataFrame:
    # Drop failed transactions from revenue analysis
    df = txn[txn["status"] != "Failed"].copy()

    # Enrich with time dimensions
    df["month"]        = df["date"].dt.to_period("M")
    df["month_str"]    = df["date"].dt.strftime("%b %Y")
    df["quarter"]      = df["date"].dt.to_period("Q").astype(str)
    df["week"]         = df["date"].dt.isocalendar().week

    # Flag anomaly: transactions > 3 std dev from segment mean
    seg_stats          = df.groupby("segment")["amount"].agg(["mean", "std"]).reset_index()
    df                 = df.merge(seg_stats, on="segment")
    df["is_anomaly"]   = df["amount"] > (df["mean"] + 3 * df["std"])
    df.drop(columns=["mean", "std"], inplace=True)

    return df


# ── 3. ANALYSE ────────────────────────────────────────────────────────────────

def analyse(df: pd.DataFrame) -> dict:
    results = {}

    # KPI Summary
    results["kpi"] = {
        "total_transactions":  int(len(df)),
        "total_volume":        round(df["amount"].sum(), 2),
        "avg_transaction":     round(df["amount"].mean(), 2),
        "unique_customers":    int(df["customer_id"].nunique()),
        "anomalies_flagged":   int(df["is_anomaly"].sum()),
        "report_date":         datetime.today().strftime("%d %B %Y"),#Day Month Year
    }

    # Monthly volume trend
    monthly = (
        df.groupby("month_str")
        .agg(transactions=("amount", "count"), volume=("amount", "sum"))
        .reset_index()
    )
    monthly["month_dt"]   = pd.to_datetime(monthly["month_str"], format="%b %Y")
    monthly               = monthly.sort_values("month_dt").drop(columns="month_dt")
    monthly["volume"]     = monthly["volume"].round(2)
    results["monthly"]    = monthly

    # By branch
    branch = (
        df.groupby("branch")
        .agg(transactions=("amount", "count"), volume=("amount", "sum"), customers=("customer_id", "nunique"))
        .reset_index()
        .sort_values("volume", ascending=False)
    )
    branch["volume"]      = branch["volume"].round(2)
    branch["avg_txn"]     = (branch["volume"] / branch["transactions"]).round(2)
    results["branch"]     = branch

    # By transaction type
    by_type = (
        df.groupby("transaction_type")
        .agg(transactions=("amount", "count"), volume=("amount", "sum"))
        .reset_index()
        .sort_values("volume", ascending=False)
    )
    by_type["volume"]     = by_type["volume"].round(2)
    by_type["share_pct"]  = (by_type["volume"] / by_type["volume"].sum() * 100).round(1)
    results["by_type"]    = by_type

    # By product
    by_product = (
        df.groupby("product")
        .agg(transactions=("amount", "count"), volume=("amount", "sum"))
        .reset_index()
        .sort_values("volume", ascending=False)
    )
    by_product["volume"]  = by_product["volume"].round(2)
    results["by_product"] = by_product

    # Customer segment analysis
    by_segment = (
        df.groupby("segment")
        .agg(transactions=("amount", "count"), volume=("amount", "sum"), customers=("customer_id", "nunique"))
        .reset_index()
    )
    by_segment["volume"]     = by_segment["volume"].round(2)
    by_segment["avg_per_cust"] = (by_segment["volume"] / by_segment["customers"]).round(2)
    results["by_segment"]   = by_segment

    # Top 10 customers by volume
    top_cust = (
        df.groupby("customer_id")
        .agg(transactions=("amount", "count"), total_volume=("amount", "sum"))
        .reset_index()
        .sort_values("total_volume", ascending=False)
        .head(10)
    )
    top_cust["total_volume"] = top_cust["total_volume"].round(2)
    results["top_customers"] = top_cust

    # Anomalies
    anomalies = df[df["is_anomaly"]].sort_values("amount", ascending=False)[
        ["transaction_id", "date", "customer_id", "segment", "branch", "transaction_type", "amount"]
    ].head(20).copy()
    anomalies["date"] = anomalies["date"].dt.strftime("%d/%m/%Y")
    anomalies["amount"] = anomalies["amount"].round(2)
    results["anomalies"] = anomalies

    return results
