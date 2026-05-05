"""
generate_data.py
Generates a realistic synthetic bank transaction dataset and saves to CSV.
Run once to create sample data, or replace with a real data source.
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import random

random.seed(42)
np.random.seed(42)

BRANCHES = ["Kuala Lumpur", "Petaling Jaya", "Penang", "Johor Bahru", "Ipoh"]
PRODUCTS = ["Savings Account", "Current Account", "Fixed Deposit", "Credit Card", "Personal Loan"]
TRANSACTION_TYPES = ["Deposit", "Withdrawal", "Transfer", "Payment", "Loan Repayment"]
CATEGORIES = {
    "Deposit":       ["Salary Credit", "Cash Deposit", "Online Transfer In"],
    "Withdrawal":    ["ATM Withdrawal", "Cash Withdrawal"],
    "Transfer":      ["IBG Transfer", "DuitNow Transfer", "Interbank Transfer"],
    "Payment":       ["Bill Payment", "Merchant Payment", "E-wallet Top Up"],
    "Loan Repayment":["Home Loan", "Car Loan", "Personal Loan"],
}

CUSTOMER_SEGMENTS = ["Retail", "SME", "Wealth Management"]

def random_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))

def generate_customers(n=200):
    rows = []
    for i in range(1, n + 1):
        rows.append({
            "customer_id": f"CUS{i:04d}",
            "segment":     random.choice(CUSTOMER_SEGMENTS),
            "branch":      random.choice(BRANCHES),
            "join_date":   random_date(datetime(2018, 1, 1), datetime(2023, 12, 31)).date(),
        })
    return pd.DataFrame(rows)

def generate_transactions(customers, n=5000):
    start = datetime(2024, 1, 1)
    end   = datetime(2024, 12, 31)
    rows  = []
    for i in range(1, n + 1):
        cust      = customers.sample(1).iloc[0]
        txn_type  = random.choice(TRANSACTION_TYPES)
        category  = random.choice(CATEGORIES[txn_type])
        # Wealth customers transact more
        amt_scale = 5 if cust["segment"] == "Wealth Management" else (2 if cust["segment"] == "SME" else 1)
        amount    = round(np.random.lognormal(mean=7, sigma=1.5) * amt_scale, 2)
        amount    = min(amount, 500_000)
        rows.append({
            "transaction_id":   f"TXN{i:06d}",
            "date":             random_date(start, end).date(),
            "customer_id":      cust["customer_id"],
            "segment":          cust["segment"],
            "branch":           cust["branch"],
            "product":          random.choice(PRODUCTS),
            "transaction_type": txn_type,
            "category":         category,
            "amount":           amount,
            "status":           random.choices(["Completed", "Pending", "Failed"], weights=[90, 7, 3])[0],
        })
    return pd.DataFrame(rows)

if __name__ == "__main__":
    customers    = generate_customers(200)
    transactions = generate_transactions(customers, 5000)
    transactions.to_csv("data/transactions.csv", index=False)
    customers.to_csv("data/customers.csv", index=False)
    print(f"Generated {len(transactions)} transactions for {len(customers)} customers.")
    print(f"Date range: {transactions['date'].min()} to {transactions['date'].max()}")
