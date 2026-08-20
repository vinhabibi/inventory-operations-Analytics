
  
    

  create  table "inventory_warehouse"."dbt_dev_marts"."dim_supplier__dbt_tmp"
  
  
    as
  
  (
    select
    supplier_key,
    supplier_name,
    country,
    lead_time_days
from "inventory_warehouse"."dbt_dev_staging"."stg_dim_supplier"

union all

-- covers fact_inventory_movement.supplier_key = -1 (originally null in raw data)
select
    -1 as supplier_key,
    'Unknown Supplier' as supplier_name,
    null as country,
    null as lead_time_days
  );
  