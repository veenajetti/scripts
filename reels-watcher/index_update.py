#!/usr/bin/env python3
"""Deterministic edits to Reels/INDEX.csv.

Columns: script_no,pillar,series,title,status,script_doc,video_url,
         scheduled_date,scheduled_time,updated

Usage:
  index_update.py --index INDEX.csv --get 9.2 --field script_doc
  index_update.py --index INDEX.csv --set 9.2 --status editing
  index_update.py --index INDEX.csv --set 9.2 --status done --video-url URL
"""
import argparse, csv, datetime, os, shutil, sys, tempfile

COLS = ["script_no", "pillar", "series", "title", "status", "script_doc",
        "video_url", "scheduled_date", "scheduled_time", "updated"]


def load(path):
    with open(path, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    return rows


def save(path, rows):
    # backup once per day next to the index, then atomic replace
    stamp = datetime.date.today().isoformat()
    backup = os.path.join(os.path.dirname(path), f"INDEX.backup-{stamp}.csv")
    if not os.path.exists(backup):
        shutil.copy2(path, backup)
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".csv")
    with os.fdopen(fd, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=COLS, lineterminator="\r\n")
        w.writeheader()
        for r in rows:
            w.writerow({c: r.get(c, "") for c in COLS})
    os.replace(tmp, path)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--index", required=True)
    ap.add_argument("--get")
    ap.add_argument("--field")
    ap.add_argument("--set")
    ap.add_argument("--status")
    ap.add_argument("--video-url")
    ap.add_argument("--title")
    a = ap.parse_args()

    rows = load(a.index)
    if a.get:
        for r in rows:
            if r["script_no"] == a.get:
                print(r.get(a.field or "status", ""))
                return 0
        return 1

    if a.set:
        row = next((r for r in rows if r["script_no"] == a.set), None)
        if row is None:
            row = {c: "" for c in COLS}
            row["script_no"] = a.set
            rows.append(row)
        if a.status:
            row["status"] = a.status
        if a.video_url:
            row["video_url"] = a.video_url
        if a.title and not row.get("title"):
            row["title"] = a.title
        row["updated"] = datetime.date.today().isoformat()
        save(a.index, rows)
        return 0
    ap.error("nothing to do")


if __name__ == "__main__":
    sys.exit(main() or 0)
