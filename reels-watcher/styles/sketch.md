STYLE: Sketch. Doodles, chalk underlines, image pops, punchy jump cuts. Playful.

Sketch is what `~/video-use-watcher/fullpass/build_full.py` produces from a spec: loop cut, cove captions, chalk chorus lines with emoji, butter Baskerville cards, real-photo pops, b-roll slices, pop and chalk SFX. The RUNBOOK in that folder is the engine; the `format-1` skill folder on the Mac is its older write-up. The rules below describe the approved look (reel 7.76 v007 and the 2026-09-24 batch) so the spec you write matches it. In every file, note and message, call this style Sketch, never Format 1.

Cut
- Pause-strip everything (gap 0.16s, pad-in 0.05, pad-out 0.07). Selective fillers: cut hesitations mid-list, keep voice-carrying ones.
- `|` loop hook to the front. Minimum 65 seconds, hard.
- Jump-cut texture cycling per range: none, 1.22 punch-in, hflip, hflip + 1.15 punch-in. Flip the state across every silence splice.
- Swearing: keep the line, bleep the word (1 kHz sine at 0.35 from word_start+0.15 to word_end-0.03). Caption shows `bullsh*t` form.

Graphics
- About 8 doodle pop-ups per 70 seconds, every 8 to 10 seconds. Hand-drawn GIF-sticker look: palette fills, wobbly #141414 outlines about 10px, bounce-in 0 to 1.12 to 1.0 over 0.3s, boil plus or minus 3px re-seeded every 4 frames, idle wobble 1.5 degrees, ProRes 4444 alpha.
- Palette, locked: lime #EAFC87, lavender #EEB5F7, purple #BDB4FE, orangecicle #FEB985, butter #FDFBD6, black #141414, white neutral.
- Content adds, never echoes the spoken words: visual gags, charts, metaphors, counters, tallies. Numbers are graphic. The CTA "send this" is the one allowed on-screen text; doodle text is Chalkboard.ttc index 0.
- Every revealing element lands on its payoff word's output timestamp through the EDL offset map. No overlapping windows (0.15s clear between slots). Safe zone y 300 to 780, x 60 to 980.
- Use doodle_lib and CATALOG.md before generating anything new.

Chorus lines
- 3 to 6 per video. Chalk handwriting (Chalkboard idx 0, about 66px), butter cream, no outline, y about 385, write-on 0.8s left to right, boil, hold 3.4 to 4.2s. Added context or a thought, never a pure reaction. Chalk SFX at each start.

Captions
- Cove captions (approved 2026-09-08): pages up to 6 words on 2 balanced lines, all white, no outline, Helvetica Neue Bold 66 body, one key word per page in lowercase italic Didot 86 with synthetic bold and a tight white glow, upcoming words dimmed to alpha A8 and lighting up as spoken, bottom-center MarginV 560, soft dark shadow.

Sound
- Pop cue on every element landing, chalk cue on every write or draw. Composite, then audio-only remux; loudnorm -14 LUFS.

From the script doc's EDIT NOTES, reuse the ANCHOR phrases, keyword pops, image pops, CTA line and LOOP as the timing map. Ignore its style label and any Studio specifics (pink typewriter, signature card).
