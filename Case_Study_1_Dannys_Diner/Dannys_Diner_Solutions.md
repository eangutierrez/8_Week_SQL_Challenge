# Case Study #1: Danny's Diner Solutions

## 1. What is the total amount each customer spent at the restaurant?
### Explanation

We can't start our query from the members table.  This is because 
there could be sales from people who aren't members.  The sales table has 
customer_id, so we can start our query from the sales table. We can then join
the menu table group by the customer_id on the sales table.  Our answer must 
include the customers and all they spent, so customer id and a SUM(price).

```SQL
SELECT 
	s.customer_id,
	SUM(mn.price) AS total_spent
FROM 
	sales AS s
INNER JOIN 
	menu as mn
ON
	s.product_id = mn.product_id
GROUP BY 
	s.customer_id;
```

## 2. How many days has each customer visited the restaurant?
### Explanation
The sales table has all the information we need: the customer_id 
and the order_date. We must group by the customer_id.  Our result should 
include the customer_id and a COUNT DISTINCT of the order_date.

```SQL
SELECT 
	customer_id,
	COUNT(DISTINCT order_date)
FROM 
	sales
GROUP BY
	customer_id;
```

## 3. What was the first item from the menu purchased by each customer?
### Explanation
The data that we want in on the sales and menu tables. Our table
should include the customer_id, the product_name, and the order_date.
Additionally, our results should be ranked by order rate, and partitioned by each
customer, and should account for customers ordering multiple products on their
first visit.  The DENSE_RANK() function should take care of this.  Our final result
can use those results as a subquery, and the quickest way to incorporate this table
is with a Common Table Expression.  We want the customer_id and the product_name
where the rank is equal to 1. Finally, we should group by the customer_id and the
product_name to avoid repetitions.

```SQL
WITH rankings AS 
	(SELECT 
		s.customer_id,
		mn.product_name,
		s.order_date,
		DENSE_RANK() OVER(PARTITION BY (customer_id) ORDER BY order_date) AS 'rank'
	FROM 
		sales AS s
	INNER JOIN
		menu AS mn
	ON
		s.product_id = mn.product_id
	)
SELECT 
	r.customer_id,
	r.product_name
FROM
	rankings AS r
WHERE 
	r.rank = 1
GROUP BY 
	r.customer_id,
	r.product_name;
```

## 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
### Explanation
The information we are looking for is on the sales and menu tables.
Our answer should include the product_id, the product_name, and the total 
number of times it was ordered.  We should group by product_name, order by the 
total number of orders in descending order, and limit our table to 1 record.

```SQL
SELECT
	mn.product_id,
	mn.product_name,
	COUNT(s.order_date) AS total_orders
FROM
	sales AS s
INNER JOIN
	menu AS mn
ON
	s.product_id = mn.product_id
GROUP BY 
	mn.product_name
ORDER BY 
	total_orders DESC
LIMIT
	1;
```

## 5. Which item was the most popular for each customer?
### Explanation
The information we are looking for is on the sales and menu tables. We must
get the customer_id, product_name, count the number of total purchases, and densely rank
over the total number of purchases, partitioned by customer_id, and order them in 
descending order.  With our subquery completed, the fastest way to proceed is to 
make this result a Common Table Expression. Moreover, we must get the customer id, 
product_name, and total number of purchases where the ranking is equal to 1. 
Finally, we must group by customer_id and product_name to make sure all results are 
displayed.

```SQL
WITH rankings AS 
	(SELECT 
		s.customer_id,
		mn.product_name,
		COUNT(s.product_id) AS total_purchases,
		DENSE_RANK() OVER(PARTITION BY (s.customer_id) ORDER BY COUNT(s.customer_id) DESC) AS 'rank'
	FROM 
		sales AS s
	INNER JOIN
		menu AS mn
	ON
		s.product_id = mn.product_id 
	GROUP BY 
		s.customer_id, mn.product_name
	)
SELECT 
	rk.customer_id,
	rk.product_name,
	rk.total_purchases
FROM
	rankings AS rk
WHERE rk.rank = 1
GROUP BY
	customer_id, product_name;
```

## 6. Which item was purchased first by the customer after they became a member?
### Explanation
The information we are looking for is on the sales and members table. However, 
we are only interested in the records after the join_date. That means that we will join both
tables on the customer_id, and add where the join_date is greater than the order_date. Our
query will display the customer_id, the product_id, and a ranking of order_dates in ascending
order, partitioned by customer_id, without repeats.  The ROW_NUMBER() function achieves this. 
After making this query a Common Table Expression, we can join it with the menu table to 
provide the product_name. We want the customer_id, the product_id, and the product_name, get 
the records where the ranking is equal to 1, and order the results by customer_id.

```SQL
WITH items_ordered AS
	(SELECT
		me.customer_id,
		s.product_id,
		ROW_NUMBER() OVER(PARTITION BY (customer_id) ORDER BY s.order_date) AS 'rank'
	FROM
		members AS me
	INNER JOIN
		sales AS s
	ON
		me.customer_id = s.customer_id 
	AND
		s.order_date > me.join_date
	)
SELECT
	it.customer_id,
	it.product_id,
	mn.product_name AS first_purchase_after_membership
FROM
	items_ordered AS it
INNER JOIN
	menu AS mn
ON
	it.product_id = mn.product_id
WHERE 
	it.rank = 1
ORDER BY 
	it.customer_id;
```

## 7. Which item was purchased just before the customer became a member?
### Explanation
The information we are looking for is on the sales and members table. However, 
we are only interested in the records before the join_date. That means that we will join both
tables on the customer_id, and add where the join_date is less than the order_date. Our
query will display the customer_id, the product_id, and a ranking of order_dates in descending 
order, partitioned by customer_id, without repeats.  The ROW_NUMBER() function achieves this. 
After making this query a Common Table Expression, we can join it with the menu table to 
provide the product_name. We want the customer_id, the product_id, and the product_name, get 
the records where the ranking is equal to 1, and order the results by customer_id.

```SQL
-- Working Version:
WITH ordered_items AS
	(SELECT 
		me.customer_id,
		s.product_id,
		s.order_date,
		ROW_NUMBER() OVER (PARTITION BY (me.customer_id) ORDER BY s.order_date DESC) as 'rank'
	FROM 
		members AS me
	INNER JOIN 
		sales AS s
	ON
		me.customer_id = s.customer_id 
	AND
		s.order_date < me.join_date
	)
SELECT 
	it.customer_id,
	it.product_id,
	it.order_date,
	mn.product_name
FROM 
	ordered_items AS it
INNER JOIN
	menu AS mn
ON
	it.product_id = mn.product_id
WHERE 
	it.rank = 1
ORDER BY
	it.customer_id;

-- Final Version:
WITH ordered_items AS
	(SELECT 
		me.customer_id,
		s.product_id,
		ROW_NUMBER() OVER (PARTITION BY (me.customer_id) ORDER BY s.order_date DESC) as 'rank'
	FROM 
		members AS me
	INNER JOIN 
		sales AS s
	ON
		me.customer_id = s.customer_id 
	AND
		s.order_date < me.join_date
	)
SELECT 
	it.customer_id,
	it.product_id,
	mn.product_name
FROM 
	ordered_items AS it
INNER JOIN
	menu AS mn
ON
	it.product_id = mn.product_id
WHERE 
	it.rank = 1
ORDER BY
	it.customer_id;
```

## 8. What is the total items and amount spent for each member before they became a member?
### Explanation
The information we are looking for is spread throughout the three tables. 
Although the answer can be found with a simple query, a more elegant solution is to 
create a Common Table Expression. We join the sales and members table on the 
customer_id and only get the records with a join_date greater than the order_date. 
We select the customer and product_ids, and make that into a CTE called prior_sales. 
We join the CTE with the menu table to gain access to the product prices. Finally, 
we can directly query the CTE and get the customer_id, the total count of the product_id 
to get the total purchases, and the sum of the price to see the total amount spent 
before membership.  We group and order by customer_id.

 ```SQL
WITH prior_sales AS 
	(SELECT 
		me.customer_id,
		s.product_id
	FROM 
		members AS me
	INNER JOIN
		sales AS s
	ON
		me.customer_id = s.customer_id 
	AND 
		me.join_date > s.order_date
	)
SELECT 
	p.customer_id,
	COUNT(p.product_id) AS total_purchases_before_membership,
	SUM(mn.price) AS total_spent_before_membership
FROM 
	prior_sales AS p
INNER JOIN
	menu AS mn
ON
	p.product_id = mn.product_id
GROUP BY 
	p.customer_id
ORDER BY 
	p.customer_id;
```

## 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier, how many points would each customer have?
### Explanation
The information we need is on the sales and menu tables.  To begin, 
we need to create an additional column on the menu table, the total_points table.  
This is done via a CASE WHEN statement.  When the product name is sushi, it will 
multiply the price by 20 to get the double the 10 points per dollar spent, and 
when the product name is anything else, it will multiply the price by 10 to get 
the 10 points per dollar spent structure. We will create a Common Table Expression 
with this information and call it pts_cte. Then, we will join the pts_cte to the 
sales table and group and order our results by customer_id.  Finally, we will get 
the customer_id, and the sum of the total_points column we created.

```SQL
WITH pts_cte AS
	(SELECT 
		mn.product_id,
		mn.product_name,
		mn.price,
		(CASE
			WHEN mn.product_name = 'sushi' THEN mn.price * 20
			ELSE mn.price * 10
		END) AS total_points
	FROM
		menu AS mn
	)
SELECT
	s.customer_id,
	SUM(pt.total_points)
FROM 
	pts_cte AS pt
INNER JOIN 
	sales AS s
ON
	pt.product_id = s.product_id
GROUP BY
	customer_id;
```

## 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
### Explanation
The information we need is spread throughout the three tables.  To begin, 
we need to query from the sales table and join the menu and members tables. We want the
customer_id, the product_name, the price, the order_date, the join_date, and an additional
column that adds six days from the membership join_date.  We will call this the end of 
promotion date, or eop_date column. Based on these columns, we will create a CASE statement
with five different possibilities.  These can be broken down into three different stages:
1. Before customers join the membership program:
	A. When the order_date is less than the join_date and customers purchase sushi, then
	   customers earn double the 10 points per $1 dollar spent, or mn.price * 10 * 2
	B. When the order_date is less than the join_date and customers purchase anything 
	   else, then customers earn 10 points per $1 dollar spent, or mn.price * 10 
2. During the promotion:
	C. When the order_date is greater than or equal to the join_date AND the order_date is
	   less than the eop_date, then they earn double the 10 points per $1 dollar spent, 
	   or mn.price * 10 * 2
3. After the promotion ends:
	D. When the order_date is greater than the join_date and customers purchase sushi, then
	   customers earn double the 10 points per $1 dollar spent, or mn.price * 10 * 2
	E. When the order_date is greater than the join_date and customers purchase anything 
	   else, then customers earn 10 points per $1 dollar spent, or mn.price * 10
To complete the query, we need to filter the results to only show purchases made in 
January 2021.  We can make this query more accessible by making it a Common Table 
Expression called pts_cte, group and order the results by the CTE's customer_id, and
select the customer_id and the sum of the points earned.

```SQL
WITH pts_cte AS
	(SELECT 
		s.customer_id,
		mn.product_name,
		mn.price,
		s.order_date,
		me.join_date,
		TIMESTAMPADD(Day, 6, me.join_date) AS eop_date,
		(CASE
	-- Before joining membership program
			WHEN s.order_date < me.join_date AND mn.product_name = 'sushi' THEN mn.price * 10 * 2
			WHEN s.order_date < me.join_date THEN mn.price * 10
	-- After joining membership program AND during 1st week of promotion
			WHEN s.order_date >= me.join_date AND s.order_date < TIMESTAMPADD(Day, 6, me.join_date) THEN mn.price * 10 * 2
	-- After joining membership program AND after promotion ends
			WHEN s.order_date > me.join_date AND mn.product_name = 'sushi' THEN mn.price * 10 * 2
			WHEN s.order_date > me.join_date THEN mn.price * 10
		END) AS pts_earned
	FROM 
		sales AS s
	INNER JOIN 
		menu AS mn
	ON 
		mn.product_id = s.product_id
	INNER JOIN 
		members AS me
	ON 
		me.customer_id = s.customer_id
	WHERE
		s.order_date BETWEEN '2021-01-01' AND '2021-01-31'
	)
SELECT
	p.customer_id,
	SUM(p.pts_earned)
FROM 
	pts_cte AS p
GROUP BY
	p.customer_id
ORDER BY
	p.customer_id;
```

## Bonus Question 1: Join All the Things (Recreate the Table)
### Explanation
We are tasked with producing the table's output by ourselves. The data we
need is spread throughout the three tables.  If we use an inner join on all the tables,
we will get rid of customer C since he is not a member.  That is why we must use
a left join to connect the sales table and the members table.After joining all tables, 
we choose the customer_id, the product_name, the price, the order_date, and the 
join_date.  The final column will be created with a case statement. When the order_date
is less than the join_date, then a value of "N" will be produced.  When the order_date 
is greater than or equal to the join_date, then a value of "Y" will be produced. And
to account for customers who are not members, we must add an else statement that 
produces a value of "N."  Finally, we can make our current query a Common Table
Expression, call the respective columns, and order by the customer_id and the order_date.

```SQL
WITH base AS
	(SELECT
		s.customer_id,
		mn.product_name,
		mn.price,
		s.order_date,
		me.join_date,
		CASE
			WHEN s.order_date < me.join_date THEN 'N'
			WHEN s.order_date >= me.join_date THEN 'Y'
			ELSE 'N'
		END AS 'member'
	FROM
		sales AS s
	LEFT JOIN
		members AS me
	ON
		s.customer_id = me.customer_id
	INNER JOIN
		menu AS mn
	ON
		s.product_id = mn.product_id
	)
SELECT 
	b.customer_id,
	b.order_date,
	b.product_name,
	b.price,
	b.member
FROM
	base AS b
ORDER BY b.customer_id, b.order_date;
```	

## Bonus Question 2: Rank All the Things (Recreate the Table)
### Explanation
This query uses the query from Bonus Question 1 as a base. It asks us to
produce an additional column called ranking, that ranks the products ordered by each
customer, partitioned by both customer_id and the member column created earlier, ordered
by the order_date, and only take members into account.  This column can be created 
outside the CTE with a Case Statement, which will rank (order with repeats, to use a 
better word) member purchases.  

```SQL
WITH base AS
	(SELECT
		s.customer_id,
		mn.product_name,
		mn.price,
		s.order_date,
		me.join_date,
		CASE
			WHEN s.order_date < me.join_date THEN 'N'
			WHEN s.order_date >= me.join_date THEN 'Y'
			ELSE 'N'
		END AS 'member' 
	FROM
		sales AS s
	LEFT JOIN
		members AS me
	ON
		s.customer_id = me.customer_id
	INNER JOIN
		menu AS mn
	ON
		s.product_id = mn.product_id
	)
SELECT 
	b.customer_id,
	b.order_date,
	b.product_name,
	b.price,
	b.member,
	CASE
		WHEN b.member = 'Y' THEN RANK() OVER (PARTITION BY b.customer_id, b.member ORDER BY s.order_date)
		ELSE NULL
	END AS ranking
FROM
	base AS b
ORDER BY b.customer_id, b.order_date;
```
