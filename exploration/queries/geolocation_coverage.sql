-- Validate zip-code coverage between customers, sellers, and geolocation.
-- The raw geolocation table contains multiple rows per zip prefix.
-- A distinct zip-key set is used here to avoid fan-out during coverage checks.


-- ============================================================
-- 1. Geolocation key-set profile
-- ============================================================

select
    count(*) as geolocation_rows,
    count(distinct geolocation_zip_code_prefix)
        as distinct_geolocation_zip_prefixes,
    round(
        count(*)::numeric
        / nullif(count(distinct geolocation_zip_code_prefix), 0),
        1
    ) as average_rows_per_zip_prefix
from raw.olist_geolocation;

-- Observed results on the current raw dataset:
-- geolocation_rows = 1,000,163
-- distinct_geolocation_zip_prefixes = 19,015
-- average_rows_per_zip_prefix = 52.6



-- ============================================================
-- 2. Customers → Geolocation
-- ============================================================

-- Customers with a null zip prefix.
-- Observed result on the current raw dataset: 0
select
    count(*) as customers_with_null_zip_prefix
from raw.olist_customers
where customer_zip_code_prefix is null;


-- Customer rows and distinct customer zip prefixes
-- without a matching geolocation zip prefix.
-- Observed results on the current raw dataset:
-- customer_rows_without_geolocation_match = 278
-- missing_customer_zip_prefixes = 157
with geolocation_zip_codes as (
    select distinct
        geolocation_zip_code_prefix
    from raw.olist_geolocation
)

select
    count(*) as customer_rows_without_geolocation_match,
    count(distinct c.customer_zip_code_prefix)
        as missing_customer_zip_prefixes
from raw.olist_customers as c
left join geolocation_zip_codes as g
    on c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
where g.geolocation_zip_code_prefix is null;



-- ============================================================
-- 3. Sellers → Geolocation
-- ============================================================

-- Sellers with a null zip prefix.
-- Observed result on the current raw dataset: 0
select
    count(*) as sellers_with_null_zip_prefix
from raw.olist_sellers
where seller_zip_code_prefix is null;


-- Seller rows and distinct seller zip prefixes
-- without a matching geolocation zip prefix.
-- Observed results on the current raw dataset:
-- seller_rows_without_geolocation_match = 7
-- missing_seller_zip_prefixes = 7
with geolocation_zip_codes as (
    select distinct
        geolocation_zip_code_prefix
    from raw.olist_geolocation
)

select
    count(*) as seller_rows_without_geolocation_match,
    count(distinct s.seller_zip_code_prefix)
        as missing_seller_zip_prefixes
from raw.olist_sellers as s
left join geolocation_zip_codes as g
    on s.seller_zip_code_prefix = g.geolocation_zip_code_prefix
where g.geolocation_zip_code_prefix is null;


-- Geolocation zip prefixes not used by any seller.
-- Observed result on the current raw dataset: 16,776
with geolocation_zip_codes as (
    select distinct
        geolocation_zip_code_prefix
    from raw.olist_geolocation
)

select
    count(*) as geolocation_zip_prefixes_without_sellers
from geolocation_zip_codes as g
left join raw.olist_sellers as s
    on g.geolocation_zip_code_prefix = s.seller_zip_code_prefix
where s.seller_zip_code_prefix is null;
