-- ==========================================================================================
-- SQ1: Which dark stores experience the highest number of stock-outs?
-- ==========================================================================================

-- SQ1
-- Which dark stores experience the highest number of stock-outs?
-- =============================================X===================================================


-- =================================================================================================
--       1. Which dark stores have highest total number of stock-outs?
--       2. At which location are these dark stores located? 
-- ==================================================================================================
### SQL Evidence

select dark_stores.dark_store_id, 
       dark_stores.store_name,
       count(inventory_snapshots.is_stockout) as 
                                                total_stockout, 
                                                dark_stores.locality, 
                                                dark_stores.city
from  inventory_snapshots 
join dark_stores on 
                   dark_stores.dark_store_id = inventory_snapshots.dark_store_id
where is_stockout = "True"
group by inventory_snapshots.dark_store_id ,
          dark_stores.locality,
          dark_stores.city, 
          dark_stores.store_name
order by total_stockout DESC 
limit 10

-- Finding :
-- DS002 -New Town Dark Store has higest number of stock-out
-- DS002 is located in New Town, Kolkata

-- ===============================================================================================================
--   	3. What percentage does each of these dark stores contribute to total stock-out?
-- ===============================================================================================================

### SQL Evidence

WITH total_stockout_table as( 
                             SELECT dark_store_id,
                             count(*) as total_stockout
							FROM inventory_snapshots
                            WHERE is_stockout = "True"
                            GROUP BY dark_store_id), 
									grand_total as ( 
                                                    SELECT SUM(total_stockout) as total			
                                                    FROM total_stockout_table)
SELECT dark_store_id, total_stockout, 
       (total_stockout_table.total_stockout/grand_total.total)*100 as percentage 
FROM total_stockout_table
CROSS JOIN  grand_total
ORDER BY percentage DESC

-- Finding :
-- DS002/New Town contributes approximately 26.58% of all stock-out events.
-- DS005/Jadavpur contributes approximately 16.73% of all stock-out events.
-- DS009/Rajarhat contributes approximately 11.88% of all stock-out events.

-- ===============================================================================================================
--        4. When does this stock-out happen (random or at a specific time)?
-- ===============================================================================================================

### SQL Evidence 

SELECT hour(stockout_started_at) as Hours ,
            count(*) as total_stockout
FROM stockout_events
GROUP BY hour(stockout_started_at)
order by total_stockout desc

-- Findings :
-- Stock-out events are concentrated during the evening, with the highest number occurring between 7 PM and 10 PM 
-- peaking at 10 PM with 780 events.

-- ================================================================================================================
--        6. Are stock-outs happening everyday or just on some days or months?
-- ================================================================================================================

### SQL Evidence 
-- Query 1: Find total analysis period

SELECT min(snapshot_date) as start_date, max(snapshot_date) as end_date, datediff(max(snapshot_date),min(snapshot_date)) +1 as total_days
FROM inventory_snapshots

-- Query 2: Find number of days with stock-outs

SELECT COUNT(distinct snapshot_date) as total_stockout_days
FROM inventory_snapshots
WHERE is_stockout = 'True'

-- Query 3: Find which date has most stock-out

SELECT date(stockout_started_at) as 'date' , 
	   count(*) as total_stockout
FROM stockout_events
GROUP BY date(stockout_started_at)
order by total_stockout DESC
LIMIT 1

-- Findings:
-- Analysis period: 2026-03-01 to 2026-06-28 = 120 days.
-- Stock-outs were observed on 120 distinct days.
-- Therefore, stock-outs occurred on 100% of the days.
-- on 2026-03-14 maxium number of stocked-outs is observed with total 101 stock-out

-- =================================================================================================================
--         7.	Which stores have the highest total stock-out duration?
-- =================================================================================================================

### SQL Evidence 

WITH stockout_evnt_hrs as (
						    SELECT dark_store_id,
                            stockout_started_at, 
                            stockout_observed_end_at,
                            CASE WHEN stockout_observed_end_at<stockout_started_at 
                            THEN date_add(stockout_observed_end_at, INTERVAL 1 DAY) 
                            ELSE stockout_observed_end_at 
                            END as stockout_observed_end_at_corrected
                            FROM  stockout_events )
SELECT dark_store_id,
	   sum(timestampdiff(hour, stockout_started_at,stockout_observed_end_at_corrected)) 
       as total_duration
FROM stockout_evnt_hrs
group by dark_store_id
order by total_duration DESC
limit 8

-- Findings :
-- DS002 has the highest cumulative stock-out duration at 12,617 hours 
-- DS005 comes next at 7306 hours.
