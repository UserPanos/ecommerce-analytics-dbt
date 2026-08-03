-- Check whether an order can contain items from multiple sellers.
-- Purpose: identify orders associated with more than one seller.
-- Source grain: one row per order item.
-- CTE grain: one row per order.
-- Modeling impact: order-level delivery and review outcomes cannot be
-- attributed unambiguously to one seller for multi-seller orders.

with orders_with_seller_count as (

    select
        order_id,
        count(distinct seller_id) as seller_count
    from raw.olist_order_items
    group by order_id

)

select
    count(*) as orders_with_items,
    count(*) filter (where seller_count > 1) as multi_seller_orders,
    round(
        100.0
        * count(*) filter (where seller_count > 1)
        / nullif(count(*), 0),
        2
    ) as multi_seller_order_pct,
    max(seller_count) as max_sellers_per_order
from orders_with_seller_count;

-- Observed results on the current raw dataset:
-- orders_with_items = 98,666
-- multi_seller_orders = 1,278
-- multi_seller_order_pct = 1.30
-- max_sellers_per_order = 5
