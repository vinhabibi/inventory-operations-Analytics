
  create view "inventory_warehouse"."dbt_dev_staging"."stg_dim_date__dbt_tmp"
    
    
  as (
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
from "inventory_warehouse"."raw"."dim_date"
  );