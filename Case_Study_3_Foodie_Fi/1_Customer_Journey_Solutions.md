# Case Study #3: Foodie Fi - Customer Journey Solutions

## 1. Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.  Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
### Explanation
The subscriptions and plans tables have all 
the information we need.  The sample table shows all the
records for customer 1, 2, 11, 13, 15, 16, 18, and 19.  These customers' onboarding journey is explained below: 
 
#### **Customer 1**
The customer started the weekly trial plan on 
08/01/2020 and the customer chose to enroll in 
the basic monthly plan after the weekly trial 
expired on 08/08/2020.

#### **Customer 2**
The customer started the weekly trial plan on 
09/20/2020 and the customer chose to enroll in
the pro annual plan after the weekly trial 
expired on 09/27/2020.

#### **Customer 11**
The customer started the weekly trial plan on
11/19/2020 and customer chose not to enroll in
any plan after the weekly trial expired on 
11/26/2020. 

#### **Customer 13**
The customer started the weekly trial plan on
12/15/2020. The customer chose to enroll in the
basic monthly plan after the weekly trial expired
on 12/22/2020.  Then, the customer chose to enroll 
in the pro monthly plan on 03/29/2021.

#### **Customer 15**
The customer started the weekly trial plan on
03/17/2020. The customer chose to enroll in the 
pro monthly plan after the weekly trial expired
on 03/24/2020.  Then, the customer chose to cancel
their plan on 04/29/2020.

#### **Customer 16**
The customer started the weekly trial on 
05/31/2020. The customer chose to enroll in the 
basic monthly plan after the weekly trial expired
on 06/07/2020.  Then, the customer chose to 
enroll in the pro annual plan on 10/21/2020

#### **Customer 18**
The customer started the weekly trial on 
07/06/2020, and then chose to enroll in the 
pro monthly plan on 07/13/2020.

#### **Customer 19**
The customer started the weekly trial on
06/22/2020. The customer then enrolled in the
pro monthly plan after the weekly trial expired
on 06/29/2020.  Then, the customer enrolled in 
the pro annual plan on 08/29/2020.

#### Query: 

```SQL
-- Query that shows the specific customer journeys:
SELECT 
	s.customer_id,
	s.plan_id,
	p.plan_name,
	p.price,
	s.start_date
FROM 
	subscriptions AS s
LEFT JOIN 
	plans AS p
ON
	s.plan_id = p.plan_id
WHERE
	s.customer_id IN (1, 2, 11, 13, 15, 16, 18, 19);
```

### Answer
![image](https://github.com/eangutierrez/8_Week_SQL_Challenge/assets/92600212/94c21957-d3df-4e8d-8a0b-b44604637f5a)
