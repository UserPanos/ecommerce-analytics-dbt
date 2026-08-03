# Olist Data Exploration Notes


## raw.olist_orders

### Overview
- Total rows: 99,441
- Grain: one row per order (order_id is unique: 99,441 rows = 99,441 distinct)
- Order lifecycle: purchase → approval → carrier handoff → customer delivery vs estimated date
- Note: customer_id is an order-specific identifier, not a person-level
  identifier. A complete 1:1 relationship with raw.olist_customers was
  validated through bidirectional anti-joins
  (see exploration/queries/relationship_integrity_checks.sql).

### Order statuses (8 total)
- delivered: 96,478
- shipped: 1,107
- canceled: 625
- unavailable: 609
- invoiced: 314
- processing: 301
- created: 5
- approved: 2

### Data quality issues
- Empty cells loaded as empty strings (''), NOT NULL
  → IS NULL returns 0, but = '' returns 2,965
- 8 orders are 'delivered' but have no delivery date
- 6 orders are 'canceled' but HAVE a delivery date

### Implications for dbt staging
- Convert empty strings to NULL (e.g. NULLIF)
- Cast timestamp columns from varchar to timestamp
- Decide how to handle the 14 anomalies


## raw.olist_order_items

### Overview
- Total rows: 112,650
- Grain: one row per order item within an order
  (order_id + order_item_id is unique: 112,650 rows = 112,650 distinct)
- The same order_id + product_id combination can appear in multiple rows.
  7,088 order-product combinations appear more than once, so product_id
  does not define the grain within an order.
- Validation query: `exploration/queries/grain_validation_checks.sql`

### Business relevance
- seller_id links each order item to the seller associated with that item
- Critical for the business problem
  (check whether delayed orders are associated with lower review scores
  and identify sellers frequently associated with delayed orders)

### Key finding: multi-seller orders
- 98,666 orders contain at least one order item.
- 1,278 orders involve more than one seller.
- Multi-seller orders represent approximately 1.30% of orders represented in `raw.olist_order_items`.
- The maximum observed number of sellers in one order is 5.
- Validation query: `exploration/queries/order_seller_cardinality.sql`

### Modeling implication
- Order-level delivery and review outcomes cannot be attributed unambiguously to one seller for multi-seller orders.


## raw.olist_order_reviews

### Overview 
- Total rows: 99,224
- Grain: one row per review per order (review_id + order_id)

### Key finding: neither ID is unique on its own
- order_id is NOT unique (99,224 vs 98,673 distinct) — an order can have multiple reviews
- review_id is NOT unique (99,224 vs 98,410 distinct) — the same review_id
  can appear with multiple order_id values in the source
- Only the combination is unique → watch for fan-out when joining on order_id

### Data quality issues
- Some columns (like 'review_comment_title' and 'review_comment_message') failed during load
  because their varchar limit was too small, so the type was changed to 'text'
- CSV had multi-line comments (commas + newlines inside quotes) that broke DBeaver import Wizard parser
- Loaded via PostgreSQL COPY instead, which handles quoted multi-line fields correctly by design
- COPY loads empty cells as NULL, whereas the Import Wizard (used for olist_orders) loaded them as empty strings.
  Proven: review_comment_title IS NULL = 87,656, = '' = 0

### Implications for dbt staging
- Cast date columns from varchar to timestamp
- NULL handling differs from orders 


## raw.olist_customers

### Overview
- Total rows: 99,441
- Grain: one row per customer_id (one per order)

### Key finding: customer_id vs customer_unique_id
- customer_id is unique (99,441 distinct), it identifies a customer within a single order, not the person
- customer_unique_id has fewer distinct values (96,096), this is the real person identifier, stable across their orders
- 99,441 − 96,096 = 3,345 additional order records beyond each
  customer's first observed order

### Why it matters
- To count actual customers, use customer_unique_id (96,096), not 
  customer_id (which counts orders)
- customer_id joins 1-to-1 with orders; customer_unique_id groups 
  orders by person


## raw.olist_sellers

### Overview
- Total rows: 3,095
- Grain: one row per seller
  (seller_id is unique: 3,095 rows = 3,095 distinct)

### Business relevance
- Provides seller location (city, state) - Needed to describe where
  sellers associated with delayed orders are located


## raw.olist_order_payments

### Overview
- Total rows: 103,886
- Grain: one row per payment sequence within an order
  (order_id + payment_sequential is unique)

### Key finding
- order_id is NOT unique (103,886 vs 99,440 distinct) - an order can have multiple payment records
- The same order_id + payment_type combination can appear in multiple rows
- 1,091 order-payment type combinations appear more than once, so
  payment_type does not define the grain within an order
- Same fan-out pattern as reviews — both tables have multiple rows per order_id
- Watch for fan-out when joining on order_id
- Validation query: `exploration/queries/grain_validation_checks.sql`

## raw.olist_products

### Overview
- Total rows: 32,951
- Grain: one row per product (product_id is unique: 32,951 rows = 32,951 distinct).

### Key finding
- product_name_lenght + product_description_lenght
  Both have typo "lenght" (should be "length"), something that will be renamed in the staging layer


## raw.product_category_name_translation

### Overview
- Total rows: 71 (product_category_name is unique: 71 rows = 71 distinct)
- Grain: one row per category
- Two columns: product_category_name (Portuguese, the join key) and 
  product_category_name_english (the translation)

### Business relevance
- Translates category names PT → EN, making marts readable for 
  English-speaking stakeholders
- product_category_name is the join key to olist_products

## raw.olist_geolocation 

### Overview
- Total rows: 1,000,163
- Distinct zip code prefixes: 19,015
- Average: approximately 52.6 geolocation rows per zip code prefix

### Key finding
- zip_code_prefix is not unique, so joining geolocation directly to
  customers or sellers would create substantial fan-out
- Implication for dbt: aggregate to one representative point per zip
  (AVG lat/lng) in an intermediate model before joining to sellers/customers
