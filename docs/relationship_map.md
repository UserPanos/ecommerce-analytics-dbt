# Relationship Mapping and Data Quality Findings

This document summarizes the validated relationships between the raw Olist tables, the data-quality issues discovered during exploration, and the resulting modeling implications.

## 1. Orders → Customers

**Relationship:** `olist_orders → olist_customers`  
**Join key:** `customer_id`  
**Cardinality:** `1:1`

**Evidence:**  
`customer_id` is unique in both tables. Bidirectional orphan checks returned zero unmatched records.

**Result:**  
The `customer_id` key sets match exactly. There are no referential-integrity or coverage gaps.

**Modeling implication:**  
This join does not create fan-out because `customer_id` is unique on both sides.

---

## 2. Order Items → Orders

**Relationship:** `olist_order_items → olist_orders`  
**Join key:** `order_id`  
**Cardinality:** `N:1`

**Evidence:**  
`order_id` repeats in `olist_order_items` because an order may contain multiple items, while it is unique in `olist_orders`.

**Result:**  
No order-item rows reference missing orders. However, 775 orders have no matching order items.

**Modeling implication:**  
Joining order-level data to order items changes the grain from one row per order to one row per order item. Order-level measures may therefore be repeated across multiple item rows.

---

## 3. Order Items → Sellers

**Relationship:** `olist_order_items → olist_sellers`  
**Join key:** `seller_id`  
**Cardinality:** `N:1`

**Evidence:**  
`seller_id` repeats in `olist_order_items` because one seller can appear in many item rows, while it is unique in `olist_sellers`.

**Result:**  
No order-item rows reference missing sellers, and every seller appears in at least one order item.

**Modeling implication:**  
The seller table can be joined to order items without creating additional fan-out from the seller side.

---

## 4. Order Payments → Orders

**Relationship:** `olist_order_payments → olist_orders`  
**Join key:** `order_id`  
**Cardinality:** `N:1`

**Evidence:**  
`order_id` may appear multiple times in `olist_order_payments`, while it is unique in `olist_orders`.

**Result:**  
No payment rows reference missing orders. However, one delivered order has no matching payment record. The order contains three item rows, one seller, and an item-level value of 143.46.

**Modeling implication:**  
Payments must be aggregated to one row per order before they are joined to order-level or seller-level models. The missing payment record must be preserved and treated as a source-data anomaly rather than assumed to represent an unpaid order.

---

## 5. Order Reviews → Orders

**Relationship:** `olist_order_reviews → olist_orders`  
**Join key:** `order_id`  
**Cardinality:** `N:1`

**Evidence:**  
Some `order_id` values appear in multiple review rows, while `order_id` is unique in `olist_orders`.

**Result:**  
No review rows reference missing orders. However, 768 orders have no review record, including 646 delivered orders. The reason for the repeated review rows has not yet been verified.

**Modeling implication:**  
Reviews cannot be joined directly to item-level data without creating fan-out risk. Review records must first be investigated and reduced to a clearly defined order-level grain.

---

## 6. Products → Product Category Translation

**Relationship:** `olist_products → product_category_name_translation`  
**Join key:** `product_category_name`  
**Cardinality:** `N:1`

**Evidence:**  
Many products can share the same category, while the translation table contains one row per category.

**Result:**  
Two non-empty category values used by 13 products have no matching translation row. An additional 610 products have a `NULL` or blank category assignment. All 71 categories in the translation table are used by at least one product.

**Modeling implication:**  
Blank category values should be normalized to `NULL` during staging. Products with missing or untranslated categories must be preserved and assigned a documented fallback value rather than being removed by an inner join.

---

## 7. Order Items → Products

**Relationship:** `olist_order_items → olist_products`  
**Join key:** `product_id`  
**Cardinality:** `N:1`

**Evidence:**  
`product_id` repeats in `olist_order_items` because one product may appear in multiple item rows, while it is unique in `olist_products`.

**Result:**  
No order-item rows contain a null or unmatched `product_id`. Every product appears in at least one order item.

**Modeling implication:**  
Products can be joined to order items without creating additional fan-out from the product side.

---

## 8. Customers → Geolocation

**Relationship:** `olist_customers → olist_geolocation`  
**Join key:** `customer_zip_code_prefix = geolocation_zip_code_prefix`  
**Raw cardinality:** `M:N`

**Evidence:**  
Customer zip prefixes repeat across customers, and the raw geolocation table contains multiple coordinate rows for the same zip prefix.

**Result:**  
All customers have a non-null zip prefix. However, 278 customer rows use 157 distinct zip prefixes that do not exist in the geolocation key set.

**Modeling implication:**  
The raw geolocation table must first be reduced to one row per zip prefix before it is joined to customers. This prevents fan-out, but it does not resolve the 157 zip prefixes that are missing from geolocation.

---

## 9. Sellers → Geolocation

**Relationship:** `olist_sellers → olist_geolocation`  
**Join key:** `seller_zip_code_prefix = geolocation_zip_code_prefix`  
**Raw cardinality:** `M:N`

**Evidence:**  
Seller zip prefixes can repeat across sellers, and the raw geolocation table contains multiple coordinate rows for the same zip prefix.

**Result:**  
All sellers have a non-null zip prefix. However, seven sellers use seven distinct zip prefixes that do not exist in the geolocation key set.

**Modeling implication:**  
The raw geolocation table must first be reduced to one row per zip prefix before it is joined to sellers. Sellers without matching geolocation records must remain in downstream models with null location attributes.

---

## Cross-Table Modeling Risk: Seller Attribution

Orders and sellers do not have a direct relationship. Their connection is created through `olist_order_items`:

```text
olist_orders
→ olist_order_items
→ olist_sellers
```

The seller-participation analysis found:

- 98,666 orders represented in `olist_order_items`
- 1,278 multi-seller orders
- Approximately 1.30% of orders with items are multi-seller
- A maximum of five sellers within one order

Delivery delays and reviews are recorded at order level, while sellers are recorded at item level. For multi-seller orders, the dataset does not identify which seller caused a delivery delay or negative review.

**Proposed modeling approach:**  
Primary seller-performance metrics should avoid claiming direct causation. Single-seller orders are a candidate for the main attribution analysis, while multi-seller orders may be reported separately as an association or diagnostic segment. The final approach will be confirmed during mart design.

---

## Verification Note

Detailed row counts, distinct counts, orphan checks, reverse coverage checks, and anomaly-investigation queries are stored separately in the exploration SQL files.

This document focuses on the validated findings and modeling implications needed to understand the project quickly.