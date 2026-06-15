-- Derivations Schema: Discount Impact Analysis
-- Covers 4 business concepts:
--   1. Volume vs Margin Tug of War
--   2. Return Traps (Impulsive Buying)
--   3. Price Anchoring & Brand Erosion
--   4. Operational Discount Leakage
-- ==========================================================

-- ==========================================================
-- 1. Volume vs Margin Tug of War
--    For each discount level, compare volume gain vs margin loss
-- ==========================================================

DROP TABLE IF EXISTS discount_volume_margin;

CREATE TABLE discount_volume_margin AS
SELECT
    discount * 100                      AS discount_pct,
    COUNT(*)                            AS line_items,
    SUM(quantity)                       AS total_quantity,
    SUM(extended_price)                 AS gross_revenue,
    SUM(extended_price * (1 - discount)) AS net_revenue,
    SUM(extended_price * discount)      AS discount_erosion,
    ROUND(
        SUM(extended_price * (1 - discount)) / NULLIF(SUM(quantity), 0), 2
    )                                   AS avg_unit_revenue,
    COUNT(DISTINCT order_id)            AS order_count,
    COUNT(DISTINCT part_id)             AS part_count,
    COUNT(DISTINCT customer_id)         AS customer_count
FROM public.lineitem
JOIN public.orders USING (order_id)
GROUP BY discount
ORDER BY discount;

-- ==========================================================
-- 2. Return Traps — Impulsive Buying Cost
--    Do higher discounts correlate with higher return rates?
-- ==========================================================

DROP TABLE IF EXISTS discount_return_analysis;

CREATE TABLE discount_return_analysis AS
SELECT
    discount * 100                                  AS discount_pct,
    COUNT(*)                                        AS total_items,
    COUNT(*) FILTER (WHERE return_flag = 'R')       AS returned_items,
    COUNT(*) FILTER (WHERE return_flag = 'A')       AS accepted_items,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE return_flag = 'R')
        / NULLIF(COUNT(*) FILTER (WHERE return_flag IN ('A', 'R')), 0),
        2
    )                                               AS return_rate_pct,
    ROUND(
        SUM(extended_price * discount) FILTER (WHERE return_flag = 'R'),
        2
    )                                               AS discount_on_returns
FROM public.lineitem
GROUP BY discount
ORDER BY discount;

-- ==========================================================
-- 3. Price Anchoring & Brand Erosion
--    How does cumulative discount exposure affect
--    a customer's future purchase behavior?
-- ==========================================================

DROP TABLE IF EXISTS customer_discount_sensitivity;

CREATE TABLE customer_discount_sensitivity AS
WITH customer_discount_stats AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)                      AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER (
            WHERE l.discount > 0
        )                                               AS discounted_orders,
        ROUND(AVG(l.discount) * 100, 2)                 AS avg_discount_pct,
        ROUND(MAX(l.discount) * 100, 2)                 AS max_discount_pct,
        MIN(o.order_date)                               AS first_order_date,
        MAX(o.order_date)                               AS last_order_date,
        SUM(l.extended_price * l.discount)              AS total_discount_received
    FROM public.orders o
    JOIN public.lineitem l USING (order_id)
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_orders,
    discounted_orders,
    avg_discount_pct,
    max_discount_pct,
    first_order_date,
    last_order_date,
    total_discount_received,
    ROUND(
        100.0 * discounted_orders / NULLIF(total_orders, 0), 2
    )                                                   AS discount_frequency_pct,
    CASE
        WHEN avg_discount_pct >= 5 THEN 'highly_discount_sensitive'
        WHEN avg_discount_pct >= 2 THEN 'moderately_sensitive'
        ELSE 'low_sensitivity'
    END                                                 AS discount_sensitivity_segment
FROM customer_discount_stats
ORDER BY total_discount_received DESC;

-- ==========================================================
-- 4. Operational Discount Leakage
--    Discounts given on urgent / high-priority orders
--    where full price would have been acceptable
-- ==========================================================

DROP TABLE IF EXISTS operational_discount_leakage;

CREATE TABLE operational_discount_leakage AS
SELECT
    o.priority,
    l.shipping_instructions,
    l.shipping_mode,
    COUNT(*)                                        AS total_line_items,
    ROUND(AVG(l.discount) * 100, 2)                 AS avg_discount_pct,
    ROUND(AVG(l.discount) * 100, 2)
        - MIN(AVG(l.discount) * 100) OVER ()        AS excess_vs_min,
    SUM(l.extended_price * l.discount)              AS total_discount_given,
    COUNT(*) FILTER (WHERE l.discount > 0)          AS discounted_items,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE l.discount > 0)
        / NULLIF(COUNT(*), 0), 2
    )                                               AS discount_incidence_pct
FROM public.lineitem l
JOIN public.orders o USING (order_id)
GROUP BY o.priority, l.shipping_instructions, l.shipping_mode
ORDER BY total_discount_given DESC;

-- ==========================================================
-- Summary: show all created tables
-- ==========================================================


