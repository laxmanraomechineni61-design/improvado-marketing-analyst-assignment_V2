/*
  view: efficiency_scorecard_widget
  ══════════════════════════════════════════════════════════════════
  GAP FILL #4 — Missing from dashboard
  ──────────────────────────────────────────────────────────────────
  Their dashboard has platform KPI tiles but no efficiency comparison.
  This view powers two widgets:

  Widget A — BUDGET vs CONVERSION SHARE (Donut pair)
    Type        : 2 × Donut / Pie chart side by side
    Left donut  : dimension = platform, metric = budget_share_pct
                  title = BUDGET SPLIT
    Right donut : dimension = platform, metric = conversion_share_pct
                  title = CONVERSION SPLIT
    Colors      : Facebook = #1877f2, Google = #6f42c1, TikTok = #212121
    Place       : next to or below the CONVERSIONS donut already on dashboard

  Widget B — EFFICIENCY SCORECARD (Scorecard per platform)
    Type        : 3 Scorecards in a row
    Metric      : efficiency_index
    Label       : efficiency_label
    Green if    : efficiency_index > 1.0
    Red if      : efficiency_index < 1.0

  Key insight:
    Facebook efficiency_index = 1.28 → over-delivers by 28%
    Google   efficiency_index = 1.09 → over-delivers by 9%
    TikTok   efficiency_index = 0.89 → under-delivers by 11%
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.efficiency_scorecard_widget` AS

WITH platform_agg AS (
    SELECT
        platform,
        SUM(spend)       AS platform_spend,
        SUM(conversions) AS platform_conversions,
        SUM(clicks)      AS platform_clicks,
        SUM(impressions) AS platform_impressions
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    GROUP BY platform
),

totals AS (
    SELECT
        SUM(platform_spend)       AS grand_spend,
        SUM(platform_conversions) AS grand_conversions
    FROM platform_agg
)

SELECT
    p.platform,

    -- Raw numbers
    ROUND(p.platform_spend, 2)                                          AS total_spend,
    p.platform_conversions                                              AS total_conversions,
    p.platform_clicks                                                   AS total_clicks,
    p.platform_impressions                                              AS total_impressions,

    -- Share metrics for donut charts
    ROUND(SAFE_DIVIDE(p.platform_spend,       t.grand_spend)       * 100, 1)  AS budget_share_pct,
    ROUND(SAFE_DIVIDE(p.platform_conversions, t.grand_conversions) * 100, 1)  AS conversion_share_pct,

    -- KPIs
    ROUND(SAFE_DIVIDE(p.platform_spend,       p.platform_conversions), 2)     AS blended_cpa,
    ROUND(SAFE_DIVIDE(p.platform_spend,       p.platform_impressions) * 1000, 2) AS blended_cpm,
    ROUND(SAFE_DIVIDE(p.platform_clicks,      p.platform_impressions), 4)     AS blended_ctr,
    ROUND(SAFE_DIVIDE(p.platform_conversions, p.platform_clicks),      4)     AS blended_cpr,

    -- Efficiency index: >1.0 = over-delivering vs budget share
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(p.platform_conversions, t.grand_conversions),
            SAFE_DIVIDE(p.platform_spend,       t.grand_spend)
        ), 2)                                                                  AS efficiency_index,

    -- Human-readable label for scorecard widget
    CASE
        WHEN SAFE_DIVIDE(
                SAFE_DIVIDE(p.platform_conversions, t.grand_conversions),
                SAFE_DIVIDE(p.platform_spend, t.grand_spend)) > 1.0
        THEN 'Over-delivering ✓'
        ELSE 'Under-delivering ✗'
    END                                                                        AS efficiency_label,

    -- Potential extra conversions if budget were reallocated to match Facebook efficiency
    ROUND(
        p.platform_spend / SAFE_DIVIDE(
            (SELECT platform_spend FROM platform_agg WHERE platform = 'Facebook'),
            (SELECT platform_conversions FROM platform_agg WHERE platform = 'Facebook')
        ) - p.platform_conversions, 0)                                        AS conversions_gap_vs_facebook

FROM platform_agg p
CROSS JOIN totals t
ORDER BY efficiency_index DESC
;
