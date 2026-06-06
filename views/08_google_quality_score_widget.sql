/*
  view: google_quality_score_widget
  ══════════════════════════════════════════════════════════════════
  GAP FILL #2 — Missing from dashboard
  ──────────────────────────────────────────────────────────────────
  Widget to add in Looker Studio:
    Type        : Bar chart (vertical or horizontal)
    Title       : GOOGLE QUALITY SCORE vs CTR
    Dimension   : quality_score_label
    Metric      : blended_ctr (format as %)
    Sort        : sort_order ASC (QS 6 → 7 → 8 → 9)
    Color field : qs_color_hex — use "Color by field" in style tab
    Secondary   : avg_cpa as secondary metric (right axis)

  Place next to TikTok funnel — right side, same row.

  Key insight visible in this widget:
    QS 9 → 5.21% CTR vs QS 7 → 1.09% CTR (4.8× difference).
    Every QS point gained is not equal — the 8→9 jump is biggest.
    Recommendation: improve ad relevance and landing page for
    low-QS ad groups to unlock the QS 9 performance tier.
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.google_quality_score_widget` AS

WITH qs_agg AS (
    SELECT
        CAST(quality_score AS INT64)                                        AS qs,
        COUNT(DISTINCT campaign_name)                                       AS campaigns,
        SUM(impressions)                                                    AS total_impressions,
        SUM(clicks)                                                         AS total_clicks,
        SUM(spend)                                                          AS total_spend,
        SUM(conversions)                                                    AS total_conversions
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    WHERE platform = 'Google'
      AND quality_score IS NOT NULL
    GROUP BY quality_score
)

SELECT
    qs                                                                       AS quality_score,
    CONCAT('QS ', CAST(qs AS STRING))                                       AS quality_score_label,
    qs                                                                       AS sort_order,
    campaigns,

    ROUND(SAFE_DIVIDE(total_clicks,       total_impressions), 4)            AS blended_ctr,
    ROUND(SAFE_DIVIDE(total_spend,        total_conversions), 2)            AS avg_cpa,
    ROUND(SAFE_DIVIDE(total_spend,        total_impressions) * 1000, 2)     AS avg_cpm,
    ROUND(SAFE_DIVIDE(total_conversions,  total_clicks), 4)                 AS avg_cpr,

    total_impressions,
    total_clicks,
    total_spend,
    total_conversions,

    -- Performance tier for color-coding in Looker Studio
    CASE
        WHEN qs >= 9 THEN 'Excellent'
        WHEN qs >= 8 THEN 'Good'
        WHEN qs >= 6 THEN 'Average'
        ELSE              'Poor'
    END                                                                     AS qs_tier,

    -- Hex colors matching dashboard palette
    CASE
        WHEN qs >= 9 THEN '#1e8449'   -- dark green
        WHEN qs >= 8 THEN '#27ae60'   -- green
        WHEN qs >= 6 THEN '#f39c12'   -- amber
        ELSE              '#c0392b'   -- red
    END                                                                     AS qs_color_hex,

    -- CTR index vs average (1.0 = average, >1 = better)
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(total_clicks, total_impressions),
            AVG(SAFE_DIVIDE(total_clicks, total_impressions)) OVER ()
        ), 2)                                                               AS ctr_index

FROM qs_agg
ORDER BY qs ASC
;
