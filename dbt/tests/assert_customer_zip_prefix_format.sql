select
    customer_id,
    customer_zip_code_prefix
from  {{ref ('stg_olist__customers')}}
where customer_zip_code_prefix !~ '^[0-9]{5}$'