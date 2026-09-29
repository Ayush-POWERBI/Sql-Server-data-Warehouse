use datawarehouse
-- Sample extraction from source bronze tables for exploratory validation before transformation.
select top 1000 * from bronze.crm_cust_info
select top 1000 * from bronze.crm_prd_info
select top 1000 * from bronze.crm_sales_details

select top 1000 * from bronze.erp_cust_az12
select top 1000 * from bronze.erp_loc_a101
select top 1000 * from bronze.erp_px_cat_giv2

-- Create the silver-layer tables used to store the cleaned and standardized business records.
IF OBJECT_ID ('silver.crm_cust_info','U') is not null
  Drop TABLE silver.crm_cust_info
create table silver.crm_cust_info(
  cst_id int,
  cst_key nvarchar(50),
  cst_firstname nvarchar(50),
  cst_lastname nvarchar(50),
  cst_material_status nvarchar(50),
  cst_gndr nvarchar(50),
  cst_create_date Date,
  dwh_create_date DATETIME2 Default GETDATE()
  );

IF OBJECT_ID ('silver.crm_prd_info','U') is not null
  Drop TABLE silver.crm_prd_info
Create table silver.crm_prd_info(
  prd_id int,
  cat_id nvarchar(50),
  prd_key nvarchar(50),
  prd_nm nvarchar(50),
  prd_cost int,
  prd_line nvarchar(50),
  prd_start_dt datetime,
  prd_end_dt datetime,
  dwh_create_date DATETIME2 Default GETDATE()
);

IF OBJECT_ID ('silver.crm_sales_details','U') is not null
  Drop TABLE silver.crm_sales_details
create table silver.crm_sales_details(
  sls_ord_num nvarchar(50),
  sls_prd_key nvarchar(50),
  sls_cust_id int,
  sls_order_dt DATE,
  sls_ship_dt DATE,
  sls_due_dt DATE,
  sls_sales int,
  sls_quantity int,
  sls_price int,
  dwh_create_date DATETIME2 Default GETDATE()
);

IF OBJECT_ID ('silver.erp_loc_a101','U') is not null
  Drop TABLE silver.erp_loc_a101
create table silver.erp_loc_a101(
  cid nvarchar(50),
  cntry nvarchar(50),
  dwh_create_date DATETIME2 Default GETDATE()
);

IF OBJECT_ID ('silver.erp_cust_az12','U') is not null
  Drop TABLE silver.erp_cust_az12
create table silver.erp_cust_az12(
  cid nvarchar(50),
  bdate date,
  gen nvarchar(50),
  dwh_create_date DATETIME2 Default GETDATE()
);

IF OBJECT_ID ('silver.erp_px_cat_giv2','U') is not null
  Drop TABLE silver.erp_px_cat_giv2
create table silver.erp_px_cat_giv2(
  id nvarchar(50),
  cat nvarchar(50),
  subcat nvarchar(50),
  maintenance nvarchar(50),
  dwh_create_date DATETIME2 Default GETDATE()
);

-- 1. Transform CRM customer data into a trusted silver-dimension record.
-- The checks below identify duplicate customer identifiers and keep only the most recent record per customer.
SELECT * FROM bronze.crm_cust_info

-- Audit for duplicates and null customer keys before loading the gold-standard version.
select
 cst_id,
 count(*) 
 from bronze.crm_cust_info
 group by cst_id
 having count(*) > 1 or cst_id is null

-- Retain only the latest version of each customer based on the most recent creation timestamp.
select * from(
select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1

-- Remove unintended leading/trailing spaces from customer names and validate the raw source values.

SELECT
  cst_id,
  cst_key,
  TRIM(cst_firstname) as cst_firstname,
  TRIM(cst_lastname) as cst_lastname,
  cst_material_status,
  cst_gndr,
  cst_create_date
  from (select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1

-- Standardize raw gender and marital codes to consistent business-friendly labels for downstream reporting.
Select
distinct(cst_gndr)
from bronze.crm_cust_info

-- Normalize customer attributes into a clean silver dimension: trim text, map codes, and preserve the latest row.
SELECT
  cst_id,
  cst_key,
  TRIM(cst_firstname) as cst_firstname,
  TRIM(cst_lastname) as cst_lastname,
  CASE
  WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
  WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
  WHEN cst_material_status is null then 'Unknown'
  end as cst_material_status,
 case
  when UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
  WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
  when cst_gndr is null then 'Unknown'
  end as cst_gndr,
  cst_create_date
  from (select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1

-- Insert the cleaned customer records into the silver dimension table for analytics consumption.
INSERT INTO silver.crm_cust_info(
  cst_id,
  cst_key,
  cst_firstname,
  cst_lastname,
  cst_material_status,
  cst_gndr,
  cst_create_date)

  SELECT
  cst_id,
  cst_key,
  TRIM(cst_firstname) as cst_firstname,
  TRIM(cst_lastname) as cst_lastname,
  CASE
  WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
  WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
  WHEN cst_material_status is null then 'Unknown'
  end as cst_material_status,
 case
  when UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
  WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
  when cst_gndr is null then 'Unknown'
  end as cst_gndr,
  cst_create_date
  from (select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1

select * from silver.crm_cust_info

-- 2. Clean and normalize the CRM product dimension before loading to silver.
select * from bronze.crm_prd_info
-- Review product identifier quality to detect duplicate or null keys that would corrupt downstream joins.

select prd_id,
count(*)
from 
bronze.crm_prd_info
group by prd_id
having count(*) =  1 or prd_id is null

-- Parse the product key into a category code and standardized product identifier while removing separators.
select 
  prd_id,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
  REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key,
  prd_nm,
  prd_cost,
  prd_line,
  prd_start_dt,
  prd_end_dt
  from bronze.crm_prd_info

-- Identify name values with stray spaces so they can be normalized before analytics usage.
select 
prd_nm
from bronze.crm_prd_info
where prd_nm <> trim(prd_nm)

-- Validate pricing data and flag null or negative values that need to be corrected in the silver layer.
 select 
 prd_cost
 from 
 bronze.crm_prd_info
 where prd_cost < 0 or prd_cost is null

 -- Replace missing cost values with zero to prevent null-driven downstream calculation issues.
 select 
  prd_id,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
  REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key,
  prd_nm,
  ISNULL(prd_cost,0) as prd_cost,
  prd_line,
  prd_start_dt,
  prd_end_dt
  from bronze.crm_prd_info
-- Standardize product line values to business-readable names and confirm the valid source codes.
  Select
  distinct(prd_line) from bronze.crm_prd_info

 -- Prepare a final cleaned product dataset with standardized codes, safe costs, and corrected effective dates.
 select 
  prd_id,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
  REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key,
  prd_nm,
  ISNULL(prd_cost,0) as prd_cost,
  CASE
  WHEN UPPER(TRIM(prd_line)) = 'M' then 'Mountains'
  WHEN UPPER(TRIM(prd_line)) = 'R' then 'Road'
  WHEN UPPER(TRIM(prd_line)) = 'S' then 'Other Sales'
  WHEN UPPER(TRIM(prd_line)) = 'T' then 'Touring'
  WHEN prd_line is null then 'Unknown'
  end as prd_line,
  CAST(prd_start_dt AS DATE) AS prd_start_dt,
  CAST(LEAD(prd_start_dt) over (partition by prd_key order by prd_end_dt asc)-1 AS DATE)as prd_end_dt
  from bronze.crm_prd_info

-- Insert the standardized product records into the silver dimension table.

INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
 select 
  prd_id,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
  REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key,
  prd_nm,
  ISNULL(prd_cost,0) as prd_cost,
  CASE
  WHEN UPPER(TRIM(prd_line)) = 'M' then 'Mountains'
  WHEN UPPER(TRIM(prd_line)) = 'R' then 'Road'
  WHEN UPPER(TRIM(prd_line)) = 'S' then 'Other Sales'
  WHEN UPPER(TRIM(prd_line)) = 'T' then 'Touring'
  WHEN prd_line is null then 'Unknown'
  end as prd_line,
  CAST(prd_start_dt AS DATE) AS prd_start_dt,
  CAST(LEAD(prd_start_dt) over (partition by prd_key order by prd_end_dt asc)-1 AS DATE)as prd_end_dt
  from bronze.crm_prd_info

 -- 3. Standardize CRM sales facts by cleaning dates and reconciling sales values.

 -- Review raw sales transactions before transformation to understand the source structure and date format issues.
 Select
 sls_ord_num,
 sls_prd_key,
 sls_cust_id,
 sls_order_dt,
 sls_ship_dt,
 sls_due_dt,
 sls_sales,
 sls_quantity,
 sls_price 
 from bronze.crm_sales_details

 -- Identify invalid or malformed date keys that do not conform to an 8-character business date format.
   select
   sls_order_dt
   from bronze.crm_sales_details
   where len(sls_order_dt) <> 8 or sls_order_dt is null 
   or sls_order_dt <= 0

-- Convert source date strings to proper DATE values while setting malformed dates to NULL.


 SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt = 0 or LEN(sls_order_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE
WHEN sls_ship_dt = 0 or len(sls_ship_dt) <> 8 THEN Null
ELSE cast(cast(sls_ship_dt AS VARCHAR ) AS DATE) 
END AS sls_ship_dt,
CASE
when sls_due_dt = 0 or len(sls_due_dt) <> 8 THEN NULL
ELSE cast(cast(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
sls_sales,
sls_quantity,
sls_price
FROM bronze.crm_sales_details

-- Ensure sales amounts are internally consistent by recalculating invalid values using quantity and price.
-- Business rule: sales should equal quantity multiplied by price, and invalid or negative values are corrected.
  
  SELECT
sls_ord_num,
REPLACE(sls_prd_key,'-','_') as sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt = 0 or LEN(sls_order_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE
WHEN sls_ship_dt = 0 or len(sls_ship_dt) <> 8 THEN Null
ELSE cast(cast(sls_ship_dt AS VARCHAR ) AS DATE) 
END AS sls_ship_dt,
CASE
when sls_due_dt = 0 or len(sls_due_dt) <> 8 THEN NULL
ELSE cast(cast(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
case
when sls_sales is null or sls_sales <> sls_quantity * sls_price or sls_sales <= 0 then sls_quantity * ABS(sls_price)
else sls_sales
end as sls_sales, 
sls_quantity,
case
when sls_price is null or sls_price <= 0 then sls_sales / nullif(sls_quantity,0)
else sls_price 
END AS sls_price
FROM bronze.crm_sales_details
select * from silver.crm_sales_details


-- Insert the cleaned sales fact rows into the silver fact table for reliable downstream analysis.

INSERT into silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
SELECT
sls_ord_num,
REPLACE(sls_prd_key,'-','_') as sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt <= 0 or LEN(sls_order_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE
WHEN sls_ship_dt <= 0 or LEN(sls_ship_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_ship_dt AS VARCHAR ) AS DATE) 
END AS sls_ship_dt,
CASE
when sls_due_dt <= 0 or lEN(sls_due_dt) <> 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
case
when sls_sales IS NULL  OR sls_sales <> sls_quantity * ABS(sls_price) OR sls_sales <= 0 THEN sls_quantity * ABS(sls_price)
else sls_sales
end as sls_sales, 
sls_quantity,
case
when sls_price IS NULL OR sls_price <= 0 then sls_sales / NULLIF(sls_quantity,0)
ELSE sls_price 
END AS sls_price
FROM bronze.crm_sales_details
-- 4. Standardize ERP customer master data for a unified silver customer dimension.

-- Remove ERP-specific prefixes from customer identifiers so they align to the canonical customer key format.
SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12

-- Identify date values that fall outside the accepted business range and must be treated as invalid.
SELECT
bdate
FROM 
bronze.erp_cust_az12
where bdate < '1924-01-01' or bdate > GETDATE()

SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
bdate,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE  bdate
END AS  bdate,
gen
FROM bronze.erp_cust_az12

-- Review source gender values to establish a consistent mapping before loading the dimension.
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

-- Normalize ERP customer identifiers and gender labels while clearing impossible birth dates.
SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE  bdate
END AS  bdate,
CASE
WHEN UPPER(TRIM(GEN))  = 'F' THEN 'Female'
WHEN UPPER(TRIM(GEN))  = 'M' THEN 'Male' 
WHEN UPPER(TRIM(GEN))  = '' THEN 'N/A'
else  gen
end as gen
FROM bronze.erp_cust_az12

-- Load the standardized ERP customer records into the silver layer for analytic joins.

INSERT INTO Silver.erp_cust_az12(cid,bdate,gen)
SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE  bdate
END AS  bdate,
CASE
WHEN UPPER(TRIM(GEN))  = 'F' THEN 'Female'
WHEN UPPER(TRIM(GEN))  = 'M' THEN 'Male' 
WHEN UPPER(TRIM(GEN))  = '' THEN 'N/A'
else  gen
end as gen
FROM bronze.erp_cust_az12

-- 5. Standardize ERP location codes into consistent country names for reporting.
select * from bronze.erp_loc_a101

-- Remove separator characters from customer/location identifiers to create a clean key format.
SELECT 
Replace(cid,'-','') as cid,
cntry
from bronze.erp_loc_a101

-- Review valid country codes and the source variations that need to be mapped to a standard vocabulary.
select
distinct cntry
from bronze.erp_loc_a101

-- Normalize country codes into canonical values and blank/null entries into a business-safe label.
SELECT 
Replace(cid,'-','') as cid,
case
when TRIM(cntry) IN ('US','USA')then 'United States'
when TRIM(cntry) = ''  OR cntry is null then 'n/a'
when TRIM(cntry)= 'DE' then 'Germany'
else TRIM(cntry)
end as cntry
from bronze.erp_loc_a101

-- Insert the standardized ERP location data into the silver country dimension table.

Insert into silver.erp_loc_a101(cid,cntry)
SELECT 
Replace(cid,'-','') as cid,
case
when TRIM(cntry) IN ('US','USA')then 'United States'
when TRIM(cntry) = ''  OR cntry is null then 'n/a'
when TRIM(cntry)= 'DE' then 'Germany'
else TRIM(cntry)
end as cntry
from bronze.erp_loc_a101
 

-- 6. Prepare the ERP product-category master for the silver layer with minimal structure cleanup.
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_giv2

-- Check for accidental leading or trailing spaces in category fields before final publication.
select
* from bronze.erp_px_cat_giv2
where cat <> trim(cat) or subcat <> trim(subcat) or maintenance <> trim(maintenance)

-- Review category values to confirm the raw source codes before persisting them into silver.
select
distinct
cat
from bronze.erp_px_cat_giv2

-- Insert the ERP category reference data into the silver dimension without altering the source semantics.

Insert into silver.erp_px_cat_giv2(id,cat,subcat,maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_giv2


-- CREATE PROCEDURE
-- This stored procedure orchestrates the full silver-layer load process, validating timing and logging each batch step.
go
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
  DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time Datetime;
 SET @batch_start_time = GETDATE()
PRINT'============================================'
PRINT'Loading silver layer'
PRINT'============================================'

-- CRM tables are refreshed first because they represent the most operationally active source data.
PRINT'--------------------------------------------'
PRINT'Loading CRM Tables'
PRINT'--------------------------------------------'

-- Loading silver.crm_cust_info
SET @start_time = GETDATE()
PRINT'>> Truncating Table: silver.crm_cust_info'
TRUNCATE TABLE silver.crm_cust_info

PRINT '>> Inserting Data Into: silver.crm_cust_info'
INSERT INTO silver.crm_cust_info(
  cst_id,
  cst_key,
  cst_firstname,
  cst_lastname,
  cst_material_status,
  cst_gndr,
  cst_create_date)

  SELECT
  cst_id,
  cst_key,
  TRIM(cst_firstname) as cst_firstname,
  TRIM(cst_lastname) as cst_lastname,
  CASE
  WHEN UPPER(TRIM(cst_material_status)) = 'S' THEN 'Single'
  WHEN UPPER(TRIM(cst_material_status)) = 'M' THEN 'Married'
  WHEN cst_material_status is null then 'Unknown'
  end as cst_material_status,
 case
  when UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
  WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
  when cst_gndr is null then 'Unknown'
  end as cst_gndr,
  cst_create_date
  from (select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1;
SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

-- Loading silver.crm_prd_info
SET @start_time = GETDATE()
PRINT'>> Truncating Table: Silver.crm_prd_info' 
TRUNCATE TABLE Silver.crm_prd_info
PRINT '>> Inserting Data Into: silver.crm_prd_info'
INSERT INTO silver.crm_prd_info(prd_id,cat_id,prd_key,prd_nm,prd_cost,prd_line,prd_start_dt,prd_end_dt)
 select 
  prd_id,
  REPLACE(SUBSTRING(prd_key,1,5),'-','_') as cat_id,
  REPLACE(SUBSTRING(prd_key,7,LEN(prd_key)),'-','_') as prd_key,
  prd_nm,
  ISNULL(prd_cost,0) as prd_cost,
  CASE
  WHEN UPPER(TRIM(prd_line)) = 'M' then 'Mountains'
  WHEN UPPER(TRIM(prd_line)) = 'R' then 'Road'
  WHEN UPPER(TRIM(prd_line)) = 'S' then 'Other Sales'
  WHEN UPPER(TRIM(prd_line)) = 'T' then 'Touring'
  WHEN prd_line is null then 'Unknown'
  end as prd_line,
  CAST(prd_start_dt AS DATE) AS prd_start_dt,
  CAST(LEAD(prd_start_dt) over (partition by prd_key order by prd_end_dt asc)-1 AS DATE)as prd_end_dt
  from bronze.crm_prd_info;
  PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

---- Loading silver.crm_sales_details
SET @start_time = GETDATE()
  PRINT'>> Truncating Table: Silver.crm_sales_details'
TRUNCATE TABLE silver.crm_sales_details
PRINT '>> Inserting Data Into: silver.crm_sales_details'
INSERT into silver.crm_sales_details(sls_ord_num,sls_prd_key,sls_cust_id,sls_order_dt,sls_ship_dt,sls_due_dt,sls_sales,sls_quantity,sls_price)
SELECT
sls_ord_num,
sls_prd_key,
sls_cust_id,
CASE
WHEN sls_order_dt <= 0 or LEN(sls_order_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE) 
END AS sls_order_dt,
CASE
WHEN sls_ship_dt <= 0 or LEN(sls_ship_dt) <> 8 THEN Null
ELSE CAST(CAST(sls_ship_dt AS VARCHAR ) AS DATE) 
END AS sls_ship_dt,
CASE
when sls_due_dt <= 0 or lEN(sls_due_dt) <> 8 THEN NULL
ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE) END AS sls_due_dt,
case
when sls_sales IS NULL  OR sls_sales <> sls_quantity * ABS(sls_price) OR sls_sales <= 0 THEN sls_quantity * ABS(sls_price)
else sls_sales
end as sls_sales, 
sls_quantity,
case
when sls_price IS NULL OR sls_price <= 0 then sls_sales / NULLIF(sls_quantity,0)
ELSE sls_price 
END AS sls_price
FROM bronze.crm_sales_details;
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'


PRINT'--------------------------------------------'
PRINT'Loading ERP Tables'
PRINT'--------------------------------------------'

-- -- Loading silver.erp_cust_az12
SET @start_time = GETDATE()
PRINT'>> Truncating Table: Silver.erp_cust_az12'
TRUNCATE TABLE Silver.erp_cust_az12
PRINT '>> Inserting Data Into: Silver.erp_cust_az12'
INSERT INTO Silver.erp_cust_az12(cid,bdate,gen)
SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
CASE
WHEN bdate > GETDATE() THEN NULL
ELSE  bdate
END AS  bdate,
CASE
WHEN UPPER(TRIM(GEN))  = 'F' THEN 'Female'
WHEN UPPER(TRIM(GEN))  = 'M' THEN 'Male' 
WHEN UPPER(TRIM(GEN))  = '' THEN 'N/A'
else  gen
end as gen
FROM bronze.erp_cust_az12;
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

-- Loading silver.erp_loc_a101
SET @start_time = GETDATE()
PRINT'>> Truncating Table: silver.erp_loc_a101'
TRUNCATE TABLE silver.erp_loc_a101
PRINT '>> Inserting Data Into: silver.erp_loc_a101'
Insert into silver.erp_loc_a101(cid,cntry)
SELECT 
Replace(cid,'-','') as cid,
case
when TRIM(cntry) IN ('US','USA')then 'United States'
when TRIM(cntry) = ''  OR cntry is null then 'n/a'
when TRIM(cntry)= 'DE' then 'Germany'
else TRIM(cntry)
end as cntry
from bronze.erp_loc_a101;
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

-- Loading silver.erp_px_cat_giv2
SET @start_time = GETDATE()
PRINT'>> Truncating Table: silver.erp_px_cat_giv2'
TRUNCATE TABLE silver.erp_px_cat_giv2
PRINT '>> Inserting Data Into: silver.erp_px_cat_giv2'
Insert into silver.erp_px_cat_giv2(id,cat,subcat,maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_giv2;
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'
SET @batch_end_time = GETDATE();
PRINT'===================================================='
PRINT'Loading Silver Layer is Completed'
PRINT'  - Total Load Duration ' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) as nvarchar) + 'seconds'
PRINT'===================================================='
END

EXEC silver.load_silver



