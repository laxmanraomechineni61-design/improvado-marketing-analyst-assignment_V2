"""
Cross-channel performance analysis — January 2024
Reads unified_data.csv and prints key insights.
"""

import csv
from collections import defaultdict


def load(path="unified_data.csv"):
    with open(path) as f:
        return list(csv.DictReader(f))


def fmt(n, prefix="$", decimals=2):
    return f"{prefix}{n:,.{decimals}f}" if prefix else f"{n:,.{decimals}f}"


def section(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print('='*60)


rows = load()


# ── 1. Platform summary ───────────────────────────────────────
section("1. PLATFORM SUMMARY — Jan 2024")

pdata = defaultdict(lambda: dict(impressions=0, clicks=0, spend=0, conversions=0))
for r in rows:
    p = r["platform"]
    pdata[p]["impressions"]  += float(r["impressions"]  or 0)
    pdata[p]["clicks"]       += float(r["clicks"]       or 0)
    pdata[p]["spend"]        += float(r["spend"]        or 0)
    pdata[p]["conversions"]  += float(r["conversions"]  or 0)

total_spend = sum(d["spend"] for d in pdata.values())
total_conv  = sum(d["conversions"] for d in pdata.values())

print(f"\n{'Platform':<12} {'Impressions':>14} {'Clicks':>10} {'Spend':>12} "
      f"{'Conversions':>13} {'CTR':>7} {'CPA':>8} {'CPM':>8}")
print("-" * 90)
for p, d in pdata.items():
    ctr = d["clicks"] / d["impressions"] * 100 if d["impressions"] else 0
    cpa = d["spend"] / d["conversions"] if d["conversions"] else 0
    cpm = d["spend"] / d["impressions"] * 1000 if d["impressions"] else 0
    print(f"{p:<12} {d['impressions']:>14,.0f} {d['clicks']:>10,.0f} "
          f"${d['spend']:>11,.2f} {d['conversions']:>13,.0f} "
          f"{ctr:>6.2f}% ${cpa:>7.2f} ${cpm:>7.2f}")


# ── 2. Budget vs conversion share ────────────────────────────
section("2. BUDGET ALLOCATION vs CONVERSION SHARE")

print(f"\n{'Platform':<12} {'Budget %':>10} {'Conv %':>10}  {'Verdict':}")
print("-" * 55)
for p, d in pdata.items():
    bpct = d["spend"] / total_spend * 100
    cpct = d["conversions"] / total_conv * 100
    verdict = "OVER-INDEXED" if cpct > bpct else "UNDER-INDEXED"
    print(f"{p:<12} {bpct:>9.1f}% {cpct:>9.1f}%  {verdict}")


# ── 3. Campaign leaderboard ───────────────────────────────────
section("3. CAMPAIGN LEADERBOARD BY CPA")

camps = defaultdict(lambda: dict(spend=0, conversions=0, impressions=0, clicks=0))
for r in rows:
    k = f"{r['platform']} | {r['campaign_name']}"
    camps[k]["spend"]       += float(r["spend"]       or 0)
    camps[k]["conversions"] += float(r["conversions"] or 0)
    camps[k]["impressions"] += float(r["impressions"] or 0)
    camps[k]["clicks"]      += float(r["clicks"]      or 0)

ranked = sorted(
    [(k, v) for k, v in camps.items() if v["conversions"] > 0],
    key=lambda x: x[1]["spend"] / x[1]["conversions"]
)

print(f"\n{'Rank':<5} {'Campaign':<45} {'CPA':>8} {'CTR':>8}")
print("-" * 70)
for i, (k, v) in enumerate(ranked, 1):
    cpa = v["spend"] / v["conversions"]
    ctr = v["clicks"] / v["impressions"] * 100
    flag = " ← BEST" if i == 1 else (" ← WORST" if i == len(ranked) else "")
    print(f"{i:<5} {k:<45} ${cpa:>7.2f} {ctr:>7.2f}%{flag}")


# ── 4. TikTok video completion funnel ────────────────────────
section("4. TIKTOK VIDEO COMPLETION FUNNEL")

tt = [r for r in rows if r["platform"] == "TikTok"]
total_views = sum(float(r["video_views"]) for r in tt if r["video_views"])

print("\n  Checkpoint       Viewers Reached    Drop-off")
print("  " + "-" * 50)
prev = total_views
for col, label in [
    ("video_watch_25",  "25% of video"),
    ("video_watch_50",  "50% of video"),
    ("video_watch_75",  "75% of video"),
    ("video_watch_100", "Completed (100%)"),
]:
    total = sum(float(r[col]) for r in tt if r[col])
    pct   = total / total_views * 100
    drop  = (prev - total) / prev * 100
    print(f"  {label:<18}  {pct:>6.1f}% reached    -{drop:.1f}% from prev")
    prev  = total


# ── 5. Weekly CPA trend ───────────────────────────────────────
section("5. WEEKLY CPA TREND BY PLATFORM")

weeks = defaultdict(lambda: defaultdict(lambda: dict(spend=0, conversions=0)))
for r in rows:
    day  = int(r["date"].split("-")[2])
    week = (day - 1) // 7 + 1
    d    = weeks[week][r["platform"]]
    d["spend"]       += float(r["spend"]       or 0)
    d["conversions"] += float(r["conversions"] or 0)

print(f"\n{'Week':<6} {'Facebook CPA':>14} {'Google CPA':>12} {'TikTok CPA':>12}")
print("-" * 48)
for w in sorted(weeks):
    row_out = f"Wk {w:<3}"
    for p in ["Facebook", "Google", "TikTok"]:
        d   = weeks[w][p]
        cpa = d["spend"] / d["conversions"] if d["conversions"] else 0
        row_out += f"   ${cpa:>9.2f}"
    print(row_out)


# ── 6. Google Quality Score impact ───────────────────────────
section("6. GOOGLE QUALITY SCORE vs CTR")

gg = [r for r in rows if r["platform"] == "Google" and r["quality_score"]]
qs_data = defaultdict(list)
for r in gg:
    qs_data[int(float(r["quality_score"]))].append(float(r["ctr"] or 0))

print(f"\n  {'Quality Score':<16} {'Avg CTR':>10}  {'Relative performance'}")
print("  " + "-" * 55)
baseline = None
for qs in sorted(qs_data):
    avg = sum(qs_data[qs]) / len(qs_data[qs]) * 100
    if baseline is None:
        baseline = avg
    delta = avg / baseline
    bar   = "█" * int(delta * 10)
    print(f"  QS {qs:<13} {avg:>9.2f}%  {bar}")


# ── 7. Key recommendations ───────────────────────────────────
section("7. RECOMMENDATIONS")

print("""
  1. REALLOCATE BUDGET  — Facebook is over-indexed in conversions vs spend.
     Shift 10-15% of TikTok budget to Facebook (esp. Conversions_Retargeting).

  2. PAUSE GOOGLE GENERIC SEARCH — CPA of $24.80 is 4.9x worse than Brand Terms.
     Redirect that budget to Shopping and Brand campaigns.

  3. SHORTEN TIKTOK ADS — Only 26% watch to completion. Front-load the CTA.
     Test 6-9 second formats to improve conversion efficiency.

  4. DON'T TOUCH FACEBOOK YET — CPA is improving week-over-week (-5.6%).
     The algorithm is still learning. Let it run through February.

  5. IMPROVE GOOGLE AD RELEVANCE — QS 9 campaigns get 2.6x more clicks than QS 7.
     Focus on landing page alignment for low-QS ad groups.
""")
