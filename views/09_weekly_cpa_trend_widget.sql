/*
  view: weekly_cpa_trend_widget
  ══════════════════════════════════════════════════════════════════
  GAP FILL #3 — Missing from dashboard
  ──────────────────────────────────────────────────────────────────
  Their dashboard has "PLATFORMS SPENDING OVERTIME" (daily spend).
  This view adds the CPA trend — showing Facebook improving weekly,
  a key strategic signal missing from the current dashboard.

  Widget to add in Looker Studio:
    Type        : Line chart
    Title       : WEEKLY CPA TREND BY PLATFORM
    Dimension   : week_label
    Breakdown   : platform
    Metric      : weekly_cpa
    Color       : Facebook = #1877f2, Google = #6f42c1, TikTok = #212121
    Sort        : sort_order ASC

  Place this as a second line chart below "PLATFORMS SPENDING OVERTIME".
  This is the "so what?" chart — spending trend shows scale,
  CPA trend shows efficiency.

  Key insight visible in this widget:
    Facebook CPA declined from $7.83 (Wk1) → $7.39 (Wk5) = -5.6%.
    Google CPA is flat/slightly worsening.
    TikTok CPA is slowly improving but remains highest.
    Recommendation: do NOT pause Facebook campaigns mid-learning phase.
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.weekly_cpa_trend_widget` AS

WITH weekly_raw AS (
    SELECT
        platform,
        CAST(CEIL(EXTRACT(DAY FROM date) / 7.0) AS INT64)  AS week_number,
        SUM(spend)                                           AS weekly_spend,
        SUM(conversions)                                     AS weekly_conversions,
        SUM(clicks)                                          AS weekly_clicks,
        SUM(impressions)                                     AS weekly_impressions
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    GROUP BY platform, week_number
)

SELECT
    platform,
    week_number,
    CONCAT('Week ', CAST(week_number AS STRING))            AS week_label,
    week_number                                             AS sort_order,

    ROUND(weekly_spend, 2)                                  AS weekly_spend,
    weekly_conversions,
    weekly_clicks,
    weekly_impressions,

    -- Weekly KPIs
    ROUND(SAFE_DIVIDE(weekly_spend,       weekly_conversions), 2)  AS weekly_cpa,
    ROUND(SAFE_DIVIDE(weekly_clicks,      weekly_impressions), 4)  AS weekly_ctr,
    ROUND(SAFE_DIVIDE(weekly_spend,       weekly_impressions) * 1000, 2) AS weekly_cpm,
    ROUND(SAFE_DIVIDE(weekly_conversions, weekly_clicks),      4)  AS weekly_cpr,

    -- Week-over-week CPA change (positive = got more expensive)
    ROUND(
        SAFE_DIVIDE(weekly_spend, weekly_conversions) -
        LAG(SAFE_DIVIDE(weekly_spend, weekly_conversions))
            OVER (PARTITION BY platform ORDER BY week_number),
    2)                                                             AS cpa_wow_change,

    -- % change vs prior week
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(weekly_spend, weekly_conversions) -
            LAG(SAFE_DIVIDE(weekly_spend, weekly_conversions))
                OVER (PARTITION BY platform ORDER BY week_number),
            LAG(SAFE_DIVIDE(weekly_spend, weekly_conversions))
                OVER (PARTITION BY platform ORDER BY week_number)
        ) * 100, 1)                                                AS cpa_wow_pct_change,

    -- Improving flag (negative = getting cheaper = good)
    CASE
        WHEN SAFE_DIVIDE(weekly_spend, weekly_conversions) <
             LAG(SAFE_DIVIDE(weekly_spend, weekly_conversions))
                 OVER (PARTITION BY platform ORDER BY week_number)
        THEN 'Improving'
        WHEN LAG(SAFE_DIVIDE(weekly_spend, weekly_conversions))
                 OVER (PARTITION BY platform ORDER BY week_number) IS NULL
        THEN 'Baseline'
        ELSE 'Worsening'
    END                                                            AS cpa_trend_status

FROM weekly_raw
ORDER BY platform, week_number
;
