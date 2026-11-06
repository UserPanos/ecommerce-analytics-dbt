select
    order_id,
    customer_id,
    order_status,
    nullif(trim(order_purchase_timestamp), '')::timestamp as purchased_at,
    nullif(trim(order_approved_at), '')::timestamp as payment_approved_at,
    nullif(trim(order_delivered_carrier_date), '')::timestamp as delivered_to_carrier_at,
    nullif(trim(order_delivered_customer_date), '')::timestamp as delivered_to_customer_at,
    nullif(trim(order_estimated_delivery_date), '')::date as estimated_delivery_date
from {{ source('olist' , 'orders') }}