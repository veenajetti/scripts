#!/bin/bash
# One-time install on Veena's Mac. Safe to re-run; it replaces the agents in place.
#   git clone <this repo> && cd scripts/reels-watcher && ./install.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/reels-watcher"
AGENTS="$HOME/Library/LaunchAgents"
UID_="$(id -u)"

echo "== preflight"
source "$HERE/config.env"
ok=1
[ -d "$RAW_DIR" ] && echo "  Drive Raw folder found" || { echo "  MISSING: $RAW_DIR  (open Google Drive for desktop and wait for sync)"; ok=0; }
command -v "$CLAUDE_BIN" >/dev/null 2>&1 && echo "  claude CLI found" || { echo "  MISSING: claude CLI (npm i -g @anthropic-ai/claude-code)"; ok=0; }
[ -x "$FFMPEG_BIN/ffmpeg" ] && echo "  ffmpeg-full found" || { echo "  MISSING: brew install ffmpeg-full"; ok=0; }
command -v python3 >/dev/null && echo "  python3 found" || { echo "  MISSING: python3"; ok=0; }
[ -d "$HOME/.claude/skills/format-1" ] && echo "  sketch engine skill present (installed on the Mac as format-1)" || echo "  WARNING: no format-1 skill in ~/.claude/skills; Sketch will use the written brief in styles/sketch.md"
echo "  edit style: $EDIT_STYLE (change EDIT_STYLE in config.env, then re-run install)"
if "$CLAUDE_BIN" -p "reply with the single word ready" --max-turns 1 --output-format text 2>/dev/null | grep -qi ready; then
  echo "  claude is logged in"
else
  echo "  MISSING: claude is not logged in. Run 'claude login' in Terminal once, then re-run install."; ok=0
fi
[ "$ok" = 1 ] || { echo "Fix the MISSING items above, then re-run."; exit 1; }

echo "== install files to $DEST"
mkdir -p "$DEST/prompts" "$DEST/styles" "$DEST/state" "$DEST/logs" "$AGENTS"
cp "$HERE"/*.sh "$HERE"/*.py "$HERE"/config.env "$HERE"/claude-settings.json "$DEST/"
cp "$HERE"/prompts/*.md "$DEST/prompts/"
cp "$HERE"/styles/*.md "$DEST/styles/"
chmod +x "$DEST"/*.sh "$DEST"/*.py

echo "== load launch agents"
for label in com.veena.reels-watcher com.veena.reels-ingest; do
  sed "s|__HOME__|$HOME|g" "$HERE/$label.plist" > "$AGENTS/$label.plist"
  launchctl bootout "gui/$UID_/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$UID_" "$AGENTS/$label.plist"
  launchctl kickstart -k "gui/$UID_/$label"
  echo "  $label loaded"
done

echo "== keep the Mac awake while plugged in (asks for your password once)"
sudo pmset -c sleep 0 disksleep 0 || echo "  skipped; set Energy Saver to never sleep on power manually"

echo
echo "Installed. Drop a file in Reels/Raw (or AirDrop an Edits export to Downloads) and watch:"
echo "  tail -f $DEST/logs/watch.log"
