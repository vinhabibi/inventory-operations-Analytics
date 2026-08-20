
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  
    
    

select
    product_key as unique_field,
    count(*) as n_records

from "inventory_warehouse"."dbt_dev_marts"."dim_product"
where product_key is not null
group by product_key
having count(*) > 1



  
  
      
    ) dbt_internal_test