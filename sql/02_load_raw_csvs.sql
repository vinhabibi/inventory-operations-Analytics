-- Run this with psql, from the folder containing the CSVs, e.g.:
--   psql -U your_user -d your_db -f 02_load_raw_csvs.sql
-- \copy runs client-side, so relative paths below assume you're running
-- psql from the same folder as the CSVs (the data/ folder from generate_data.py).

\copy raw.dim_date FROM 'dim_date.csv' WITH (FORMAT csv, HEADER true)
\copy raw.dim_warehouse FROM 'dim_warehouse.csv' WITH (FORMAT csv, HEADER true)
\copy raw.dim_supplier FROM 'dim_supplier.csv' WITH (FORMAT csv, HEADER true)
\copy raw.dim_product FROM 'dim_product.csv' WITH (FORMAT csv, HEADER true)
\copy raw.dim_movement_type FROM 'dim_movement_type.csv' WITH (FORMAT csv, HEADER true)
\copy raw.fact_inventory_movement FROM 'fact_inventory_movement.csv' WITH (FORMAT csv, HEADER true)
\copy raw.fact_stock_snapshot FROM 'fact_stock_snapshot.csv' WITH (FORMAT csv, HEADER true)

-- Quick sanity check
SELECT 'dim_date' AS table_name, COUNT(*) FROM raw.dim_date
UNION ALL SELECT 'dim_warehouse', COUNT(*) FROM raw.dim_warehouse
UNION ALL SELECT 'dim_supplier', COUNT(*) FROM raw.dim_supplier
UNION ALL SELECT 'dim_product', COUNT(*) FROM raw.dim_product
UNION ALL SELECT 'dim_movement_type', COUNT(*) FROM raw.dim_movement_type
UNION ALL SELECT 'fact_inventory_movement', COUNT(*) FROM raw.fact_inventory_movement
UNION ALL SELECT 'fact_stock_snapshot', COUNT(*) FROM raw.fact_stock_snapshot;
