
/* maximal departure delay in minutes for each airline */

select L_AIRLINE_ID.Name , max(DepDelayMinutes) as MaxAirlineDepDelay
from  al_perf left join L_AIRLINE_ID on  L_AIRLINE_ID.ID = al_perf.DOT_ID_Reporting_Airline
group by L_AIRLINE_ID.ID
order by MaxAirlineDepDelay asc;



/* Maximal early departures in minutes for each airline*/

select L_AIRLINE_ID.Name
from al_perf left join L_AIRLINE_ID on al_perf.DOT_ID_Reporting_Airline = L_AIRLINE_ID.ID
group by al_perf.DOT_ID_Reporting_Airline
having al_perf.DOT_ID_Reporting_Airline is not null AND min(DepDelayMinutes) is not null
order by min(DepDelayMinutes) desc;


select distinct L_WEEKDAYS.Day as Day_Week, 
                      sum(Flights) as total_flights,
                      rank() over (order by sum(Flights) desc) as weekday_rank
from al_perf join L_WEEKDAYS on al_perf.DayOfWeek = L_WEEKDAYS.Code
where al_perf.Cancelled = 0.00
group by DayOfWeek
order by weekday_rank asc;





/*airport that has the highest average departure delay among all airports */
 

select L_AIRPORT_ID.Name, al_perf.OriginAirportID, avg(case when DepDelayMinutes <0 then 0 else DepDelayMinutes end) as avg_delay
from al_perf left join L_AIRPORT_ID on L_AIRPORT_ID.ID = al_perf.OriginAirportID
group by al_perf.OriginAirportID
order by avg_delay desc
limit 1;
/* 1 row returned */

 
 
 
/*for each airline, airport with the highest average departure delay*/

with airline_airport_delay_table as 
(select L_AIRLINE_ID.Name as airline_name,
       al_perf.OriginAirportID as OriginAirportID,
       al_perf.DOT_ID_Reporting_Airline as DOT_ID_Reporting_Airline ,
       L_AIRPORT_ID.Name as airport_name,
       avg(DepDelayMinutes) as avg_dep_delay
from al_perf left join L_AIRPORT_ID on L_AIRPORT_ID.ID = al_perf.OriginAirportID 
	 left join L_AIRLINE_ID on L_AIRLINE_ID.ID = al_perf.DOT_ID_Reporting_Airline
group by al_perf.DOT_ID_Reporting_Airline, al_perf.OriginAirportID 
order by avg_dep_delay)
select airline_name, airport_name, max(avg_dep_delay)as max_avg_dep_delay
from airline_airport_delay_table
where OriginAirportID is not null and DOT_ID_Reporting_Airline is not null 
group by  DOT_ID_Reporting_Airline;
/* 2 rows returned */

 
/*canceled flights */
select sum(Cancelled) as no_cancelled_flights
from al_perf;

/*the most frequent reason for each departure airport */

with airport_cancellation_major_reason_table as 
(select L_AIRPORT_ID.Name as Airport_name,
       al_perf.OriginAirportID as OriginAirportID,
       al_perf.CancellationCode as CancellationCode,
       L_CANCELATION.Reason as cancellation_reason,
       count(cancelled) as no_cancellations
from al_perf left join L_AIRPORT_ID on L_AIRPORT_ID.ID = al_perf.OriginAirportID
			 left join L_CANCELATION on al_perf.CancellationCode = L_CANCELATION.Code
where Cancelled = 1
group by al_perf.OriginAirportID, al_perf.CancellationCode
order by no_cancellations desc)
select Airport_name, cancellation_reason, max(no_cancellations) as max_cancellations
from airport_cancellation_major_reason_table
group by OriginAirportID;

/* For each day, the average number of flights over the preceding 3 days. */

with date_flights_table as 
(select FlightDate, count(Flights) as total_flights
from al_perf
where al_perf.Cancelled = 0.0
group by FlightDate
order by FlightDate)
select FlightDate, avg(total_flights) over (order by FlightDate asc rows 3 preceding) as Avg_flights
from date_flights_table;
