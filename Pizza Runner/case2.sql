CREATE DATABASE pizza_runner;

USE pizza_runner;

CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);

INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');

CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');
  
  CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');
  
  CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');
  
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');
  
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');

SET SQL_SAFE_UPDATES=1;

-- How many pizza were ordered?
SELECT 
	COUNT(order_id) AS total_order
FROM 
	customer_orders;
    
-- How many unique customer orders were made?
SELECT 
	customer_id,
    dense_rank() OVER (ORDER BY customer_id) AS unique_customer,
    (SELECT COUNT(DISTINCT customer_id) FROM customer_orders) AS total_customer
FROM customer_orders
GROUP BY customer_id;

-- How many succesful orders were delivered by each runner?
SELECT 
	runner_id, 
    order_success 
FROM (
		SELECT 
			runner_id, 
            COUNT(runner_id) OVER (PARTITION BY runner_id) AS order_success
		FROM 
			runner_orders 
		WHERE 
			pickup_time NOT LIKE ''
	) AS tabel_1  
GROUP BY 
	order_success;
    
-- How many of each type of pizza was delivered? 
SELECT 
	t3.pizza_id,
    t4.pizza_name,
    t3.total_pizza_delivered_order
FROM(
	SELECT 
		t1.customer_id, t1.pizza_id, t2.pickup_time, t2.distance, t2.duration,
		COUNT(pizza_id) OVER (PARTITION BY pizza_id) AS total_pizza_delivered_order
	FROM 
		customer_orders t1 JOIN runner_orders t2 ON t1.order_id = t2.order_id
	WHERE t2.pickup_time NOT LIKE ''
    ) AS t3 JOIN pizza_names t4 ON t3.pizza_id = t4.pizza_id
GROUP BY pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
	t1.customer_id,
    t1.pizza_id,
    t2.pizza_name,
    COUNT(t2.pizza_name) as total_pizza_ordered
 FROM customer_orders t1 JOIN pizza_names t2 ON t1.pizza_id = t2.pizza_id
GROUP BY customer_id, pizza_id, pizza_name
ORDER BY customer_id ASC;

-- What was maximum number of pizzas delivered in a single order?
SELECT 
	*,
    COUNT(order_id) OVER (PARTITION BY order_time) AS maximum_number_of_pizzas_delivered
FROM customer_orders WHERE order_id IN (SELECT order_id FROM runner_orders WHERE cancellation='')
ORDER BY maximum_number_of_pizzas_delivered DESC LIMIT 1;


-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT
	customer_id,
	SUM(CASE WHEN (exclusions > 0 OR extras > 0) THEN 1 ELSE 0 END) as changes,
	SUM(CASE WHEN (exclusions = 0 AND extras = 0) THEN 1 ELSE 0 END) as no_changes
FROM 
	customer_orders
GROUP BY customer_id
ORDER BY customer_id;


-- How many pizzas were delivered that had both exclusions and extras?
SELECT 
	COUNT(*) AS pizza_count 
FROM customer_orders 
WHERE order_id IN 
	(SELECT order_id FROM runner_orders WHERE cancellation='') 
    AND exclusions > 1 AND extras != 0 ;
 
 
 -- What was the total volume of pizzas ordered for each hour of the day?
 SELECT HOUR(order_time) as hour_of_the_day, count(order_id) as total_pizza,
COUNT(order_id)*100/ SUM(COUNT(*)) OVER()  AS volume FROM 
customer_orders
GROUP BY hour_of_the_day;


-- What was the volume of orders for each day of the week?
SELECT 
	DAYOFWEEK(order_time) AS days, 
    COUNT(order_id) as total_pizza,
	COUNT(order_id)*100/ SUM(COUNT(*)) OVER() AS volume 
FROM 
	customer_orders
GROUP BY days;

