-- ==========================================================================================
-- SQ3: Which product categories contribute the most to stock-outs?
-- ==========================================================================================

--                             SQ3 Which product categories contribute the most to stock-outs?
-- ===========================================================================================================================


-- ==============================================================================================================================
--         Q1. What are average hours of stock-out for each product category?
-- ==============================================================================================================================
### SQL Evidence 

SELECT products.category , Round(avg(
                                      timestampdiff( HOUR, stockout_started_at, CASE WHEN stockout_observed_end_at< stockout_started_at THEN date_add(stockout_observed_end_at, INTERVAL 1 DAY ) ELSE stockout_observed_end_at END
                                                   )       
									),2) as Avg_hrs
FROM stockout_events
JOIN products on stockout_events.sku_id = products.sku_id
Group by category
order by Avg_hrs Desc

-- Findings
-- Category   Average in hours
   Fresh Produce	9.04
   Dairy	        8.72
   Health	        5.69
   Baby Care	    5.60
   Beverages	    5.57
   Instant Foods	5.47
   Breakfast	    5.24
   Personal Care	4.89
   Pet Care	        4.72
   Sweets	        4.66
   Bakery	        4.21
   Frozen	        4.04
   Household	    3.91
   Snacks	        3.68

-- ===================================================================================================================
--          Q2 Which categories have the highest number of stockout observations?
-- ===================================================================================================================
### SQL Evidence 

SELECT products.category, SUM( CASE WHEN is_stockout = 'TRUE' THEN 1 ELSE 0 END) as Total_stockout
FROM inventory_snapshots
JOIN products on inventory_snapshots.sku_id = products.sku_id
Group by products.category
order by Total_stockout desc

-- Findings
-- data suggests Dairy based products has higets stock-out SKUs with 6790 total stock outs 
-- Followed by Fresh Produce with 6570 total stock-outs

-- =====================================================================================================================
--      Q3.	What percentage of total stock-outs is contributed by each category?
-- =====================================================================================================================
### SQL Evidence 

WITH t AS (SELECT products.category, SUM( CASE WHEN is_stockout = 'TRUE' THEN 1 ELSE 0 END) as Total_stockout
FROM inventory_snapshots
JOIN products on inventory_snapshots.sku_id = products.sku_id
Group by products.category), grand_total as (SELECT SUM( CASE WHEN is_stockout = 'TRUE' THEN 1 ELSE 0 END) as gt 
FROM inventory_snapshots)
SELECT t.category ,t.Total_stockout, ROUND((Total_stockout/gt )*100.0 ,2) as stockout_contribution_percent
FROM t
CROSS JOIN grand_total
order by stockout_contribution_percent desc

-- Findings
-- Data suggest dairy and Fresh Produce contributes to more than 50 % of the stock-outs 

-- =====================================================================================================================
--   Q4. Are perishable categories experiencing more stock-outs than non-perishable categories?
-- ======================================================================================================================
### SQL Evidence 

SELECT products.is_perishable, SUM( CASE WHEN is_stockout = 'TRUE' THEN 1 ELSE 0 END) as Total_stockout
FROM inventory_snapshots
JOIN products on inventory_snapshots.sku_id = products.sku_id
Group by products.is_perishable

-- Findings
-- Yes perishable catagories is experiencing more stock-out than non persishable catagories
