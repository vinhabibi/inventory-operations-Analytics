
  
    

  create  table "inventory_warehouse"."dbt_dev_marts"."dim_movement_type__dbt_tmp"
  
  
    as
  
  (
    select * from "inventory_warehouse"."dbt_dev_staging"."stg_dim_movement_type"
  );
  