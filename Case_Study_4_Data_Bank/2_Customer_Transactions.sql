/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the unique count and total amount for each transaction type?
/*
Explanation: The customer_transactions table has all the information we 
need.  After grouping by transaction type, we can select the transaction
type, the total count of all transactions, and the sum of all 
transaction amounts.  
*/
SELECT
	ct.txn_type,
	COUNT(ct.txn_type) AS total_transactions,
	SUM(ct.txn_amount) AS total_dollars
FROM	
	customer_transactions AS ct
GROUP BY
	ct.txn_type;


-- 2. What is the average total historical deposit counts and amounts for all customers?
/*
Explanation: The customer_transactions table has all the information we 
need.  After filtering all the deposit transactions in the WHERE clause,
we should group by customer_id.  Then we should select the customer_id, 
the total count of transactions, and the average transaction amount.  
We can use this query as a CTE called deposits_cte to query the final
answer.  After building our CTE, we are ready to complete the query.
The solution should include the average of the total deposits, as well
as the average of the total amounts.
*/
WITH deposits_cte AS
(
	SELECT
		ct.customer_id,
		COUNT(ct.txn_type) AS total_deposits,
		AVG(ct.txn_amount) AS avg_amounts
	FROM	
		customer_transactions AS ct
	WHERE
		ct.txn_type = 'deposit'
	GROUP BY
		ct.customer_id
)
SELECT
	ROUND(AVG(d.total_deposits)) AS avg_number_of_deposits,
	ROUND(AVG(d.avg_amounts), 2) AS avg_deposit_amounts
FROM
	deposits_cte AS d;


-- 3. For each month - how many Data Bank customers make more than 1 deposit 
-- and either 1 purchase or 1 withdrawal in a single month?
/*
Explanation: The customer_transactions table has all the information we 
need.  After grouping by customer_id and transaction month, we can 
use the HAVING clause to filter the results for records with more than 
one deposit and either one withdrawal or one purchase.  We can build a 
CTE from this query called data_cte, that will help us answer our 
question.  After grouping by transaction month, we should select the
transaction month and the total count of customer_ids to find the number
of customers that fit the correct parameters. 
*/
WITH data_cte AS
(
	SELECT 
		ct.customer_id,
		MONTHNAME(ct.txn_date) AS txn_month,
		SUM(CASE
			WHEN ct.txn_type = 'deposit' THEN 1 ELSE 0
		END) AS num_deposits,
		SUM(CASE
			WHEN ct.txn_type = 'withdrawal' THEN 1 ELSE 0
		END) AS num_withdrawals, 
		SUM(CASE
			WHEN ct.txn_type = 'purchase' THEN 1 ELSE 0
		END) AS num_purchases
	FROM 
		customer_transactions AS ct
	GROUP BY
		ct.customer_id, txn_month
	HAVING
		num_deposits > 1 AND (num_withdrawals = 1 OR num_purchases = 1)
	ORDER BY
		txn_month, ct.customer_id
)
SELECT 
	d.txn_month,
	COUNT(d.customer_id) AS total_instances
FROM
	data_cte AS d
GROUP BY
	d.txn_month
ORDER BY
	FIELD(d.txn_month, 'January', 'February', 'March', 'April');


-- 4. What is the closing balance for each customer at the end of the month?
/*
Explanation: The customer_transactions table has all the information we 
need.  We need to build two CTEs to answer the question.  The first CTE,
transaction_values_cte, selects all the contents of the 
customer_transactions table, plus uses a CASE statement to create a new
column with positive amounts for deposits and negative amounts for all
other transactions.  The next CTE, balance_cte, queries all the first 
CTE's columns, plus a sum over the transaction value partitioned by 
customer_id and ordered by transaction date to get a running sum.  The
final column creates a unique value per row partitioned by customer_id 
and transaction month ordered by transaction date in descending order
to find the last transaction for all customers each month.  

With our CTEs completed, we are ready to answer the question.  After 
filtering for the first row_number in the WHERE clause, we select the 
customer_id, the transaction month, and the closing balance of each
column.
*/
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		MONTHNAME(ct.txn_date) AS txn_month,
		ct.txn_date,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS value
	FROM
		customer_transactions AS ct
)
, balance_cte AS
(
	SELECT
		tv.customer_id,
		tv.txn_month,
		tv.txn_date,
		tv.value AS transaction_total,
		SUM(tv.value) OVER (PARTITION BY tv.customer_id ORDER BY tv.txn_date) AS running_sum,
		ROW_NUMBER() OVER (PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date DESC) AS row_num
	FROM 
		transaction_values_cte AS tv
	ORDER BY
		tv.txn_date
)
SELECT 
	b.customer_id,
	b.txn_month AS month_name,
	b.running_sum AS closing_balance
FROM 
	balance_cte AS b
WHERE 
	b.row_num = 1
ORDER BY
	b.customer_id, FIELD(b.txn_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');


-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
/*
Explanation: This problem builds off the answer for question 4.  After
the first two CTEs, we need to build another CTE called prev_month_cte, 
that queries from the previous CTE, filters the last month transaction 
in the WHERE clause, and selects the customer_id, the month_name, the 
previous month name using the DATE_SUB() function, and the running_sum.

The next CTE, percentage_cte, queries the previous CTE, joins it with 
itself on the month name with the previous month name, and on the 
customer_id.  It selects all the columns from the previous CTE, plus 
the next month’s name, and a CASE statement that counts all customers 
with a 5% closing monthly balance increase.
  
After all the CTEs are completed, we can answer our question.  We can
query the sum of the positive flags, divided by the count of the 
positive flags, multiply by one hundred, and round to two decimal 
places.  This will give us the percentage of customers who increase 
their closing balance by more than 5%.
*/
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		MONTHNAME(ct.txn_date) AS txn_month,
		ct.txn_date,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS value
	FROM
		customer_transactions AS ct
)
, balance_cte AS
(
	SELECT
		tv.customer_id,
		tv.txn_month,
		tv.txn_date,
		tv.value AS transaction_total,
		SUM(tv.value) OVER (PARTITION BY tv.customer_id ORDER BY tv.txn_date) AS running_sum,
		ROW_NUMBER() OVER (PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date DESC) AS row_num
	FROM 
		transaction_values_cte AS tv
	ORDER BY
		tv.txn_date
)
, prev_month_cte AS
(
	SELECT 
		b.customer_id,
		b.txn_month AS month_name,
		MONTHNAME(DATE_SUB(b.txn_date, INTERVAL 1 MONTH)) AS prev_month_name,
		b.running_sum AS closing_balance
	FROM 
		balance_cte AS b
	WHERE 
		b.row_num = 1
	ORDER BY
		b.customer_id, FIELD(b.txn_month, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December')
)
, percentage_cte AS
(
	SELECT
		p1.customer_id,
		p1.month_name,
		p1.closing_balance,
		p2.month_name AS next_month,
		p2.closing_balance AS next_month_closing_balance,
		(CASE
			WHEN (p2.closing_balance > p1.closing_balance AND 
				(p2.closing_balance - p1.closing_balance) / p1.closing_balance > 0.05) THEN 1 ELSE 0
		END) AS positive_flag
	FROM
		prev_month_cte AS p1
	INNER JOIN
		prev_month_cte AS p2
	ON
		p1.month_name = p2.prev_month_name
	AND 
		p1.customer_id = p2.customer_id
)
SELECT
	ROUND((SUM(positive_flag) / COUNT(positive_flag)) * 100, 2) AS pct_customers_with_increasing_balance
FROM
	percentage_cte;