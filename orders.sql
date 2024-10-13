SELECT *
FROM orders;

--total number of orders--
SELECT COUNT (order_id)
FROM orders;

--Amount of order received per year--
SELECT COUNT (order_id) AS total_order_per_year,
       EXTRACT(year FROM order_date) AS year
FROM orders
GROUP BY EXTRACT(year FROM order_date)
ORDER BY COUNT (order_id) DESC; 

--sales performance analysis (Determine sales trends and identify top-performing products or customers)
SELECT product_category,
       AVG(order_quantity) AS avg_quantity,
       SUM(sales) AS total_sales
FROM orders
GROUP BY product_category
ORDER BY total_sales DESC;
--Technology had most sales while office supplies had the highest order quantity--

-- Identify products typically bought in larger quantities--
--(e.g product with average order quantity greater than 20).--
SELECT product_category, 
       product_sub_category, 
	   AVG(order_quantity) AS avg_order_quantity
FROM orders
GROUP BY product_category, 
         product_sub_category
HAVING AVG(order_quantity) > 20
ORDER BY avg_order_quantity DESC;
--All product sub category had order quantity above 20 with the top 3 under office supplies(product category)

--Identify which specific sub-categories contribute the most to total sales.--
SELECT product_category, 
       product_sub_category, 
	   SUM(sales) AS total_sales
FROM orders
GROUP BY product_category, 
         product_sub_category
ORDER BY total_sales DESC;

--determine how different product categories perform relative to one another--
SELECT product_category, 
       SUM(sales) AS total_sales,
       COUNT(order_id) AS total_orders,
       AVG(order_quantity) AS avg_order_quantity,
       AVG(discount) AS avg_discount
FROM orders
GROUP BY product_category
ORDER BY total_sales DESC;


SELECT 
    EXTRACT(MONTH FROM order_date) AS month,
    product_category,
    SUM(sales) AS total_sales
FROM orders
GROUP BY month, 
         product_category
ORDER BY month,
         total_sales DESC;

--total sales per year--
SELECT 
    DATE_TRUNC('year', order_date) AS year,
    SUM(sales) AS total_sales
FROM orders
GROUP BY year
ORDER BY SUM(sales) DESC;
--2009 was the year with most sales followed by 2012, 2010 had the lowest sales--

--Customer Purchase Behavior Analysis--
--total number of customers--
SELECT COUNT(DISTINCT customer) AS no_of_customers
FROM orders;
--there are 777 number of customers--

--top 5 customers based on sales--
SELECT customer,
       SUM (sales) AS total_sales
FROM orders
GROUP BY customer
ORDER BY total_sales DESC
LIMIT 5;

--total sales and total orders of each customer--
SELECT customer, 
       COUNT(order_id) AS total_orders, 
	   SUM(sales) AS total_sales
FROM orders
GROUP BY customer
ORDER BY total_sales DESC;

-- Identify customers who has purchased more than once--
SELECT customer, 
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;
--762 customers purchased more than once--

SELECT customer, 
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer
HAVING COUNT(order_id) > 10
ORDER BY total_orders DESC;

--Identifying Customers Who Place Frequent Orders--
SELECT 
    customer, 
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer
HAVING COUNT(order_id) > 15 -- frequent orders = 16 and above
ORDER BY total_orders DESC;
--39 customers placed orders more than 15 times--

-- Identify product sub category with repeat orders--
SELECT product_sub_category, 
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY product_sub_category
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;
--All product sub category had more than one order--

--repeat orders for specific customers and products--
SELECT customer, 
       product_sub_category, 
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY customer, product_sub_category
HAVING COUNT(order_id) > 1
ORDER BY total_orders DESC;

-- Identifying Customers Who Place Large Orders--
SELECT 
    customer, 
    SUM(order_quantity) AS total_order_quantity,
    AVG(order_quantity) AS avg_order_quantity
FROM orders
GROUP BY customer
HAVING SUM(order_quantity) > 500
ORDER BY total_order_quantity DESC;
--14 customers has order quantity above 500--

--Tracking Customer Purchase Frequency Over Time--
--(identify customers who have decreased their purchasing frequency)--
WITH order_counts AS (
    SELECT 
        customer,
        EXTRACT(QUARTER FROM order_date) AS order_quarter,
        EXTRACT(YEAR FROM order_date) AS order_year,
        COUNT(order_id) AS total_orders
    FROM orders
    GROUP BY customer, 
	         EXTRACT(QUARTER FROM order_date), 
	         EXTRACT(YEAR FROM order_date)
)

SELECT 
    current.customer,
    current.total_orders AS current_orders,
    previous.total_orders AS previous_orders,
    (current.total_orders - previous.total_orders) AS order_difference
FROM order_counts AS current
JOIN order_counts AS previous
    ON current.customer = previous.customer
    AND current.order_quarter = previous.order_quarter + 1
    AND current.order_year = previous.order_year
WHERE current.total_orders < previous.total_orders
ORDER BY order_difference ASC;
--230 customers decreased their purchasing frequency--

--Identify customers who have stopped purchasing--	
SELECT customer,
       MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer
HAVING MAX(order_date) < CURRENT_DATE - INTERVAL '6 months'
ORDER BY last_order_date;

SELECT customer,
       MAX(order_date) AS last_order_date
FROM orders
GROUP BY customer
HAVING MAX(order_date) < CURRENT_DATE - INTERVAL '6 months'
AND COUNT(order_id) > 5
ORDER BY last_order_date;

--no of new customers gained per year--
WITH first_order AS (
    SELECT 
        customer, 
        MIN(order_date) AS first_order_date
    FROM orders
    GROUP BY customer
)
SELECT 
    EXTRACT(YEAR FROM first_order_date) AS year, 
    COUNT(DISTINCT customer) AS new_customers
FROM first_order
GROUP BY year
ORDER BY year;

--Detect unusually large orders or discounts that may indicate fraud or special events--
SELECT order_id, 
       customer, 
	   sales, 
	   discount
FROM orders
WHERE 
    sales > (SELECT AVG(sales) + 3 * STDDEV(sales) FROM orders)
ORDER BY sales DESC;

--Discount Effectiveness Analysis--
--Does discount impact sales?--
SELECT product_category, 
       AVG(discount) AS avg_discount, 
	   SUM(sales) AS total_sales
FROM orders
GROUP BY product_category
ORDER BY avg_discount DESC;

--impact of discount across total sales, order quantity and total orders--
SELECT 
    CASE 
        WHEN discount > 0 THEN 'Discount Applied'
        ELSE 'No Discount'
    END AS discount_status,
    COUNT(order_id) AS total_orders,
    SUM(sales) AS total_sales,
    AVG(order_quantity) AS avg_order_quantity,
    AVG(discount) AS avg_discount
FROM orders
GROUP BY discount_status;

--Most Frequent Discounts by Product Category(which product category receives the most discounts).--
SELECT 
    product_category,
    COUNT(CASE WHEN discount > 0 THEN 1 END) AS discount_frequency,
    COUNT(order_id) AS total_orders
FROM orders
GROUP BY product_category
ORDER BY discount_frequency DESC;


--Order Status Analysis--
SELECT order_status, 
       COUNT(order_id) AS order_count
FROM orders
GROUP BY order_status
ORDER BY order_count DESC;

--product categories that experience the most issues in terms of order status (e.g., cancellations)--
SELECT product_category,
       order_status,
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY 
    product_category, 
	order_status
ORDER BY order_status DESC;

--total number of orders for each product category--
SELECT product_category,
       COUNT(order_id) AS total_orders
FROM orders
GROUP BY  product_category
ORDER BY COUNT (order_id) DESC;

-- total number of orders for each product sub category--
SELECT product_category,
       product_sub_category,
       COUNT(order_id) AS total_orders OVER (PARTITION BY )
FROM orders
GROUP BY  product_category,
          product_sub_category
ORDER BY COUNT (order_id) DESC;

--moving average for sales prediction--
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', order_date) AS month,
           SUM(sales) AS total_monthly_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
    ORDER BY month
)
SELECT 
    month,
    SUM(total_monthly_sales) OVER (ORDER BY month ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) / 12 AS moving_avg_sales
FROM monthly_sales;
	







