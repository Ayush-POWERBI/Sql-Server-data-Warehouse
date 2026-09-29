use DataWarehouse
IF OBJECT_ID ('bronze.crm_cust_info','U') is not null
  Drop TABLE bronze.crm_cust_info
create table bronze.crm_cust_info(
  cst_id int,
  cst_key nvarchar(50),
  cst_firstname nvarchar(50),
  cst_lastname nvarchar(50),
  cst_material_status nvarchar(50),
  cst_gndr nvarchar(50),
  cst_create_date Date
  );

IF OBJECT_ID ('bronze.crm_prd_info','U') is not null
  Drop TABLE bronze.crm_prd_info
Create table bronze.crm_prd_info(
  prd_id int,
  prd_key nvarchar(50),
  prd_nm nvarchar(50),
  prd_cost int,
  prd_line nvarchar(50),
  prd_start_dt datetime,
  prd_end_dt datetime
);

IF OBJECT_ID ('bronze.crm_sales_details','U') is not null
  Drop TABLE bronze.crm_sales_details
create table bronze.crm_sales_details(
  sls_ord_num nvarchar(50),
  sls_prd_key nvarchar(50),
  sls_cust_id int,
  sls_order_dt int,
  sls_ship_dt int,
  sls_due_dt int,
  sls_sales int,
  sls_quantity int,
  sls_price int
);

IF OBJECT_ID ('bronze.erp_loc_a101','U') is not null
  Drop TABLE bronze.erp_loc_a101
create table bronze.erp_loc_a101(
  cid nvarchar(50),
  cntry nvarchar(50)
);

IF OBJECT_ID ('bronze.erp_cust_az12','U') is not null
  Drop TABLE bronze.erp_cust_az12
create table bronze.erp_cust_az12(
  cid nvarchar(50),
  bdate date,
  gen nvarchar(50)
);

IF OBJECT_ID ('bronze.erp_px_cat_giv2','U') is not null
  Drop TABLE bronze.erp_px_cat_giv2
create table bronze.erp_px_cat_giv2(
  id nvarchar(50),
  cat nvarchar(50),
  subcat nvarchar(50),
  maintenance nvarchar(50)
);

--insert data into tables
GO
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
  DECLARE @start_time DATETIME , @end_time DATETIME , @batch_start_time DATETIME , @batch_end_time Datetime;
 SET @batch_start_time = GETDATE()
PRINT'============================================'
PRINT'Loading bronze layer'
PRINT'============================================'

PRINT'--------------------------------------------'
PRINT'Loading CRM Tables'
PRINT'--------------------------------------------'
set @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.crm_cust_info'
TRUNCATE TABLE bronze.crm_cust_info;

PRINT '>> Inserting Table:bronze.crm_cust_info'
BULK INSERT bronze.crm_cust_info
from 'C:\Users\Ayush_PC\Desktop\bronze_data\cust_info.csv'
with(
FIRSTROW = 2,
FIELDTERMINATOR= ',',
TABLOCK
);
SET @end_time = GETDATE();
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.crm_prd_info'
TRUNCATE TABLE bronze.crm_prd_info;

PRINT '>> Inserting Table:bronze.crm_prd_info'
BULK INSERT bronze.crm_prd_info
from 'C:\Users\Ayush_PC\Desktop\bronze_data\prd_info.csv'
with(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);
SET @end_time = GETDATE()
PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar)+ 'seconds'
PRINT'---------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.crm_sales_details'
TRUNCATE TABLE bronze.crm_sales_details;

PRINT '>> Inserting Table:bronze.crm_sales_details'
BULK INSERT bronze.crm_sales_details
from 'C:\Users\Ayush_PC\Desktop\bronze_data\sales_details.csv'
with(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);
SET @end_time = GETDATE()
PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar)+ 'seconds'
PRINT'---------------------------'

PRINT'--------------------------------------------'
PRINT'Loading ERP Tables'
PRINT'--------------------------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.erp_cust_az12'
TRUNCATE TABLE bronze.erp_cust_az12

PRINT '>> Inserting Table:bronze.erp_cust_az12_'
BULK INSERT bronze.erp_cust_az12
FROM 'C:\Users\Ayush_PC\Desktop\bronze_data\cust_az12.csv'
with(
FIRSTROW = 2,
FIELDTERMINATOR =',',
TABLOCK
);
SET @end_time = GETDATE()
PRINT'>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'

SET @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.erp_loc_a101'
TRUNCATE TABLE bronze.erp_loc_a101

PRINT '>> Inserting Table:bronze.erp_loc_a101'
BULK INSERT bronze.erp_loc_a101
FROM 'C:\Users\Ayush_PC\Desktop\bronze_data\LOC_A101.csv'
with(
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);
SET @end_time = GETDATE()
PRINT '>> Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar)+ 'seconds'
PRINT'---------------------------'

set @start_time = GETDATE()
PRINT '>> Truncating Table: bronze.erp_px_cat_giv2'
TRUNCATE TABLE bronze.erp_px_cat_giv2

PRINT '>> Inserting Table:bronze.erp_px_cat_giv2'
BULK INSERT bronze.erp_px_cat_giv2
FROM 'C:\Users\Ayush_PC\Desktop\bronze_data\PX_CAT_G1V2.csv'
WITH (
FIRSTROW = 2,
FIELDTERMINATOR = ',',
TABLOCK
);
SET @end_time = GETDATE()
PRINT'Load Duration: ' + CAST(DATEDIFF(second,@start_time,@end_time) as nvarchar) + 'seconds'
PRINT'---------------------------'
SET @batch_end_time = GETDATE();
PRINT'===================================================='
PRINT'Loading Bronze Layer is Completed'
PRINT'  - Total Load Duration ' + CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) as nvarchar) + 'seconds'
PRINT'===================================================='
END;

Exec bronze.load_bronze



