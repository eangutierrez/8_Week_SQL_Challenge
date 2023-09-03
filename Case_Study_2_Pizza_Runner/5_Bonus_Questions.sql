/* --------------------
   Case Study Questions
   --------------------*/

-- 1. If Danny wants to expand his range of pizzas - how would this impact the existing data design? 
-- Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the 
-- toppings was added to the Pizza Runner menu?
/* 
Explanation: To add an additional pizza, the pizza_names and 
pizza_recipes tables from the original design would be affected.
The pizza_names table would have an additional row, with a 
pizza_id of 3 and a pizza_name of 'Supreme.'  In the original
data design, the pizza_recipes table consisted of two columns,
pizza_id and toppings.  This table only had two rows because
it was not normalized, as the toppings table contained the 
comma-separated values of individual topping_ids, representing
the combination of toppings for each recipe.

I will provide two solutions to this problem.  Solution #1 will
provide an unormalized version of the pizza_recipes table, in 
case leadership wants to keep the original table design.
Solution # 2 will provide a normalized version of the table, in
case leadership wants to simplify the original data design.
*/
-- Update pizza_names table:
INSERT INTO pizza_names 
VALUES (3, 'Supreme');

-- Verify pizza_names table has updated:
SELECT
	*
FROM
	pizza_names;


-- Update unnormalized pizza_recipes table: 
INSERT INTO pizza_recipes 
VALUES (3, (SELECT
				GROUP_CONCAT(topping_id SEPARATOR ', ')
			FROM
				pizza_toppings));

			
-- Update normalized pizza_recipes table: 
INSERT INTO pizza_recipes 
VALUES (3, 1),
	   (3, 2),
	   (3, 3),
	   (3, 4),
	   (3, 5),
	   (3, 6),
	   (3, 7),
	   (3, 8),
	   (3, 9),
	   (3, 10),
	   (3, 11),
	   (3, 12);