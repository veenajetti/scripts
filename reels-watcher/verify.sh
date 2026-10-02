#!/bin/bash
# verify.sh <cut.mp4>  -- the mandatory checks from the house editing manual.
# Exit 0 = ship it. Exit 1 = hold in Edited with a FAILED note.
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
source "$HERE/config.env"; source "$HERE/lib.sh"
f="$1"; fail=0

dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f" 2>/dev/null)
vlen=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 "$f" 2>/dev/null)
alen=$(ffprobe -v error -select_streams a:0 -show_entries stream=duration -of csv=p=0 "$f" 2>/dev/null)

python3 - "$dur" "$MIN_RUNTIME" <<'PY' || { echo "FAIL runtime under minimum"; fail=1; }
import sys; d=float(sys.argv[1] or 0); m=float(sys.argv[2]); sys.exit(0 if d>=m else 1)
PY

python3 - "$vlen" "$alen" <<'PY' || { echo "FAIL audio/video length drift over 0.15s"; fail=1; }
import sys; v=float(sys.argv[1] or 0); a=float(sys.argv[2] or 0); sys.exit(0 if abs(v-a)<=0.15 else 1)
PY

hits=$(ffmpeg -hide_banner -nostats -i "$f" -af "silencedetect=n=-32dB:d=0.45" -f null - 2>&1 | grep -c silence_start || true)
if [ "${hits:-0}" -gt 0 ]; then echo "FAIL $hits silences of 0.45s or longer"; fail=1; fi

w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f" 2>/dev/null)
[ "$w" = "1080,1920" ] || { echo "FAIL frame is $w, expected 1080,1920"; fail=1; }

echo "duration=$dur video=$vlen audio=$alen silences=${hits:-0} frame=$w"
exit $fail
