-- Validate whether alternative column combinations can uniquely identify
-- rows within an order.
-- These checks support the documented grains of order items and payments.


-- ============================================================
-- 1. Repeated order_id + product_id combinations
-- ============================================================

select
    count(*) as repeated_order_product_combinations
from (
    select
        order_id,
        product_id
    from raw.olist_order_items
    group by
        order_id,
        product_id
    having count(*) > 1
) as repeated_combinations;

-- Observed result on the current raw dataset: 7,088
-- Therefore, order_id + product_id does not uniquely identify
-- an order-item row.


-- ============================================================
-- 2. Repeated order_id + payment_type combinations
-- ============================================================

select
    count(*) as repeated_order_payment_type_combinations
from (
    select
        order_id,
        payment_type
    from raw.olist_order_payments
    group by
        order_id,
        payment_type
    having count(*) > 1
) as repeated_combinations;

-- Observed result on the current raw dataset: 1,091
-- Therefore, order_id + payment_type does not uniquely identify
-- a payment row.
