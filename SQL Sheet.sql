-- =========================================
-- Airline Data Analysis SQL
-- Cleaned, Optimized & Extended
-- =========================================

-- =========================================
-- Problem Statement 18
-- Find year-over-year passenger growth
-- =========================================
WITH yearly_passengers AS (
    SELECT YEAR(fly_date) AS year, 
           SUM(passengers) AS total_passengers
    FROM airports
    GROUP BY YEAR(fly_date)
)
SELECT year,
       total_passengers,
       LAG(total_passengers) OVER (ORDER BY year) AS previous_year_passengers,
       ROUND(((total_passengers - LAG(total_passengers) OVER (ORDER BY year)) 
             / NULLIF(LAG(total_passengers) OVER (ORDER BY year), 0)) * 100, 2) 
             AS yoy_growth_percent
FROM yearly_passengers
ORDER BY year;

-- Outcome: Shows year-on-year passenger growth %

-- =========================================
-- Problem Statement 19
-- Identify busiest airport per year (by passengers)
-- =========================================
WITH yearly_airports AS (
    SELECT origin_airport, 
           YEAR(fly_date) AS year,
           SUM(passengers) AS total_passengers
    FROM airports
    GROUP BY origin_airport, YEAR(fly_date)
)
SELECT year, origin_airport, total_passengers
FROM (
    SELECT year, origin_airport, total_passengers,
           ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_passengers DESC) AS rn
    FROM yearly_airports
) ranked
WHERE rn = 1
ORDER BY year;

-- Outcome: Most busy airport (highest passengers) per year

-- =========================================
-- Problem Statement 20
-- Top 5 fastest-growing routes (CAGR)
-- =========================================
WITH yearly_route AS (
    SELECT origin_airport, destination_airport, 
           YEAR(fly_date) AS year, 
           SUM(passengers) AS total_passengers
    FROM airports 
    GROUP BY origin_airport, destination_airport, YEAR(fly_date)
),
growth_calc AS (
    SELECT origin_airport, destination_airport,
           MIN(year) AS start_year, MAX(year) AS end_year,
           MIN(total_passengers) AS start_passengers,
           MAX(total_passengers) AS end_passengers
    FROM yearly_route
    GROUP BY origin_airport, destination_airport
    HAVING start_passengers > 0
)
SELECT origin_airport, destination_airport,
       ROUND(((POWER(end_passengers*1.0/start_passengers, 1.0/(end_year-start_year)) - 1) * 100), 2) AS cagr_percent
FROM growth_calc
ORDER BY cagr_percent DESC
LIMIT 5;

-- Outcome: Shows top 5 fastest-growing routes by CAGR

-- =========================================
-- Problem Statement 21
-- Airport market share by passengers
-- =========================================
SELECT origin_airport,
       SUM(passengers) AS total_passengers,
       ROUND((SUM(passengers)*100.0 / SUM(SUM(passengers)) OVER()), 2) AS market_share_percent
FROM airports
GROUP BY origin_airport
ORDER BY market_share_percent DESC
LIMIT 5;

-- Outcome: Top 5 airports by market share %

-- =========================================
-- Problem Statement 22
-- Load factor analysis (city-to-city)
-- =========================================
SELECT origin_city, destination_city,
       ROUND(SUM(passengers) * 100.0 / NULLIF(SUM(seats), 0), 2) AS avg_load_factor
FROM airports
GROUP BY origin_city, destination_city
ORDER BY avg_load_factor DESC;

-- Outcome: Load factor % for each route, useful for heatmap visualization
