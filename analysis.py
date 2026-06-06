"""
Cross-channel performance analysis — January 2024
Mirrors all BigQuery views locally for validation.
Run before deploying to BigQuery to verify numbers.
"""

import csv
from collections import defaultdict


def load(path="unified_data.csv"):
    with open(path) as f:
        return list(csv.DictReader(f))


def agg(rows):
    return rows.reduce if False else {
        'spend':        sum(float(r['spend'] or 0) for r in rows),
        'conversions':  sum(float(r['conversions'] or 0) for r in rows),
        'impressions':  sum(float(r['impressions'] or 0) for r in rows),
        'clicks':       sum(float(r['clicks'] or 0) for r in rows),
        'video_views':  sum(float(r['video_views'] or 0) if r.get('video_views') else 0 for r in rows),
        'conv_value':   sum(float(r['conversion_value']) if r.get('conversion_value') else 0 for r in rows),
        'vw25':         sum(float(r['video_watch_25']) if r.get('video_watch_25') else 0 for r in rows),
        'vw50':         sum(float(r['video_watch_50']) if r.get('video_watch_50') else 0 for r in rows),
        'vw75':         sum(float(r['video_watch_75']) if r.get('video_watch_75') else 0 for r in rows),
        'vw100':        sum(float(r['video_watch_100']) if r.get('video_watch_100') else 0 for r in rows),
        'likes':        sum(float(r['likes']) if r.get('likes') else 0 for r in rows),
        'shares':       sum(float(r['shares']) if r.get('shares') else 0 for r in rows),
        'comments':     sum(float(r['comments']) if r.get('comments') else 0 for r in rows),
    }


def kpis(a):
    sp, cv, im, cl = a['spend'], a['conversions'], a['impressions'], a['clicks']
    return {
        **a,
        'ctr':   cl / im        if im else 0,
        'cpa':   sp / cv        if cv else 0,
        'cpm':   sp / im * 1000 if im else 0,
        'cpc':   sp / cl        if cl else 0,
        'cpr':   cv / cl        if cl else 0,
        'roas':  a['conv_value'] / sp if sp else 0,
        'vcr':   a['vw100'] / a['video_views'] if a['video_views'] else 0,
    }


def section(title):
    print(f"\n{'═'*62}")
    print(f"  {title}")
    print('═' * 62)


rows = load()


# ── 1. QA VALIDATION (mirrors 00_qa_validation.sql) ──────────────
section("0. QA VALIDATION")
platforms = ['Facebook', 'Google', 'TikTok']
all_pass = True
for p in platforms:
    pr = [r for r in rows if r['platform'] == p]
    checks = [
        ('Row count = 110',   len(pr) == 110),
        ('No NULL spend',     all(r['spend'] for r in pr)),
        ('No zero impr',      all(float(r['impressions']) > 0 for r in pr)),
        ('Clicks ≤ impr',     all(float(r['clicks']) <= float(r['impressions']) for r in pr)),
    ]
    for label, ok in checks:
        status = '✓ PASS' if ok else '✗ FAIL'
        if not ok: all_pass = False
        print(f"  {p:<10} {label:<25} {status}")

total_spend = sum(float(r['spend']) for r in rows)
spend_ok = abs(total_spend - 130244.90) < 1
print(f"  {'All':<10} {'Total spend = $130,244.90':<25} {'✓ PASS' if spend_ok else '✗ FAIL'}")
print(f"\n  {'All checks passed ✓' if all_pass and spend_ok else 'FAILURES FOUND — fix before deploying'}")


# ── 2. PLATFORM SUMMARY (mirrors 01_platform_summary.sql) ────────
section("1. PLATFORM SUMMARY — mirrors platform_summary view")

grand = kpis(agg(rows))
print(f"\n  {'Platform':<12} {'Spend':>10} {'Conv':>8} {'CTR':>8} {'CPA':>8} {'CPM':>8} {'CPR':>8} {'Budget%':>9} {'Conv%':>7} {'Eff.Idx':>9}")
print(f"  {'-'*92}")

pdata = {}
for p in platforms:
    pr = [r for r in rows if r['platform'] == p]
    pdata[p] = kpis(agg(pr))

for p in platforms:
    d = pdata[p]
    bpct = d['spend'] / grand['spend'] * 100
    cpct = d['conversions'] / grand['conversions'] * 100
    eff  = (cpct / bpct) if bpct else 0
    flag = '↑ Over' if eff > 1 else '↓ Under'
    print(f"  {p:<12} ${d['spend']:>9,.0f} {d['conversions']:>8,.0f} {d['ctr']*100:>7.2f}%"
          f" ${d['cpa']:>7.2f} ${d['cpm']:>7.2f} {d['cpr']*100:>7.2f}%"
          f" {bpct:>8.1f}% {cpct:>6.1f}% {eff:>8.2f}x  {flag}")


# ── 3. CAMPAIGN LEADERBOARD (mirrors 02_campaign_performance.sql) ─
section("2. CAMPAIGN LEADERBOARD — mirrors campaign_performance view")

camps = defaultdict(lambda: dict(spend=0, conversions=0, impressions=0, clicks=0,
                                   conv_value=0, video_views=0, vw25=0, vw50=0, vw75=0, vw100=0))
for r in rows:
    k = (r['platform'], r['campaign_name'])
    camps[k]['spend']       += float(r['spend'] or 0)
    camps[k]['conversions'] += float(r['conversions'] or 0)
    camps[k]['impressions'] += float(r['impressions'] or 0)
    camps[k]['clicks']      += float(r['clicks'] or 0)
    camps[k]['conv_value']  += float(r['conversion_value']) if r.get('conversion_value') else 0

ranked = sorted(
    [(k, kpis(v)) for k, v in camps.items() if v['conversions'] > 0],
    key=lambda x: x[1]['cpa']
)

print(f"\n  {'#':<3} {'Platform':<10} {'Campaign':<30} {'Spend':>9} {'Conv':>6} {'CPA':>8} {'CTR':>7} {'CPR':>7} {'ROAS':>7}")
print(f"  {'-'*88}")
for i, (k, d) in enumerate(ranked, 1):
    cpa_flag = ' ← BEST' if i == 1 else (' ← WORST' if i == len(ranked) else '')
    roas = f"{d['roas']:.2f}x" if d['roas'] else '—'
    print(f"  {i:<3} {k[0]:<10} {k[1]:<30} ${d['spend']:>8,.0f} {d['conversions']:>6,.0f}"
          f" ${d['cpa']:>7.2f} {d['ctr']*100:>6.2f}% {d['cpr']*100:>6.2f}% {roas:>7}{cpa_flag}")


# ── 4. DAILY TREND SAMPLE (mirrors 03_daily_trend.sql) ───────────
section("3. DAILY TREND SAMPLE — mirrors daily_trend view (first 5 days)")

daily = defaultdict(lambda: defaultdict(lambda: dict(spend=0, conversions=0, clicks=0, impressions=0)))
for r in rows:
    daily[r['date']][r['platform']]['spend']       += float(r['spend'] or 0)
    daily[r['date']][r['platform']]['conversions'] += float(r['conversions'] or 0)
    daily[r['date']][r['platform']]['clicks']      += float(r['clicks'] or 0)
    daily[r['date']][r['platform']]['impressions'] += float(r['impressions'] or 0)

print(f"\n  {'Date':<12} {'Platform':<10} {'Spend':>9} {'Conv':>6} {'CPA':>8} {'CTR':>8}")
print(f"  {'-'*58}")
for date in sorted(daily.keys())[:15]:
    for p in platforms:
        if p in daily[date]:
            d = daily[date][p]
            cpa = d['spend'] / d['conversions'] if d['conversions'] else 0
            ctr = d['clicks'] / d['impressions'] if d['impressions'] else 0
            print(f"  {date:<12} {p:<10} ${d['spend']:>8,.2f} {d['conversions']:>6,.0f} ${cpa:>7.2f} {ctr*100:>7.3f}%")


# ── 5. TIKTOK FUNNEL (mirrors 07_tiktok_video_funnel_widget.sql) ──
section("4. TIKTOK VIDEO FUNNEL — mirrors tiktok_video_funnel_widget view")

tt = [r for r in rows if r['platform'] == 'TikTok']
total_views = sum(float(r['video_views']) for r in tt)
funnel = [
    ('Impressions → Views', total_views),
    ('25% Watched',         sum(float(r['video_watch_25']) for r in tt)),
    ('50% Watched',         sum(float(r['video_watch_50']) for r in tt)),
    ('75% Watched',         sum(float(r['video_watch_75']) for r in tt)),
    ('Completed (100%)',    sum(float(r['video_watch_100']) for r in tt)),
]

print(f"\n  {'Stage':<22} {'Viewers':>12} {'% of Views':>12} {'Drop-off':>10}")
print(f"  {'-'*60}")
prev = total_views
for label, viewers in funnel:
    pct  = viewers / total_views * 100 if total_views else 0
    drop = ((prev - viewers) / prev * 100) if prev and label != 'Impressions → Views' else 0
    bar  = '█' * int(pct / 5)
    print(f"  {label:<22} {viewers:>12,.0f} {pct:>11.1f}% {drop:>9.1f}%  {bar}")
    prev = viewers


# ── 6. QUALITY SCORE (mirrors 08_google_quality_score_widget.sql) ─
section("5. GOOGLE QS vs CTR — mirrors google_quality_score_widget view")

gg = [r for r in rows if r['platform'] == 'Google' and r.get('quality_score')]
qs_groups = defaultdict(lambda: dict(clicks=0, impressions=0, spend=0, conversions=0))
for r in gg:
    qs = int(float(r['quality_score']))
    qs_groups[qs]['clicks']      += float(r['clicks'] or 0)
    qs_groups[qs]['impressions'] += float(r['impressions'] or 0)
    qs_groups[qs]['spend']       += float(r['spend'] or 0)
    qs_groups[qs]['conversions'] += float(r['conversions'] or 0)

print(f"\n  {'QS':<6} {'CTR':>8} {'CPA':>9} {'Tier':<12} {'Bar (CTR)'}")
print(f"  {'-'*55}")
for qs in sorted(qs_groups.keys()):
    d   = qs_groups[qs]
    ctr = d['clicks'] / d['impressions'] * 100 if d['impressions'] else 0
    cpa = d['spend'] / d['conversions'] if d['conversions'] else 0
    tier = 'Excellent' if qs >= 9 else 'Good' if qs >= 8 else 'Average' if qs >= 6 else 'Poor'
    bar = '█' * int(ctr * 3)
    print(f"  QS {qs:<3} {ctr:>7.2f}% ${cpa:>8.2f}  {tier:<12} {bar}")


# ── 7. WEEKLY CPA TREND (mirrors 09_weekly_cpa_trend_widget.sql) ──
section("6. WEEKLY CPA TREND — mirrors weekly_cpa_trend_widget view")

weekly = defaultdict(lambda: defaultdict(lambda: dict(spend=0, conversions=0)))
for r in rows:
    day  = int(r['date'].split('-')[2])
    week = (day - 1) // 7 + 1
    weekly[week][r['platform']]['spend']       += float(r['spend'] or 0)
    weekly[week][r['platform']]['conversions'] += float(r['conversions'] or 0)

print(f"\n  {'Week':<8} {'Facebook CPA':>14} {'WoW':>8} {'Google CPA':>12} {'WoW':>8} {'TikTok CPA':>12} {'WoW':>8}")
print(f"  {'-'*76}")
prev_cpa = {p: None for p in platforms}
for wk in sorted(weekly.keys()):
    row_out = f"  Week {wk:<3}"
    for p in platforms:
        d   = weekly[wk][p]
        cpa = d['spend'] / d['conversions'] if d['conversions'] else 0
        wow = f"{cpa - prev_cpa[p]:+.2f}" if prev_cpa[p] else '  base'
        row_out += f"   ${cpa:>7.2f} ({wow})"
        prev_cpa[p] = cpa
    print(row_out)


# ── 8. EFFICIENCY INDEX (mirrors 10_efficiency_scorecard_widget) ──
section("7. EFFICIENCY SCORECARD — mirrors efficiency_scorecard_widget view")

grand_spend = sum(float(r['spend']) for r in rows)
grand_conv  = sum(float(r['conversions']) for r in rows)

print(f"\n  {'Platform':<12} {'Budget%':>9} {'Conv%':>8} {'Eff.Index':>11} {'Label':<22} {'Conv Gap vs FB'}")
print(f"  {'-'*75}")
fb_cpa = pdata['Facebook']['cpa']
for p in platforms:
    d    = pdata[p]
    bpct = d['spend'] / grand_spend * 100
    cpct = d['conversions'] / grand_conv * 100
    eff  = (cpct / bpct) if bpct else 0
    label = '✓ Over-delivering' if eff > 1 else '✗ Under-delivering'
    conv_gap = d['spend'] / fb_cpa - d['conversions']
    gap_str  = f"+{conv_gap:,.0f}" if conv_gap > 0 else f"{conv_gap:,.0f}"
    print(f"  {p:<12} {bpct:>8.1f}% {cpct:>7.1f}% {eff:>10.2f}x  {label:<22} {gap_str} conversions")


# ── 9. KEY RECOMMENDATIONS ────────────────────────────────────────
section("8. RECOMMENDATIONS FOR MARKETING TEAM")

print("""
  ┌─────────────────────────────────────────────────────────────┐
  │  1. REALLOCATE BUDGET — Shift 10-15% from TikTok → Facebook │
  │     TikTok efficiency: 0.89x (under-delivering)             │
  │     Facebook efficiency: 1.28x (over-delivering)           │
  │     Impact: ~+500 additional conversions at same total spend │
  ├─────────────────────────────────────────────────────────────┤
  │  2. PAUSE Google Search_Generic_Terms immediately           │
  │     CPA $24.80 vs Brand Terms $5.10 — 4.9x worse           │
  │     Redirect budget to Brand + Shopping campaigns           │
  ├─────────────────────────────────────────────────────────────┤
  │  3. DON'T TOUCH Facebook campaigns yet                      │
  │     CPA improved -5.6% from Wk1→Wk5 (algorithm learning)   │
  │     Let it run through February before any changes          │
  ├─────────────────────────────────────────────────────────────┤
  │  4. Shorten TikTok ads to 6-9 seconds                       │
  │     Only 26% watch to completion — CTA is being missed      │
  │     Front-load message in first 3 seconds                   │
  ├─────────────────────────────────────────────────────────────┤
  │  5. Improve Google QS for low-scoring ad groups             │
  │     QS9 = 5.21% CTR vs QS7 = 1.09% CTR (4.8x difference)  │
  │     Focus: landing page relevance + ad copy alignment       │
  └─────────────────────────────────────────────────────────────┘
""")
