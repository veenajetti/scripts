#!/bin/bash
# Shared helpers. Source after config.env.

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

notify() {
  # macOS banner. Never fails the pipeline if osascript is unavailable.
  local title="$1" body="$2"
  osascript -e "display notification \"$body\" with title \"$title\"" >/dev/null 2>&1 || true
}

# 9.2.20261002.mp4 -> 9.2 ; C.03.mp4 -> C.03 ; 8.2.1.mp4 -> 8.2.1
script_no_from_name() {
  local base="${1%.*}"
  # strip a trailing .YYYYMMDD collision suffix the uploader adds
  base="$(printf '%s' "$base" | sed -E 's/\.[0-9]{8}$//')"
  printf '%s' "$base"
}

# True when the file has stopped growing (Drive finished syncing).
wait_until_stable() {
  local f="$1" waited=0 a b
  a=$(stat -f %z "$f" 2>/dev/null || echo -1)
  while :; do
    sleep "$STABLE_SECONDS"
    b=$(stat -f %z "$f" 2>/dev/null || echo -2)
    if [ "$a" = "$b" ] && [ "$b" -gt 1000000 ]; then return 0; fi
    a="$b"; waited=$((waited + STABLE_SECONDS))
    if [ "$waited" -ge 1800 ]; then log "gave up waiting for $f to settle"; return 1; fi
  done
}

# Drive for desktop exposes the Drive file id as an extended attribute.
drive_file_id() {
  xattr -p 'com.google.drivefs.item-id#S' "$1" 2>/dev/null | tr -d '\n' || true
}

drive_view_url() {
  local id; id="$(drive_file_id "$1")"
  [ -n "$id" ] && printf 'https://drive.google.com/file/d/%s/view' "$id"
}

# Fallback when the mount has no Drive id yet: ask rclone (the pipeline's own remote).
rclone_view_url() {
  command -v rclone >/dev/null || return 0
  local id; id="$(rclone lsjson "gdrive:$(dirname "$1")" 2>/dev/null | python3 -c '
import sys, json, os
name = os.path.basename(sys.argv[1])
for f in json.load(sys.stdin):
    if f.get("Name") == name: print(f.get("ID", "")); break' "$1")"
  [ -n "$id" ] && printf 'https://drive.google.com/file/d/%s/view' "$id"
}

# Another render in flight (a hand-run build or a Cut Room job) means wait: parallel renders OOM.
wait_for_render_slot() {
  local waited=0
  while pgrep -f "build_full.py|helpers/render.py|deliver_reel.py" >/dev/null 2>&1; do
    [ "$waited" -eq 0 ] && log "another render is running; waiting for it to finish"
    sleep 60; waited=$((waited + 60))
    [ "$waited" -ge 7200 ] && { log "waited 2h for a render slot; proceeding anyway"; break; }
  done
}

# Ledger of files already handled: "<script_no>|<size>|<mtime>"
ledger_key() { printf '%s|%s|%s' "$1" "$(stat -f %z "$2")" "$(stat -f %m "$2")"; }
ledger_has() { grep -qxF "$1" "$STATE_DIR/processed.txt" 2>/dev/null; }
ledger_add() { printf '%s\n' "$1" >> "$STATE_DIR/processed.txt"; }

# Column lookup in INDEX.csv (python handles quoting correctly)
index_field() {
  python3 "$(dirname "${BASH_SOURCE[0]}")/index_update.py" --index "$INDEX_CSV" --get "$1" --field "$2"
}
