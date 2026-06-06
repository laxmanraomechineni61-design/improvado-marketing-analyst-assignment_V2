/*
  view: daily_trend
  ──────────────────────────────────────────────────────────────────
  Powers:
    1. "Platforms Spending Overtime" line chart — daily spend per
       platform across Jan 1–31
    2. Daily CPA/CTR trend lines — for executive performance tracking

  In Looker Studio:
    - Line chart: dimension = date, metric = daily_spend,
                  breakdown dimension = platform
    - Add date range filter → auto-responds to date picker
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.daily_trend` AS

SELECT
    date,
    platform,

    -- Daily volume
    SUM(impressions)                                                AS daily_impressions,
    SUM(clicks)                                                     AS daily_clicks,
    SUM(spend)                                                      AS daily_spend,
    SUM(conversions)                                                AS daily_conversions,
    SUM(video_views)                                                AS daily_video_views,

    -- Daily KPIs
    ROUND(SAFE_DIVIDE(SUM(clicks),       SUM(impressions)),    4)   AS daily_ctr,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(conversions)),    2)   AS daily_cpa,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(impressions)) * 1000, 2) AS daily_cpm,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(clicks)),         2)   AS daily_cpc,
    ROUND(SAFE_DIVIDE(SUM(conversions),  SUM(clicks)),         4)   AS daily_cvr,

    -- 7-day rolling average CPA (smooths daily noise)
    ROUND(
        AVG(SAFE_DIVIDE(SUM(spend), SUM(conversions))) OVER (
            PARTITION BY platform
            ORDER BY date
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2)                                                       AS cpa_7day_rolling_avg,

    -- Day-over-day spend change
    SUM(spend) - LAG(SUM(spend)) OVER (
        PARTITION BY platform ORDER BY date
    )                                                               AS spend_dod_change,

    -- Week number (1–5) for weekly aggregation in Looker Studio
    CAST(CEIL(EXTRACT(DAY FROM date) / 7.0) AS INT64)              AS week_number

FROM `improvado-assignment-498500.marketing_data.unified_ads`

GROUP BY date, platform
ORDER BY date, platform
;
