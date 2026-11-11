# Blinkit Dark Store Stock-Out & Operations Intelligence Analysis

[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](https://www.mysql.com/)
[![PowerBI](https://img.shields.io/badge/Power_BI-Desktop-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Status](https://img.shields.io/badge/Project_Status-Completed-0C831F?style=for-the-badge)](https://github.com/Animus004)

> **An end-to-end SQL and Power BI operations intelligence project analyzing dark store availability, chronic SKU stock-outs, peak operational failure windows, and replenishment reliability across the Blinkit Kolkata dark store network.**

---

## 1. Executive Summary

In quick-commerce, **10-minute delivery promises** rely entirely on near-100% shelf availability within hyper-local micro-fulfillment centers (dark stores). Stock-outs directly translate to lost revenue, cart abandonment, and customer churn to competitors.

This project investigates inventory health across **12 dark stores in Kolkata** over **120 days (March 1, 2026 – June 28, 2026)**. By synthesizing periodic inventory snapshots and transactional stock-out events, this study answers key operational questions for Dark Store Operations Managers to isolate chronic bottlenecks, optimize replenishment timing, and establish benchmark performance.

### Key Insights at a Glance:
- **Disproportionate Store Burden:** **New Town Dark Store (DS002)** alone contributes **26.58%** of all network stock-outs and accumulated **12,617 cumulative stock-out hours**, followed by Jadavpur (16.73%) and Rajarhat (11.88%).
- **Peak Operational Vulnerability:** Stock-outs are heavily concentrated in the late evening, surging between **7:00 PM and 10:00 PM** (peaking at 10:00 PM with 780 incidents).
- **Perishable Dominance:** **Dairy** (6,790 observations, ~8.72h avg duration) and **Fresh Produce** (6,570 observations, ~9.04h avg duration) account for **over 50%** of all stock-outs.
- **Chronic High-Velocity SKUs:** Top stock-out duration items include *Mother Dairy Toned Milk 500ml* (2,023 hrs) and *Apple Royal Gala 4 pcs* (1,905 hrs). High-frequency items like *Green Chilli 100g* remained out of stock on 94 out of 120 days despite restock requests every 5 hours.
- **Benchmark Stores:** **Alipore (DS012)** and **Barasat (DS011)** maintained exceptional inventory health with fewer than 500 total stock-out observations and supplier fill rates exceeding **80%**.

---

## 2. Interactive Dashboard Preview

The analysis is accompanied by an interactive two-page Power BI executive dashboard:

### Page 1: Dark Store & SKU Intelligence
*Features network-wide store stock-out counts, GIS location mapping, hourly event distribution, cumulative store outage durations, chronic SKU durations, and replenishment request intervals.*

![Dashboard Page 1](Screenshots/dashboard_page_1.png)

### Page 2: SKU & Category Intelligence
*Features category-level stock-out duration rankings, category observation volumes, category contribution share, and store-wise replenishment lead duration.*

![Dashboard Page 2](Screenshots/dashboard_page_2.png)

---

## 3. Core Business Problem & Objectives

Dark Store Operations Managers face critical supply-demand imbalances during daily operations:
1. **Where are stock-outs most concentrated?** Is availability failure uniform across Kolkata or driven by specific micro-fulfillment hubs?
2. **When do stock-outs occur?** Do stock-outs happen randomly throughout the day, or do they follow predictable customer ordering surges?
3. **Which SKUs and categories are failing?** Are stock-outs caused by long-tail non-essential items or daily fast-moving essentials?
4. **What can underperforming stores learn from healthy stores?** How do best-in-class stores sustain high availability?

---

## 4. Analytical Approach & Stakeholder Framework

The project executes four foundational Stakeholder Questions (**SQ1 – SQ4**) designed for Operations Leadership:

```text
├── SQ1: Dark Store Stock-Out Concentration & Temporal Patterns
├── SQ2: Chronic SKU Frequency & Replenishment Friction
├── SQ3: Category Contribution & Perishability Vulnerability
└── SQ4: Healthy Store Benchmarking & Capacity Utilization Audit
```

### SQ1: Which dark stores experience the highest number of stock-outs?
* **SQL Script:** [`SQL/SQ1_highest_store_stockouts.sql`](SQL/SQ1_highest_store_stockouts.sql)
* **Core Logic:** Aggregates snapshot-level boolean flags (`is_stockout = 'TRUE'`), calculates store contribution percentages via CTEs, extracts hour-of-day timestamps from event logs, and computes duration using boundary-adjusted timestamps.
* **Findings:**
  - **New Town (DS002)** is the highest-burden dark store, generating **26.58%** of all stock-outs and **12,617 cumulative stock-out hours**.
  - **Jadavpur (DS005)** ranks second, contributing **16.73%** of stock-outs (7,306 outage hours).
  - Stock-outs occurred across **100% of the 120 analysis days** (peaking on March 14, 2026 with 101 events).
  - Outages spike sharply between **19:00 and 22:00**, indicating evening inventory depletion before replenishment arrives.

### SQ2: Which SKUs experience stock-outs most frequently?
* **SQL Script:** [`SQL/SQ2_frequently_stocked_out_skus.sql`](SQL/SQ2_frequently_stocked_out_skus.sql)
* **Core Logic:** Evaluates total outage hours per SKU, identifies recurring out-of-stock days (`HAVING COUNT(DISTINCT DATE) > 1`), computes time differences between replenishment orders using the `LAG()` window function, and joins with order transactions.
* **Findings:**
  - **Mother Dairy Toned Milk 500ml** logged the highest cumulative outage duration (**2,023 hours**).
  - **Green Chilli 100g** experienced the most chronic multi-day outages, appearing out of stock on **94 distinct days** out of 120.
  - **26 high-pressure SKUs** generate replenishment reorders faster than every **8 hours** (e.g., Apple Royal Gala and Mozzarella Cheese reordered every 5 hours; Amul Milk every 6 hours).
  - High demand strongly correlates with stock-outs on daily essentials, proving inventory depletion is driven by sales velocity exceeding shelf capacity.

### SQ3: Which product categories contribute the most to stock-outs?
* **SQL Script:** [`SQL/SQ3_category_stockouts.sql`](SQL/SQ3_category_stockouts.sql)
* **Core Logic:** Groups inventory snapshots and stock-out durations across merchandise categories, calculates category contribution shares against total network stock-outs, and segments by perishability.
* **Findings:**
  - **Dairy** leads in stock-out volume (**6,790 observations**, avg duration **8.72 hours**).
  - **Fresh Produce** leads in outage duration (avg duration **9.04 hours**, **6,570 observations**).
  - Together, **Dairy and Fresh Produce generate >50%** of all network stock-out volume.
  - Perishable categories experience significantly higher stock-outs than ambient packaged categories due to limited batch sizes and strict shelf-life constraints.

### SQ4: Which stores consistently maintain healthy inventory?
* **SQL Script:** [`SQL/SQ4_healthy_inventory_stores.sql`](SQL/SQ4_healthy_inventory_stores.sql)
* **Core Logic:** Identifies dark stores with the fewest total stock-out observations, assesses average supplier fill rates, measures the percentage of snapshots falling below reorder points, and calculates storage capacity utilization.
* **Findings:**
  - **Alipore (DS012)** and **Barasat (DS011)** maintain the lowest stock-out counts across Kolkata (< 500 stock-out observations).
  - Both stores achieve strong supplier fill rates exceeding **80%**.
  - Reorder point breach frequency at Alipore (10.04%) and Barasat (10.47%) is significantly lower than network averages.
  - **Capacity Anomaly:** Recorded storage utilization for DS011 (185.92%) and DS012 (208.26%) exceeds 100%, uncovering a critical data definition or unit-mismatch issue rather than physical over-stuffing.

---

## 5. Operations Manager Actionable Recommendations

| Horizon | Operational Action | Target Area | Business Impact |
| :--- | :--- | :--- | :--- |
| **Immediate (0–30 Days)** | **Pre-Evening Buffer Stocking:** Shift secondary replenishment delivery from 20:00 to 16:30–17:30. | New Town, Jadavpur, Rajarhat | Eliminates the 19:00–22:00 stock-out spike during peak ordering hours. |
| **Immediate (0–30 Days)** | **Perishable Reorder Point Uplift:** Increase safety stock thresholds by 20–25% on top 5 Dairy and Fresh Produce SKUs. | Network-wide (Mother Dairy, Amul, Green Chilli) | Reduces chronic daily stock-out recurrence. |
| **Medium Term (30–90 Days)** | **Supplier SLA & Fill-Rate Contracts:** Enforce minimum 85% supplier fill rate with penalties for evening delays. | Kolkata Supply Hubs | Stabilizes replenishment lead time and prevents repeated back-to-back reorders. |
| **Medium Term (30–90 Days)** | **Alipore/Barasat SOP Playbook:** Standardize bin allocation and reorder execution from benchmark stores to New Town. | Operations Teams | Disseminates best practices across high-burden stores. |
| **Strategic (90+ Days)** | **Storage Capacity Unit Audit:** Re-calibrate unit measurement formulas for dark store capacity before committing CapEx. | Supply Chain Engineering | Resolves 208% utilization data anomaly and guides accurate facility sizing. |

---

## 6. Critical Data Integrity Notice: Capacity Utilization

> **Analytical Finding:**
> Average recorded storage utilization is calculated as:
> $$\text{Utilization \%} = \frac{\text{estimated\_storage\_units\_used\_store}}{\text{store\_storage\_capacity\_units}} \times 100$$
> For stores such as DS011 (185.92%) and DS012 (208.26%), the calculated utilization exceeds 100%. 
>
> **Interpretation:**
> In physical warehousing, true volumetric utilization cannot sustainably exceed 100%. This metric reflects a **unit mismatch** (e.g., individual item pieces counted against carton/crate capacity limits) or outdated capacity benchmarks in the ERP. Operations management must validate this measurement prior to making real estate expansion decisions.

---

## 7. Repository Structure

```text
Blinkit_Dark_Store_Stockout_Analysis/
│
├── README.md                                             <-- Project overview & executive summary
│
├── SQL/                                                  <-- Modularized SQL analysis scripts
│   ├── SQ1_highest_store_stockouts.sql                   <-- Store stock-outs & hourly patterns
│   ├── SQ2_frequently_stocked_out_skus.sql               <-- Chronic SKUs & replenishment cadence
│   ├── SQ3_category_stockouts.sql                        <-- Category & perishability breakdown
│   └── SQ4_healthy_inventory_stores.sql                  <-- Store benchmarking & utilization audit
│
├── PowerBI/                                              <-- Power BI desktop report
│   └── DARK_STORE_OPERATIONS_INTELLIGENCE_Dashboard.pbix <-- Full interactive two-page dashboard
│
├── Report/                                               <-- Formal executive stakeholder deliverable
│   └── Blinkit_Dark_Store_Operations_Report.pdf          <-- Operations manager summary PDF
│
├── Screenshots/                                          <-- High-resolution dashboard visuals
│   ├── dashboard_page_1.png                              <-- Dark Store & SKU Intelligence view
│   └── dashboard_page_2.png                              <-- SKU & Category Intelligence view
│
└── Data/                                                 <-- Data architecture documentation
    └── README.md                                         <-- Schema, tables, & data dictionary
```

---

## 8. Tools & Technologies Used

- **SQL (MySQL 8.0):** Complex data aggregation, Common Table Expressions (`WITH`), Window Functions (`LAG()`, `PARTITION BY`), Date-time interval arithmetic (`TIMESTAMPDIFF`, `DATE_ADD`), Conditional logic (`CASE WHEN`).
- **Microsoft Power BI:** Data modeling, star schema design, DAX measures (Below Reorder %, Utilization %, Stockout Contribution %), interactive multi-page dashboards.
- **Data Modeling & Architecture:** Normalization, star schema design, dual-grain modeling (periodic snapshots vs. transactional events).
- **Executive Reporting:** Markdown documentation, GitHub documentation best practices, Operations Management briefing.

---

## 9. How to Reproduce & Explore

### A. Run SQL Queries
1. Clone this repository:
   ```bash
   git clone https://github.com/Animus004/blinkit-dark-store-stockout-analysis.git
   cd Blinkit_Dark_Store_Stockout_Analysis
   ```
2. Connect to your MySQL client (e.g., MySQL Workbench, DBeaver, or CLI).
3. Execute scripts in sequence from the `SQL/` directory:
   - `SQL/SQ1_highest_store_stockouts.sql`
   - `SQL/SQ2_frequently_stocked_out_skus.sql`
   - `SQL/SQ3_category_stockouts.sql`
   - `SQL/SQ4_healthy_inventory_stores.sql`

### B. Explore the Power BI Dashboard
1. Ensure [Microsoft Power BI Desktop](https://powerbi.microsoft.com/desktop/) is installed.
2. Open [`PowerBI/DARK_STORE_OPERATIONS_INTELLIGENCE_Dashboard.pbix`](PowerBI/DARK_STORE_OPERATIONS_INTELLIGENCE_Dashboard.pbix).
3. Interact with slicers (Month, Dark Store, Category) to examine localized inventory patterns.

---

## 10. Author & Contact

**Nikhil Kumar**    
- **GitHub:** [@Nikhil1234Gaur](https://github.com/Nikhil1234Gaur)  
- **Email:** [nikhil.kumar729999@gmail.com](mailto:nikhil.kumar729999@gmail.com)
