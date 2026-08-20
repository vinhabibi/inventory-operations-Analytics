
    
    

select
    movement_id as unique_field,
    count(*) as n_records

from "inventory_warehouse"."dbt_dev_marts"."fact_inventory_movement"
where movement_id is not null
group by movement_id
having count(*) > 1


