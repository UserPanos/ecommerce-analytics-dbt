select
    customer_id,
    customer_unique_id,
    lpad(customer_zip_code_prefix::text,5,'0') as customer_zip_code_prefix,
    customer_city,
    customer_state
from {{source ('olist' , 'customers') }}