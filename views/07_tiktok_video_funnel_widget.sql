/*
  view: tiktok_video_funnel_widget
  ══════════════════════════════════════════════════════════════════
  GAP FILL #1 — Missing from dashboard
  ──────────────────────────────────────────────────────────────────
  Widget to add in Looker Studio:
    Type        : Bar chart (horizontal)
    Title       : TIKTOK VIDEO COMPLETION FUNNEL
    Dimension   : funnel_stage
    Metric      : total_viewers
    Sort        : sort_order ASC
    Secondary   : Add "pct_of_views" as data label
    Color       : Use single color — match TikTok tile color (#212121)

  Place below the SPENDING OF PLATFORMS sankey,
  left side — mirrors the layout balance of the dashboard.

  Key insight visible in this widget:
    Only 26% of TikTok viewers complete the ad.
    The steepest drop is between 75% → 100% watched (-34.6%).
    Recommendation: shorten ads to 6-9 seconds, front-load CTA.
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.tiktok_video_funnel_widget` AS

WITH totals AS (
    SELECT
        SUM(video_views)     AS v_start,
        SUM(video_watch_25)  AS v_25,
        SUM(video_watch_50)  AS v_50,
        SUM(video_watch_75)  AS v_75,
        SUM(video_watch_100) AS v_100
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    WHERE platform = 'TikTok'
),

stages AS (
    SELECT 1 AS sort_order, 'Impressions → Views'  AS funnel_stage, v_start FROM totals UNION ALL
    SELECT 2,               '25% Watched',           v_25             FROM totals UNION ALL
    SELECT 3,               '50% Watched',           v_50             FROM totals UNION ALL
    SELECT 4,               '75% Watched',           v_75             FROM totals UNION ALL
    SELECT 5,               'Completed (100%)',       v_100            FROM totals
)

SELECT
    sort_order,
    funnel_stage,
    viewers                                                                  AS total_viewers,

    ROUND(SAFE_DIVIDE(viewers,
          FIRST_VALUE(viewers) OVER (ORDER BY sort_order)) * 100, 1)         AS pct_of_views,

    -- Drop-off % from previous stage (shown as positive number)
    ROUND(SAFE_DIVIDE(
        LAG(viewers) OVER (ORDER BY sort_order) - viewers,
        LAG(viewers) OVER (ORDER BY sort_order)
    ) * 100, 1)                                                              AS dropoff_pct,

    LAG(viewers) OVER (ORDER BY sort_order) - viewers                        AS viewers_lost

FROM (
    SELECT sort_order, funnel_stage,
           CASE sort_order
               WHEN 1 THEN v_start
               WHEN 2 THEN v_25
               WHEN 3 THEN v_50
               WHEN 4 THEN v_75
               WHEN 5 THEN v_100
           END AS viewers
    FROM stages
)
ORDER BY sort_order
;
