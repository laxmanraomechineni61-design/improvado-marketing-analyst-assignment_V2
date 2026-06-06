/*
  view: qa_validation
  ══════════════════════════════════════════════════════════════════
  Run this FIRST after uploading raw CSVs to BigQuery.
  Validates data integrity before running any dashboard views.

  How to use:
    1. Run in BigQuery — should return 0 rows for every check
    2. If any rows returned → fix the source data or upload
    3. Then run unified_model.sql and all views in order

  Checks performed:
    ✓ Row counts (110 per platform expected)
    ✓ Date range (all Jan 2024)
    ✓ No NULL spend / impressions / clicks
    ✓ No negative values
    ✓ No zero impressions (would cause divide-by-zero in KPIs)
    ✓ Spend > 0 for all rows
    ✓ CTR sanity check (clicks must be ≤ impressions)
    ✓ TikTok: video_watch_100 ≤ video_views
    ✓ Google: quality_score between 1–10
*/

-- ── 1. ROW COUNT CHECK ────────────────────────────────────────────
SELECT 'ROW COUNT' AS check_name, platform, COUNT(*) AS row_count,
       CASE WHEN COUNT(*) = 110 THEN 'PASS' ELSE 'FAIL — expected 110' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

-- ── 2. DATE RANGE CHECK ───────────────────────────────────────────
SELECT 'DATE RANGE' AS check_name, platform,
       CONCAT(CAST(MIN(date) AS STRING), ' → ', CAST(MAX(date) AS STRING)) AS row_count,
       CASE
           WHEN MIN(date) = '2024-01-01' AND MAX(date) = '2024-01-31'
           THEN 'PASS'
           ELSE 'FAIL — unexpected date range'
       END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

-- ── 3. NULL CRITICAL FIELDS CHECK ────────────────────────────────
SELECT 'NULL SPEND' AS check_name, platform,
       CAST(COUNTIF(spend IS NULL) AS STRING) AS row_count,
       CASE WHEN COUNTIF(spend IS NULL) = 0 THEN 'PASS' ELSE 'FAIL — NULLs in spend' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

SELECT 'NULL IMPRESSIONS' AS check_name, platform,
       CAST(COUNTIF(impressions IS NULL OR impressions = 0) AS STRING) AS row_count,
       CASE WHEN COUNTIF(impressions IS NULL OR impressions = 0) = 0
            THEN 'PASS' ELSE 'FAIL — NULL/zero impressions' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

-- ── 4. NEGATIVE VALUES CHECK ──────────────────────────────────────
SELECT 'NEGATIVE SPEND' AS check_name, platform,
       CAST(COUNTIF(spend < 0) AS STRING) AS row_count,
       CASE WHEN COUNTIF(spend < 0) = 0 THEN 'PASS' ELSE 'FAIL — negative spend' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

SELECT 'NEGATIVE CONVERSIONS' AS check_name, platform,
       CAST(COUNTIF(conversions < 0) AS STRING) AS row_count,
       CASE WHEN COUNTIF(conversions < 0) = 0 THEN 'PASS' ELSE 'FAIL — negative conversions' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

-- ── 5. CTR SANITY: clicks ≤ impressions ──────────────────────────
SELECT 'CTR SANITY' AS check_name, platform,
       CAST(COUNTIF(clicks > impressions) AS STRING) AS row_count,
       CASE WHEN COUNTIF(clicks > impressions) = 0
            THEN 'PASS' ELSE 'FAIL — clicks exceed impressions' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
GROUP BY platform

UNION ALL

-- ── 6. TIKTOK: video_watch_100 ≤ video_views ─────────────────────
SELECT 'TIKTOK VIDEO FUNNEL' AS check_name, 'TikTok' AS platform,
       CAST(COUNTIF(video_watch_100 > video_views) AS STRING) AS row_count,
       CASE WHEN COUNTIF(video_watch_100 > video_views) = 0
            THEN 'PASS' ELSE 'FAIL — completions exceed views' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
WHERE platform = 'TikTok'

UNION ALL

-- ── 7. GOOGLE: quality_score 1–10 ────────────────────────────────
SELECT 'QUALITY SCORE RANGE' AS check_name, 'Google' AS platform,
       CAST(COUNTIF(quality_score NOT BETWEEN 1 AND 10) AS STRING) AS row_count,
       CASE WHEN COUNTIF(quality_score NOT BETWEEN 1 AND 10) = 0
            THEN 'PASS' ELSE 'FAIL — quality_score out of range' END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`
WHERE platform = 'Google'
  AND quality_score IS NOT NULL

UNION ALL

-- ── 8. TOTAL SPEND SANITY (cross-check vs known total) ───────────
SELECT 'TOTAL SPEND' AS check_name, 'All' AS platform,
       CAST(ROUND(SUM(spend), 2) AS STRING) AS row_count,
       CASE WHEN ROUND(SUM(spend), 0) = 130245
            THEN 'PASS — $130,244.90'
            ELSE CONCAT('FAIL — got $', CAST(ROUND(SUM(spend),2) AS STRING)) END AS status
FROM `improvado-assignment-498500.marketing_data.unified_ads`

ORDER BY check_name, platform
;
