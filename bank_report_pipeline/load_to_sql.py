# load_to_sql.py
# Run this ONCE to load CSV data into SQL Server
# After this, run_pipeline.py will work fully

import pandas as pd
from sqlalchemy import create_engine

# ── UPDATE THIS with your actual SQL Server details ──────────
SERVER   = "LAPTOP-8EN32KFS"   # e.g. DESKTOP-ABC123\SQLEXPRESS
DATABASE = "databank"
DRIVER   = "ODBC Driver 17 for SQL Server"

CONNECTION_STRING = (
    f"mssql+pyodbc://@{SERVER}/{DATABASE}"
    f"?driver={DRIVER}&trusted_connection=yes"
)
# If using username/password instead of Windows auth:
# CONNECTION_STRING = f"mssql+pyodbc://user:password@{SERVER}/{DATABASE}?driver={DRIVER}"
# ─────────────────────────────────────────────────────────────

engine = create_engine(CONNECTION_STRING)

# Load CSVs
print("Loading transactions...")
txn = pd.read_csv(r"C:\Users\user\Downloads\customer analysis\bank_report_pipeline\data\transactions.csv")
txn.to_sql("fact_transactions", engine, schema="bank",
           if_exists="replace", index=False)
print(f"  {len(txn)} rows loaded into bank.fact_transactions")

print("Loading customers...")
cust  = pd.read_csv(r"C:\Users\user\Downloads\customer analysis\bank_report_pipeline\data\customers.csv")
cust.to_sql("dim_customers", engine, schema="bank",
            if_exists="replace", index=False)
print(f"  {len(cust)} rows loaded into bank.dim_customers")

print("\nDone. Run python run_pipeline.py now.")