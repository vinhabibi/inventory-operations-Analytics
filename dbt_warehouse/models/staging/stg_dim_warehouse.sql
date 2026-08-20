select
    warehouse_key,
    warehouse_name,
    region,
    city,
    capacity
from {{ source('raw', 'dim_warehouse') }}
