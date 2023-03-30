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

-- Select inserted/deleted tuples from customer_address.
CREATE TABLE customer_address_random AS
SELECT *
FROM customer_address
WHERE cast(random() * 1000 as int) = 1;

CREATE TABLE customer_address_ins AS
SELECT *
FROM customer_address_random
WHERE cast(OID AS INT8) % 2 = 0;

CREATE TABLE customer_address_del AS
SELECT *
FROM customer_address_random
WHERE cast(OID AS INT8) % 2 = 1;

DROP TABLE customer_address_random;

-- Select inserted/deleted tuples from store_sales.
CREATE TABLE store_sales_ins AS
SELECT *
FROM store_sales
WHERE
    ss_addr_sk IN (SELECT DISTINCT ca_address_sk FROM customer_address_ins);

CREATE TABLE store_sales_del AS
SELECT *
FROM store_sales
WHERE
    ss_addr_sk IN (SELECT DISTINCT ca_address_sk FROM customer_address_del);

-- Create tables.
CREATE TABLE store_sales_cpy
(
    ss_sold_date_sk        INTEGER,
    ss_sold_time_sk        INTEGER,
    ss_item_sk             INTEGER  NOT NULL,
    ss_customer_sk         INTEGER,
    ss_cdemo_sk            INTEGER,
    ss_hdemo_sk            INTEGER,
    ss_addr_sk             INTEGER,
    ss_store_sk            INTEGER,
    ss_promo_sk            INTEGER,
    ss_ticket_number       BIGINT   NOT NULL,
    ss_quantity            INTEGER,
    ss_wholesale_cost      DECIMAL(7,2),
    ss_list_price          DECIMAL(7,2),
    ss_sales_price         DECIMAL(7,2),
    ss_ext_discount_amt    DECIMAL(7,2),
    ss_ext_sales_price     DECIMAL(7,2),
    ss_ext_wholesale_cost  DECIMAL(7,2),
    ss_ext_list_price      DECIMAL(7,2),
    ss_ext_tax             DECIMAL(7,2),
    ss_coupon_amt          DECIMAL(7,2),
    ss_net_paid            DECIMAL(7,2),
    ss_net_paid_inc_tax    DECIMAL(7,2),
    ss_net_profit          DECIMAL(7,2)
)
DISTKEY(ss_item_sk)
SORTKEY(ss_sold_date_sk);

CREATE TABLE customer_address_cpy
(
    ca_address_sk     INTEGER   NOT NULL,
    ca_address_id     CHAR(16)  NOT NULL,
    ca_street_number  CHAR(10),
    ca_street_name    VARCHAR(60),
    ca_street_type    CHAR(15),
    ca_suite_number   CHAR(10),
    ca_city           VARCHAR(60),
    ca_county         VARCHAR(30),
    ca_state          CHAR(2),
    ca_zip            CHAR(10),
    ca_country        VARCHAR(20),
    ca_gmt_offset     DECIMAL(5,2),
    ca_location_type  CHAR(20)
)
DISTKEY(ca_address_sk);

-- Add primary keys.
ALTER TABLE store_sales_cpy      ADD PRIMARY KEY (ss_item_sk, ss_ticket_number);
ALTER TABLE customer_address_cpy ADD PRIMARY KEY (ca_address_sk);

-- Add foreign keys.
ALTER TABLE store_sales_cpy ADD CONSTRAINT fk_1 FOREIGN KEY (ss_addr_sk) REFERENCES customer_address(ca_address_sk);

-- Load data.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address
WHERE
    ca_address_sk NOT IN (SELECT ca_address_sk FROM customer_address_ins);

INSERT INTO store_sales_cpy
SELECT b.*
FROM
    store_sales b LEFT JOIN store_sales_ins s ON
    (
        b.ss_item_sk = s.ss_item_sk AND
        b.ss_ticket_number = s.ss_ticket_number
    )
WHERE
    s.ss_item_sk IS NULL AND
    s.ss_ticket_number IS NULL;

-- Analyze
ANALYZE customer_address_cpy;
ANALYZE store_sales_cpy;

-- Create materialized view.
CREATE MATERIALIZED VIEW ss_1dim AS
SELECT
    ss_sold_date_sk,
    ss_item_sk,
    ca_gmt_offset,
    ss_ext_sales_price
FROM
    store_sales_cpy,
    customer_address_cpy
WHERE
    ss_addr_sk = ca_address_sk;

-- Insert selected tuples.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address_ins;

INSERT INTO store_sales_cpy
SELECT *
FROM store_sales_ins;

-- Delete selected tuples.
DELETE FROM customer_address_cpy USING customer_address_del
WHERE customer_address_cpy.ca_address_sk = customer_address_del.ca_address_sk;

DELETE FROM store_sales_cpy USING store_sales_del
WHERE
    store_sales_cpy.ss_item_sk = store_sales_del.ss_item_sk AND
    store_sales_cpy.ss_ticket_number = store_sales_del.ss_ticket_number;

-- Refresh materialized view.
REFRESH MATERIALIZED VIEW ss_1dim;

-- Drop statements.
DROP MATERIALIZED VIEW ss_1dim;
DROP TABLE store_sales_ins;
DROP TABLE store_sales_del;
DROP TABLE store_sales_cpy;
DROP TABLE customer_address_ins;
DROP TABLE customer_address_del;
DROP TABLE customer_address_cpy;
