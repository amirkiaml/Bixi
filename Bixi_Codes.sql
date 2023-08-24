###### Exploratory Queries ######

USE bixi;

DESC trips;
Select * from trips
LIMIT 10;

DESC stations;
Select * from stations
LIMIT 10;


############# Question 1 ###############

-- Q1.1. The total number of trips for the year of 2016.
SELECT count(id) FROM trips
WHERE YEAR(start_date) = 2016;

-- Q1.3. The total number of trips for the year of 2016 broken down by month.
SELECT MONTH(start_date) AS month_2016, count(id)
FROM trips
GROUP BY month_2016;

-- Q1.5. The average number of trips a day for each year-month combination in the dataset.

SELECT YEAR(start_date) AS year_, MONTH(start_date) AS month_, ROUND(COUNT(DAY(start_date))/COUNT(DISTINCT DAY(start_date))) AS daily_trip_count_avg
FROM trips
GROUP BY year_, month_;

-- Q1.6. Save your query results from the previous question (Q1.5) by creating a table called working_table1.
DROP TABLE IF EXISTS workingtable1;
CREATE TABLE workingtable1 AS
SELECT YEAR(start_date) AS year_, MONTH(start_date) AS month_, ROUND(COUNT(DAY(start_date))/COUNT(DISTINCT DAY(start_date))) AS daily_trip_count_avg
FROM trips
GROUP BY year_, month_;


############# Question 2 ###############

-- Q2.1. The total number of trips in the year 2017 broken down by membership status (member/non-member).

SELECT is_member, count(*) AS trip_count
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY is_member
ORDER BY is_member;

-- Q2.2. The percentage of total trips by members for the year 2017 broken down by month.

-- Method 1:
SELECT MONTH(start_date) AS month_2017, AVG(is_member) AS membe_trip_percentage
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY month_2017
ORDER BY month_2017;

-- Method 2:
SELECT a.Year_, a.Month_, a.Trip_Count_Members, b.Total_Trip_Count, a.Trip_Count_Members/b.Total_Trip_Count AS Ratio_of_Travel
FROM
(SELECT YEAR(start_date) AS Year_, MONTH(start_date) AS Month_, COUNT(DAY(start_date)) AS Trip_Count_Members
FROM trips
WHERE is_member = 1 AND YEAR(start_date) = 2017
GROUP BY YEAR(start_date), MONTH(start_date)) AS a
JOIN
(SELECT YEAR(start_date) AS Year_, MONTH(start_date) AS Month_, COUNT(DAY(start_date)) AS Total_Trip_Count
FROM trips
WHERE YEAR(start_date) = 2017
GROUP BY YEAR(start_date), MONTH(start_date)) AS b
ON a.Month_ = b.Month_
ORDER BY a.Month_, a.Trip_Count_Members DESC;

############# Question 3 ###############

-- Q3.1. At which time(s) of the year is the demand for Bixi bikes at its peak?

SELECT YEAR(start_date) AS year_, MONTH(start_date) AS month_, count(id) AS trp_count
FROM trips
GROUP BY year_, month_
ORDER BY year_, trp_count DESC;

############# Question 4 ###############

-- Q4.1. What are the names of the 5 most popular starting stations? Determine the answer without using a subquery.

SELECT * FROM trips;
SELECT * FROM stations;

SELECT s.name, count(t.start_station_code) AS num_trips
FROM trips AS t
JOIN stations AS s
ON t.start_station_code = s.code
GROUP BY start_station_code
ORDER BY num_trips DESC
LIMIT 5;

-- Q4.2. Solve the same question as Q4.1, but now use a subquery. Is there a difference in query run time between 4.1 and 4.2? Why or why not?

# Method 1:
SELECT s.name, s.code, t.num_trips FROM 
	(SELECT start_station_code AS start_code, count(start_station_code) AS num_trips
	FROM trips
	GROUP BY start_code
	ORDER BY num_trips DESC
	LIMIT 5) AS t
JOIN stations AS s
ON s.code = t.start_code;

# Method 2:
SELECT s.name,
	(
	SELECT COUNT(*)
	FROM trips AS t
	WHERE t.start_station_code = s.code
    )
AS num_trips									
FROM stations AS s
ORDER BY num_trips DESC
LIMIT 5;

############# Question 5 ###############

-- Q5.1. How is the number of starts and ends distributed for the station Mackay / de Maisonneuve throughout the day?
SELECT starts_.time_of_day, starts_.num_starts, ends_.num_ends 
FROM
    (SELECT *, count(start_date) AS num_starts,
		CASE
		   WHEN HOUR(start_date) BETWEEN 7 AND 11 THEN "morning"
		   WHEN HOUR(start_date) BETWEEN 12 AND 16 THEN "afternoon"
		   WHEN HOUR(start_date) BETWEEN 17 AND 21 THEN "evening"
		   ELSE "night"
	END AS "time_of_day"
	FROM trips AS t
	WHERE start_station_code = 6100
	GROUP BY time_of_day
    ORDER BY num_starts DESC) AS starts_
    
    JOIN
 
	(SELECT *, count(end_date) as num_ends,
		CASE
		   WHEN HOUR(end_date) BETWEEN 7 AND 11 THEN "morning"
		   WHEN HOUR(end_date) BETWEEN 12 AND 16 THEN "afternoon"
		   WHEN HOUR(end_date) BETWEEN 17 AND 21 THEN "evening"
		   ELSE "night"
	END AS "time_of_day"
	FROM trips AS t
	WHERE end_station_code = 6100
	GROUP BY time_of_day
    ORDER BY num_ends DESC) AS ends_
    
    ON starts_.time_of_day = ends_.time_of_day;
    
############# Question 6 ###############


-- Q6.1. First, write a query that counts the number of starting trips per station.
SELECT start_station_code, count(*) AS start_trip_count
FROM trips
GROUP BY start_station_code
ORDER BY start_trip_count DESC;

-- Q6.2. Second, write a query that counts, for each station, the number of round trips.
SELECT start_station_code, count(*) AS round_trip_count
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code
ORDER BY round_trip_count DESC;

-- Q6.3. Combine the above queries and calculate the fraction of round trips to the total number of starting trips for each station.
SELECT s.start_station_code, s.start_trip_count/round_trip_count AS round_to_total_trips
FROM
(SELECT start_station_code, count(*) AS start_trip_count
FROM trips
GROUP BY start_station_code
ORDER BY start_trip_count DESC) AS s
JOIN 
(SELECT start_station_code, count(*) AS round_trip_count
FROM trips
WHERE start_station_code = end_station_code
GROUP BY start_station_code
ORDER BY round_trip_count DESC) AS r
ON s.start_station_code = r.start_station_code;

-- Q6.4. Filter down to stations with at least 500 trips originating from them and having at least 10% of their trips as round trips.

# Methos 1:
SELECT s.start_station_code, s.start_trip_count/round_trip_count AS round_to_total_trips
FROM
	(SELECT start_station_code, count(*) AS start_trip_count
	FROM trips
	GROUP BY start_station_code
	HAVING start_trip_count >=500
	ORDER BY start_trip_count DESC) AS s
JOIN 
	(SELECT start_station_code, count(*) AS round_trip_count
	FROM trips
	WHERE start_station_code = end_station_code
	GROUP BY start_station_code
	HAVING round_trip_count >=.1
	ORDER BY round_trip_count DESC) AS r
	ON s.start_station_code = r.start_station_code;

SELECT *
FROM
	(SELECT f.code_, f.total_starting_trips, g.round_trips,  g.round_trips/f.total_starting_trips AS ratio_
	FROM
		(SELECT start_station_code AS code_, COUNT(*) AS total_starting_trips
		FROM trips
		GROUP BY start_station_code) AS f
	JOIN
		(SELECT start_station_code AS start_, end_station_code AS end_, COUNT(*) AS round_trips
		FROM trips
		GROUP BY start_station_code, end_station_code
		HAVING start_station_code = end_station_code) AS g
	ON f.code_ = g.start_) AS h
WHERE total_starting_trips>= 500 AND ratio_>=.10;


#### Q6.5. Where would you expect to find stations with a high fraction of round trips? Describe why and justify your reasoning.

#### Answer: Around lakes and riversides (particularly Lake Saint Luis in Montreal), parks, and green areas (such as Jean Drapeau park, Domaine Saint-Paul), Sherbrooke Street West. 
#### Reason: We can JOIN the previous table to the stations table to ontain latitudes and longitudes of the popular stations (query below). And external search, using the wbsite
#### https://www.latlong.net, shows that the relevant geographic coordinations around around the areas mentioned above. (Use the schema https://www.latlong.net/c/?lat=[...]&long=[...] for finding
#### specific coordinations on the map; for example, https://www.latlong.net/c/?lat=45.4671&long=-73.5426)
#### Here's the query that does the JOIN:

SELECT *
FROM
	(SELECT f.code_, f.total_starting_trips, g.round_trips,  g.round_trips/f.total_starting_trips AS ratio_
	FROM
		(SELECT start_station_code AS code_, COUNT(*) AS total_starting_trips
		FROM trips
		GROUP BY start_station_code) AS f
	JOIN
		(SELECT start_station_code AS start_, end_station_code AS end_, COUNT(*) AS round_trips
		FROM trips
		GROUP BY start_station_code, end_station_code
		HAVING start_station_code = end_station_code) AS g
	ON f.code_ = g.start_) AS h
JOIN stations AS s
ON s.code = h.code_
WHERE total_starting_trips>= 500 AND ratio_>=.10
ORDER BY ratio_ DESC;


############# Question 7 ###############

-- Q7.1. What are the top 5 stations with the highest number of incoming trips?
SELECT s.name AS station_name,
       COUNT(t.end_station_code) AS incoming_trip_count
FROM trips AS t
JOIN stations AS s ON t.end_station_code = s.code
GROUP BY station_name
ORDER BY incoming_trip_count DESC
LIMIT 5;

-- Q7.2. For the top 5 starting stations, what are the most common end stations?

-- First, get the top 5 starting stations
CREATE TEMPORARY TABLE top_starting_stations AS
SELECT s.name AS starting_station
FROM trips AS t
JOIN stations AS s ON t.start_station_code = s.code
GROUP BY starting_station
ORDER BY COUNT(*) DESC
LIMIT 5;

-- Now, for each of the top 5 starting stations, find the most common end stations
SELECT ts.starting_station,
       s_end.name AS most_common_end_station,
       COUNT(*) AS trip_count
FROM trips AS t
JOIN stations AS s_start ON t.start_station_code = s_start.code
JOIN stations AS s_end ON t.end_station_code = s_end.code
JOIN top_starting_stations AS ts ON s_start.name = ts.starting_station
GROUP BY ts.starting_station, most_common_end_station
ORDER BY ts.starting_station, trip_count DESC;


############# Question 8 ###############

-- Q8.1. How many trips were taken by registered users compared to casual users each year?
SELECT YEAR(start_date) AS year_,
       SUM(CASE WHEN is_member = 1 THEN 1 ELSE 0 END) AS registered_user_trips,
       SUM(CASE WHEN is_member = 0 THEN 1 ELSE 0 END) AS casual_user_trips
FROM trips
GROUP BY year_
ORDER BY year_;

-- Q8.2. What is the most common type of membership status among users who take long trips (over 30 minutes)?
SELECT is_member,
       COUNT(*) AS trip_count
FROM trips
WHERE TIMESTAMPDIFF(MINUTE, start_date, end_date) > 30
GROUP BY is_member
ORDER BY trip_count DESC
LIMIT 1;