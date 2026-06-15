-- Top product category from each year
WITH category_revenue AS (
    SELECT
        EXTRACT(YEAR FROM o.order_date)::int AS yr,
        SPLIT_PART(p.part_type, ' ', 3) AS product_category,
        SUM(l.extended_price * (1 - l.discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.order_id = l.order_id
    JOIN part p ON l.part_id = p.part_id
    GROUP BY yr, product_category
),
ranked AS (
    SELECT
        yr,
        product_category,
        revenue,
        ROW_NUMBER() OVER (PARTITION BY yr ORDER BY revenue DESC) AS rn
    FROM category_revenue
)
SELECT yr, product_category, revenue
FROM ranked
WHERE rn = 1
ORDER BY yr;

-- Total Categories
select distinct p.part_type from part as p;

-- Save customer quarterly metrics to derivations schema
CREATE SCHEMA IF NOT EXISTS derivations;

DROP TABLE IF EXISTS derivations.customer_quarterly_metrics;

CREATE TABLE derivations.customer_quarterly_metrics AS
WITH customer_quarters AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('quarter', order_date)::date AS quarter
    FROM orders
),
customer_first_quarter AS (
    SELECT
        customer_id,
        MIN(quarter) AS first_quarter
    FROM customer_quarters
    GROUP BY customer_id
),
all_quarters AS (
    SELECT DISTINCT quarter FROM customer_quarters
),
quarterly_metrics AS (
    SELECT
        q.quarter,
        COUNT(DISTINCT cq.customer_id) AS active_customers,
        COUNT(DISTINCT cq.customer_id) FILTER (
            WHERE cf.first_quarter = q.quarter
        ) AS new_customers,
        COUNT(DISTINCT cq_prev.customer_id) AS prev_customers,
        COUNT(DISTINCT cq.customer_id) FILTER (
            WHERE cq_prev.customer_id IS NOT NULL
        ) AS retained_customers
    FROM all_quarters q
    LEFT JOIN customer_quarters cq ON cq.quarter = q.quarter
    LEFT JOIN customer_first_quarter cf ON cf.customer_id = cq.customer_id
    LEFT JOIN customer_quarters cq_prev ON cq_prev.customer_id = cq.customer_id
        AND cq_prev.quarter = q.quarter - INTERVAL '3 months'
    GROUP BY q.quarter
)
SELECT
    quarter,
    new_customers AS acquisitions,
    prev_customers - retained_customers AS lost_customers,
    retained_customers,
    ROUND(100.0 * new_customers / NULLIF(active_customers, 0), 2) AS acquisition_rate_pct,
    ROUND(100.0 * (prev_customers - retained_customers) / NULLIF(prev_customers, 0), 2) AS churn_rate_pct,
    ROUND(100.0 * retained_customers / NULLIF(prev_customers, 0), 2) AS retention_rate_pct
FROM quarterly_metrics
ORDER BY quarter;

--
