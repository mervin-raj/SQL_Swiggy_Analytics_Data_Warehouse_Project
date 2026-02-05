# 🍽️ Swiggy Analytics – SQL Data Warehouse Project

## 📌 Project Overview

This project focuses on **SWIGGY SALES ANALYSIS**, built as a complete SQL-based analytics and data warehousing solution. The objective is to transform raw food delivery data into a **clean, structured, and analysis-ready system** that can answer key business questions related to sales, customer behavior, restaurant performance, and pricing trends.

The project follows **industry-standard practices** including data cleaning, dimensional modeling (Star Schema), KPI development, and deep-dive business analysis, making it highly suitable for real-world analytics roles.
This project is a **complete end-to-end SQL analytics case study** built using Swiggy-style food order data. It demonstrates how raw transactional data can be **cleaned, modeled, and transformed into a data warehouse** using a **Star Schema**, and then analyzed to generate meaningful **business insights**.

The project is designed to reflect **real-world data analyst / SQL developer workflows** and is fully **interview and recruiter ready**.

---

## 🎯 Objectives

* Clean and validate raw food order data
* Design a scalable **data warehouse (Star Schema)**
* Build **fact and dimension tables**
* Perform ETL (Extract, Transform, Load) using SQL
* Generate KPIs and analytical insights using **aggregates & window functions**

---

## 🗂️ Dataset Overview

**Source Table:** `swiggy_data`

| Column          | Description             |
| --------------- | ----------------------- |
| state           | Order state             |
| city            | Order city              |
| order_date      | Date of order           |
| restaurant_name | Restaurant name         |
| location        | Locality                |
| category        | Cuisine / food category |
| dish_name       | Dish ordered            |
| price_inr       | Price in INR            |
| rating          | Rating value            |
| rating_count    | Number of ratings       |

---

## 🧹 Data Cleaning & Validation

The raw table `swiggy_data` contains food delivery records across **states, cities, restaurants, cuisines, and dishes**. Before performing any analytics, ensuring **data quality and consistency** is critical.

### Data Quality Checks Performed

#### 1️⃣ Null Check

Identify missing values in the following critical fields:

* State
* City
* Order_Date
* Restaurant_Name
* Location
* Category
* Dish_Name
* Price_INR
* Rating
* Rating_Count

Null values in these columns can lead to incorrect aggregations, broken joins, and misleading insights.

#### 2️⃣ Blank / Empty String Check

Detect records where fields contain blank values (`''`) instead of NULLs. Blank values often bypass NULL checks and can silently impact analysis accuracy.

#### 3️⃣ Duplicate Detection

Duplicate records are identified by grouping on all **business-critical columns** that together define a unique order.

#### 4️⃣ Duplicate Removal

Duplicates are removed using the `ROW_NUMBER()` window function, ensuring that **only one clean record is retained** for each unique order while safely deleting redundant rows.
The following checks were performed before analytics:

* NULL value detection
* Blank value detection
* Duplicate record identification and removal

### Duplicate Removal (CTE + ROW_NUMBER)

```sql
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY state, city, order_date, restaurant_name,
        location, category, dish_name, price_inr, rating, rating_count
        ORDER BY (SELECT NULL)
    ) AS rn
    FROM swiggy_data
)
DELETE FROM cte WHERE rn > 1;
```

✔ Ensures clean, non-duplicated transactional data

---

## 🏗️ Dimensional Modeling – Star Schema

Dimensional modeling is used to organize data in a way that makes analysis **simple, consistent, and highly efficient**. Instead of storing all information in a single large table, the Star Schema separates descriptive attributes into **dimension tables** and keeps measurable values in a central **fact table**.

### Why Star Schema?

* Reduces data redundancy
* Improves query performance
* Simplifies analytical queries
* Widely supported by BI tools (Power BI, Tableau, Looker)
* Enables reliable aggregations and scalable reporting

This approach provides a **clean, scalable, and performance-optimized foundation** for analytics.

### Dimension Tables

* **dim_date** → Year, Month, Quarter, Week
* **dim_location** → State, City, Location
* **dim_restaurant** → Restaurant_Name
* **dim_category** → Cuisine / Category
* **dim_dish** → Dish_Name

### Fact Table

* **fact_swiggy_orders**

  * Measures: Price_INR, Rating, Rating_Count
  * Foreign Keys: Date, Location, Restaurant, Category, Dish

Each dimension is populated using **distinct values from the cleaned source**, and the fact table is loaded only after all dimension keys are resolved.
The project follows a **Star Schema**, commonly used in analytics and data warehousing.

### Dimension Tables

* `dim_date` – time-based analysis
* `dim_location` – state, city, locality
* `dim_restaurant` – restaurant details
* `dim_category` – cuisine/category
* `dim_dish` – dish information

### Fact Table

* `fact_swiggy_orders`

  * Measures: `price_inr`, `rating_count`
  * Foreign Keys: date, location, restaurant, category, dish

✔ Enables fast and flexible analytical queries

---

## 🔄 ETL Process

1. Load cleaned data into **dimension tables** using `DISTINCT`
2. Generate surrogate keys for dimensions
3. Insert records into the **fact table** by joining all dimensions

### Fact Table Load Query

```sql
INSERT INTO fact_swiggy_orders
SELECT
    dd.date_id,
    s.price_inr,
    s.rating_count,
    dl.location_id,
    dr.restaurant_id,
    dc.category_id,
    dsh.dish_id
FROM swiggy_data s
JOIN dim_date dd ON dd.full_date = s.order_date
JOIN dim_location dl ON dl.state = s.state AND dl.city = s.city AND dl.location = s.location
JOIN dim_restaurant dr ON dr.restaurant_name = s.restaurant_name
JOIN dim_category dc ON dc.category_name = s.category
JOIN dim_dish dsh ON dsh.dish_name = s.dish_name;
```

---

## 📊 KPI Development & Business Analysis

Once the Star Schema is built, the next step is to compute **core performance indicators** and perform deep-dive analysis to support business decision-making.

### 🔹 Basic KPIs

* Total Orders
* Total Revenue (INR Million)
* Average Dish Price
* Average Rating

### 🔹 Date-Based Analysis

* Monthly order trends
* Quarterly order trends
* Year-wise growth analysis
* Day-of-week ordering patterns

### 🔹 Location-Based Analysis

* Top 10 cities by order volume
* Revenue contribution by states

### 🔹 Food Performance Analysis

* Top 10 restaurants by orders
* Top cuisine categories (Indian, Chinese, etc.)
* Most ordered dishes
* Cuisine performance → Total Orders + Average Rating

### 🔹 Customer Spending Insights

Customer spending behavior is analyzed using price buckets:

* Under 100
* 100–199
* 200–299
* 300–499
* 500+

This helps understand affordability patterns and pricing strategy.

### 🔹 Ratings Analysis

* Distribution of dish ratings from 1 to 5
* Helps evaluate customer satisfaction and food quality trends

### Total Orders

```sql
SELECT COUNT(*) AS total_orders FROM fact_swiggy_orders;
```

### Revenue by State (with % Contribution)

```sql
SELECT
    l.state,
    SUM(f.price_inr) AS total_revenue,
    ROUND(SUM(f.price_inr) * 100.0 / SUM(SUM(f.price_inr)) OVER (), 2) AS revenue_percentage
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.state
ORDER BY total_revenue DESC;
```

### Top 10 Restaurants by Orders

```sql
SELECT r.restaurant_name, COUNT(*) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_orders DESC
LIMIT 10;
```

### Orders by Price Range

```sql
SELECT
CASE
    WHEN price_inr < 100 THEN 'Under 100'
    WHEN price_inr BETWEEN 100 AND 199 THEN '100-199'
    WHEN price_inr BETWEEN 200 AND 299 THEN '200-299'
    WHEN price_inr BETWEEN 300 AND 399 THEN '300-399'
    WHEN price_inr BETWEEN 400 AND 499 THEN '400-499'
    ELSE 'Above 500'
END AS price_range,
COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY price_range
ORDER BY MIN(price_inr);
```

---

## 🧠 SQL Concepts Used

* Joins (Inner Joins)
* Aggregate Functions (`SUM`, `COUNT`, `AVG`)
* Window Functions (`ROW_NUMBER`, `SUM() OVER()`)
* CTE (Common Table Expressions)
* CASE statements
* Star Schema modeling

---

---

## 🚀 Tools & Technologies

* PostgreSQL
* SQL
* Data Warehousing Concepts

---

⭐ **If you found this project useful, please star the repository!**
