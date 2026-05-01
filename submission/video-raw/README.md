# Raw Video Assets

## `kan-demo-flow.mp4`

Captured on 2026-05-01 from the Mac-hosted Android emulator using:

```bash
adb shell screenrecord --time-limit 75 /sdcard/kan-demo-flow.mp4
adb pull /sdcard/kan-demo-flow.mp4 submission/video-raw/kan-demo-flow.mp4
```

Purpose:

- Raw footage for the final 3-minute Kaggle video.
- Shows the default local-mode Kan flow: open app, verify synthetic CUI, view match, scroll through guidance, tool traces, and complaint draft.

Verification:

- Size: about 7.7 MB.
- `file submission/video-raw/kan-demo-flow.mp4` reports ISO Media MP4.

Limitation:

- This is raw silent screen footage, not the final public YouTube video.

## `kan-final-narration.aiff`

Generated on 2026-05-01 with macOS text-to-speech from `submission/final-video-narration.txt`:

```bash
say -v Daniel -r 85 -o submission/video-raw/kan-final-narration.aiff -f submission/final-video-narration.txt
```

Purpose:

- Narration source for `submission/kan-final-demo-video.mp4`.
- Uses only claims already documented in the final writeup and evidence files.
