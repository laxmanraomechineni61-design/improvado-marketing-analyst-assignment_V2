/*
  view: platform_summary
  ──────────────────────────────────────────────────────────────────
  Powers: Per-platform KPI cards (Facebook / Google / TikTok blocks)
          in Looker Studio — the colored tiles showing spend, CPA,
          CPM, CTR per platform.

  Connect in Looker Studio as a separate data source, use platform
  as a dimension and all KPI fields as metrics.
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.platform_summary` AS

SELECT
    platform,

    -- Volume metrics
    SUM(impressions)                                            AS total_impressions,
    SUM(clicks)                                                 AS total_clicks,
    SUM(spend)                                                  AS total_spend,
    SUM(conversions)                                            AS total_conversions,
    SUM(video_views)                                            AS total_video_views,

    -- Blended KPIs (calculated from totals — not average of row-level rates)
    ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 4)        AS blended_ctr,
    ROUND(SAFE_DIVIDE(SUM(spend), SUM(conversions)), 2)         AS blended_cpa,
    ROUND(SAFE_DIVIDE(SUM(spend), SUM(impressions)) * 1000, 2)  AS blended_cpm,
    ROUND(SAFE_DIVIDE(SUM(spend), SUM(clicks)), 2)              AS blended_cpc,
    ROUND(SAFE_DIVIDE(SUM(conversions), SUM(clicks)), 4)        AS blended_cvr,

    -- Budget share (% of total cross-platform spend)
    ROUND(
        SAFE_DIVIDE(SUM(spend),
            SUM(SUM(spend)) OVER ()) * 100, 1)                 AS budget_share_pct,

    -- Conversion share (% of total cross-platform conversions)
    ROUND(
        SAFE_DIVIDE(SUM(conversions),
            SUM(SUM(conversions)) OVER ()) * 100, 1)           AS conversion_share_pct,

    -- Efficiency index: conversion share / budget share
    -- > 1.0 = over-delivering, < 1.0 = under-delivering
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(SUM(conversions), SUM(SUM(conversions)) OVER ()),
            SAFE_DIVIDE(SUM(spend),       SUM(SUM(spend))       OVER ())
        ), 2)                                                   AS efficiency_index,

    -- ROAS (Google only — NULL for others)
    ROUND(SAFE_DIVIDE(SUM(conversion_value), SUM(spend)), 2)    AS roas,

    -- TikTok video completion (NULL for Facebook/Google)
    ROUND(SAFE_DIVIDE(SUM(video_watch_100), SUM(video_views)), 3) AS avg_video_completion_rate

FROM `improvado-assignment-498500.marketing_data.unified_ads`

GROUP BY platform
ORDER BY total_spend DESC
;
