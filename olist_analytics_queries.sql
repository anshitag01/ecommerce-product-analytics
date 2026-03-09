show tables;

CREATE TABLE analytics_orders AS
SELECT
o.order_id,
c.customer_unique_id,
o.order_purchase_timestamp,
o.order_delivered_customer_date,
r.review_score
FROM olist_orders_dataset o
JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
LEFT JOIN olist_order_reviews_dataset r ON o.order_id = r.order_id;

-- Total users
SELECT COUNT(DISTINCT customer_unique_id) AS total_users
FROM analytics_orders;

-- Total orders
SELECT COUNT(order_id) AS total_orders
FROM analytics_orders;

-- One time buyers
SELECT COUNT(*)
FROM(
SELECT customer_unique_id, COUNT(order_id) AS orders_count
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
HAVING COUNT(order_id) = 1
) t;

-- One time v/s repeat customers
SELECT
CASE
WHEN order_count = 1 THEN 'One-time buyers'
ELSE 'Repeat buyers'
END AS customer_type,
COUNT(*) AS customers
FROM(
SELECT customer_unique_id, COUNT(order_id) AS order_count
FROM analytics_orders
GROUP BY customer_unique_id
) t
GROUP BY customer_type;

-- Retention rate
SELECT ROUND(COUNT(DISTINCT CASE WHEN order_count > 1 THEN customer_unique_id END)/COUNT(DISTINCT customer_unique_id) * 100,2) AS retention_rate
FROM(
SELECT customer_unique_id, COUNT(order_id) AS order_count
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
ON o.customer_id = c.customer_id
GROUP BY customer_unique_id
) t;

-- Orders by month
SELECT
DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS order_month,
COUNT(DISTINCT customer_unique_id) AS active_users
FROM analytics_orders
GROUP BY order_month
ORDER BY order_month;

-- Delivery time vs satisfaction
SELECT
review_score,
AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)) AS avg_delivery_days
FROM analytics_orders
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score desc;

-- Repeat purchase behavior vs review score
SELECT
review_score,
COUNT(DISTINCT customer_unique_id) AS customers
FROM analytics_orders
WHERE review_score IS NOT NULL
GROUP BY review_score
ORDER BY review_score desc;

-- Funnel analysis
SELECT 'Total Users' AS stage,
COUNT(DISTINCT customer_unique_id) AS value
FROM analytics_orders

UNION

SELECT 'Customers Who Ordered',
COUNT(DISTINCT customer_unique_id)
FROM analytics_orders

UNION

SELECT 'Repeat Customers',
COUNT(DISTINCT customer_unique_id)
FROM (
SELECT customer_unique_id
FROM analytics_orders
GROUP BY customer_unique_id
HAVING COUNT(order_id) > 1
) t;