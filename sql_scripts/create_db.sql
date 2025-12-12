/*
================================================================================
  e-commerce database schema setup
================================================================================

This SQL script sets up the main e-commerce database schema, including tables,
types, constraints, and indexes

Main points of this script:

1. Data Definition (DDL):
   - Creates all tables with primary keys
   - Defines ENUM types 
   - Sets up foreign key relationships between tables
   - Creates indexes for faster query performance

2. Data Validation / Integrity:
   - Checks on numeric fields (weight, dimensions, price, installments) to ensure
     values are reasonable and non-negative
   - Constraints on age (must be between 13 and 150) and review scores (1–5)
   - Primary keys guarantee uniqueness where needed

3. Optional schema reset:
   - Commented out DROP SCHEMA / CREATE SCHEMA commands allow resetting the database
     if needed

This script does not insert any data. Its purpose is to define the structure of the
database, enforce integrity rules, and prepare the database for loading data
in separate scripts.    
*/

--Drop and recreate the public schema (resets the database)
/*
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
*/

-- ENUM type for order status
DROP TYPE IF EXISTS order_status_type;
CREATE TYPE order_status_type AS ENUM (
    'created',
    'approved',
    'shipped',
    'delivered',
    'canceled',
	'invoiced', 
	'processing',
	'unavailable'
);

-- Geolocations table: stores postal codes with coordinates and city/country
-- DROP TABLE IF EXISTS geolocations;
CREATE TABLE geolocations (
    geo_postal_code VARCHAR(16) NOT NULL,
    geo_lat double precision,
    geo_lon double precision,
	geolocation_city VARCHAR(128) NOT NULL,
    geo_country VARCHAR(64) NOT NULL,
    PRIMARY KEY (geo_postal_code, geolocation_city) 
);

-- Customers table with foreign key to geolocations
-- DROP TABLE IF EXISTS customer_list;
CREATE TABLE customer_list (
    customer_trx_id VARCHAR(32) PRIMARY KEY,
    subscriber_id VARCHAR(32) NOT NULL,
    subscribe_date DATE NOT NULL,
    first_order_date DATE,
    customer_postal_code VARCHAR(16) NOT NULL,
    customer_city VARCHAR(128) NOT NULL,
    customer_country VARCHAR(64) NOT NULL,
    customer_country_code CHAR(2),
    age SMALLINT CHECK (age >= 13 AND age <= 150), -- Ensures reasonable age
    gender VARCHAR(50),
	CONSTRAINT fk_customer_geo_postal
		FOREIGN KEY (customer_postal_code, customer_city)
		REFERENCES geolocations (geo_postal_code, geolocation_city)
);
-- CREATE INDEX idx_customer_postal_city ON customer_list (customer_postal_code, customer_city);

-- Sellers table with foreign key to geolocations
-- DROP TABLE IF EXISTS sellers_list;
CREATE TABLE sellers_list (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_name VARCHAR(255) NOT NULL,
    seller_postal_code VARCHAR(16) NOT NULL,
    seller_city VARCHAR(128) NOT NULL,
    country_code CHAR(2),
    seller_country VARCHAR(64) NOT NULL,
    CONSTRAINT fk_seller_geo_postal
    	FOREIGN KEY (seller_postal_code, seller_city)
    	REFERENCES geolocations (geo_postal_code, geolocation_city)
);
-- CREATE INDEX idx_seller_postal_city ON sellers_list (seller_postal_code, seller_city);

-- Products table with basic product attributes
-- DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_weight_gr INTEGER CHECK (product_weight_gr >= 0),
    product_length_cm INTEGER CHECK (product_length_cm >= 0),
    product_height_cm INTEGER CHECK (product_height_cm >= 0),
    product_width_cm INTEGER CHECK (product_width_cm >= 0) -- Product dimensions and weight (non-negative values)
);

-- Orders table with status ENUM and timestamps
-- DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_trx_id VARCHAR(32) UNIQUE NOT NULL REFERENCES customer_list (customer_trx_id),
    order_status order_status_type NOT NULL,
    order_purchase_timestamp TIMESTAMP NOT NULL,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date DATE NOT NULL
);
CREATE INDEX idx_orders_customer_trx ON orders (customer_trx_id); -- Index to quickly find orders by customer_trx_id
CREATE INDEX idx_orders_purchase_ts ON orders (order_purchase_timestamp); -- Index to quickly filter orders by purchase timestamp

-- Order items table linking orders, products, and sellers
-- DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    order_id VARCHAR(32) REFERENCES orders (order_id),
    order_item_id SMALLINT CHECK (order_item_id > 0), -- Item sequence must be positive
    product_id VARCHAR(32) NOT NULL REFERENCES products (product_id),
    seller_id VARCHAR(32) NOT NULL REFERENCES sellers_list (seller_id) ,
    shipping_limit_date TIMESTAMP,
    price NUMERIC(12,2) CHECK (price >= 0) NOT NULL, -- Price cannot be negative
    freight_value NUMERIC(12,2) NOT NULL CHECK (freight_value >= 0), -- Freight cost cannot be negative
    PRIMARY KEY (order_id, order_item_id)
);
CREATE INDEX idx_order_items_product ON order_items (product_id); -- Index to quickly find order items by product
CREATE INDEX idx_order_items_seller ON order_items (seller_id); -- Index to quickly find order items by seller

-- Order payments table storing multiple payments per order
-- DROP TABLE IF EXISTS order_payments;
CREATE TABLE order_payments (
    order_id VARCHAR(32) REFERENCES orders (order_id),
    payment_sequential SMALLINT CHECK (payment_sequential > 0),
    payment_type VARCHAR(32) NOT NULL,
    payment_installments SMALLINT NOT NULL CHECK (payment_installments >= 0),
    payment_value NUMERIC(12,2) CHECK (payment_value >= 0) NOT NULL,
    PRIMARY KEY (order_id, payment_sequential)
);

-- Order reviews table linking reviews to orders
-- DROP TABLE IF EXISTS order_reviews;
CREATE TABLE order_reviews (
    review_id VARCHAR(32) NOT NULL,
    order_id VARCHAR(32) NOT NULL REFERENCES orders (order_id),
    review_score SMALLINT CHECK (review_score BETWEEN 1 AND 5) NOT NULL, -- Score must be between 1 and 5
    review_comment_title_en VARCHAR(100),
    review_comment_message_en VARCHAR(3000),
    review_creation_date DATE,
    review_answer_timestamp TIMESTAMP
);
