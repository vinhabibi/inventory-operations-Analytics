
  create view "inventory_warehouse"."dbt_dev_staging"."stg_dim_product__dbt_tmp"
    
    
  as (
    -- The raw generator intentionally introduced ~3% duplicate SKUs (same SKU,
-- different product_key) to simulate an upstream data entry error.
-- We dedupe here, keeping the lowest product_key per SKU as the "canonical" row.

with ranked as (

    select
        product_key,
        sku,
        product_name,
        category,
        subcategory,
        unit_cost,
        unit_price,
        reorder_point,
        row_number() over (partition by sku order by product_key asc) as rn
    from "inventory_warehouse"."raw"."dim_product"

)

select
    product_key,
    sku,
    product_name,
    category,
    subcategory,
    unit_cost,
    unit_price,
    reorder_point
from ranked
where rn = 1
  );