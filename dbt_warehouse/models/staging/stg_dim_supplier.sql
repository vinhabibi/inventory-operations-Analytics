select
    supplier_key,
    supplier_name,
    country,
    lead_time_days
from {{ source('raw', 'dim_supplier') }}
