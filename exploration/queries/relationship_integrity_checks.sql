-- Validate referential integrity and key coverage between raw Olist tables.
-- Child-to-parent checks identify orphan records.
-- Reverse checks identify parent records with no related child records.
--
-- Important:
-- A child record without a parent is a referential-integrity violation.
-- A parent record without a child is a coverage gap, not necessarily an RI violation.


-- ============================================================
-- 1. Orders → Customers
-- Join key: customer_id
-- Cardinality: 1:1
-- ============================================================

-- Orders without a matching customer.
-- Expected result: 0
select
    count(*) as orders_without_matching_customers
from raw.olist_orders as o
left join raw.olist_customers as c
    on o.customer_id = c.customer_id
where c.customer_id is null;


-- Customers without a matching order.
-- Expected result: 0
select
    count(*) as customers_without_matching_orders
from raw.olist_customers as c
left join raw.olist_orders as o
    on c.customer_id = o.customer_id
where o.customer_id is null;



-- ============================================================
-- 2. Order Items → Orders
-- Join key: order_id
-- Cardinality: N:1
-- ============================================================

-- Order-item rows without a matching order.
-- Expected result: 0
select
    count(*) as order_items_without_matching_orders
from raw.olist_order_items as oi
left join raw.olist_orders as o
    on oi.order_id = o.order_id
where o.order_id is null;


-- Orders without matching order items.
-- Expected result: 775
select
    count(*) as orders_without_order_items
from raw.olist_orders as o
left join raw.olist_order_items as oi
    on o.order_id = oi.order_id
where oi.order_id is null;



-- ============================================================
-- 3. Order Items → Sellers
-- Join key: seller_id
-- Cardinality: N:1
-- ============================================================

-- Order-item rows without a matching seller.
-- Expected result: 0
select
    count(*) as order_items_without_matching_sellers
from raw.olist_order_items as oi
left join raw.olist_sellers as s
    on oi.seller_id = s.seller_id
where s.seller_id is null;


-- Sellers without matching order items.
-- Expected result: 0
select
    count(*) as sellers_without_order_items
from raw.olist_sellers as s
left join raw.olist_order_items as oi
    on s.seller_id = oi.seller_id
where oi.seller_id is null;



-- ============================================================
-- 4. Order Payments → Orders
-- Join key: order_id
-- Cardinality: N:1
-- ============================================================

-- Payment rows without a matching order.
-- Expected result: 0
select
    count(*) as payments_without_matching_orders
from raw.olist_order_payments as p
left join raw.olist_orders as o
    on p.order_id = o.order_id
where o.order_id is null;


-- Orders without a matching payment record.
-- Expected result: 1
select
    count(*) as orders_without_payments
from raw.olist_orders as o
left join raw.olist_order_payments as p
    on o.order_id = p.order_id
where p.order_id is null;



-- ============================================================
-- 5. Order Reviews → Orders
-- Join key: order_id
-- Cardinality: N:1
-- ============================================================

-- Review rows without a matching order.
-- Expected result: 0
select
    count(*) as reviews_without_matching_orders
from raw.olist_order_reviews as r
left join raw.olist_orders as o
    on r.order_id = o.order_id
where o.order_id is null;


-- Orders without a matching review record.
-- Expected result: 768
select
    count(*) as orders_without_reviews
from raw.olist_orders as o
left join raw.olist_order_reviews as r
    on o.order_id = r.order_id
where r.order_id is null;



-- ============================================================
-- 6. Order Items → Products
-- Join key: product_id
-- Cardinality: N:1
-- ============================================================

-- Order-item rows with a null product_id or no matching product.
-- Expected result: 0
select
    count(*) as order_items_without_matching_products
from raw.olist_order_items as oi
left join raw.olist_products as p
    on oi.product_id = p.product_id
where p.product_id is null;


-- Products without matching order items.
-- Expected result: 0
select
    count(*) as products_without_order_items
from raw.olist_products as p
left join raw.olist_order_items as oi
    on p.product_id = oi.product_id
where oi.product_id is null;