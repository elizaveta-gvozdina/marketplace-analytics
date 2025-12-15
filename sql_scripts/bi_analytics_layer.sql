/*
================================================================================
  Power BI analytics views
================================================================================

This SQL script creates analytical views for reporting and Power BI dashboards.

Purpose:
  - Support data analysis and visualization
  - Provide a clean, pre-aggregated analytical layer for logistics, sales, and retention

Data model:
  - Item-level fact view (delivery) for delivery and seller performance analysis
  - Order-level fact view (order_facts) for revenue and order-level metrics
  - Calendar dimension to support time-based analysis and period comparisons

Includes aggregated views for:
  - Top delivery routes
  - Late deliveries by sellers
  - Customer retention cohorts
*/


/* Calendar view: date dimension for time-based analysis:
  - Generates a continuous date range with derived time attributes
  - Supports time intelligence calculations (YTD, MTD, period comparisons)
  - Ensures correct sorting and filtering in Power BI
*/
--DROP VIEW IF EXISTS calendar;
CREATE OR REPLACE VIEW calendar AS
SELECT
    d::date AS date,                               -- Actual date
    DATE_TRUNC('month', d)::date AS month_start,   -- First day of the month
    DATE_TRUNC('year', d)::date AS year_start,     -- First day of the year

    EXTRACT(YEAR FROM d)::int AS year,            -- Numeric year
    EXTRACT(MONTH FROM d)::int AS month_number,   -- Numeric month
    TO_CHAR(d, 'Month') AS month_name,            -- Full month name
    TO_CHAR(d, 'Mon') AS month_short,             -- Abbreviated month
    EXTRACT(DAY FROM d)::int AS day_of_month,     -- Day of the month

    EXTRACT(ISODOW FROM d)::int AS day_of_week_iso,  -- ISO day of week (1=Mon..7=Sun)
    TO_CHAR(d, 'Day') AS day_name,                   -- Full day name
    TO_CHAR(d, 'Dy') AS day_short,                  -- Abbreviated day name
    CASE WHEN EXTRACT(ISODOW FROM d) IN (6,7) THEN true ELSE false END AS is_weekend,  -- Weekend flag

    TO_CHAR(d, 'YYYY-MM') AS month_year,             -- Formatted year-month string "2025-03"
    TO_CHAR(d, 'Month YYYY') AS month_year_label,    -- Formatted "March 2025"
    TO_CHAR(d, 'MonYY') AS short_month_year_label   -- Formatted "Mar25"

FROM generate_series(
    '2020-01-01'::date,
    '2025-01-01'::date,
    '1 day'::interval
) AS d
ORDER BY date;  -- Ensures the view is sorted chronologically

/* -- Drop existing views if they exist to allow recreation:
DROP VIEW IF EXISTS top_delivery_routes;
DROP VIEW IF EXISTS order_facts;
DROP VIEW IF EXISTS late_by_sellers;
DROP VIEW IF EXISTS cohorts;
DROP VIEW IF EXISTS delivery_orders_agg; 
DROP VIEW IF EXISTS delivery;
*/

/* 
Delivery view: item-level fact view combining orders, customers, sellers, geolocations, and reviews
- Base fact view for delivery and seller performance analysis
*/
CREATE OR REPLACE VIEW delivery AS 
WITH last_review AS ( 
    -- Includes latest review score per order using ROW_NUMBER() to select the most recent review
    SELECT
        order_id,
        review_score
    FROM (
        SELECT
            order_id,
            review_score,
            ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC) AS row_num
        FROM order_reviews
    ) t
    WHERE 
        row_num = 1
)
SELECT
    oi.order_id,
    oi.product_id,
    o.order_status,

	oi.price as item_price,                                 -- Price of the individual order item
    oi.seller_id,
	g_c.geolocation_id AS customer_geo_id,                  -- Customer's geolocation surrogate key
    CAST(o.order_purchase_timestamp AS date) AS order_date, -- Purchase date of the order
    

    CASE
    -- Calculates delivery status at the order level
        WHEN o.order_status = 'canceled' THEN 'canceled'
        WHEN o.order_delivered_customer_date IS NULL THEN 'pending'
        WHEN CAST(o.order_delivered_customer_date AS date) > o.order_estimated_delivery_date THEN 'late_delivery'
        ELSE 'on_time'
    END AS delivery_status,
    
    CASE
    -- Computes delivery days: difference between delivery date and order date
        WHEN o.order_delivered_customer_date IS NOT NULL
            THEN (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)::int
        ELSE NULL
    END AS delivery_days,
    
    CASE
    -- Calculates seller-level delivery performance
        WHEN o.order_status = 'canceled' AND o.order_delivered_carrier_date IS NULL THEN 'canceled_before_shipping'
        WHEN o.order_status = 'canceled' AND o.order_delivered_carrier_date IS NOT NULL 
             AND o.order_delivered_carrier_date > oi.shipping_limit_date THEN 'late_seller'
        WHEN o.order_status = 'canceled' AND o.order_delivered_carrier_date IS NOT NULL THEN 'on_time_seller'
        WHEN oi.shipping_limit_date IS NULL THEN 'pending'
        WHEN o.order_delivered_carrier_date IS NULL THEN 'pending'
        WHEN o.order_delivered_carrier_date > oi.shipping_limit_date THEN 'late_seller'
        ELSE 'on_time_seller'
    END AS seller_delivery_status,

    g_c.geo_country AS customer_country,
    g_s.geo_country AS seller_country,
    lr.review_score                            -- Latest review score from last_review CTE

FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN customer_list cl ON cl.customer_trx_id = o.customer_trx_id
LEFT JOIN sellers_list sl ON sl.seller_id = oi.seller_id
LEFT JOIN geolocations g_c ON cl.geolocation_id = g_c.geolocation_id
LEFT JOIN geolocations g_s ON sl.geolocation_id = g_s.geolocation_id
LEFT JOIN last_review lr ON lr.order_id = o.order_id
LEFT JOIN products pr ON pr.product_id = oi.product_id
LEFT JOIN (
    -- Aggregated payments per order
    SELECT 
        order_id, 
        SUM(payment_value) AS order_revenue
    FROM 
        order_payments
    GROUP BY 
         order_id
) p_agg ON p_agg.order_id = oi.order_id;

/* 
Order facts: Order-level fact view aggregated from delivery data:
- Intended for high-level sales, revenue, and delivery performance reporting
*/

-- DROP VIEW IF EXISTS order_facts;
CREATE OR REPLACE VIEW order_facts AS
SELECT
    o.order_id,
    cl.subscriber_id,               -- Customer-level subscriber identifier
    cl.customer_trx_id,             -- Customer transaction ID
    o.order_status,
    CAST(o.order_purchase_timestamp AS date) AS order_date, -- Purchase date of the order
    COALESCE(p_agg.order_revenue, 0) AS order_revenue,      -- Total revenue for the order, defaults to 0 if no payments
    d_agg.review_score,                                     -- Latest review score for the order
    g_c.geolocation_id AS customer_geo_id,                  -- Customer geolocation surrogate key
    d_agg.delivery_status,                          -- Overall delivery status from item-level aggregation
    d_agg.delivery_days AS delivery_days            -- Total days between purchase and delivery
FROM 
    orders o
LEFT JOIN (
    -- Aggregated payments per order
    SELECT order_id, 
           SUM(payment_value) AS order_revenue
    FROM order_payments
    GROUP BY order_id
) p_agg ON p_agg.order_id = o.order_id
LEFT JOIN customer_list cl ON cl.customer_trx_id = o.customer_trx_id
LEFT JOIN geolocations g_c ON g_c.geolocation_id = cl.geolocation_id
LEFT JOIN (
    -- Aggregate delivery info from item-level view to order-level
	SELECT 
        order_id,
		MIN(delivery_status) AS delivery_status, 
		--MIN(seller_delivery_status) AS seller_delivery_status,
		MIN(delivery_days) AS delivery_days, 
		MIN(review_score) AS review_score  
	FROM delivery
	GROUP BY order_id
) d_agg ON d_agg.order_id = o.order_id;

/* 
Top delivery routes: Aggregated view of delivery performance between seller and customer countries.
- Used to identify top delivery routes 2024
*/
CREATE OR REPLACE VIEW top_delivery_routes AS
SELECT
    seller_country AS from_country,          -- Origin country of the seller
    customer_country AS to_country,          -- Destination country of the customer
    COUNT(*) AS total_orders,                -- Total number of orders for this route
    SUM(CASE WHEN delivery_status = 'late_delivery' THEN 1 ELSE 0 END)::float
        / COUNT(*) AS late_ratio,           -- Ratio of late deliveries per route
    AVG(delivery_days) AS avg_delivery_days,  -- Average delivery time in days
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY delivery_days) AS median_delivery_days -- Median delivery time

FROM (
    -- Subquery to get distinct orders with relevant delivery info
    SELECT DISTINCT
        order_id,
        seller_country,
        customer_country,
        delivery_status,
        delivery_days
    FROM delivery
    WHERE order_date BETWEEN '2024-01-01' AND '2024-08-31'  -- Filter orders for specific period
) t1_1

GROUP BY seller_country, customer_country  -- Aggregate metrics per route
HAVING COUNT(*) >= 40                       -- Include only routes with 40+ orders
ORDER BY late_ratio DESC;                   -- Sort routes by worst delivery performance


/*
 Late by sellers: Seller-focused view for analyzing late and problematic deliveries.
- Data reflects Year-To-Date (YTD) for 2024, basically a filtered slice of 'delivery'
- Intended for seller monitoring and operational analysis.
*/
CREATE OR REPLACE VIEW late_by_sellers AS
SELECT DISTINCT
    d.order_id,
    d.seller_id,
    sl.seller_name,
    d.seller_country,
    d.customer_geo_id,
    d.delivery_status,
	d.seller_delivery_status, 
    d.delivery_days,
    d.order_date
FROM 
    delivery d
LEFT JOIN sellers_list sl 
    ON sl.seller_id = d.seller_id
WHERE 
    d.order_date BETWEEN '2024-01-01' AND '2024-08-31';

/*
Cohorts: 
- Cohort analysis view based on customers' first order date.
- Calculates monthly retention by cohort and relative retention percentage.
- Used for customer lifecycle and retention analysis.
*/
CREATE OR REPLACE VIEW cohorts AS
SELECT
    cohort_month,
    month_number,
    users, 
    -- Retention percentage: users in the current month divided by the initial cohort size:
    users::decimal / FIRST_VALUE(users) OVER(PARTITION BY cohort_month ORDER BY month_number) AS retention_pct
FROM (
    SELECT  
        DATE_TRUNC('month', cl.first_order_date)::date AS cohort_month,                                                  -- Cohort month based on the user's first order date
        (EXTRACT(YEAR FROM o.order_purchase_timestamp)*12 + EXTRACT(MONTH FROM o.order_purchase_timestamp)               -- Number of months since the cohort's first order (0 = first month)
          - (EXTRACT(YEAR FROM cl.first_order_date)*12 + EXTRACT(MONTH FROM cl.first_order_date)))::int AS month_number, 
        COUNT(DISTINCT cl.subscriber_id) AS users                                                                        -- Number of unique users in the cohort for that month
    FROM orders o
    JOIN customer_list cl 
        ON cl.customer_trx_id = o.customer_trx_id
	WHERE EXTRACT(YEAR FROM cl.first_order_date) IN (2023, 2024) AND (o.order_status NOT IN ('canceled'))     -- Include only users with first orders in 2023 or 2024 and valid (non-canceled) orders:
    GROUP BY cohort_month, month_number
) t3;

   


 

