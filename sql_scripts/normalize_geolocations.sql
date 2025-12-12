/*
================================================================================
  Geolocations normalization and surrogate key update
================================================================================

This SQL script refactors the geolocations table and updates related tables
(customer_list and sellers_list) to use a surrogate primary key (geolocation_id)
instead of composite keys (postal_code + city). 

Purpose:
   - Normalize geolocations and related tables (towards 3NF)
   - Remove data redundancy
   - Ensure consistency and improve query performance
================================================================================
*/

--ROLLBACK;
--ALTER TABLE geolocations DROP COLUMN geolocation_id CASCADE;

-- Start transaction (allows automatic rollback on errors)
BEGIN;   

-- 1. Drop old primary key
ALTER TABLE geolocations
DROP CONSTRAINT geolocations_pkey CASCADE;

-- 2. Add a surrogate PK to geolocations
ALTER TABLE geolocations
ADD COLUMN geolocation_id BIGSERIAL PRIMARY KEY;

/*
-- Check the uniqueness of combinations to avoid duplicates
SELECT 
    geo_postal_code, geolocation_city, geo_country, COUNT(*)
FROM 
    geolocations
GROUP BY 
    geo_postal_code, geolocation_city, geo_country
HAVING 
    COUNT(*) > 1;
*/

-- 3. Add geolocation_id to customer_list and sellers_list
ALTER TABLE customer_list ADD COLUMN geolocation_id INTEGER;
ALTER TABLE sellers_list ADD COLUMN geolocation_id INTEGER;

-- 4. Add a column for country code to geolocations
ALTER TABLE geolocations
ADD COLUMN geo_country_code CHAR(2);

-- 5. Fill geo_country_code via JOIN with customer_list
UPDATE geolocations g
SET geo_country_code = cl.customer_country_code
FROM customer_list cl
WHERE LOWER(TRIM(g.geo_country)) = LOWER(TRIM(cl.customer_country));

/*
-- Check that all rows are populated
SELECT *
FROM 
    geolocations
WHERE 
    geo_country_code IS NULL;
*/

-- 6. Populate geolocation_id for customers
UPDATE customer_list cl
SET geolocation_id = g.geolocation_id
FROM geolocations g
WHERE LOWER(TRIM(cl.customer_city)) = LOWER(TRIM(g.geolocation_city))
  AND (LOWER(TRIM(cl.customer_country)) = LOWER(TRIM(g.geo_country)) OR cl.customer_country IS NULL);

-- 7. Populate geolocation_id for sellers
UPDATE sellers_list sl
SET geolocation_id = g.geolocation_id
FROM geolocations g
WHERE LOWER(TRIM(sl.seller_city)) = LOWER(TRIM(g.geolocation_city))
  AND (LOWER(TRIM(sl.seller_country)) = LOWER(TRIM(g.geo_country)) OR sl.seller_country IS NULL);

-- 8. Check for any missing geolocation_id values
SELECT COUNT(*) AS missing_customers FROM customer_list WHERE geolocation_id IS NULL;
SELECT COUNT(*) AS missing_sellers FROM sellers_list WHERE geolocation_id IS NULL;

-- 9. Drop old postal/city/country columns
ALTER TABLE customer_list
    DROP COLUMN customer_postal_code,
    DROP COLUMN customer_city,
    DROP COLUMN customer_country_code,
    DROP COLUMN customer_country;

ALTER TABLE sellers_list
    DROP COLUMN seller_postal_code,
    DROP COLUMN seller_city,
    DROP COLUMN country_code,
    DROP COLUMN seller_country;

-- 10. Add foreign key constraints to geolocations
ALTER TABLE customer_list
    ADD CONSTRAINT fk_customer_geo FOREIGN KEY (geolocation_id)
    REFERENCES geolocations(geolocation_id);

ALTER TABLE sellers_list
    ADD CONSTRAINT fk_seller_geo FOREIGN KEY (geolocation_id)
    REFERENCES geolocations(geolocation_id);

-- 11. Create indexes on geolocation_id for faster lookup
CREATE INDEX idx_customer_geo_id ON customer_list(geolocation_id);
CREATE INDEX idx_seller_geo_id ON sellers_list(geolocation_id);

COMMIT;

