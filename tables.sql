-- List all tables
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';

-- First 10 rows from each table
SELECT * FROM customer LIMIT 10;
SELECT * FROM lineitem LIMIT 10;
SELECT * FROM orders LIMIT 10;
SELECT * FROM nation LIMIT 10;
SELECT * FROM region LIMIT 10;
SELECT * FROM part LIMIT 10;
SELECT * FROM partsupp LIMIT 10;
SELECT * FROM supplier LIMIT 10;

-- Rename columns to descriptive names
ALTER TABLE customer RENAME COLUMN c_custkey TO customer_id;
ALTER TABLE customer RENAME COLUMN c_name TO customer_name;
ALTER TABLE customer RENAME COLUMN c_address TO address;
ALTER TABLE customer RENAME COLUMN c_nationkey TO nation_id;
ALTER TABLE customer RENAME COLUMN c_phone TO phone;
ALTER TABLE customer RENAME COLUMN c_acctbal TO account_balance;
ALTER TABLE customer RENAME COLUMN c_mktsegment TO market_segment;
ALTER TABLE customer RENAME COLUMN c_comment TO comment;

ALTER TABLE lineitem RENAME COLUMN l_orderkey TO order_id;
ALTER TABLE lineitem RENAME COLUMN l_partkey TO part_id;
ALTER TABLE lineitem RENAME COLUMN l_suppkey TO supplier_id;
ALTER TABLE lineitem RENAME COLUMN l_linenumber TO line_number;
ALTER TABLE lineitem RENAME COLUMN l_quantity TO quantity;
ALTER TABLE lineitem RENAME COLUMN l_extendedprice TO extended_price;
ALTER TABLE lineitem RENAME COLUMN l_discount TO discount;
ALTER TABLE lineitem RENAME COLUMN l_tax TO tax;
ALTER TABLE lineitem RENAME COLUMN l_returnflag TO return_flag;
ALTER TABLE lineitem RENAME COLUMN l_linestatus TO line_status;
ALTER TABLE lineitem RENAME COLUMN l_shipdate TO ship_date;
ALTER TABLE lineitem RENAME COLUMN l_commitdate TO commit_date;
ALTER TABLE lineitem RENAME COLUMN l_receiptdate TO receipt_date;
ALTER TABLE lineitem RENAME COLUMN l_shipinstruct TO shipping_instructions;
ALTER TABLE lineitem RENAME COLUMN l_shipmode TO shipping_mode;
ALTER TABLE lineitem RENAME COLUMN l_comment TO comment;

ALTER TABLE orders RENAME COLUMN o_orderkey TO order_id;
ALTER TABLE orders RENAME COLUMN o_custkey TO customer_id;
ALTER TABLE orders RENAME COLUMN o_orderstatus TO order_status;
ALTER TABLE orders RENAME COLUMN o_totalprice TO total_price;
ALTER TABLE orders RENAME COLUMN o_orderdate TO order_date;
ALTER TABLE orders RENAME COLUMN o_orderpriority TO priority;
ALTER TABLE orders RENAME COLUMN o_clerk TO clerk;
ALTER TABLE orders RENAME COLUMN o_shippriority TO shipping_priority;
ALTER TABLE orders RENAME COLUMN o_comment TO comment;

ALTER TABLE nation RENAME COLUMN n_nationkey TO nation_id;
ALTER TABLE nation RENAME COLUMN n_name TO nation_name;
ALTER TABLE nation RENAME COLUMN n_regionkey TO region_id;
ALTER TABLE nation RENAME COLUMN n_comment TO comment;

ALTER TABLE region RENAME COLUMN r_regionkey TO region_id;
ALTER TABLE region RENAME COLUMN r_name TO region_name;
ALTER TABLE region RENAME COLUMN r_comment TO comment;

ALTER TABLE part RENAME COLUMN p_partkey TO part_id;
ALTER TABLE part RENAME COLUMN p_name TO part_name;
ALTER TABLE part RENAME COLUMN p_mfgr TO manufacturer;
ALTER TABLE part RENAME COLUMN p_brand TO brand;
ALTER TABLE part RENAME COLUMN p_type TO part_type;
ALTER TABLE part RENAME COLUMN p_size TO size;
ALTER TABLE part RENAME COLUMN p_container TO container;
ALTER TABLE part RENAME COLUMN p_retailprice TO retail_price;
ALTER TABLE part RENAME COLUMN p_comment TO comment;

ALTER TABLE partsupp RENAME COLUMN ps_partkey TO part_id;
ALTER TABLE partsupp RENAME COLUMN ps_suppkey TO supplier_id;
ALTER TABLE partsupp RENAME COLUMN ps_availqty TO available_quantity;
ALTER TABLE partsupp RENAME COLUMN ps_supplycost TO supply_cost;
ALTER TABLE partsupp RENAME COLUMN ps_comment TO comment;

ALTER TABLE supplier RENAME COLUMN s_suppkey TO supplier_id;
ALTER TABLE supplier RENAME COLUMN s_name TO supplier_name;
ALTER TABLE supplier RENAME COLUMN s_address TO address;
ALTER TABLE supplier RENAME COLUMN s_nationkey TO nation_id;
ALTER TABLE supplier RENAME COLUMN s_phone TO phone;
ALTER TABLE supplier RENAME COLUMN s_acctbal TO account_balance;
ALTER TABLE supplier RENAME COLUMN s_comment TO comment;

