select
    geolocation_zip_code_prefix
from {{ ref('stg_olist__geolocation') }}
where geolocation_zip_code_prefix !~ '^[0-9]{5}$'