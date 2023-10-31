# Case Study #2: Pizza Runner - Runner and Customer Experience Solutions

## 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
### Explanation
The runners table has all the information we need.  The WEEK()
function with an argument of 1 will provide the correct context to solve 
this query.  The argument of 1 means we count the number of weeks with a 
range from zero to 53, and with the first week having four or more
days this year.  Our answer should include the week of the year and the 
total number of runner signups.

```SQL
SELECT 
	WEEK(registration_date, 1) AS week_of_the_year,
	COUNT(runner_id) AS num_of_signups
FROM
	runners
GROUP BY
	1;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/2f560ce9-9299-4a81-abac-5aa1d5c5b785)


## 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need.  We can create a CTE called pickup_times_cte that 
includes the order_id, the order_time, the pickup_time, and the 
difference in minutes between columns 2 and 3.  Once this CTE has been
created, we can get the average time it took for runners to pick up 
pizzas.  Our answer should include the runner_id, the 
average_runner_pickup_time, and we should group by the runner_id.

```SQL
WITH pickup_times_cte AS
(
	SELECT
		co.order_id,
		co.order_time,
		ro.pickup_time,
		ro.runner_id,
		TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time) AS pickup_mins
	FROM
		customer_orders AS co
	INNER JOIN
		runner_orders AS ro
	ON
		co.order_id = ro.order_id
	WHERE
		cancellation IS NULL
	GROUP BY
		co.order_id, co.order_time, ro.pickup_time
)
SELECT
	pt.runner_id,
	AVG(pt.pickup_mins) AS avg_runner_pickup_time
FROM
	pickup_times_cte AS pt
GROUP BY
	pt.runner_id;
```

### Answer 
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/464896dd-3726-414e-8590-62e0755695a8)


## 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need.  We can create a CTE called total_prep_cte that 
includes the order_id, total count of pizzas in each order, the 
order_time, the pickup_time, and the difference in minutes between 
columns 3 and 4.  Once this CTE has been created, we can get the average
time it took for orders grouped by the number of pizzas. Our answer 
should include the number of pizzas in the order and the average 
prep time of each, grouped by the number of pizzas. This table 
shows that on average, the prep time of each order increases as
the number of pizzas increases.

```SQL
WITH total_prep_cte AS
(
	SELECT
		co.order_id,
		COUNT(co.pizza_id) AS num_pizzas,
		co.order_time,
		ro.pickup_time,
		TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time) AS prep_time
	FROM
		customer_orders AS co
	INNER JOIN
		runner_orders AS ro
	ON
		co.order_id = ro.order_id
	WHERE
		cancellation IS NULL
	GROUP BY
		co.order_id, co.order_time, ro.pickup_time
)
SELECT
	tp.num_pizzas,
	AVG(tp.prep_time) AS avg_prep_time
FROM
	total_prep_cte AS tp
GROUP BY
	tp.num_pizzas;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/032870d9-68f4-48e7-a44b-fa666e35a277)


## 4. What was the average distance travelled for each customer?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need.  We must filter out the cancelled orders in the 
WHERE clause.  Our answer should include the customer_id and the
average distance, grouped by customer_id.

```SQL
SELECT
	co.customer_id,
	AVG(ro.distance) AS avg_distance_travelled
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	ro.cancellation IS NULL
GROUP BY
	co.customer_id;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/fa047c34-bdf9-402c-946b-ed8c25600047)


## 5. What was the difference between the longest and shortest delivery times for all orders?
### Explanation
The runner_orders table has all the information 
we need.  We are interested in the maximum and minimum values
of the duration column, while disregarding cancelled orders.
Our answer should include the max duration minus the min
duration. 

```SQL
SELECT
	MAX(ro.duration) - MIN(ro.duration) AS max_min_difference
FROM
	runner_orders AS ro
WHERE 
	ro.cancellation IS NULL;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/fffc55f9-650e-4143-be23-daa8e2e25377)


## 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
### Explanation
The customer_orders and runner_orders tables have all the 
information we need.  The main columns we are interested in are the
runner_id, the order_id, the order_time, and the avg_speed, which 
is calculated by dividing the distance over time.  We should filter
out all the cancelled orders, group by runner_id and order_id, and 
order by the same values.  By looking at our results, we can see
that runners 1 and 2 have increased their average speed as the runner
delivers more orders.  We need more runner 3 observations before 
finding new information.

```SQL
SELECT
	ro.runner_id,
	co.order_id,
	co.order_time,
	AVG((ro.distance * 60) / ro.duration) AS avg_speed_km_hr
FROM
	customer_orders AS co
INNER JOIN
	runner_orders AS ro
ON
	co.order_id = ro.order_id
WHERE
	cancellation IS NULL
GROUP BY
	co.order_id, ro.runner_id
ORDER BY
	runner_id, order_id;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/97b2facc-e723-40fe-89c9-19b7c21d6bc0)


## 7. What is the successful delivery percentage for each runner?
### Explanation
The runner_orders table has all the information we
need.  The main columns we are interested in are the runner_id, 
the order_id, and cancellation.  We need to find the total orders
(counting cancelled orders), the completed orders (not counting
cancelled orders), and use these numbers to compute the percentage
of cancelled orders per runner.  I completed the task using the
working version of the query, but simplified it to the final
version below.  Note: these cancellations have nothing to do with
runner performance, so these results should not be taken to heart.

```SQL
-- Working Version
SELECT
	x.runner_id,
	(x.completed_orders / x.total_orders) * 100 AS successful_deliv_pct
FROM 
	(
	SELECT
		ro.runner_id,
		SUM(CASE
				WHEN ro.cancellation IS NULL THEN 1
				ELSE 0
			  END) AS completed_orders,	
		COUNT(ro.order_id) AS total_orders
	FROM
		runner_orders AS ro
	GROUP BY
		ro.runner_id
	ORDER BY
		runner_id
	) AS x;

-- Final Version
SELECT
	runner_id,
	(SUM(CASE 
		WHEN ro.cancellation IS NULL THEN 1
		ELSE 0
	END) / COUNT(ro.order_id)) * 100 AS successful_deliv_pct
FROM
	runner_orders AS ro
GROUP BY 
	ro.runner_id;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/2cbf7dc4-4557-4daa-8be7-ba71eb74466e)
