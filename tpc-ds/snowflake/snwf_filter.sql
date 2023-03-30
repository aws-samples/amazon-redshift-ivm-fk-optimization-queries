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

-- Select inserted/deleted tuples from date_dim.
CREATE TABLE date_dim_random AS
SELECT *
FROM date_dim
WHERE cast(random() * 1000 as int) = 1;

CREATE TABLE date_dim_ins AS
SELECT *
FROM date_dim_random
WHERE cast(OID AS INT8) % 2 = 0;

CREATE TABLE date_dim_del AS
SELECT *
FROM date_dim_random
WHERE cast(OID AS INT8) % 2 = 1;

DROP TABLE date_dim_random;

-- Select inserted/deleted tuples from customer.
CREATE TABLE customer_ins AS
SELECT *
FROM customer
WHERE
    c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address_ins);

CREATE TABLE customer_del AS
SELECT *
FROM customer
WHERE
    c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address_del);

-- Select inserted/deleted tuples from web_sales.
CREATE TABLE web_sales_ins AS
SELECT *
FROM web_sales
WHERE
    ws_item_sk IN (SELECT i_item_sk FROM item_ins) OR
    ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer_ins) OR
    ws_ship_customer_sk IN (SELECT c_customer_sk FROM customer_ins) OR
    ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim_ins) OR
    ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim_ins);

CREATE TABLE web_sales_del AS
SELECT *
FROM web_sales
WHERE
    ws_item_sk IN (SELECT i_item_sk FROM item_del) OR
    ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer_del) OR
    ws_ship_customer_sk IN (SELECT c_customer_sk FROM customer_del) OR
    ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim_del) OR
    ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim_del);

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

CREATE TABLE customer_cpy
(
    c_customer_sk           INTEGER   NOT NULL,
    c_customer_id           CHAR(16)  NOT NULL,
    c_current_cdemo_sk      INTEGER,
    c_current_hdemo_sk      INTEGER,
    c_current_addr_sk       INTEGER,
    c_first_shipto_date_sk  INTEGER,
    c_first_sales_date_sk   INTEGER,
    c_salutation            CHAR(10),
    c_first_name            CHAR(20),
    c_last_name             CHAR(30),
    c_preferred_cust_flag   CHAR(1),
    c_birth_day             INTEGER,
    c_birth_month           INTEGER,
    c_birth_year            INTEGER,
    c_birth_country         VARCHAR(20),
    c_login                 CHAR(13),
    c_email_address         CHAR(50),
    c_last_review_date_sk   INTEGER
)
DISTKEY(c_customer_sk);

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

CREATE TABLE date_dim_cpy
(
    d_date_sk            INTEGER   NOT NULL,
    d_date_id            CHAR(16)  NOT NULL,
    d_date               DATE      NOT NULL,
    d_month_seq          INTEGER,
    d_week_seq           INTEGER,
    d_quarter_seq        INTEGER,
    d_year               INTEGER,
    d_dow                INTEGER,
    d_moy                INTEGER,
    d_dom                INTEGER,
    d_qoy                INTEGER,
    d_fy_year            INTEGER,
    d_fy_quarter_seq     INTEGER,
    d_fy_week_seq        INTEGER,
    d_day_name           CHAR(9),
    d_quarter_name       CHAR(6),
    d_holiday            CHAR(1),
    d_weekend            CHAR(1),
    d_following_holiday  CHAR(1),
    d_first_dom          INTEGER,
    d_last_dom           INTEGER,
    d_same_day_ly        INTEGER,
    d_same_day_lq        INTEGER,
    d_current_day        CHAR(1),
    d_current_week       CHAR(1),
    d_current_month      CHAR(1),
    d_current_quarter    CHAR(1),
    d_current_year       CHAR(1)
)
DISTSTYLE all;

-- Add primary keys.
ALTER TABLE web_sales_cpy        ADD PRIMARY KEY (ws_item_sk, ws_order_number);
ALTER TABLE customer_cpy         ADD PRIMARY KEY (c_customer_sk);
ALTER TABLE customer_address_cpy ADD PRIMARY KEY (ca_address_sk);
ALTER TABLE item_cpy             ADD PRIMARY KEY (i_item_sk);
ALTER TABLE date_dim_cpy         ADD PRIMARY KEY (d_date_sk);

-- Add foreign keys.
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_1 FOREIGN KEY (ws_item_sk)          REFERENCES item_cpy (i_item_sk);
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_2 FOREIGN KEY (ws_bill_customer_sk) REFERENCES customer_cpy (c_customer_sk);
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_3 FOREIGN KEY (ws_ship_customer_sk) REFERENCES customer_cpy (c_customer_sk);
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_4 FOREIGN KEY (ws_ship_date_sk)     REFERENCES date_dim_cpy (d_date_sk);
ALTER TABLE web_sales_cpy ADD CONSTRAINT fk_5 FOREIGN KEY (ws_sold_date_sk)     REFERENCES date_dim_cpy (d_date_sk);
ALTER TABLE customer_cpy  ADD CONSTRAINT FK_6 FOREIGN KEY (c_current_addr_sk)   REFERENCES customer_address_cpy (ca_address_sk);

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

INSERT INTO date_dim_cpy
SELECT *
FROM date_dim
WHERE
    d_date_sk NOT IN (SELECT d_date_sk FROM date_dim_ins);

INSERT INTO customer_cpy
SELECT *
FROM customer
WHERE
    c_customer_sk NOT IN (SELECT c_customer_sk FROM customer_ins);

-- Web Sales Copy
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

-- Analyze
ANALYZE customer_address_cpy;
ANALYZE customer_cpy;
ANALYZE date_dim_cpy;
ANALYZE item_cpy;
ANALYZE web_sales_cpy;

-- Create materialized view.
CREATE MATERIALIZED VIEW snwf_filter AS
SELECT
    ca_zip,
    ca_county,
    i_item_id,
    ws_sales_price
FROM
    web_sales_cpy,
    customer_cpy,
    customer_address_cpy,
    date_dim_cpy,
    item_cpy
WHERE
    ws_bill_customer_sk = c_customer_sk AND
    c_current_addr_sk = ca_address_sk AND
    ws_item_sk = i_item_sk AND
    ws_sold_date_sk = d_date_sk AND
    d_qoy = 1 AND
    d_year = 2000;

-- Insert selected tuples.
INSERT INTO customer_address_cpy
SELECT *
FROM customer_address_ins;

INSERT INTO item_cpy
SELECT *
FROM item_ins;

INSERT INTO date_dim_cpy
SELECT *
FROM date_dim_ins;

INSERT INTO customer_cpy
SELECT *
FROM customer_ins;

INSERT INTO web_sales_cpy
SELECT *
FROM web_sales_ins;

-- Delete selected tuples.
DELETE FROM customer_address_cpy using customer_address_del
WHERE customer_address_cpy.ca_address_sk = customer_address_del.ca_address_sk;

DELETE FROM item_cpy using item_del
WHERE item_cpy.i_item_sk = item_del.i_item_sk;

DELETE FROM date_dim_cpy using date_dim_del
WHERE date_dim_cpy.d_date_sk = date_dim_del.d_date_sk;

DELETE FROM customer_cpy using customer_del
WHERE customer_cpy.c_customer_sk = customer_del.c_customer_sk;

DELETE FROM web_sales_cpy using web_sales_del
WHERE
    web_sales_cpy.ws_item_sk = web_sales_del.ws_item_sk AND
    web_sales_cpy.ws_order_number = web_sales_del.ws_order_number;

-- Refresh materialized view.
REFRESH MATERIALIZED VIEW snwf_filter;

-- Drop statements.
DROP MATERIALIZED VIEW snwf_filter;
DROP TABLE web_sales_ins;
DROP TABLE web_sales_del;
DROP TABLE web_sales_cpy;
DROP TABLE customer_ins;
DROP TABLE customer_del;
DROP TABLE customer_cpy;
DROP TABLE customer_address_ins;
DROP TABLE customer_address_del;
DROP TABLE customer_address_cpy;
DROP TABLE item_ins;
DROP TABLE item_del;
DROP TABLE item_cpy;
DROP TABLE date_dim_ins;
DROP TABLE date_dim_del;
DROP TABLE date_dim_cpy;
