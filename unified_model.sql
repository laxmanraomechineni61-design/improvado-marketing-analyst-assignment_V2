-- this query is for combining all 3 platform data into one table
-- facebook, google and tiktok data is there for january 2024
-- i am using bigquery standard sql for this
-- will use this unified table in looker studio for dashboard

-- some things i noticed in data and handled:
--   facebook is using "spend" column but google and tiktok using "cost" so i made it same as spend
--   facebook calling it ad_set_id, google is ad_group_id, tiktok is adgroup_id.. all different so normalized to ad_group_id
--   some columns are only in one platform like quality_score is only google, likes/shares only tiktok etc
--   for those columns i put NULL in other platforms, that way structure is same for all
--   calculated ctr, cpa, cpm in the query itself so dont have to do it in dashboard

WITH facebook AS (

    SELECT
        date,
        'Facebook'                          AS platform,
        campaign_id,
        campaign_name,
        ad_set_id                           AS ad_group_id,      -- facebook calls it ad_set_id, making it same name
        ad_set_name                         AS ad_group_name,
        impressions,
        clicks,
        spend,                                                    -- facebook already has spend column, no change needed
        conversions,
        video_views,

        -- these metrics i calculated here only
        SAFE_DIVIDE(clicks, impressions)            AS ctr,       -- clicks divided by impressions
        SAFE_DIVIDE(spend, conversions)             AS cpa,       -- how much we spending per conversion
        SAFE_DIVIDE(spend, impressions) * 1000      AS cpm,       -- cost per 1000 impressions

        -- only facebook has these columns
        engagement_rate,
        reach,
        frequency,

        -- google columns not there in facebook so putting null
        NULL                                AS conversion_value,
        NULL                                AS avg_cpc,
        NULL                                AS quality_score,
        NULL                                AS search_impression_share,

        -- tiktok columns also not in facebook
        NULL                                AS video_watch_25,
        NULL                                AS video_watch_50,
        NULL                                AS video_watch_75,
        NULL                                AS video_watch_100,
        NULL                                AS likes,
        NULL                                AS shares,
        NULL                                AS comments

    FROM `improvado-assignment-498500.marketing_data.facebook_ads`

),

google AS (

    SELECT
        date,
        'Google'                            AS platform,
        campaign_id,
        campaign_name,
        ad_group_id,                                             -- google already has this name so no change
        ad_group_name,
        impressions,
        clicks,
        cost                                AS spend,            -- google calls it cost, changing to spend
        conversions,
        NULL                                AS video_views,      -- google search and shopping dont have video views

        -- same metrics calculated
        SAFE_DIVIDE(clicks, impressions)            AS ctr,
        SAFE_DIVIDE(cost, conversions)              AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000       AS cpm,

        -- facebook columns not there in google
        NULL                                AS engagement_rate,
        NULL                                AS reach,
        NULL                                AS frequency,

        -- only google has these columns
        conversion_value,
        avg_cpc,
        quality_score,                                           -- this is useful for search campaigns
        search_impression_share,

        -- tiktok columns not in google
        NULL                                AS video_watch_25,
        NULL                                AS video_watch_50,
        NULL                                AS video_watch_75,
        NULL                                AS video_watch_100,
        NULL                                AS likes,
        NULL                                AS shares,
        NULL                                AS comments

    FROM `improvado-assignment-498500.marketing_data.google_ads`

),

tiktok AS (

    SELECT
        date,
        'TikTok'                            AS platform,
        campaign_id,
        campaign_name,
        adgroup_id                          AS ad_group_id,      -- tiktok calling it adgroup_id, normalizing
        adgroup_name                        AS ad_group_name,
        impressions,
        clicks,
        cost                                AS spend,            -- tiktok also using cost, changing to spend
        conversions,
        video_views,

        -- same metrics
        SAFE_DIVIDE(clicks, impressions)            AS ctr,
        SAFE_DIVIDE(cost, conversions)              AS cpa,
        SAFE_DIVIDE(cost, impressions) * 1000       AS cpm,

        -- facebook columns not in tiktok
        NULL                                AS engagement_rate,
        NULL                                AS reach,
        NULL                                AS frequency,

        -- google columns not in tiktok
        NULL                                AS conversion_value,
        NULL                                AS avg_cpc,
        NULL                                AS quality_score,
        NULL                                AS search_impression_share,

        -- tiktok has video engagement data which other platforms dont have
        video_watch_25,                                          -- how many people watched 25% of video
        video_watch_50,
        video_watch_75,
        video_watch_100,                                         -- completed views
        likes,
        shares,
        comments

    FROM `improvado-assignment-498500.marketing_data.tiktok_ads`

)

-- union all 3 platforms together
-- using union all not union because we dont want to remove duplicates
SELECT * FROM facebook
UNION ALL
SELECT * FROM google
UNION ALL
SELECT * FROM tiktok

ORDER BY date, platform, campaign_id
;
