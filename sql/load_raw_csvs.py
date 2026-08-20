"""
Alternative to 02_load_raw_csvs.sql, for anyone who'd rather load via Python
than psql. Uses psycopg2's COPY, which is just as fast as \\copy.

Requires: pip install psycopg2-binary --break-system-packages

Edit the connection details below, then run:
    python load_raw_csvs.py
from the folder containing the CSVs (the data/ folder from generate_data.py).
"""

import psycopg2

CONN_PARAMS = dict(
    host="localhost",
    port=5432,
    dbname="datasciencedb",  # reuse your existing DB, or create a new one
    user="postgres",
    password="your_password_here",
)

TABLES = [
    "dim_date",
    "dim_warehouse",
    "dim_supplier",
    "dim_product",
    "dim_movement_type",
    "fact_inventory_movement",
    "fact_stock_snapshot",
]


def main():
    conn = psycopg2.connect(**CONN_PARAMS)
    conn.autocommit = False
    cur = conn.cursor()

    try:
        for table in TABLES:
            csv_path = f"{table}.csv"
            with open(csv_path, "r", encoding="utf-8") as f:
                cur.copy_expert(
                    f"COPY raw.{table} FROM STDIN WITH (FORMAT csv, HEADER true)", f
                )
            print(f"Loaded {table}")
        conn.commit()
        print("All tables loaded successfully.")
    except Exception as e:
        conn.rollback()
        print(f"Failed, rolled back: {e}")
        raise
    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
