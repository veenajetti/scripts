STYLE: Cinema. Widescreen bars, film-grade color, sparse serif titles. Moody.

DRAFT SPEC. The Cut Room publishes only the one-line description above. Cut one reference reel and lock these values before relying on them, then edit this file.

- Look for a local skill named cinema or cut-room-cinema in ~/.claude/skills and prefer it over this draft.
- Frame: 1080x1920 output with black letterbox bars, picture window 1080x1350 centered (bars 285px top and bottom). Captions sit on the lower bar.
- Grade: film look, lifted blacks, teal shadows, warm skin, slight grain (noise filter c0s=6), vignette. Tone-map the iPhone HLG first (zscale, ffmpeg-full).
- Cut: pause-strip, loop hook to front, 65s minimum. Cuts every 6 to 9 seconds, slow push-ins only.
- Titles: 2 to 4 sparse serif title cards, Didot Regular 72 white, letter-spaced, centered on the top bar, 2.5 seconds each, fade 0.4s. One for the hook, one for the turn, one for the CTA.
- Captions: Helvetica Neue 52 white at 90 percent on the bottom bar, full phrases, no highlight.
- Sound: speech, loudnorm -14 LUFS, optional low room-tone bed under -30 dB.
