# Olist Data Exploration Notes

## raw.olist_orders

### Overview
- Total rows: 99,441
- Grain: one row per customer order, capturing the full order lifecycle 
  (purchase → approval → carrier handoff → customer delivery vs estimated date)
- Note: each customer_id appears exactly once (every customer has only one order in this dataset)

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
- Grain: one row per product within an order (order_id + order_item_id)

### Business relevance
- seller_id: the bridge between an order and the seller who fulfilled it
- Critical for the business problem (delivery delays → bad reviews → identify slow sellers)

## raw.olist_order_reviews

### Overview 
- Total rows: 99,224
- Grain: one row per review per order (review_id + order_id)

### Key finding: neither ID is unique on its own
- order_id is NOT unique (99,224 vs 98,673 distinct) — an order can have multiple reviews
- review_id is NOT unique (99,224 vs 98,410 distinct) — one review can span multiple orders
- Only the combination is unique → watch for fan-out when joining on order_id

### Data quality issues
- Some columns (like 'review_comment_title' and 'review_comment_message') failed during load because their varchar limit was too small, so the type was changed to 'text'
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
- 99,441 − 96,096 = 3,345 repeat purchases (same person, new order)

### Why it matters
- To count actual customers, use customer_unique_id (96,096), not 
  customer_id (which counts orders)
- customer_id joins 1-to-1 with orders; customer_unique_id groups 
  orders by person