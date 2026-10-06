# SQL Server Data Warehouse – Bronze Layer 🥉

## 📌 Overview

This project demonstrates how to build a Bronze Layer in a SQL Server Data Warehouse.

Raw data from CRM and ERP CSV files is loaded into SQL Server using BULK INSERT and Stored Procedures.

## 🏗️ Architecture

CSV Files → BULK INSERT → Bronze Layer → Silver Layer → Gold Layer → Power BI

> Currently, this project focuses on the Bronze Layer.

## 🛠️ Tools & Technologies

- SQL Server
- T-SQL
- SSMS
- VS Code
- CSV Files
- Stored Procedures
- BULK INSERT

## 🗄️ Bronze Tables

### CRM Tables

- bronze.crm_cust_info
- bronze.crm_prd_info
- bronze.crm_sales_details

### ERP Tables

- bronze.erp_cust_az12
- bronze.erp_loc_a101
- bronze.erp_px_cat_giv2

## 🔄 Data Loading Process

The Bronze Layer uses a Full Load process:

TRUNCATE TABLE
       ↓
BULK INSERT
       ↓
Load CSV Data
       ↓
Track Load Duration

Example:

BULK INSERT bronze.crm_cust_info
FROM 'YOUR_PATH\cust_info.csv'
WITH
(
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    TABLOCK
);

## ⚙️ Stored Procedure

The complete Bronze Layer loading process is automated using:

EXEC bronze.load_bronze;

The procedure:

- Truncates existing data
- Loads CRM and ERP CSV files
- Displays rows affected
- Tracks loading time

## 📸 Screenshots

### Table Creation

![Table Creation](screenshots/1.Table_creation.png)

### Stored Procedure & BULK INSERT

![Stored Procedure](screenshots/2.stored_procedure_and_bulk_insert.png)

### Procedure Execution

![Procedure Execution](screenshots/3.procedure_execution.png)

### Execution Output

![Execution Output](screenshots/4.bronze_layer_store_procedure_execution_output.png)

## 📚 What I Learned

- SQL Server Data Warehousing
- Bronze Layer Architecture
- BULK INSERT
- Stored Procedures
- Full Load Processing
- ETL / ELT Concepts
- Load Performance Tracking

## 🚀 Future Improvements

- Silver Layer
- Gold Layer
- Data Cleaning
- Incremental Loading
- Data Quality Checks
- Power BI Dashboard


Aspiring Data Engineer | SQL | Data Warehousing | ETL
