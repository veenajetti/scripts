#!/bin/bash
# Fired by launchd when ~/Downloads changes. Moves AirDropped Edits-app exports into Reels/Raw.
#   Edits_C_03_20261002_063012.mp4  -> Raw/C.03.mp4
#   Edits_9_2_20261002_063012.mp4   -> Raw/9.2.mp4
#   Edits_8_2_1_20260908_151726.mp4 -> Raw/8.2.1.mp4
# A same-named raw already in Raw is moved to Raw/_superseded, never silently kept as a duplicate.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/config.env"; source "$HERE/lib.sh"
mkdir -p "$LOG_DIR" "$SUPERSEDED_DIR"
exec >>"$LOG_DIR/ingest.log" 2>&1

shopt -s nullglob
for f in "$DOWNLOADS_DIR"/Edits_*.mp4 "$DOWNLOADS_DIR"/Edits_*.mov "$DOWNLOADS_DIR"/Edits_*.MOV; do
  base="$(basename "$f")"
  # strip prefix, timestamp (two trailing numeric groups), extension; underscores become dots
  core="$(printf '%s' "${base%.*}" | sed -E 's/^Edits_//; s/_[0-9]{8}_[0-9]{6}$//; s/_[0-9]{8}$//')"
  N="$(printf '%s' "$core" | tr '_' '.')"
  [ -n "$N" ] || continue
  wait_until_stable "$f" || continue
  if [ -e "$RAW_DIR/$N.mp4" ]; then
    mv -f "$RAW_DIR/$N.mp4" "$SUPERSEDED_DIR/$N.$(date -r "$RAW_DIR/$N.mp4" +%Y%m%d_%H%M).mp4"
    log "superseded older $N.mp4"
  fi
  mv -f "$f" "$RAW_DIR/$N.mp4"
  log "ingested $base -> Raw/$N.mp4"
  notify "Reels: $N uploaded to Raw" "Edit starts when Drive finishes syncing."
done
