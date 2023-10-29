# Case Study #1: Danny's Diner
# Pizza Metrics

## 1. How many pizzas were ordered?
### Explanation
The customer_orders table has all the information we need.  Each 
row represents an individual pizza, so we can simply count the number of rows
to find the total number of pizzas ordered.

```SQL
SELECT 
	COUNT(order_id)
FROM 
	customer_orders;
```

## 2. How many unique customer orders were made?
### Explanation
The customer_orders table has all the information we need.  Each 
order_id represents an individual order, so we can simply count the number
of distinct order_ids. 

```SQL
SELECT 
	COUNT(DISTINCT order_id)
FROM 
	customer_orders;
```

## 3. How many successful orders were delivered by each runner?
### Explanation
The runner_orders table has all the information we need. It's
not enough to count the number of order_ids and group by runner_id. This
is because we have two cancellations. That is why we must not count those
orders to get the true total.

```SQL
SELECT 
	runner_id,
	COUNT(order_id)
FROM
	runner_orders
WHERE
	cancellation IS NULL
GROUP BY
	runner_id;
```

## 4. How many of each type of pizza was delivered?
### Explanation
The customer_orders, runner_orders, and pizza_names tables 
have all the information we need. After inner joining the runner_orders 
and pizza_names tables to the customer_orders table, we should filter 
out all the pizzas that were cancelled.  Finally, we should select the 
pizza_name and the total count of all the pizza_names, grouping by the 
pizza_name.

```SQL
SELECT
	pn.pizza_name,
	COUNT(pn.pizza_name) AS num_pizzas_delivered
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
INNER JOIN
	pizza_names AS pn
ON
	co.pizza_id = pn.pizza_id
WHERE
	ro.cancellation IS NULL
GROUP BY
	pn.pizza_name;
```

## 5. How many Vegetarian and Meatlovers were ordered by each customer?
### Explanation
The customer_orders, runner_orders, and pizza_names tables 
have all the information we need. After inner joining the runner_orders 
and pizza_names tables to the customer_orders table, we should filter 
out all the pizzas that were cancelled.  Finally, we should include the
customer_id, the pizza_name, and the total count of all the pizza_names,
grouping by customer_id and pizza_name.

```SQL
SELECT
	co.customer_id,
	pn.pizza_name,
	COUNT(pn.pizza_name) AS num_pizzas_ordered
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
INNER JOIN
	pizza_names AS pn
ON
	co.pizza_id = pn.pizza_id
WHERE
	ro.cancellation IS NULL
GROUP BY
	co.customer_id, pn.pizza_name
ORDER BY
	co.customer_id, pn.pizza_name
```

## 6. What was the maximum number of pizzas delivered in a single order?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need. After inner joining the runner_orders table to the
customer_orders table, we should filter out all the pizzas that were 
cancelled.  We should include the order_id, the total count of order_ids,
and group by order_id to find the total number of pizzas ordered per
order. Finally, we can use this query as a subquery to find the max
number of pizzas delivered in a single order.

```SQL
SELECT 
	MAX(orders.num_pizzas_ordered) AS max_num_pizzas_ordered
FROM
	(
	SELECT
		co.order_id,
		COUNT(co.order_id) AS num_pizzas_ordered
	FROM
		customer_orders AS co
	INNER JOIN
		runner_orders AS ro
	ON
		co.order_id = ro.order_id
	WHERE
		ro.cancellation IS NULL
	GROUP BY
		co.order_id
	) AS orders;
```

## 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need. After inner joining the runner_orders table to the
customer_orders table, we should filter out all the pizzas that were 
cancelled.  We need to build two case statements. The first one should 
create a one when the number of exclusions and extras is null, as this
will count a pizza without changes. To count a pizza with changes, 
we should create a one when the exclusions or the extras are not null.
Finally, our answer should include the customer id, the sum of the 
number of pizzas without changes, and the sum of the number of pizzas
with changes.

```SQL
SELECT
	co.customer_id,
	SUM(CASE
		WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1 
		ELSE 0
	END) AS num_pizzas_without_changes,
	SUM(CASE
		WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 
		ELSE 0
	END) AS num_pizzas_with_changes
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY
  customer_id;
```

## 8. How many pizzas were delivered that had both exclusions and extras?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need. After inner joining the runner_orders table to the
customer_orders table, we should filter out all the pizzas that were 
cancelled.  We need to build one case statements. The first statement
should create a one when the number of exclusions and extras is not 
null, which will count as a pizza with both exclusions and changes.
Finally, our answer should include the sum of the number of pizzas 
with both exclusions and extras.

```SQL 
SELECT
	SUM(CASE
        WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1 ELSE 0
	    END) AS num_pizzas_with_both_exclusions_and_extras	
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	ro.cancellation IS NULL;
```

## 9.  What was the total volume of pizzas ordered for each hour of the day? 
## Explanation
The customer_orders and runner_orders tables have all the 
information we need. After inner joining the runner_orders table to the
customer_orders table, we should filter out all the pizzas that were 
cancelled.  Our final answer should include the hour of the day and the
number of pizzas ordered by the hour of the day.

```SQL
SELECT 
	DATE_FORMAT(co.order_time, '%l %p') AS hour_of_the_day,
	COUNT(co.order_id) AS num_pizzas_ordered
FROM 
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY 
	hour_of_the_day
ORDER BY 
	FIELD(hour_of_the_day, '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM', '7 AM', '8 AM', '9 AM', '10 AM', '11 AM', '12 PM', '1 PM', '2 PM', '3 PM', '4 PM', '5 PM', '6 PM', '7 PM', '8 PM', '9 PM', '10 PM', '11 PM');
```	

## 10. What was the volume of orders for each day of the week?
## Explanation
The customer_orders and runner_orders tables have all the 
information we need. After inner joining the runner_orders table to the
customer_orders table, we should filter out all the pizzas that were 
cancelled.  Our final answer should include the day of the week and the
number of pizzas ordered by the day of the week of the day.

```SQL
SELECT 
	DAYNAME(co.order_time) AS day_of_the_week,
	COUNT(co.order_id) AS num_pizzas_ordered
FROM 
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY 
	day_of_the_week
ORDER BY 
	day_of_the_week DESC;
```
