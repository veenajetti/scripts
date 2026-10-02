# Reels watcher

Event-driven editing for `My Drive/Reels`. A file lands in `Raw`, the edit starts within a minute, the cut is verified, moved to `Done`, and `INDEX.csv` is updated. One video at a time, no batching, no one at the keyboard.

## What runs where

Everything runs on the Mac, because that is where the edit engine lives (video-use, ffmpeg-full, the Sketch and Studio engine skills, the fonts and doodle library). The cloud cannot do this part.

| Piece | Trigger | What it does |
|---|---|---|
| `com.veena.reels-ingest` | `~/Downloads` changes | `Edits_C_03_<ts>.mp4` from AirDrop becomes `Raw/C.03.mp4`. An older `C.03.mp4` is moved to `Raw/_superseded`, so no more `9.2.20261002.mp4` twins. |
| `com.veena.reels-watcher` | `Reels/Raw` changes, plus every 10 min | Waits for Drive to finish syncing the new file, then runs `run_edit.sh` for it. A lock keeps it to one edit at a time; files that arrive mid-edit are picked up right after. |
| `run_edit.sh` | called per video | Finds the script text, marks the INDEX row `editing`, runs the headless editor (`claude -p` with the local skills) into `~/Movies/video-use-jobs/reel_<N>/`, runs `verify.sh`, then moves the cut and sidecars to `Done` and marks the row `done` with the Drive link. |
| `verify.sh` | after every edit | The manual's hard checks: 65s minimum, zero silences of 0.45s or longer, audio and video within 0.15s, 1080x1920. A failing cut stays in `Edited` with a `<N>.FAILED.md` and the row reads `needs review`. |

INDEX status flow: `scripted` → `editing` → `done`, or `needs review` / `edit failed` when something stops it. A daily `INDEX.backup-<date>.csv` is written next to the index before the first change of the day.

## Naming rule

The Cut Room's names are the only names. A style is called what thecutroom.ai calls it, in config, in file names, in INDEX.csv, in edit notes, in chat. The old internal labels are retired:

| Retired label | Cut Room name |
|---|---|
| Format 1, Style 1, doodle edit | Sketch |
| Clean Pink, Style 2 | Studio |

Two engine skills on the Mac still carry old folder names (`~/.claude/skills/format-1` and `clean-pink-edit`) because renaming a skill folder changes nothing visible and risks breaking the engine. The style briefs point at them by those paths. Everything a person reads says Sketch and Studio.

## Choosing the style

One line in `config.env` decides how every video is cut:

```
EDIT_STYLE="sketch"
```

| Setting | What it is | State |
|---|---|---|
| `sketch` | Doodles, chalk chorus lines, image pops, jump cuts. The locked spec from reel 7.76 v007. | Locked, current default |
| `studio` | Typewriter cold open, phrase captions, minimal pops. | Locked, retired as default |
| `bold` | Big uppercase captions, fast cuts, zero decoration. | Draft, needs one reference cut |
| `luxe` | Word-by-word reveal, italic serif flourish. | Draft |
| `authority` | Name-plate lower third, crisp captions, steady pacing. | Draft |
| `cinema` | Letterbox bars, film grade, sparse serif titles. | Draft |
| `butter-world` | One calm take, headline card, polaroid receipts, chapter stickers. 90s and up. | Draft |

The site publishes one line per style, so the five drafts are written from that line plus the house rules. Each draft says so at the top. To lock one: set it, drop one raw, react to the cut, edit the brief, re-run `install.sh`. The brief wins over any style label inside a script doc; the doc's anchors, pops, CTA and loop still drive the timing.

## Install (once, on the Mac)

```bash
git clone <this repo> ~/Developer/scripts   # or pull if it is already there
cd ~/Developer/scripts/reels-watcher
./install.sh
```

Open Terminal on the Mac, paste those four lines, press return. The installer checks for Drive, ffmpeg-full, python3, the claude CLI and a working `claude login`, then copies this folder to `~/reels-watcher`, loads both launch agents, and sets the Mac to never sleep on power. Re-run it after any change to these files.

## What has to stay true

- Google Drive for desktop is running. If it is not, Raw is invisible and nothing fires.
- The Mac is awake and on power. The installer sets this; a closed lid still sleeps unless the Mac is docked.
- `claude login` has been done once in Terminal. This was the blocker on the earlier 01_INBOX watcher.
- The ElevenLabs key is still in `~/Developer/video-use/.env` for transcription.

## Watching it work

```bash
tail -f ~/reels-watcher/logs/watch.log          # arrivals, renames, start and finish of each edit
tail -f ~/reels-watcher/logs/edit_<N>.*.log     # one editor session
launchctl print gui/$(id -u)/com.veena.reels-watcher | head -20
```

You also get a macOS banner at each step: uploaded, editing, in Done, or needs review.

## Re-running a video

Delete its line from `~/reels-watcher/state/processed.txt` and touch the file in Raw, or drop a fresh export. A file that is replaced by a newer upload of the same script number is always re-edited; the old raw goes to `Raw/_superseded`.

## Script text

The editor looks, in order, for a `.txt` sidecar next to the raw or in `Scripts`, then tries to export the Google Doc from the INDEX row, then reads the doc through the Drive connector if the Mac's Claude Code has one. With no script at all it still cuts (pause-strip and captions, no loop) and leaves `<N>.FLAG.md` beside the result.
