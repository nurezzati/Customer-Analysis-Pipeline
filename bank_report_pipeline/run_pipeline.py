"""
run_pipeline.py
Main entry point — run this script to generate the full report.
Usage: python run_pipeline.py
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "scripts"))

from pipeline import extract, transform, analyse
from report_generator import generate_report
from datetime import datetime

OUTPUT_DIR = "output"
DATA_DIR   = "data"

def main():
    print("=" * 55)
    print("  CUSTOMER TRANSACTION REPORT PIPELINE")
    print("=" * 55)

    # Step 1: Extract
    print("\n[2/4] Extracting data from SQL...")
    connection_string = f"mssql+pyodbc://@LAPTOP-8EN32KFS/databank?driver=ODBC+Driver+17+for+SQL+Server&trusted_connection=yes"
    txn, cust = extract(connection_string)
    print(f"      Loaded {len(txn)} rows.")

    # Step 2: Transform & Analyse
    print("\n[3/4] Cleaning, transforming, and analysing...")
    df      = transform(txn, cust)
    results = analyse(df)
    kpi     = results["kpi"]
    print(f"      Total volume    : RM {kpi['total_volume']:,.2f}")
    print(f"      Transactions    : {kpi['total_transactions']:,}")
    print(f"      Unique customers: {kpi['unique_customers']:,}")
    print(f"      Anomalies found : {kpi['anomalies_flagged']}")

    # Step 3: Generate Excel Report
    print("\n[4/4] Building Excel report...")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    timestamp   = datetime.today().strftime("%Y%m%d")
    output_path = f"{OUTPUT_DIR}/Customer_Transaction_Report_{timestamp}.xlsx"
    generate_report(results, output_path)

    print("\n" + "=" * 55)
    print("  PIPELINE COMPLETE")
    print(f"  Report: {output_path}")
    print("=" * 55)

if __name__ == "__main__":
    main()
