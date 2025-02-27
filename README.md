# SQL - Data Analyst Project

## Overview

This project analyzes sales data using SQL to extract key insights on customer behavior, product sales, and revenue trends. The dataset is structured in a star schema with fact and dimension tables.

## Data Sources

gold.fact_sales.csv - Contains transaction-level sales data.

gold.dim_products.csv - Contains product-related details.

gold.dim_customers.csv - Contains customer demographics.

Database Schema

The project uses a star schema:

Fact Table:

gold.fact_sales (Order transactions)

Dimension Tables:

gold.dim_customers (Customer details)

gold.dim_products (Product details)

## Key SQL Queries

### 1. Sales Analysis

Aggregating yearly sales using SUM() OVER().

Comparing sales with previous years using LAG().

Identifying top-selling products.

### 2. Customer Segmentation

Categorizing customers as VIP, Regular, or New using CASE.

Calculating customer lifespan based on first and last orders.

### 3. Product Performance

Ranking products by revenue.

Analyzing sales trends over time.

## Technologies Used

SQL Server

Window functions (SUM() OVER(), AVG() OVER(), LAG(), PARTITION BY)

Common Table Expressions (WITH)

## How to Use

Load the datasets into your SQL database.

Run the provided SQL scripts to create tables and insert data.

Execute analysis queries to generate insights.

## Future Improvements

Implement advanced analytics using Python and Power BI.

Optimize queries for better performance.

Expand customer segmentation with machine learning.
