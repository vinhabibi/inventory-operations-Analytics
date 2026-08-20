with raw_snapshot as (

    select * from {{ source('raw', 'fact_stock_snapshot') }}

),

raw_products as (

    select product_key, sku from {{ source('raw', 'dim_product') }}

),

canonical_products as (

    select product_key as canonical_product_key, sku
    from {{ ref('stg_dim_product') }}

),

product_key_map as (

    select
        rp.product_key as raw_product_key,
        cp.canonical_product_key
    from raw_products rp
    inner join canonical_products cp on rp.sku = cp.sku

)

select
    s.date_key,
    pm.canonical_product_key as product_key,
    s.warehouse_key,
    s.quantity_on_hand
from raw_snapshot s
inner join product_key_map pm on s.product_key = pm.raw_product_key
