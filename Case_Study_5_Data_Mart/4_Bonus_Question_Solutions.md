# Case Study #5: Data Mart - Bonus Question Solutions

## 1. Which areas of the business have the highest negative impact in sales metrics performance in 2020 for the 12 week before and after period?
* region
* platform
* age_band
* demographic
* customer_type

Do you have any further recommendations for Danny’s team at Data Mart 
or any interesting insights based off this analysis? 

### Explanation
The clean_weekly_sales table has all the 
information we need.  We can adapt the last query we used
on part 3 to answer each of these questions.  By simply
updating the calendar_year to a different dimension, we
can see how these changes affected each dimension.  Some
of the highlights include:

Region:
* Asia was the most negatively affected area after
implementing the change, with a 61,315,418 loss of 
sales, which amounts to a -1.33% change.
Platform:
* Retail was the most negatively affected dimension
after implementing the change, with a 117,464,107 
loss of sales, which amounts to a -0.59% change.
Age Band:
* Unknown was the most negatively affected dimension
after implementing the change, with a 44,645,418 loss
of sales, which amounts to a -0.55% change.
Demographic:
* Unknown was the most negatively affected dimension
after implementing the change, with a 44,645,418 loss
of sales, which amounts to a -0.55% change.
Customer Type:
* Existing was the most negatively affected dimension
after implementing the change, with a 51,510,403 loss
of sales, which amounts to a -0.51% change.

```SQL
-- region:
WITH week_selection_cte AS
(
	SELECT 
		region,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		region, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.region,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.region
)
SELECT 
	wc.region,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```

```SQL
-- platform:
WITH week_selection_cte AS
(
	SELECT 
		platform,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		platform, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.platform,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.platform
)
SELECT 
	wc.platform,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```	

```SQL
-- age_band:
WITH week_selection_cte AS
(
	SELECT 
		age_band,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		age_band, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.age_band,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.age_band
)
SELECT 
	wc.age_band,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```

```SQL
-- demographic: 
WITH week_selection_cte AS
(
	SELECT 
		demographic,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		demographic, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.demographic,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.demographic
)
SELECT 
	wc.demographic,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```	

```SQL
-- customer_type: 
WITH week_selection_cte AS
(
	SELECT 
		customer_type,
		week_number,
		SUM(sales) AS total_sales
	FROM
		clean_weekly_sales
	WHERE
		week_number BETWEEN 13 AND 36
	GROUP BY
		customer_type, week_number
)
, week_classifier_cte AS
(
	SELECT
		ws.customer_type,
		SUM(CASE
				WHEN ws.week_number BETWEEN 13 AND 24 THEN ws.total_sales ELSE NULL
			END) AS sum_before_change,
		SUM(CASE
				WHEN ws.week_number BETWEEN 25 AND 36 THEN ws.total_sales ELSE NULL
			END) AS sum_after_change
	FROM
		week_selection_cte AS ws
	GROUP BY
		ws.customer_type
)
SELECT 
	wc.customer_type,
	(wc.sum_after_change - wc.sum_before_change) AS change_in_sales,
	ROUND((wc.sum_after_change - wc.sum_before_change) / wc.sum_before_change * 100, 2) AS pct_change
FROM 
	week_classifier_cte AS wc;
```

Based on our results, we can produce the following 
recommendations:
Region:
* Although Asia had a negative reception to the changes,
Africa, our region with the most sales, was more receptive.
We should consider providing each region with the option to
choose their package.
Platform:
* Shopify customers were more receptive to these changes.
We should continue using the new packaging on this platform.
Customer Type:
* The negative change in existing and guest customers 
was not made up by the positive sales changes brought by
new customers.  If costs permit, we should allow for customers
to choose what type of packaging they want.
