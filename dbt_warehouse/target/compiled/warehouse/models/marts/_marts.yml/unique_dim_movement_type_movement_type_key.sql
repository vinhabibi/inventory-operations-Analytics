
    
    

select
    movement_type_key as unique_field,
    count(*) as n_records

from "inventory_warehouse"."dbt_dev_marts"."dim_movement_type"
where movement_type_key is not null
group by movement_type_key
having count(*) > 1


