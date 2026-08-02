# Olist Marketplace Data Pipeline

A work-in-progress end-to-end data engineering project built around the
Olist Brazilian marketplace dataset, with a strong analytics engineering
foundation in dbt, testing, and dimensional modeling.

> 🚧 **Work in progress**

## Business Problem

Olist operates a multi-seller marketplace where delayed deliveries
may negatively affect customer satisfaction and create operational risk.
The company needs a reliable way to understand whether orders delivered
after the estimated delivery date are associated with lower review scores
and where these patterns are concentrated.

This project analyzes delivery performance, customer reviews,
and seller participation to identify sellers that are frequently associated
with delayed and poorly reviewed orders.
Because a single order can contain products from multiple sellers,
the analysis does not assume that one seller directly caused the delay or the review outcome.

The final models and dashboard are intended to help Olist's operations
and seller-performance teams prioritize which sellers and order patterns
require deeper investigation, monitoring, or support.
