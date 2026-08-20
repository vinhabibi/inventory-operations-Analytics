-- Raw schema: mirrors the CSVs exactly, no cleaning applied here.
-- This is the "landing zone" — dbt staging models will clean this up.

CREATE SCHEMA IF NOT EXISTS raw;

DROP TABLE IF EXISTS raw.dim_date CASCADE;
CREATE TABLE raw.dim_date (
    date_key     INT,
    full_date    DATE,
    year         INT,
    quarter      INT,
    month        INT,
    month_name   TEXT,
    week         INT,
    day_of_week  TEXT,
    is_weekend   BOOLEAN
);

DROP TABLE IF EXISTS raw.dim_warehouse CASCADE;
CREATE TABLE raw.dim_warehouse (
    warehouse_key   INT,
    warehouse_name  TEXT,
    region          TEXT,
    city            TEXT,
    capacity        INT
);

DROP TABLE IF EXISTS raw.dim_supplier CASCADE;
CREATE TABLE raw.dim_supplier (
    supplier_key    INT,
    supplier_name   TEXT,
    country         TEXT,
    lead_time_days  INT
);

DROP TABLE IF EXISTS raw.dim_product CASCADE;
CREATE TABLE raw.dim_product (
    product_key    INT,
    sku            TEXT,
    product_name   TEXT,
    category       TEXT,
    subcategory    TEXT,
    unit_cost      NUMERIC(10,2),
    unit_price     NUMERIC(10,2),
    reorder_point  INT
);

DROP TABLE IF EXISTS raw.dim_movement_type CASCADE;
CREATE TABLE raw.dim_movement_type (
    movement_type_key  INT,
    movement_type       TEXT
);

DROP TABLE IF EXISTS raw.fact_inventory_movement CASCADE;
CREATE TABLE raw.fact_inventory_movement (
    movement_id        INT,
    date_key            INT,
    product_key         INT,
    warehouse_key       INT,
    supplier_key        INT,   -- nullable on purpose (raw messiness)
    movement_type_key   INT,
    quantity             INT,
    unit_cost            NUMERIC(10,2)
);

DROP TABLE IF EXISTS raw.fact_stock_snapshot CASCADE;
CREATE TABLE raw.fact_stock_snapshot (
    date_key           INT,
    product_key        INT,
    warehouse_key      INT,
    quantity_on_hand   INT
);
