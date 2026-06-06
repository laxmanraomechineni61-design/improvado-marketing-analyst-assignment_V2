/*
  view: budget_vs_conversion
  ──────────────────────────────────────────────────────────────────
  Powers: Budget vs Conversion Share donut/comparison chart.
          The most important strategic insight: Facebook over-delivers
          (17.9% conversions on 14% budget), TikTok under-delivers
          (50.5% conversions on 57% budget).

  In Looker Studio:
    - Pie / Donut chart 1: dimension = platform, metric = budget_share_pct
    - Pie / Donut chart 2: dimension = platform, metric = conversion_share_pct
    - Scorecard: efficiency_index (>1 = good, <1 = bad)
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.budget_vs_conversion` AS

WITH platform_totals AS (
    SELECT
        platform,
        SUM(spend)       AS platform_spend,
        SUM(conversions) AS platform_conversions
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    GROUP BY platform
),

grand_totals AS (
    SELECT
        SUM(platform_spend)       AS grand_spend,
        SUM(platform_conversions) AS grand_conversions
    FROM platform_totals
)

SELECT
    p.platform,
    ROUND(p.platform_spend, 2)                                          AS total_spend,
    p.platform_conversions                                              AS total_conversions,

    -- Share of total budget
    ROUND(SAFE_DIVIDE(p.platform_spend, g.grand_spend) * 100, 1)       AS budget_share_pct,

    -- Share of total conversions
    ROUND(SAFE_DIVIDE(p.platform_conversions, g.grand_conversions) * 100, 1) AS conversion_share_pct,

    -- Efficiency index > 1.0 means platform over-delivers vs its budget share
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(p.platform_conversions, g.grand_conversions),
            SAFE_DIVIDE(p.platform_spend,       g.grand_spend)
        ), 2)                                                           AS efficiency_index,

    -- Plain label for dashboard callouts
    CASE
        WHEN SAFE_DIVIDE(p.platform_conversions, g.grand_conversions) >
             SAFE_DIVIDE(p.platform_spend,       g.grand_spend)
        THEN 'Over-delivering'
        ELSE 'Under-delivering'
    END                                                                 AS efficiency_label,

    ROUND(SAFE_DIVIDE(p.platform_spend, p.platform_conversions), 2)    AS blended_cpa

FROM platform_totals p
CROSS JOIN grand_totals g
ORDER BY budget_share_pct DESC
;
