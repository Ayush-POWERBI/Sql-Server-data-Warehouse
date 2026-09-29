use datawarehouse
select top 1000 * from bronze.crm_cust_info
select top 1000 * from bronze.crm_prd_info
select top 1000 * from bronze.crm_sales_details

select top 1000 * from bronze.erp_cust_az12
select top 1000 * from bronze.erp_loc_a101
select top 1000 * from bronze.erp_px_cat_giv2
--CREATE TABLES
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

-- 1.TRANSFORM CRM_CUST_INFO
---1 CHECK FRO NULL OR DUPLICATE IN PRIMARY KEY
SELECT * FROM bronze.crm_cust_info

select
 cst_id,
 count(*) 
 from bronze.crm_cust_info
 group by cst_id
 having count(*) > 1 or cst_id is null

select * from(
select *,
ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date desc) flag_last
from bronze.crm_cust_info)t
where flag_last = 1

--CHECK FOR UNWANTED SPACE

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

---DATA STANDARDIZATION & CONSISTENCY
Select
distinct(cst_gndr)
from bronze.crm_cust_info

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

-- INSERT INTO silver.crm_cust_info
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

--- prd_info
select * from bronze.crm_prd_info
--check nulls

select prd_id,
count(*)
from 
bronze.crm_prd_info
group by prd_id
having count(*) =  1 or prd_id is null

--prd_key
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

--chek unwanted spaces
select 
prd_nm
from bronze.crm_prd_info
where prd_nm <> trim(prd_nm)

--check for nulls or negative number
 select 
 prd_cost
 from 
 bronze.crm_prd_info
 where prd_cost < 0 or prd_cost is null

 --Replacing NULL WITH 0
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
--DATA STANDARDIZATION
  Select
  distinct(prd_line) from bronze.crm_prd_info

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

--INSERT INTO PRD_TABLE

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

 -- sls_sales_details

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

 --Check for invalid dates
   select
   sls_order_dt
   from bronze.crm_sales_details
   where len(sls_order_dt) <> 8 or sls_order_dt is null 
   or sls_order_dt <= 0

-- Handle nulls or 0 and covert Data-Type into Date


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

--Check consistency between sls_sales,sls_quantity,sls_price
-->> sales = quantity * price
-->> value must be null, zero or negative
  
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


-- Insert into table

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
-- rep_cust_a12


SELECT
CASE
WHEN cid like 'NAS%' Then Substring(cid,4,len(cid))
ELSE cid
END AS cid,
bdate,
gen
FROM bronze.erp_cust_az12

--IDENTIFY OUT-OF-RANGE DATE
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

--Data Standardization & Consistency
SELECT DISTINCT gen
FROM bronze.erp_cust_az12

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

--Insert ino silver layer 

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

-- erp_loc_a101
select * from bronze.erp_loc_a101

--Replace - to nothing

SELECT 
Replace(cid,'-','') as cid,
cntry
from bronze.erp_loc_a101

--Data Standardization & Consistency
select
distinct cntry
from bronze.erp_loc_a101

SELECT 
Replace(cid,'-','') as cid,
case
when TRIM(cntry) IN ('US','USA')then 'United States'
when TRIM(cntry) = ''  OR cntry is null then 'n/a'
when TRIM(cntry)= 'DE' then 'Germany'
else TRIM(cntry)
end as cntry
from bronze.erp_loc_a101

--Insert Data into table

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
 

-- erp_px_cat_giv2
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_giv2

--Check for Unwanted Space
select
* from bronze.erp_px_cat_giv2
where cat <> trim(cat) or subcat <> trim(subcat) or maintenance <> trim(maintenance)

-- Data Standardization & Consistency
select
distinct
cat
from bronze.erp_px_cat_giv2

--insert data into table

Insert into silver.erp_px_cat_giv2(id,cat,subcat,maintenance)
select
id,
cat,
subcat,
maintenance
from bronze.erp_px_cat_giv2


-- CREATE  PROCEDURE
CREATE OR ALTER PROCEDURE silver.load_silver AS 
BEGIN
  DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time Datetime;
 SET @batch_start_time = GETDATE()
PRINT'============================================'
PRINT'Loading silver layer'
PRINT'============================================'

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
PRINT '>> Inserting Data Into: silver.crm_cust_info'
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
END;





