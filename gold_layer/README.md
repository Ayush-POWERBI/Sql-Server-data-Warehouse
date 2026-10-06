# 🥇 Gold Layer | SQL Server Data Warehouse

## 📌 Overview

The Gold Layer is the final layer of the Data Warehouse.

It takes the cleaned and standardized data from the Silver Layer, integrates related data using SQL joins, creates business-ready dimensions, and prepares the data for analytics and reporting.

### Data Flow

Bronze Layer → Silver Layer → Gold Layer → Analytics

---

## 🎯 Project Objective

The main objective of the Gold Layer is to convert Silver Layer data into business-ready datasets that can be easily used for reporting, dashboards, and analytics.

The Gold Layer focuses on:

- Data integration
- Joining related Silver Layer tables
- Creating business-friendly dimensions
- Generating surrogate keys
- Handling missing values
- Standardizing analytical attributes
- Creating SQL Views
- Preparing analytics-ready data

---

## 🏗️ Gold Layer Structure

### dim_customers

Contains standardized customer information such as:

- Customer ID
- Customer Key
- First Name
- Last Name
- Gender
- Marital Status
- Country
- Birth Date
- Create Date

### dim_products

Contains product-related information such as:

- Product Key
- Product Name
- Category
- Subcategory
- Product Line
- Cost
- Start Date
- End Date

### fact_sales

Contains sales-related business information such as:

- Order Number
- Product Key
- Customer ID
- Order Date
- Shipping Date
- Due Date
- Sales
- Quantity
- Price


---

👁️ SQL Views
The Gold Layer uses SQL Views to provide a clean and reusable analytical interface.
Example:
CREATE VIEW gold.dim_customers AS
SELECT ...

Views help separate the analytical layer from the underlying transformation logic and make the final data easier to consume.
🏗️ Gold Layer Architecture
                 ┌────────────────────┐
                 │    Silver Layer    │
                 │ Cleaned & Standard │
                 │      Data          │
                 └─────────┬──────────┘
                           │
                           ▼
                ┌─────────────────────┐
                │     Gold Layer      │
                │                     │
                │ Data Integration    │
                │ Table Joins         │
                │ Business Logic      │
                │ Dimensions          │
                │ SQL Views           │
                └──────────┬──────────┘
                           │
                           ▼
                 ┌────────────────────┐
                 │     Analytics      │
                 │ Dashboards / BI    │
                 │ Reporting          │
                 └────────────────────┘

🛠️ Technologies Used
- Microsoft SQL Server
- T-SQL
- SQL Server Management Tools
- SQL Views
- SQL Joins
- Data Warehouse Architecture

✅ Result
The Gold Layer successfully integrates the cleaned Silver Layer data and converts it into business-friendly analytical structures.
The resulting dimensions and views provide a reliable foundation for:
- Business Intelligence
- Reporting
- Data Analysis
- Dashboards
- KPI Development

```sql
gold.dim_customers
