create database sql2mini;
use sql2mini;
#1. Join all the tables and create a new table called combined_table.
#(market_fact, cust_dimen, orders_dimen, prod_dimen, shipping_dimen)

CREATE TABLE combined_table AS
SELECT 
	market.Ord_id, market.Prod_id, market.Ship_id, market.Cust_id, Sales, 
    Discount, Order_Quantity, Profit, Shipping_Cost, Product_Base_Margin, 
    cust.Customer_Name, cust.Province, cust.Region, cust.Customer_Segment, 
    orders.Order_Date, orders.Order_Priority, prod.Product_Category, 
    prod.Product_Sub_Category, orders.Order_ID, ship.Ship_Mode, ship.Ship_Date
FROM
    market_fact AS market
CROSS JOIN
	cust_dimen AS cust ON market.Cust_id = cust.Cust_id
CROSS JOIN
	orders_dimen AS orders ON orders.Ord_id = market.Ord_id
CROSS JOIN
	prod_dimen AS prod ON prod.Prod_id = market.Prod_id
CROSS JOIN
	shipping_dimen AS ship ON ship.Ship_id = market.Ship_id;

#  2. Find the top 3 customers who have the maximum number of orders
select Customer_Name,Cust_id from cust_dimen where Cust_id in(
select Cust_id from market_fact group by Cust_id order by count(Ord_id) desc)  limit 3;

#3. Create a new column DaysTakenForDelivery that contains the date difference of Order_Date and Ship_Date.
select o.Order_ID ,o.Order_Date,s.Ship_Date , datediff(s.Ship_Date,o.Order_Date) as DaysTakenForDelivery  from 
orders_dimen as o 
join 
shipping_dimen as s 
on o.Order_ID=s.Order_ID 
order by DaysTakenForDelivery desc ;



#4. Find the customer whose order took the maximum time to get delivered.
select c.Cust_id, c.Customer_Name, o.Order_ID ,o.Order_Date,s.Ship_Date , 
datediff(s.Ship_Date,o.Order_Date) as DaysTakenForDelivery  from 
cust_dimen as c 
join market_fact as m 
on c.cust_id=m.Cust_id
join
orders_dimen as o
on m.Ord_id=o.Ord_id
join shipping_dimen as s  
on o.Order_ID=s.Order_ID 
order by DaysTakenForDelivery desc limit 1  ;

#5. Retrieve total sales made by each product from the data (use Windows function)
select distinct Prod_id, sum(Sales) over(partition by Prod_id ) Total_sales from market_fact order by Total_sales desc;

#6. Retrieve total profit made from each product from the data (use windows function)
select distinct Prod_id, sum(Profit) over(partition by Prod_id) Total_Profit from market_fact order by Total_Profit desc;

#7.Count the total number of unique customers in January 
#and how many of them came back every month over the entire year in 2011
select   o.Order_Date,count(distinct m.cust_id) No_of_Returning_Customers from 
market_fact as m 
join 
orders_dimen as o 
on m.Ord_id=o.Ord_id
where year(Order_date) = '2011'
group by month(Order_date);

#8. Retrieve month-by-month customer retention rate since the start of the business.(using views)
with mon_cus as (
select distinct m.Cust_id, 
month(str_to_date(o.Order_Date, '%Y-%m-%d')) mon,
count(Cust_id) over(partition by m.Cust_id) rep
from orders_dimen o join 
market_fact m on o.Ord_id = m.Ord_id),
cte2 as (
select mon_cus.mon, mon_cus.cust_id,
lag(mon, 1) over(partition by mon_cus.cust_id) as prev_month
from mon_cus 
order by mon asc)
select  cte2.mon,
sum(case when prev_month <2 then 1 else null end) as Irregular, 
sum(case when isnull(prev_month) then 1 else null end) as Churned,
sum(case when prev_month > 1  then 1 else null end) as Retained
from cte2 group by cte2.mon;