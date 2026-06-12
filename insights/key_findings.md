# Key Findings & Recommendations


## 1 — Revenue & Business Performance

### 1.1 Growth
- Total revenue: **£8.28M** | MoM: **+4.3%** | YoY: **+1,398.7%**
- YoY figure reflects near-zero Dec 2010 baseline — not a reliable growth signal
- MoM consistency (+4.3% on both revenue and orders) is the credible trend
- Total orders: **22K** | MoM: **+4.3%** | YoY: **+1,199.2%**
- Total customers: **4,372** | MoM: **+0.9%** — customer base growing slower than revenue, meaning existing customers are spending more

**Implication:** Revenue per customer is increasing. The business is deepening wallet share, not just acquiring volume. Avg order value at **£373.07** with revenue per customer at **£1.89K** confirms this.


### 1.2 Geographic Concentration
- UK: **£6.75M (81.5%)** of total revenue
- International: **£1.53M (18.5%)**
- Top international market: Netherlands **£0.28M** — less than 5% of UK revenue

**Implication:** The business has a single-market dependency. Any UK demand disruption — regulatory, economic, or competitive — has no revenue buffer. Netherlands and Germany show organic traction without targeted investment. They are the lowest-risk entry points for international expansion.


### 1.3 Day-of-Week Revenue Pattern
- Thursday: **£1.90M** — peak revenue day
- Tuesday and Wednesday close behind
- Sunday: **£0.78M** | Saturday: near-zero

**Implication:** The business effectively operates on a 4-day commercial window (Mon–Thu). Marketing campaigns, email sends, promotions, and restock decisions scheduled outside this window are working against actual purchase behavior. Weekend activity is low enough that it may not justify operational cost.


### 1.4 Product Concentration
- Top product: Regency Cakestand 3-Tier — **£133K**
- Top 5 products carry disproportionate revenue weight

**Implication:** Revenue dependency on a narrow SKU set creates supply chain risk. A stockout or supplier failure on top-5 products has a direct and measurable P&L impact. These SKUs warrant priority inventory management and supplier diversification.


### 1.5 November Peak and December Drop
- Revenue peaked in **November 2011** then dropped sharply in December
- Dataset ends mid-December — the drop is partly a data completeness artifact

**Implication:** Seasonal conclusions should not be drawn from December figures until full-month data is confirmed. If the drop is real, it indicates the business has a post-peak demand problem and needs a strategy to sustain Q4 momentum beyond Black Friday / gifting season.


## 2 — Customer Segmentation (RFM + KMeans)

### 2.1 Segment Distribution
| Segment | Share | Profile |

| **Re-Engage** | 36.18% | Inactive, previously engaged |
| **Reward** | 19.83% | High value, high frequency, recent |
| **Retain** | 16.42% | High value, regular buyers |
| **Nurture** | 14.96% | Recent, low frequency, low spend |
| **Others** | 8.28% | Mixed signals |
| **Lost** | 4.32% | No recent activity, low scores |

**Implication:** The largest single segment is disengaged customers. The combined Re-Engage + Lost pool (40.5%) represents recoverable and permanently lost revenue respectively. The core monetizable base — Reward + Retain — is only **36.25%** of customers. Marketing spend allocation almost certainly does not reflect this distribution.


### 2.2 Outlier Segments
Customers removed from main clustering due to extreme IQR values were segmented separately:

| Segment | Profile | Priority Action |

| **PAMPER** | High spend, infrequent | Personalized re-activation — one lost purchase is high-value |
| **UPSELL** | High frequency, low spend | Basket size optimization — they're already buying, increase order value |
| **DELIGHT** | Extreme spend + frequency | Top-tier VIP — these are the highest-risk accounts to lose |

**Implication:** Outlier customers should never be treated as noise. DELIGHT customers alone likely represent a significant share of total revenue concentration. They need account-level management, not segment-level campaigns.


### 2.3 Top Account Concentration
- Customer ID **14646**: **£279.49K** — approximately **3.4% of total revenue** from a single account
- Top 8 customers individually generate between £71K–£279K

**Implication:** This is institutional revenue concentration. Losing the top account is a reportable business event. These accounts need named relationship owners, proactive health monitoring, and retention plans that are independent of standard CRM workflows.


## 3 — Retention & Cohort Analysis

### 3.1 Retention Overview
- Returning customers: **3,059 of 4,372 (69.97%)**
- Avg purchase frequency: **5.1x per customer/year**
- Avg lifetime spend: **£1.89K**
- Overall retention rate: **70.0%**

**Implication:** A 70% retention rate is strong. The business has a loyal core. But the aggregate metric masks a critical structural problem visible only in cohort data.


### 3.2 Cohort Retention — Where Customers Are Actually Lost
- Retention drops to **~20–25% by Month 1** across all cohorts
- Stabilizes at **20–35%** from Month 2 onwards
- December 2010 cohort shows the strongest long-term retention

**Implication:** 75–80% of customers who make a first purchase do not return in Month 1. The 70% retention headline is driven entirely by customers who survived this initial drop. Month 1 is not a retention problem — it is the retention problem. Customers who make it past Month 1 tend to stick. The intervention window is the first 30 days after acquisition.


## 4 — Probabilistic CLV Modeling

### 4.1 What Probabilistic Models Add Over RFM
RFM clustering answers *what did customers do?*  
Probabilistic models answer *what will customers do next — and are they still active?*

Two models were applied in sequence:

**BG/NBD Model**
- Predicts future transaction count per customer
- Outputs `probability_alive` — whether a customer is still an active buyer or has silently churned
- Customers with high frequency and long recency window have the highest survival probability
- Key use: separating genuinely inactive customers from those who look inactive but are statistically likely to return

**Gamma-Gamma Model**
- Predicts average transaction value based on each customer's purchase history
- Applied only to customers with positive monetary value
- Adjusts historical averages based on confidence — customers with more purchases get predictions closer to their actual average; low-frequency customers get pulled toward the population mean


### 4.2 90-Day CLV Predictions
```
Predicted Profit (90 days) = BG/NBD transactions × Gamma-Gamma spend × 15% margin
```
- CLV range: **£2 – £11,308** per customer over 90 days
- Distribution is highly skewed — a small number of customers generate the majority of near-term profit

**Implication:** The CLV range proves that treating all customers equally is not just suboptimal — it is actively damaging. Spending the same to retain a £2 CLV customer as an £11,308 CLV customer misallocates budget at scale. Per-customer profit predictions directly set the ceiling on justifiable spend for acquisition and retention.


### 4.3 Why Probabilistic Beats Descriptive CLV
| Model Type | What It Does | Limitation |
|-----------|-------------|-----------|
| Aggregation | Average CLV across all customers | Too optimistic, no individual variation |
| Cohort | CLV by acquisition month | More granular but still backward-looking |
| Probabilistic (BG/NBD + GG) | Per-customer future prediction | Requires transaction history depth |

Descriptive models are useful for reporting. Probabilistic models are useful for decisions. The 90-day profit figure per customer is directly actionable — it sets a budget ceiling per customer that descriptive models cannot.


## 5 — Recommendations

### R1 — Build a Month 1 Retention Trigger
**Priority: High | Effort: Low**  
Cohort data shows retention collapses in the first 30 days universally. A triggered sequence — onboarding email, first-purchase follow-up, time-limited second-order incentive — activated within 7 days of acquisition is the single highest-leverage retention investment available. No other intervention has a larger addressable population.


### R2 — Run a Structured Re-Engage Campaign
**Priority: High | Effort: Medium**  
36.18% of customers are disengaged. This is recoverable revenue with a defined time window. A win-back campaign with a time-limited offer, personalized by last purchase category, will convert a measurable share before they migrate to Lost. Every month of inaction permanently reduces the recoverable pool.


### R3 — Set Per-Customer Spend Caps Using CLV
**Priority: High | Effort: Medium**  
90-day profit predictions exist at the customer level. Acquisition and retention spend should be capped as a percentage of predicted CLV — not distributed as a flat rate. A customer with £11,308 predicted CLV justifies significantly more retention spend than one with £2 CLV. Applying a uniform spend rate across all segments wastes budget on low-value customers and under-invests in high-value ones.


### R4 — Implement Account-Level Management for Top Customers
**Priority: High | Effort: Low**  
Top customer (ID: 14646) represents 3.4% of total revenue. The top 8 customers individually generate £71K–£279K. At this concentration level, standard CRM workflows are insufficient. These accounts need named owners, proactive health tracking, and retention plans triggered by behavioral signals — not by churn after the fact.


### R5 — Validate International Expansion in Netherlands and Germany
**Priority: Medium | Effort: Medium**  
Both markets show organic revenue traction without targeted investment. A controlled paid experiment — structured as a 90-day test with a defined CAC ceiling based on CLV predictions for those markets — would validate whether international can become a second revenue pillar. Current 81.5% UK dependency is a structural risk that only market diversification resolves.


### R6 — Stress-Test Top-SKU Dependency
**Priority: Medium | Effort: Low**  
Top 5 products carry disproportionate revenue concentration. A supplier disruption or demand shift on these SKUs has immediate P&L impact. Mapping substitute products, diversifying supplier relationships for top-5 SKUs, and setting reorder triggers based on sales velocity are standard supply chain risk management steps that the product concentration data now justifies.


## Summary

| Finding | Metric | Action |

| Month 1 drop-off | 75–80% churn in first 30 days | Trigger-based onboarding sequence |
| Re-Engage segment | 36.18% of customer base | Win-back campaign |
| UK concentration | 81.5% of revenue | Test Netherlands + Germany |
| Top account risk | ID 14646 = 3.4% of revenue | Account-level management |
| CLV range | £2 – £11,308 per customer | Per-customer spend caps |
| Top SKU risk | Regency Cakestand leads at £133K | Supplier diversification |
| Thursday peak | £1.90M vs Sunday £0.78M | Align campaigns to Tue–Thu |