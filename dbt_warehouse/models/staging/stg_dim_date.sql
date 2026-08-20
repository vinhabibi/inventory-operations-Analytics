select
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    week,
    day_of_week,
    is_weekend
from {{ source('raw', 'dim_date') }}
