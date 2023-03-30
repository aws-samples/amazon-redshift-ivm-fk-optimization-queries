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

-- Select inserted/deleted tuples from item.
CREATE TABLE item_random AS
SELECT *
FROM item
WHERE cast(random() * 1000 as int) = 1;

CREATE TABLE item_ins AS
SELECT *
FROM item_random
WHERE cast(OID AS INT8) % 2 = 0;

CREATE TABLE item_del AS
SELECT *
FROM item_random
WHERE cast(OID AS INT8) % 2 = 1;

DROP TABLE item_random;

-- Select inserted/deleted tuples from catalog_sales.
CREATE TABLE catalog_sales_ins AS
SELECT *
FROM catalog_sales
WHERE
    cs_item_sk IN (SELECT i_item_sk FROM item_ins) OR
    cs_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address_ins) OR
    cs_ship_addr_sk IN (SELECT ca_address_sk FROM customer_address_ins);

CREATE TABLE catalog_sales_del AS
SELECT *
FROM catalog_sales
WHERE
    cs_item_sk IN (SELECT i_item_sk FROM item_del) OR
    cs_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address_del) OR
    cs_ship_addr_sk IN (SELECT ca_address_sk FROM customer_address_del);

-- Create tables.
CREATE TABLE catalog_sales_cpy
(
    cs_sold_date_sk           INTEGER,
    cs_sold_time_sk           INTEGER,
    cs_ship_date_sk           INTEGER,
    cs_bill_customer_sk       INTEGER,
    cs_bill_cdemo_sk          INTEGER,
    cs_bill_hdemo_sk          INTEGER,
    cs_bill_addr_sk           INTEGER,
    cs_ship_customer_sk       INTEGER,
    cs_ship_cdemo_sk          INTEGER,
    cs_ship_hdemo_sk          INTEGER,
    cs_ship_addr_sk           INTEGER,
    cs_call_center_sk         INTEGER,
    cs_catalog_page_sk        INTEGER,
    cs_ship_mode_sk           INTEGER,
    cs_warehouse_sk           INTEGER,
    cs_item_sk                INTEGER  NOT NULL,
    cs_promo_sk               INTEGER,
    cs_order_number           BIGINT   NOT NULL,
    cs_quantity               INTEGER,
    cs_wholesale_cost         DECIMAL(7,2),
    cs_list_price             DECIMAL(7,2),
    cs_sales_price            DECIMAL(7,2),
    cs_ext_discount_amt       DECIMAL(7,2),
    cs_ext_sales_price        DECIMAL(7,2),
    cs_ext_wholesale_cost     DECIMAL(7,2),
    cs_ext_list_price         DECIMAL(7,2),
    cs_ext_tax                DECIMAL(7,2),
    cs_coupon_amt             DECIMAL(7,2),
    cs_ext_ship_cost          DECIMAL(7,2),
    cs_net_paid               DECIMAL(7,2),
    cs_net_paid_inc_tax       DECIMAL(7,2),
    cs_net_paid_inc_ship      DECIMAL(7,2),
    cs_net_paid_inc_ship_tax  DECIMAL(7,2),
    cs_net_profit             DECIMAL(7,2)
)
DISTKEY(cs_item_sk)
SORTKEY(cs_sold_date_sk);

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

CREATE TABLE item_cpy
(
    i_item_sk         INTEGER   NOT NULL,
    i_item_id         CHAR(16)  NOT NULL,
    i_rec_start_date  DATE,
    i_rec_end_date    DATE,
    i_item_desc       VARCHAR(200),
    i_current_price   DECIMAL(7,2),
    i_wholesale_cost  DECIMAL(7,2),
    i_brand_id        INTEGER,
    i_brand           CHAR(50),
    i_class_id        INTEGER,
    i_class           CHAR(50),
    i_category_id     INTEGER,
    i_category        CHAR(50),
    i_manufact_id     INTEGER,
    i_manufact        CHAR(50),
    i_size            CHAR(20),
    i_formulation     CHAR(20),
    i_color           CHAR(20),
    i_units           CHAR(10),
    i_container       CHAR(10),
    i_manager_id      INTEGER,
    i_product_name    CHAR(50)
)
DISTKEY(i_item_sk)
SORTKEY(i_category);

-- Add primary keys.
ALTER TABLE catalog_sales_cpy    ADD PRIMARY KEY (cs_item_sk, cs_order_number);
ALTER TABLE item_cpy             ADD PRIMARY KEY (i_item_sk);
ALTER TABLE customer_address_cpy ADD PRIMARY KEY (ca_address_sk);

-- Add foreign keys.
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_1 FOREIGN KEY (cs_item_sk)      REFERENCES item_cpy (i_item_sk);
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_2 FOREIGN KEY (cs_bill_addr_sk) REFERENCES customer_address_cpy (ca_address_sk);
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_3 FOREIGN KEY (cs_ship_addr_sk) REFERENCES customer_address_cpy (ca_address_sk);

-- Load data.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address
WHERE
    ca_address_sk NOT IN (SELECT ca_address_sk FROM customer_address_ins);

INSERT INTO item_cpy
SELECT *
FROM item
WHERE
    i_item_sk NOT IN (SELECT i_item_sk FROM item_ins);

INSERT INTO catalog_sales_cpy
SELECT b.*
FROM
    catalog_sales b LEFT JOIN catalog_sales_ins s ON
    (
        b.cs_item_sk = s.cs_item_sk AND
        b.cs_order_number = s.cs_order_number
    )
WHERE
    s.cs_item_sk IS NULL AND
    s.cs_order_number IS NULL;

-- Analyze.
ANALYZE catalog_sales_cpy;
ANALYZE customer_address_cpy;
ANALYZE item_cpy;

-- Create materialized view.
CREATE MATERIALIZED VIEW cs_2dim AS
SELECT
    cs_sold_date_sk,
    i_item_id,
    ca_gmt_offset,
    cs_ext_sales_price
FROM
    catalog_sales_cpy,
    customer_address_cpy,
    item_cpy
WHERE
    cs_item_sk = i_item_sk AND
    cs_bill_addr_sk = ca_address_sk;

-- Insert selected tuples.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address_ins;

INSERT INTO item_cpy
SELECT *
FROM item_ins;

INSERT INTO catalog_sales_cpy
SELECT *
FROM catalog_sales_ins;

-- Delete selected tuples.
DELETE FROM customer_address_cpy using customer_address_del
WHERE
    customer_address_cpy.ca_address_sk = customer_address_del.ca_address_sk;

DELETE FROM item_cpy using item_del
WHERE item_cpy.i_item_sk = item_del.i_item_sk;

DELETE FROM catalog_sales_cpy using catalog_sales_del
WHERE
    catalog_sales_cpy.cs_item_sk = catalog_sales_del.cs_item_sk AND
    catalog_sales_cpy.cs_order_number = catalog_sales_del.cs_order_number;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW cs_2dim;

-- Drop statements.
DROP MATERIALIZED VIEW cs_2dim;
DROP TABLE catalog_sales_ins;
DROP TABLE catalog_sales_del;
DROP TABLE catalog_sales_cpy;
DROP TABLE customer_address_ins;
DROP TABLE customer_address_del;
DROP TABLE customer_address_cpy;
DROP TABLE item_ins;
DROP TABLE item_del;
DROP TABLE item_cpy;
