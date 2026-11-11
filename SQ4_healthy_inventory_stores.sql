-- ==========================================================================================
-- SQ4: Which stores consistently maintain healthy inventory?
-- ==========================================================================================

--                             SQ4 Which stores consistently maintain healthy inventory?
-- ===========================================================================================================================


-- ============================================================================================================================
--        Q1. Which dark stores have lowest total number of stock-outs?
-- ============================================================================================================================
### SQL Evidence 

SELECT dark_stores.dark_store_id,dark_stores.store_name, SUM( CASE WHEN is_stockout = 'TRUE' THEN 1 ELSE 0 END) as Total_stockout
FROM inventory_snapshots
JOIN dark_stores on dark_stores.dark_store_id = inventory_snapshots.dark_store_id
Group by dark_stores.dark_store_id , dark_stores.store_name
ORDER BY Total_stockout ASC

-- Findings 
-- DS012	"Alipore Dark Store" DS011	"Barasat Dark Store" These 2 dark store had lowest stock out less than 500 stockouts 

-- ============================================================================================================================
--         Q2. What are the avg Fil rate of these dark stores ?
-- ============================================================================================================================

SELECT dark_stores.dark_store_id ,dark_stores.store_name, ROUND(avg (supplier_fill_rate)*100,2) as average_fillrate
FROM replenishments
JOIN dark_stores on dark_stores.dark_store_id = replenishments.dark_store_id
WHERE replenishments.dark_store_id IN ('DS011','DS012')
Group by dark_stores.dark_store_id , dark_stores.store_name
ORDER BY average_fillrate DESC

-- Findings
-- The Average Fill rate of these store are more than 80 %

-- ==============================================================================================================================
--          Q3 . How often do these stores fall below the reorder point?
-- ==============================================================================================================================
### SQL Evidence 

WITH t as (SELECT dark_store_id, SUM(CASE WHEN available_qty < reorder_point THEN 1 ELSE 0 END) as Below_reorder_point, COUNT(*) as total
FROM  inventory_snapshots
group by dark_store_id)
SELECT t.dark_store_id, t.Below_reorder_point, t.total , ROUND((t.Below_reorder_point/t.total)*100,2) as "Below-RP %"
FROM t
WHERE t.dark_store_id IN ('DS011','DS012')

-- Findings
-- DS011 was below its reorder point during approximately 10.47 % of observed inventory snapshots.
-- DS012 was below its reorder point during approximately 10.04% of observed inventory snapshots.

-- ==============================================================================================================================
--       Q4. What is the average inventory utilization compared to storage capacity?
-- ==============================================================================================================================
### SQL Evidence 

WITH utilization AS (
    SELECT 
        dark_store_id,
        (estimated_storage_units_used_store / store_storage_capacity_units)*100 AS utilization_pct
    FROM inventory_snapshots
    WHERE dark_store_id IN ('DS011', 'DS012')
      AND store_storage_capacity_units > 0
)

SELECT 
    dark_store_id,
    ROUND(AVG(utilization_pct), 2) AS avg_inventory_utilization_pct
FROM utilization
GROUP BY dark_store_id
ORDER BY avg_inventory_utilization_pct DESC;
 
 -- Findings 
 -- The calculated average storage utilization exceeds 100% for both DS011 (185.92%) and DS012 (208.26%). 
 -- Since utilization above 100% implies inventory exceeding the recorded storage capacity,
 -- these results should be treated as a potential data-integrity or capacity-definition issue rather than confirmed over-utilization.
