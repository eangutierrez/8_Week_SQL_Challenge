# Case Study #4: Data Bank - Data Allocation Challenge Solutions

## 1. Using all of the data available - how much data would have been required for each option on a monthly basis?
To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time

For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

* running customer balance column that includes the impact each transaction
* customer balance at the end of each month
* minimum, average and maximum values of the running balance for each customer

Using all of the data available - how much data would have been required for each option on a monthly basis
### Explanation
#### Data Elements
The data elements will be set the foundation of each of the
answers.  To create a running customer balance column, we need to create 
a case statement that either takes the transaction amount from the 
txn_amount column when a deposit occurs or multiplies the transaction 
amount by negative one when a purchase or a withdrawal occur.  We can put 
that query in a CTE to create an additional column to calculate the 
running_customer_balance.  This column is the sum of the transaction value 
partitioned by customer_id and ordered by the transaction date.  There are 
several customers who have multiple transactions on the same day.  We 
should use the ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW keywords 
to ensure that the calculation applies row by row, and not just the sum 
repeated over several records.  

To create the customer balance at the end of the month, we can build on the 
CTE we created for the first data element.  This CTE, called 
running_balance_cte, will take the sum of the transaction value, but it will 
partition by both customer_id and transaction month.  Finally, we will create 
a column with the record number partitioned by both the customer_id and the 
transaction month.  Additionally, we will order by the transaction date in 
descending order to ensure that the last record always has a number of 1.

To create the minimum, average, and maximum amounts of the running balance for 
each customer, we can build on the two CTEs for the second data element with a 
minor adjustment.  We need to only partition by the customer id, and order by 
the transaction date with the keywords ROWS BETWEEN UNBOUNDED PRECEDING AND 
CURRENT ROW.  This will ensure that sum calculation applies row by row, and not 
just the sum repeated over several records where there are multiple customer 
transactions per day.
```SQL
-- Data Elements:
-- A: Running Customer Balance Column:
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS  txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
)
SELECT
	tv.*,
	SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id 
		ORDER BY tv.txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_customer_balance
FROM 
	transaction_values_cte AS tv;


-- B: Customer Balance at the end of the Month:
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS  txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
)
, running_balance_cte AS
(
	SELECT
		tv.*,
		SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date) AS running_monthly_customer_balance,
		ROW_NUMBER() OVER(PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date DESC) AS row_num
	FROM 
		transaction_values_cte AS tv
)
SELECT
	rb.customer_id,
	rb.txn_date,
	rb.txn_month,
	rb.running_monthly_customer_balance AS customer_balance_at_end_of_month
FROM
	running_balance_cte AS rb
WHERE
	rb.row_num = 1	
GROUP BY
	rb.customer_id, rb.txn_month;


-- C: Minimum, Average, and Maximum Values of the Running Balance for Each Customer:
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS  txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
)
, running_balance_cte AS
(
	SELECT
		tv.*,
		-- Use rows between unbounded preceding and current row to maintain original values throughout the sum calculation
		SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id 
			ORDER BY tv.txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_customer_balance
	FROM 
		transaction_values_cte AS tv
)
SELECT
	rb.customer_id,
	MIN(rb.running_customer_balance) AS min_value,
	AVG(rb.running_customer_balance) AS avg_value,
	MAX(rb.running_customer_balance) AS max_value
FROM
	running_balance_cte AS rb
GROUP BY
	rb.customer_id;
```	
##### Answer
Note: these tables only show part of the records.  The actual tables are much longer


![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/dceb85bb-f4dc-4fc5-a2c2-3bf2b90b06df)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/c3110edd-a7be-4206-b43a-021268ba403c)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/19d054ac-6dd9-45b5-a5c5-e80a13037c03)


The three data elements will help us find monthly totals to know how many data 
units are needed to be provisioned for each option:

#### Option 1
For option 1: we can use the two CTEs from data element two as base to create 
a new CTE, monthly_balance_cte, that groups the data by customer_id and 
transaction month, filters all the records with a row number of 1, and selects 
all the information from the table.  With all the CTEs completed, we can select
the month name for each transaction and sum the running balance of all customers 
only if it is greater than zero, because there are customers with a negative 
running balance.
```SQL
-- Option 1: data is allocated based off the amount of money at the end of the previous month
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS  txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
)
, running_balance_cte AS
(
	SELECT
		tv.*,
		SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id 
			ORDER BY tv.txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance,
		ROW_NUMBER() OVER(PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date DESC) AS row_num
	FROM 
		transaction_values_cte AS tv
)
, monthly_balance_cte AS
(
	SELECT
		rb.*
	FROM
		running_balance_cte AS rb
	WHERE
		rb.row_num = 1	
	GROUP BY
		rb.customer_id, rb.txn_month
)
SELECT 
	MONTHNAME(mb.txn_date),
	-- SUM(IF)) accounts for customers who carry a negative balance on their accounts
	SUM(IF(mb.running_balance > 0, mb.running_balance, 0)) AS data_req 
FROM 
	monthly_balance_cte AS mb
GROUP BY
	mb.txn_month
ORDER BY
	mb.txn_month;
```

##### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/430fed3e-a73d-4bc0-b29e-20227f3296ec)


#### Option 2
For option 2, we can use the two CTEs from data element two as a base to create 
a new CTE, avg_balance_cte, that gets the average running balance partitioned by 
customer_id and ordered by the transaction date with the keywords ROWS BETWEEN 
UNBOUNDED PRECEDING AND CURRENT ROW to ensure the average calculation is applied 
row by row.  After completing the CTEs, we can group by transaction month, filter 
the last records on the running monthly average, and sum this number.
```SQL
-- Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS  txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
)
, running_balance_cte AS
(
	SELECT
		tv.*,
		SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id 
			ORDER BY tv.txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance,
		ROW_NUMBER() OVER(PARTITION BY tv.customer_id, tv.txn_month ORDER BY tv.txn_date DESC) AS row_num
	FROM 
		transaction_values_cte AS tv
)
, avg_balance_cte AS
(
	SELECT
			rb.*,
			AVG(rb.running_balance) OVER(PARTITION BY rb.customer_id 
				ORDER BY rb.txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS monthly_avg
	FROM
		running_balance_cte AS rb
)
SELECT
	MONTHNAME(am.txn_date),
	ROUND(SUM(am.monthly_avg))
FROM
	avg_balance_cte AS am
WHERE
	am.row_num = 1
GROUP BY
	am.txn_month
ORDER BY
	am.txn_date;
```

##### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/9eb80f00-72c0-40a4-9814-10782b903792)


#### Option 3
For option 3, we can use the two CTEs from data element two as base.  To query 
the final answer, we would need the month name and the sum of the running 
customer balance. 

```SQL
-- Option 3: data is updated real-time
WITH transaction_values_cte AS
(
	SELECT 
		ct.customer_id,
		ct.txn_date,
		MONTH(ct.txn_date) AS txn_month,
		ct.txn_type,
		ct.txn_amount,
		(CASE
			WHEN ct.txn_type = 'deposit' THEN ct.txn_amount ELSE ct.txn_amount * -1
		END) AS txn_value
	FROM 
		customer_transactions AS ct
	ORDER BY
		customer_id, txn_date
)
, running_customer_balance_cte AS
(
	SELECT
		tv.*,
		SUM(tv.txn_value) OVER(PARTITION BY tv.customer_id 
			ORDER BY tv.txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_customer_balance
	FROM
		transaction_values_cte AS tv
)
SELECT 
	MONTHNAME(rc.txn_date),
	SUM(rc.running_customer_balance) AS data_req
FROM 
	running_customer_balance_cte AS rc 
GROUP BY
	rc.txn_month
ORDER BY 
	rc.txn_date;
```

##### Answer 
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/377f55fd-8a2a-4ef1-9842-7d15887d10e7)
