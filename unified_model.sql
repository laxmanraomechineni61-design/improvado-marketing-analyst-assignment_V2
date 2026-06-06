/*
  unified_model.sql
  ─────────────────────────────────────────────────────────────────
  BASE TABLE — save as BigQuery table or view:
    improvado-assignment-498500.marketing_data.unified_ads

  Connects directly to Looker Studio as the single source of truth.
  All downstream views (platform_summary, campaign_performance,
  daily_trend, tiktok_funnel, quality_score_analysis) query this table.

  Source dataset : improvado-assignment-498500.marketing_data
  Period         : January 2024
  Output rows    : 330 (110 per platform)

  Normalization decisions:
  ─ "cost" (Google, TikTok)           → renamed to "spend"
  ─ "ad_set_id" (Facebook)            → renamed to "ad_group_id"
  ─ "adgroup_id" (TikTok)             → renamed to "ad_group_id"
  ─ CTR recalculated from raw clicks/impressions for cross-platform
    consistency (overrides Google's natively reported ctr value)
  ─ Platform-specific columns filled with NULL on other platforms
  ─ ROAS calculated where conversion_value exists (Google only)
  ─ video_completion_rate calculated for TikTok only
*/

CREATE OR REPLACE VIEW `improvado-assignment-498500.marketing_data.unified_ads` AS

WITH facebook AS (

    SELECT
        date,
        'Facebook'                                          AS platform,
        campaign_id,
        campaign_name,
        ad_set_id                                           AS ad_group_id,
        ad_set_name                                         AS ad_group_name,
        SAFE_CAST(impressions   AS INT64)                   AS impressions,
        SAFE_CAST(clicks        AS INT64)                   AS clicks,
        SAFE_CAST(spend         AS NUMERIC)                 AS spend,
        SAFE_CAST(conversions   AS INT64)                   AS conversions,
        SAFE_CAST(video_views   AS INT64)                   AS video_views,

        -- Core KPIs (recalculated from raw for cross-platform consistency)
        SAFE_DIVIDE(clicks, impressions)                    AS ctr,
        SAFE_DIVIDE(spend, conversions)                     AS cpa,
        SAFE_DIVIDE(spend, impressions) * 1000              AS cpm,
        SAFE_DIVIDE(spend, clicks)                          AS cpc,
        SAFE_DIVIDE(conversions, clicks)                    AS conversion_rate,
        CAST(NULL AS NUMERIC)                               AS roas,               -- no conversion_value on Facebook
        CAST(NULL AS NUMERIC)                               AS video_completion_rate,

        -- Facebook-only
        SAFE_CAST(engagement_rate   AS NUMERIC)             AS engagement_rate,
        SAFE_CAST(reach             AS INT64)               AS reach,
        SAFE_CAST(frequency         AS NUMERIC)             AS frequency,

        -- Google-only → NULL
        CAST(NULL AS NUMERIC)                               AS conversion_value,
        CAST(NULL AS NUMERIC)                               AS avg_cpc,
        CAST(NULL AS INT64)                                 AS quality_score,
        CAST(NULL AS NUMERIC)                               AS search_impression_share,

        -- TikTok-only → NULL
        CAST(NULL AS INT64)                                 AS video_watch_25,
        CAST(NULL AS INT64)                                 AS video_watch_50,
        CAST(NULL AS INT64)                                 AS video_watch_75,
        CAST(NULL AS INT64)                                 AS video_watch_100,
        CAST(NULL AS INT64)                                 AS likes,
        CAST(NULL AS INT64)                                 AS shares,
        CAST(NULL AS INT64)                                 AS comments,
        CAST(NULL AS INT64)                                 AS total_engagements

    FROM `improvado-assignment-498500.marketing_data.facebook_ads`

),

google AS (

    SELECT
        date,
        'Google'                                            AS platform,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,
        SAFE_CAST(impressions   AS INT64)                   AS impressions,
        SAFE_CAST(clicks        AS INT64)                   AS clicks,
        SAFE_CAST(cost          AS NUMERIC)                 AS spend,
        SAFE_CAST(conversions   AS INT64)                   AS conversions,
        CAST(NULL AS INT64)                                 AS video_views,

        SAFE_DIVIDE(clicks, impressions)                    AS ctr,
        SAFE_DIVIDE(cost, conversions)                      AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000               AS cpm,
        SAFE_DIVIDE(cost, clicks)                           AS cpc,
        SAFE_DIVIDE(conversions, clicks)                    AS conversion_rate,
        -- ROAS only meaningful for Google where conversion_value exists
        SAFE_DIVIDE(SAFE_CAST(conversion_value AS NUMERIC),
                    SAFE_CAST(cost AS NUMERIC))             AS roas,
        CAST(NULL AS NUMERIC)                               AS video_completion_rate,

        -- Facebook-only → NULL
        CAST(NULL AS NUMERIC)                               AS engagement_rate,
        CAST(NULL AS INT64)                                 AS reach,
        CAST(NULL AS NUMERIC)                               AS frequency,

        -- Google-only
        SAFE_CAST(conversion_value          AS NUMERIC)     AS conversion_value,
        SAFE_CAST(avg_cpc                   AS NUMERIC)     AS avg_cpc,
        SAFE_CAST(quality_score             AS INT64)       AS quality_score,
        SAFE_CAST(search_impression_share   AS NUMERIC)     AS search_impression_share,

        -- TikTok-only → NULL
        CAST(NULL AS INT64)                                 AS video_watch_25,
        CAST(NULL AS INT64)                                 AS video_watch_50,
        CAST(NULL AS INT64)                                 AS video_watch_75,
        CAST(NULL AS INT64)                                 AS video_watch_100,
        CAST(NULL AS INT64)                                 AS likes,
        CAST(NULL AS INT64)                                 AS shares,
        CAST(NULL AS INT64)                                 AS comments,
        CAST(NULL AS INT64)                                 AS total_engagements

    FROM `improvado-assignment-498500.marketing_data.google_ads`

),

tiktok AS (

    SELECT
        date,
        'TikTok'                                            AS platform,
        campaign_id,
        campaign_name,
        adgroup_id                                          AS ad_group_id,
        adgroup_name                                        AS ad_group_name,
        SAFE_CAST(impressions   AS INT64)                   AS impressions,
        SAFE_CAST(clicks        AS INT64)                   AS clicks,
        SAFE_CAST(cost          AS NUMERIC)                 AS spend,
        SAFE_CAST(conversions   AS INT64)                   AS conversions,
        SAFE_CAST(video_views   AS INT64)                   AS video_views,

        SAFE_DIVIDE(clicks, impressions)                    AS ctr,
        SAFE_DIVIDE(cost, conversions)                      AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000               AS cpm,
        SAFE_DIVIDE(cost, clicks)                           AS cpc,
        SAFE_DIVIDE(conversions, clicks)                    AS conversion_rate,
        CAST(NULL AS NUMERIC)                               AS roas,
        -- % of people who started the video and watched to the end
        SAFE_DIVIDE(SAFE_CAST(video_watch_100 AS NUMERIC),
                    SAFE_CAST(video_views AS NUMERIC))      AS video_completion_rate,

        -- Facebook-only → NULL
        CAST(NULL AS NUMERIC)                               AS engagement_rate,
        CAST(NULL AS INT64)                                 AS reach,
        CAST(NULL AS NUMERIC)                               AS frequency,

        -- Google-only → NULL
        CAST(NULL AS NUMERIC)                               AS conversion_value,
        CAST(NULL AS NUMERIC)                               AS avg_cpc,
        CAST(NULL AS INT64)                                 AS quality_score,
        CAST(NULL AS NUMERIC)                               AS search_impression_share,

        -- TikTok video completion funnel
        SAFE_CAST(video_watch_25    AS INT64)               AS video_watch_25,
        SAFE_CAST(video_watch_50    AS INT64)               AS video_watch_50,
        SAFE_CAST(video_watch_75    AS INT64)               AS video_watch_75,
        SAFE_CAST(video_watch_100   AS INT64)               AS video_watch_100,
        SAFE_CAST(likes             AS INT64)               AS likes,
        SAFE_CAST(shares            AS INT64)               AS shares,
        SAFE_CAST(comments          AS INT64)               AS comments,
        SAFE_CAST(likes AS INT64)
          + SAFE_CAST(shares AS INT64)
          + SAFE_CAST(comments AS INT64)                    AS total_engagements

    FROM `improvado-assignment-498500.marketing_data.tiktok_ads`

)

-- UNION ALL: rows are guaranteed distinct across platforms — no dedup needed
SELECT * FROM facebook
UNION ALL
SELECT * FROM google
UNION ALL
SELECT * FROM tiktok

ORDER BY date, platform, campaign_id
;
