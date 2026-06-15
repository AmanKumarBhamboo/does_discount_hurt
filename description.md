# Database: tpc (TPC-H Schema)

8 tables across the TPC-H benchmark schema. No foreign key constraints are enforced in the DB; relationships below are logical/inferred.

## Entity Relationship Map

```
region ──< nation ──< customer ──< orders ──< lineitem
                      │                         │
                      │               ┌─────────┘
                      │               ▼
                      └──────> part ──> lineitem
                      │         │
                      │         ▼
                      └──> supplier ──> lineitem
                            │
                            ▼
                         partsupp ──> part
                         partsupp ──> supplier
```

### Relationships

| From | To | Via |
|------|----|------|
| customer | nation | nation_id → nation_id |
| supplier | nation | nation_id → nation_id |
| nation | region | region_id → region_id |
| orders | customer | customer_id → customer_id |
| lineitem | orders | order_id → order_id |
| lineitem | part | part_id → part_id |
| lineitem | supplier | supplier_id → supplier_id |
| partsupp | part | part_id → part_id |
| partsupp | supplier | supplier_id → supplier_id |

## Tables

### customer
Customers who place orders.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| customer_id | integer | NO | Primary key, unique customer identifier |
| customer_name | varchar(25) | NO | Customer name |
| address | varchar(40) | NO | Customer address |
| nation_id | integer | NO | Foreign key to nation.nation_id |
| phone | char(15) | NO | Phone number |
| account_balance | numeric | NO | Account balance |
| market_segment | char(10) | NO | Market segment (e.g. AUTOMOBILE, BUILDING) |
| comment | varchar(117) | NO | Miscellaneous comment |

### lineitem
Line items belonging to orders. This is the most granular table (fact table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| order_id | integer | NO | Foreign key to orders.order_id (composite PK with line_number) |
| part_id | integer | NO | Foreign key to part.part_id |
| supplier_id | integer | NO | Foreign key to supplier.supplier_id |
| line_number | integer | NO | Line number within the order (composite PK) |
| quantity | numeric | NO | Quantity ordered |
| extended_price | numeric | NO | Price per unit × quantity |
| discount | numeric | NO | Discount applied as decimal |
| tax | numeric | NO | Tax applied as decimal |
| return_flag | char(1) | NO | Return status (A = accepted, R = returned) |
| line_status | char(1) | NO | Line status (O = open, F = fulfilled) |
| ship_date | date | NO | Date shipped |
| commit_date | date | NO | Promised ship date |
| receipt_date | date | NO | Date received |
| shipping_instructions | char(25) | NO | Shipping instructions |
| shipping_mode | char(10) | NO | Shipping mode (e.g. AIR, TRUCK) |
| comment | varchar(44) | NO | Comment |

### orders
Order headers placed by customers.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| order_id | integer | NO | Primary key, unique order identifier |
| customer_id | integer | NO | Foreign key to customer.customer_id |
| order_status | char(1) | NO | Order status (F = fulfilled, O = open, P = pending) |
| total_price | numeric | NO | Total price of the order |
| order_date | date | NO | Date order was placed |
| priority | char(15) | NO | Priority (e.g. 1-URGENT, 2-HIGH) |
| clerk | char(15) | NO | Clerk who processed the order |
| shipping_priority | integer | NO | Shipping priority |
| comment | varchar(79) | NO | Comment |

### nation
Countries (lookup table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| nation_id | integer | NO | Primary key, unique nation identifier |
| nation_name | char(25) | NO | Nation name |
| region_id | integer | NO | Foreign key to region.region_id |
| comment | varchar(152) | YES | Comment |

### region
Geographic regions (lookup table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| region_id | integer | NO | Primary key, unique region identifier |
| region_name | char(25) | NO | Region name (e.g. AMERICA, ASIA) |
| comment | varchar(152) | YES | Comment |

### part
Parts sold by suppliers.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| part_id | integer | NO | Primary key, unique part identifier |
| part_name | varchar(55) | NO | Part name |
| manufacturer | char(25) | NO | Manufacturer |
| brand | char(10) | NO | Brand |
| part_type | varchar(25) | NO | Part type |
| size | integer | NO | Size (in unspecified units) |
| container | char(10) | NO | Container type (e.g. WRAP BOX) |
| retail_price | numeric | NO | Retail price |
| comment | varchar(23) | NO | Comment |

### partsupp
Supplier inventory for parts (bridge table between part and supplier).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| part_id | integer | NO | Foreign key to part.part_id (composite PK) |
| supplier_id | integer | NO | Foreign key to supplier.supplier_id (composite PK) |
| available_quantity | integer | NO | Available quantity |
| supply_cost | numeric | NO | Supply cost |
| comment | varchar(199) | NO | Comment |

### supplier
Suppliers who provide parts.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| supplier_id | integer | NO | Primary key, unique supplier identifier |
| supplier_name | char(25) | NO | Supplier name |
| address | varchar(40) | NO | Supplier address |
| nation_id | integer | NO | Foreign key to nation.nation_id |
| phone | char(15) | NO | Phone number |
| account_balance | numeric | NO | Account balance |
| comment | varchar(101) | NO | Comment |
