# Case Study #5: Data Mart - Data Exploration Solutions

## 1. What day of the week is used for each week_date value?
### Explanation
The clean_weekly_sales table has all the 
information we need.  We can use the DAYNAME() function with 
the DISTINCT keyword to find what day of the week is used
for each week_date value.  The answer is Monday. 

```SQL
SELECT 
	DISTINCT DAYNAME(week_date)
FROM
	clean_weekly_sales;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/0e54eb9d-c5d4-485d-9445-4038cb912874)


## 2. What range of week numbers are missing from the dataset?
### Explanation
The clean_weekly_sales table has all the 
information we need.  The first step is to create a 
recursive CTE that contains one column called value.
After selecting 1 as the value, we use the UNION ALL
keywords to stack another set on top of this 1.  The
WHERE clause will limit to 52, which is the maximum 
number of weeks in a year.

After building our recursive CTE, we are ready to
answer the question.  We will begin by selecting
the value column from the recursive CTE, and use
the WHERE clause to filter out all the values that
are not in a subquery.  This subquery will find
all the distinct week numbers from the 
clean_weekly_sales table.

```SQL
WITH RECURSIVE seq AS 
(
	SELECT 
		1 AS value
	UNION ALL
	SELECT
		value + 1
	FROM
		seq
	WHERE
		value < 52
)
SELECT 
	s.value AS missing_week_numbers
FROM 
	seq AS s
WHERE 
	value NOT IN
	(
		SELECT 
			DISTINCT week_number
		FROM 
			clean_weekly_sales
	);
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/d2f5bcef-31ed-44d0-b6fc-b1af9152e5d1)


## 3. How many total transactions were there for each year in the dataset?
### Explanation
The clean_weekly_sales table has all the 
information we need.  After selecting our table and 
grouping by the calendar_year, we can select the 
calendar_year column and the sum of the transactions
to find our answer.

```SQL
SELECT
	calendar_year,
	SUM(transactions)
FROM
	clean_weekly_sales
GROUP BY
	calendar_year;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/28b4e311-cd62-4b1f-9099-3dbefdadb55b)


## 4. What is the total sales for each region for each month?
### Explanation
The clean_weekly_sales table has all the 
information we need.  After selecting our table and
grouping by region and month_number, we can select
the region, use the MONTHNAME() function to find the
name of the month for each transaction, and the sum
of sales to find our answer.

```SQL
SELECT
	region,
	MONTHNAME(week_date) AS month_name,
	SUM(sales)
FROM
	clean_weekly_sales
GROUP BY
	region, month_number;
```

### Answer
Note: This is only part of the whole table.  The final table has 49 records.

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/62e55ed1-9ab8-4483-8fc1-6ab7f0f30734)


## 5. What is the total count of transactions for each platform?
### Explanation
The clean_weekly_sales table has all the 
information we need.  After selecting our table and
grouping by platform, we can select the platform and
sum of transactions to find our answer.

```SQL
SELECT
	platform,
	SUM(transactions) AS number_of_transactions
FROM
	clean_weekly_sales
GROUP BY
	platform;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/6ad413c6-ac86-4956-b91e-cd89ab3f12ea)


## 6. What is the percentage of sales for Retail vs Shopify for each month?
### Explanation
The clean_weekly_sales table has all the 
information we need.  The first step is to create a 
CTE called sales_cte, that selects the calendar_year,
month_number, the month name, the platform, 
selecting our table, and three CASE statements to
find the total sales for Retail, Shopify, and the 
sum of the sum of sales partitioned by calendar_year
and month.  These CASE statements will make our final
query a lot easier.  Note that we must group by the 
first three columns to complete the CTE.

After building our CTE, we are ready to answer the
question.  The answer should include the calendar_year,
the month, a column that finds the percentage of retail
sales, and another column that calculates the percentage
of shopify sales.

```SQL
WITH sales_cte AS
(
SELECT
	calendar_year,
	month_number,
	MONTHNAME(week_date) AS month,
	platform,
	SUM(CASE
			WHEN platform = 'Retail' THEN sales ELSE NULL
		END) AS retail_sales,
	SUM(CASE
			WHEN platform = 'Shopify' THEN sales ELSE NULL
		END) AS shopify_sales,
	SUM(SUM(sales)) OVER(PARTITION BY calendar_year, month_number) AS monthly_total
FROM
	clean_weekly_sales
GROUP BY
	calendar_year, month_number, MONTHNAME(week_date)
)
SELECT
	s.calendar_year,
	s.month,
	ROUND(s.retail_sales / s.monthly_total * 100, 2) AS retail_pct,
	ROUND(s.shopify_sales / s.monthly_total * 100, 2) AS shopify_pct
FROM
	sales_cte AS s;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/5779f846-15f5-49c3-96c5-f17afba190f3)


## 7. What is the percentage of sales by demographic for each year in the dataset?
### Explanation
The clean_weekly_sales table has all the 
information we need.  We can use a process similar to
the one from question 6.  The first step is to create a 
CTE called yearly_sales_cte, that selects the calendar_year,
demographic, and four CASE statements to
find the total sales for couples, families, unknown, and
the sum of the sum of sales partitioned by calendar_year  
These CASE statements will make our final
query a lot easier.  Note that we must group by the 
calendar_year only to complete the CTE.  The combination of
the CASE statements and grouping by the calendar_year alone
creates a data table in wide format, that contains no
NULL values.

With our CTE completed, we can query our answer. The
solution includes the calendar year, three columns that
calculate the percentage of sales per demographic.    

```SQL
WITH yearly_sales_cte AS
(
	SELECT 
		calendar_year,
		demographic,
		SUM(CASE
				WHEN demographic = 'Couples' THEN sales ELSE NULL
			END) AS sum_couples,
		SUM(CASE
				WHEN demographic = 'Families' THEN sales ELSE NULL
			END) AS sum_families,
		SUM(CASE
				WHEN demographic = 'unknown' THEN sales ELSE NULL
			END) AS sum_unknown,
		SUM(SUM(sales)) OVER(PARTITION BY calendar_year) AS yearly_total
	FROM
		clean_weekly_sales
	GROUP BY
		calendar_year
)
SELECT
	y.calendar_year,
	ROUND(y.sum_couples / y.yearly_total * 100, 2) AS pct_couples,
	ROUND(y.sum_families / y.yearly_total * 100, 2) AS pct_families,
	ROUND(y.sum_unknown / y.yearly_total * 100, 2) AS pct_unknown
FROM yearly_sales_cte AS y;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/252e01b7-89c5-4907-a0c8-efbd35d2cf12)


## 8. Which age_band and demographic values contribute the most to Retail sales?
### Explanation
The clean_weekly_sales table has all the 
information we need.  After choosing our table, we need 
to filter for all the 'Retail' records in the WHERE clause.
After grouping by both age_band and demographic, we can 
select the pertinent columns to answer the question.  The
solution should include the age_band, demographic, the sum
of sales, and a column that calculates the sum of sales 
divided by the total sum of sales, multiplies by 100, and 
rounds to two decimal places.  This calculation is the 
percentage of contribution to sales.  

```SQL
SELECT 
	age_band,
	demographic, 
	SUM(sales),
	ROUND(100 * SUM(sales) / 
		(
			SELECT
				SUM(sales)
			FROM
				clean_weekly_sales
			WHERE
				platform = 'Retail'
		), 2) AS pct
FROM
	clean_weekly_sales
WHERE
	platform = 'Retail'
GROUP BY 
	age_band, demographic
ORDER BY
	4 DESC;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/06a6d0fe-4988-4e03-b6d9-6ff48e09f7a7)


## 9.  Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
### Explanation
The clean_weekly_sales table has all the 
information we need.  After choosing our table and grouping 
by calendar_year and platform, we are ready to finalize
the query.  The answer should include the calendar_year, 
platform, the average function on the avg_transaction column,
and the sum of the sales divided by the sum of the 
transactions.  The answer clearly shows that we can't use
the avg_transaction column.  The average of averages is 
generally not accurate.  A better practice is to divide 
after finding the individual sums.

```SQL
SELECT
	calendar_year,
	platform,
	ROUND(AVG(avg_transaction), 2) AS avg_using_column,
	ROUND(SUM(sales) / SUM(transactions), 2) AS avg_calculation
FROM
	clean_weekly_sales
GROUP BY
	calendar_year, platform;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/5ba8ee8e-fd38-4f76-916c-de52271fdea3)
