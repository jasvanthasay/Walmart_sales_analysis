use walmart_db;
select * from walmart_cleaned_data limit 10;

select Branch, count(*) from walmart_cleaned_data group by Branch;

select count(distinct Branch) from walmart_cleaned_data;

-- Business Problem Q1: Find different payment methods, number of transactions, and quantity sold by payment method
select payment_method, count(*) as no_payments 
from walmart_cleaned_data 
group by payment_method ;

-- Project Question #2: Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating
with ranking as
( select Branch, category, avg(rating) as avg_rating,
rank() over (partition by Branch order by avg(rating) desc) as ranked
from walmart_cleaned_data
group by Branch, category)
select * from ranking where ranked=1;

-- Q3: Identify the busiest day for each branch based on the number of transactions
with dayrank as
( select branch, dayname(date) as day_name, count(*) as no_transactions,
rank() over(partition by branch order by count(*) desc) as ranked 
from walmart_cleaned_data
group by branch, day_name)
select * from dayrank where ranked=1;

SELECT branch, day_name, no_transactions
FROM (
    SELECT 
        branch,
        DAYNAME(STR_TO_DATE(date, '%d/%m/%Y')) AS day_name,
        COUNT(*) AS no_transactions,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS ranked
    FROM walmart_cleaned_data
    GROUP BY branch, day_name
) AS ranked_as
WHERE ranked = 1;

-- Q4: Calculate the total quantity of items sold per payment method
select payment_method, sum(quantity) as total_quantity
from walmart_cleaned_data
group by payment_method;

-- Q5: Determine the average, minimum, and maximum rating of categories for each city
select city, category,
		    AVG(rating) as average_rating,
            MIN(rating) as minimum_rating,
            MAX(rating) as maximum_rating
from walmart_cleaned_data
group by city, category
order by city;

-- Q6: Calculate the total profit for each category
select category, sum(total) as revenue, sum(total*profit_margin) as total_profit
from walmart_cleaned_data
group by category;

-- Q7: Determine the most common payment method for each branch
with pays as
( select branch, payment_method,count(*) as total_transaction,rank() over(partition by branch order by count(*) desc) as ranked
from walmart_cleaned_data
group by branch, payment_method)
select * from pays where ranked=1;

-- Q8: Categorize sales into Morning, Afternoon, and Evening shifts
select branch,
case when hour(time(time)) < 12 then 'Morning'
	 when hour(time(time)) between 12 and 17 then 'Afternoon'
     else 'Evening' end as shifts,
count(*) as no_invoices
from walmart_cleaned_data
group by branch, shifts
order by branch, no_invoices desc;

-- Q9: Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)
WITH revenue_2022 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart_cleaned_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2022
    GROUP BY branch
),
revenue_2023 AS (
    SELECT 
        branch,
        SUM(total) AS revenue
    FROM walmart_cleaned_data
    WHERE YEAR(STR_TO_DATE(date, '%d/%m/%Y')) = 2023
    GROUP BY branch
)
SELECT 
    r2022.branch,
    r2022.revenue AS last_year_revenue,
    r2023.revenue AS current_year_revenue,
    ROUND(((r2022.revenue - r2023.revenue) / r2022.revenue) * 100, 2) AS revenue_decrease_ratio
FROM revenue_2022 AS r2022
JOIN revenue_2023 AS r2023 ON r2022.branch = r2023.branch
WHERE r2022.revenue > r2023.revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;
 