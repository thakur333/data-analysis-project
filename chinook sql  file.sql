USE chinook
-- OBJECTIVE QUESTIONS

-- Q1. Does any table have missing values or duplicates? If yes how would you handle it ?

SELECT * FROM album;

SELECT * FROM artist;

SELECT COUNT(*) FROM customer -- 49 company, 29 state, 47 fax values are null in the customer table
WHERE fax is NULL;

SELECT * from employee; -- 1 reports_to value is null in the employee table

SELECT * FROM genre;

SELECT * FROM invoice;

SELECT * FROM invoice_line;

SELECT * FROM media_type;

SELECT * FROM playlist;

SELECT * FROM playlist_track;

SELECT COUNT(*) FROM track -- 978 composer columns are null in the track table
WHERE composer is NULL

/*
There are no duplicate values in the whole dataset.
In case of null values I would use COALESCE function to handle the situation
*/
--------------------------------------------------------------------------------------------------

-- Q2. Find the top-selling tracks and top artist in the USA and identify their most famous genres.

SELECT Top_selling_track, Top_artist, Top_genre FROM 
(
SELECT t.name Top_selling_track, a.name Top_artist, g.name Top_genre, SUM(t.unit_price * il.quantity) FROM track t
LEFT JOIN invoice_line il on t.track_id = il.track_id
LEFT JOIN invoice i on i.invoice_id = il.invoice_id
LEFT JOIN album al on al.album_id = t.album_id
LEFT JOIN artist a on a.artist_id = al.artist_id
LEFT JOIN genre g on g.genre_id = t.genre_id
WHERE billing_country = "USA"
GROUP BY t.name, a.name, g.name
ORDER BY SUM(total) DESC
LIMIT 10
) Agg_table;

--------------------------------------------------------------------------------------------------

-- Q3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?

SELECT city, country, COUNT(customer_id) FROM customer
GROUP BY 1,2
ORDER BY country;

SELECT country, COUNT(customer_id) FROM customer
GROUP BY 1
ORDER BY 1;

SELECT COUNT(distinct country) FROM customer;

/*
The Customer Demographic Breakdown based on location is very diversified.
The Chinook's customer base is spread over 24 countries with max number of customers from USA.
The customer table does not have age and gender columns to understand the customer breakdown
*/

-------------------------------------------------------------------------------------------------------

-- Q4. Calculate the total revenue and number of invoices for each country, state, and city

SELECT billing_city, billing_state, billing_country, COUNT(invoice_id) num_of_invoices, SUM(total) total_revenue FROM invoice
GROUP BY 1,2,3
ORDER BY COUNT(invoice_id) DESC, SUM(total) DESC

---------------------------------------------------------------------------------------------------------

-- Q5. Find the top 5 customers by total revenue in each country

WITH cte as
(
SELECT country, first_name, last_name, SUM(t.unit_price * il.quantity) total_revenue FROM customer c
LEFT JOIN invoice i on i.customer_id = c.customer_id
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id 
LEFT JOIN track t on t.track_id = il.track_id
GROUP BY 1,2,3
ORDER BY country
),
cte2 as
(
SELECT country, first_name, last_name,
RANK() OVER(PARTITION BY country ORDER BY total_revenue DESC) rk
FROM cte
)
SELECT country, first_name, last_name FROM cte2
WHERE rk <= 5;

--------------------------------------------------------------------------------------------------------

-- Q6. Identify the top-selling track for each customer

SELECT first_name, last_name, t.name Track_name, SUM(quantity) Total_quantity FROM customer c
LEFT JOIN invoice i on i.customer_id = c.customer_id
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
LEFT JOIN track t on t.track_id = il.track_id
GROUP BY 1,2,3
ORDER BY SUM(quantity) DESC;

----------------------------------------------------------------------------------------------------

-- Q7. Are there any patterns or trends in customer purchasing behavior 
-- (e.g., frequency of purchases, preferred payment methods, average order value)?

SELECT customer_id, COUNT(invoice_id) num_invoices, AVG(total) avg_sales FROM invoice
GROUP BY 1
ORDER BY COUNT(invoice_id) DESC, AVG(total) DESC

/*
No there is no correlation or trend between the number/frequency of orders by different customers and the 
average sales generated by these customers.
The average sales most probably depends on the unit price of each track and not he number of orders.
*/ 
------------------------------------------------------------------------------------------------------

-- Q8. What is the customer churn rate?

WITH num_cust_in_1st_3months as 
(
SELECT COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
),-- I have taken the assumption that total number of customers in the beginning is equal to the customers joining in the first 3 months.
num_cust_in_last_2months as
(
SELECT COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
) -- I have taken the assumption that churn rate will be calculated on the basis of the number of customers left in the last two months. 
SELECT ((SELECT ttl FROM num_cust_in_1st_3months)-(SELECT l_num FROM num_cust_in_last_2months))/(SELECT ttl FROM num_cust_in_1st_3months) * 100 as churn_rate
;

/* 
Therefore the customer churn rate of the company is 40.8163 based on the total number of customer 
in first 3 months i.e 49 and the number of customer present in the last 2 months i.e 29
So, number of customers lost = 49-29 = 20
*/ 
------------------------------------------------------------------------------------------------------

-- Q9. Calculate the percentage of total sales contributed by each genre in the USA and 
--     identify the best-selling genres and artists.

WITH cte as
(
SELECT SUM(total) total_revenue_for_USA FROM invoice
WHERE billing_country = 'USA'
),
genre_sales as
(
SELECT  g.genre_id, g.name, sum(t.unit_price * il.quantity) total_revenue_for_genre FROM track t
LEFT JOIN genre g on g.genre_id = t.genre_id
LEFT JOIN invoice_line il on il.track_id = t.track_id
LEFT JOIN invoice i on i.invoice_id = il.invoice_id
WHERE billing_country = 'USA'
GROUP BY 1,2 
ORDER BY total_revenue_for_genre DESC
),
ranking as
(
SELECT genre_id, name, ROUND(total_revenue_for_genre/(SELECT total_revenue_for_USA FROM cte) * 100,2) percentage_contribution,
DENSE_RANK() OVER(ORDER BY ROUND(total_revenue_for_genre/(SELECT total_revenue_for_USA FROM cte) * 100,2) DESC) rk FROM genre_sales
)
SELECT ranking.genre_id, ranking.name genre_name, a.name artist_name, percentage_contribution, rk FROM ranking
LEFT JOIN track t on t.genre_id = ranking.genre_id
LEFT JOIN album al on al.album_id = t.album_id
LEFT JOIN artist a on a.artist_id = al.artist_id
GROUP BY 1,2,3,4

/* Therefore the top selling genre in USA is Rock.
and 
The Posies
Scorpions
Ozzy Osbourne
Dread Zeppelin
Velvet Revolver
Van Halen
U2
The Who
The Rolling Stones
The Police
The Doors
The Cult
Terry Bozzio, Tony Levin & Steve Stevens
Stone Temple Pilots
Soundgarden
Skank
Lenny Kravitz
Santana
Rush
Red Hot Chili Peppers
Raul Seixas
R.E.M.
Queen
Pink Floyd
Pearl Jam
Paul D'Ianno
Page & Plant
O Terço
Nirvana
Men At Work
Marillion
Led Zeppelin
Kiss
Joe Satriani
Jimi Hendrix
Jamiroquai
Iron Maiden
Guns N' Roses
Foo Fighters
Faith No More
Def Leppard
Deep Purple
Creedence Clearwater Revival
David Coverdale
Frank Zappa & Captain Beefheart
Audioslave
Alice In Chains
Alanis Morissette
Aerosmith
AC/DC
Accept
are all the top artists who are associated with the Rock genre.
*/

---------------------------------------------------------------------------------------------------------

-- Q10. Find customers who have purchased tracks from at least 3 different+ genres

SELECT name_of_customer FROM
(
SELECT CONCAT(first_name, ' ', last_name) name_of_customer, COUNT(DISTINCT g.name) FROM customer c 
LEFT JOIN invoice i on i.customer_id = c.customer_id
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
LEFT JOIN track t on t.track_id = il.track_id
LEFT JOIN genre g on g.genre_id = t.genre_id
GROUP BY 1 HAVING COUNT(DISTINCT g.name) >= 3
ORDER BY COUNT(DISTINCT g.name) DESC
) agg_table

/* Leonie Köhler is the person who has bought tracks from 14 different genres.
*/

-------------------------------------------------------------------------------------------------------

-- Q11. Rank genres based on their sales performance in the USA

WITH cte as
(
SELECT t.genre_id, g.name,  SUM(t.unit_price * il.quantity) sale_performance FROM track t
LEFT JOIN genre g on g.genre_id = t.genre_id
LEFT JOIN invoice_line il on il.track_id = t.track_id
LEFT JOIN invoice i on i.invoice_id = il.invoice_id
WHERE billing_country = 'USA'
GROUP BY 1, 2
)
SELECT name, sale_performance,
DENSE_RANK() OVER(ORDER BY sale_performance DESC) `rank` FROM cte
;

------------------------------------------------------------------------------------------------------

-- Q12. Identify customers who have not made a purchase in the last 3 months

WITH last_3_months as
(
SELECT * from invoice
WHERE invoice_date > (SELECT MAX(invoice_date) FROM invoice) - INTERVAL 3 MONTH
)
SELECT CONCAT(first_name, ' ', last_name) name_of_customer FROM customer c
LEFT JOIN last_3_months lm on lm.customer_id = c.customer_id
WHERE invoice_id is NULL
;

/* There are 22 customers in the dataset who have not made any purchase in the last 3 months.
*/

========================================================================================================
========================================================================================================

-- SUBJECTIVE QUESTIONS

-- Q1. Recommend the three albums from the new record label that should be prioritised 
-- for advertising and promotion in the USA based on genre sales analysis.

WITH genre_sales as
(
SELECT  g.genre_id, g.name, sum(t.unit_price * il.quantity) total_revenue_for_genre FROM track t
LEFT JOIN genre g on g.genre_id = t.genre_id
LEFT JOIN invoice_line il on il.track_id = t.track_id
LEFT JOIN invoice i on i.invoice_id = il.invoice_id
WHERE billing_country = 'USA'
GROUP BY 1,2
ORDER BY total_revenue_for_genre DESC
),
ranking as
(
SELECT genre_id, name, total_revenue_for_genre,
DENSE_RANK() OVER(ORDER BY total_revenue_for_genre DESC) rk FROM genre_sales
),
genre_album as
(
SELECT ranking.genre_id, ranking.name genre_name, al.title album_name FROM ranking
LEFT JOIN track t on t.genre_id = ranking.genre_id
LEFT JOIN album al on al.album_id = t.album_id
LEFT JOIN artist a on a.artist_id = al.artist_id
WHERE rk = 1
GROUP BY 1,2,3
),
best_album as
(
SELECT al.album_id, title, SUM(t.unit_price * il.quantity) FROM album al
LEFT JOIN track t on t.album_id = al.album_id
LEFT JOIN invoice_line il on il.track_id = t.track_id
GROUP BY 1,2
ORDER BY SUM(t.unit_price * il.quantity) desc
)
SELECT genre_id, genre_name, album_name FROM genre_album 
inner join best_album on best_album.title = genre_album.album_name
LIMIT 3
/* 
Top 3 albums that should be prioritised for advertisements and promotions in the 
USA based on genre analysis are
Every Kind of Light
20th Century Masters - The Millennium Collection: The Best of Scorpions
Speak of the Devil
All these albums are from the genre Rock as it is the most popular genre in the USA. 
*/

------------------------------------------------------------------------------------------------------

-- Q2. Determine the top-selling genres in countries 
-- other than the USA and identify any commonalities or differences.

SELECT  g.genre_id, g.name, sum(t.unit_price * il.quantity) total_revenue_for_genre FROM track t
LEFT JOIN genre g on g.genre_id = t.genre_id
LEFT JOIN invoice_line il on il.track_id = t.track_id
LEFT JOIN invoice i on i.invoice_id = il.invoice_id
WHERE billing_country != 'USA'
GROUP BY 1,2
ORDER BY total_revenue_for_genre DESC

/* The commonality between the data regarding USA and rest of the countries 
is that the ROCK genre has been taking the top spot in both the data. 
The 2nd and 3rd spot is taken by METAL & ALTERNATIVE & PUNK genre respectively. 
*/

------------------------------------------------------------------------------------------------------

-- Q3. Customer Purchasing Behavior Analysis: 
-- How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ 
-- from those of new customers? What insights can these patterns provide about customer loyalty and 
-- retention strategies?
 
 WITH cte as
(
SELECT i.customer_id, MAX(invoice_date), MIN(invoice_date), abs(TIMESTAMPDIFF(MONTH, MAX(invoice_date), MIN(invoice_date))) time_for_each_customer, SUM(total) sales, SUM(quantity) items, COUNT(invoice_date) frequency FROM invoice i
LEFT JOIN customer c on c.customer_id = i.customer_id
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1
ORDER BY time_for_each_customer DESC
),
average_time as
(
SELECT AVG(time_for_each_customer) average FROM cte
),-- 1244.3220 Days OR 40.36 Months
categorization as
(
SELECT *,
CASE
WHEN time_for_each_customer > (SELECT average from average_time) THEN "Long-term Customer" ELSE "Short-term Customer" 
END category
FROM cte
)
SELECT category, SUM(sales) total_spending, SUM(items) basket_size, COUNT(frequency) frequency FROM categorization
GROUP BY 1 

/* 
Insights- It can be seen that the spending amount, basket size and frequency for long term customers is more 
than the short term customers.
Recommendations - It shows that customer loyalty plays an important role in increasing the revenue of 
the company because the long term customers tend to buy more than the short term customers. Therefore, 
the company should focus on the retention rate of the customers so as to increase the sales over time.
 */
 -----------------------------------------------------------------------------------------------------
 
 -- Q4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased 
 -- together by customers? How can this information guide product recommendations and 
 -- cross-selling initiatives?

WITH cte as
(
SELECT invoice_id, COUNT(DISTINCT g.name) num FROM invoice_line il
left JOIN track t on t.track_id = il.track_id
left JOIN genre g on  g.genre_id = t.genre_id
GROUP BY 1 HAVING COUNT(DISTINCT g.name) > 1
)
SELECT cte.invoice_id, num, g.name FROM cte
left join invoice_line il on il.invoice_id = cte.invoice_id
left JOIN track t on t.track_id = il.track_id
left JOIN genre g on  g.genre_id = t.genre_id
GROUP BY 1,2,3;

WITH cte as
(
SELECT invoice_id, COUNT(DISTINCT al.title) num FROM invoice_line il
left JOIN track t on t.track_id = il.track_id
left JOIN album al on al.album_id = t.album_id
GROUP BY 1 HAVING COUNT(DISTINCT al.title) > 1
)
SELECT cte.invoice_id, num, al.title FROM cte
left join invoice_line il on il.invoice_id = cte.invoice_id
left JOIN track t on t.track_id = il.track_id
left JOIN album al on  al.album_id = t.album_id
GROUP BY 1,2,3;

WITH cte as
(
SELECT invoice_id, COUNT(DISTINCT a.name) num FROM invoice_line il
left JOIN track t on t.track_id = il.track_id
left JOIN album al on al.album_id = t.album_id
left join artist a on a.artist_id = al.artist_id
GROUP BY 1 HAVING COUNT(DISTINCT a.name) > 1
)
SELECT cte.invoice_id, num, a.name FROM cte
left join invoice_line il on il.invoice_id = cte.invoice_id
left JOIN track t on t.track_id = il.track_id
left JOIN album al on  al.album_id = t.album_id
left join artist a on a.artist_id = al.artist_id
GROUP BY 1,2,3;
/*
When the output of the above query is plotted as a table in excel and a pivot table is constructed with 
genres in rows, invoice id in columns and count of genres in values it can be seen that the 
Rock, Metal & Alternative and Punk are the genres frequently purchased together.
In similar way when when albums are checked then
Mezmerize, The Doors & Dark Side Of The Moon are the albums frequently purchased together. 
In simalar way when artists are checked then
 Green Day, Foo Fighters & U2 are the artists frequently purchased together.
*/

------------------------------------------------------------------------------------------------------

-- Q5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across 
-- different geographic regions or store locations? How might these correlate with local demographic or 
-- economic factors?

WITH num_cust_in_1st_3months as
(
SELECT billing_country, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_country, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_country, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_country = n2.billing_country
;

WITH num_cust_in_1st_3months as
(
SELECT billing_city, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_city, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_city, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_city = n2.billing_city
;

WITH num_cust_in_1st_3months as
(
SELECT billing_state, COUNT(customer_id) ttl from invoice
WHERE invoice_date BETWEEN '2017-01-01' AND '2017-03-31'
GROUP BY 1
),
num_cust_in_last_2months as
(
SELECT billing_state, COUNT(customer_id) l_num FROM invoice
WHERE invoice_date BETWEEN '2020-11-01' AND '2020-12-31' 
GROUP BY 1
)
SELECT n1.billing_state, (ttl - COALESCE(l_num,0))/ttl * 100 churn_rate FROM num_cust_in_1st_3months n1
LEFT JOIN  num_cust_in_last_2months n2 on n1.billing_state = n2.billing_state
;


SELECT billing_country, COUNT(invoice_id) num_invoices, AVG(total) avg_sales FROM invoice
GROUP BY 1
ORDER BY COUNT(invoice_id) DESC, AVG(total) DESC

/*
Insights - Therefore it can be seen from the above queries that the customer churn rate varies across 
different countries, cities and state.
Also yes the purchasing behaviour of the customers vary across different countries.
Recommendations - It can be observed that the developed nations have more number of orders and 
average sales as compared to the developing nations. It shows that economic factors play a 
crucial role in the sales generated from a region. Therefore more number of advertisements should 
be launched in the countries with high economy and cheaper tracks should be sold in the coutries with 
low economy. Population can also be considered an important metric to judge sales in different countries. 
*/
 
-----------------------------------------------------------------------------------------------------

-- Q6. Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), 
-- which customer segments are more likely to churn or pose a higher risk of reduced spending? 
-- What factors contribute to this risk?

SELECT i.customer_id, CONCAT(first_name, " ", last_name) name, billing_country, invoice_date, SUM(total) total_spending, COUNT(invoice_id) num_of_orders FROM invoice i
LEFT JOIN customer c on c.customer_id = i.customer_id
GROUP BY 1,2,3,4
ORDER BY name

/*
After analyzing the data in the form of charts and tables it can be seen that the countries with 
already high spending amount and frequency of orders, their numbers are increasing whereas the 
sales and frequency are stagnant in other countries. Therefore, it is seen that new promotional campaigns 
need to be done in those coutries to reduce churn rate as well as maintain & increase the spending.
Factors which contribute to this risk are: - 
Are younger customers more likely to churn? (if information was given)
Does gender play a role? (if information was given)
How does location impact churn?
Analysis of spending behavior (e.g., high spenders vs. infrequent buyers).
If there was information regarding age and gender of the customers, the customer segmentation would 
have been - Young-Male-High-Spendors, Young-Female-High-Spendors, Old-Male-Low-Spendors, 
Old-Female-Low-Spendors and many more. 
*/
--------------------------------------------------------------------------------------------------------

-- Q7. Customer Lifetime Value Modeling: How can you leverage customer data (tenure, purchase history, 
-- engagement) to predict the lifetime value of different customer segments? 
-- This could inform targeted marketing and loyalty program strategies. 
-- Can you observe any common characteristics or purchase patterns among customers who have stopped 
-- purchasing?

/*
To predict the lifetime value of the customer segment, I could analyze the customer purchase history 
and the tenure for which a customer is with the company. With these two parameters we can judge whether a 
customer is a High_value customer or not. 
If the tenure of the customer is small but the purchase history is big, then promotional campaigns 
should be targeted to these type of customers as they can be converted into loyal customers.
The customers who have stopped purchasing have one thing in common that they belong to the 
under developed or developing countries. This shows that economic factor plays an important role in 
the sales of the company. This could be prevented by using adequate number of promotion channels like 
social media, articles and advertisements. Also giving discounts could boost the sales in those countries.   
*/       

--------------------------------------------------------------------------------------------------------

-- Q11. Chinook is interested in understanding the purchasing behavior of customers based on their 
-- geographical location. They want to know the average total amount spent by customers from each country, 
-- along with the number of customers and the average number of tracks purchased per customer. 
-- Write an SQL query to provide this information.

SELECT billing_country, 
COUNT(DISTINCT customer_id) num_of_customers, 
AVG(total) Average_total_amount, 
COUNT(track_id) num_of_tracks 
FROM invoice i
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1 
;

SELECT customer_id, COUNT(DISTINCT track_id) num_of_tracks_per_customer FROM invoice i
LEFT JOIN invoice_line il on il.invoice_id = i.invoice_id
GROUP BY 1

