-- =============================================================
-- Script  : 01_database_exploration.sql
-- Purpose : Explore the structure of the databank database.
--           Lists all tables, schemas, column metadata, row
--           counts and data types for quick orientation.
-- Author  : Business Data Analyst
-- =============================================================

USE databank;
GO


-- -------------------------------------------------------------
-- 1. List all tables in the database
-- -------------------------------------------------------------

SELECT
    TABLE_SCHEMA            AS [Schema],
    TABLE_NAME              AS [Table],
    TABLE_TYPE              AS [Type]
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_SCHEMA, TABLE_NAME;


-- -------------------------------------------------------------
-- 2. List all columns and data types for every table
-- -------------------------------------------------------------

SELECT
    TABLE_SCHEMA            AS [Schema],
    TABLE_NAME              AS [Table],
    COLUMN_NAME             AS [Column],
    ORDINAL_POSITION        AS [Position],
    DATA_TYPE               AS [Data Type],
    CHARACTER_MAXIMUM_LENGTH AS [Max Length],
    IS_NULLABLE             AS [Nullable],
    COLUMN_DEFAULT          AS [Default]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bank'
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- -------------------------------------------------------------
-- 3. Inspect columns for FACT table specifically
-- -------------------------------------------------------------

SELECT
    COLUMN_NAME             AS [Column],
    DATA_TYPE               AS [Data Type],
    CHARACTER_MAXIMUM_LENGTH AS [Max Length],
    IS_NULLABLE             AS [Nullable]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bank'
  AND TABLE_NAME   = 'fact_transactions'
ORDER BY ORDINAL_POSITION;


-- -------------------------------------------------------------
-- 4. Inspect columns for DIMENSION tables
-- -------------------------------------------------------------

SELECT
    TABLE_NAME              AS [Table],
    COLUMN_NAME             AS [Column],
    DATA_TYPE               AS [Data Type],
    IS_NULLABLE             AS [Nullable]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'bank'
  AND TABLE_NAME IN ('dim_customers', 'dim_date', 'dim_product', 'dim_branch')
ORDER BY TABLE_NAME, ORDINAL_POSITION;


-- -------------------------------------------------------------
-- 5. Row counts for all tables
-- -------------------------------------------------------------

SELECT
    t.TABLE_SCHEMA          AS [Schema],
    t.TABLE_NAME            AS [Table],
    p.rows                  AS [Row Count]
FROM INFORMATION_SCHEMA.TABLES t
JOIN sys.partitions p
    ON p.object_id = OBJECT_ID(t.TABLE_SCHEMA + '.' + t.TABLE_NAME)
    AND p.index_id IN (0, 1)
WHERE t.TABLE_SCHEMA = 'bank'
ORDER BY p.rows DESC;


-- -------------------------------------------------------------
-- 6. List all primary and foreign key constraints
-- -------------------------------------------------------------

SELECT
    tc.TABLE_NAME           AS [Table],
    tc.CONSTRAINT_NAME      AS [Constraint Name],
    tc.CONSTRAINT_TYPE      AS [Type],
    kcu.COLUMN_NAME         AS [Column],
    ccu.TABLE_NAME          AS [Referenced Table],
    ccu.COLUMN_NAME         AS [Referenced Column]
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
    ON tc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu
    ON tc.CONSTRAINT_NAME = ccu.CONSTRAINT_NAME
WHERE tc.TABLE_SCHEMA = 'bank'
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;
