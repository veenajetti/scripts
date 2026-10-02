#!/bin/bash
# run_edit.sh <script_no> <raw_file>
# One video end to end: find script, run the headless editor, verify, move to Done, update INDEX.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/config.env"; source "$HERE/lib.sh"

N="$1"; RAW="$2"
JOB_DIR="$WORK_DIR/reel_$N"
mkdir -p "$JOB_DIR/versions" "$EDITED_DIR" "$DONE_DIR" "$LOG_DIR"
LOG="$LOG_DIR/edit_$N.$(date +%Y%m%d_%H%M%S).log"
exec >>"$LOG" 2>&1

log "=== start $N from $RAW"
cp -n "$RAW" "$JOB_DIR/source.mp4" 2>/dev/null || true

# 1. Script text. Sidecar first, then the index's doc URL as a hint for the editor.
TITLE="$(index_field "$N" title || true)"
DOC="$(index_field "$N" script_doc || true)"
SRC=""
for cand in "$RAW_DIR/$N"*.txt "$SCRIPTS_DIR/$N - "*.txt "$EDITED_DIR/$N - "*.txt; do
  [ -e "$cand" ] && { SRC="$cand"; break; }
done
if [ -z "$SRC" ] && [ -n "$DOC" ]; then
  # Works when the doc is link-viewable; otherwise the editor reads it through the Drive connector.
  id="$(printf '%s' "$DOC" | sed -E 's#.*/d/([^/]+).*#\1#')"
  if curl -fsSL "https://docs.google.com/document/d/$id/export?format=txt" -o "$JOB_DIR/script.txt" 2>/dev/null \
     && [ -s "$JOB_DIR/script.txt" ]; then SRC="$JOB_DIR/script.txt"; fi
fi
[ -n "$SRC" ] && log "script source: $SRC" || log "no local script text; editor will use Drive connector or flag"
[ -z "$TITLE" ] && TITLE="$N"

python3 "$HERE/index_update.py" --index "$INDEX_CSV" --set "$N" --status editing --title "$TITLE"
notify "Reels: editing $N" "$TITLE"

# 2. Headless edit with a watchdog.
STYLE_FILE="$HERE/styles/$EDIT_STYLE.md"
[ -f "$STYLE_FILE" ] || { log "unknown EDIT_STYLE '$EDIT_STYLE'; falling back to sketch"; STYLE_FILE="$HERE/styles/sketch.md"; }
STYLE_NAME="$(basename "$STYLE_FILE" .md)"
log "style: $STYLE_NAME"
export N RAW JOB_DIR SRC DOC EDITED_DIR TITLE STYLE_NAME STYLE_FILE
PROMPT="$(python3 "$HERE/render_prompt.py" "$HERE/prompts/edit_one.md")"

( cd "$JOB_DIR" && "$CLAUDE_BIN" -p "$PROMPT" --model "$CLAUDE_MODEL" \
    --settings "$HERE/claude-settings.json" --permission-mode acceptEdits \
    --output-format text ) &
PID=$!
SECS=0
while kill -0 "$PID" 2>/dev/null; do
  sleep 30; SECS=$((SECS + 30))
  if [ "$SECS" -ge "$EDIT_TIMEOUT" ]; then
    log "watchdog: killing editor after ${EDIT_TIMEOUT}s"; kill "$PID" 2>/dev/null; sleep 5; kill -9 "$PID" 2>/dev/null || true
    break
  fi
done
wait "$PID" 2>/dev/null; RC=$?
log "editor exit code $RC"

CUT="$EDITED_DIR/$N.mp4"
if [ ! -s "$CUT" ]; then
  log "no cut delivered"
  python3 "$HERE/index_update.py" --index "$INDEX_CSV" --set "$N" --status "edit failed"
  notify "Reels: $N FAILED" "No cut delivered. See $LOG"
  exit 1
fi

# 3. Our own verification, independent of the editor's.
if ! "$HERE/verify.sh" "$CUT"; then
  log "verification failed; holding in Edited"
  printf 'Verification failed on %s\n\n%s\n' "$(date)" "$("$HERE/verify.sh" "$CUT" 2>&1)" > "$EDITED_DIR/$N.FAILED.md"
  python3 "$HERE/index_update.py" --index "$INDEX_CSV" --set "$N" --status "needs review"
  notify "Reels: $N needs review" "Cut failed a hard check. Held in Edited."
  exit 1
fi

# 4. Promote to Done. Sidecars travel with the cut.
mv -f "$CUT" "$DONE_DIR/$N.mp4"
for side in "$EDITED_DIR/$N.editnotes.txt" "$EDITED_DIR/$N - "*.txt "$EDITED_DIR/$N.FLAG.md"; do
  [ -e "$side" ] && mv -f "$side" "$DONE_DIR/"
done
sleep 20  # give Drive a moment to assign the id to the moved file
URL="$(drive_view_url "$DONE_DIR/$N.mp4")"
python3 "$HERE/index_update.py" --index "$INDEX_CSV" --set "$N" --status done ${URL:+--video-url "$URL"}
log "done: $DONE_DIR/$N.mp4 ${URL:-(url pending sync)}"
notify "Reels: $N is in Done" "$TITLE"
exit 0
