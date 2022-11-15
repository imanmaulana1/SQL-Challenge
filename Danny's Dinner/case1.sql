CREATE DATABASE danny_dinner;

CREATE TABLE sales(
    customer_id varchar(255),
    order_date date,
    product_id int
);

CREATE TABLE members(
    customer_id varchar(255),
    join_date timestamp
);

CREATE TABLE menu(
    product_id int,
    product_name varchar(255),
    price int
);

INSERT INTO sales
VALUES
    ('A', '2021-01-01', '1'),
    ('A', '2021-01-01', '2'),
    ('A', '2021-01-07', '2'),
    ('A', '2021-01-10', '3'),
    ('A', '2021-01-11', '3'),
    ('A', '2021-01-11', '3'),
    ('B', '2021-01-01', '2'),
    ('B', '2021-01-02', '2'),
    ('B', '2021-01-04', '1'),
    ('B', '2021-01-11', '1'),
    ('B', '2021-01-16', '3'),
    ('B', '2021-02-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-01', '3'),
    ('C', '2021-01-07', '3');
 
INSERT INTO members 
VALUES
    ('A', '2021-01-07'),
    ('B', '2021-01-09');

INSERT INTO menu 
VALUES
    ('1', 'sushi', '10'),
    ('2', 'curry', '15'),
    ('3', 'ramen', '12');
  
    
--What is the total amount each customer spent at the restaurant?
SELECT 
    customer_id, 
    COUNT(customer_id) AS "Total_Order" 
FROM sales 
GROUP BY customer_id 
ORDER BY customer_id ASC


--How many days has each customer visited the restaurant?
WITH cte AS(
SELECT 
    customer_id, 
    order_date, 
    COUNT(order_date) AS "Total_Day" 
FROM sales 
GROUP BY 
    customer_id,
    order_date 
ORDER BY customer_id ASC
)
SELECT 
    customer_id, 
    COUNT(order_date) AS "Total_Visit" 
FROM cte 
GROUP BY customer_id


--What was the first item from the menu purchased by each customer?
SELECT 
    sales.customer_id, 
    menu.product_name
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
WHERE 
    order_date = (SELECT MIN(order_date) FROM sales)
GROUP BY 
    sales.customer_id, 
    menu.product_name                 
ORDER BY sales.customer_id ASC


--What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH cte AS(
SELECT 
    sales.customer_id, 
    menu.product_name AS "menu", 
    COUNT(menu.product_name) AS "total_order"
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id 
GROUP BY menu.product_name, sales.customer_id
ORDER BY sales.customer_id ASC
)
SELECT 
    menu, 
    SUM(total_order) AS "total_purchased" 
FROM cte 
GROUP BY menu


--Which item was the most popular for each customer?
SELECT 
    sales.customer_id AS customer_id, 
    menu.product_name AS "menu", 
    COUNT(menu.product_name) AS "total_order"
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
GROUP BY menu.product_name, sales.customer_id
ORDER BY customer_id ASC


--Which item was purchased first by the customer after they became a member?
SELECT
    members.customer_id AS customer_id, 
    menu.product_name AS menu, 
    members.join_date,
    sales.order_date 
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE 
    order_date > '2021-01-07'  AND  members.customer_id = 'A'
ORDER BY order_date ASC
LIMIT 1

SELECT
    members.customer_id AS customer_id, 
    menu.product_name AS menu, 
    members.join_date,
    sales.order_date 
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE 
    order_date > '2021-01-09'  AND  members.customer_id = 'B'
ORDER BY order_date ASC
LIMIT 1


--Which item was purchased just before the customer became a member?
SELECT
    members.customer_id AS customer_id, 
    menu.product_name AS menu, 
    members.join_date,
    sales.order_date 
FROM sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE 
    sales.order_date < '2021-01-07' 
ORDER BY members.customer_id


--What is the total items and amount spent for each member before they became a member?
SELECT
    members.customer_id AS customer_id,
    COUNT(menu.product_name) AS total_items,
    SUM(menu.price) AS total_price_$
FROM 
    sales
INNER JOIN menu ON sales.product_id = menu.product_id
INNER JOIN members ON sales.customer_id = members.customer_id
WHERE 
    sales.order_date < '2021-01-07' 
GROUP BY members.customer_id
ORDER BY members.customer_id


-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH point AS(
	SELECT 
		sales.customer_id, 
		menu.product_name, 
		menu.price,
		CASE
			WHEN menu.product_name = 'sushi' THEN (price*20)
			ELSE (price*10)
		END AS point
	FROM 
		sales 
	INNER JOIN menu ON sales.product_id=menu.product_id )
SELECT 
	customer_id,
	SUM(point) AS point
FROM 
	point
GROUP BY customer_id
ORDER BY customer_id


-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH point_member AS (
	SELECT 
		sales.customer_id, 
		sales.order_date,
		menu.product_name, 
		menu.price,
		CASE
			WHEN members.customer_id = 'A' AND sales.order_date >= '2021-01-07' THEN (price*20)
			WHEN members.customer_id = 'A' AND sales.order_date < '2021-01-07' THEN (price*10)
			WHEN members.customer_id = 'B' AND sales.order_date >= '2021-01-11' THEN (price*20)
			WHEN members.customer_id = 'B' AND sales.order_date < '2021-01-11' THEN (price*10)
		END AS point
	FROM 
		sales 
	INNER JOIN menu ON sales.product_id=menu.product_id
	INNER JOIN members ON sales.customer_id=members.customer_id)
SELECT 
	customer_id,
	SUM(point) AS point_member
FROM point_member
GROUP BY customer_id