# Looker Studio Dashboard Setup Guide
## SIGNAL · Multi-Platform Ad Intelligence

Exact configuration to build and extend the dashboard —
maintaining the existing layout and adding the 4 missing widgets.

---

## Step 1 — Run All BigQuery Views in Order

```sql
-- Run in BigQuery in this exact sequence:
1. unified_model.sql                        → unified_ads (base table)
2. views/01_platform_summary.sql            → platform_summary
3. views/02_campaign_performance.sql        → campaign_performance
4. views/03_daily_trend.sql                 → daily_trend
5. views/07_tiktok_video_funnel_widget.sql  → tiktok_video_funnel_widget
6. views/08_google_quality_score_widget.sql → google_quality_score_widget
7. views/09_weekly_cpa_trend_widget.sql     → weekly_cpa_trend_widget
8. views/10_efficiency_scorecard_widget.sql → efficiency_scorecard_widget
```

---

## Step 2 — Data Sources to Add in Looker Studio

| Data Source Name | BigQuery View | Powers |
|---|---|---|
| Unified Ads | `unified_ads` | All base widgets |
| Platform Summary | `platform_summary` | Platform KPI tiles + efficiency scorecards |
| Campaign Performance | `campaign_performance` | Table + Scatter + Sankey |
| Daily Trend | `daily_trend` | Spending Overtime line chart |
| TikTok Funnel | `tiktok_video_funnel_widget` | Video completion funnel (NEW) |
| QS Analysis | `google_quality_score_widget` | Quality Score chart (NEW) |
| Weekly CPA | `weekly_cpa_trend_widget` | Weekly CPA trend (NEW) |
| Efficiency | `efficiency_scorecard_widget` | Budget vs Conv share (NEW) |

---

## Step 3 — Existing Widgets (Keep As-Is)

### ✅ Header Bar
- Title: **SIGNAL · Multi-Platform Ad Intelligence**
- Subtitle: Facebook · Google · TikTok | January 2024 | 12 Campaigns
- Background: #1a237e (dark navy)

### ✅ Top 5 KPI Scorecards
| Scorecard | Source | Field | Format |
|---|---|---|---|
| Total Spend | unified_ads | SUM(spend) | $130.24K |
| Total Clicks | unified_ads | SUM(clicks) | 688,333 |
| Blended CTR | unified_ads | SUM(clicks)/SUM(impressions) | 0.02 |
| Total Conversions | unified_ads | SUM(conversions) | 13,363 |
| Blended CPA | unified_ads | SUM(spend)/SUM(conversions) | $10.88 |

### ✅ Platform KPI Tiles (Facebook / Google / TikTok)
Source: `platform_summary`
| Field shown | Column | Format |
|---|---|---|
| spend | total_spend | $18.29K / $37.69K / $74.27K |
| BLENDED CPA | blended_cpa | 7.6 / 8.9 / 11.0 |
| CPM | blended_cpm | 4.0 / 5.2 / 2.6 |
| BLENDED CTR | blended_ctr | 2.0 / 1.9 / 1.6 |

Platform colors:
- Facebook: `#1877f2` (blue)
- Google: `#6f42c1` (purple)
- TikTok: `#212121` (near black)

### ✅ CONVERSIONS Donut
- Source: `efficiency_scorecard_widget`
- Dimension: platform
- Metric: total_conversions
- Colors: Facebook #1877f2, Google #6f42c1, TikTok #212121

### ✅ SPEND INDICATOR Scatter Plot
- Source: `campaign_performance`
- X-axis: blended_ctr
- Y-axis: blended_cpa
- Bubble size: total_spend
- Color dimension: platform

### ✅ PLATFORMS SPENDING OVERTIME Line Chart
- Source: `daily_trend`
- Dimension: date
- Metric: daily_spend
- Breakdown dimension: platform
- Line colors: TikTok = light blue, Google = blue, Facebook = navy

### ✅ SPENDING OF PLATFORMS Sankey
- Source: `campaign_performance`
- Source node: platform
- Target node: campaign_name
- Value: total_spend

### ✅ PERFORMANCE ANALYSIS TABLE
- Source: `campaign_performance`
- Columns: campaign_name, platform, total_spend, total_conversions,
           total_clicks, blended_cpa, blended_cpr
- Sort: blended_cpa ASC
- Rows per page: 12

---

## Step 4 — ADD These 4 Missing Widgets

---

### 🆕 Widget 1: TIKTOK VIDEO COMPLETION FUNNEL

```
Type        : Bar chart (horizontal)
Title       : TIKTOK VIDEO COMPLETION FUNNEL
Source      : tiktok_video_funnel_widget
Dimension   : funnel_stage
Metric      : pct_of_views
Sort        : sort_order ASC
Data labels : ON — show pct_of_views value
Bar color   : #212121 (match TikTok tile)

Position    : Row 4, Left column (below Sankey)
Size        : ~400px wide × 280px tall
```

What it shows:
```
Impressions → Views   100%  ████████████████████
25% Watched            78%  ████████████████
50% Watched            57%  ████████████
75% Watched            40%  ████████
Completed (100%)       26%  █████
```

---

### 🆕 Widget 2: GOOGLE QUALITY SCORE vs CTR

```
Type        : Bar chart (vertical)
Title       : GOOGLE QUALITY SCORE vs CTR
Source      : google_quality_score_widget
Dimension   : quality_score_label
Metric      : blended_ctr (format as %)
Sort        : sort_order ASC
Color by    : qs_tier field
  Excellent → #1e8449
  Good      → #27ae60
  Average   → #f39c12
Secondary   : avg_cpa (right Y-axis, line overlay)

Position    : Row 4, Right column (next to funnel)
Size        : ~400px wide × 280px tall
```

What it shows:
```
QS 6  ██  2.00%
QS 7  █   1.09%
QS 8  ████  3.33%
QS 9  ██████████  5.21%
```

---

### 🆕 Widget 3: WEEKLY CPA TREND BY PLATFORM

```
Type        : Line chart
Title       : WEEKLY CPA TREND — Is efficiency improving?
Source      : weekly_cpa_trend_widget
Dimension   : week_label
Metric      : weekly_cpa
Breakdown   : platform
Line colors : Facebook = #1877f2, Google = #6f42c1, TikTok = #212121
Show points : ON
Data labels : ON (last point only)

Position    : Row 5, full width (below funnel + QS row)
Size        : Full width × 220px tall
```

What it shows:
```
$12 ─ ─ ─ ─ ─ TikTok  $11.28 → $11.01 → $10.93 → $10.93 → $10.91
 $9 ─────────── Google  $8.65 → $8.99  → $9.06  → $8.94  → $9.08
 $7 ─── Facebook $7.83 → $7.88 → $7.56 → $7.46  → $7.39 ← improving
```

---

### 🆕 Widget 4: BUDGET vs CONVERSION SHARE

```
Type        : 2 × Scorecard + 1 Table

Scorecards (3 in a row, one per platform):
  Source    : efficiency_scorecard_widget
  Metric    : efficiency_index
  Label     : platform
  Green if  : efficiency_index > 1.0
  Red if    : efficiency_index < 1.0

  Facebook  1.28 ✓ Over-delivering
  Google    1.09 ✓ Over-delivering
  TikTok    0.89 ✗ Under-delivering

Table below scorecards:
  Columns   : platform, budget_share_pct, conversion_share_pct,
              efficiency_index, efficiency_label, blended_cpa
  Sort      : efficiency_index DESC

Position    : Row 5, right section (or new row 6)
```

---

## Final Dashboard Layout After All Gaps Filled

```
┌─────────────────────────────────────────────────────────────────┐
│         SIGNAL · Multi-Platform Ad Intelligence                 │
│         Facebook · Google · TikTok | Jan 2024 | 12 Campaigns   │
├──────────┬──────────┬──────────┬──────────┬─────────────────────┤
│  SPEND   │  CLICKS  │   CTR    │   CONV   │    BLENDED CPA      │  ← existing
│ $130.24K │ 688,333  │   0.02   │  13,363  │      $10.88         │
├──────────┴──────────┴──────────┴──────────┴─────────────────────┤
│ [FACEBOOK $18.29K] [GOOGLE $37.69K]  [TIKTOK $74.27K]          │  ← existing
│  CPA 7.6 CPM 4.0   CPA 8.9 CPM 5.2   CPA 11.0 CPM 2.6         │
├──────────────────────┬──────────────────────────────────────────┤
│  CONVERSIONS (donut) │  SPEND INDICATOR (scatter)               │  ← existing
├──────────────────────┴──────────────────────────────────────────┤
│  PLATFORMS SPENDING OVERTIME (daily line chart)                 │  ← existing
├────────────────────────┬────────────────────────────────────────┤
│  SPENDING OF PLATFORMS │  PERFORMANCE ANALYSIS TABLE            │  ← existing
│  (sankey flow)         │  Campaign | Platform | Spend | CPA...  │
├────────────────────────┴────────────────────────────────────────┤
│  TIKTOK FUNNEL (bar)   │  GOOGLE QS vs CTR (bar)                │  ← 🆕 NEW
│  100% → 78% → 26%      │  QS9 = 5.21% CTR vs QS7 = 1.09%       │
├─────────────────────────────────────────────────────────────────┤
│  WEEKLY CPA TREND (line) — Facebook improving, TikTok flat      │  ← 🆕 NEW
├────────────────────────┬────────────────────────────────────────┤
│  EFFICIENCY SCORECARDS │  BUDGET vs CONVERSION TABLE            │  ← 🆕 NEW
│  FB 1.28✓ GG 1.09✓     │  platform | budget% | conv% | index    │
│  TikTok 0.89✗           │                                        │
└────────────────────────┴────────────────────────────────────────┘
```
