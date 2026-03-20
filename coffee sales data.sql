CREATE DATABASE monday_coffee;
USE monday_coffee;

#------MONDAY_COFFEE -- DATA_ANALYSIS------#

SELECT * FROM city;
SELECT * FROM customers;
SELECT * FROM products;
SELECT * FROM sales;

#-----Reports and Data Analysis-----#

### Q-1 Coffee consumer count.
### How many people in each city are estimated to consume coffee, given that 25% of the population does?

SELECT 
      city_name, 
      population, 
      ROUND((population * 0.25)/1000000, 2) as coffee_consumer_in_millions, 
      city_rank 
FROM city 
ORDER BY 2 DESC;

### Q-2 Total Revenue from coffee sales.
### What is the total revenue generated from coffe sale across all cities in the last quater of 2023?

SELECT 
	SUM(total) as total_revenue
FROM sales
WHERE 
	EXTRACT(YEAR FROM sale_date) = 2023 
    AND
    EXTRACT(QUARTER FROM sale_date) = 4;
    
### Q-3 Sales count for each product.
### How many units of each coffee product have been sold?

SELECT
    p.product_name,
    COUNT(s.sale_id) as total_orders
FROM products p
LEFT JOIN
sales s
ON s.product_id = p.product_id
GROUP BY 1
ORDER BY 2 DESC;

### Q-4 Average sales amount per city.
### What is the average sales amount per customer in each city?

## city abd total sale 
## no cx in eath these city

SELECT 
	ci.city_name,
    SUM(s.total) as total_revenue,
    COUNT(DISTINCT s.customer_id) as total_cx,
    ROUND(
		SUM(s.total)/
			COUNT(DISTINCT s.customer_id)
		,2) as avg_sale_pr_cx
        
FROM sales as s
JOIN customers as c
ON s.customer_id = c.customer_id
JOIN  city as ci
ON ci.city_id = c.city_id
GROUP BY 1
ORDER BY 2 DESC;

## Q-5 City population and coffee consumer?
## provide a list of city along with their popolation and estimated coffee consumers.alter
## Return city name, Total current cx, Estimated coffee consumers (25%).

WITH city_table as

(
	SELECT 
		city_name,
        ROUND((population * 0.25)/1000000, 2) as coffee_consumers
	FROM city
),
customers_table 
AS 
(
	SELECT
		ci.city_name,
        COUNT(DISTINCT c.customer_id) as unique_cx
	FROM sales as s
    JOIN customers as c 
    ON c.customer_id = s.customer_id
    JOIN city as ci
    ON ci.city_id = c.city_id
    GROUP BY 1 
)
SELECT
	customers_table.city_name, 
    city_table.coffee_consumers as  coffee_consumer_in_millions,
    customers_table.unique_cx
FROM city_table as ct 
JOIN
customers_table 
ON city_table.city_name = customers_table.city_name;

## Q-6 Top Selling Products by City?
## What are the top 3 selling products in each city based on sales volume.

SELECT *
FROM -- table
(
SELECT 
	ci.city_name,
    p.product_name,
    COUNT(s.sale_id) as total_orders,
    DENSE_RANK() OVER(PARTITION BY ci.city_name ORDER BY COUNT(s.sale_id) DESC) as rrank
FROM sales as s
JOIN products as p
ON s.product_id = p.product_id
JOIN customers as c
ON c.customer_id = s.customer_id
JOIN city as ci
ON ci.city_id = c.city_id
GROUP BY 1, 2
) as tl
WHERE rrank <= 3;

## Q-7 Customer Segmentation by City?
## How many unique customer are there in each city who have purchsed coffe products.

SELECT 
    ci.city_name,
    COUNT(DISTINCT c.customer_id) as unique_cx
FROM city as ci
LEFT JOIN
customers as c
ON c.city_id = ci.city_id
JOIN sales as s
ON s.customer_id = c.customer_id
WHERE s.product_id IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
GROUP BY 1;

## Q-8 Average Sale vs Rent
## Find each city and their average sale per customer and avg rent per customer.

WITH city_table
AS
(
	SELECT 
		ci.city_name,
        SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
			SUM(s.total)/
				COUNT(DISTINCT s.customer_id)
			,2) as avg_sale_pr_cx
        
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN  city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT city_name, estimated_rent FROM city)

SELECT 
	cr.city_name, cr.estimated_rent, ct.total_cx, ct.avg_sale_pr_cx,
    ROUND
		(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
    FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 4 DESC;

## Q-9 Monthly Sales Growth.
## Sales growth rate: Calculate the percentage growth (or decline) in sales over diffrent time period (monthly) by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as monthh,
		EXTRACT(YEAR FROM sale_date) as yearr,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			monthh,
			yearr,
			total_sale AS cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name) AS last_month_sale
			FROM monthly_sales
)
SELECT
	city_name,
     monthh,
     yearr,
     cr_month_sale,
     last_month_sale,
     ROUND
		((cr_month_sale - last_month_sale) / last_month_sale * 100, 2) as growth_ratio
FROM growth_ratio
WHERE last_month_sale IS NOT NULL;

## Q-10 Market Potential Analysis
## Identify top 3 city on highest sales, return city name, total sale, total rent, total customer, estimated coffee consumer

 WITH city_table
AS
(
	SELECT 
		ci.city_name,
        SUM(s.total) as total_revenue,
		COUNT(DISTINCT s.customer_id) as total_cx,
		ROUND(
			SUM(s.total)/
				COUNT(DISTINCT s.customer_id)
			,2) as avg_sale_pr_cx
        
	FROM sales as s
	JOIN customers as c
	ON s.customer_id = c.customer_id
	JOIN  city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1
	ORDER BY 2 DESC
),
city_rent
AS
(SELECT city_name,
ROUND((population * 0.25)/ 1000000, 3 ) AS estimated_coffee_consumer_in_millions,
estimated_rent FROM city)

SELECT 
	cr.city_name, total_revenue, 
    cr.estimated_rent AS total_rent, 
    ct.total_cx,
    ct.avg_sale_pr_cx,
    estimated_coffee_consumer_in_millions,
    ROUND
		(cr.estimated_rent/ct.total_cx, 2) as avg_rent_per_cx
    FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC;

#/-
## Recomdation
## City 1: Pune
	## 1. avg rent per cx is very low
    ## 2. highest total revenue
    ## 3. avg sale per cx is also high
    
## City 2: Delhi
	## 1. Highest eastimated coffee consumer which is 7.7M 
    ## 2. Highest total cx which is 68
    ## 3. Avg rent per cx is 330 (under 500)
    
## City 3: Jaipur
	## 1. Highest cx no which is 69
    ## 2. Avg rent per cx is very less 156
	## 3. Ang sale per cx is better which at 11.6k




