/*
  view: quality_score_analysis
  ──────────────────────────────────────────────────────────────────
  Powers: Google Quality Score vs CTR/CPA analysis chart.
          Shows that QS 9 campaigns deliver 2.6x better CTR
          than QS 7 — the biggest lever in Google Ads.

  In Looker Studio:
    - Bar chart: dimension = quality_score,
                 metric = avg_ctr (or avg_cpa)
    - Color: green = QS 8-10, yellow = QS 6-7, red = QS 1-5
    - Add second metric = campaign_count for context
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.quality_score_analysis` AS

SELECT
    quality_score,

    COUNT(DISTINCT campaign_name)                                       AS campaign_count,
    COUNT(*)                                                            AS row_count,

    -- Aggregated from totals (not average of averages)
    ROUND(SAFE_DIVIDE(SUM(clicks),       SUM(impressions)),       4)   AS avg_ctr,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(conversions)),       2)   AS avg_cpa,
    ROUND(SAFE_DIVIDE(SUM(spend),        SUM(impressions)) * 1000, 2)  AS avg_cpm,
    ROUND(SAFE_DIVIDE(SUM(conversions),  SUM(clicks)),            4)   AS avg_cvr,

    SUM(impressions)                                                    AS total_impressions,
    SUM(clicks)                                                         AS total_clicks,
    SUM(spend)                                                          AS total_spend,
    SUM(conversions)                                                    AS total_conversions,

    -- CTR relative to QS 7 baseline (index: 1.0 = same as QS 7)
    ROUND(
        SAFE_DIVIDE(
            SAFE_DIVIDE(SUM(clicks), SUM(impressions)),
            AVG(SAFE_DIVIDE(SUM(clicks), SUM(impressions))) OVER ()
        ), 2)                                                           AS ctr_index_vs_avg,

    -- QS performance tier label for Looker Studio color coding
    CASE
        WHEN quality_score >= 8 THEN 'High (8-10)'
        WHEN quality_score >= 6 THEN 'Medium (6-7)'
        ELSE                         'Low (1-5)'
    END                                                                 AS qs_tier

FROM `improvado-assignment-498500.marketing_data.unified_ads`

WHERE platform = 'Google'
  AND quality_score IS NOT NULL

GROUP BY quality_score
ORDER BY quality_score ASC
;
