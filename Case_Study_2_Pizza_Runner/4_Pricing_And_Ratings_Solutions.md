# Case Study #2: Pizza Runner - Pricing and Ratings Solutions

## 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes, how much money has Pizza Runner made so far if there are no delivery fees?
### Explanation
The customer_order and runner_orders tables have 
all the information we need. We need to create a new column 
called price that assigns $12 and $10 for Meat Lovers and 
Vegetarian pizzas, respectively.  We can create a CTE that 
includes the order_id, pizza_id, pizza_name, and a CASE 
statement that creates the price column.  We should make
sure to not count the orders that were cancelled.  With our CTE 
completed, we can use the SUM() function to sum the prices of 
all pizzas.

```SQL
WITH pizza_prices_cte AS
	(
	SELECT 
		co.order_id,
		co.pizza_id,
		pn.pizza_name,
		(CASE
			WHEN co.pizza_id = 1 THEN 12
			ELSE 10
		END) AS price
	FROM 
		customer_orders AS co
	LEFT JOIN 
		runner_orders AS r
	ON
		co.order_id = r.order_id
	LEFT JOIN
		pizza_names AS pn
	ON 
		co.pizza_id = pn.pizza_id
	WHERE
		r.cancellation IS NULL
)
SELECT
	SUM(pp.price)
FROM
	pizza_prices_cte AS pp;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/fe9ee394-878f-4869-831b-d98799d94a83)


## 2. What if there was an additional $1 charge for any pizza extras?  Add cheese is $1 extra
### Explanation
The customer_orders, pizza_toppings, and pizza_names 
tables have all the information we need. To make our work easier,
we should create a Temporary Table. First, this table will use the
ROW_NUMBER() and OVER() function to create a row number for each 
row.  This will be our primary key and ensure all data is analyzed.
Then, we will add all of the customer_order table columns, as well 
as separate the values of the exclusions and extras columns. Next,
we will create another temporary table called extras_tt, that 
includes the ROW_NUMBER() OVER() function to create a record 
identifier, as well as the topping_id that identifies the topping
that was added to each pizza.  We can create a CTE that 
includes the order_id, pizza_id, pizza_name, and a CASE 
statement that creates the price column.  We should make
sure to not count the orders that were cancelled.  Next, we will 
count the number of times the row_num from the extras table 
appeared.  We can build an additional CTE of the original CTE 
that creates a new column that adds the pizza price and the
number of times an extra appeared for each record.  With our CTEs 
completed, we can use the SUM() function to sum the prices of 
all pizzas and their extra toppings.

```SQL
-- Create customer_orders tt with row_numbers
CREATE TEMPORARY TABLE IF NOT EXISTS customer_orders_primary_tt AS 
SELECT
	ROW_NUMBER() OVER() AS row_num,
	order_id,
	customer_id,
	pizza_id,
	exclusions,
	CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 1)), ',', -1) AS UNSIGNED) AS exclusion_1,
	CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 2)), ',', -1)) AS UNSIGNED) AS exclusion_2,
	extras,
	CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 1)), ',', -1) AS UNSIGNED) AS extra_1,
	CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 2)), ',', -1)) AS UNSIGNED) AS extra_2,
	order_time
FROM
	customer_orders;

-- Create extras temporary table
CREATE TEMPORARY TABLE IF NOT EXISTS extras_tt AS
WITH extras_cte AS
(
	SELECT
		ROW_NUMBER() OVER() AS row_num,
		order_id,
		customer_id,
		pizza_id,
		exclusions,
		CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 1)), ',', -1) AS UNSIGNED) AS exclusion_1,
		CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(exclusions, ',', 2)), ',', -1)) AS UNSIGNED) AS exclusion_2,
		extras,
		CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 1)), ',', -1) AS UNSIGNED) AS extra_1,
		CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(extras, ',', 2)), ',', -1)) AS UNSIGNED) AS extra_2,
		order_time
	FROM
		customer_orders
)
SELECT
	e.row_num,
	e.extra_1 AS topping_id
FROM
	extras_cte AS e
WHERE
	e.row_num = 8 	AND e.extras IS NOT NULL
UNION
SELECT
	e.row_num,
	e.extra_1
FROM
	extras_cte AS e
WHERE
	e.row_num = 10 AND e.extras IS NOT NULL
UNION
SELECT
	e.row_num,
	e.extra_1
FROM
	extras_cte AS e
WHERE
	e.row_num = 12 AND e.extras IS NOT NULL
UNION
SELECT
	e.row_num,
	e.extra_2
FROM
	extras_cte AS e
WHERE
	e.row_num = 12 AND e.extras IS NOT NULL
UNION
SELECT
	e.row_num,
	e.extra_1
FROM
	extras_cte AS e 
WHERE
	e.row_num = 14 AND e.extras IS NOT NULL
UNION
SELECT
	e.row_num,
	e.extra_2
FROM
	extras_cte AS e
WHERE
	e.row_num = 14 AND e.extras IS NOT NULL;

SELECT *
FROM customer_orders_primary;


-- answer question
WITH pizza_prices_cte AS
	(
	SELECT 
		co1.row_num,
		co1.order_id,
		co1.pizza_id,
		COUNT(exttt.row_num) AS num_extras,
		r.cancellation,
		(CASE
			WHEN co1.pizza_id = 1 THEN 12
			ELSE 10
		END) AS price
	FROM 
		customer_orders_primary_tt AS co1
	LEFT JOIN 
		runner_orders AS r
	ON
		co1.order_id = r.order_id
	LEFT JOIN
		extras_tt AS exttt
	ON 
		co1.row_num = exttt.row_num
	WHERE
		r.cancellation IS NULL
	GROUP BY
		co1.row_num
)
, updated_prices_cte AS
(
	SELECT 
		pp.*,
		pp.num_extras + pp.price AS real_prices
	FROM
		pizza_prices_cte AS pp
	GROUP BY 
		pp.row_num
)
SELECT
	SUM(up.real_prices)
FROM
	updated_prices_cte AS up;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/751e6b6d-beaf-4904-88da-45636d72dffa)


## 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
### Explanation
To review each runner, we would need a rating column,
a review column where customers can write a short review, and an
order identifier.  Because only one runner can deliver an order,
we do not need a runner_id.  The order_id would be a much more 
appropriate identifier.  This way, we can join our new table with 
the runner_orders table to link each order with their respective
runners.  The statements below create this table and add
dummy data. 

```SQL
CREATE TABLE runner_ratings (order_id INTEGER, rating INTEGER, review VARCHAR(50));

INSERT INTO runner_ratings 
VALUES (1, 3, "Delivered to my neighbors' address."),
	   (2, 3, "Poor customer service."),
	   (3, 5, "Excellent service!"),
	   (4, 5, "Good job. Would recommend."),
	   (5, 3, "Delivery was slow."),
	   (7, 1, "Pizza was cold."),
	   (8, 2, "Took too long."),
	   (10, 2, "Pizza was tossed on my doorstep.");
```

## 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
* customer_id
* order_id
* runner_id
* rating
* order_time
* pickup_time
* Time between order and pickup
* Delivery duration
* Average speed
* Total number of pizzas
### Explanation
The customer_orders, runner_orders, and runner_ratings
tables have all the information we need.  After joining the 
tables and using the WHERE clause to filter out the cancelled 
orders, we should group by order_id to get the desired results. 
Finally, we can get the desired columns in the SELECT statement.

### Answer

```SQL
SELECT
	co1.customer_id,
	co1.order_id,
	ro.runner_id,
	rr.rating,
	co1.order_time,
	ro.pickup_time,
	TIMESTAMPDIFF(MINUTE, co1.order_time, ro.pickup_time) AS time_between_pickup,
	ro.duration,
	AVG((ro.distance * 60) / ro.duration) AS avg_speed_km_per_hr,
	COUNT(co1.order_id) AS total_pizzas_ordered
FROM
	customer_orders_primary_tt AS co1
LEFT JOIN
	runner_orders AS ro
ON
	co1.order_id = ro.order_id
LEFT JOIN	
	runner_ratings AS rr
ON
	ro.order_id = rr.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY
	co1.order_id;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/8742a8bc-264e-49a9-a92b-052344c59128)


## 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
### Explanation
The customer_orders and runner_orders tables have 
all the information we need.  We need to create two CTEs to 
prepare the information we need.  Our first CTE, called 
revenues_cte, joins the customer_orders table and the 
runner_orders table, filters out cancelled orders, and
gets the order_id, and the SUM() function to create a column
called rev, that assigns the correct price for each pizza
variety.  Using the SUM() function guarantees that we get
one row, where the order_id is 1 and the rev is the sum of
all the pizzas from uncancelled orders.  

The second CTE, called costs_cte, only uses the runner_orders
table.  This guarantees that the SUM() function only adds
each delivery once.  After filtering out cancelled orders in 
the WHERE clause, we get the order_id and the rounded sum 
based on the distance calculations.  Our CTE produces one row,
with an order_id of 1 and a column called costs with our sum.

After building our CTEs, we are ready to query the answer.
We join both CTEs via order_id and subtract our costs from
our revenues, giving us a column called net_income with a
value of $94.44.

```SQL
WITH revenues_cte AS
(
	SELECT 
		co1.order_id AS order_id,
		SUM(CASE
				WHEN co1.pizza_id = 1 THEN 12
				ELSE 10
			END) AS rev
	FROM 
		customer_orders_primary_tt AS co1
	INNER JOIN
		runner_orders AS ro
	ON
		co1.order_id = ro.order_id
	WHERE
		ro.cancellation IS NULL
)
, costs_cte AS
(
SELECT
	ro.order_id,
	SUM(ROUND((ro.distance * 0.3), 2)) AS cost
FROM
	runner_orders AS ro
WHERE
	ro.cancellation IS NULL
)
SELECT
	r.rev - ct.cost AS net_income
FROM
	revenues_cte AS r
INNER JOIN
	costs_cte AS ct
ON
	r.order_id = ct.order_id; 
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/b54744bc-f7f1-4d4c-bfc5-c361bcaa2d28)
