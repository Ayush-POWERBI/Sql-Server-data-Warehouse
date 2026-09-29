use DataWarehouse

select * from silver.crm_cust_info
select * from silver.erp_cust_az12
select * from silver.erp_loc_a101

- Join tables 
SELECT
  ci.cst_id,
  ci.cst_key,
  ci.cst_firstname,
  ci.cst_lastname,
  ci.cst_material_status,
  ci.cst_gndr,
  ci.cst_create_date,
  ca.bdate,
  ca.gen,
  la.cntry
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid

--Data Integration

SELECT Distinct
  ci.cst_gndr, 
  ca.gen
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid
   order by 1,2

-- solve nulls and missing data

 SELECT Distinct
  CASE
  WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
  else coalesce(ca.gen,'n/a')
  end as new_gen
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid
  
  SELECT
  ci.cst_id,
  ci.cst_key,
  ci.cst_firstname,
  ci.cst_lastname,
  ci.cst_material_status,
    CASE
  WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
  else coalesce(ca.gen,'n/a')
  end as new_gen,
  ci.cst_create_date,
  ca.bdate,
  la.cntry
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid
   

  -- Rename columns
  SELECT
  ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
  ci.cst_id customer_id,
  ci.cst_key customer_number,
  ci.cst_firstname first_name,
  ci.cst_lastname last_name,
  la.cntry country,
  ci.cst_material_status marital_status ,
    CASE
  WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
  else coalesce(ca.gen,'n/a')
  end as gender,
  ca.bdate  birth_date,
  ci.cst_create_date create_date
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid

-- create view

create view gold.dim_customers as 
 SELECT
  ROW_NUMBER() OVER (ORDER BY cst_id) as customer_key,
  ci.cst_id customer_id,
  ci.cst_key customer_number,
  ci.cst_firstname first_name,
  ci.cst_lastname last_name,
  la.cntry country,
  ci.cst_material_status marital_status ,
    CASE
  WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
  else coalesce(ca.gen,'n/a')
  end as gender,
  ca.bdate  birth_date,
  ci.cst_create_date create_date
  from silver.crm_cust_info ci
   LEFT JOIN 
   silver.erp_cust_az12 ca
   on ci.cst_key = ca.cid
   LEFT JOIN
   silver.erp_loc_a101 la
   on ci.cst_key = la.cid

--- CREATE 2ND DIMENSION
select  * from silver.crm_prd_info
select * from silver.erp_px_cat_giv2

-- join tables
select prd_key,count(*) from(
SELECT 
p.prd_id,
p.cat_id,
p.prd_key,
p.prd_nm,
p.prd_cost,
prd_line,
p.prd_start_dt,
p.prd_end_dt,
pr.cat,
pr.subcat,
pr.maintenance
from silver.crm_prd_info p
left join
silver.erp_px_cat_giv2 pr
on p.cat_id = pr.id
where p.prd_end_dt is null--- Filter out  all historical data
)t group by prd_key
having count(*) > 1 -- check duplicates

-- Reaarange columns & rename columns


SELECT 
ROW_NUMBER() OVER (ORDER BY P.prd_start_dt,p.prd_key) AS product_key, -- add surrogate key
p.prd_id product_id,
p.prd_key product_number,
p.prd_nm product_name,
p.cat_id category_id,
pr.cat category,
pr.subcat sub_category,
pr.maintenance maintenance,
p.prd_cost cost,
prd_line product_line,
p.prd_start_dt start_date
from silver.crm_prd_info p
left join
silver.erp_px_cat_giv2 pr
on p.cat_id = pr.id
where p.prd_end_dt is null--- Filter out  all historical data


--- create view
create view gold.dim_products as 
SELECT 
ROW_NUMBER() OVER (ORDER BY P.prd_start_dt,p.prd_key) AS product_key, -- add surrogate key
p.prd_id product_id,
p.prd_key product_number,
p.prd_nm product_name,
p.cat_id category_id,
pr.cat category,
pr.subcat sub_category,
pr.maintenance maintenance,
p.prd_cost cost,
prd_line product_line,
p.prd_start_dt start_date
from silver.crm_prd_info p
left join
silver.erp_px_cat_giv2 pr
on p.cat_id = pr.id
where p.prd_end_dt is null--- Filter out  all historical data


-- create fact table

select * from silver.crm_sales_details
select * from gold.fact_salES

select
 s.sls_ord_num,
 dp.product_key,
 dc.customer_key,
 s.sls_order_dt,
 s.sls_ship_dt,
 s.sls_due_dt,
 s.sls_sales,
 s.sls_quantity,
 s.sls_price
 from silver.crm_sales_details s
 LEFT JOIN
 gold.dim_products dp
 on s.sls_prd_key = dp.product_number
 LEFT JOIN
 gold.dim_customers dc
 on dc.customer_id = s.sls_cust_id

 select * from gold.dim_customers

 --- rename and reaarange columns

create view gold.fact_sales as 
select
 s.sls_ord_num order_number,
 dp.product_key,
 dc.customer_key,
 s.sls_order_dt order_date,
 s.sls_ship_dt ship_date,
 s.sls_due_dt due_date,
 s.sls_sales sales,
 s.sls_quantity quantity,
 s.sls_price price 
 from silver.crm_sales_details s
 LEFT JOIN
 gold.dim_products dp
 on s.sls_prd_key = dp.product_number
 LEFT JOIN
 gold.dim_customers dc
 on dc.customer_id = s.sls_cust_id
