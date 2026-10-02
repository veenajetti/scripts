#!/bin/bash
# Fired by launchd whenever Reels/Raw changes (and every 10 min as a safety net).
# Finds new footage, waits for Drive to finish syncing it, then runs one edit at a time.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/config.env"; source "$HERE/lib.sh"
mkdir -p "$STATE_DIR" "$LOG_DIR" "$SUPERSEDED_DIR"
exec >>"$LOG_DIR/watch.log" 2>&1

LOCK="$STATE_DIR/lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # A run is active. It re-scans Raw before exiting, so the new file is not lost.
  exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
caffeinate -i -w $$ &

[ -d "$RAW_DIR" ] || { log "Raw folder missing: $RAW_DIR (is Google Drive running?)"; exit 0; }

pass=0
while :; do
  pass=$((pass + 1)); worked=0
  for f in "$RAW_DIR"/*.mp4 "$RAW_DIR"/*.mov "$RAW_DIR"/*.MOV; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in .*|*.gdownload|*.tmp|*.partial) continue;; esac

    N="$(script_no_from_name "$base")"
    [ -n "$N" ] || continue

    # Collision rule: a date-suffixed upload replaces the older plain file.
    if [ "$base" != "$N.mp4" ]; then
      wait_until_stable "$f" || continue
      if [ -e "$RAW_DIR/$N.mp4" ]; then
        mv -f "$RAW_DIR/$N.mp4" "$SUPERSEDED_DIR/$N.$(date -r "$RAW_DIR/$N.mp4" +%Y%m%d_%H%M).mp4"
        log "superseded older $N.mp4"
      fi
      mv -f "$f" "$RAW_DIR/$N.mp4"; f="$RAW_DIR/$N.mp4"
      log "renamed $base -> $N.mp4"
    fi

    # Already cut? A newer <N>.mp4 in Done or Edited means this raw was handled
    # before the watcher existed. Only a raw newer than its cut gets re-edited.
    skip=0
    for cut in "$DONE_DIR/$N.mp4" "$EDITED_DIR/$N.mp4"; do
      if [ -e "$cut" ] && [ "$cut" -nt "$f" ]; then skip=1; fi
    done
    if [ "$skip" = 1 ]; then
      key="$(ledger_key "$N" "$f")"; ledger_has "$key" || { ledger_add "$key"; log "skip $N: a newer cut already exists"; }
      continue
    fi

    key="$(ledger_key "$N" "$f")"
    ledger_has "$key" && continue
    wait_until_stable "$f" || continue
    key="$(ledger_key "$N" "$f")"
    ledger_has "$key" && continue

    log "new footage $N ($(stat -f %z "$f") bytes)"
    ledger_add "$key"          # claim first so a crash cannot loop forever
    wait_for_render_slot
    "$HERE/run_edit.sh" "$N" "$f"; rc=$?
    log "$N finished rc=$rc"
    worked=1
  done
  # Anything that arrived while we were busy gets picked up before we exit.
  [ "$worked" -eq 1 ] && [ "$pass" -lt 20 ] || break
done
