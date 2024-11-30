-- 1. Business Request - 
-- City-Level Fare and Trip Summary Report 
-- Generate a report that displays the total trips, average fare per km, average fare per trip, and the percentage contribution of each 
-- city's trips to the overall trips. This report will help in assessing trip volume, pricing efficiency, and each city's contribution to 
-- the overall trip count.

select ct.city_name, trip.total_trips, trip.avg_fare_per_km, trip.avg_fare_per_trip,
trip.perct as '%_contribution_to_total_trips' from (
SELECT city_id, count(trip_id) as total_trips, round(sum(fare_amount) / sum(distance_travelled_km),2) as avg_fare_per_km, 
round(sum(fare_amount) / count(trip_id),2) as avg_fare_per_trip,
round(count(trip_id) * 100 / (select count(trip_id) from trips_db.fact_trips),2) as
 perct
FROM trips_db.fact_trips
group by city_id) as trip
join trips_db.dim_city as ct
on trip.city_id = ct.city_id;



-- 2. Business Request -
-- Monthly City-Level Trips Target Performance Report
-- Generate a report that evaluates the target performance for trips at the monthly and city level. For each city and month, 
-- compare the actual total trips with the target trips and categorize the performance as follows:
-- If actual trips are greater than target trips, mark it as "Above Target".
-- If actual trips are less than or equal to target trips, mark it as "Below Target".
-- Additionally, calculate the % difference between actual and target trips to quantify the performance gap.

with cte1 as (
SELECT ct.city_id, ct.city_name, dt.month_name, dt.start_of_month, count(trip.trip_id) as actual_trips from 
trips_db.dim_city as ct join trips_db.fact_trips as trip on ct.city_id = trip.city_id
join trips_db.dim_date as dt on dt.date = trip.date
group by ct.city_id, ct.city_name, dt.month_name, dt.start_of_month
),
cte2 as (
select ct1.*, tg.total_target_trips from cte1 as ct1
join targets_db.monthly_target_trips as tg on ct1.start_of_month = tg.month and ct1.city_id = tg.city_id
)

select city_name, month_name, actual_trips, total_target_trips, 
case
when actual_trips > total_target_trips then "Above Target"
when actual_trips < total_target_trips then "Below Target"
else "Same"
end as performance_status,
round((actual_trips - total_target_trips) * 100 / total_target_trips,2) as "%_difference"
 from cte2;
 
 
 
 -- 3. Business Request -
-- City-Level Repeat Passenger Trip Frequency Report
-- Generate a report that shows the percentage distribution of repeat passengers by then umber of trips they have taken in each city. 
-- Calculate the percentage of repeat passengers who took 2 trips, 3 trips, and so on, up to 10 trips.
-- Each column should represent a trip count category, displaying the percentage of repeat passengers who fall into that category 
-- out of the total repeat passengers for that city.
-- This report will help identify cities with high repeat trip frequency, which can indicate strongcustomer loyalty or frequent usage patterns.

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



-- 4. Business Request -
-- Identify Cities with Highest and Lowest Total New Passengers
-- Generate a report that calculates the total new passengers for each city and ranks them based on this value. 
-- Identify the top 3 cities with the highest number of new passengers as well as the bottom 3 cities with the lowest number of new passengers, 
-- categorizing them as "Top 3" or "Bottom 3" accordingly.

with cte1 as (
select city_name, total_new_passengers, 'Top 3' as city_category from (
select ct.city_name, np.total_new_passengers,
dense_rank() over(order by np.total_new_passengers desc) as rnk
 from (
SELECT city_id, sum(new_passengers) as total_new_passengers FROM trips_db.fact_passenger_summary
group by city_id) as np
join trips_db.dim_city as ct
on np.city_id = ct.city_id) as sq1
order by rnk asc
limit 3
),
cte2 as (
select city_name, total_new_passengers, 'Bottom 3' as city_category from (
select ct.city_name, np.total_new_passengers,
dense_rank() over(order by np.total_new_passengers asc) as rnk
 from (
SELECT city_id, sum(new_passengers) as total_new_passengers FROM trips_db.fact_passenger_summary
group by city_id) as np
join trips_db.dim_city as ct
on np.city_id = ct.city_id) as sq1
order by rnk asc
limit 3
)
select city_name, total_new_passengers, city_category from cte1
union
select city_name, total_new_passengers, city_category from cte2;



-- 5. Business Request -
-- Identify Month with Highest Revenue for Each City
-- Generate a report that identifies the month with the highest revenue for each city. For each city, display the month_name, 
-- the revenue amount for that month, and the percentage contribution of that month's revenue to the city's total revenue.

with cte1 as (
SELECT dt.month_name, ct.city_name, sum(rv.fare_amount) as Revenue FROM trips_db.fact_trips as rv
join trips_db.dim_date as dt on rv.date = dt.date
join trips_db.dim_city as ct on rv.city_id = ct.city_id
group by dt.month_name, ct.city_name
),
cte2 as (
select city_name, month_name, Revenue from(
select city_name, month_name, Revenue,
dense_rank() over(partition by city_name order by Revenue desc) as rnk
 from cte1) as sq1
 where rnk = 1
 ),
 cte3 as (
 select city_name, sum(Revenue) as Total_Revenue from cte1
 group by city_name
 )
 
 select ct2.city_name, ct2.month_name as highest_revenue_month, ct2.Revenue, round(ct2.Revenue * 100 / ct3.Total_Revenue,2) as 'percentage_contribution (%)'
 from cte2 as ct2 join cte3 as ct3 on ct2.city_name = ct3.city_name;
 
 
 
-- 6. Business Request -
-- Repeat Passenger Rate Analysis
-- Generate a report that calculates two metrics:
-- Monthly Repeat Passenger Rate: Calculate the repeat passenger rate for each cityand month by comparing the number of repeat passengers 
-- to the total passengers.
-- City-wide Repeat Passenger Rate: Calculate the overall repeat passenger rate foreach city, considering all passengers across months.
-- These metrics will provide insights into monthly repeat trends as well as the overall repeat behaviour for each city.

with cte1 as (
SELECT ct.city_name, dt.month_name, pg.total_passengers, pg.repeat_passengers,
round(pg.repeat_passengers * 100 / pg.total_passengers,2) as monthly_repeat_passenger_rate
 FROM trips_db.fact_passenger_summary as pg
join trips_db.dim_city as ct on pg.city_id = ct.city_id
join (SELECT distinct(start_of_month), month_name FROM trips_db.dim_date) as dt on dt.start_of_month = pg.month
),
cte2 as (
select city_name, round(sum(repeat_passengers) * 100 /sum(total_passengers),2) as city_repeat_passenger_rate from cte1
group by city_name
)
select ct1.city_name, ct1.month_name, ct1.total_passengers, ct1.repeat_passengers, ct1.monthly_repeat_passenger_rate,
 ct2.city_repeat_passenger_rate from cte1 as ct1
 join cte2 as ct2 on ct1.city_name = ct2.city_name;