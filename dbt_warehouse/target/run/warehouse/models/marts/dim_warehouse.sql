
  
    

  create  table "inventory_warehouse"."dbt_dev_marts"."dim_warehouse__dbt_tmp"
  
  
    as
  
  (
    select * from "inventory_warehouse"."dbt_dev_staging"."stg_dim_warehouse"
  );
  