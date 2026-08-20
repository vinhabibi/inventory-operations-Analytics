
  create view "inventory_warehouse"."dbt_dev_staging"."stg_dim_warehouse__dbt_tmp"
    
    
  as (
    select
    warehouse_key,
    warehouse_name,
    region,
    city,
    capacity
from "inventory_warehouse"."raw"."dim_warehouse"
  );