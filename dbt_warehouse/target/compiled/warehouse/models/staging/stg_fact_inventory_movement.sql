-- Two cleanup jobs happen here, both driven by messiness baked into the raw data:
--   1. Some movement rows reference a "duplicate" product_key that stg_dim_product
--      dropped during dedup. We remap those to the canonical product_key via SKU.
--   2. ~4% of rows have a null supplier_key. Rather than leave nulls in a fact
--      table's foreign key (Power BI relationships don't handle that well),
--      we point them at an "Unknown Supplier" member added in the mart layer.

with raw_movements as (

    select * from "inventory_warehouse"."raw"."fact_inventory_movement"

),

raw_products as (

    -- includes the duplicate rows dbt hasn't deduped yet, purely to map sku
    select product_key, sku from "inventory_warehouse"."raw"."dim_product"

),

canonical_products as (

    select product_key as canonical_product_key, sku
    from "inventory_warehouse"."dbt_dev_staging"."stg_dim_product"

),

product_key_map as (

    select
        rp.product_key as raw_product_key,
        cp.canonical_product_key
    from raw_products rp
    inner join canonical_products cp on rp.sku = cp.sku

)

select
    m.movement_id,
    m.date_key,
    pm.canonical_product_key as product_key,
    m.warehouse_key,
    coalesce(m.supplier_key::int, -1) as supplier_key,   -- -1 = Unknown Supplier
    m.movement_type_key,
    m.quantity,
    m.unit_cost
from raw_movements m
inner join product_key_map pm on m.product_key = pm.raw_product_key