/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: MIT-0
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this
 * software and associated documentation files (the "Software"), to deal in the Software
 * without restriction, including without limitation the rights to use, copy, modify,
 * merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
 * PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

-- Select inserted/deleted tuples from customer.
CREATE TABLE customer_random AS
SELECT *
FROM customer
WHERE cast(random() * 1000 as int) = 1;

CREATE TABLE customer_ins AS
SELECT *
FROM customer_random
WHERE cast(OID AS INT8) % 2 = 0;

CREATE TABLE customer_del AS
SELECT *
FROM customer_random
WHERE cast(OID AS INT8) % 2 = 1;

DROP TABLE customer_random;

-- Select inserted/deleted tuples from orders.
CREATE TABLE orders_ins AS
SELECT *
FROM orders
WHERE
    o_custkey IN (SELECT c_custkey FROM customer_ins);

CREATE TABLE orders_del AS
SELECT *
FROM orders
WHERE
    o_custkey IN (SELECT c_custkey FROM customer_del);

-- Select inserted/deleted tuples from lineitem.
CREATE TABLE lineitem_ins AS
SELECT *
FROM lineitem
WHERE
    l_orderkey IN (SELECT o_orderkey FROM orders_ins);

CREATE TABLE lineitem_del AS
SELECT *
FROM lineitem
WHERE
    l_orderkey IN (SELECT o_orderkey FROM orders_del);

-- Create tables
CREATE TABLE nation_cpy
(
    n_nationkey  INTEGER   NOT NULL,
    n_name       CHAR(25)  NOT NULL,
    n_regionkey  INTEGER   NOT NULL,
    n_comment    VARCHAR(152)
)
DISTSTYLE ALL
SORTKEY(n_nationkey);

CREATE TABLE customer_cpy
(
    c_custkey     BIGINT         NOT NULL,
    c_name        VARCHAR(25)    NOT NULL,
    c_address     VARCHAR(40)    NOT NULL,
    c_nationkey   INTEGER        NOT NULL,
    c_phone       CHAR(15)       NOT NULL,
    c_acctbal     DECIMAL(15,2)  NOT NULL,
    c_mktsegment  CHAR(10)       NOT NULL,
    c_comment     VARCHAR(117)   NOT NULL
)
DISTSTYLE EVEN
SORTKEY(c_custkey);

CREATE TABLE orders_cpy
(
    o_orderkey       BIGINT         NOT NULL,
    o_custkey        BIGINT         NOT NULL,
    o_orderstatus    CHAR(1)        NOT NULL,
    o_totalprice     DECIMAL(15,2)  NOT NULL,
    o_orderdate      DATE           NOT NULL,
    o_orderpriority  CHAR(15)       NOT NULL,
    o_clerk          CHAR(15)       NOT NULL,
    o_shippriority   INTEGER        NOT NULL,
    o_comment        VARCHAR(79)    NOT NULL
)
DISTKEY (o_orderkey)
SORTKEY (o_orderdate);

CREATE TABLE lineitem_cpy
(
    l_orderkey       BIGINT         NOT NULL,
    l_partkey        BIGINT         NOT NULL,
    l_suppkey        INTEGER        NOT NULL,
    l_linenumber     INTEGER        NOT NULL,
    l_quantity       DECIMAL(15,2)  NOT NULL,
    l_extendedprice  DECIMAL(15,2)  NOT NULL,
    l_discount       DECIMAL(15,2)  NOT NULL,
    l_tax            DECIMAL(15,2)  NOT NULL,
    l_returnflag     CHAR(1)        NOT NULL,
    l_linestatus     CHAR(1)        NOT NULL,
    l_shipdate       DATE           NOT NULL,
    l_commitdate     DATE           NOT NULL,
    l_receiptdate    DATE           NOT NULL,
    l_shipinstruct   CHAR(25)       NOT NULL,
    l_shipmode       CHAR(10)       NOT NULL,
    l_comment        VARCHAR(44)    NOT NULL
)
distkey(l_orderkey)
SORTKEY(l_shipdate);

-- Add primary keys.
ALTER TABLE nation_cpy    ADD PRIMARY KEY (n_nationkey);
ALTER TABLE customer_cpy  ADD PRIMARY KEY (c_custkey);
ALTER TABLE orders_cpy    ADD PRIMARY KEY (o_orderkey);
ALTER TABLE lineitem_cpy  ADD PRIMARY KEY (l_orderkey, l_linenumber);

-- Add foreign keys.
ALTER TABLE customer_cpy  ADD CONSTRAINT fk_1 FOREIGN KEY (c_nationkey)  REFERENCES nation_cpy (n_nationkey);
ALTER TABLE orders_cpy    ADD CONSTRAINT fk_2 FOREIGN KEY (o_custkey)    REFERENCES customer_cpy (c_custkey);
ALTER TABLE lineitem_cpy  ADD CONSTRAINT fk_3 FOREIGN KEY (l_orderkey)   REFERENCES orders_cpy (o_orderkey);

-- Load data.
INSERT INTO nation_cpy
SELECT *
FROM nation;

INSERT INTO customer_cpy
SELECT *
FROM customer
WHERE
    c_custkey NOT IN (SELECT c_custkey FROM customer_ins);

INSERT INTO orders_cpy
SELECT *
FROM orders
WHERE
    o_orderkey NOT IN (SELECT o_orderkey FROM orders_ins);

INSERT INTO lineitem_cpy
SELECT b.*
FROM
    lineitem b LEFT JOIN lineitem_ins s ON
    (
        b.l_orderkey = s.l_orderkey AND
        b.l_linenumber = s.l_linenumber
    )
WHERE
    s.l_orderkey IS NULL AND
    s.l_linenumber IS NULL;

-- Analyze
ANALYZE nation_cpy;
ANALYZE customer_cpy;
ANALYZE orders_cpy;
ANALYZE lineitem_cpy;

-- Create materialized view
CREATE MATERIALIZED VIEW chain AS
SELECT
    l_returnflag,
    o_orderdate,
    c_custkey,
    c_name,
    l_extendedprice,
    l_discount,
    c_acctbal,
    n_name,
    c_address,
    c_phone,
    c_comment
FROM
    lineitem_cpy,
    orders_cpy,
    customer_cpy,
    nation_cpy
WHERE
    c_custkey = o_custkey AND
    l_orderkey = o_orderkey AND
    c_nationkey = n_nationkey;

-- Insert selected tuples.
INSERT INTO customer_cpy
SELECT *
FROM customer_ins;

INSERT INTO orders_cpy
SELECT *
FROM orders_ins;

INSERT INTO lineitem_cpy
SELECT *
FROM lineitem_ins;

-- Delete selected tuples.
DELETE FROM customer_cpy USING customer_del
WHERE customer_cpy.c_custkey = customer_del.c_custkey;

DELETE FROM orders_cpy USING orders_del
WHERE orders_cpy.o_orderkey = orders_del.o_orderkey;

DELETE FROM lineitem_cpy USING lineitem_del
WHERE
    lineitem_cpy.l_orderkey = lineitem_del.l_orderkey
    AND lineitem_cpy.l_linenumber = lineitem_del.l_linenumber;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW chain;

-- Drop statements.
DROP MATERIALIZED VIEW chain;
DROP TABLE lineitem_ins;
DROP TABLE lineitem_del;
DROP TABLE lineitem_cpy;
DROP TABLE orders_ins;
DROP TABLE orders_del;
DROP TABLE orders_cpy;
DROP TABLE customer_ins;
DROP TABLE customer_del;
DROP TABLE customer_cpy;
DROP TABLE nation_cpy;
