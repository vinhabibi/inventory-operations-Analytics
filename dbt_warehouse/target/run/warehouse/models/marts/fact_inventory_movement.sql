
  
    

  create  table "inventory_warehouse"."dbt_dev_marts"."fact_inventory_movement__dbt_tmp"
  
  
    as
  
  (
    select * from "inventory_warehouse"."dbt_dev_staging"."stg_fact_inventory_movement"
  );
  