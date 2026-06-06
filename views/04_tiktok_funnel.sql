/*
  view: tiktok_funnel
  ──────────────────────────────────────────────────────────────────
  Powers: TikTok Video Completion Funnel chart
          Shows how many viewers reach each watch checkpoint,
          revealing where the audience drops off.

  In Looker Studio:
    - Bar chart or Funnel chart
    - Dimension = funnel_stage (use Sort Order field)
    - Metric    = total_viewers
    - Add % labels using pct_of_views field
    - Filter: platform = TikTok (already pre-filtered in this view)

  Key insight from data:
    Only 26% of TikTok viewers watch to completion —
    front-load the CTA in the first 3 seconds.
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.tiktok_funnel` AS

WITH tiktok_totals AS (
    SELECT
        SUM(video_views)     AS total_video_views,
        SUM(video_watch_25)  AS total_watch_25,
        SUM(video_watch_50)  AS total_watch_50,
        SUM(video_watch_75)  AS total_watch_75,
        SUM(video_watch_100) AS total_watch_100,
        SUM(conversions)     AS total_conversions,
        SUM(spend)           AS total_spend
    FROM `improvado-assignment-498500.marketing_data.unified_ads`
    WHERE platform = 'TikTok'
),

funnel_stages AS (
    SELECT 1 AS sort_order, 'Video Views (Start)'   AS funnel_stage, total_video_views  AS viewers FROM tiktok_totals UNION ALL
    SELECT 2,               '25% Watched',            total_watch_25                               FROM tiktok_totals UNION ALL
    SELECT 3,               '50% Watched',            total_watch_50                               FROM tiktok_totals UNION ALL
    SELECT 4,               '75% Watched',            total_watch_75                               FROM tiktok_totals UNION ALL
    SELECT 5,               'Completed (100%)',        total_watch_100                              FROM tiktok_totals
)

SELECT
    sort_order,
    funnel_stage,
    viewers                                                         AS total_viewers,

    -- % relative to video views (top of funnel)
    ROUND(SAFE_DIVIDE(viewers,
        FIRST_VALUE(viewers) OVER (ORDER BY sort_order)) * 100, 1) AS pct_of_views,

    -- Drop-off from previous stage
    ROUND(SAFE_DIVIDE(
        LAG(viewers) OVER (ORDER BY sort_order) - viewers,
        LAG(viewers) OVER (ORDER BY sort_order)
    ) * 100, 1)                                                     AS dropoff_pct_from_prev_stage,

    -- Absolute drop from previous stage
    LAG(viewers) OVER (ORDER BY sort_order) - viewers              AS viewers_lost_from_prev_stage

FROM funnel_stages
ORDER BY sort_order
;
