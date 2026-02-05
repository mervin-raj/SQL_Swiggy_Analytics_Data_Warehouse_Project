
DROP TABLE IF EXISTS public.food_orders;
CREATE TABLE public.food_orders (
    state VARCHAR(150),
    city VARCHAR(150),
    order_date DATE,
    restaurant_name VARCHAR(100),
    location VARCHAR(100),
    category VARCHAR(150),
    dish_name VARCHAR(200),
    price_inr NUMERIC(10,2),
    rating NUMERIC(2,1),
    rating_count SMALLINT
);

ALTER TABLE public.food_orders
RENAME TO swiggy_data;


SELECT * FROM swiggy_data;



---data cleaning and validation--

SELECT
    SUM(CASE WHEN state IS NULL THEN 1 ELSE 0 END) AS null_state,
	SUM(CASE WHEN city IS NULL THEN 1 ELSE 0 END ) AS null_city,
	sum(case WHEN order_date IS NULL THEN 1 ELSE 0 END)AS null_order_date,
	SUM(CASE WHEN restaurant_name IS NULL THEN 1 ELSE 0 END)AS NULL_RES_name,
     SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END)AS NULL_location,
	SUM(CASE WHEN category IS NULL THEN 1 ELSE 0 END)AS NULL_category,
	SUM(CASE WHEN dish_name IS NULL THEN 1 ELSE 0 END)AS NULL_dish_name,
	SUM(CASE WHEN price_inr IS NULL THEN 1 ELSE 0 END)AS NULL_price_inr,
	SUM(CASE WHEN rating IS NULL THEN 1 ELSE 0 END)AS NULL_rating,
	SUM(CASE WHEN rating_count IS NULL THEN 1 ELSE 0 END)AS NULL_rating_count
FROM swiggy_data;

--blank or empty string--


 SELECT *
FROM swiggy_data
WHERE
    city = ''
    OR state = ''
    OR restaurant_name = ''
    OR location = ''
    OR category = ''
    OR dish_name = '';


--duplicate detection--


SELECT 
    state,
    city,
    order_date,
    restaurant_name,
    location,
    category,
    dish_name,
    price_inr,
    rating,
    rating_count,
    COUNT(*) AS cnt
FROM swiggy_data
GROUP BY 
    state,
    city,
    order_date,
    restaurant_name,
    location,
    category,
    dish_name,
    price_inr,
    rating,
    rating_count
HAVING COUNT(*) > 1;

--DUPLICATE DELETION--
WITH cte AS (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY
                   state,
                   city,
                   order_date,
                   restaurant_name,
                   location,
                   category,
                   dish_name,
                   price_inr,
                   rating,
                   rating_count
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM swiggy_data
)
DELETE FROM cte
WHERE rn > 1;

--or

WITH cte AS (
    SELECT ctid,
           ROW_NUMBER() OVER (
               PARTITION BY
                   state,
                   city,
                   order_date,
                   restaurant_name,
                   location,
                   category,
                   dish_name,
                   price_inr,
                   rating,
                   rating_count
               ORDER BY (SELECT NULL)
           ) AS rn
    FROM swiggy_data
)
DELETE FROM swiggy_data
USING cte
WHERE swiggy_data.ctid = cte.ctid
  AND cte.rn > 1;

--creating schema
--dimension tables
--date tables

CREATE TABLE dim_date (
    date_id SERIAL PRIMARY KEY,
    full_date DATE,
    year INT,
    month INT,
    month_name VARCHAR(20),
    quarter INT,
    day INT,
    week INT
);

CREATE TABLE dim_location (
    location_id SERIAL PRIMARY KEY,
    state VARCHAR(100),
     city VARCHAR(100),
     location VARCHAR(100)
);

CREATE TABLE dim_restaurant (
    restaurant_id SERIAL PRIMARY KEY,
    restaurant_name VARCHAR(200)
);

CREATE TABLE dim_category (
    category_id SERIAL PRIMARY KEY,
   category_name VARCHAR(200)
);



CREATE TABLE dim_dish(
    dish_id SERIAL PRIMARY KEY,
   dish_name VARCHAR(200)
);

--creating fact table
CREATE TABLE fact_swiggy_orders (
    order_id SERIAL PRIMARY KEY,

    date_id INT,
    price_inr DECIMAL(10,2),
    rating_count INT,

    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,

    CONSTRAINT fk_date
        FOREIGN KEY (date_id) REFERENCES dim_date(date_id),

    CONSTRAINT fk_location
        FOREIGN KEY (location_id) REFERENCES dim_location(location_id),

    CONSTRAINT fk_category
        FOREIGN KEY (category_id) REFERENCES dim_category(category_id),

    CONSTRAINT fk_dish
        FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

select * from swiggy;

--insert data in tables

--dim date

INSERT INTO dim_date (
    full_date,
    year,
    month,
    month_name,
    quarter,
    day,
    week
)
SELECT DISTINCT
    order_date,
    EXTRACT(YEAR FROM order_date),
    EXTRACT(MONTH FROM order_date),
    TO_CHAR(order_date, 'Month'),
    EXTRACT(QUARTER FROM order_date),
    EXTRACT(DAY FROM order_date),
    EXTRACT(WEEK FROM order_date)
FROM swiggy_data
WHERE order_date IS NOT NULL;

SELECT * FROM dim_date;

--dim_location
INSERT INTO dim_location (state, city, location)
SELECT DISTINCT
    state,
    city,
    location
FROM swiggy_data
WHERE state IS NOT NULL
  AND city IS NOT NULL
  AND location IS NOT NULL;

--dim_restaurant
INSERT INTO dim_restaurant (restaurant_name)
SELECT DISTINCT
    restaurant_name
FROM swiggy_data
WHERE restaurant_name IS NOT NULL;

--dim_category
INSERT INTO dim_category (category_name)
SELECT DISTINCT
    category
FROM swiggy_data
WHERE category IS NOT NULL;


--dish_name

--dim_category
INSERT INTO dim_dish (dish_name)
SELECT DISTINCT
    dish_name
FROM swiggy_data
WHERE dish_name IS NOT NULL;

select * from dim_category;

--facttable--
INSERT INTO fact_swiggy_orders
(
    date_id,
    price_inr,
    rating_count,
    location_id,
    restaurant_id,
    category_id,
    dish_id
)
SELECT
    dd.date_id,
    s.price_inr,
    s.rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s

JOIN dim_date dd
  ON dd.full_date = s.order_date

JOIN dim_location dl
  ON dl.state = s.state
 AND dl.city = s.city
 AND dl.location = s.location

JOIN dim_restaurant dr
  ON dr.restaurant_name = s.restaurant_name

JOIN dim_category dc
  ON dc.category_name = s.category

JOIN dim_dish dsh
  ON dsh.dish_name = s.dish_name;

SELECT *
FROM fact_swiggy_orders f

JOIN dim_date d
  ON f.date_id = d.date_id

JOIN dim_location l
  ON f.location_id = l.location_id

JOIN dim_restaurant r
  ON f.restaurant_id = r.restaurant_id

JOIN dim_category c
  ON f.category_id = c.category_id

JOIN dim_dish di
  ON f.dish_id = di.dish_id;


--KPIS--

--TOTAL_ORDERS--

SELECT COUNT(*) AS total_orders
from fact_swiggy_orders

--total revenue(INR MILLION)
SELECT
    ROUND(SUM(price_inr) / 2000000.0, 2) AS total_revenue_inr_million
FROM fact_swiggy_orders;

--average dishprice
SELECT
    ROUND(AVG(price_inr), 2) AS avg_dish_price
FROM fact_swiggy_orders;

--monthly order trends
SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;

--quarterly order trend--

SELECT
    d.year,
    d.quarter,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY
    d.year,
    d.quarter
ORDER BY
    d.year,
    d.quarter;

----yearly trends

	SELECT
    d.year,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY
    d.year
ORDER BY
    d.year;
 --order by day of week(mon-sun)

SELECT
    TO_CHAR(d.full_date, 'Day') AS day_of_week,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_date d
    ON f.date_id = d.date_id
GROUP BY
    day_of_week,
    EXTRACT(DOW FROM d.full_date)
ORDER BY
    CASE EXTRACT(DOW FROM d.full_date)
        WHEN 1 THEN 1  -- Monday
        WHEN 2 THEN 2  -- Tuesday
        WHEN 3 THEN 3  -- Wednesday
        WHEN 4 THEN 4  -- Thursday
        WHEN 5 THEN 5  -- Friday
        WHEN 6 THEN 6  -- Saturday
        WHEN 0 THEN 7  -- Sunday
    END;

--top 10 cities by order value--

SELECT
    l.city,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY
    l.city
ORDER BY
    total_orders DESC
LIMIT 10;

--revenue by states


SELECT
    l.state,
    SUM(f.Price_INR) AS total_revenue,
    ROUND(SUM(f.Price_INR) * 100.0 / SUM(SUM(f.Price_INR)) OVER (), 2) AS revenue_percentage
FROM fact_swiggy_orders f
JOIN dim_location l
    ON f.location_id = l.location_id
GROUP BY
    l.state
ORDER BY
    total_revenue DESC;

--top 10 restaurants by orders
SELECT
    r.restaurant_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_restaurant r
    ON f.restaurant_id = r.restaurant_id
GROUP BY
    r.restaurant_name
ORDER BY
    total_orders DESC
LIMIT 10;


--top categories by energy volume

SELECT
    c.category_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY
    c.category_name
ORDER BY
    total_orders DESC
LIMIT 10;
--most ordered dishes
SELECT
    d.dish_name,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_dish d
    ON f.dish_id = d.dish_id
GROUP BY
    d.dish_name
ORDER BY
    total_orders DESC
LIMIT 10;

--cusine performance

SELECT
    c.category_name AS cuisine,
    COUNT(*) AS total_orders,
    ROUND(AVG(f.rating_count), 2) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c
    ON f.category_id = c.category_id
GROUP BY
    c.category_name
ORDER BY
    total_orders DESC;
--total orders by price range
SELECT
    CASE
        WHEN Price_INR < 100 THEN 'Under 100'
        WHEN Price_INR BETWEEN 100 AND 199 THEN '100-199'
        WHEN Price_INR BETWEEN 200 AND 299 THEN '200-299'
        WHEN Price_INR BETWEEN 300 AND 399 THEN '300-399'
        WHEN Price_INR BETWEEN 400 AND 499 THEN '400-499'
        ELSE 'Above 500' 
    END AS "Price Range",
    COUNT(*) AS "Total Orders"
FROM fact_swiggy_orders
GROUP BY
    "Price Range"
ORDER BY
    MIN(Price_INR);


--ratingcount dstribution
SELECT
    rating_count AS "Rating",
    COUNT(*) AS "Rating Count"
FROM fact_swiggy_orders
GROUP BY rating_count
ORDER BY "Rating Count" DESC;






