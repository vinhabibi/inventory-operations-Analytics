
  
    

  create  table "inventory_warehouse"."dbt_dev_marts"."fact_stock_snapshot__dbt_tmp"
  
  
    as
  
  (
    select * from "inventory_warehouse"."dbt_dev_staging"."stg_fact_stock_snapshot"
  );
  