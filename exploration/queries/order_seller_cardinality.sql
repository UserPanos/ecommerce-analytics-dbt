-- Check whether an order can contain items from multiple sellers.
-- Purpose: identify orders associated with more than one seller.
-- Source grain: one row per order item.
-- CTE grain: one row per order.
-- Modeling impact: order-level delivery and review outcomes are ambiguous
-- for orders involving multiple sellers.

with orders_with_seller_count as (
	
	select
		order_id,
	    count(distinct seller_id) as seller_count
	from raw.olist_order_items
	group by order_id 

)
select 
	count(*) as total_orders,
	count(*) filter (where seller_count > 1) as multi_seller_orders,		
	100.0 
	* count(*) filter (where seller_count > 1)
	/  nullif( count(*),0 ) as multi_seller_order_pct ,
	max(seller_count) as max_sellers_per_order
from orders_with_seller_count