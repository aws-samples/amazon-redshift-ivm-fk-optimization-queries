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

-- Select inserted/deleted tuples from web_sales.
CREATE TABLE web_sales_ins AS
SELECT *
FROM web_sales
WHERE
    ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address_ins) OR
    ws_ship_addr_sk IN (SELECT ca_address_sk FROM customer_address_ins);

CREATE TABLE web_sales_del AS
SELECT *
FROM web_sales
WHERE
    ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address_del) OR
    ws_ship_addr_sk IN (SELECT ca_address_sk FROM customer_address_del);

-- Create tables.
CREATE TABLE web_sales_cpy
(
    ws_sold_date_sk           INTEGER,
    ws_sold_time_sk           INTEGER,
    ws_ship_date_sk           INTEGER,
    ws_item_sk                INTEGER  NOT NULL,
    ws_bill_customer_sk       INTEGER,
    ws_bill_cdemo_sk          INTEGER,
    ws_bill_hdemo_sk          INTEGER,
    ws_bill_addr_sk           INTEGER,
    ws_ship_customer_sk       INTEGER,
    ws_ship_cdemo_sk          INTEGER,
    ws_ship_hdemo_sk          INTEGER,
    ws_ship_addr_sk           INTEGER,
    ws_web_page_sk            INTEGER,
    ws_web_site_sk            INTEGER,
    ws_ship_mode_sk           INTEGER,
    ws_warehouse_sk           INTEGER,
    ws_promo_sk               INTEGER,
    ws_order_number           BIGINT    NOT NULL,
    ws_quantity               INTEGER,
    ws_wholesale_cost         DECIMAL(7,2),
    ws_list_price             DECIMAL(7,2),
    ws_sales_price            DECIMAL(7,2),
    ws_ext_discount_amt       DECIMAL(7,2),
    ws_ext_sales_price        DECIMAL(7,2),
    ws_ext_wholesale_cost     DECIMAL(7,2),
    ws_ext_list_price         DECIMAL(7,2),
    ws_ext_tax                DECIMAL(7,2),
    ws_coupon_amt             DECIMAL(7,2),
    ws_ext_ship_cost          DECIMAL(7,2),
    ws_net_paid               DECIMAL(7,2),
    ws_net_paid_inc_tax       DECIMAL(7,2),
    ws_net_paid_inc_ship      DECIMAL(7,2),
    ws_net_paid_inc_ship_tax  DECIMAL(7,2),
    ws_net_profit             DECIMAL(7,2)
)
DISTKEY(ws_order_number)
SORTKEY(ws_sold_date_sk);

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
ALTER TABLE web_sales_cpy        ADD PRIMARY KEY (ws_item_sk, ws_order_number);
ALTER TABLE customer_address_cpy ADD PRIMARY KEY (ca_address_sk);

-- Add foreign keys.
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_1 FOREIGN KEY (ws_bill_addr_sk) REFERENCES customer_address_cpy (ca_address_sk);
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_2 FOREIGN KEY (ws_ship_addr_sk) REFERENCES customer_address_cpy (ca_address_sk);

-- Load data.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address
WHERE
    ca_address_sk NOT IN (SELECT ca_address_sk FROM customer_address_ins);

INSERT INTO web_sales_cpy
SELECT b.*
FROM
    web_sales b LEFT JOIN web_sales_ins s ON
    (
        b.ws_item_sk = s.ws_item_sk AND
        b.ws_order_number = s.ws_order_number
    )
WHERE
    s.ws_item_sk IS NULL AND
    s.ws_order_number IS NULL;

-- Analyze.
ANALYZE customer_address_cpy;
ANALYZE web_sales_cpy;

-- Create materialized view.
CREATE MATERIALIZED VIEW ws_1dim AS
SELECT
    ws_item_sk,
    ws_sold_date_sk,
    ca_gmt_offset,
    ws_ext_sales_price
FROM
    web_sales_cpy,
    customer_address_cpy
WHERE
    ws_bill_addr_sk = ca_address_sk;

-- Insert selected tuples.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address_ins;

INSERT INTO web_sales_cpy
SELECT *
FROM web_sales_ins;

-- Delete selected tuples.
DELETE FROM customer_address_cpy USING customer_address_del
WHERE customer_address_cpy.ca_address_sk = customer_address_del.ca_address_sk;

DELETE FROM web_sales_cpy USING web_sales_del
WHERE
    web_sales_cpy.ws_item_sk = web_sales_del.ws_item_sk AND
    web_sales_cpy.ws_order_number = web_sales_del.ws_order_number;

-- Refresh materialized view.
REFRESH MATERIALIZED VIEW ws_1dim;

-- Drop statements.
DROP MATERIALIZED VIEW ws_1dim;
DROP TABLE web_sales_ins;
DROP TABLE web_sales_del;
DROP TABLE web_sales_cpy;
DROP TABLE customer_address_ins;
DROP TABLE customer_address_del;
DROP TABLE customer_address_cpy;
