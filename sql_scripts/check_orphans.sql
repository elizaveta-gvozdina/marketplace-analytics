/*
================================================================================
  Orphan data check
================================================================================

This SQL script checks for orphan records* in the e-commerce database.

*Orphan records are entries in a child table that do not have a corresponding 
parent record in the related table.  
*/

-- 1. Sellers without valid geolocation
SELECT s.*
FROM sellers_list s
LEFT JOIN geolocations g 
    ON s.geolocation_id = g.geolocation_id
WHERE g.geolocation_id IS NULL;

-- 2. Customers without valid geolocation
SELECT c.*
FROM customer_list c
LEFT JOIN geolocations g 
    ON c.geolocation_id = g.geolocation_id
WHERE g.geolocation_id IS NULL;

-- 3. Orders without a valid customer
SELECT o.*
FROM orders o
LEFT JOIN customer_list c ON o.customer_trx_id = c.customer_trx_id
WHERE c.customer_trx_id IS NULL;

-- 4. Order items without a valid order
SELECT oi.*
FROM order_items oi
LEFT JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 5. Order items with invalid product
SELECT oi.*
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- 6. Order items with invalid seller
SELECT oi.*
FROM order_items oi
LEFT JOIN sellers_list s ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- 7. Payments with invalid order
SELECT op.*
FROM order_payments op
LEFT JOIN orders o ON op.order_id = o.order_id
WHERE o.order_id IS NULL;

-- 8. Reviews with invalid order
SELECT r.*
FROM order_reviews r
LEFT JOIN orders o ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

