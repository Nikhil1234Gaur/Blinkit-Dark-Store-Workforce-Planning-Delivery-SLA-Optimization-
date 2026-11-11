# Dataset Architecture & Schema Documentation

This document provides a comprehensive overview of the relational data model, schemas, and analytical data dictionary powering the **Blinkit Dark Store Stockout & Operations Intelligence** analysis.

---

## 1. Overview & Analysis Context

- **Network Scope:** Kolkata Dark Store Network (12 active dark stores including New Town, Jadavpur, Rajarhat, Dum Dum, Gariahat, Behala, Salt Lake, Ballygunge, Park Street, Howrah, Barasat, and Alipore).
- **Analysis Period:** March 1, 2026 – June 28, 2026 (120 continuous calendar days).
- **Storage & Relational Engine:** MySQL / Relational Data Warehouse.
- **Analytical Purpose:** Identify dark store inventory bottlenecks, root causes of SKU-level stock-outs, peak operational stress windows, and supplier replenishment reliability.

---

## 2. Relational Data Model

The data model follows an enterprise operations schema with two primary grains of observation:
1. **Periodic Snapshot Grain (`inventory_snapshots`):** Captures point-in-time inventory health, available quantities, and threshold breaches.
2. **Transactional Event Grain (`stockout_events`, `replenishments`, `order_items`):** Captures timestamped events, replenishment cycles, and customer ordering pressure.

```text
       +-----------------------+              +-----------------------+
       |      dark_stores      |              |       products        |
       +-----------------------+              +-----------------------+
       | dark_store_id (PK)    |              | sku_id (PK)           |
       | store_name            |              | product_name          |
       | locality              |              | category              |
       | city                  |              | is_perishable         |
       +-----------+-----------+              +-----------+-----------+
                   |                                      |
         +---------+---------+                  +---------+---------+
         |                   |                  |                   |
         v                   v                  v                   v
+-----------------------+  +-----------------------+  +-----------------------+
|  inventory_snapshots  |  |    stockout_events    |  |    replenishments     |
+-----------------------+  +-----------------------+  +-----------------------+
| snapshot_id (PK)      |  | event_id (PK)         |  | replenishment_id (PK) |
| dark_store_id (FK)    |  | dark_store_id (FK)    |  | dark_store_id (FK)    |
| sku_id (FK)           |  | sku_id (FK)           |  | sku_id (FK)           |
| snapshot_date         |  | stockout_started_at   |  | requested_at          |
| available_qty         |  | stockout_observed_end |  | supplier_fill_rate    |
| reorder_point         |  | duration_hours        |  +-----------------------+
| is_stockout           |  +-----------------------+
| estimated_storage_used|
| store_storage_capacity|
+-----------------------+
```

---

## 3. Data Dictionary & Entity Descriptions

### A. `dark_stores` (Dimension)
Master table representing micro-fulfillment dark stores across Kolkata.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `dark_store_id` | `VARCHAR(10)` | Unique identifier for each dark store (e.g., `DS002`, `DS011`, `DS012`) [PK]. |
| `store_name` | `VARCHAR(100)` | Full descriptive name (e.g., "New Town Dark Store", "Alipore Dark Store"). |
| `locality` | `VARCHAR(100)` | Neighborhood/catchment area in Kolkata. |
| `city` | `VARCHAR(50)` | Base metropolitan city (`Kolkata`). |

---

### B. `products` (Dimension)
Catalog dimension classifying all stock keeping units (SKUs).

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `sku_id` | `VARCHAR(20)` | Unique SKU identifier (e.g., `SKU0002`, `SKU0049`, `SKU0050`) [PK]. |
| `product_name` | `VARCHAR(150)` | Brand and item name (e.g., "Mother Dairy Toned Milk 500ml", "Green Chilli 100g"). |
| `category` | `VARCHAR(50)` | Department category (`Dairy`, `Fresh Produce`, `Beverages`, `Instant Foods`, etc.). |
| `is_perishable` | `VARCHAR(10)` | Boolean flag indicating short shelf-life items (`TRUE` / `FALSE`). |

---

### C. `inventory_snapshots` (Fact - Periodic)
Periodic snapshots recording shelf availability and storage utilization.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `dark_store_id` | `VARCHAR(10)` | Foreign key referencing `dark_stores.dark_store_id`. |
| `sku_id` | `VARCHAR(20)` | Foreign key referencing `products.sku_id`. |
| `snapshot_date` | `DATE` | Date of snapshot record (2026-03-01 to 2026-06-28). |
| `available_qty` | `INT` | Physical units available on shelf at snapshot time. |
| `reorder_point` | `INT` | Minimum inventory threshold triggering automated replenishment. |
| `is_stockout` | `VARCHAR(10)` | String boolean (`'TRUE'` / `'FALSE'`) denoting zero shelf inventory. |
| `estimated_storage_units_used_store` | `DECIMAL` | Total calculated storage volume occupied at the store. |
| `store_storage_capacity_units` | `DECIMAL` | Baseline nominal storage limit configured for the dark store. |

---

### D. `stockout_events` (Fact - Transactional)
Discrete stock-out incidents tracking exact start, resolution, and cumulative outage hours.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `dark_store_id` | `VARCHAR(10)` | Foreign key referencing `dark_stores.dark_store_id`. |
| `sku_id` | `VARCHAR(20)` | Foreign key referencing `products.sku_id`. |
| `stockout_started_at` | `DATETIME` | Timestamp when physical stock hit zero. |
| `stockout_observed_end_at`| `DATETIME` | Timestamp when stock became available (replenishment inbound). |
| `duration_hours_observed` | `DECIMAL` | Total elapsed duration of outage (accounting for midnight boundary crossovers). |

---

### E. `replenishments` (Fact - Transactional)
Procurement and inward fulfillment log tracking warehouse-to-store deliveries.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `dark_store_id` | `VARCHAR(10)` | Dark store requesting inward inventory. |
| `sku_id` | `VARCHAR(20)` | Item requested for replenishment. |
| `requested_at` | `DATETIME` | Timestamp when the reorder order was placed with supplier/hub. |
| `supplier_fill_rate` | `DECIMAL(5,2)` | Ratio of units delivered versus units requested (0.00 to 1.00). |

---

### F. `order_items` (Fact - Transactional)
Customer sales transactions utilized to evaluate demand pressure on stocking levels.

| Column Name | Data Type | Description |
| :--- | :--- | :--- |
| `order_id` | `VARCHAR(50)` | Customer order identifier. |
| `sku_id` | `VARCHAR(20)` | Item ordered. |
| `quantity` | `INT` | Item unit count purchased. |

---

## 4. Analytical Notes & Grain Discipline

- **Observation Count vs. Distinct Events:**
  - `COUNT(inventory_snapshots.is_stockout = 'TRUE')` measures the frequency of **observed snapshot states** where an item was unavailable.
  - `COUNT(stockout_events.stockout_started_at)` measures discrete **stock-out incidents**.
  - SQL queries and dashboard visuals distinguish these two grains to ensure consistency across KPI reporting.

- **Midnight Date Boundary Handling:**
  For stockout events that begin in late evening and conclude after midnight (next calendar day), SQL queries explicitly apply conditional correction:
  ```sql
  CASE 
      WHEN stockout_observed_end_at < stockout_started_at 
      THEN DATE_ADD(stockout_observed_end_at, INTERVAL 1 DAY) 
      ELSE stockout_observed_end_at 
  END
  ```
