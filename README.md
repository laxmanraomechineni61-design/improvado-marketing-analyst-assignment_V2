# Cross-Channel Marketing Performance Analysis
### Improvado Marketing Analyst Technical Assignment

---

## Overview

This project unifies paid advertising data from **Facebook**, **Google Ads**, and **TikTok** into a single normalized data model, enabling cross-channel performance analysis through one consistent schema and pre-calculated KPIs.

**Data period:** January 2024 | **Total records:** 330 rows (110 per platform)

---

## The Problem

Each platform exports data in its own format:

| Field | Facebook | Google | TikTok |
|---|---|---|---|
| Money spent | `spend` | `cost` | `cost` |
| Ad group ID | `ad_set_id` | `ad_group_id` | `adgroup_id` |
| Video metrics | `video_views` | — | `video_watch_25/50/75/100` |
| Platform-specific | `reach`, `frequency`, `engagement_rate` | `quality_score`, `avg_cpc`, `search_impression_share` | `likes`, `shares`, `comments` |

Without normalization, cross-platform comparison is impossible.

---

## Solution: Unified Data Model

`unified_model.sql` — a BigQuery Standard SQL query that:

1. **Renames** all platform-specific column names to a common schema
2. **Fills NULLs** for platform-specific columns that don't exist on other platforms
3. **Calculates KPIs** at the SQL layer (not the dashboard layer) for consistency:
   - **CTR** = clicks / impressions
   - **CPA** = spend / conversions
   - **CPM** = (spend / impressions) × 1,000
4. **Unions** all three platforms into one queryable table

> **Note on CTR:** Google Ads natively provides a `ctr` column. We recalculate it from raw `clicks/impressions` across all platforms to ensure a consistent, comparable definition regardless of platform-reported values.

---

## How to Run

```sql
-- In BigQuery, run unified_model.sql against:
-- Project: improvado-assignment-498500
-- Dataset: marketing_data
-- Tables: facebook_ads, google_ads, tiktok_ads
```

Output schema of the unified table: 28 columns

```
date, platform, campaign_id, campaign_name,
ad_group_id, ad_group_name, impressions, clicks, spend,
conversions, video_views, ctr, cpa, cpm,
engagement_rate, reach, frequency,          -- Facebook only
conversion_value, avg_cpc, quality_score,
search_impression_share,                    -- Google only
video_watch_25/50/75/100, likes, shares,
comments                                    -- TikTok only
```

---

## Key Findings & Recommendations

### 1. Facebook delivers the best return on spend

| Platform | Budget Share | Conversion Share | CPA |
|---|---|---|---|
| **Facebook** | **14%** | **17.9%** | **$7.64** |
| Google | 28.9% | 31.6% | $8.93 |
| TikTok | 57.0% | 50.5% | $11.00 |

**Facebook converts more than it costs** — 14% of budget yields 17.9% of conversions. TikTok is the opposite — 57% of budget for only 50.5% of conversions.

> **Recommendation:** Reallocate 10-15% of TikTok budget to Facebook, especially to the Conversions_Retargeting campaign (CPA: $5.95).

---

### 2. Google Search Brand Terms is the single best-performing campaign

| Rank | Platform | Campaign | CPA | CTR |
|---|---|---|---|---|
| 1 | Google | Search_Brand_Terms | $5.10 | 5.22% |
| 2 | Facebook | Conversions_Retargeting | $5.95 | 4.63% |
| 3 | Google | Shopping_All_Products | $6.34 | 3.34% |

Worst performer: **Google Search_Generic_Terms at $24.80 CPA** — 4.9× worse than brand terms on the same platform.

> **Recommendation:** Pause or drastically cut Search_Generic_Terms budget. Shift Google budget toward Brand and Shopping campaigns.

---

### 3. TikTok's video funnel drops sharply after the first 25%

| Checkpoint | % of Viewers Who Reached It |
|---|---|
| 25% of video | 78.2% |
| 50% of video | 57.4% |
| 75% of video | 39.7% |
| 100% (completed) | **26.0%** |

Only 1 in 4 viewers watches a TikTok ad to completion. Despite this, TikTok drives massive reach (28.7M impressions vs Facebook's 4.5M).

> **Recommendation:** Front-load the key message in the first 3 seconds. Test shorter ad formats (6-9 seconds) to improve completion rates and conversion efficiency.

---

### 4. Facebook CPA is consistently improving week over week

| Week | Facebook CPA | Google CPA | TikTok CPA |
|---|---|---|---|
| Week 1 | $7.83 | $8.65 | $11.28 |
| Week 2 | $7.88 | $8.99 | $11.01 |
| Week 3 | $7.56 | $9.06 | $10.93 |
| Week 4 | $7.46 | $8.94 | $10.93 |
| Week 5 | $7.39 | $9.08 | $10.91 |

Facebook CPA improved **5.6% from Week 1 to Week 5**, likely driven by algorithm learning and audience optimization. Google and TikTok show flat or worsening trends.

> **Recommendation:** Facebook campaigns are still in the optimization phase — do not disrupt targeting or creatives. Let the algorithm continue learning.

---

### 5. Google Quality Score is a strong predictor of CTR

| Quality Score | Avg CTR |
|---|---|
| 6 | 2.00% |
| 7 | 1.09% |
| 8 | 3.33% |
| 9 | **5.21%** |

QS 9 campaigns deliver **2.6× higher CTR** than QS 7 campaigns. Every point of Quality Score is not equal — the jump from 8→9 is especially significant.

> **Recommendation:** Prioritize improving Quality Score on underperforming ad groups by improving ad relevance and landing page experience.

---

## Assumptions Made

1. All monetary values are in the same currency (USD assumed)
2. `conversions` represents the same event type across platforms (purchase/lead)
3. January 2024 data is representative; no major campaign changes mid-month
4. Google's natively reported CTR is overridden by our calculated CTR for cross-platform consistency
5. NULL values in platform-specific columns represent "not applicable", not missing data

---

## Files

| File | Description |
|---|---|
| `unified_model.sql` | BigQuery SQL — normalizes and unions all 3 platforms |
| `unified_data.csv` | Output of the SQL — 330 rows, 28 columns, ready for BI tools |
| `01_facebook_ads.csv` | Raw Facebook Ads data — Jan 2024, 110 rows |
| `02_google_ads.csv` | Raw Google Ads data — Jan 2024, 110 rows |
| `03_tiktok_ads.csv` | Raw TikTok Ads data — Jan 2024, 110 rows |

---

## Dashboard

The `unified_data.csv` is structured for direct import into **Looker Studio** or any BI tool.

Suggested dashboard views:
- Platform comparison: CPA, CTR, CPM side by side
- Campaign leaderboard: sorted by CPA
- TikTok video funnel: watch-through rates
- Weekly trend: CPA over time per platform
- Google Quality Score impact analysis
