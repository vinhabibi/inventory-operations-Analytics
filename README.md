# Power BI Inventory Warehouse Project

An end-to-end data warehouse + Power BI dashboard project, built for hands-on
practice with star-schema design, ETL with dbt, and Power BI report building.

**Pipeline:** Python (synthetic data) → PostgreSQL (raw landing) → dbt
(staging + marts) → Power BI (report)

## Project structure

```
powerbi-warehouse/
├── generate_data.py           # generates raw CSVs (Faker + pandas)
├── data/                      # output CSVs land here
├── sql/
│   ├── 01_create_raw_tables.sql   # raw schema DDL
│   ├── 02_load_raw_csvs.sql       # psql \copy loader
│   └── load_raw_csvs.py           # Python loader (psycopg2 alternative)
└── dbt_warehouse/
    ├── dbt_project.yml
    ├── profiles_example.yml       # copy to ~/.dbt/profiles.yml
    └── models/
        ├── staging/                # 1:1 with raw tables, cleans messiness
        │   ├── _sources.yml
        │   ├── stg_dim_date.sql
        │   ├── stg_dim_warehouse.sql
        │   ├── stg_dim_supplier.sql
        │   ├── stg_dim_product.sql        # dedupes SKUs
        │   ├── stg_dim_movement_type.sql
        │   ├── stg_fact_inventory_movement.sql   # remaps dupes, fills nulls
        │   └── stg_fact_stock_snapshot.sql
        └── marts/                  # final star schema Power BI connects to
            ├── _marts.yml           # dbt tests: uniqueness, not-null, FK relationships
            ├── dim_date.sql
            ├── dim_warehouse.sql
            ├── dim_supplier.sql     # adds "Unknown Supplier" member
            ├── dim_product.sql
            ├── dim_movement_type.sql
            ├── fact_inventory_movement.sql
            └── fact_stock_snapshot.sql
```

## Step 1 — Generate the raw data

```bash
pip install faker pandas
python generate_data.py
```

Produces 7 CSVs in `data/`. Some intentional messiness is baked in: ~3%
duplicate SKUs in `dim_product`, and ~4% of movement rows missing a
`supplier_key`. This gives the ETL layer real problems to solve rather than
just passing data straight through.

## Step 2 — Load into PostgreSQL

Create a database (or reuse an existing one), then:

```bash
psql -U your_user -d your_db -f sql/01_create_raw_tables.sql
cd data
psql -U your_user -d your_db -f ../sql/02_load_raw_csvs.sql
```

Prefer Python/pgAdmin over the command line? Use `sql/load_raw_csvs.py`
instead — edit the connection details at the top, then run it from the
`data/` folder.

## Step 3 — Run dbt

```bash
pip install dbt-postgres
```

Copy `dbt_warehouse/profiles_example.yml` to `~/.dbt/profiles.yml` (create
the `.dbt` folder if it doesn't exist) and fill in your Postgres credentials.

```bash
cd dbt_warehouse
dbt run    # builds staging views + mart tables
dbt test   # runs uniqueness, not-null, and foreign-key checks
```

If `dbt test` passes, your star schema in the `marts` Postgres schema is
clean and ready for Power BI. If it fails, check which test failed — that's
the whole point of the exercise: catching data quality issues before they
hit the dashboard.

## Step 4 — Connect Power BI

1. Open Power BI Desktop → **Get Data** → **PostgreSQL database**
2. Server: `localhost`, Database: your db name
3. Choose **Import** mode (or DirectQuery if you want to practice that)
4. Select all 7 tables from the `marts` schema
5. In **Model view**, verify/create relationships:
   - `fact_inventory_movement[date_key]` → `dim_date[date_key]`
   - `fact_inventory_movement[product_key]` → `dim_product[product_key]`
   - `fact_inventory_movement[warehouse_key]` → `dim_warehouse[warehouse_key]`
   - `fact_inventory_movement[supplier_key]` → `dim_supplier[supplier_key]`
   - `fact_inventory_movement[movement_type_key]` → `dim_movement_type[movement_type_key]`
   - `fact_stock_snapshot[date_key]` → `dim_date[date_key]`
   - `fact_stock_snapshot[product_key]` → `dim_product[product_key]`
   - `fact_stock_snapshot[warehouse_key]` → `dim_warehouse[warehouse_key]`
6. Mark `dim_date` as a **Date Table** (Table tools → Mark as Date Table),
   using `full_date` as the date column — required for time-intelligence DAX.

From here: build DAX measures (stock turnover, days of inventory on hand,
stockout frequency), then build report pages.

## Notes on design decisions

- **Two fact tables at different grains**: `fact_inventory_movement` is
  transactional (one row per event); `fact_stock_snapshot` is periodic
  (one row per product/warehouse/day, sampled). This is a deliberately
  realistic pattern — mixing grains without noticing is a classic
  Power BI modeling mistake.
- **Surrogate key -1 for "Unknown Supplier"**: rather than leaving nulls in
  a fact table foreign key (which Power BI relationships handle poorly),
  the dbt staging layer coalesces nulls to -1 and the mart layer adds a
  matching dimension row. This is the standard warehouse pattern for
  handling missing dimension references.
