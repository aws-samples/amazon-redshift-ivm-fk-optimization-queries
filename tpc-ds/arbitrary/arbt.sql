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

-- Select inserted/deleted tuples from store.
CREATE TABLE store_random AS
SELECT *
FROM store
WHERE cast(random() * 1000 as int) = 1;

CREATE TABLE store_ins AS
SELECT *
FROM store_random
WHERE cast(OID AS INT8) % 2 = 0;

CREATE TABLE store_del AS
SELECT *
FROM store_random
WHERE cast(OID AS INT8) % 2 = 1;

DROP TABLE store_random;

-- Select inserted/deleted tuples from store_sales.
CREATE TABLE store_sales_ins AS
SELECT *
FROM store_sales
WHERE
    ss_item_sk IN (SELECT i_item_sk FROM item_ins) OR
    ss_store_sk IN (SELECT s_store_sk FROM store_ins) OR
    ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim_ins);

CREATE TABLE store_sales_del AS
SELECT *
FROM store_sales
WHERE
    ss_item_sk IN (SELECT i_item_sk FROM item_del) OR
    ss_store_sk IN (SELECT s_store_sk FROM store_del) OR
    ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim_del);

-- Select inserted/deleted tuples from catalog_sales.
CREATE TABLE catalog_sales_ins AS
SELECT *
FROM catalog_sales
WHERE
    cs_item_sk IN (SELECT i_item_sk FROM item_ins) OR
    cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim_ins) OR
    cs_ship_date_sk IN (SELECT d_date_sk FROM date_dim_ins);

CREATE TABLE catalog_sales_del AS
SELECT *
FROM catalog_sales
WHERE
    cs_item_sk IN (SELECT i_item_sk FROM item_del) OR
    cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim_del) OR
    cs_ship_date_sk IN (SELECT d_date_sk FROM date_dim_del);

-- Select inserted/deleted tuples from store_returns.
CREATE TABLE store_returns_ins AS
SELECT *
FROM store_returns
WHERE
    sr_item_sk IN (SELECT ss_item_sk FROM store_sales_ins) OR
    sr_ticket_number IN (SELECT ss_ticket_number FROM store_sales_ins) OR
    sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim_ins);

CREATE TABLE store_returns_del AS
SELECT *
FROM store_returns
WHERE
    sr_item_sk IN (SELECT ss_item_sk FROM store_sales_del) OR
    sr_ticket_number IN (SELECT ss_ticket_number FROM store_sales_del) OR
    sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim_del);

-- Create tables.
CREATE TABLE store_returns_cpy
(
    sr_returned_date_sk       INTEGER,
    sr_return_time_sk         INTEGER,
    sr_item_sk                INTEGER  NOT NULL,
    sr_customer_sk            INTEGER,
    sr_cdemo_sk               INTEGER,
    sr_hdemo_sk               INTEGER,
    sr_addr_sk                INTEGER,
    sr_store_sk               INTEGER,
    sr_reason_sk              INTEGER,
    sr_ticket_number          BIGINT   NOT NULL,
    sr_return_quantity        INTEGER,
    sr_return_amt             DECIMAL(7,2),
    sr_return_tax             DECIMAL(7,2),
    sr_return_amt_inc_tax     DECIMAL(7,2),
    sr_fee                    DECIMAL(7,2),
    sr_return_ship_cost       DECIMAL(7,2),
    sr_refunded_cash          DECIMAL(7,2),
    sr_reversed_charge        DECIMAL(7,2),
    sr_store_credit           DECIMAL(7,2),
    sr_net_loss               DECIMAL(7,2)
)
DISTKEY(sr_item_sk)
SORTKEY(sr_returned_date_sk);

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

CREATE TABLE store_cpy
(
    s_store_sk          INTEGER   NOT NULL,
    s_store_id          CHAR(16)  NOT NULL,
    s_rec_start_date    DATE,
    s_rec_end_date      DATE,
    s_closed_date_sk    INTEGER,
    s_store_name        VARCHAR(50),
    s_number_employees  INTEGER,
    s_floor_space       INTEGER,
    s_hours             CHAR(20),
    s_manager           VARCHAR(40),
    s_market_id         INTEGER,
    s_geography_class   VARCHAR(100),
    s_market_desc       VARCHAR(100),
    s_market_manager    VARCHAR(40),
    s_division_id       INTEGER,
    s_division_name     VARCHAR(50),
    s_company_id        INTEGER,
    s_company_name      VARCHAR(50),
    s_street_number     VARCHAR(10),
    s_street_name       VARCHAR(60),
    s_street_type       CHAR(15),
    s_suite_number      CHAR(10),
    s_city              VARCHAR(60),
    s_county            VARCHAR(30),
    s_state             CHAR(2),
    s_zip               CHAR(10),
    s_country           VARCHAR(20),
    s_gmt_offset        DECIMAL(5,2),
    s_tax_precentage    DECIMAL(5,2)
)
DISTSTYLE all;

-- Add primary keys.
ALTER TABLE store_returns_cpy ADD PRIMARY KEY (sr_item_sk, sr_ticket_number);
ALTER TABLE store_sales_cpy   ADD PRIMARY KEY (ss_item_sk, ss_ticket_number);
ALTER TABLE catalog_sales_cpy ADD PRIMARY KEY (cs_item_sk, cs_order_number);
ALTER TABLE item_cpy          ADD PRIMARY KEY (i_item_sk);
ALTER TABLE date_dim_cpy      ADD PRIMARY KEY (d_date_sk);
ALTER TABLE store_cpy         ADD PRIMARY KEY (s_store_sk);

-- Add foreign keys.
ALTER TABLE store_returns_cpy ADD CONSTRAINT fk_1 FOREIGN KEY (sr_item_sk, sr_ticket_number) REFERENCES store_sales_cpy (ss_item_sk, ss_ticket_number);
ALTER TABLE store_returns_cpy ADD CONSTRAINT fk_2 FOREIGN KEY (sr_returned_date_sk) REFERENCES date_dim_cpy (d_date_sk);
ALTER TABLE store_sales_cpy   ADD CONSTRAINT fk_3 FOREIGN KEY (ss_sold_date_sk)     REFERENCES date_dim_cpy (d_date_sk);
ALTER TABLE store_sales_cpy   ADD CONSTRAINT fk_4 FOREIGN KEY (ss_item_sk)          REFERENCES item_cpy (i_item_sk);
ALTER TABLE store_sales_cpy   ADD CONSTRAINT fk_5 FOREIGN KEY (ss_store_sk)         REFERENCES store_cpy (s_store_sk);
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_6 FOREIGN KEY (cs_item_sk)          REFERENCES item_cpy (i_item_sk);
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_7 FOREIGN KEY (cs_sold_date_sk)     REFERENCES date_dim_cpy (d_date_sk);
ALTER TABLE catalog_sales_cpy ADD CONSTRAINT fk_8 FOREIGN KEY (cs_ship_date_sk)     REFERENCES date_dim_cpy (d_date_sk);

-- Load data.
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

INSERT INTO store_cpy
SELECT *
FROM store
WHERE
    s_store_sk NOT IN (SELECT s_store_sk FROM store_ins);

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

INSERT INTO store_returns_cpy
SELECT b.*
FROM
    store_returns b LEFT JOIN store_returns_ins s ON
    (
        b.sr_item_sk = s.sr_item_sk AND
        b.sr_ticket_number = s.sr_ticket_number
    )
WHERE
    s.sr_item_sk IS NULL AND
    s.sr_ticket_number IS NULL;

-- Analyze
ANALYZE store_cpy;
ANALYZE date_dim_cpy;
ANALYZE item_cpy;
ANALYZE store_sales_cpy;
ANALYZE catalog_sales_cpy;
ANALYZE store_returns_cpy;

-- Create materialized view
CREATE MATERIALIZED VIEW arbt AS
SELECT
    i_item_id,
    i_item_desc,
    s_store_id,
    s_store_name,
    d1.d_moy AS d1_d_moy,
    d2.d_moy AS d2_d_moy,
    d2.d_year AS d2_d_year,
    d3.d_year AS d3_d_year,
    ss_quantity AS attr1,
    sr_return_quantity AS attr2,
    cs_quantity AS attr3
FROM
    store_sales_cpy,
    store_returns_cpy,
    catalog_sales_cpy,
    date_dim_cpy d1,
    date_dim_cpy d2,
    date_dim_cpy d3,
    store_cpy,
    item_cpy
WHERE
    d2.d_date_sk = ss_sold_date_sk
    AND i_item_sk = ss_item_sk
    AND s_store_sk = ss_store_sk
    AND ss_customer_sk = sr_customer_sk
    AND ss_item_sk = sr_item_sk
    AND ss_ticket_number = sr_ticket_number
    AND sr_returned_date_sk = d1.d_date_sk
    AND i_item_sk = cs_item_sk
    AND cs_sold_date_sk = d3.d_date_sk;

-- Insert selected tuples
INSERT INTO store_cpy
SELECT *
FROM store_ins;

INSERT INTO item_cpy
SELECT *
FROM item_ins;

INSERT INTO date_dim_cpy
SELECT *
FROM date_dim_ins;

INSERT INTO store_sales_cpy
SELECT *
FROM store_sales_ins;

INSERT INTO catalog_sales_cpy
SELECT *
FROM catalog_sales_ins;

INSERT INTO store_returns_cpy
SELECT *
FROM store_returns_ins;

-- Delete selected tuples
DELETE FROM store_cpy using store_del
WHERE store_cpy.s_store_sk = store_del.s_store_sk;

DELETE FROM item_cpy using item_del
WHERE item_cpy.i_item_sk = item_del.i_item_sk;

DELETE FROM date_dim_cpy using date_dim_del
WHERE date_dim_cpy.d_date_sk = date_dim_del.d_date_sk;

DELETE FROM store_sales_cpy using store_sales_del
WHERE
    store_sales_cpy.ss_item_sk = store_sales_del.ss_item_sk
    AND store_sales_cpy.ss_ticket_number = store_sales_del.ss_ticket_number;

DELETE FROM catalog_sales_cpy using catalog_sales_del
WHERE
    catalog_sales_cpy.cs_item_sk = catalog_sales_del.cs_item_sk
    AND catalog_sales_cpy.cs_order_number = catalog_sales_del.cs_order_number;

DELETE FROM store_returns_cpy using store_returns_del
WHERE
    store_returns_cpy.sr_item_sk = store_returns_del.sr_item_sk
    AND store_returns_cpy.sr_ticket_number = store_returns_del.sr_ticket_number;

-- Refresh materialized view
REFRESH MATERIALIZED VIEW arbt;

-- Drop statements
DROP MATERIALIZED VIEW arbt;
DROP TABLE store_returns_ins;
DROP TABLE store_returns_del;
DROP TABLE store_returns_cpy;
DROP TABLE catalog_sales_ins;
DROP TABLE catalog_sales_del;
DROP TABLE catalog_sales_cpy;
DROP TABLE store_sales_ins;
DROP TABLE store_sales_del;
DROP TABLE store_sales_cpy;
DROP TABLE store_ins;
DROP TABLE store_del;
DROP TABLE store_cpy;
DROP TABLE item_ins;
DROP TABLE item_del;
DROP TABLE item_cpy;
DROP TABLE date_dim_ins;
DROP TABLE date_dim_del;
DROP TABLE date_dim_cpy;
