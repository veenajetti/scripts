#!/bin/bash
# Installs the launchd agent that keeps Remote Control running for ~/Developer/scripts.
# Run once on the Mac:  ./install_remote_control.sh
# Before running: the folder must already be trusted and Remote Control accepted once
# interactively (both happened the first time `claude remote-control` was answered y).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
DEST="$HOME/reels-watcher"; AGENTS="$HOME/Library/LaunchAgents"; LABEL=com.veena.remote-control
mkdir -p "$DEST/logs" "$AGENTS"
cp "$HERE/remote_control.sh" "$DEST/remote_control.sh"; chmod +x "$DEST/remote_control.sh"
sed "s|__HOME__|$HOME|g" "$HERE/$LABEL.plist" > "$AGENTS/$LABEL.plist"
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$AGENTS/$LABEL.plist"
launchctl kickstart -k "gui/$(id -u)/$LABEL"
sleep 8
echo "agent state:"; launchctl print "gui/$(id -u)/$LABEL" | grep -E "state|pid" | head -3
echo "last log lines:"; tail -5 "$DEST/logs/remote-control.log" 2>/dev/null || true
echo
echo "If a `claude remote-control` is still running in a Terminal window, press Ctrl+C there; the agent has taken over."
