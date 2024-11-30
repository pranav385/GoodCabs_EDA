-- Q1. Top and Bottom Performing Cities
-- Identify the top 3 and bottom 3 cities by total trips over the entire analysis period.

(SELECT ct.city_name, count(tr.trip_id) as Trip_Count, 'Top 3' as Category FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
order by Trip_Count desc
limit 3)
union all
(SELECT ct.city_name, count(tr.trip_id) as Trip_Count, 'Bottom 3' as Category FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
order by Trip_Count asc
limit 3)
order by Trip_Count DESC;



-- Q2. Average Fare per Trip by City
-- Calculate the average fare per trip for each city and compare it with the city's average trip distance. 
-- Identify the cities with the highest and lowest average fare per trip to assess pricing efficiency across locations.

(SELECT ct.city_name, avg(tr.fare_amount) as Avg_Fare_Amount, avg(tr.distance_travelled_km) as Avg_Distance_Travelled,
'Highest Average Fare Per Trip' as Category
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
order by Avg_Fare_Amount desc
limit 1)
union all
(SELECT ct.city_name, avg(tr.fare_amount) as Avg_Fare_Amount, avg(tr.distance_travelled_km) as Avg_Distance_Travelled,
'Lowest Average Fare Per Trip' as Category
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
order by Avg_Fare_Amount asc
limit 1)
order by Avg_Fare_Amount desc;

-- For all city Average Fare and Avg_Distance_Travelled 

SELECT ct.city_name, avg(tr.fare_amount) as Avg_Fare_Amount, avg(tr.distance_travelled_km) as Avg_Distance_Travelled
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
order by Avg_Fare_Amount desc;



-- Q3. Average Ratings by City and Passenger Type
-- Calculate the average passenger and driver ratings for each city, segmented by passenger type (new vs. repeat). 
-- Identify cities with the highest and lowest average ratings.

(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating,
'Highest Rated by Repated Passenger' as Category 
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'repeated'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating desc
limit 1)
union all
(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating,
'Lowest Rated by Repated Passenger' as Category 
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'repeated'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating asc
limit 1)
union all
(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating,
'Highest new by New Passenger' as Category 
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'new'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating desc
limit 1)
union all
(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating,
'Lowest New by new Passenger' as Category 
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'new'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating asc
limit 1)
order by Passenger_Rating desc;

-- For all cities, analyze passenger ratings and driver ratings by passenger type. 

(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'repeated'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating desc
)
union all
(SELECT ct.city_name, tr.passenger_type, avg(tr.passenger_rating) as Passenger_Rating, avg(tr.driver_rating) as Driver_Rating
FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on ct.city_id = tr.city_id
where passenger_type = 'new'
group by ct.city_name, tr.passenger_type
order by Passenger_Rating desc
)
order by city_name, passenger_type;



-- Q4. Peak and Low Demand Months by City
-- For each city, identify the month with the highest total trips (peak demand) and the month with the lowest total trips (low demand). 
-- This analysis will help Goodcabs understand seasonal patterns and adjust resources accordingly.

with cte1 as (
SELECT ct.city_name, MONTHNAME(tr.date) as month_name, count(tr.trip_id) as Total_Trips FROM trips_db.fact_trips as tr
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name, MONTHNAME(tr.date)
),
cte2 as (
select city_name, month_name, Total_Trips,
dense_rank() over(partition by city_name order by Total_Trips desc) as rnk1
from cte1
),
cte3 as (
select city_name, month_name, Total_Trips,
dense_rank() over(partition by city_name order by Total_Trips asc) as rnk2
from cte1
),
cte4 as (
select ct2.city_name, ct2.month_name, ct2.Total_Trips, ct2.rnk1, ct3.rnk2 from cte2 as ct2
join cte3 as ct3 on ct2.city_name = ct3.city_name and ct2.month_name = ct3.month_name and ct2.Total_Trips = ct3.Total_Trips
) 
select city_name, month_name, Total_Trips from cte4
where rnk1 = 1 or rnk2 = 1;



-- Q5. Weekend vs. Weekday Trip Demand by City
-- Compare the total trips taken on weekdays versus weekends for each city over the six-month period. 
-- Identify cities with a strong preference for either weekend or weekday trips to understand demand variations.

with cte1 as (
SELECT ct.city_name, 
count(if(dt.day_type='Weekday', 1, null)) as Weekday_Count, count(if(dt.day_type='Weekend', 1, null)) as Weekend_Count
 FROM trips_db.fact_trips as tr
join trips_db.dim_date as dt on tr.date = dt.date
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name
)
select city_name, Weekday_Count, Weekend_Count,
case
when Weekday_Count>Weekend_Count then 'People prefer traviling on Weekdays'
when Weekday_Count<Weekend_Count then 'People prefer traviling on Weekends'
else 'Same'
end as Choice
from cte1;

--  City and month-wise passenger count for weekdays and weekends.

with cte1 as (
SELECT ct.city_name, monthname(dt.date) as month_name, 
count(if(dt.day_type='Weekday', 1, null)) as Weekday_Count, count(if(dt.day_type='Weekend', 1, null)) as Weekend_Count
 FROM trips_db.fact_trips as tr
join trips_db.dim_date as dt on tr.date = dt.date
join trips_db.dim_city as ct on tr.city_id = ct.city_id
group by ct.city_name, monthname(dt.date)
)
select city_name, Weekday_Count, Weekend_Count, month_name,
case
when Weekday_Count>Weekend_Count then 'People prefer traviling on Weekdays'
when Weekday_Count<Weekend_Count then 'People prefer traviling on Weekends'
else 'Same'
end as Choice
from cte1;



-- Q6. Repeat Passenger Frequency and City Contribution Analysis
-- Analyse the frequency of trips taken by repeat passengers in each city (e.g., % of repeat passengers taking 2 trips, 3 trips, etc.). 
-- Identify which cities contribute most to higher trip frequencies among repeat passengers, and examine if there are distinguishable patterns 
-- between tourism-focused and business-focused cities.

with cte1 as (
SELECT city_id,
    SUM(IF(trip_count = '2-Trips', repeat_passenger_count, 0)) AS two_trips,
    SUM(IF(trip_count = '3-Trips', repeat_passenger_count, 0)) AS three_trips,
    SUM(IF(trip_count = '4-Trips', repeat_passenger_count, 0)) AS four_trips,
    SUM(IF(trip_count = '5-Trips', repeat_passenger_count, 0)) AS five_trips,
    SUM(IF(trip_count = '6-Trips', repeat_passenger_count, 0)) AS six_trips,
    SUM(IF(trip_count = '7-Trips', repeat_passenger_count, 0)) AS seven_trips,
    SUM(IF(trip_count = '8-Trips', repeat_passenger_count, 0)) AS eight_trips,
    SUM(IF(trip_count = '9-Trips', repeat_passenger_count, 0)) AS nine_trips,
    SUM(IF(trip_count = '10-Trips', repeat_passenger_count, 0)) AS ten_trips
FROM trips_db.dim_repeat_trip_distribution
GROUP BY city_id
),
cte2 as (
SELECT city_id, sum(repeat_passenger_count) as total_passengers FROM trips_db.dim_repeat_trip_distribution
group by city_id
)

SELECT 
     ct.city_name,
    ROUND(ct1.two_trips * 100.0 / ct2.total_passengers, 2) AS "2-Trips",
    ROUND(ct1.three_trips * 100.0 / ct2.total_passengers, 2) AS "3-Trips",
    ROUND(ct1.four_trips * 100.0 / ct2.total_passengers, 2) AS "4-Trips",
    ROUND(ct1.five_trips * 100.0 / ct2.total_passengers, 2) AS "5-Trips",
    ROUND(ct1.six_trips * 100.0 / ct2.total_passengers, 2) AS "6-Trips",
    ROUND(ct1.seven_trips * 100.0 / ct2.total_passengers, 2) AS "7-Trips",
    ROUND(ct1.eight_trips * 100.0 / ct2.total_passengers, 2) AS "8-Trips",
    ROUND(ct1.nine_trips * 100.0 / ct2.total_passengers, 2) AS "9-Trips",
    ROUND(ct1.ten_trips * 100.0 / ct2.total_passengers, 2) AS "10-Trips"
FROM cte1 AS ct1 JOIN cte2 AS ct2 
ON ct1.city_id = ct2.city_id
join trips_db.dim_city as ct on ct1.city_id = ct.city_id;



-- Q7. Monthly Target Achievement Analysis for Key Metrics 
-- For each city, evaluate monthly performance against targets for total trips, new passengers, 
-- and average passenger ratings from targets_db. Determine if each metric met, exceeded, or missed the target, 
-- and calculate the percentage difference. Identify any consistent patterns in target achievement, particularly 
-- across tourism versus business-focused cities.

with cte1 as (
SELECT city_id, monthname(date) as month_name, count(trip_id) as Total_Trips, round(avg(passenger_rating),2) as Avg_Passenger_Rating FROM trips_db.fact_trips
group by city_id, monthname(date)
),
cte2 as (
select city_id, monthname(month) as month_name, sum(new_passengers) as Total_New_Passengers from trips_db.fact_passenger_summary
group by city_id, monthname(month)
),
cte3 as (
select ct1.city_id, ct.city_name, ct1.month_name, ct1.Total_Trips, tmt.total_target_trips, ct2.Total_New_Passengers,
tmnp.target_new_passengers, ct1.Avg_Passenger_Rating, tpgr.target_avg_passenger_rating
from cte1 as ct1
join cte2 as ct2 on ct1.city_id = ct2.city_id and ct1.month_name = ct2.month_name
join targets_db.monthly_target_new_passengers as tmnp on ct1.city_id = tmnp.city_id and ct1.month_name = monthname(tmnp.month)
join targets_db.monthly_target_trips as tmt on ct1.city_id = tmt.city_id and ct1.month_name = monthname(tmt.month)
join targets_db.city_target_passenger_rating as tpgr on ct1.city_id = tpgr.city_id
join trips_db.dim_city as ct on ct1.city_id = ct.city_id
)
select city_name, month_name, Total_Trips, total_target_trips, 
case
    when total_target_trips = 0 then 
        'No target set'
    when Total_Trips > total_target_trips then 
        CONCAT('Exceeds the target by ', ROUND((Total_Trips - total_target_trips) * 100.0 / total_target_trips, 2), '%')
    when Total_Trips < total_target_trips then 
        CONCAT('Lags the target by ', ROUND((Total_Trips - total_target_trips) * 100.0 / total_target_trips, 2), '%')
    else 
        'Same'
end as Trips_Target,
Total_New_Passengers, target_new_passengers,
case
    when target_new_passengers = 0 then 
        'No target set'
    when Total_New_Passengers > target_new_passengers then 
        CONCAT('Exceeds the target by ', ROUND((Total_New_Passengers - target_new_passengers) * 100.0 / target_new_passengers, 2), '%')
    when Total_New_Passengers < target_new_passengers then 
        CONCAT('Lags the target by ', ROUND((Total_New_Passengers - target_new_passengers) * 100.0 / target_new_passengers, 2), '%')
    else 
        'Same'
end as New_Passenger_Target,
Avg_Passenger_Rating, target_avg_passenger_rating,
case
    when target_avg_passenger_rating = 0 then 
        'No target set'
    when Avg_Passenger_Rating > target_avg_passenger_rating then 
        CONCAT('Exceeds the target by ', ROUND((Avg_Passenger_Rating - target_avg_passenger_rating) * 100.0 / target_avg_passenger_rating, 2), '%')
    when Avg_Passenger_Rating < target_avg_passenger_rating then 
        CONCAT('Lags the target by ', ROUND((Avg_Passenger_Rating - target_avg_passenger_rating) * 100.0 / target_avg_passenger_rating, 2), '%')
    else 
        'Same'
end as Avg_Rating_Target
from cte3; 



-- Q8. Highest and Lowest Repeat Passenger Rate (RPR%) by City and Month 
-- Analyse the Repeat Passenger Rate (RPR%) for each city across the six- month period. 
-- Identify the top 2 and bottom 2 cities based on their RPR% to determine which locations have the strongest and weakest rates.

with cte1 as (
SELECT ct.city_name, round(sum(pg.repeat_passengers) * 100 / sum(pg.total_passengers),2) as Repear_Passenger_Rate FROM trips_db.fact_passenger_summary as pg
join trips_db.dim_city as ct on pg.city_id = ct.city_id
group by ct.city_name
)
(select city_name, Repear_Passenger_Rate, 'Top 2' as Category from cte1
order by Repear_Passenger_Rate desc
limit 2)
union all
(select city_name, Repear_Passenger_Rate, 'Bottom 2' as Category from cte1
order by Repear_Passenger_Rate asc
limit 2)
order by Repear_Passenger_Rate desc;


-- . Similarly, analyse the RPR% by month across all cities and identify the months with the highest and lowest repeat passenger rates. 
-- This will help to pinpoint any seasonal patterns or months with higher repeat passenger loyalty.

with cte1 as (
SELECT ct.city_name, dt.month_name, pg.total_passengers, pg.repeat_passengers,
round(pg.repeat_passengers * 100 / pg.total_passengers,2) as monthly_repeat_passenger_rate
 FROM trips_db.fact_passenger_summary as pg
join trips_db.dim_city as ct on pg.city_id = ct.city_id
join (SELECT distinct(start_of_month), month_name FROM trips_db.dim_date) as dt on dt.start_of_month = pg.month
)
select city_name, month_name, total_passengers, repeat_passengers, monthly_repeat_passenger_rate from(
select city_name, month_name, total_passengers, repeat_passengers, monthly_repeat_passenger_rate,
dense_rank() over(partition by city_name order by monthly_repeat_passenger_rate desc) as rnk1,
dense_rank() over(partition by city_name order by monthly_repeat_passenger_rate asc) as rnk2
from cte1) as sq1
where rnk1=1 or rnk2=1;
