
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

with child as (
    select warehouse_key as from_field
    from "inventory_warehouse"."dbt_dev_marts"."fact_inventory_movement"
    where warehouse_key is not null
),

parent as (
    select warehouse_key as to_field
    from "inventory_warehouse"."dbt_dev_marts"."dim_warehouse"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



  
  
      
    ) dbt_internal_test