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