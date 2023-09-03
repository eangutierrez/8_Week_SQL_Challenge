/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What are the standard ingredients for each pizza?
/*
Explanation: The pizza_names, pizza_recipes and pizza_toppings 
tables have all the information we need. We need to join the 
tables, query the pizza_id, pizza_name, and topping_name.
The question could also be asking for the ingredients which
both pizzas have in common.  To find the common pizza toppings, 
we need to find all the toppings of pizza one, and ask for 
all the toppings that are also in pizza two.
*/
SELECT 
	pr.pizza_id,
	pn.pizza_name,
	pt.topping_name
FROM
	pizza_names AS pn
INNER JOIN
	pizza_recipes AS pr
ON
	pn.pizza_id - pr.pizza_id
INNER JOIN
	pizza_toppings AS pt
ON
	pr.topping_id = pt.topping_id;

-- Common ingredients:

SELECT
	pr.topping_id,
	pt.topping_name
FROM
	pizza_recipes AS pr
INNER JOIN
	pizza_toppings AS pt
ON
	pt.topping_id = pr.topping_id
WHERE
	pr.pizza_id = 2
AND pr.topping_id IN
	(
	SELECT 
		topping_id
	FROM
		pizza_recipes
	WHERE 
		pizza_id = 1
	);


-- 2. What was the most commonly added extra?
/*
Explanation: The customer_orders and pizza_toppings tables have
all the information we need.  The extra toppings are put together
on one column-row pair, so we must use the SUBSTRING_INDEX function
to place them on individual columns. We must be careful to CAST the
substring results as integers.  The first query should include the
order_id, the extras column, and the separated values of the extras
column.  We can use this query as a CTE called totals_cte, and use
it to refine our answer.  We should select the 1st extra_column,
the topping_name, and the total count of all the toppings in the
first extra value. Then we can perform a UNION operator to 
combine the result-set of the first extras column with the 
result-set of the second extras column.
*/
WITH totals_cte AS
(
	SELECT 
		co.order_id,
		co.extras AS all_extras,
		CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(co.extras, ',', 1)), ',', -1) AS UNSIGNED) AS extra_1,
		CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(co.extras, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(co.extras, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(co.extras, ',', 2)), ',', -1)) AS UNSIGNED) AS extra_2
	FROM 
		customer_orders AS co
	WHERE
		co.extras IS NOT NULL
)
SELECT
	t.extra_1 AS topping_id,
	pt.topping_name,
	COUNT(t.extra_1) AS total_times_added
FROM
	totals_cte AS t
INNER JOIN
	pizza_toppings AS pt
ON
	t.extra_1 = pt.topping_id
UNION
SELECT
	t.extra_2,
	pt.topping_name,
	COUNT(t.extra_2)
FROM
	totals_cte AS t
INNER JOIN
	pizza_toppings AS pt
ON
	t.extra_2 = pt.topping_id
GROUP BY
	t.extra_2;


-- 3. What was the most common exclusion?
/*
Explanation: The customer_orders table has all the information
we need.  The excluded toppings are put together on one 
column-row pair, so we must use the SUBSTRING_INDEX function
to place them on individual columns. We must be careful to CAST the
substring results as integers.  The first query should include the
order_id, the exclusions column, and the separated values of the
extras column.  We can use this query as a CTE called totals_cte, 
and use it to refine our answer.  We should select the 
1st excluded_column, the topping_name, and the total count of all
the toppings in the first excluded value. Then we can use a UNION 
operator to combine the result-set of the first exclusions column 
with the result-set of the second exclusions column.
*/
WITH totals_cte AS
(
	SELECT 
		co.order_id,
		co.exclusions AS all_exclusions,
		CAST(SUBSTRING_INDEX((SUBSTRING_INDEX(co.exclusions, ',', 1)), ',', -1) AS UNSIGNED) AS exclusion_1,
		CAST(IF(SUBSTRING_INDEX((SUBSTRING_INDEX(co.exclusions, ',', 2)), ',', -1) = SUBSTRING_INDEX((SUBSTRING_INDEX(co.exclusions, ',', 1)), ',', -1), NULL, SUBSTRING_INDEX((SUBSTRING_INDEX(co.exclusions, ',', 2)), ',', -1)) AS UNSIGNED) AS exclusion_2
	FROM 
		customer_orders AS co
	WHERE
		co.exclusions IS NOT NULL
)
SELECT
	t.exclusion_1 AS topping_id,
	pt.topping_name,
	COUNT(t.exclusion_1) AS total_times_removed
FROM
	totals_cte AS t
INNER JOIN
	pizza_toppings AS pt
ON
	t.exclusion_1 = pt.topping_id
GROUP BY
	t.exclusion_1
UNION
SELECT
	t.exclusion_2,
	pt.topping_name,
	COUNT(t.exclusion_2)
FROM
	totals_cte AS t
INNER JOIN
	pizza_toppings AS pt
ON
	t.exclusion_2 = pt.topping_id
GROUP BY
	t.exclusion_2;


-- 4-A. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
/*
Explanation: The customer_orders, pizza_toppings, and pizza_names 
tables have all the information we need. To make our work easier,
we should create a Temporary Table. First, this table will use the
ROW_NUMBER() and OVER() function to create a row number for each 
row.  This will be our primary key and ensure all data is analyzed.
Then, we will add all of the customer_order table columns, as well 
as separate the values of the exclusions and extras columns. Next,
we will create a CTE, called order_summary_cte, that pairs
each separated extra and exclusion value to the pizza_toppings
table to extract the topping name. We will also fetch the 
pizza name, as well as concatenate the extras and exclusions
topping names in new columns.  This will make the final query
much easier.  Finally, we will query the CTE and build
the logic to ensure the pizza summary matches the desired output.
*/
-- Create a Temporary Table to prepare data for analysis. This temporary table, 
-- we will separate the exclusions and extras into separate columns
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
-- Create CTE that pairs the topping_id with the name, changes it to the the
-- topping name, and concatenates it for easy extraction
WITH order_summary_cte AS
(
	SELECT 
		co1.row_num,
		co1.order_id,
		co1.customer_id,
		pn.pizza_name,
		IF(CONCAT_WS(', ', pt1.topping_name, pt2.topping_name) = '', NULL, CONCAT_WS(', ', pt1.topping_name, pt2.topping_name)) AS tot_exclusions,
		IF(CONCAT_WS(', ', pt3.topping_name, pt4.topping_name) = '', NULL, CONCAT_WS(', ', pt3.topping_name, pt4.topping_name)) AS tot_extras
	FROM 
		customer_orders_primary_tt AS co1
	INNER JOIN
		pizza_names AS pn
	ON
		co1.pizza_id = pn.pizza_id
	LEFT JOIN
		pizza_toppings AS pt1
	ON
		co1.exclusion_1 = pt1.topping_id
	LEFT JOIN
		pizza_toppings AS pt2
	ON
		co1.exclusion_2 = pt2.topping_id
	LEFT JOIN
		pizza_toppings AS pt3
	ON
		co1.extra_1 = pt3.topping_id
	LEFT JOIN
		pizza_toppings AS pt4
	ON
		co1.extra_2 = pt4.topping_id
	GROUP BY
		row_num
)
-- Query the CTE and build logic based on the question's parameters.
SELECT
	os.order_id,
	os.customer_id,
	(CASE
		WHEN os.tot_exclusions IS NULL AND os.tot_extras IS NULL THEN os.pizza_name
		WHEN os.tot_exclusions IS NOT NULL AND os.tot_extras IS NULL THEN CONCAT(os.pizza_name, ' - Exclude ', os.tot_exclusions)
		WHEN os.tot_exclusions IS NULL AND os.tot_extras IS NOT NULL THEN CONCAT(os.pizza_name, ' - Extra ', os.tot_extras)
		ELSE CONCAT(os.pizza_name, ' - Exclude ', os.tot_exclusions, ' - Extra ', os.tot_extras)
	END) AS pizza_instructions
FROM 
	order_summary_cte AS os
GROUP BY 
	os.row_num;


-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order
-- from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
/*
Explanation: The customer_orders, pizza_toppings, pizza_recipes, 
and pizza_names tables have all the information we need. To make 
our work easier, we should create two Temporary Tables, one with
all the pizzas with extra toppings, and another with all the pizzas
with excluded toppings.  Both of these tables should include the
row_number (to distinguish between pizzas) and the topping_id to 
identify the specific topping that's included or excluded in the
pizza. First, we will create a CTE that includes the ROW_NUMBER() 
OVER() function to create a record identifier, all the 
customer_orders table columns, and the extras and exclusions 
separated into single row-column pairs.  Then we will query each
of the records that contain extras, but place them in long form
by using the UNION operator after each query.  This is the same
formula for both the extras_cte table and the exclusions_cte 
table.  

With both of our temporary tables completed, we can 
create a CTE that queries the row number, the pizza_name, and
the topping_name for each of these tables.  By combining this
table with the extras_cte and exclusions_cte tables, we can 
add a 2x for the extra toppings and get rid of the excluded
toppings.  Finally, we can use the GROUP_CONCAT() function to
present our results in a delimited list
*/
-- Make extra toppings temporary table
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

-- Make excluded toppings temporary table
CREATE TEMPORARY TABLE IF NOT EXISTS exclusions_tt AS
WITH exclusions_cte AS
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
	e.exclusion_1 AS topping_id
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 5	AND e.exclusions IS NOT NULL
UNION
SELECT
	e.row_num,
	e.exclusion_1
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 6	AND e.exclusions IS NOT NULL
UNION
SELECT
	e.row_num,
	e.exclusion_1
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 7	AND e.exclusions IS NOT NULL
UNION
SELECT
	e.row_num,
	e.exclusion_1
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 12	AND e.exclusions IS NOT NULL
UNION
SELECT
	e.row_num,
	e.exclusion_1
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 14	AND e.exclusions IS NOT NULL
UNION
SELECT
	e.row_num,
	e.exclusion_2
FROM
	exclusions_cte AS e
WHERE
	e.row_num = 14	AND e.exclusions IS NOT NULL

	
-- With extras and exclusions temp tables done, query answer:
WITH ingredients_cte AS 
(
SELECT
	co1.row_num,
	pn.pizza_name,
	(CASE
		WHEN pt.topping_id IN
			(
			SELECT
				ext.topping_id
			FROM
				extras_tt AS ext
			WHERE
				co1.row_num = ext.row_num
			)
		THEN CONCAT('2x', pt.topping_name)
		ELSE pt.topping_name
	END) AS topping 
FROM
	customer_orders_primary_tt AS co1
INNER JOIN
	pizza_names AS pn
ON
	co1.pizza_id = pn.pizza_id
INNER JOIN
	pizza_recipes AS pr
ON
	pn.pizza_id = pr.pizza_id
INNER JOIN
	pizza_toppings AS pt
ON
	pr.topping_id = pt.topping_id
WHERE
	pr.topping_id NOT IN
		(
		SELECT
			exc.topping_id
		FROM
			exclusions_tt AS exc
		WHERE
			exc.row_num = co1.row_num
		)
)
SELECT
	i.row_num,
	i.pizza_name,
	CONCAT(i.pizza_name, ': ', GROUP_CONCAT(i.topping ORDER BY i.topping ASC SEPARATOR ', ')) AS pizza_summary
FROM
	ingredients_cte AS i
GROUP BY
	i.row_num, i.pizza_name
ORDER BY
	1;


-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
/*
Explanation: The customer_orders, pizza_toppings, pizza_recipes, 
and pizza_names tables have all the information we need. To make 
our work easier, we work with the Temporary Tables we created 
on question 5.  

Additionally, we should create another temporary table.  This
is a copy of the temporary table we created on question 4.  We
can join this table to the extras table and runner_orders to 
capture both the extra toppings and the toppings that were
added but were not part of the original recipe.
 
First, we will create a CTE, called ingredients_cte, that
queries all the row numbers and topping_ids of all the 
non-cancelled orders.  We can then add each of the records 
that contain extras below by using the UNION operator.  
We must do this because just joining the tables will 
exclude the extra toppings that are not part of the 
original pizza recipe (for example, adding bacon to a
vegetarian pizza).  

With our CTE created, we can join the pizza_toppings
table to gain access to the topping_names.  Our answer
shoul dinclude the topping_name and the total count of
all the topping_ids, grouping by topping_name.  
*/
-- Create additional temporary table:
CREATE TEMPORARY TABLE IF NOT EXISTS customer_orders_primary_2 AS
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


-- Create CTE
WITH ingredients_cte AS 
(
SELECT
	co1.row_num,
	pt.topping_id	
FROM
	customer_orders_primary_tt AS co1
INNER JOIN
	pizza_recipes AS pr
ON
	co1.pizza_id = pr.pizza_id
INNER JOIN
	pizza_toppings AS pt
ON
	pr.topping_id = pt.topping_id
INNER JOIN
	runner_orders AS r
ON
	co1.order_id = r.order_id
WHERE
	pr.topping_id NOT IN
		(
		SELECT
			exc.topping_id
		FROM
			exclusions_tt AS exc
		WHERE
			exc.row_num = co1.row_num
		) AND r.cancellation IS NULL
-- Add the extra toppings and the toppings that were
-- not part of the original recipes
UNION ALL 
SELECT 
	exttt.row_num,
	exttt.topping_id
FROM
	extras_tt AS exttt
LEFT JOIN
	customer_orders_primary_2 AS co2
ON
	exttt.row_num = co2.row_num
LEFT JOIN 
	runner_orders AS r1
ON 
	co2.order_id = r1.order_id
WHERE 
	r1.cancellation IS NULL
)
SELECT
pt.topping_name,
COUNT(i.topping_id) AS total_times_used
FROM
	ingredients_cte AS i
LEFT JOIN 
	pizza_toppings AS pt
ON
	i.topping_id = pt.topping_id
GROUP BY
	pt.topping_name
ORDER BY
	2 DESC, 1;