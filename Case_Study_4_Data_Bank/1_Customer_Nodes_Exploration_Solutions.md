# Case Study #4: Data Bank - Customer Journey Solutions

## 1. How many unique nodes are there on the Data Bank system?
### Explanation
The customer_nodes table has all the information we need.  
By looking at the table, we see that each region has five distinct
nodes, with node_ids from one to five.  This shows that the node_id
by itself is not a unique identifier.  This means that the combination
of region_id and node_id uniquely identify each node.  We can count 
the distinct nodes of all regions in a CTE called node_count.  After
our CTE is complete, we can query the CTE to sum all of the region
nodes to find the total number of unique nodes on the Data Bank
system.

```SQL
WITH node_count AS
(
	SELECT 
		cn.region_id,
		r.region_name,
		COUNT(DISTINCT cn.node_id) AS total_unique_nodes_per_region
	FROM 
		customer_nodes AS cn
	INNER JOIN
		regions AS r
	ON
		cn.region_id = r.region_id
	GROUP BY
		cn.region_id
)
SELECT
	SUM(total_unique_nodes_per_region)
FROM
	node_count;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/c86f1540-5a74-4deb-9aef-547f8b3eec66)


## 2. What is the number of nodes per region?
### Explanation
The customer_nodes and regions tables has all the 
information we need.  This question does not ask for the unique
number of nodes, so we can modify question 1's CTE to find
this answer.  After joining both tables and grouping by 
region_id, we can ask for the region_id, the region_name, and
the total count of nodes per region.

```SQL
SELECT 
	cn.region_id,
	r.region_name,
	COUNT(cn.node_id) AS total_nodes_per_region
FROM 
	customer_nodes AS cn
INNER JOIN
	regions AS r
ON
	cn.region_id = r.region_id
GROUP BY
	cn.region_id
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/8ee70e0e-27f8-4542-ac42-050bff1dd558)


## 3. How many customers are allocated to each region?
### Explanation
The customer_nodes and regions tables have all the 
information we need.  After joining both tables and grouping by
the region_id, we can select the region_id, region_name, and the 
total count of distinct customer_ids per region.

```SQL
SELECT
	cn.region_id,
	r.region_name,
	COUNT(DISTINCT cn.customer_id)
FROM
	customer_nodes AS cn
INNER JOIN
	regions AS r
ON
	cn.region_id = r.region_id
GROUP BY
	cn.region_id;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/f6991a4a-2e53-49c7-91bc-2b9fc91e41c8)


## 4. How many days on average are customers reallocated to a different node?
### Explanation
The customer_nodes table has all the information we need.
While exploring each customer's individual transactions, we can see that
each customer's last record has an end date of '9999-12-31.'  This could
be a typo, or a value that system engineers set to signal the latest
record on file.  Using this outlier value in our calculation will yield
a wrong result, so we should filter it in the where clause.  Moreover,
we see that sometimes customers go back and forth between nodes multiple
times.  This means that we must group by customer_id and node_id to 
get the sum of the the differences in dates.  We can use this query as a
CTE called sum_days_in_node_cte, where we can get the average number
of days a customer is reallocated to a different node. 

```SQL
WITH sum_days_in_node_cte AS
(
	SELECT
		cn.region_id,
		cn.customer_id,
		cn.node_id,
		cn.start_date,
		cn.end_date,
		SUM(DATEDIFF(cn.end_date, cn.start_date)) AS days_in_node
	FROM
		customer_nodes AS cn
	WHERE 
		cn.end_date != '9999-12-31'
	GROUP BY
		cn.customer_id, cn.node_id
)
SELECT
	ROUND(AVG(s.days_in_node), 2) AS avg_days_before_reallocation
FROM
	sum_days_in_node_cte AS s
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/73470ec2-7933-4d97-b7a1-6c0ca64661dc)


## 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
### Explanation
The customer_nodes and regions tables have all the 
information we need.  We can build on the answer for question 4 for this
question.  First, we want to join the customer_nodes and regions tables
and select all the contents of the customer_nodes tables, plus the 
region_names column.  Then we create another CTE called ordered_cte
that gets the region_name, the days_before_reallocation, and creates
a row number partitioned by region_name and ordered by the difference
in days.  Finally, we can create a CTE called max_cte, that finds the
region_name and the last row of each region's records.  This max will
help with the calculations for median, 80th, and 95th percentile.  

After building the CTEs, we can complete our query.  First, we will
join the ordered_cte and the max_cte on region_name.  Then, we will
filter the days before reallocation for the median, 80th, and 95th
percentile in the WHERE clause.  To finish the query, we select the
region_name, a CASE statement to name the specific metric, and the
row number that contains the number of days before a customer was
reallocated.

```SQL
-- get the necessary data, group by and filter faulty date:
WITH days_cte AS
(
	SELECT 
		r.region_name,
		cn.customer_id,
		cn.node_id,
		cn.start_date,
		cn.end_date,
		SUM(DATEDIFF(cn.end_date, cn.start_date)) AS days_diff
	FROM 
		customer_nodes AS cn
	INNER JOIN
		regions AS r
	ON
		cn.region_id = r.region_id
	WHERE 
		cn.end_date != '9999-12-31'
	GROUP BY
		r.region_name, cn.customer_id, cn.node_id
)
-- create row_number partitioned by region_name and ordered by the difference in days:
, ordered_cte AS
(
	SELECT
		d.region_name,
		d.days_diff,
		ROW_NUMBER() OVER(PARTITION BY d.region_name ORDER BY d.days_diff) AS row_num
	FROM
		days_cte AS d
)
-- Find the last row number per region.  This will help calculate values 
	max_cte AS m
ON
	o.region_name = m.region_name
-- Only filter the values for the median, 80th, and 95th percentile
, max_cte AS
(
	SELECT
		o.region_name,
		MAX(o.row_num) AS max_row
	FROM
		ordered_cte AS o
	GROUP BY
		o.region_name
)
-- Create table with that gives, region, metric_name, and days_before_reallocation value
SELECT
	o.region_name,
-- Switch between metric names
	(CASE
		WHEN row_num = ROUND(m.max_row / 2) THEN 'Median'
		WHEN row_num = ROUND(m.max_row * 0.8, 0) THEN '80th Percentile'
		WHEN row_num = ROUND(m.max_row * 0.95, 0) THEN '95th Percentile'
	END) AS metric_name,
	o.row_num AS days_before_reallocation
FROM
	ordered_cte AS o
-- Join max_cte to gain access to each region's last row number
INNER JOIN
	max_cte AS m
ON
	o.region_name = m.region_name
-- Only filter the values for the median, 80th, and 95th percentile
WHERE
	o.row_num IN ( 
		ROUND(m.max_row / 2),
		ROUND(m.max_row * 0.8, 0),
		ROUND(m.max_row * 0.95, 0));
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/a9d0c63c-2916-4d26-8d71-c98ccf43031d)
