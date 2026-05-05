-- =============================================================
-- Script  : 00_init_database.sql
-- Purpose : Initialize the DataBank database from scratch.
--           Drops and recreates the database, schema, and all
--           tables (fact + dimension) for the transaction pipeline.
-- Author  : Business Data Analyst
-- =============================================================


-- -------------------------------------------------------------
-- STEP 1: Drop and recreate the database
-- -------------------------------------------------------------

USE master;
GO

-- Drop existing database if it exists
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'databank')
BEGIN
    ALTER DATABASE databank SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE databank;
    PRINT 'Existing databank database dropped.';
END

-- Create fresh database
CREATE DATABASE databank;
PRINT 'databank database created.';
GO

USE databank;
GO


-- -------------------------------------------------------------
-- STEP 2: Create schema
-- -------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'bank')
BEGIN
    EXEC('CREATE SCHEMA bank');
    PRINT 'Schema [bank] created.';
END
GO


-- -------------------------------------------------------------
-- STEP 3: Create DIMENSION tables
-- -------------------------------------------------------------

-- DIM: Customers
-- Stores customer profile and segmentation data
CREATE TABLE bank.dim_customers (
    customer_id     VARCHAR(20)     NOT NULL,
    segment         VARCHAR(30)     NOT NULL,   -- Retail, SME, Wealth Management
    branch          VARCHAR(50)     NOT NULL,
    join_date       DATE            NOT NULL,
    CONSTRAINT PK_dim_customers PRIMARY KEY (customer_id)
);
PRINT 'Table bank.dim_customers created.';

-- DIM: Date
-- Pre-populated date dimension for time-based analysis
CREATE TABLE bank.dim_date (
    date_id         INT             NOT NULL,   -- YYYYMMDD format
    full_date       DATE            NOT NULL,
    day_of_week     VARCHAR(10)     NOT NULL,
    day_num         TINYINT         NOT NULL,
    week_num        TINYINT         NOT NULL,
    month_num       TINYINT         NOT NULL,
    month_name      VARCHAR(10)     NOT NULL,
    quarter         TINYINT         NOT NULL,
    year            SMALLINT        NOT NULL,
    is_weekend      BIT             NOT NULL DEFAULT 0,
    CONSTRAINT PK_dim_date PRIMARY KEY (date_id)
);
PRINT 'Table bank.dim_date created.';

-- DIM: Product
CREATE TABLE bank.dim_product (
    product_id      INT             NOT NULL IDENTITY(1,1),
    product_name    VARCHAR(50)     NOT NULL,   -- Savings Account, Credit Card, etc.
    CONSTRAINT PK_dim_product PRIMARY KEY (product_id)
);
PRINT 'Table bank.dim_product created.';

-- DIM: Branch
CREATE TABLE bank.dim_branch (
    branch_id       INT             NOT NULL IDENTITY(1,1),
    branch_name     VARCHAR(50)     NOT NULL,
    region          VARCHAR(30)     NULL,
    CONSTRAINT PK_dim_branch PRIMARY KEY (branch_id)
);
PRINT 'Table bank.dim_branch created.';


-- -------------------------------------------------------------
-- STEP 4: Create FACT table
-- -------------------------------------------------------------

-- FACT: Transactions
-- Central fact table — one row per transaction
CREATE TABLE bank.fact_transactions (
    transaction_id      VARCHAR(20)     NOT NULL,
    [date]              DATE            NOT NULL,
    customer_id         VARCHAR(20)     NOT NULL,
    segment             VARCHAR(30)     NOT NULL,
    branch              VARCHAR(50)     NOT NULL,
    product             VARCHAR(50)     NOT NULL,
    transaction_type    VARCHAR(30)     NOT NULL,   -- Deposit, Withdrawal, Transfer, etc.
    category            VARCHAR(50)     NOT NULL,
    amount              DECIMAL(15,2)   NOT NULL,
    [status]            VARCHAR(20)     NOT NULL,   -- Completed, Pending, Failed
    is_anomaly          BIT             NOT NULL DEFAULT 0,
    load_date           DATETIME        NOT NULL DEFAULT GETDATE(),
    CONSTRAINT PK_fact_transactions PRIMARY KEY (transaction_id),
    CONSTRAINT FK_fact_customers    FOREIGN KEY (customer_id)
        REFERENCES bank.dim_customers (customer_id)
);
PRINT 'Table bank.fact_transactions created.';
GO


-- -------------------------------------------------------------
-- STEP 5: Create indexes for query performance
-- -------------------------------------------------------------

CREATE INDEX IX_fact_transactions_date
    ON bank.fact_transactions ([date]);

CREATE INDEX IX_fact_transactions_customer
    ON bank.fact_transactions (customer_id);

CREATE INDEX IX_fact_transactions_branch
    ON bank.fact_transactions (branch);

CREATE INDEX IX_fact_transactions_status
    ON bank.fact_transactions ([status]);

PRINT 'Indexes created.';
GO

PRINT '================================================';
PRINT ' databank database initialized successfully.';
PRINT '================================================';
