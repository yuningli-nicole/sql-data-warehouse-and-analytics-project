/*
===============================================================================
Quality Checks
===============================================================================
Script Purpose:
    This script performs various quality checks for data consistency, accuracy, 
    and standardization across the 'silver' layer. It includes checks for:
    - Null or duplicate primary keys.
    - Unwanted spaces in string fields.
    - Data standardization and consistency.
    - Invalid date ranges and orders.
    - Data consistency between related fields.

Usage Notes:
    - Run these checks after data loading Silver Layer.
    - Investigate and resolve any discrepancies found during the checks.
===============================================================================
*/


-- crm_cust_info
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT cst_id, count(*)
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL

-- Check for unwanted spaces
-- Expectation: No Results
SELECT cst_firstname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)

SELECT cst_gndr
FROM silver.crm_cust_info
WHERE cst_gndr != TRIM(cst_gndr)

-- Data Standardization & Consistency
SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info



-- crm_prd_info
-- Check For Nulls or Duplicates in Primary Key
-- Expectation: No Result
SELECT
prd_id,
COUNT(*)
FROM silver.crm_prd_info
GROUP BY prd_id
HAVING COUNT(*) > 1 OR prd_id IS NULL

-- Check for unwanted spaces
-- Expectation: No Results
SELECT prd_nm
FROM silver.crm_prd_info
WHERE prd_nm != TRIM(prd_nm)

-- Check for Nulls or Negative Numbers
-- Expectation: No Results
SELECT prd_cost
FROM silver.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL

-- Data Standardization & Consistency
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

-- Check for Invalid Date Orders
SELECT * 
FROM silver.crm_prd_info
WHERE prd_end_dt < prd_start_dt




-- crm_sales_details
-- Check for Invalid Dates
SELECT
NULLIF(sls_order_dt, 0) sls_order_dt
FROM silver.crm_sales_details
WHERE sls_order_dt <= 0 
OR LEN(sls_order_dt) != 8 
OR sls_order_dt > 20500101 
OR sls_order_dt < 19000101

-- Check for Invalid Date Orders
SELECT
*
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt OR sls_order_dt > sls_due_dt

-- Check for Data Consistency: Between Sales, Quantity, and Price
-- >> Business Rules: sales = quantity * price
-- >> Negative, zeros, nulls are not allowed
SELECT DISTINCT
sls_sales AS old_sls_sales,
sls_quantity,
sls_price AS old_sls_price,
CASE WHEN sls_sales IS NULL OR sls_sales <= 0 OR sls_sales != sls_quantity * ABS(sls_price)
        THEN sls_quantity * ABS(sls_price)
     ELSE sls_sales
END AS sls_sales,
CASE WHEN sls_price IS NULL OR sls_price <= 0 
        THEN sls_sales / NULLIF(sls_quantity, 0)
     ELSE sls_price
END AS sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
OR sls_sales IS NULL OR sls_quantity IS NULL OR sls_price IS NULL
OR sls_sales <= 0 OR sls_quantity <= 0 OR sls_price <= 0
ORDER BY sls_sales, sls_quantity, sls_price
-- Rules: If Sales is negative, zero, or null, derive it using Quantity and Price.
--        If Price is zero or null, calculate it using Sales and Quantity.
--        If Price is negative, convert it to a positive value.




-- erp_cust_az12
-- Identify Out-of-Range Dates
SELECT DISTINCT 
bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

-- Data Standardization & Consistency
SELECT DISTINCT
gen
FROM silver.erp_cust_az12



-- erp_loc_a101
-- Data Standardization & Consistency
SELECT DISTINCT cntry
FROM silver.erp_loc_a101
ORDER BY cntry



-- erp_px_cat_g1v2
-- Check for unwanted spaces
SELECT *
FROM silver.erp_px_cat_g1v2
WHERE cat != TRIM(cat) OR subcat != TRIM(subcat) OR maintenance != TRIM(maintenance)

-- Data Standardization & Consistency
SELECT DISTINCT
maintenance
FROM silver.erp_px_cat_g1v2
