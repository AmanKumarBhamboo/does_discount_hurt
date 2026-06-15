-- 1A. Discount-to-Return Ratio by Customer Segment
--     Identifies the discount % at which return rate spikes

DROP TABLE IF EXISTS discount_return_ratio_by_segment;

CREATE TABLE discount_return_ratio_by_segment AS
SELECT
    c.market_segment,
    l.discount * 100                                        AS discount_pct,
    COUNT(*)                                                AS total_items,
    COUNT(*) FILTER (WHERE l.return_flag = 'R')             AS returned,
    COUNT(*) FILTER (WHERE l.return_flag = 'A')             AS accepted,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE l.return_flag = 'R')
        / NULLIF(COUNT(*) FILTER (WHERE l.return_flag IN ('A', 'R')), 0),
        2
    )                                                       AS return_rate_pct
FROM public.lineitem l
JOIN public.orders o USING (order_id)
JOIN public.customer c ON c.customer_id = o.customer_id
GROUP BY c.market_segment, l.discount
ORDER BY c.market_segment, l.discount;

-- -------------------------------------------------------
-- 1B. Product Margin Erosion Score
--     Compares net revenue after discount to retail price
-- -------------------------------------------------------

DROP TABLE IF EXISTS product_margin_erosion;

CREATE TABLE product_margin_erosion AS
SELECT
    p.part_id,
    p.part_type,
    p.manufacturer,
    p.brand,
    p.retail_price,
    AVG(l.extended_price / NULLIF(l.quantity, 0))          AS avg_selling_price,
    ROUND(AVG(l.discount) * 100, 2)                        AS avg_discount_pct,
    ROUND(MAX(l.discount) * 100, 2)                        AS max_discount_pct,
    SUM(l.quantity)                                         AS total_quantity,
    SUM(l.extended_price * (1 - l.discount))                AS net_revenue,
    SUM(l.extended_price * l.discount)                      AS total_discount_erosion,
    ROUND(
        AVG(l.extended_price * (1 - l.discount) / NULLIF(l.quantity, 0))
        / NULLIF(AVG(p.retail_price), 0) * 100,
        2
    )                                                       AS pct_of_retail_achieved,
    ROUND(
        100.0 * SUM(l.extended_price * l.discount)
        / NULLIF(SUM(l.extended_price), 0),
        2
    )                                                       AS margin_erosion_score,
    CASE
        WHEN AVG(l.discount) >= 0.08 THEN 'critical'
        WHEN AVG(l.discount) >= 0.05 THEN 'warning'
        ELSE 'healthy'
    END                                                     AS margin_health_status
FROM public.lineitem l
JOIN public.part p ON p.part_id = l.part_id
GROUP BY p.part_id, p.part_type, p.manufacturer, p.brand, p.retail_price
ORDER BY margin_erosion_score DESC;

-- -------------------------------------------------------
-- 1C. Demand Elasticity Score
--     % change in quantity / % change in price per category
-- -------------------------------------------------------

DROP TABLE IF EXISTS demand_elasticity;

CREATE TABLE demand_elasticity AS
WITH category_discount_volume AS (
    SELECT
        SPLIT_PART(p.part_type, ' ', 3)                     AS product_category,
        l.discount,
        ROUND(AVG(l.extended_price / NULLIF(l.quantity, 0)), 2)
                                                            AS avg_base_price,
        SUM(l.quantity)                                      AS total_quantity,
        COUNT(DISTINCT l.order_id)                           AS order_count
    FROM public.lineitem l
    JOIN public.part p ON p.part_id = l.part_id
    GROUP BY product_category, l.discount
),
with_prev AS (
    SELECT
        product_category,
        discount                                              AS discount_raw,
        discount * 100                                        AS discount_pct,
        total_quantity,
        avg_base_price,
        LAG(total_quantity) OVER (PARTITION BY product_category ORDER BY discount)
                                                              AS prev_quantity,
        LAG(discount) OVER (PARTITION BY product_category ORDER BY discount)
                                                              AS prev_discount_raw,
        LAG(avg_base_price) OVER (PARTITION BY product_category ORDER BY discount)
                                                              AS prev_base_price
    FROM category_discount_volume
)
SELECT
    product_category,
    discount_pct,
    total_quantity,
    prev_quantity,
    CASE
        WHEN prev_quantity IS NOT NULL AND prev_quantity > 0
            THEN ROUND((total_quantity - prev_quantity) * 100.0 / prev_quantity, 2)
    END                                                      AS qty_change_pct,
    CASE
        WHEN prev_discount_raw IS NOT NULL AND prev_discount_raw < 1
            THEN ROUND(
                (prev_discount_raw - discount_raw) * 100.0
                / NULLIF(1 - prev_discount_raw, 0),
                4
            )
    END                                                      AS price_change_pct,
    CASE
        WHEN prev_quantity IS NOT NULL AND prev_quantity > 0
            AND prev_discount_raw IS NOT NULL AND prev_discount_raw < 1
            AND (total_quantity - prev_quantity) * 100.0 / prev_quantity != 0
            AND (prev_discount_raw - discount_raw) * 100.0 / (1 - prev_discount_raw) != 0
            THEN ROUND(
                ((total_quantity - prev_quantity) * 100.0 / prev_quantity)
                / NULLIF(
                    (prev_discount_raw - discount_raw) * 100.0 / (1 - prev_discount_raw),
                    0
                ),
                2
            )
    END                                                      AS elasticity_score
FROM with_prev
ORDER BY product_category, discount_pct;

-- ====================================================================
-- PHASE 2: COHORT ANALYSIS & CUSTOMER SEGMENTATION
-- ====================================================================

-- -------------------------------------------------------
-- 2A. Discount Hunters
--     Customers who purchase only when discount > 5%
-- -------------------------------------------------------

DROP TABLE IF EXISTS discount_hunters;

CREATE TABLE discount_hunters AS
WITH customer_discount_profile AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER (WHERE l.discount > 0.05)
                                                            AS high_discount_orders,
        ROUND(AVG(l.discount) * 100, 2)                     AS avg_discount_pct,
        SUM(l.extended_price * (1 - l.discount))            AS total_spent,
        SUM(l.extended_price * l.discount)                  AS total_discount_received,
        MIN(o.order_date)                                   AS first_order,
        MAX(o.order_date)                                   AS last_order
    FROM public.orders o
    JOIN public.lineitem l USING (order_id)
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_orders,
    high_discount_orders,
    avg_discount_pct,
    total_spent,
    total_discount_received,
    first_order,
    last_order,
    ROUND(
        100.0 * high_discount_orders / NULLIF(total_orders, 0), 2
    )                                                       AS hunter_score,
    CASE
        WHEN total_orders = 1 AND high_discount_orders = 1 THEN 'one_time_hunter'
        WHEN 100.0 * high_discount_orders / total_orders >= 80 THEN 'core_hunter'
        WHEN 100.0 * high_discount_orders / total_orders >= 50 THEN 'opportunistic'
        ELSE 'not_hunter'
    END                                                     AS hunter_segment,
    EXTRACT(YEAR FROM age(last_order, first_order)) * 12
        + EXTRACT(MONTH FROM age(last_order, first_order))  AS customer_lifetime_months,
    ROUND(
        SUM(total_spent) OVER ()
        / NULLIF(COUNT(*) OVER (), 0), 2
    )                                                       AS avg_customer_ltv
FROM customer_discount_profile
WHERE high_discount_orders > 0
    AND 100.0 * high_discount_orders / NULLIF(total_orders, 0) >= 50
ORDER BY hunter_score DESC;

-- -------------------------------------------------------
-- 2B. Loyalists
--     Customers who order regularly even without discounts
-- -------------------------------------------------------

DROP TABLE IF EXISTS loyalists;

CREATE TABLE loyalists AS
WITH customer_loyalty_profile AS (
    SELECT
        o.customer_id,
        COUNT(DISTINCT o.order_id)                          AS total_orders,
        COUNT(DISTINCT o.order_id) FILTER (WHERE l.discount = 0)
                                                            AS full_price_orders,
        COUNT(DISTINCT o.order_id) FILTER (WHERE l.discount > 0)
                                                            AS discounted_orders,
        ROUND(AVG(l.discount) * 100, 2)                     AS avg_discount_pct,
        SUM(l.extended_price * (1 - l.discount))            AS total_spent,
        MIN(o.order_date)                                   AS first_order,
        MAX(o.order_date)                                   AS last_order,
        MAX(o.order_date) - MIN(o.order_date)               AS active_span_days
    FROM public.orders o
    JOIN public.lineitem l USING (order_id)
    GROUP BY o.customer_id
)
SELECT
    customer_id,
    total_orders,
    full_price_orders,
    discounted_orders,
    avg_discount_pct,
    total_spent,
    first_order,
    last_order,
    active_span_days,
    ROUND(
        100.0 * full_price_orders / NULLIF(total_orders, 0), 2
    )                                                       AS loyalty_score,
    CASE
        WHEN discounted_orders = 0 THEN 'pure_loyalist'
        WHEN 100.0 * full_price_orders / total_orders >= 70 THEN 'mostly_loyalist'
        ELSE 'casual'
    END                                                     AS loyalty_segment
FROM customer_loyalty_profile
WHERE full_price_orders > 0
    AND 100.0 * full_price_orders / NULLIF(total_orders, 0) >= 70
ORDER BY loyalty_score DESC;

-- -------------------------------------------------------
-- 2C. Urgency Exploiters
--     Customers who request urgent delivery AND get discounts
-- -------------------------------------------------------

DROP TABLE IF EXISTS urgency_exploiters;

CREATE TABLE urgency_exploiters AS
SELECT
    o.customer_id,
    COUNT(DISTINCT o.order_id)                              AS total_orders,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.priority IN ('1-URGENT', '2-HIGH')
          AND l.discount > 0
    )                                                       AS urgent_discounted_orders,
    COUNT(DISTINCT o.order_id) FILTER (
        WHERE o.priority IN ('1-URGENT', '2-HIGH')
    )                                                       AS urgent_orders,
    COUNT(DISTINCT o.order_id) FILTER (WHERE l.discount > 0)
                                                            AS discounted_orders,
    ROUND(
        AVG(l.discount) FILTER (WHERE o.priority IN ('1-URGENT', '2-HIGH'))
        * 100, 2
    )                                                       AS urgent_avg_discount_pct,
    ROUND(AVG(l.discount) * 100, 2)                         AS overall_avg_discount_pct,
    SUM(l.extended_price * l.discount) FILTER (
        WHERE o.priority IN ('1-URGENT', '2-HIGH')
    )                                                       AS urgent_discount_erosion,
    SUM(l.extended_price * (1 - l.discount)) FILTER (
        WHERE o.priority IN ('1-URGENT', '2-HIGH')
    )                                                       AS urgent_net_revenue
FROM public.orders o
JOIN public.lineitem l USING (order_id)
GROUP BY o.customer_id
HAVING COUNT(DISTINCT o.order_id) FILTER (
           WHERE o.priority IN ('1-URGENT', '2-HIGH')
             AND l.discount > 0
       ) > 0
ORDER BY urgent_discounted_orders DESC, urgent_discount_erosion DESC;

-- ====================================================================
-- PHASE 3: ROOT CAUSE ANALYSIS (Diagnostic)
-- ====================================================================

-- -------------------------------------------------------
-- 3A. Clerk / Salesman Discount Leakage
--     Which clerks give excessive discounts without extra revenue?
-- -------------------------------------------------------

DROP TABLE IF EXISTS clerk_discount_leakage;

CREATE TABLE clerk_discount_leakage AS
SELECT
    o.clerk,
    COUNT(DISTINCT o.order_id)                              AS orders_handled,
    COUNT(*)                                                AS line_items,
    ROUND(AVG(l.discount) * 100, 2)                         AS avg_discount_pct,
    ROUND(
        AVG(l.discount) * 100
        - AVG(AVG(l.discount) * 100) OVER (),
        2
    )                                                       AS deviation_from_org_avg,
    SUM(l.extended_price * (1 - l.discount))                AS net_revenue_generated,
    SUM(l.extended_price * l.discount)                      AS total_discount_given,
    ROUND(
        SUM(l.extended_price * l.discount) * 100.0
        / NULLIF(SUM(l.extended_price * (1 - l.discount)), 0),
        2
    )                                                       AS discount_leakage_ratio,
    ROUND(
        SUM(l.extended_price * l.discount)
        / NULLIF(COUNT(DISTINCT o.order_id), 0),
        2
    )                                                       AS avg_discount_per_order,
    CASE
        WHEN AVG(l.discount) * 100 > (
            SELECT AVG(discount) * 100 + 2 * STDDEV(discount)
            FROM public.lineitem
        ) THEN 'high_risk_leak'
        WHEN AVG(l.discount) * 100 > (
            SELECT AVG(discount) * 100 + STDDEV(discount)
            FROM public.lineitem
        ) THEN 'moderate_leak'
        ELSE 'normal'
    END                                                     AS leak_risk_level
FROM public.orders o
JOIN public.lineitem l USING (order_id)
GROUP BY o.clerk
ORDER BY discount_leakage_ratio DESC;

-- -------------------------------------------------------
-- 3B. Shipping Mode vs Discount Paradox
--     High discount + expensive shipping = negative profit?
-- -------------------------------------------------------

DROP TABLE IF EXISTS shipping_discount_paradox;

CREATE TABLE shipping_discount_paradox AS
WITH shipping_profitability AS (
    SELECT
        l.shipping_mode,
        l.shipping_instructions,
        CASE
            WHEN l.discount >= 0.07 THEN 'high'
            WHEN l.discount >= 0.03 THEN 'medium'
            ELSE 'low'
        END                                                 AS discount_tier,
        l.discount * 100                                    AS discount_pct,
        COUNT(*)                                            AS line_items,
        SUM(l.quantity)                                     AS total_quantity,
        SUM(l.extended_price * (1 - l.discount))            AS net_revenue,
        SUM(l.extended_price * l.discount)                  AS discount_erosion,
        SUM(l.extended_price * (1 - l.discount) * l.tax)    AS tax_collected,
        COUNT(*) FILTER (WHERE l.return_flag = 'R')         AS returns,
        ROUND(
            100.0 * COUNT(*) FILTER (WHERE l.return_flag = 'R')
            / NULLIF(COUNT(*) FILTER (WHERE l.return_flag IN ('A', 'R')), 0),
            2
        )                                                   AS return_rate_pct
    FROM public.lineitem l
    GROUP BY l.shipping_mode, l.shipping_instructions, l.discount
)
SELECT
    shipping_mode,
    shipping_instructions,
    discount_tier,
    COUNT(*)                                                AS distinct_discount_levels,
    SUM(line_items)                                         AS total_line_items,
    SUM(total_quantity)                                     AS total_quantity,
    ROUND(AVG(discount_pct), 2)                             AS avg_discount_pct,
    SUM(net_revenue)                                        AS total_net_revenue,
    SUM(discount_erosion)                                   AS total_discount_erosion,
    SUM(returns)                                            AS total_returns,
    ROUND(AVG(return_rate_pct), 2)                          AS avg_return_rate_pct,
    CASE
        WHEN SUM(discount_erosion) > SUM(net_revenue) * 0.10 THEN 'profit_risk'
        ELSE 'acceptable'
    END                                                     AS paradox_flag
FROM shipping_profitability
GROUP BY shipping_mode, shipping_instructions, discount_tier
ORDER BY total_discount_erosion DESC;

-- -------------------------------------------------------
-- Combined Health Index Dashboard
-- -------------------------------------------------------

DROP TABLE IF EXISTS discount_health_index;

CREATE TABLE discount_health_index AS
WITH metrics AS (
    SELECT
        'avg_discount_pct'                                  AS metric,
        ROUND(AVG(discount) * 100, 2)::text                 AS value
    FROM public.lineitem
    UNION ALL
    SELECT 'overall_return_rate_pct',
        ROUND(100.0 * COUNT(*) FILTER (WHERE return_flag = 'R')
            / NULLIF(COUNT(*) FILTER (WHERE return_flag IN ('A', 'R')), 0), 2)::text
    FROM public.lineitem
    UNION ALL
    SELECT 'total_discount_erosion',
        ROUND(SUM(extended_price * discount), 2)::text
    FROM public.lineitem
    UNION ALL
    SELECT 'urgent_order_discount_pct',
        ROUND(AVG(l.discount) * 100, 2)::text
    FROM public.lineitem l
    JOIN public.orders o USING (order_id)
    WHERE o.priority IN ('1-URGENT', '2-HIGH')
)
SELECT metric, value FROM metrics;

-- Show summary
SELECT 'discount_hunters' AS tbl, COUNT(*) AS rows FROM discount_hunters
UNION ALL SELECT 'loyalists', COUNT(*) FROM loyalists
UNION ALL SELECT 'urgency_exploiters', COUNT(*) FROM urgency_exploiters
UNION ALL SELECT 'clerk_discount_leakage', COUNT(*) FROM clerk_discount_leakage
UNION ALL SELECT 'shipping_discount_paradox', COUNT(*) FROM shipping_discount_paradox
UNION ALL SELECT 'demand_elasticity', COUNT(*) FROM demand_elasticity
UNION ALL SELECT 'product_margin_erosion', COUNT(*) FROM product_margin_erosion
UNION ALL SELECT 'discount_return_ratio_by_segment', COUNT(*) FROM discount_return_ratio_by_segment
UNION ALL SELECT 'discount_health_index', COUNT(*) FROM discount_health_index;
