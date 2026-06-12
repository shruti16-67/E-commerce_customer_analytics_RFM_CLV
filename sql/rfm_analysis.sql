-- E-COMMERCE CUSTOMER RFM ANALYSIS

-- Window Functions Used:
--   ROW_NUMBER, RANK, DENSE_RANK, NTILE
--   LAG, LEAD, SUM OVER, AVG OVER
--   FIRST_VALUE, LAST_VALUE
--   PERCENTILE_CONT, PERCENT_RANK, CUME_DIST

-- STEP 1: DATABASE SETUP

CREATE TABLE online_retail (
    InvoiceNo     VARCHAR(20),
    StockCode     VARCHAR(20),
    Description   VARCHAR(255),
    Quantity      INT,
    UnitPrice     DECIMAL(10,2),
    CustomerID    VARCHAR(20),
    Country       VARCHAR(100),
    Date          DATE,
    TotalRevenue  DECIMAL(10,2)
);


-- STEP 2: DATA EXPLORATION

-- Total records
SELECT COUNT(*) AS total_records
FROM online_retail;

-- Date range
SELECT
    MIN(Date) AS earliest_date,
    MAX(Date) AS latest_date
FROM online_retail;

-- Unique counts
SELECT
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT InvoiceNo)  AS unique_invoices,
    COUNT(DISTINCT StockCode)  AS unique_products,
    COUNT(DISTINCT Country)    AS unique_countries
FROM online_retail;

-- Revenue overview
SELECT
    ROUND(SUM(TotalRevenue), 2)  AS total_revenue,
    ROUND(AVG(TotalRevenue), 2)  AS avg_line_revenue,
    ROUND(MIN(TotalRevenue), 2)  AS min_revenue,
    ROUND(MAX(TotalRevenue), 2)  AS max_revenue
FROM online_retail;

-- Top 10 countries by revenue
SELECT TOP 10
    Country,
    COUNT(DISTINCT CustomerID)  AS customers,
    COUNT(DISTINCT InvoiceNo)   AS orders,
    ROUND(SUM(TotalRevenue), 2) AS total_revenue
FROM online_retail
GROUP BY Country
ORDER BY total_revenue DESC;


-- STEP 3: DATA QUALITY CHECKS

-- Null CustomerIDs
SELECT
    COUNT(*)                                    AS total_rows,
    COUNT(CustomerID)                           AS non_null_customers,
    COUNT(*) - COUNT(CustomerID)                AS null_customers,
    ROUND(
        (COUNT(*) - COUNT(CustomerID)) * 100.0
        / COUNT(*), 2
    )                                           AS null_pct
FROM online_retail;

-- Negative quantities
SELECT
    COUNT(*) AS negative_qty_rows,
    SUM(Quantity) AS total_negative_qty
FROM online_retail
WHERE Quantity < 0;

-- Zero/negative prices
SELECT COUNT(*) AS invalid_price_rows
FROM online_retail
WHERE UnitPrice <= 0;

-- Cancelled invoices
SELECT
    COUNT(*)                    AS cancelled_rows,
    COUNT(DISTINCT InvoiceNo)   AS cancelled_invoices,
    COUNT(DISTINCT CustomerID)  AS affected_customers
FROM online_retail
WHERE InvoiceNo LIKE 'C%';

-- All quality issues summary
SELECT
    COUNT(*)                                        AS total_rows,
    SUM(CASE WHEN CustomerID IS NULL  THEN 1
        ELSE 0 END)                                 AS null_customer_rows,
    SUM(CASE WHEN Quantity < 0        THEN 1
        ELSE 0 END)                                 AS negative_qty_rows,
    SUM(CASE WHEN UnitPrice <= 0      THEN 1
        ELSE 0 END)                                 AS invalid_price_rows,
    SUM(CASE WHEN InvoiceNo LIKE 'C%' THEN 1
        ELSE 0 END)                                 AS cancelled_rows,
    SUM(CASE WHEN InvoiceNo LIKE 'A%' THEN 1
        ELSE 0 END)                                 AS anomalous_rows
FROM online_retail;


-- STEP 4: DATA CLEANING

CREATE VIEW cleaned_retail AS
SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    UnitPrice,
    CustomerID,
    Country,
    Date,
    Quantity * UnitPrice AS SalesLineTotal
FROM online_retail
WHERE
    CustomerID IS NOT NULL
    AND Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND InvoiceNo NOT LIKE 'A%';

-- Verify cleaning
SELECT
    COUNT(*)                        AS cleaned_rows,
    COUNT(DISTINCT CustomerID)      AS unique_customers,
    COUNT(DISTINCT InvoiceNo)       AS unique_invoices,
    ROUND(SUM(SalesLineTotal), 2)   AS total_revenue
FROM cleaned_retail;

-- Data retention rate
SELECT
    (SELECT COUNT(*) FROM online_retail)  AS original_rows,
    (SELECT COUNT(*) FROM cleaned_retail) AS cleaned_rows,
    ROUND(
        (SELECT COUNT(*) FROM cleaned_retail) * 100.0
        / (SELECT COUNT(*) FROM online_retail),
    1)                                    AS retention_pct;


-- STEP 5: FEATURE ENGINEERING

-- Monthly revenue trend
SELECT
    FORMAT(Date, 'yyyy-MM')             AS year_month,
    COUNT(DISTINCT InvoiceNo)           AS orders,
    COUNT(DISTINCT CustomerID)          AS customers,
    SUM(Quantity)                       AS total_items,
    ROUND(SUM(SalesLineTotal), 2)       AS revenue,
    ROUND(AVG(SalesLineTotal), 2)       AS avg_line_value
FROM cleaned_retail
GROUP BY FORMAT(Date, 'yyyy-MM')
ORDER BY year_month;

-- Revenue by day of week
SELECT
    DATENAME(WEEKDAY, Date)             AS day_name,
    DATEPART(WEEKDAY, Date)             AS day_number,
    COUNT(DISTINCT InvoiceNo)           AS orders,
    ROUND(SUM(SalesLineTotal), 2)       AS revenue
FROM cleaned_retail
GROUP BY DATENAME(WEEKDAY, Date), DATEPART(WEEKDAY, Date)
ORDER BY day_number;

-- Top 10 products by revenue
SELECT TOP 10
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo)           AS times_ordered,
    SUM(Quantity)                       AS total_qty_sold,
    ROUND(SUM(SalesLineTotal), 2)       AS total_revenue
FROM cleaned_retail
GROUP BY StockCode, Description
ORDER BY total_revenue DESC;


-- STEP 6: RFM METRICS CALCULATION

DECLARE @ref_date DATE = (SELECT MAX(Date) FROM cleaned_retail);

CREATE VIEW customer_rfm_metrics AS
SELECT
    CustomerID,
    MAX(Country)                                AS Country,
    DATEDIFF(DAY, MAX(Date), @ref_date)         AS Recency,
    COUNT(DISTINCT InvoiceNo)                   AS Frequency,
    ROUND(SUM(SalesLineTotal), 2)               AS MonetaryValue,
    MIN(Date)                                   AS FirstPurchaseDate,
    MAX(Date)                                   AS LastPurchaseDate,
    COUNT(DISTINCT StockCode)                   AS UniqueProducts,
    ROUND(AVG(
        SalesLineTotal / NULLIF(Quantity, 0)
    ), 2)                                       AS AvgItemPrice
FROM cleaned_retail
GROUP BY CustomerID;


-- STEP 7: WINDOW FUNCTIONS — RANKING & PERCENTILES
-- Understanding customer distribution before scoring

-- 7A: Customer revenue ranking using ROW_NUMBER, RANK, DENSE_RANK
SELECT
    CustomerID,
    Country,
    MonetaryValue,

    -- ROW_NUMBER: Unique rank even for ties
    ROW_NUMBER() OVER (
        ORDER BY MonetaryValue DESC
    )                                           AS revenue_row_num,

    -- RANK: Same rank for ties, skips next ranks
    RANK() OVER (
        ORDER BY MonetaryValue DESC
    )                                           AS revenue_rank,

    -- DENSE_RANK: Same rank for ties, no gaps
    DENSE_RANK() OVER (
        ORDER BY MonetaryValue DESC
    )                                           AS revenue_dense_rank,

    -- Rank within each country
    RANK() OVER (
        PARTITION BY Country
        ORDER BY MonetaryValue DESC
    )                                           AS revenue_rank_by_country

FROM customer_rfm_metrics;

-- 7B: Dividing customers into quartiles using NTILE
-- This is how we determine RFM score boundaries
SELECT
    CustomerID,
    MonetaryValue,
    Frequency,
    Recency,

    -- Split into 5 equal groups for scoring
    NTILE(5) OVER (ORDER BY MonetaryValue ASC)  AS monetary_quintile,
    NTILE(5) OVER (ORDER BY Frequency ASC)      AS frequency_quintile,

    -- Lower recency = more recent = better
    -- So we order DESC for recency scoring
    NTILE(5) OVER (ORDER BY Recency DESC)       AS recency_quintile,

    -- Split into 4 quartiles for analysis
    NTILE(4) OVER (ORDER BY MonetaryValue ASC)  AS monetary_quartile

FROM customer_rfm_metrics;


-- 7C: Running totals and cumulative revenue using SUM OVER
SELECT
    CustomerID,
    Country,
    MonetaryValue,

    -- Running total of revenue (ordered by spend)
    SUM(MonetaryValue) OVER (
        ORDER BY MonetaryValue DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )                                           AS cumulative_revenue,

    -- Total revenue (same for all rows)
    SUM(MonetaryValue) OVER ()                  AS total_revenue,

    -- Revenue share % per customer
    ROUND(
        MonetaryValue * 100.0
        / SUM(MonetaryValue) OVER (),
    2)                                          AS revenue_share_pct,

    -- Cumulative revenue % (80/20 rule check)
    ROUND(
        SUM(MonetaryValue) OVER (
            ORDER BY MonetaryValue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 / SUM(MonetaryValue) OVER (),
    2)                                          AS cumulative_revenue_pct

FROM customer_rfm_metrics
ORDER BY MonetaryValue DESC;


-- 7D: Average comparison using AVG OVER
SELECT
    CustomerID,
    Country,
    MonetaryValue,
    Frequency,
    Recency,

    -- Overall averages for comparison
    ROUND(AVG(MonetaryValue) OVER (), 2)        AS overall_avg_revenue,
    ROUND(AVG(Frequency) OVER (), 1)            AS overall_avg_frequency,
    ROUND(AVG(Recency) OVER (), 0)              AS overall_avg_recency,

    -- Country-level averages
    ROUND(AVG(MonetaryValue) OVER (
        PARTITION BY Country
    ), 2)                                       AS country_avg_revenue,

    -- Difference from overall average
    ROUND(MonetaryValue - AVG(MonetaryValue)
        OVER (), 2)                             AS diff_from_avg,

    -- Above or below average flag
    CASE
        WHEN MonetaryValue > AVG(MonetaryValue) OVER ()
            THEN 'Above Average'
        ELSE
            'Below Average'
    END                                         AS vs_avg_revenue

FROM customer_rfm_metrics;


-- 7E: Month over month revenue change using LAG and LEAD
WITH monthly_revenue AS (
    SELECT
        FORMAT(Date, 'yyyy-MM')             AS year_month,
        ROUND(SUM(SalesLineTotal), 2)       AS monthly_revenue,
        COUNT(DISTINCT CustomerID)          AS monthly_customers,
        COUNT(DISTINCT InvoiceNo)           AS monthly_orders
    FROM cleaned_retail
    GROUP BY FORMAT(Date, 'yyyy-MM')
)
SELECT
    year_month,
    monthly_revenue,
    monthly_customers,
    monthly_orders,

    -- Previous month revenue using LAG
    LAG(monthly_revenue, 1) OVER (
        ORDER BY year_month
    )                                       AS prev_month_revenue,

    -- Next month revenue using LEAD
    LEAD(monthly_revenue, 1) OVER (
        ORDER BY year_month
    )                                       AS next_month_revenue,

    -- Month over month change
    ROUND(
        monthly_revenue - LAG(monthly_revenue, 1)
            OVER (ORDER BY year_month),
    2)                                      AS mom_revenue_change,

    -- Month over month % change
    ROUND(
        (monthly_revenue - LAG(monthly_revenue, 1)
            OVER (ORDER BY year_month))
        * 100.0
        / NULLIF(LAG(monthly_revenue, 1)
            OVER (ORDER BY year_month), 0),
    1)                                      AS mom_revenue_pct,

    -- Previous month customers
    LAG(monthly_customers, 1) OVER (
        ORDER BY year_month
    )                                       AS prev_month_customers,

    -- Customer growth %
    ROUND(
        (monthly_customers - LAG(monthly_customers, 1)
            OVER (ORDER BY year_month))
        * 100.0
        / NULLIF(LAG(monthly_customers, 1)
            OVER (ORDER BY year_month), 0),
    1)                                      AS customer_growth_pct

FROM monthly_revenue
ORDER BY year_month;


-- 7F: First and last purchase value per customer using FIRST_VALUE, LAST_VALUE
SELECT DISTINCT
    CustomerID,
    Country,

    -- First invoice date and value
    FIRST_VALUE(Date) OVER (
        PARTITION BY CustomerID
        ORDER BY Date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                       AS first_purchase_date,

    FIRST_VALUE(SalesLineTotal) OVER (
        PARTITION BY CustomerID
        ORDER BY Date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                       AS first_purchase_value,

    -- Most recent invoice date and value
    LAST_VALUE(Date) OVER (
        PARTITION BY CustomerID
        ORDER BY Date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                       AS last_purchase_date,

    LAST_VALUE(SalesLineTotal) OVER (
        PARTITION BY CustomerID
        ORDER BY Date ASC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    )                                       AS last_purchase_value

FROM cleaned_retail;


-- 7G: Percentile distribution using PERCENT_RANK and CUME_DIST
SELECT
    CustomerID,
    MonetaryValue,
    Frequency,
    Recency,

    -- PERCENT_RANK: 0 to 1 relative rank
    ROUND(PERCENT_RANK() OVER (
        ORDER BY MonetaryValue
    ), 4)                                   AS monetary_percent_rank,

    -- CUME_DIST: Cumulative distribution
    ROUND(CUME_DIST() OVER (
        ORDER BY MonetaryValue
    ), 4)                                   AS monetary_cume_dist,

    -- PERCENTILE_CONT: Exact percentile values
    PERCENTILE_CONT(0.25) WITHIN GROUP (
        ORDER BY MonetaryValue
    ) OVER ()                               AS monetary_q1,

    PERCENTILE_CONT(0.50) WITHIN GROUP (
        ORDER BY MonetaryValue
    ) OVER ()                               AS monetary_median,

    PERCENTILE_CONT(0.75) WITHIN GROUP (
        ORDER BY MonetaryValue
    ) OVER ()                               AS monetary_q3

FROM customer_rfm_metrics;


-- 7H: Identify 80/20 customers (top 20% driving 80% revenue)
WITH revenue_ranked AS (
    SELECT
        CustomerID,
        MonetaryValue,
        ROUND(CUME_DIST() OVER (
            ORDER BY MonetaryValue ASC
        ) * 100, 1)                         AS percentile_rank,
        ROUND(
            SUM(MonetaryValue) OVER (
                ORDER BY MonetaryValue DESC
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) * 100.0
            / SUM(MonetaryValue) OVER (),
        1)                                  AS cumulative_revenue_pct
    FROM customer_rfm_metrics
)
SELECT
    CustomerID,
    MonetaryValue,
    percentile_rank,
    cumulative_revenue_pct,
    CASE
        WHEN percentile_rank >= 80
            THEN 'Top 20% Customers'
        ELSE
            'Bottom 80% Customers'
    END                                     AS customer_tier
FROM revenue_ranked
ORDER BY MonetaryValue DESC;

-- STEP 8: RFM SCORING

CREATE VIEW customer_rfm_scores AS
SELECT
    CustomerID,
    Country,
    Recency,
    Frequency,
    MonetaryValue,
    FirstPurchaseDate,
    LastPurchaseDate,

    -- RECENCY SCORE
    CASE
        WHEN Recency <= 30  THEN 5
        WHEN Recency <= 60  THEN 4
        WHEN Recency <= 90  THEN 3
        WHEN Recency <= 180 THEN 2
        ELSE 1
    END AS R_Score,

    -- FREQUENCY SCORE
    CASE
        WHEN Frequency >= 10 THEN 5
        WHEN Frequency >= 7  THEN 4
        WHEN Frequency >= 5  THEN 3
        WHEN Frequency >= 3  THEN 2
        ELSE 1
    END AS F_Score,

    -- MONETARY SCORE
    CASE
        WHEN MonetaryValue >= 5000 THEN 5
        WHEN MonetaryValue >= 2000 THEN 4
        WHEN MonetaryValue >= 1000 THEN 3
        WHEN MonetaryValue >= 500  THEN 2
        ELSE 1
    END AS M_Score

FROM customer_rfm_metrics;

-- Score distribution
SELECT
    R_Score,
    F_Score,
    M_Score,
    COUNT(*) AS customer_count
FROM customer_rfm_scores
GROUP BY R_Score, F_Score, M_Score
ORDER BY R_Score DESC, F_Score DESC, M_Score DESC;


-- STEP 9: CUSTOMER SEGMENTATION

CREATE VIEW customer_segments AS
SELECT
    CustomerID,
    Country,
    Recency,
    Frequency,
    MonetaryValue,
    R_Score,
    F_Score,
    M_Score,
    CONCAT(
        CAST(R_Score AS VARCHAR),
        CAST(F_Score AS VARCHAR),
        CAST(M_Score AS VARCHAR)
    )                               AS RFM_Score,

    CASE
        WHEN R_Score = 5
            AND F_Score >= 4        THEN 'REWARD'
        WHEN R_Score >= 4
            AND F_Score >= 3        THEN 'RETAIN'
        WHEN R_Score >= 3
            AND F_Score <= 2        THEN 'NURTURE'
        WHEN R_Score <= 2
            AND F_Score >= 3        THEN 'RE-ENGAGE'
        WHEN M_Score >= 4
            AND F_Score <= 2        THEN 'PAMPER'
        WHEN F_Score >= 4
            AND M_Score <= 2        THEN 'UPSELL'
        WHEN R_Score = 1
            AND F_Score = 1         THEN 'LOST'
        ELSE                             'OTHERS'
    END AS Segment,

    CASE
        WHEN R_Score = 5 AND F_Score >= 4
            THEN 'Reward with VIP programs and exclusive offers'
        WHEN R_Score >= 4 AND F_Score >= 3
            THEN 'Retain with loyalty programs and personalized offers'
        WHEN R_Score >= 3 AND F_Score <= 2
            THEN 'Nurture with relationship building and incentives'
        WHEN R_Score <= 2 AND F_Score >= 3
            THEN 'Re-engage with targeted campaigns and discounts'
        WHEN M_Score >= 4 AND F_Score <= 2
            THEN 'Pamper with premium personalized service'
        WHEN F_Score >= 4 AND M_Score <= 2
            THEN 'Upsell with bundle deals and loyalty rewards'
        WHEN R_Score = 1 AND F_Score = 1
            THEN 'Last resort win-back campaign'
        ELSE
            'Standard marketing approach'
    END AS RecommendedAction,

    CASE
        WHEN Recency <= 30  THEN 'Low Risk'
        WHEN Recency <= 90  THEN 'Medium Risk'
        WHEN Recency <= 180 THEN 'High Risk'
        ELSE                     'Very High Risk'
    END AS ChurnRisk,

    CASE
        WHEN MonetaryValue >= 5000 THEN 'High Value'
        WHEN MonetaryValue >= 2000 THEN 'Medium Value'
        WHEN MonetaryValue >= 500  THEN 'Low Value'
        ELSE                            'Very Low Value'
    END AS CLV_Tier

FROM customer_rfm_scores;

-- STEP 10: SEGMENT ANALYSIS WITH WINDOW FUNCTIONS

-- 10A: Segment summary with revenue contribution
SELECT
    Segment,
    COUNT(CustomerID)                               AS customer_count,
    ROUND(
        COUNT(CustomerID) * 100.0
        / SUM(COUNT(CustomerID)) OVER (),
    1)                                              AS pct_of_customers,
    ROUND(AVG(MonetaryValue), 2)                    AS avg_revenue,
    ROUND(SUM(MonetaryValue), 2)                    AS total_revenue,
    ROUND(
        SUM(MonetaryValue) * 100.0
        / SUM(SUM(MonetaryValue)) OVER (),
    1)                                              AS pct_of_revenue,
    ROUND(AVG(CAST(Recency AS FLOAT)), 0)           AS avg_recency,
    ROUND(AVG(CAST(Frequency AS FLOAT)), 1)         AS avg_frequency,
    RecommendedAction
FROM customer_segments
GROUP BY Segment, RecommendedAction
ORDER BY total_revenue DESC;


-- 10B: Rank customers within each segment
SELECT
    CustomerID,
    Country,
    Segment,
    MonetaryValue,
    Frequency,
    Recency,

    -- Rank within segment by revenue
    RANK() OVER (
        PARTITION BY Segment
        ORDER BY MonetaryValue DESC
    )                                               AS rank_in_segment,

    -- Segment average revenue
    ROUND(AVG(MonetaryValue) OVER (
        PARTITION BY Segment
    ), 2)                                           AS segment_avg_revenue,

    -- Difference from segment average
    ROUND(
        MonetaryValue - AVG(MonetaryValue) OVER (
            PARTITION BY Segment
        ),
    2)                                              AS diff_from_segment_avg,

    -- Revenue share within segment
    ROUND(
        MonetaryValue * 100.0
        / SUM(MonetaryValue) OVER (PARTITION BY Segment),
    2)                                              AS pct_of_segment_revenue

FROM customer_segments
ORDER BY Segment, rank_in_segment;


-- 10C: High value churning customers — most urgent action
SELECT
    CustomerID,
    Country,
    Segment,
    Recency,
    Frequency,
    MonetaryValue,
    ChurnRisk,

    -- Revenue rank overall
    RANK() OVER (
        ORDER BY MonetaryValue DESC
    )                                               AS overall_revenue_rank,

    -- Recency rank (higher recency = churned longer)
    RANK() OVER (
        ORDER BY Recency DESC
    )                                               AS churn_risk_rank

FROM customer_segments
WHERE ChurnRisk IN ('High Risk', 'Very High Risk')
    AND CLV_Tier IN ('High Value', 'Medium Value')
ORDER BY MonetaryValue DESC;


-- STEP 11: EXPORT FOR PYTHON CLV MODELING
-- This output feeds into Python BG/NBD + Gamma-Gamma model

SELECT
    cs.CustomerID,
    cs.Country,
    cs.Recency,
    cs.Frequency,
    cs.MonetaryValue,
    cs.R_Score,
    cs.F_Score,
    cs.M_Score,
    cs.RFM_Score,
    cs.Segment,
    cs.ChurnRisk,
    cs.CLV_Tier,
    cs.RecommendedAction,
    m.FirstPurchaseDate,
    m.LastPurchaseDate,
    m.UniqueProducts,

    -- overall revenue percentile
    ROUND(PERCENT_RANK() OVER (
        ORDER BY cs.MonetaryValue
    ) * 100, 1)                                     AS revenue_percentile

FROM customer_segments cs
JOIN customer_rfm_metrics m
    ON cs.CustomerID = m.CustomerID
ORDER BY cs.MonetaryValue DESC;