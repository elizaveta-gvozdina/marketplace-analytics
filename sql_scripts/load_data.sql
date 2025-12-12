/*
================================================================================
  e-commerce data loading script
================================================================================

This SQL script loads data from CSV files into the e-commerce database tables
using PostgreSQL's \copy command. 

IMPORTANT:
  This script is intended to be run in the PostgreSQL interactive terminal (psql).
  The \copy commands will not work in standard SQL editors or GUI clients.
  Usage example:
    1. Open terminal.
    2. Run: psql -U <username> -d <database_name>
    3. Execute this script using \i 'path/to/this/script.sql'
*/

-- Set client encoding
SET CLIENT_ENCODING TO 'UTF-8'; 

-- Start transaction (allows automatic rollback on errors)
BEGIN;

-- Load CSV files into tables via psql
\copy geolocations FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Geolocations.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy products FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Products.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy sellers_list FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Sellers List.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy customer_list FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Customer List.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy orders FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Orders.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy order_items FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Order Items.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy order_payments FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom Inc Order Payments.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');
\copy order_reviews FROM 'C:/Users/Vlad/Desktop/SQL project/dataset/Fecom_Inc_Order_Reviews_No_Emojis.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, NULL '');

-- Commit transaction to finalize data load
COMMIT;
