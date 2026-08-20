
    
    

select
    warehouse_key as unique_field,
    count(*) as n_records

from "inventory_warehouse"."dbt_dev_marts"."dim_warehouse"
where warehouse_key is not null
group by warehouse_key
having count(*) > 1


