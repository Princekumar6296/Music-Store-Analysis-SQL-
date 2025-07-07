-- who is the senior most employee based on job title

select * from employee
order by levels desc
limit 1;


-- Which country has the most Invoices.

select count(*) as Invoice_count, billing_country
from invoice
group by billing_country
order by Invoice_count desc;


-- What are top 3 values of total invoice

select total, billing_country from invoice
order by total desc
limit 3;



-- Which city has the best customers? we would like to throw a promotional Music Festival in the city we made the most money.
-- write a query that returns one city that has the highest sum of invioce totals. Return both the city name & sum of all invoice totals.

select sum(total) as Total_invoice, billing_city
from invoice
group by billing_city
order by Total_invoice desc;



-- Who is the best customer? The customer who has spent the most money will be declared the best customer. write a query that returns the
-- person who spent the most money.

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as totals
from customer
join invoice
ON customer.customer_id = invoice.customer_id
group by customer.customer_id
order by totals desc
limit 1;



-- Write a query to return the email, first_name, last_name, & genre of all Rock Music Listners.
-- Return your list ordered alphabetically by email starting with A.

select Distinct customer.email, customer.first_name, customer.last_name
from customer
join invoice on customer.customer_id = invoice.customer_id 
join invoice_line on invoice.invoice_id = invoice_line.invoice_id 
where track_id in(
	select track_id from track
	join genre on track.genre_id = genre.genre_id 
	where genre.name like 'Rock'
)
order by email;



-- Let's invite the artist who have written the most rock music in our dataset. 
-- Write a query that returns the Artist name and total track count of the top 10 rock bands.

select artist.name, artist.artist_id, count(artist.artist_id) as number_of_songs
from track
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
join genre on genre.genre_id = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10;



-- Return all the track names that have a song length longer than the average song length.
-- Return the name and millisecond for each track. Order by the song length with the longest songs listed first.

select name, milliseconds 
from track
Where milliseconds >(
	select avg(milliseconds) as Avg_track_length
	from track
)
order by milliseconds desc;



-- Find how much amount spent by each customer on artist? Write a query to return customer name, artist name and total spent.

WITH best_selling_artist AS (
    SELECT 
        artist.artist_id AS artist_id,
        artist.name AS artist_name,
        SUM(invoice_line.unit_price * invoice_line.quantity) AS total_sales
    FROM invoice_line
    JOIN track ON invoice_line.track_id = track.track_id
    JOIN album ON track.album_id = album.album_id
    JOIN artist ON album.artist_id = artist.artist_id
    GROUP BY artist.artist_id, artist.name
),
top_customers_for_best_artist AS (
    SELECT 
        c.customer_id, 
        c.first_name, 
        c.last_name, 
        bsa.artist_name,
        SUM(il.unit_price * il.quantity) AS amount_spent
    FROM invoice i
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN invoice_line il ON il.invoice_id = i.invoice_id
    JOIN track t ON t.track_id = il.track_id
    JOIN album alb ON alb.album_id = t.album_id
    JOIN (
        SELECT * FROM best_selling_artist
        ORDER BY total_sales DESC
        LIMIT 1
    ) bsa ON bsa.artist_id = alb.artist_id
    GROUP BY c.customer_id, c.first_name, c.last_name, bsa.artist_name
)

SELECT * 
FROM top_customers_for_best_artist
ORDER BY amount_spent DESC;



-- We want to find out the most popular music Genre for each country.
-- (we determine the most popular genre as the genre with the highest amount of purchases. )


WITH popular_music AS (
    SELECT 
        COUNT(il.quantity) AS purchases,
        c.country,
        g.name AS genre_name,
        g.genre_id,
        ROW_NUMBER() OVER(PARTITION BY c.country ORDER BY COUNT(il.quantity) DESC) AS row_no
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN customer c ON c.customer_id = i.customer_id
    JOIN track t ON t.track_id = il.track_id
    JOIN genre g ON g.genre_id = t.genre_id
    GROUP BY 2,3,4
)

SELECT 
    country,
    genre_name AS most_popular_genre,
    purchases
FROM popular_music
WHERE row_no <= 1
ORDER BY country;



-- Write a query that determine the customer that has spent the most on music for each country.
-- Write a query that returns the country along with the top customer and how much they spent.
-- For countries where the top amount spent is shared, provide all customers who spent this amount.


WITH 
customer_with_country AS (
    SELECT 
        customer.customer_id, 
        first_name, 
        last_name, 
        billing_country, 
        SUM(total) AS total_spent 
    FROM invoice
    JOIN customer ON customer.customer_id = invoice.customer_id
    GROUP BY customer.customer_id, first_name, last_name, billing_country
),

customer_max_spending AS (
    SELECT 
        billing_country, 
        MAX(total_spent) AS max_spent
    FROM customer_with_country
    GROUP BY billing_country
)

SELECT   
    cc.first_name, 
    cc.last_name,
	cc.billing_country,
	cc.total_spent
FROM customer_with_country cc
JOIN customer_max_spending ms
    ON cc.billing_country = ms.billing_country
WHERE cc.total_spent = ms.max_spent
ORDER BY 1;
