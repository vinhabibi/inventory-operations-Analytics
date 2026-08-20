
  create view "inventory_warehouse"."dbt_dev_staging"."stg_dim_movement_type__dbt_tmp"
    
    
  as (
    select
    movement_type_key,
    movement_type
from "inventory_warehouse"."raw"."dim_movement_type"
  );