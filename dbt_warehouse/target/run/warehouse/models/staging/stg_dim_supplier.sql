
  create view "inventory_warehouse"."dbt_dev_staging"."stg_dim_supplier__dbt_tmp"
    
    
  as (
    select
    supplier_key,
    supplier_name,
    country,
    lead_time_days
from "inventory_warehouse"."raw"."dim_supplier"
  );