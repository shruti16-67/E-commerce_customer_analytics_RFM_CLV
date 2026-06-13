# E-Commerce Customer Segmentation & Lifetime Value Modeling — End-to-End Analytics
**RFM (Recency, Frequency, Monetary) Segmentation · KMeans Clustering · Probabilistic CLV · Predictive Modeling · Power BI**
[![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://www.python.org/)
[![Pandas](https://img.shields.io/badge/Pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)](https://pandas.pydata.org/)
[![NumPy](https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white)](https://numpy.org/)
[![Matplotlib](https://img.shields.io/badge/Matplotlib-11557C?style=for-the-badge&logo=matplotlib&logoColor=white)](https://matplotlib.org/)
[![Seaborn](https://img.shields.io/badge/Seaborn-FF6F61?style=for-the-badge&logoColor=white)](https://seaborn.pydata.org/)
[![Math](https://img.shields.io/badge/Math-4A90D9?style=for-the-badge&logoColor=white)](https://docs.python.org/3/library/math.html)
[![scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikit-learn&logoColor=white)](https://scikit-learn.org/)
[![SciPy](https://img.shields.io/badge/SciPy-8CAAE6?style=for-the-badge&logo=scipy&logoColor=white)](https://scipy.org/)
[![K-means](https://img.shields.io/badge/K--means-FFD700?style=for-the-badge&logoColor=black)](https://en.wikipedia.org/wiki/K-means_clustering)
[![Customer Lifetime Value](https://img.shields.io/badge/Customer_Lifetime_Value-1E6B5E?style=for-the-badge&logoColor=white)](https://en.wikipedia.org/wiki/Customer_lifetime_value)
[![RFM](https://img.shields.io/badge/RFM-4CAF50?style=for-the-badge&logoColor=white)](https://en.wikipedia.org/wiki/RFM_model)
---

## Problem Statement

The primary objective of this project is to conduct an in-depth analysis of online retail transaction data to identify distinct customer segments through RFM (Recency, Frequency, Monetary) analysis. By systematically evaluating customer behavior across these dimensions, the study aims to estimate Customer Lifetime Value (CLV) and inform the development of targeted marketing strategies to enhance customer retention and overall profitability.

---

## Tech Stack

| Tool | Role |
|------|------|
| **Python** | Data cleaning, KMeans clustering, probabilistic CLV modeling, Predictive Modeling |
| **SQL** | RFM metrics, window functions, segmentation analysis |
| **Power BI** | Interactive dashboard, cohort heatmap, DAX measures |

---

## Workflow

```
Raw Data (525K rows)
       │
       ▼
Python — Clean & validate
       │
       ▼
SQL — RFM metrics + window function analysis + segmentation
       │
       ▼
Python — KMeans clustering + outlier segmentation
       │
       ▼
Python — Probabilistic CLV (BG/NBD + Gamma-Gamma)
       │
       ▼
Power BI — Business Performance + Customer Intelligence dashboard
```

---

## Analysis Pipeline

### 1. Data Cleaning
- **87% data retention** — 525K → 400K+ clean records
- Engineered `SalesLineTotal` as base monetary metric

---

### 2. RFM Analysis (SQL)
Calculated per-customer **Recency** (days since last purchase), **Frequency** (unique invoice count), and **Monetary** (total spend). Scored each metric 1–5 and assigned rule-based segment labels.

**Window functions applied:**
| Function | Purpose |
|----------|---------|
| `RANK`, `DENSE_RANK`, `ROW_NUMBER` | Customer revenue ranking |
| `NTILE(5)` | Quintile boundaries for RFM scoring |
| `SUM OVER` | Cumulative revenue, 80/20 identification |
| `AVG OVER` | Customer vs. overall and country-level averages |
| `LAG`, `LEAD` | Month-over-month revenue and customer growth |
| `FIRST_VALUE`, `LAST_VALUE` | First and last purchase per customer |
| `PERCENT_RANK`, `CUME_DIST` | Revenue percentile distribution |

---

### 3. Customer Segmentation (Python — KMeans)
- Removed outliers using IQR method on Monetary and Frequency independently
- Scaled features using `StandardScaler` (mean=0, std=1) to prevent metric dominance
- Optimal k selected via **Elbow method** (inertia) + **Silhouette score** — k=4 selected
- Outlier customers segmented separately into PAMPER / UPSELL / DELIGHT based on which IQR boundary they breached

**Segments:**
| Segment | Profile | Action |
|---------|---------|--------|
| **REWARD** | High value, high frequency, recent | VIP programs, exclusive offers |
| **RETAIN** | High value, regular, not always recent | Loyalty programs, personalized offers |
| **NURTURE** | Recent, low frequency, low spend | Incentives, relationship building |
| **RE-ENGAGE** | Inactive, previously engaged | Win-back campaigns, time-limited discounts |
| **PAMPER** | High spend, infrequent | Premium personalized service |
| **UPSELL** | High frequency, low spend per visit | Bundle deals, basket size optimization |
| **DELIGHT** | Extreme spend + frequency (top-tier outliers) | Top-tier VIP treatment |

Violin plots used to validate segment separation across Recency, Frequency and Monetary distributions before finalizing labels.

---

### 4. Probabilistic CLV Modeling (Python — BG/NBD + Gamma-Gamma)

**Why probabilistic over descriptive?**  
RFM clustering describes past behavior. Probabilistic models predict future behavior — specifically whether a customer is still active and what they will spend next.

**BG/NBD Model**
- Predicts number of future transactions per customer
- Outputs `probability_alive` — the likelihood a customer is still an active buyer vs. silently churned
- Key insight from probability alive matrix: customers with high frequency and long recency window have the highest survival probability

**Gamma-Gamma Model**
- Predicts average transaction value per customer based on frequency and historical monetary value
- Assumes spend per transaction varies around each customer's personal average
- Applied only to customers with `monetary_value > 0`

**90-Day CLV Output**
```
CLV (90 days) = BG/NBD predicted transactions × Gamma-Gamma predicted spend × profit margin (15%)
```
- `time=3` months, `freq='D'` (daily), `discount_rate=0.01`
- Per-customer profit prediction stored in `predicted_profit_3mo`
- CLV range: **£2 – £11,308** per customer over 90 days

---

## Dashboard — Power BI

### Page 1 — Business Performance
*Answers: Is the business growing? Where does revenue come from? What drives it?*

| Visual | Business Question Answered |
|--------|---------------------------|
| KPI Cards (Revenue, Orders, Customers, AOV) | Is growth recent or structural? |
| Monthly Revenue Trend (cumulative) | When did growth peak and why did it drop? |
| Revenue by Day of Week | Which days to run campaigns and promotions? |
| Top 5 Products | Which SKUs carry the most revenue risk? |
| Top 10 Countries | How dependent are we on a single market? |
| UK vs International Donut | What is the geographic concentration risk? |

---

### Page 2 — Customer Intelligence & Retention
*Answers: Who are our customers? Are we keeping them? Which ones matter most?*

| Visual | Business Question Answered |
|--------|---------------------------|
| KPI Cards (Retention, Frequency, Spend) | Do we have a loyalty problem or advantage? |
| RFM Segment Donut | Where should marketing budget be allocated? |
| Top 8 Customers by Revenue | How much revenue risk sits in a few accounts? |
| New vs Returning (Monthly) | Is growth acquisition-led or retention-led? |
| Cohort Retention Heatmap | When exactly do we lose customers? |

---

## Key Findings

**Revenue is growing — but concentration is a risk**  
**£8.28M** total revenue. **+4.3% MoM**, **+1,398.7% YoY**. The YoY figure reflects a near-zero baseline in Dec 2010. The MoM trend is the reliable signal. UK generates **£6.75M (81.5%)** of all revenue. Netherlands is second at **£0.28M**. One market disruption has no revenue buffer.

**The business runs on a 4-day window**  
Thursday peaks at **£1.90M**. Sunday sits at **£0.78M**. Saturday is near-zero. Campaigns, restocks and outreach scheduled outside Tuesday–Thursday are operating against the grain of actual purchase behavior.

**One SKU, one exposure**  
Regency Cakestand 3-Tier at **£133K** leads all products. Revenue dependency on a narrow product set means stockouts or supplier issues have direct P&L impact. Top-5 SKU concentration needs to be stress-tested.

**Retention is strong — but the first 30 days are where customers are lost**  
**3,059 of 4,372 customers returned (69.97%)**. Avg frequency: **5.1x/year**. Avg lifetime spend: **£1.89K**. But cohort analysis shows retention drops to **~20–25% by Month 1** across every cohort before stabilizing at 20–35%. The loyalty base is real — but it is built from customers who survive Month 1. That window is where intervention has maximum leverage.

**Over a third of the customer base is disengaged**  
RFM breakdown: **Re-engage at 36.18%** is the single largest segment. Combined with **Lost (4.32%)**, 40%+ of customers are inactive. **Reward (19.83%)** and **Retain (16.42%)** represent the core revenue base. Current marketing spend distribution almost certainly does not reflect this.

**Probabilistic CLV reveals who is worth fighting for**  
BG/NBD probability alive scores identify customers who appear inactive but statistically remain buyers. Gamma-Gamma predicted spend combined with BG/NBD purchase predictions produces a per-customer 90-day profit figure. This directly answers what acquisition and retention spend is justifiable per customer — something RFM alone cannot do.

**Single-account revenue concentration is a business risk**  
Top customer (ID: **14646**) generated **£279.49K** — approximately 3.4% of total revenue from one account. At this concentration, account health monitoring is a revenue protection activity.

**November 2011 peak followed by sharp December drop**  
Revenue peaked in Nov 2011 and dropped sharply in Dec. Dataset ends mid-December — the drop is partly a data completeness artifact. Seasonal conclusions should not be drawn until full December data is confirmed.

---

## Recommendations

**1. Intervene at Month 1**  
Cohort data is unambiguous — retention collapses in the first 30 days. A triggered onboarding sequence (email, offer, or outreach) on first purchase is the highest-leverage retention investment available.

**2. Activate Re-engage before they become Lost**  
36% of customers are disengaged but recoverable. A time-limited win-back campaign targeting this segment captures revenue that is otherwise permanently lost. Every month of inaction converts more of this group into the 4.32% Lost bucket.

**3. Use probabilistic CLV to set per-customer marketing budgets**  
90-day profit predictions per customer exist. Acquisition and retention spend should be capped as a percentage of predicted CLV — not set as a flat rate across all segments. This prevents overspending on low-CLV customers and underspending on high-probability returners.

**4. Validate international expansion in Netherlands and Germany**  
Both markets show organic traction without targeted investment. A controlled paid experiment would test whether international can become a second revenue pillar and reduce the current 81.5% UK dependency.

---

## Repository Structure

```
ecommerce-customer-analytics/
├── README.md
├── data/
│   ├── raw/README.md              ← dataset source + link
│   └── processed/
│       ├── cleaned_df.csv
├── sql/
│   └── rfm_analysis.sql           ← RFM metrics + window functions
├── python/
│   ├──E_Commerce_CLV.ipynb ← KMeans + outlier segmentation, BG/NBD + Gamma-Gamma + 90-day CLV
│   └── requirements.txt
├── powerbi/
│   ├── ecommerce_dashboard.pbix
│   └── screenshots/
│       ├── page1_business_performance.png
│       └── page2_customer_retention.png
└── insights/
    └── key_findings_&_recommendations.md
```

---

## Setup

```bash
# Python
pip install -r python/requirements.txt
# Run in order: 01 → 02 → 03

# SQL
# Execute sql/rfm_analysis.sql in any SQL client
# Export final output → rfm_segmented_customers.csv

# Power BI
# Open powerbi/ecommerce_dashboard.pbix in Power BI Desktop
```

**Dataset:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii)  
**Period:** Dec 2010 – Dec 2011 | **Raw records:** 525,461 | **After cleaning:** ~400K (87% retained)
