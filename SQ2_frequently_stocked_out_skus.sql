-- ==========================================================================================
-- SQ2: Which SKUs experience stock-outs most frequently?
-- ==========================================================================================

--                          SQ2 Which SKUs experience stock-outs most frequently?
-- ===========================================================================================================================


-- ==========================================================================================================================
-- 	       1. Which SKUs have the highest total hours of stock-out?
-- ==========================================================================================================================
### SQL Evidence 

WITH stockout_evnt_hrs as (
						    SELECT dark_store_id,
                                   stockout_started_at, 
								   stockout_observed_end_at,
                                   sku_id,
                            CASE WHEN stockout_observed_end_at<stockout_started_at 
                            THEN date_add(stockout_observed_end_at, INTERVAL 1 DAY) 
                            ELSE stockout_observed_end_at 
                            END as stockout_observed_end_at_corrected
                            FROM  stockout_events )
SELECT stockout_evnt_hrs.sku_id,products.product_name,
	   sum(timestampdiff(hour, stockout_started_at,stockout_observed_end_at_corrected)) 
       as total_duration
FROM stockout_evnt_hrs
join products on stockout_evnt_hrs.sku_id = products.sku_id
group by stockout_evnt_hrs.sku_id , products.product_name
order by total_duration DESC
limit 8 

-- Finding 
-- SKU0002	"Mother Dairy Toned Milk 500ml" has the highest cumulative stock-out duration at 2,023 hours
-- SKU0050 "Apple Royal Gala 4 pcs" comes next at 1905 hours 
-- SKU0049 "Green Chilli 100g" comes next at 1845 hours .

-- ====================================================================================================
--            2. Which SKUs repeatedly appear in highest number of stock-out observations across multiple days?
-- ====================================================================================================
### SQL Evidence 

SELECT stockout_events.sku_id, products.product_name, count(DISTINCT date( stockout_started_at)) as stockout_days ,count(stockout_started_at) as total_events
FROM stockout_events
join products on stockout_events.sku_id = products.sku_id 
group by stockout_events.sku_id ,products.product_name
HAVING COUNT(DISTINCT DATE(stockout_started_at)) > 1 AND total_events >100
order by stockout_days desc

-- 14 products where identifed to be in most frequent srtock-out list with over 100 + highest number of stock-out observations .
-- Higest number of stockout being SKU0049	"Green Chilli 100g" apprearing out of stock 94 days out of 127 highest number of stock-out observations
-- followed by SKU0011	"Chaas 500ml"	apprearing out of stock 86 days out of 133 total highest number of stock-out observations.
-- SKU0050	"Apple Royal Gala 4 pcs" also apperd in the list with 85 stock-out days form 127 total highest number of stock-out observations.

-- ==================================================================================================================================
--                Q3. What is the average time between replenishment requests for each SKU?
-- ==================================================================================================================================
### SQL Evidence 

WITH hsot AS (SELECT sku_id, count(DISTINCT date( stockout_started_at)) as stockout_days ,count(stockout_started_at) as total_events
FROM stockout_events
group by sku_id
HAVING COUNT(DISTINCT DATE(stockout_started_at)) > 1
order by stockout_days desc)
SELECT t.sku_id,products.product_name, avg(TIMESTAMPDIFF(HOUR, previous_req , requested_at)) as avg_hrs_diff
FROM(SELECT sku_id, requested_at ,LAG(requested_at) OVER (partition by sku_id order by requested_at) as previous_req
      FROM replenishments
	) as t
CROSS JOIN hsot
JOIN products on products.sku_id = t.sku_id
WHERE t.sku_id = hsot.sku_id
group by sku_id ,products.product_name
HAVING avg(TIMESTAMPDIFF(HOUR, previous_req , requested_at)) < 8
order by avg_hrs_diff ASC

-- Findigs 
-- 26 products where identifed to have more than 2 re-stock request a day 
-- SKU0050	"Apple Royal Gala 4 pcs " , SKU0012	"Mozzarella Cheese 200g", SKU0049 "Green Chilli 100g" restock is being requested every 5 hrs 
-- SKU0006	"Lassi Sweet 200m"l ,SKU0001 "Amul Taaza Milk 1L" restock is being requested every 6 hrs
-- SKU0002	"Mother Dairy Toned Milk 500ml", SKU0017 "Red Bull 250ml", SKU0005	"Britannia Cheese Slices" restock is being requested every 7 hrs

-- ===================================================================================================================================
--         Q4. Are these high stock-out SKUs also high-demand SKUs?
-- ===================================================================================================================================
### SQL Evidence 

WITH hsot AS (SELECT sku_id, count(DISTINCT date( stockout_started_at)) as stockout_days ,count(stockout_started_at) as total_events
FROM stockout_events
group by sku_id
HAVING COUNT(DISTINCT DATE(stockout_started_at)) > 1)

SELECT order_items.sku_id ,products.product_name,  hsot.stockout_days , hsot.total_events, sum( order_items.quantity) as total_qnty, count( DISTINCT order_id) as total_orders
FROM order_items
JOIN hsot on hsot.sku_id = order_items.sku_id
join products on order_items.sku_id = products.sku_id 
Group by order_items.sku_id,products.product_name
ORDER BY total_orders DESC

-- Findings
-- "Several high-stockout SKUs also exhibit high observed demand, 
-- suggesting demand pressure may contribute to stockout frequency. However, the relationship is not universal, 
-- as some high-demand SKUs experience comparatively few stockout events.
