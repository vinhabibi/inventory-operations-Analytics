select
    supplier_key,
    supplier_name,
    country,
    lead_time_days
from {{ ref('stg_dim_supplier') }}

union all

-- covers fact_inventory_movement.supplier_key = -1 (originally null in raw data)
select
    -1 as supplier_key,
    'Unknown Supplier' as supplier_name,
    null as country,
    null as lead_time_days
