# Database: tpc (TPC-H Schema)

8 tables across the TPC-H benchmark schema.

## Tables

### customer (8 columns)
| Column | Type | Nullable |
|--------|------|----------|
| c_custkey | integer | NO |
| c_name | varchar(25) | NO |
| c_address | varchar(40) | NO |
| c_nationkey | integer | NO |
| c_phone | char(15) | NO |
| c_acctbal | numeric | NO |
| c_mktsegment | char(10) | NO |
| c_comment | varchar(117) | NO |

### lineitem (16 columns)
| Column | Type | Nullable |
|--------|------|----------|
| l_orderkey | integer | NO |
| l_partkey | integer | NO |
| l_suppkey | integer | NO |
| l_linenumber | integer | NO |
| l_quantity | numeric | NO |
| l_extendedprice | numeric | NO |
| l_discount | numeric | NO |
| l_tax | numeric | NO |
| l_returnflag | char(1) | NO |
| l_linestatus | char(1) | NO |
| l_shipdate | date | NO |
| l_commitdate | date | NO |
| l_receiptdate | date | NO |
| l_shipinstruct | char(25) | NO |
| l_shipmode | char(10) | NO |
| l_comment | varchar(44) | NO |

### orders (9 columns)
| Column | Type | Nullable |
|--------|------|----------|
| o_orderkey | integer | NO |
| o_custkey | integer | NO |
| o_orderstatus | char(1) | NO |
| o_totalprice | numeric | NO |
| o_orderdate | date | NO |
| o_orderpriority | char(15) | NO |
| o_clerk | char(15) | NO |
| o_shippriority | integer | NO |
| o_comment | varchar(79) | NO |

### nation (4 columns)
| Column | Type | Nullable |
|--------|------|----------|
| n_nationkey | integer | NO |
| n_name | char(25) | NO |
| n_regionkey | integer | NO |
| n_comment | varchar(152) | YES |

### region (3 columns)
| Column | Type | Nullable |
|--------|------|----------|
| r_regionkey | integer | NO |
| r_name | char(25) | NO |
| r_comment | varchar(152) | YES |

### part (9 columns)
| Column | Type | Nullable |
|--------|------|----------|
| p_partkey | integer | NO |
| p_name | varchar(55) | NO |
| p_mfgr | char(25) | NO |
| p_brand | char(10) | NO |
| p_type | varchar(25) | NO |
| p_size | integer | NO |
| p_container | char(10) | NO |
| p_retailprice | numeric | NO |
| p_comment | varchar(23) | NO |

### partsupp (5 columns)
| Column | Type | Nullable |
|--------|------|----------|
| ps_partkey | integer | NO |
| ps_suppkey | integer | NO |
| ps_availqty | integer | NO |
| ps_supplycost | numeric | NO |
| ps_comment | varchar(199) | NO |

### supplier (7 columns)
| Column | Type | Nullable |
|--------|------|----------|
| s_suppkey | integer | NO |
| s_name | char(25) | NO |
| s_address | varchar(40) | NO |
| s_nationkey | integer | NO |
| s_phone | char(15) | NO |
| s_acctbal | numeric | NO |
| s_comment | varchar(101) | NO |
