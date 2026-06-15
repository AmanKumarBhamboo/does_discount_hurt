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
|------|----|-----|
| customer | nation | c_nationkey → n_nationkey |
| supplier | nation | s_nationkey → n_nationkey |
| nation | region | n_regionkey → r_regionkey |
| orders | customer | o_custkey → c_custkey |
| lineitem | orders | l_orderkey → o_orderkey |
| lineitem | part | l_partkey → p_partkey |
| lineitem | supplier | l_suppkey → s_suppkey |
| partsupp | part | ps_partkey → p_partkey |
| partsupp | supplier | ps_suppkey → s_suppkey |

## Tables

### customer
Customers who place orders.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| c_custkey | integer | NO | Primary key, unique customer identifier |
| c_name | varchar(25) | NO | Customer name |
| c_address | varchar(40) | NO | Customer address |
| c_nationkey | integer | NO | Foreign key to nation.n_nationkey |
| c_phone | char(15) | NO | Phone number |
| c_acctbal | numeric | NO | Account balance |
| c_mktsegment | char(10) | NO | Market segment (e.g. AUTOMOBILE, BUILDING) |
| c_comment | varchar(117) | NO | Miscellaneous comment |

### lineitem
Line items belonging to orders. This is the most granular table (fact table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| l_orderkey | integer | NO | Foreign key to orders.o_orderkey (composite PK with l_linenumber) |
| l_partkey | integer | NO | Foreign key to part.p_partkey |
| l_suppkey | integer | NO | Foreign key to supplier.s_suppkey |
| l_linenumber | integer | NO | Line number within the order (composite PK) |
| l_quantity | numeric | NO | Quantity ordered |
| l_extendedprice | numeric | NO | Price per unit × quantity |
| l_discount | numeric | NO | Discount applied as decimal |
| l_tax | numeric | NO | Tax applied as decimal |
| l_returnflag | char(1) | NO | Return status (A = accepted, R = returned) |
| l_linestatus | char(1) | NO | Line status (O = open, F = fulfilled) |
| l_shipdate | date | NO | Date shipped |
| l_commitdate | date | NO | Promised ship date |
| l_receiptdate | date | NO | Date received |
| l_shipinstruct | char(25) | NO | Shipping instructions |
| l_shipmode | char(10) | NO | Shipping mode (e.g. AIR, TRUCK) |
| l_comment | varchar(44) | NO | Comment |

### orders
Order headers placed by customers.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| o_orderkey | integer | NO | Primary key, unique order identifier |
| o_custkey | integer | NO | Foreign key to customer.c_custkey |
| o_orderstatus | char(1) | NO | Order status (F = fulfilled, O = open, P = pending) |
| o_totalprice | numeric | NO | Total price of the order |
| o_orderdate | date | NO | Date order was placed |
| o_orderpriority | char(15) | NO | Priority (e.g. 1-URGENT, 2-HIGH) |
| o_clerk | char(15) | NO | Clerk who processed the order |
| o_shippriority | integer | NO | Shipping priority |
| o_comment | varchar(79) | NO | Comment |

### nation
Countries (lookup table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| n_nationkey | integer | NO | Primary key, unique nation identifier |
| n_name | char(25) | NO | Nation name |
| n_regionkey | integer | NO | Foreign key to region.r_regionkey |
| n_comment | varchar(152) | YES | Comment |

### region
Geographic regions (lookup table).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| r_regionkey | integer | NO | Primary key, unique region identifier |
| r_name | char(25) | NO | Region name (e.g. AMERICA, ASIA) |
| r_comment | varchar(152) | YES | Comment |

### part
Parts sold by suppliers.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| p_partkey | integer | NO | Primary key, unique part identifier |
| p_name | varchar(55) | NO | Part name |
| p_mfgr | char(25) | NO | Manufacturer |
| p_brand | char(10) | NO | Brand |
| p_type | varchar(25) | NO | Part type |
| p_size | integer | NO | Size (in unspecified units) |
| p_container | char(10) | NO | Container type (e.g. WRAP BOX) |
| p_retailprice | numeric | NO | Retail price |
| p_comment | varchar(23) | NO | Comment |

### partsupp
Supplier inventory for parts (bridge table between part and supplier).

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| ps_partkey | integer | NO | Foreign key to part.p_partkey (composite PK) |
| ps_suppkey | integer | NO | Foreign key to supplier.s_suppkey (composite PK) |
| ps_availqty | integer | NO | Available quantity |
| ps_supplycost | numeric | NO | Supply cost |
| ps_comment | varchar(199) | NO | Comment |

### supplier
Suppliers who provide parts.

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| s_suppkey | integer | NO | Primary key, unique supplier identifier |
| s_name | char(25) | NO | Supplier name |
| s_address | varchar(40) | NO | Supplier address |
| s_nationkey | integer | NO | Foreign key to nation.n_nationkey |
| s_phone | char(15) | NO | Phone number |
| s_acctbal | numeric | NO | Account balance |
| s_comment | varchar(101) | NO | Comment |
