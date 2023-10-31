# Case Study #5: Data Mart - Before And After Analysis Solutions

This technique is usually used when we inspect an important event and 
want to inspect the impact before and after a certain point in time.

Taking the week_date value of 2020-06-15 as the baseline week where 
the Data Mart sustainable packaging changes came into effect.

We would include all week_date values for 2020-06-15 as the start of 
the period after the change and the previous week_date values would be before.

Using this analysis approach - answer the following questions:

## 1. What is the total sales for the 4 weeks before and after 2020-06-15?  What is the growth or reduction rate in actual values and percentage of sales?
### Explanation
The clean_weekly_sales table has all the 
information we need.  The first step is to create a 
CTE, called week_classifier_cte, that creates one
additional column called time_classifier.  This
column uses a CASE statement and the DATE_SUB()
function to identify the four weeks before the 
change and the four weeks after the change.  

It's important to note that the DATE_SUB() function
allows for us to pick the specific date we want,
'2020-06-15', and apply simple keywords to get
the proper timeframes.  The first WHEN statement
inside our CASE statement subtracts four weeks
from the date.  And because the BETWEEN keyword
is inclusive, we must pick '2020-06-14' to make
sure that the proper dates are picked.

The second WHEN statement uses the DATE_ADD()
function to pick our date, and add 3 weeks.
Because BETWEEN is inclusive, this means that 
the count will start from the week of '2020-06-15',
so we only need three additional weeks to 
specify the correct timeframe.    

After building our CTE, we are ready to find
the answer.  The query uses two CASE statements 
to only add the sales with a "before_change" 
classifier in one column, and the sales with
the "after_change" classifier in the other 
column.  

We can add to this query to find the growth
or reduction rate and the percentage of sales.
This is done by creating a second CTE, called 
sales_cte, that sums sales based on each classifier.
Finally, we can query the second CTE to find
the change in sales, as well as the percent
change in sales.   

```SQL
-- Total sales for the 4 weeks before and after:
WITH week_classifier_cte AS
(
	SELECT
		*,
		(CASE
			WHEN week_date BETWEEN 
				DATE_SUB('2020-06-15', INTERVAL 4 WEEK) AND '2020-06-14' THEN 'before_change'
			WHEN week_date BETWEEN
				'2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 3 WEEK) THEN 'after_change'
			ELSE NULL
		END) AS time_classifier
	FROM 
		clean_weekly_sales
)
SELECT
	SUM(CASE
			WHEN w.time_classifier = 'before_change' THEN w.sales ELSE NULL
		END) AS sum_before_change,
	SUM(CASE
			WHEN w.time_classifier = 'after_change' THEN w.sales ELSE NULL
		END) AS sum_after_change
FROM
	week_classifier_cte AS w;


-- Growth or reduction rate in actual values and percentage of sales:
WITH week_classifier_cte AS
(
	SELECT
		*,
		(CASE
			WHEN week_date BETWEEN 
				DATE_SUB('2020-06-15', INTERVAL 4 WEEK) AND '2020-06-14' THEN 'before_change'
			WHEN week_date BETWEEN
				'2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 3 WEEK) THEN 'after_change'
			ELSE NULL
		END) AS time_classifier
	FROM 
		clean_weekly_sales
)
, sales_cte AS
(
	SELECT
		SUM(CASE
				WHEN w.time_classifier = 'before_change' THEN w.sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN w.time_classifier = 'after_change' THEN w.sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_classifier_cte AS w
)
SELECT
	(s.sum_after_change - s.sum_before_change) AS change_in_sales,
	ROUND((s.sum_after_change - s.sum_before_change) / s.sum_before_change * 100, 2) AS pct_change
FROM
	sales_cte AS s
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/ccb58f88-3ad5-4765-b0ad-1b8dc3900e9b)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/7b5e2817-aae5-463c-a211-a04946169926)


## 2. What about the entire 12 weeks before and after?
### Explanation
Explanation: The clean_weekly_sales table has all the 
information we need.  Because we solved the previous
problem with a non-specific method, we can solve this
problem by simply updating the parameters inside the 
DATE_SUB() and DATE_ADD() functions to count 12 weeks 
instead of four.

As a data analyst, we must strive to write elegant
solutions that can be easily adapted to solve future
problems.

```SQL
-- Total sales for the entire 12 weeks before and after:
WITH week_classifier_cte AS
(
	SELECT
		*,
		(CASE
			WHEN week_date BETWEEN 
				DATE_SUB('2020-06-15', INTERVAL 12 WEEK) AND '2020-06-14' THEN 'before_change'
			WHEN week_date BETWEEN
				'2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 11 WEEK) THEN 'after_change'
			ELSE NULL
		END) AS time_classifier
	FROM 
		clean_weekly_sales
)
SELECT
	SUM(CASE
			WHEN w.time_classifier = 'before_change' THEN w.sales ELSE NULL
		END) AS sum_before_change,
	SUM(CASE
			WHEN w.time_classifier = 'after_change' THEN w.sales ELSE NULL
		END) AS sum_after_change
FROM
	week_classifier_cte AS w;


-- Growth or reduction rate in actual values and percentage of sales:
WITH week_classifier_cte AS
(
	SELECT
		*,
		(CASE
			WHEN week_date BETWEEN 
				DATE_SUB('2020-06-15', INTERVAL 12 WEEK) AND '2020-06-14' THEN 'before_change'
			WHEN week_date BETWEEN
				'2020-06-15' AND DATE_ADD('2020-06-15', INTERVAL 11 WEEK) THEN 'after_change'
			ELSE NULL
		END) AS time_classifier
	FROM 
		clean_weekly_sales
)
, sales_cte AS
(
	SELECT
		SUM(CASE
				WHEN w.time_classifier = 'before_change' THEN w.sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN w.time_classifier = 'after_change' THEN w.sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_classifier_cte AS w
)
SELECT
	(s.sum_after_change - s.sum_before_change) AS change_in_sales,
	ROUND((s.sum_after_change - s.sum_before_change) / s.sum_before_change * 100, 2) AS pct_change
FROM
	sales_cte AS s
```

### Answer

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/ab99bef6-b1e8-4f9e-8b40-998591fbf2d9)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/165b79f4-027f-4294-99c9-b92f36cf1ede)


## 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
### Explanation
Explanation: The clean_weekly_sales table has all the 
information we need.  The approach we used on the first
two problems will not work because we indicate the day, 
month, and year on our parameters.  This makes it difficult
to apply our process to different years.  

After looking at our data, however, I realized that the 
sales data was similar throughout each year.  This means
that we can focus on the week_number column to specify
the specific weeks without specifying a specific year.
This allows us to select the calendar_year, week_number,
and the sum of sales, group by the calendar_year and 
week_number, and only filter out the week_numbers that
fit between the four weeks before and after our date, and
the 12 weeks before and after our date.    

By updating our approach to filter out the time, we are able
to easily find the sum in sales for each time period, as
well as the change in sales and percentage change across
each year.

```SQL
-- For 4 weeks
-- Total sales for the entire 4 weeks before and after:
WITH week_selection_cte AS
(
	SELECT 
		calendar_year,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 21 AND 28
	GROUP BY
		calendar_year, week_number
)
, week_classifier_cte AS
(
	SELECT
		w.calendar_year,
		SUM(CASE
				WHEN w.week_number BETWEEN 21 AND 24 THEN w.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN w.week_number BETWEEN 25 AND 28 THEN w.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS w
	GROUP BY
		w.calendar_year
)
SELECT 
	* 
FROM 
	week_classifier_cte;
	
-- For 4 weeks
-- Growth or reduction rate in actual values and percentage of sales:
WITH week_selection_cte AS
(
	SELECT 
		calendar_year,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 21 AND 28
	GROUP BY
		calendar_year, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.calendar_year,
		SUM(CASE
				WHEN ws.week_number BETWEEN 21 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 28 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.calendar_year
)
SELECT 
	wc.calendar_year,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/5246d2b7-7cfd-415d-8d98-b08c6f3795ef)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/ceeb6d70-0ff0-4cce-aacd-02f0a09387de)


```SQL
-- For 12 weeks
-- Total sales for the entire 12 weeks before and after:
WITH week_selection_cte AS
(
	SELECT 
		calendar_year,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		calendar_year, week_number
)
, week_classifier_cte AS
(
	SELECT
		w.calendar_year,
		SUM(CASE
				WHEN w.week_number BETWEEN 13 AND 24 THEN w.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN w.week_number BETWEEN 25 AND 36 THEN w.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS w
	GROUP BY
		w.calendar_year
)
SELECT 
	* 
FROM 
	week_classifier_cte;
	

-- For 12 weeks
-- Growth or reduction rate in actual values and percentage of sales:
WITH week_selection_cte AS
(
	SELECT 
		calendar_year,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		calendar_year, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.calendar_year,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.calendar_year
)
SELECT 
	wc.calendar_year,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/6732bcd5-ef00-4562-a892-aad5f1821462)

![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/d0625569-633e-4d34-929f-a1c1434b9257)
