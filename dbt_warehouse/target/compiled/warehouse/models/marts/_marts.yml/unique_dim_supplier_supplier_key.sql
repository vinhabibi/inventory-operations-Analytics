
    
    

select
    supplier_key as unique_field,
    count(*) as n_records

from "inventory_warehouse"."dbt_dev_marts"."dim_supplier"
where supplier_key is not null
group by supplier_key
having count(*) > 1


