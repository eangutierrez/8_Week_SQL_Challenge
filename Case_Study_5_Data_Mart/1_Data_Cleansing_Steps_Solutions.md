# Case Study #5: Data Mart - Data Cleansing Steps Solutions

## 1. In a single query, perform the following operations and generate a new table in the data_mart schema named clean_weekly_sales:
* Convert the week_date to a DATE format 
* Add a week_number as the second column for each week_date value, for example any value from the 1st of January to 7th of January will be 1, 8th to 14th will be 2 etc
* Add a month_number with the calendar month for each week_date value as the 3rd column
* Add a calendar_year column as the 4th column containing either 2018, 2019 or 2020 values
* Add a new column called age_band after the original segment column using the following mapping on the number inside the segment value
* Add a new demographic column using the following mapping for the first letter in the segment values
* Ensure all null string values with an "unknown" string value in the original segment column as well as the new age_band and demographic columns
* Generate a new avg_transaction column as the sales value divided by transactions rounded to 2 decimal places for each record

### Explanation
To clean the weekly_sales data and use its 
data to build another table, we can use a SELECT statement
with the CREATE TABLE keywords.  To begin, we 
need to create a CTE called clean_date_cte, that selects 
all the data from the wekly_sales table, and creates an 
additional column called clean_date.  This column will 
transform the date from a string to a date with the 
STR_TO_DATE function.  This first step will make the rest 
of our query easier.

With the CTE completed, we are ready to build the table.  
First, we select the clean_date column 
and rename  it to week_date.  Then, we extract the week of 
the year, the month number, and the calendar year from our 
date using the WEEKOFYEAR(), MONTH(), AND YEAR() functions.  
After choosing the region, platform, and segment columns, we
need to use CASE statements to build two additional columns, 
age_band and demographic, based on the question’s parameters.  
Finally, we select the rest of the columns, and round the 
quotient of sales and transactions to get the avg_transaction 
column.  I ordered the result by week_date, region, platform, 
and segment for presentation purposes.

Note: MySQL does not allow referring to a temporary table
more than once in the same query.  Therefore, creating and using
a temporary table limits our querying abilities 

```SQL
CREATE TABLE IF NOT EXISTS clean_weekly_sales AS
WITH clean_date_cte AS
(
	SELECT 
		*,
		STR_TO_DATE(week_date, '%e/%m/%y') AS clean_date
	FROM
		weekly_sales
)
SELECT
	cd.clean_date AS week_date,
	WEEKOFYEAR(cd.clean_date) AS week_number,
	MONTH(cd.clean_date) AS month_number,
	YEAR(cd.clean_date) AS calendar_year,
	cd.region,
	cd.platform,
	cd.segment,
	(CASE
		WHEN cd.segment = 'null' THEN 'unknown'
		WHEN RIGHT(cd.segment, 1) = 1 THEN 'Young Adults'
		WHEN RIGHT(cd.segment, 1) = 2 THEN 'Middle Aged'
		WHEN RIGHT(cd.segment, 1) IN (3, 4) THEN 'Retirees'
	END) AS age_band,
	(CASE
		WHEN cd.segment = 'null' THEN 'unknown'
		WHEN LEFT(cd.segment, 1) = 'C' THEN 'Couples'
		WHEN LEFT(cd.segment, 1) = 'F' THEN 'Families'
	END) AS demographic,
	cd.customer_type,
	cd.transactions,
	cd.sales,
	ROUND(cd.sales / cd.transactions, 2) AS avg_transaction
FROM
	clean_date_cte AS cd
ORDER BY 
	cd.week_date, cd.region, cd.platform, cd.segment;
```
