create database weather;
use WeatherDB;
SHOW TABLES;
select * from weather;
-- 1. Give the count of the minimum number of days for the time when temperature reduced

SELECT COUNT(*)
FROM (SELECT id, temperature, LAG(temperature) OVER (ORDER BY date) AS prev_temperature
      FROM weather) subquery
WHERE prev_temperature > temperature;

-- 2. Find the temperature as Cold / hot by using the case and avg of values of the given data set
ALTER TABLE weather
ADD COLUMN temperature_category VARCHAR(10);

CREATE TEMPORARY TABLE temp_data AS
SELECT id, temperature, 
       CASE 
           WHEN temperature < (SELECT AVG(temperature) FROM weather) THEN 'cold'
           ELSE 'hot'
       END AS temperature_category
FROM weather;

UPDATE weather
JOIN temp_data
ON weather.id = temp_data.id
SET weather.temperature_category = temp_data.temperature_category;

DROP TEMPORARY TABLE temp_data;
drop table temp_data;


SET @avg_temp = (SELECT AVG(temperature) FROM weather);
SET SQL_SAFE_UPDATES = 0;
CREATE TEMPORARY TABLE temp_data AS
SELECT id, temperature, 
       CASE 
           WHEN temperature < @avg_temp THEN 'cold'
           ELSE 'hot'
       END AS temperature_category
FROM weather;

UPDATE weather
JOIN temp_data
ON weather.id = temp_data.id
SET data.temperature_category = temp_data.temperature_category;

DROP TEMPORARY TABLE temp_data;


SELECT * FROM weather;

-- 3. Can you check for all 4 consecutive days when the temperature was below 30 Fahrenheit

SELECT COUNT(*)
FROM (
  SELECT id, date, temperature, @prev_temp := temperature AS prev_temp
  FROM weather, (SELECT @prev_temp := null) var
  WHERE temperature < 30
) subquery
WHERE prev_temp < 30 AND
      (SELECT temperature 
       FROM weather 
       WHERE id = subquery.id + 1) < 30 AND
      (SELECT temperature 
       FROM weather 
       WHERE id = subquery.id + 2) < 30 AND
      (SELECT temperature 
       FROM weather 
       WHERE id = subquery.id + 3) < 30;


-- 4. Can you find the maximum number of days for which temperature dropped
WITH temp_drop AS (
  SELECT id, date, temperature,
         LAG(temperature) OVER (ORDER BY date) AS prev_temp
  FROM weather
), drop_groups AS (
  SELECT id, date, temperature,
         SUM(CASE WHEN temperature < prev_temp THEN 1 ELSE 0 END)
           OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS drop_group
  FROM temp_drop
)
SELECT MAX(num_days)
FROM (
  SELECT drop_group, COUNT(*) AS num_days
  FROM drop_groups
  GROUP BY drop_group
) subquery;

-- 5. Can you find the average humidity average from the dataset
-- ( NOTE:should contain the following clauses: group by, order by, date )

SELECT date, AVG(average_humidity) AS avg_humidity
FROM weather
GROUP BY date
ORDER BY date;


-- 6. Use the GROUP BY clause on the Date column and make a query to fetch details for average windspeed ( which is now windspeed done in task 3 )
SELECT date, AVG(average_windspeed) AS avg_windspeed
FROM weather
GROUP BY date
ORDER BY date;

-- 7.Please add the data in the dataset for 2034 and 2035 as well as forecast predictions for these years
-- ( NOTE:data consistency and uniformity should be maintained )



-- 8. If the maximum gust speed increases from 55mph, fetch the details for the next 4 days
SELECT date, maximum_gust_speed, temperature, average_humidity, average_dewpoint
FROM weather
WHERE date > (SELECT date
FROM weather
WHERE maximum_gust_speed > 55
ORDER BY date DESC
LIMIT 1)
ORDER BY date
LIMIT 4;

-- 9. Find the number of days when the temperature went below 0 degrees Celsius
SELECT Count(*) from weather where temperature < 0;


-- 10.Create another table with a “Foreign key” relation with the existing given data set.
