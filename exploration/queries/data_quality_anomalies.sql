-- Investigate notable source-data anomalies discovered during raw exploration.
-- These queries provide supporting evidence for findings documented
-- in docs/relationship_map.md.


-- ============================================================
-- 1. Orders without a payment record
-- ============================================================

-- Identify orders with no matching payment record.
-- Observed result on the current raw dataset: 1 order
with orders_without_payments as (
    select
        o.order_id,
        o.order_status
    from raw.olist_orders as o
    left join raw.olist_order_payments as p
        on o.order_id = p.order_id
    where p.order_id is null
),

order_item_summary as (
    select
        order_id,
        count(*) as item_row_count,
        count(distinct seller_id) as seller_count,
        sum(price + freight_value) as item_level_value
    from raw.olist_order_items
    group by order_id
)

select
    owp.order_id,
    owp.order_status,
    ois.item_row_count,
    ois.seller_count,
    ois.item_level_value
from orders_without_payments as owp
left join order_item_summary as ois
    on owp.order_id = ois.order_id;

-- Observed finding:
-- order_status = delivered
-- item_row_count = 3
-- seller_count = 1
-- item_level_value = 143.46
--
-- Interpretation:
-- The order has no payment record in the source dataset.
-- This does not prove that the customer failed to pay.


-- ============================================================
-- 2. Orders without review records
-- ============================================================

-- Count orders without reviews by order status.
-- Observed total on the current raw dataset: 768 orders
-- Observed delivered orders without reviews: 646
select
    o.order_status,
    count(*) as orders_without_reviews
from raw.olist_orders as o
left join raw.olist_order_reviews as r
    on o.order_id = r.order_id
where r.order_id is null
group by o.order_status
order by orders_without_reviews desc;

-- Observed status breakdown on the current raw dataset:
-- delivered   = 646
-- shipped     = 75
-- canceled    = 20
-- unavailable = 14
-- processing  = 6
-- invoiced    = 5
-- created     = 2


-- Inspect orders with multiple review rows.
-- The existence of repeated order_id values is confirmed,
-- but the business reason has not yet been established.
select
    order_id,
    count(*) as review_row_count,
    count(distinct review_id) as distinct_review_id_count
from raw.olist_order_reviews
group by order_id
having count(*) > 1
order by review_row_count desc, order_id;


-- ============================================================
-- 3. Product category completeness
-- ============================================================

-- Products with a null or blank category assignment.
-- Observed result on the current raw dataset: 610
select
    count(*) as products_without_valid_category
from raw.olist_products
where nullif(trim(product_category_name), '') is null;


-- ============================================================
-- 4. Product category translation coverage
-- ============================================================

-- Count products using non-empty categories that have no translation.
-- Observed results on the current raw dataset:
-- products_without_translation = 13
-- missing_category_values = 2
select
    count(*) as products_without_translation,
    count(distinct p.product_category_name)
        as missing_category_values
from raw.olist_products as p
left join raw.product_category_name_translation as t
    on p.product_category_name = t.product_category_name
where nullif(trim(p.product_category_name), '') is not null
  and t.product_category_name is null;


-- List the untranslated category values and affected product counts.
select
    p.product_category_name,
    count(*) as affected_products
from raw.olist_products as p
left join raw.product_category_name_translation as t
    on p.product_category_name = t.product_category_name
where nullif(trim(p.product_category_name), '') is not null
  and t.product_category_name is null
group by p.product_category_name
order by affected_products desc;


-- Translation categories that are not used by any product.
-- Observed result on the current raw dataset: 0
select
    count(*) as unused_translation_categories
from raw.product_category_name_translation as t
left join raw.olist_products as p
    on t.product_category_name = p.product_category_name
where p.product_category_name is null;