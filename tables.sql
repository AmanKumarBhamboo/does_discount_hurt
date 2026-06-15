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
