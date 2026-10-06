# 🥈 Silver Layer | SQL Server Data Warehouse

## 📌 Overview

The Silver Layer is the second layer of the Data Warehouse pipeline.

It takes raw data from the Bronze Layer and performs data cleaning, validation, transformation, standardization, and preparation for analytics.

### Data Flow

Bronze Layer → Silver Layer → Gold Layer → Analytics

---

## 🎯 Project Objective

The main objective of this project is to transform raw Bronze Layer data into clean, consistent, and business-ready Silver Layer data.

The process focuses on:

- Data cleaning
- Data validation
- Data standardization
- Duplicate removal
- NULL and invalid value handling
- Data type conversion
- Business rule implementation
- Automated loading using a Stored Procedure

---

## 📂 Source Tables

The Silver Layer processes data from CRM and ERP source tables.

### CRM Tables

- `bronze.crm_cust_info`
- `bronze.crm_prd_info`
- `bronze.crm_sales_details`

### ERP Tables

- `bronze.erp_cust_az12`
- `bronze.erp_loc_a101`
- `bronze.erp_px_cat_giv2`

---

## 🧹 Data Cleaning & Transformation

### Customer Data

- Removes duplicate customer records
- Keeps the latest record using `ROW_NUMBER()`
- Trims unwanted spaces from names
- Standardizes Marital Status
- Standardizes Gender
- Handles NULL values

### Product Data

- Cleans and standardizes product information
- Validates product-related attributes
- Prepares product data for downstream analytics

### Sales Data

- Validates order, shipping, and due dates
- Converts valid date values into proper DATE format
- Handles invalid date values
- Validates sales amount
- Calculates corrected sales values when required
- Validates and derives product price

### ERP Data

- Cleans customer information
- Standardizes location data
- Handles invalid or missing values
- Loads product category information into the Silver Layer

---

## 🗄️ Silver Layer Tables

The cleaned data is stored in the following tables:

- `silver.crm_cust_info`
- `silver.crm_prd_info`
- `silver.crm_sales_details`
- `silver.erp_cust_az12`
- `silver.erp_loc_a101`
- `silver.erp_px_cat_giv2`

---

## ⚙️ Stored Procedure

A centralized Stored Procedure is created to automate the complete Silver Layer loading process.

```sql
silver.load_silver

It performs the following steps:
1. Starts the Silver Layer load process
2. Truncates existing Silver Layer data
3. Loads cleaned CRM data
4. Loads cleaned ERP data
5. Displays rows affected
6. Tracks execution time for each table
7. Displays total load duration
8. Confirms successful completion
Execute the Silver Layer Load


📊 Load Result
The Stored Procedure successfully loads data into the Silver Layer.
Example execution results:
- Customer records loaded
- Product records loaded
- Sales records loaded
- ERP customer records loaded
- ERP location records loaded
- ERP category records loaded
The procedure also displays the execution duration for each loading step and the total execution time.

🏗️ Architecture
                ┌─────────────────┐
                │   Bronze Layer  │
                │   Raw Data      │
                └────────┬────────┘
                         │
                         ▼
              ┌─────────────────────┐
              │    Silver Layer     │
              │                     │
              │ Cleaning            │
              │ Validation          │
              │ Transformation      │
              │ Standardization     │
              └──────────┬──────────┘
                         │
                         ▼
                ┌─────────────────┐
                │    Gold Layer   │
                │ Analytics Ready │
                └─────────────────┘

🛠️ Technologies Used
- Microsoft SQL Server
- T-SQL
- SQL Server Management Tools
- Data Warehouse Architecture

✅ Conclusion
The Silver Layer successfully transforms raw Bronze Layer data into clean, validated, standardized, and analytics-ready data.
The automated Stored Procedure makes the complete Silver Layer loading process easier to execute, monitor, and maintain.


