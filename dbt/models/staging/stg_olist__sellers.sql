select
seller_id,
lpad(seller_zip_code_prefix::text, 5, '0') as seller_zip_code_prefix,
seller_city,
seller_state
from {{source ('olist', 'sellers')}}