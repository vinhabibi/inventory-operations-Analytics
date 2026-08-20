
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    



select movement_id
from "inventory_warehouse"."dbt_dev_marts"."fact_inventory_movement"
where movement_id is null



  
  
      
    ) dbt_internal_test