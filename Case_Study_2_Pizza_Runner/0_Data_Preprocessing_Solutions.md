# Case Study #2: Pizza Runner: Data Preprocessing
## 1. Clean the Data
### Explanation

#### Let's have a look at all of our tables: 

```SQL
-- pizza_names table
SELECT *
FROM pizza_names;

DESCRIBE pizza_names;
```

```SQL
-- pizza_toppings table
SELECT *
FROM pizza_toppings;

DESCRIBE pizza_toppings;
```

```SQL
-- runners table
SELECT *
FROM runners;

DESCRIBE runners;
```

```SQL
-- pizza_recipes table
SELECT *
FROM pizza_recipes;

DESCRIBE pizza_recipes;
```

```SQL
-- runner_order table
SELECT *
FROM runner_orders;

DESCRIBE runner_orders;
```

```SQL
-- customer_orders table
SELECT *
FROM customer_orders;

DESCRIBE customer_orders;
```

#### Issues 
After looking at the data, it looks like there are three tables that need to be preprocessed: 
the runner_orders, the customer_orders, and the pizza_recipes tables.  
Here are the main issues:

**runner_orders table**:
1. The pickup_time column has multiple cells with the word 'null' instead of
actual NULL values.
2. The distance column has multiple cells with the word 'null' instead of
actual NULL values.
3. Additionally, this column has both numbers and letters (the numbers and
dimensions.  We must get rid of the words to before making any calculations.
4. Next, this column has the wrong data type.  It should be a numeric value.
5. The duration column has similar issues as the distance column.  
6. The cancellation column has both empty strings and the word 'null'
instead of actual NULL values.
7. Finally, the column does not have the correct data types.  The 
column pickup_time should be DATETIME, the distance column should be  
FLOAT, and the duration column should be an integer.

**customer_orders table**:
1. The exclusions column has empty strings and the word 'null' instead of 
actual NULL values
2. The extras column has the same issues as the exclusions column.

**pizza_recipes table**:
1. The toppings column has multiple comma-separated-values.  Not only does
this make it difficult to query, but our data table is not 1NF normalized.
We need to make sure that there is one topping in each row-column pair.

As a precaution, we should also make sure that all the columns with string 
values do not have extra trailing or leading spaces.  I opted to make copies
of these tables, fix their issues, delete the original tables, and rename 
the duplicate tables.  Applying these changes will make our data analysis
much easier.

#### Solution

```SQL
-- Create copy runner_orders table
CREATE TABLE runner_orders_x AS
SELECT
	order_id,
	runner_id,
	(CASE
		WHEN pickup_time LIKE 'null' THEN NULL
		ELSE pickup_time
	END) AS pickup_time,
	(CASE
		WHEN distance LIKE 'null' THEN NULL
		WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
		ELSE distance
	END) AS distance,
	(CASE
		WHEN duration LIKE 'null' THEN NULL
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
		WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
		ELSE duration
	END) AS duration,
	(CASE
		WHEN cancellation = '' OR cancellation = 'null' THEN NULL
		ELSE cancellation
	END) AS cancellation
FROM
	runner_orders;

DROP TABLE runner_orders;

RENAME TABLE runner_orders_x TO runner_orders;

-- Create copy of customer_orders table
CREATE TABLE customer_orders_x AS
SELECT
	order_id,
	customer_id,
	pizza_id,
	(CASE
		WHEN exclusions = '' OR exclusions = 'null' THEN NULL
		ELSE exclusions
	END) AS exclusions,
	(CASE
		WHEN extras = '' OR extras = 'null' THEN NULL
		ELSE extras
	END) AS extras,
	order_time
FROM
	customer_orders;

-- Delete old table and rename new table as the old table's name
DROP TABLE customer_orders;

RENAME TABLE customer_orders_x TO customer_orders;


-- Change correct data types
ALTER TABLE runner_orders
	MODIFY COLUMN pickup_time DATETIME,
	MODIFY COLUMN distance FLOAT,
	MODIFY COLUMN duration INT;

-- Create copy of pizza_recipes table that splits all toppings into multiple columns
CREATE TABLE pizza_recipes_x AS
SELECT 
	pizza_id,
	toppings,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 1)), ',', -1) AS topping_1,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 2)), ',', -1) AS topping_2,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 3)), ',', -1) AS topping_3,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 4)), ',', -1) AS topping_4,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 5)), ',', -1) AS topping_5,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 6)), ',', -1) AS topping_6,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 7)), ',', -1) AS topping_7,
	SUBSTRING_INDEX((SUBSTRING_INDEX(toppings, ',', 8)), ',', -1) AS topping_8
FROM
	pizza_recipes;


-- Create copy of pizza_recipes_y table that converts data to long format
CREATE TABLE pizza_recipes_y AS
SELECT  -- Add toppings from pizza_id = 1
	pizza_id,
	topping_1 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_2 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_3 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_4 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_5 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_6 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_7 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION
SELECT
	pizza_id,
	topping_8 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 1
UNION -- Add toppings from pizza_id = 2
SELECT
	pizza_id,
	topping_1 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2
UNION
SELECT
	pizza_id,
	topping_2 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2
UNION
SELECT
	pizza_id,
	topping_3 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2
UNION	
SELECT
	pizza_id,
	topping_4 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2
UNION
SELECT
	pizza_id,
	topping_5 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2
UNION
SELECT
	pizza_id,
	topping_6 AS topping_id
FROM
	pizza_recipes_x
WHERE
	pizza_id = 2;

-- Drop old tables and transition
DROP TABLE pizza_recipes;
DROP TABLE pizza_recipes_x;

RENAME TABLE pizza_recipes_y TO pizza_recipes;

-- Change pizza_recipes table to correct data types
ALTER TABLE pizza_recipes
	MODIFY COLUMN topping_id INT;
	
-- Trim trailing and leading spaces
UPDATE pizza_names
SET pizza_name = TRIM(pizza_name);

UPDATE pizza_toppings
SET topping_name = TRIM(topping_name);
```
