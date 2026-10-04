"""Report Docker Hub version tags that have not been pulled for a long time.

Writes report.json (path in argv[1]) and appends the text report to the step summary.
Floating tags (latest, 7, 7.7) and pre-release tags (7.7.1-rc2) are never candidates.
"""
import json
import os
import re
import sys
import urllib.request
from datetime import datetime, timedelta, timezone

REPOS = os.environ.get("REPOS", "kolumbus120/churchcrm kolumbus120/churchcrm-frankenphp").split()
MONITOR = timedelta(days=270)  # 9 months
DELETE = timedelta(days=365)   # 12 months
FULL_VERSION = re.compile(r"^\d+\.\d+\.\d+$")

now = datetime.now(timezone.utc)
lines = ["=== DOCKER HUB TAG CLEANUP REPORT ===", f"Generated: {now:%Y-%m-%d %H:%M UTC}", ""]
delete_candidates, old_tags = [], []


def fetch_tags(repo):
    url = f"https://hub.docker.com/v2/repositories/{repo}/tags?page_size=100"
    tags = []
    while url:
        with urllib.request.urlopen(url, timeout=30) as resp:
            data = json.load(resp)
        tags += data.get("results", [])
        url = data.get("next")
    return tags


for repo in REPOS:
    try:
        tags = fetch_tags(repo)
    except Exception as exc:  # repository may not exist yet
        lines += [f"{repo}: could not fetch tags ({exc})", ""]
        continue
    versions = [t for t in tags if FULL_VERSION.match(t["name"])]
    lines.append(f"{repo}: {len(versions)} full version tags")
    for tag in versions:
        pulled = tag.get("tag_last_pulled")
        if not pulled:
            continue
        age = now - datetime.fromisoformat(pulled.replace("Z", "+00:00"))
        item = {"repo": repo, "name": tag["name"], "last_pulled": pulled[:10], "age_days": age.days}
        if age > DELETE:
            delete_candidates.append(item)
        elif age > MONITOR:
            old_tags.append(item)
    lines.append("")

for title, items in (("DELETE CANDIDATES (not pulled for >12 months)", delete_candidates),
                     ("OLD TAGS (monitor, not pulled for >9 months)", old_tags)):
    if items:
        lines.append(title + ":")
        lines += [f"  - {t['repo']}:{t['name']}: last pulled {t['last_pulled']} ({t['age_days']} days ago)"
                  for t in sorted(items, key=lambda x: -x["age_days"])]
        lines.append("")
if not delete_candidates and not old_tags:
    lines.append("ALL GOOD: all tags are active")

report = "\n".join(lines)
print(report)
with open(sys.argv[1], "w") as f:
    json.dump({"action_needed": bool(delete_candidates), "delete_candidates": delete_candidates,
               "old_tags": old_tags, "report": report}, f)
if os.environ.get("GITHUB_STEP_SUMMARY"):
    with open(os.environ["GITHUB_STEP_SUMMARY"], "a") as f:
        f.write("```\n" + report + "\n```\n")
