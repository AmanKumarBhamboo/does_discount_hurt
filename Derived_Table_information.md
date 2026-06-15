# Derived Tables — `derivations` Schema

17 tables in the `derivations` schema, organized by purpose.

---

## Helper / Intermediate Tables

### `all_quarters`
**Rows:** 27  
**Purpose:** Distinct list of all quarters present in the order data. Used as the backbone for time-series aggregations.

| Column | Type | Description |
|--------|------|-------------|
| quarter | date | Quarter start date (e.g. 1992-01-01) |

**Sample:**
```
 1992-01-01
 1992-04-01
 1992-07-01
```

---

### `customer_quarters`
**Rows:** 1,119,843  
**Purpose:** Distinct customer × quarter combinations. Each row means that customer placed at least one order in that quarter.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier |
| quarter | date | Quarter in which the customer placed an order |

**Sample:**
```
 customer_id |  quarter
-------------+------------
       65146 | 1995-07-01
      135028 | 1995-07-01
      139369 | 1993-01-01
```

---

### `customer_first_quarter`
**Rows:** 99,996  
**Purpose:** The first quarter in which each customer ever placed an order. Used to identify new (acquired) customers per quarter.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier (PK) |
| first_quarter | date | Earliest quarter the customer appears |

**Sample:**
```
 customer_id | first_quarter
-------------+---------------
           1 | 1992-04-01
           2 | 1992-04-01
           4 | 1992-04-01
```

---

### `customer_quarterly_metrics`
**Rows:** 27  
**Purpose:** Per-quarter customer acquisition, churn, and retention metrics. Built from `customer_quarters` and `customer_first_quarter`.

| Column | Type | Description |
|--------|------|-------------|
| quarter | date | Quarter |
| acquisitions | bigint | New customers acquired this quarter |
| lost_customers | bigint | Customers active in previous quarter but not this quarter |
| retained_customers | bigint | Customers active in both previous and current quarter |
| acquisition_rate_pct | numeric | acquisitions / active_customers × 100 |
| churn_rate_pct | numeric | lost_customers / prev_customers × 100 |
| retention_rate_pct | numeric | retained_customers / prev_customers × 100 |

**Sample:**
```
  quarter   | acquisitions | lost | retained | acq_rate | churn_rate | retention
 1992-01-01 |        42247 |    0 |        0 |   100.00 |            |
 1992-04-01 |        23068 |    0 |    18918 |    54.94 |       0.00 |    100.00
 1992-07-01 |        13305 |    0 |    18918 |    31.50 |       0.00 |    100.00
```

---

## Phase 1 — Discount Health Index

### `discount_volume_margin`
**Rows:** 11  
**Purpose:** The Volume vs Margin Tug of War — for each discount level (0%–10%), compares gross revenue, net revenue after discount, and total discount erosion.

| Column | Type | Description |
|--------|------|-------------|
| discount_pct | numeric | Discount percentage (0.00 to 10.00) |
| line_items | bigint | Total line items at this discount |
| total_quantity | numeric | Total units sold |
| gross_revenue | numeric | Revenue before discount (extended_price) |
| net_revenue | numeric | Revenue after discount |
| discount_erosion | numeric | Total discount given |
| avg_unit_revenue | numeric | Net revenue per unit after discount |
| order_count | bigint | Distinct orders |
| part_count | bigint | Distinct parts sold |
| customer_count | bigint | Distinct customers |

**Sample:**
```
 discount_pct | line_items | total_qty   | gross_revenue   | net_revenue     | erosion
         0.00 |     544886 | 13910779.00 | 20864194594.11  | 20864194594.11  |     0.00
         1.00 |     545834 | 13922569.00 | 20879360592.52  | 20670566986.59  |   208793605.93
         2.00 |     546173 | 13937010.00 | 20893021299.88  | 20475160873.88  |   417860425.99
```

---

### `discount_return_analysis`
**Rows:** 11  
**Purpose:** Return Traps — correlates discount level with return rate and total discount amount applied to returned items.

| Column | Type | Description |
|--------|------|-------------|
| discount_pct | numeric | Discount percentage |
| total_items | bigint | Total line items |
| returned_items | bigint | Items marked return_flag = 'R' |
| accepted_items | bigint | Items marked return_flag = 'A' |
| return_rate_pct | numeric | returned / (returned + accepted) × 100 |
| discount_on_returns | numeric | Discount amount given on items that were later returned |

**Sample:**
```
 discount_pct | total_items | returned | accepted | return_rate | discount_on_returns
         0.00 |      544886 |   134300 |   133929 |       50.07 |                0.00
         1.00 |      545834 |   134615 |   134555 |       50.01 |         51518039.94
         2.00 |      546173 |   134209 |   135095 |       49.84 |        102703575.98
```

---

### `discount_return_ratio_by_segment`
**Rows:** 55 (5 segments × 11 discount levels)  
**Purpose:** Discount-to-Return Ratio segmented by `market_segment` — identifies which customer segments spike in returns at specific discount levels.

| Column | Type | Description |
|--------|------|-------------|
| market_segment | char(10) | Customer market segment (AUTOMOBILE, BUILDING, FURNITURE, HOUSEHOLD, MACHINERY) |
| discount_pct | numeric | Discount percentage |
| total_items | bigint | Total line items |
| returned | bigint | Returned items |
| accepted | bigint | Accepted items |
| return_rate_pct | numeric | Return rate within this segment × discount level |

**Sample:**
```
 market_segment | discount_pct | total_items | returned | accepted | return_rate
 AUTOMOBILE     |         0.00 |      107971 |    26671 |    26496 |       50.16
 AUTOMOBILE     |         1.00 |      108140 |    26644 |    26932 |       49.73
 AUTOMOBILE     |         2.00 |      108160 |    26480 |    26739 |       49.76
```

---

### `product_margin_erosion`
**Rows:** 200,000  
**Purpose:** Margin Erosion Score per product — compares achieved selling price after discount to the retail price to flag products crossing minimum sustainable margin thresholds.

| Column | Type | Description |
|--------|------|-------------|
| part_id | integer | Part identifier |
| part_type | varchar(25) | Part type description |
| manufacturer | char(25) | Manufacturer name |
| brand | char(10) | Brand |
| retail_price | numeric | Manufacturer's retail price |
| avg_selling_price | numeric | Average actual selling price (extended_price / quantity) |
| avg_discount_pct | numeric | Average discount percentage applied |
| max_discount_pct | numeric | Maximum discount percentage applied |
| total_quantity | numeric | Total units sold |
| net_revenue | numeric | Revenue after discount |
| total_discount_erosion | numeric | Total discount amount |
| pct_of_retail_achieved | numeric | (avg_selling_price / retail_price) × 100 |
| margin_erosion_score | numeric | (total_discount_erosion / gross_revenue) × 100 |
| margin_health_status | text | 'critical' (≥8% avg discount), 'warning' (≥5%), 'healthy' (<5%) |

**Sample:**
```
 part_id | part_type            | manufacturer  | retail_price | avg_selling_price | avg_disc | margin_health
  130800 | LARGE ANODIZED STEEL | Manufacturer#4 |      1830.80 |         1830.80   |    7.62  | warning
   14088 | SMALL ANODIZED TIN   | Manufacturer#3 |      1002.08 |         1002.08   |    7.48  | warning
  182112 | LARGE PLATED STEEL   | Manufacturer#3 |      1194.11 |         1194.11   |    7.35  | warning
```

---

### `demand_elasticity`
**Rows:** 55 (5 product categories × 11 discount levels)  
**Purpose:** Price Elasticity of Demand — measures whether a 1% increase in discount leads to >1% increase in sales volume. Product category is derived as the last word of `part_type` (base metal).

| Column | Type | Description |
|--------|------|-------------|
| product_category | text | Base metal category (BRASS, COPPER, NICKEL, STEEL, TIN) |
| discount_pct | numeric | Discount percentage |
| total_quantity | numeric | Total units sold at this discount level |
| prev_quantity | numeric | Units sold at previous discount level |
| qty_change_pct | numeric | % change in quantity from previous discount level |
| price_change_pct | numeric | % change in net price from previous discount level |
| elasticity_score | numeric | qty_change_pct / price_change_pct ( >1 = elastic, <1 = inelastic) |

**Sample:**
```
 category | discount_pct | total_quantity | qty_change | price_change | elasticity
 BRASS    |         0.00 |     2799636.00 |            |              |
 BRASS    |         1.00 |     2767331.00 |      -1.15 |       -1.0000 |       1.15
 BRASS    |         2.00 |     2784186.00 |       0.61 |       -1.0101 |      -0.60
```

---

### `discount_health_index`
**Rows:** 4  
**Purpose:** Dashboard KPI summary — overall health metrics for the entire discount strategy.

| Column | Type | Description |
|--------|------|-------------|
| metric | text | KPI name |
| value | text | KPI value |

**Rows:**
| metric | value |
|--------|-------|
| avg_discount_pct | 5.00 |
| total_discount_erosion | 11,475,087,016.20 |
| overall_return_rate_pct | 50.01 |
| urgent_order_discount_pct | 5.00 |

---

## Phase 2 — Cohort Analysis

### `discount_hunters`
**Rows:** 99,608  
**Purpose:** Customers who purchase primarily when discounts exceed 5%. Includes hunter score, segment, lifetime value, and lifetime months.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier |
| total_orders | bigint | Total orders placed |
| high_discount_orders | bigint | Orders with discount > 5% |
| avg_discount_pct | numeric | Average discount received |
| total_spent | numeric | Total net revenue from this customer |
| total_discount_received | numeric | Total discount given to this customer |
| first_order | date | Date of first order |
| last_order | date | Date of most recent order |
| hunter_score | numeric | (high_discount_orders / total_orders) × 100 |
| hunter_segment | text | 'core_hunter' (≥80%), 'opportunistic' (≥50%), 'one_time_hunter' (single order at high discount) |
| customer_lifetime_months | numeric | Months between first and last order |
| avg_customer_ltv | numeric | Average LTV across all hunters |

**Sample:**
```
 customer_id | total_orders | high_disc_orders | hunter_score | hunter_segment | lifetime_months
       28592 |           11 |              11  |       100.00 | core_hunter    |              68
       30551 |            5 |               5  |       100.00 | core_hunter    |              47
```

---

### `loyalists`
**Rows:** 611  
**Purpose:** Customers who place regular orders even without discounts (≥70% of orders at full price).

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier |
| total_orders | bigint | Total orders placed |
| full_price_orders | bigint | Orders with 0% discount |
| discounted_orders | bigint | Orders with discount > 0% |
| avg_discount_pct | numeric | Average discount across all orders |
| total_spent | numeric | Total net revenue |
| first_order | date | Date of first order |
| last_order | date | Date of most recent order |
| active_span_days | integer | Days between first and last order |
| loyalty_score | numeric | (full_price_orders / total_orders) × 100 |
| loyalty_segment | text | 'pure_loyalist' (no discounted orders), 'mostly_loyalist' (≥70% full price) |

**Sample:**
```
 customer_id | total_orders | full_price | disc_orders | loyalty_score | loyalty_segment
       67328 |            1 |          1 |           1 |        100.00 | mostly_loyalist
      122090 |            3 |          3 |           3 |        100.00 | mostly_loyalist
```

---

### `urgency_exploiters`
**Rows:** 98,992  
**Purpose:** Customers who request urgent/high-priority delivery while also receiving discounts — indicating potential revenue leakage.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier |
| total_orders | bigint | Total orders placed |
| urgent_discounted_orders | bigint | Urgent orders (priority 1-URGENT or 2-HIGH) that received a discount |
| urgent_orders | bigint | Total urgent orders |
| discounted_orders | bigint | Total discounted orders |
| urgent_avg_discount_pct | numeric | Average discount on urgent orders |
| overall_avg_discount_pct | numeric | Average discount across all orders |
| urgent_discount_erosion | numeric | Total discount erosion on urgent orders |
| urgent_net_revenue | numeric | Net revenue from urgent orders |

**Sample:**
```
 customer_id | total_orders | urgent_discounted | urgent_disc_pct | urgent_erosion
       15859 |           30 |                21 |            5.22 |     196134.17
       99070 |           28 |                21 |            4.90 |     191042.11
```

---

## Phase 3 — Root Cause Analysis

### `clerk_discount_leakage`
**Rows:** 1,000  
**Purpose:** Clerk-level discount analysis — identifies sales agents who provide excessive discounts without generating proportional revenue.

| Column | Type | Description |
|--------|------|-------------|
| clerk | char(15) | Clerk identifier |
| orders_handled | bigint | Distinct orders handled |
| line_items | bigint | Total line items processed |
| avg_discount_pct | numeric | Average discount given by this clerk |
| deviation_from_org_avg | numeric | Clerk's avg discount minus organization-wide avg |
| net_revenue_generated | numeric | Net revenue from orders handled by this clerk |
| total_discount_given | numeric | Total discount amount given |
| discount_leakage_ratio | numeric | (total_discount_given / net_revenue) × 100 |
| avg_discount_per_order | numeric | Average discount amount per order |
| leak_risk_level | text | 'high_risk_leak', 'moderate_leak', or 'normal' (based on stddev from mean) |

**Sample:**
```
 clerk             | orders | avg_disc | deviation | leak_ratio | leak_risk
 Clerk#000000207   |   1508 |     5.08 |      0.08 |       5.42 | high_risk_leak
 Clerk#000000481   |   1493 |     5.12 |      0.12 |       5.41 | high_risk_leak
```

---

### `operational_discount_leakage`
**Rows:** 140  
**Purpose:** Discount incidence and erosion grouped by order priority × shipping instructions × shipping mode. Highlights unnecessary discounts where full price would have been acceptable.

| Column | Type | Description |
|--------|------|-------------|
| priority | char(15) | Order priority (1-URGENT to 5-LOW) |
| shipping_instructions | char(25) | Shipping instruction (COLLECT COD, DELIVER IN PERSON, NONE, TAKE BACK RETURN) |
| shipping_mode | char(10) | Shipping mode (AIR, FOB, MAIL, RAIL, REG AIR, SHIP, TRUCK) |
| total_line_items | bigint | Total line items |
| avg_discount_pct | numeric | Average discount percentage |
| excess_vs_min | numeric | Excess discount above the minimum avg across all groups |
| total_discount_given | numeric | Total discount amount |
| discounted_items | bigint | Items that received a discount |
| discount_incidence_pct | numeric | (discounted_items / total_line_items) × 100 |

**Sample:**
```
 priority | shipping_instructions | ship_mode | total_items | avg_disc | total_discount
 5-LOW    | TAKE BACK RETURN      | REG AIR    |       43326 |     5.01 |   83873798.45
 5-LOW    | TAKE BACK RETURN      | FOB        |       43331 |     5.01 |   83220817.80
```

---

### `shipping_discount_paradox`
**Rows:** 84  
**Purpose:** Shipping Mode vs Discount Paradox — investigates whether high discounts combined with expensive shipping modes result in negative net profit.

| Column | Type | Description |
|--------|------|-------------|
| shipping_mode | char(10) | Shipping mode |
| shipping_instructions | char(25) | Shipping instruction |
| discount_tier | text | 'high' (≥7%), 'medium' (3–7%), 'low' (<3%) |
| distinct_discount_levels | bigint | Number of distinct discount values in group |
| total_line_items | numeric | Total line items |
| total_quantity | numeric | Total units |
| avg_discount_pct | numeric | Average discount percentage |
| total_net_revenue | numeric | Total revenue after discount |
| total_discount_erosion | numeric | Total discount given |
| total_returns | numeric | Total returned items |
| avg_return_rate_pct | numeric | Average return rate |
| paradox_flag | text | 'profit_risk' if erosion > 10% of net_revenue, else 'acceptable' |

**Sample:**
```
 shipping_mode | discount_tier | total_discount_erosion | paradox_flag
 AIR           | high          |         255145869.0462 | acceptable
 SHIP          | high          |         254917520.4786 | acceptable
 FOB           | high          |         254901040.6885 | acceptable
```

---

### `customer_discount_sensitivity`
**Rows:** 99,996  
**Purpose:** Per-customer discount sensitivity analysis — tracks total orders, discount frequency, average discount depth, and segments customers into sensitivity tiers.

| Column | Type | Description |
|--------|------|-------------|
| customer_id | integer | Customer identifier |
| total_orders | bigint | Total orders placed |
| discounted_orders | bigint | Orders with discount > 0% |
| avg_discount_pct | numeric | Average discount percentage across all line items |
| max_discount_pct | numeric | Maximum discount percentage received |
| first_order_date | date | Date of first order |
| last_order_date | date | Date of most recent order |
| total_discount_received | numeric | Total discount amount received |
| discount_frequency_pct | numeric | (discounted_orders / total_orders) × 100 |
| discount_sensitivity_segment | text | 'highly_discount_sensitive' (avg_disc ≥ 5%), 'moderately_sensitive' (≥ 2%), 'low_sensitivity' (< 2%) |

**Sample:**
```
 customer_id | total_orders | avg_disc | max_disc | disc_freq_pct | sensitivity_segment
      143500 |           39 |     5.21 |    10.00 |        100.00 | highly_discount_sensitive
       95257 |           36 |     5.06 |    10.00 |         97.22 | highly_discount_sensitive
```
