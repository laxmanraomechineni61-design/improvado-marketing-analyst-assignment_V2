/*
  unified_model.sql
  -----------------
  Combines Facebook, Google Ads, and TikTok into one normalized table
  for cross-channel performance analysis in Looker Studio.

  Source dataset : improvado-assignment-498500.marketing_data
  Period         : January 2024
  Output rows    : 330 (110 per platform)

  Normalization decisions:
  - "cost" (Google, TikTok) → renamed to "spend" to match Facebook
  - "ad_set_id" (Facebook), "adgroup_id" (TikTok) → renamed to "ad_group_id"
  - CTR recalculated from raw clicks/impressions across all platforms
    (overrides Google's natively reported ctr for cross-platform consistency)
  - Platform-specific columns filled with NULL on other platforms so every
    row shares the same 28-column schema
*/

WITH facebook AS (

    SELECT
        date,
        'Facebook'                              AS platform,
        campaign_id,
        campaign_name,
        ad_set_id                               AS ad_group_id,
        ad_set_name                             AS ad_group_name,
        impressions,
        clicks,
        spend,
        conversions,
        video_views,

        SAFE_DIVIDE(clicks, impressions)        AS ctr,
        SAFE_DIVIDE(spend, conversions)         AS cpa,
        SAFE_DIVIDE(spend, impressions) * 1000  AS cpm,

        -- Facebook-only engagement metrics
        engagement_rate,
        reach,
        frequency,

        -- Google-only columns → NULL for Facebook
        NULL AS conversion_value,
        NULL AS avg_cpc,
        NULL AS quality_score,
        NULL AS search_impression_share,

        -- TikTok-only columns → NULL for Facebook
        NULL AS video_watch_25,
        NULL AS video_watch_50,
        NULL AS video_watch_75,
        NULL AS video_watch_100,
        NULL AS likes,
        NULL AS shares,
        NULL AS comments

    FROM `improvado-assignment-498500.marketing_data.facebook_ads`

),

google AS (

    SELECT
        date,
        'Google'                                AS platform,
        campaign_id,
        campaign_name,
        ad_group_id,
        ad_group_name,
        impressions,
        clicks,
        cost                                    AS spend,
        conversions,
        NULL                                    AS video_views,

        -- Recalculated for consistency; Google's native ctr column is not carried forward
        SAFE_DIVIDE(clicks, impressions)        AS ctr,
        SAFE_DIVIDE(cost, conversions)          AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000   AS cpm,

        -- Facebook-only columns → NULL for Google
        NULL AS engagement_rate,
        NULL AS reach,
        NULL AS frequency,

        -- Google-only metrics
        conversion_value,
        avg_cpc,
        quality_score,
        search_impression_share,

        -- TikTok-only columns → NULL for Google
        NULL AS video_watch_25,
        NULL AS video_watch_50,
        NULL AS video_watch_75,
        NULL AS video_watch_100,
        NULL AS likes,
        NULL AS shares,
        NULL AS comments

    FROM `improvado-assignment-498500.marketing_data.google_ads`

),

tiktok AS (

    SELECT
        date,
        'TikTok'                                AS platform,
        campaign_id,
        campaign_name,
        adgroup_id                              AS ad_group_id,
        adgroup_name                            AS ad_group_name,
        impressions,
        clicks,
        cost                                    AS spend,
        conversions,
        video_views,

        SAFE_DIVIDE(clicks, impressions)        AS ctr,
        SAFE_DIVIDE(cost, conversions)          AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000   AS cpm,

        -- Facebook-only columns → NULL for TikTok
        NULL AS engagement_rate,
        NULL AS reach,
        NULL AS frequency,

        -- Google-only columns → NULL for TikTok
        NULL AS conversion_value,
        NULL AS avg_cpc,
        NULL AS quality_score,
        NULL AS search_impression_share,

        -- TikTok video completion funnel
        video_watch_25,
        video_watch_50,
        video_watch_75,
        video_watch_100,
        likes,
        shares,
        comments

    FROM `improvado-assignment-498500.marketing_data.tiktok_ads`

)

-- UNION ALL (not UNION) because rows are guaranteed distinct across platforms
SELECT * FROM facebook
UNION ALL
SELECT * FROM google
UNION ALL
SELECT * FROM tiktok

ORDER BY date, platform, campaign_id
;
