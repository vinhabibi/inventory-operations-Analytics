select
    movement_type_key,
    movement_type
from {{ source('raw', 'dim_movement_type') }}
