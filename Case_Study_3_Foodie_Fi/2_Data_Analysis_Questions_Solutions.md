# Case Study #3: Foodie Fi - Data Analysis Questions & Solutions

## 1. How many customers has Foodie-Fi ever had?
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we
simply need to use the COUNT(DISTINCT) function to find
the total number of unique customer_ids in the database.

```SQL
SELECT 
	COUNT(DISTINCT s.customer_id) AS total_customers 
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
ORDER BY
	s.customer_id, s.start_date;
```

## 2. What is the monthly distribution of trial plan start_date values for our dataset?  Use the start of the month as the group by value
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must exclude the records of all trial_plan members. After
grouping by month, we need to create two columns.  First,
we will use the MONTHNAME() function to find the specific
month name of all start_dates.  Second, we need to count
the total number of new trial plans per month. 

```SQL
SELECT 
	MONTHNAME(s.start_date) AS month_name,
	COUNT(s.customer_id) AS new_trial_plan_customers
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
WHERE 
	s.plan_id = 0
GROUP BY
	month_name
ORDER BY
	FIELD(month_name, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December');
```
	
## 3. What plan start_date values occur after the year 2020 for our dataset?  Show the breakdown by count of events for each plan_name
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must exclude the records that occur after the year 2020. 
After grouping by plan_name, we can select the columns
for our answer.  We need the plan_id, the plan_name, and
the total count of plans by plan_name. 

```SQL
SELECT 
	p.plan_id,
	p.plan_name,
	COUNT(p.plan_name) AS total_plans_after_2020
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
WHERE 
	YEAR(s.start_date) > 2020
GROUP BY 
	p.plan_name
ORDER BY
	p.plan_id;
```

## 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must find the total count of distinct customer_ids and 
the total count of churn instances.  After finding both
results, we can use this query as a CTE.  After updating
the CTE, we can query the total number of churn instances
and the percent of the total number of churn instances.  
I have provided a CTE version and a non-CTE version for
reference.  

```SQL
-- CTE version
WITH churn_instances_cte AS
(
	SELECT
		COUNT(DISTINCT s.customer_id) AS total_customers,
		SUM(CASE
				  WHEN s.plan_id = 4 THEN 1 ELSE 0
		    END) AS total_churn_instances
	FROM
		subscriptions AS s
)
SELECT 
	c.total_churn_instances,
	ROUND((c.total_churn_instances * 100) / c.total_customers, 1) AS pct_of_churn_instances
FROM 
	churn_instances_cte AS c


-- Finished Version
SELECT 
	COUNT(p.plan_name) AS total_churn_instances,
	ROUND(100 * COUNT(s.customer_id) / (SELECT COUNT(DISTINCT customer_id)
                                        FROM subscriptions), 1) AS churn_pct
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
WHERE
	s.plan_id = 4
GROUP BY 
	p.plan_name
ORDER BY
	p.plan_id;
```

## 5. How many customers have churned straight after their initial free trial?  What percentage is this rounded to the nearest whole number?
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must create a new column that ranks we over the 
subscription start_date, partitioned by the customer_id. 
This will allow us to identify the customers who churned
after the trial period expired.  We can use that query as
a CTE called customer_journey_cte.  Then we can create
another CTE called aggregates_cte that finds the total
number of customers and the total number of customers
who churned after the trial period expired.  With both
of the CTEs created, we build an answer that has the
total number of customers who churned after their 
trial expired, and the percentage of those customers

```SQL
WITH customer_journey_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		p.price,
		s.start_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS row_num
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
)
, aggregates_cte AS
(
	SELECT
		COUNT(DISTINCT c.customer_id) AS total_customers,
		SUM(CASE
          WHEN c.row_num = 2 AND c.plan_id = 4 THEN 1 ELSE 0
		    END) AS total_churn_instances
	FROM
		customer_journey_cte AS c
)
SELECT 
	a.total_churn_instances,
	(a.total_churn_instances * 100) / a.total_customers AS pct
FROM 
	aggregates_cte AS a;
```

## 6. What is the number and percentage of customer plans after their initial free trial?
### Explanation
The subscriptions and plans tables have all 
the information we need.  We can use the CTE of question
5 as the base of this solution.  After creating our CTE, 
we filter by the second row to find each customer action
after the trial week expired.  We select the plan_name,
the total count of all the customer_ids, and the percentage
of total count of all customer_ids from the total customers,
grouped by the plan_name.   

```SQL
WITH customer_journey_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		p.price,
		s.start_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS row_num
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
)
SELECT 
	c.plan_name,
	COUNT(c.customer_id) AS total_plans,
	ROUND((COUNT(c.customer_id) / (SELECT 
                                   COUNT(DISTINCT customer_id)
								                 FROM 
								   	               customer_journey_cte) * 100), 1) AS pct
FROM
	customer_journey_cte AS c
WHERE 
	c.row_num = 2
GROUP BY
	c.plan_name
ORDER BY
	c.plan_id;
```

## 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must exclude the records of all trial_plan members. After
grouping by month, we need to create two columns.  First,
we will use the MONTHNAME() function to find the specific
month name of all start_dates.  Second, we need to count
the total number of new trial plans per month. 

```SQL
WITH customer_journey_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		p.price,
		s.start_date,
		ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.start_date DESC) AS row_num
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE
		s.start_date <= '2020-12-31'
)
SELECT 
	c.plan_name,
	COUNT(c.customer_id) AS total_plans,
	ROUND((COUNT(c.customer_id) / (SELECT 
								   	               COUNT(DISTINCT customer_id)
                                 FROM 
								   	               customer_journey_cte) * 100), 1) AS pct
FROM
	customer_journey_cte AS c
WHERE
	c.row_num = 1
GROUP BY
	c.plan_name
ORDER BY
	c.plan_id;
```
	
## 8. How many customers have upgraded to an annual plan in 2020?
### Explanation
The subscriptions and plans tables have all 
the information we need.  After joining the tables, we 
must exclude the records where the plan_name is pro annual
and where the year is 2020. Our answer must include the 
plan_name and the total count of all customer_ids.

```SQL
SELECT 
	p.plan_name,
	COUNT(s.customer_id) AS total_plans
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
WHERE
	YEAR(s.start_date) = 2020 AND p.plan_name = 'pro annual';
```

## 9.  How many days on average does it take for a customer to go to an annual plan from the day they join Foodie-Fi?
### Explanation
The subscriptions and plans tables have all 
the information we need.  First, we must build two CTEs.
Each CTE will find the customer_id, plan_id, plan_name, 
and start_date.  The difference between these two CTEs
is that one will find all the information for the trial
plans, and the other will find all the information for
the pro annual plans.  After building both CTEs, we are
ready to find the answer.  We will join both CTEs by 
customer_id, then we will find the plan_id, plan_name,
and the average of the date difference between both
start_dates.  This will give us the average number of
days it took for customers to enroll in the pro annual
plan.  

```SQL
WITH trial_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE 
		p.plan_name = 'trial'
)
, pro_annual_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE 
		p.plan_name = 'pro annual'
)
SELECT
	p.plan_id,
	p.plan_name,
	ROUND(AVG(DATEDIFF(p.start_date, t.start_date)), 2) AS avg_days
FROM
	trial_cte AS t
INNER JOIN
	pro_annual_cte AS p
ON
	t.customer_id = p.customer_id;
```

## 10. Can you further breakdown this average value into 30 day periods?  (i.e. 0-30 days, 31-60 days etc)
### Explanation
This answer to this question is built up 
from the answer of question 9.  It has an addtional 
CTE called window_cte, that combines the data of the
previous CTEs, calculates the difference between both
start_dates, and creates a 30-day time window.  After 
building the three CTEs, we can create a case statement
to show the 30-day windows, count the total number of
customers, and get the average number of days it took
for a customer to switch to an annual plan in 30-day
time intervals.  

```SQL
WITH trial_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE 
		p.plan_name = 'trial'
)
, pro_annual_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE 
		p.plan_name = 'pro annual'
)
, window_cte AS
(
	SELECT
		t.*,
		p.customer_id AS pcustomer_id,
		p.plan_id AS pplan_id,
		p.plan_name AS pplan_name,
		p.start_date AS pstart_date,
		DATEDIFF(p.start_date, t.start_date) AS diff,
		ROUND(DATEDIFF(p.start_date, t.start_date) / 30) AS 30_day_wdw
	FROM 
		trial_cte AS t
	INNER JOIN
		pro_annual_cte AS p
	ON
		t.customer_id = p.customer_id
)
SELECT
	(CASE
		WHEN w.30_day_wdw = 0 THEN '0 - 30 days'
		WHEN w.30_day_wdw = 1 THEN '31 - 60 days'
		WHEN w.30_day_wdw = 2 THEN '61 - 90 days'
		WHEN w.30_day_wdw = 3 THEN '91 - 120 days'
		WHEN w.30_day_wdw = 4 THEN '120 - 150 days'
		WHEN w.30_day_wdw = 5 THEN '151 - 180 days'
		WHEN w.30_day_wdw = 6 THEN '181 - 210 days'
		WHEN w.30_day_wdw = 7 THEN '211 - 240 days'
		WHEN w.30_day_wdw = 8 THEN '241 - 270 days'
		WHEN w.30_day_wdw = 9 THEN '271 - 300 days'
		WHEN w.30_day_wdw = 10 THEN '301 - 330 days'
		WHEN w.30_day_wdw = 11 THEN '331 - 360 days'
		ELSE NULL
	END) AS time_window,
	COUNT(w.customer_id) AS total_customers,
	AVG(diff) AS avg_days_to_upgrade
FROM
	window_cte AS w
WHERE
	w.30_day_wdw IS NOT NULL
GROUP BY
	w.30_day_wdw
ORDER BY
	w.30_day_wdw;
```

## 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
### Explanation
The subscriptions and plans tables have all 
the information we need.  We must build a CTE called 
pro_monthly_cte, that filters all the records that
start in the year 2020.  This CTE finds the customer_id,
the plan_id, the plan_name, the start_date, and uses
the LEAD() function to fetch the next row's plan_id.
Once the CTE is completed, we can query this CTE to 
find our answer.  We must filter out the records whose
plan_id is 2 and the next_plan_id is 1.  These plan_ids
correspond to customers downgrading from the pro_monthly
plan to the basic_monthly plan.   

```SQL
WITH pro_monthly_cte AS
(
	SELECT 
		s.customer_id,
		s.plan_id,
		p.plan_name,
		s.start_date,
		LEAD(p.plan_id) OVER(PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_id
	FROM 
		subscriptions AS s
	LEFT JOIN 
		plans AS p
	ON
		s.plan_id = p.plan_id
	WHERE 
		YEAR(s.start_date) = 2020 
)
SELECT
	COUNT(p.customer_id) AS total_customers_who_downgraded
FROM
	pro_monthly_cte AS p
WHERE
	p.plan_id = 2
AND
	p.next_plan_id = 1;
```
