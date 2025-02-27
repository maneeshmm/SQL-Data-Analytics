USE master;
GO

-- Drop and recreate the 'DataWarehouseAnalytics' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouseAnalytics')
BEGIN
    ALTER DATABASE DataWarehouseAnalytics SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouseAnalytics;
END;
GO

-- Create the 'DataWarehouseAnalytics' database
CREATE DATABASE DataWarehouseAnalytics;
GO

USE DataWarehouseAnalytics;
GO

-- Create Schemas

CREATE SCHEMA gold;
GO

CREATE TABLE gold.dim_customers(
	customer_key int,
	customer_id int,
	customer_number nvarchar(50),
	first_name nvarchar(50),
	last_name nvarchar(50),
	country nvarchar(50),
	marital_status nvarchar(50),
	gender nvarchar(50),
	birthdate date,
	create_date date
);
GO

CREATE TABLE gold.dim_products(
	product_key int ,
	product_id int ,
	product_number nvarchar(50) ,
	product_name nvarchar(50) ,
	category_id nvarchar(50) ,
	category nvarchar(50) ,
	subcategory nvarchar(50) ,
	maintenance nvarchar(50) ,
	cost int,
	product_line nvarchar(50),
	start_date date 
);
GO

CREATE TABLE gold.fact_sales(
	order_number nvarchar(50),
	product_key int,
	customer_key int,
	order_date date,
	shipping_date date,
	due_date date,
	sales_amount int,
	quantity tinyint,
	price int 
);
GO

TRUNCATE TABLE gold.dim_customers;
GO

BULK INSERT gold.dim_customers
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL16.SPARTA\MSSQL\DATA\gold.dim_customers.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.dim_products;
GO

BULK INSERT gold.dim_products
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL16.SPARTA\MSSQL\DATA\gold.dim_products.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

TRUNCATE TABLE gold.fact_sales;
GO

BULK INSERT gold.fact_sales
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL16.SPARTA\MSSQL\DATA\gold.fact_sales.csv'
WITH (
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	TABLOCK
);
GO

SELECT * FROM gold.dim_customers
SELECT * FROM gold.dim_products
SELECT * FROM gold.fact_sales

--Changes over time analysis

SELECT YEAR(order_date) AS order_year , 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  YEAR(order_date)
ORDER BY  YEAR(order_date)

SELECT MONTH(order_date) AS order_month , 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  MONTH(order_date)
ORDER BY  MONTH(order_date)

SELECT YEAR(order_date) AS order_year , 
MONTH(order_date) AS order_month,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  YEAR(order_date), MONTH(order_date) 
ORDER BY  YEAR(order_date), MONTH(order_date) 


SELECT DATETRUNC(YEAR,order_date) AS order_year , 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(YEAR,order_date)
ORDER BY  DATETRUNC(YEAR,order_date)

SELECT DATETRUNC(MONTH,order_date) AS order_year , 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(MONTH,order_date)
ORDER BY  DATETRUNC(MONTH,order_date)

SELECT FORMAT(order_date,'yyyy-MMM') AS order_year , 
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_quantity 
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  FORMAT(order_date,'yyyy-MMM')
ORDER BY FORMAT(order_date,'yyyy-MMM')

--Cumulative Analysis
/* Calculate the total sales per month 
and the running total of sales over time*/

SELECT order_date, total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales
FROM(

SELECT DATETRUNC(MONTH,order_date) AS order_date , 
SUM(sales_amount) AS total_sales
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(MONTH,order_date)
) AS sales_summary 
ORDER BY order_date

SELECT order_date, total_sales,
SUM(total_sales) OVER(PARTITION BY order_date ORDER BY order_date) AS running_total_sales
FROM(

SELECT DATETRUNC(MONTH,order_date) AS order_date , 
SUM(sales_amount) AS total_sales
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(MONTH,order_date)
) AS sales_summary 
ORDER BY order_date


SELECT order_date, total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales
FROM(

SELECT DATETRUNC(YEAR,order_date) AS order_date , 
SUM(sales_amount) AS total_sales
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(YEAR,order_date)
) AS sales_summary 
ORDER BY order_date


SELECT order_date, total_sales,
SUM(total_sales) OVER(ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER(ORDER BY order_date) AS moving_avg_price

FROM(

SELECT DATETRUNC(YEAR,order_date) AS order_date , 
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales 
WHERE order_date IS NOT NULL 
GROUP BY  DATETRUNC(YEAR,order_date)
) AS sales_summary 
ORDER BY order_date

--Performance Analysis
/* Analyze the yearly performance of products 
by comparing each product's sales 
to both its average sales performance and the previous year's sales.*/

WITH yearly_product_sales AS(
SELECT YEAR(f.order_date) AS order_year,
p.product_name,
SUM(f.sales_amount) AS current_sales
FROM
gold.fact_sales AS f LEFT JOIN gold.dim_products AS p 
ON f.product_key = p.product_key
WHERE f.order_date IS NOT NULL
GROUP BY YEAR(f.order_date),p.product_name
)

SELECT order_year, product_name, current_sales,
AVG(current_sales) OVER(PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales) OVER(PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) > 0 THEN 'Above Avg'
WHEN current_sales - AVG(current_sales) OVER(PARTITION BY product_name) < 0 THEN 'Below Avg'
ELSE 'Avg' 
END AS avg_change,
LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
WHEN current_sales - LAG(current_sales) OVER(PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
ELSE 'No change'
END AS py_change

FROM yearly_product_sales
ORDER BY  order_year, product_name

-- Part to whole analysis
/* Which categories contribute the most to overall sales*/

WITH category_sales AS(
SELECT category, SUM(sales_amount) AS total_sales FROM gold.fact_sales AS f LEFT JOIN gold.dim_products AS p ON p.product_id = f.product_key
WHERE category IS NOT NULL GROUP BY category)

SELECT category, total_sales,
SUM(total_sales) OVER() AS overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER())*100,2),'%') AS pertcentage_of_total
FROM category_sales
ORDER BY total_sales DESC

-- Data Segmentation
/* Segment products into cost ranges and 
count how many products fall into each segment*/

WITH product_segments AS (
SELECT product_key, product_name,cost, 
CASE WHEN cost < 100 THEN 'Below 100'
WHEN cost BETWEEN 100 AND 500 THEN '100-500'
WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
ELSE 'Above 1000'
END AS cost_range
FROM gold.dim_products)

SELECT cost_range, COUNT(product_key) AS total_products
FROM product_segments GROUP BY cost_range
ORDER BY total_products DESC

/* Group customers into three segments 
based on their spending behavior.*/


WITH customer_spending AS (
SELECT c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM gold.fact_sales AS f LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
GROUP BY c.customer_key )

SELECT customer_segment, COUNT(customer_key) AS total_customer FROM (
SELECT customer_key,
CASE WHEN lifespan >= 12 AND total_spending > 5000 THEN 'VIP'
WHEN lifespan >= 12 AND total_spending <= 5000 THEN 'Regular'
ELSE 'New'
END AS customer_segment
FROM customer_spending) AS segment_data
GROUP BY customer_segment
ORDER BY total_customer DESC

-- Build customer report

CREATE VIEW gold.report_customers AS
WITH base_query AS(
SELECT f.order_number, f.product_key,f.order_date,f.sales_amount,f.quantity,
c.customer_key, c.customer_number, 
CONCAT(c.first_name,' ',c.last_name) AS customer_name, 
DATEDIFF(YEAR, c.birthdate, GETDATE()) AS age
FROM gold.fact_sales AS f LEFT JOIN gold.dim_customers AS c 
ON f.customer_key = c.customer_key
WHERE order_date IS NOT NULL),

customer_aggregation AS (
SELECT customer_key, customer_number, customer_name, age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(MONTH, MIN(order_date), MAX(order_date)) AS lifespan
FROM base_query
GROUP BY customer_key, customer_number, customer_name, age)
SELECT customer_key, customer_number, customer_name, age,
CASE WHEN age < 20 THEN 'under 20'
WHEN age BETWEEN 20 AND 29 THEN '20-29'
WHEN age BETWEEN 30 AND 39 THEN '30-39'
WHEN age BETWEEN 40 AND 49 THEN '40-49'
ELSE '50 and above'
END AS age_group,
total_orders,total_sales, total_quantity, total_products, last_order_date,
DATEDIFF(MONTH, last_order_date,GETDATE()) AS recency,
CASE WHEN lifespan >= 12 AND total_sales > 5000 THEN 'VIP'
WHEN lifespan >= 12 AND total_sales <= 5000 THEN 'Regular'
ELSE 'New'
END AS customer_segment,
total_sales/total_orders AS avg_order_value,
CASE WHEN lifespan = 0 THEN total_sales
ELSE total_sales/lifespan
END AS avg_monthly_spend
FROM customer_aggregation;

SELECT * FROM gold.report_customers