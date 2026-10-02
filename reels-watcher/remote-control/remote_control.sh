#!/bin/bash
# Keeps `claude remote-control` running for ~/Developer/scripts so the Mac always
# shows up as an environment in the Claude Code app. launchd restarts it if it exits.
# `script` gives it a pseudo-terminal, which the CLI expects even when nobody is watching.
set -u
PROJECT="$HOME/Developer/scripts"
LOG="$HOME/reels-watcher/logs/remote-control.log"
mkdir -p "$(dirname "$LOG")"
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.local/bin:/usr/bin:/bin"
cd "$PROJECT" || { echo "$(date) project folder missing: $PROJECT" >> "$LOG"; sleep 60; exit 1; }
echo "$(date) starting remote-control in $PROJECT" >> "$LOG"
exec script -q -a "$LOG" claude remote-control --spawn=same-dir --name "Veenas MacBook Pro"
