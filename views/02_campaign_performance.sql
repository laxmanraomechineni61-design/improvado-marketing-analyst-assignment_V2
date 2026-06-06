/*
  view: campaign_performance
  ──────────────────────────────────────────────────────────────────
  Powers:
    1. Campaign Leaderboard table (sortable by CPA, CTR, Spend etc.)
    2. Scatter/Bubble chart  — CTR (x-axis) vs CPA (y-axis),
                               bubble size = spend
    3. Sankey / Flow chart   — Platform → Campaign → Spend

  In Looker Studio:
    - Table  : use all fields, sort by cpa ASC
    - Scatter: x = blended_ctr, y = blended_cpa, size = total_spend,
               color dimension = platform
    - Sankey : source = platform, target = campaign_name, value = total_spend
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.campaign_performance` AS

SELECT
    platform,
    campaign_id,
    campaign_name,

    -- Volume
    SUM(impressions)                                                AS total_impressions,
    SUM(clicks)                                                     AS total_clicks,
    SUM(spend)                                                      AS total_spend,
    SUM(conversions)                                                AS total_conversions,
    SUM(video_views)                                                AS total_video_views,

    -- Blended KPIs from aggregated totals (avoids averaging percentages)
    ROUND(SAFE_DIVIDE(SUM(clicks),       SUM(impressions)),    4)   AS blended_ctr,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(conversions)),    2)   AS blended_cpa,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(impressions)) * 1000, 2) AS blended_cpm,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(clicks)),         2)   AS blended_cpc,
    ROUND(SAFE_DIVIDE(SUM(conversions),  SUM(clicks)),         4)   AS conversion_rate,

    -- ROAS (Google only)
    ROUND(SAFE_DIVIDE(SUM(conversion_value), SUM(spend)), 2)        AS roas,

    -- Campaign's share of its platform total spend
    ROUND(
        SAFE_DIVIDE(SUM(spend),
            SUM(SUM(spend)) OVER (PARTITION BY platform)) * 100, 1) AS spend_share_within_platform_pct,

    -- CPA rank within platform (1 = most efficient)
    RANK() OVER (
        PARTITION BY platform
        ORDER BY SAFE_DIVIDE(SUM(spend), SUM(conversions)) ASC
    )                                                               AS cpa_rank_in_platform,

    -- CPA rank across all campaigns globally
    RANK() OVER (
        ORDER BY SAFE_DIVIDE(SUM(spend), SUM(conversions)) ASC
    )                                                               AS cpa_rank_global

FROM `improvado-assignment-498500.marketing_data.unified_ads`

GROUP BY platform, campaign_id, campaign_name
ORDER BY blended_cpa ASC
;
