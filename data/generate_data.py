"""
Synthetic data generator for the Power BI inventory warehouse project.

Generates raw CSVs matching the star schema:
  Dimensions: dim_date, dim_product, dim_warehouse, dim_supplier, dim_movement_type
  Facts:      fact_inventory_movement, fact_stock_snapshot

These are "raw" outputs on purpose (some messiness included) — they're meant
to be loaded into PostgreSQL and cleaned up in a dbt staging layer, not
loaded straight into Power BI.

Run:
    python generate_data.py
Outputs land in ./data/
"""

import random
from datetime import date, timedelta

import pandas as pd
from faker import Faker

fake = Faker()
Faker.seed(42)
random.seed(42)

OUT_DIR = "data"

START_DATE = date(2024, 1, 1)
END_DATE = date(2025, 12, 31)

N_WAREHOUSES = 6
N_SUPPLIERS = 15
N_PRODUCTS = 120
AVG_MOVEMENTS_PER_DAY = 35

CATEGORIES = {
    "Electronics": ["Audio", "Accessories", "Components"],
    "Home & Kitchen": ["Cookware", "Storage", "Small Appliances"],
    "Office Supplies": ["Paper Goods", "Writing", "Furniture"],
    "Apparel": ["Outerwear", "Footwear", "Accessories"],
    "Tools & Hardware": ["Hand Tools", "Power Tools", "Fasteners"],
}

MOVEMENT_TYPES = ["inbound", "outbound", "transfer", "return", "adjustment"]
REGIONS = ["Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret", "Thika"]


def build_dim_date(start, end):
    rows = []
    d = start
    key = 1
    while d <= end:
        rows.append(
            {
                "date_key": key,
                "full_date": d.isoformat(),
                "year": d.year,
                "quarter": (d.month - 1) // 3 + 1,
                "month": d.month,
                "month_name": d.strftime("%B"),
                "week": d.isocalendar()[1],
                "day_of_week": d.strftime("%A"),
                "is_weekend": d.weekday() >= 5,
            }
        )
        d += timedelta(days=1)
        key += 1
    return pd.DataFrame(rows)


def build_dim_warehouse(n):
    rows = []
    used_regions = random.sample(REGIONS, k=min(n, len(REGIONS)))
    for i in range(1, n + 1):
        region = used_regions[i - 1] if i <= len(used_regions) else random.choice(REGIONS)
        rows.append(
            {
                "warehouse_key": i,
                "warehouse_name": f"{region} Distribution Center",
                "region": region,
                "city": region,
                "capacity": random.randint(5000, 30000),
            }
        )
    return pd.DataFrame(rows)


def build_dim_supplier(n):
    rows = []
    for i in range(1, n + 1):
        rows.append(
            {
                "supplier_key": i,
                "supplier_name": fake.company(),
                "country": random.choice(
                    ["Kenya", "China", "India", "UAE", "South Africa", "Germany", "USA"]
                ),
                "lead_time_days": random.randint(3, 45),
            }
        )
    return pd.DataFrame(rows)


def build_dim_product(n):
    rows = []
    for i in range(1, n + 1):
        category = random.choice(list(CATEGORIES.keys()))
        subcategory = random.choice(CATEGORIES[category])
        unit_cost = round(random.uniform(2, 400), 2)
        margin = random.uniform(1.2, 2.5)
        rows.append(
            {
                "product_key": i,
                "sku": f"SKU-{1000 + i}",
                "product_name": f"{fake.word().capitalize()} {subcategory[:-1] if subcategory.endswith('s') else subcategory}",
                "category": category,
                "subcategory": subcategory,
                "unit_cost": unit_cost,
                "unit_price": round(unit_cost * margin, 2),
                "reorder_point": random.randint(10, 100),
            }
        )
    df = pd.DataFrame(rows)
    # intentional messiness: a few duplicate SKUs (simulating a data entry error upstream)
    dupes = df.sample(frac=0.03, random_state=1).copy()
    dupes["product_key"] = dupes["product_key"] + 10000  # different key, same SKU
    return pd.concat([df, dupes], ignore_index=True)


def build_dim_movement_type():
    return pd.DataFrame(
        {
            "movement_type_key": range(1, len(MOVEMENT_TYPES) + 1),
            "movement_type": MOVEMENT_TYPES,
        }
    )


def build_fact_movements(dim_date, dim_product, dim_warehouse, dim_supplier, dim_movement_type):
    rows = []
    movement_id = 1
    movement_type_weights = [0.45, 0.40, 0.08, 0.05, 0.02]  # inbound/outbound dominate

    for _, drow in dim_date.iterrows():
        n_today = max(0, int(random.gauss(AVG_MOVEMENTS_PER_DAY, 8)))
        for _ in range(n_today):
            mtype_key = random.choices(
                dim_movement_type["movement_type_key"].tolist(), weights=movement_type_weights
            )[0]
            product_key = random.choice(dim_product["product_key"].tolist())
            warehouse_key = random.choice(dim_warehouse["warehouse_key"].tolist())
            # ~4% of rows missing supplier (only inbound should have one anyway;
            # left messy on purpose for the dbt cleaning step)
            supplier_key = (
                random.choice(dim_supplier["supplier_key"].tolist())
                if random.random() > 0.04
                else None
            )
            quantity = random.randint(1, 250)
            unit_cost_row = dim_product.loc[
                dim_product["product_key"] == product_key, "unit_cost"
            ]
            unit_cost = float(unit_cost_row.iloc[0]) if not unit_cost_row.empty else None

            rows.append(
                {
                    "movement_id": movement_id,
                    "date_key": drow["date_key"],
                    "product_key": product_key,
                    "warehouse_key": warehouse_key,
                    "supplier_key": supplier_key,
                    "movement_type_key": mtype_key,
                    "quantity": quantity,
                    "unit_cost": unit_cost,
                }
            )
            movement_id += 1
    return pd.DataFrame(rows)


def build_fact_stock_snapshot(dim_date, dim_product, dim_warehouse, fact_movements):
    """Roll movements forward into a daily on-hand snapshot per product/warehouse."""
    sign = {
        1: +1,  # inbound
        2: -1,  # outbound
        3: 0,  # transfer (nets to 0 warehouse-wide, simplification)
        4: +1,  # return
        5: 0,  # adjustment (randomized separately)
    }

    movements = fact_movements.copy()
    movements["signed_qty"] = movements["movement_type_key"].map(sign) * movements["quantity"]

    # start every product/warehouse pair at a random base stock level
    combos = [
        (p, w)
        for p in dim_product["product_key"].tolist()
        for w in dim_warehouse["warehouse_key"].tolist()
    ]
    # sample down combos to keep file size reasonable
    combos = random.sample(combos, k=min(len(combos), 400))
    base_stock = {c: random.randint(50, 500) for c in combos}

    daily_delta = (
        movements.groupby(["date_key", "product_key", "warehouse_key"])["signed_qty"]
        .sum()
        .reset_index()
    )

    rows = []
    running = dict(base_stock)
    for date_key in dim_date["date_key"]:
        day_deltas = daily_delta[daily_delta["date_key"] == date_key]
        delta_map = {
            (r.product_key, r.warehouse_key): r.signed_qty for r in day_deltas.itertuples()
        }
        for combo in combos:
            running[combo] = max(0, running[combo] + delta_map.get(combo, 0))
            # only write a snapshot row ~1 in 3 days per combo to keep volume sane
            if random.random() < 0.33:
                rows.append(
                    {
                        "date_key": date_key,
                        "product_key": combo[0],
                        "warehouse_key": combo[1],
                        "quantity_on_hand": running[combo],
                    }
                )
    return pd.DataFrame(rows)


def main():
    import os

    os.makedirs(OUT_DIR, exist_ok=True)

    dim_date = build_dim_date(START_DATE, END_DATE)
    dim_warehouse = build_dim_warehouse(N_WAREHOUSES)
    dim_supplier = build_dim_supplier(N_SUPPLIERS)
    dim_product = build_dim_product(N_PRODUCTS)
    dim_movement_type = build_dim_movement_type()

    fact_movements = build_fact_movements(
        dim_date, dim_product, dim_warehouse, dim_supplier, dim_movement_type
    )
    fact_snapshot = build_fact_stock_snapshot(dim_date, dim_product, dim_warehouse, fact_movements)

    dim_date.to_csv(f"{OUT_DIR}/dim_date.csv", index=False)
    dim_warehouse.to_csv(f"{OUT_DIR}/dim_warehouse.csv", index=False)
    dim_supplier.to_csv(f"{OUT_DIR}/dim_supplier.csv", index=False)
    dim_product.to_csv(f"{OUT_DIR}/dim_product.csv", index=False)
    dim_movement_type.to_csv(f"{OUT_DIR}/dim_movement_type.csv", index=False)
    fact_movements.to_csv(f"{OUT_DIR}/fact_inventory_movement.csv", index=False)
    fact_snapshot.to_csv(f"{OUT_DIR}/fact_stock_snapshot.csv", index=False)

    print("Generated:")
    for name, df in [
        ("dim_date", dim_date),
        ("dim_warehouse", dim_warehouse),
        ("dim_supplier", dim_supplier),
        ("dim_product", dim_product),
        ("dim_movement_type", dim_movement_type),
        ("fact_inventory_movement", fact_movements),
        ("fact_stock_snapshot", fact_snapshot),
    ]:
        print(f"  {name}: {len(df):,} rows")


if __name__ == "__main__":
    main()
