-- Run this in the PostgreSQL interactive terminal
-- Set client encoding
--SET CLIENT_ENCODING TO 'WIN1251';
SET CLIENT_ENCODING TO 'UTF-8';

-- Start transaction (optional)
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

-- Commit transaction
COMMIT;
