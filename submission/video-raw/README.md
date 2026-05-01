# Raw Video Assets

## `kan-demo-flow.mp4`

Captured on 2026-05-01 from the Mac-hosted Android emulator using:

```bash
adb shell screenrecord --time-limit 75 /sdcard/kan-demo-flow.mp4
adb pull /sdcard/kan-demo-flow.mp4 submission/video-raw/kan-demo-flow.mp4
```

Purpose:

- Raw footage for the final 3-minute Kaggle video.
- Superseded by `zpk-demo-flow.mp4`; retained only as older raw evidence.

Verification:

- Size: about 7.7 MB.
- `file submission/video-raw/kan-demo-flow.mp4` reports ISO Media MP4.

Limitation:

- This is raw silent screen footage, not the final public YouTube video.

## `zpk-demo-flow.mp4`

Captured on 2026-05-01 from the Mac-hosted Android emulator after the ZPK Digital ID pivot:

```bash
adb shell screenrecord --time-limit 60 /sdcard/zpk-demo-flow.mp4
adb pull /sdcard/zpk-demo-flow.mp4 submission/video-raw/zpk-demo-flow.mp4
```

Purpose:

- Current raw footage for the final Kaggle video.
- Shows the updated ZPK Digital ID UI, synthetic CUI registration, local wallet mode, risk match, Spanish guidance, and local model route.

Verification:

- Size: about 7.3 MB.
- SHA-256: `a9684dc794b0b0def65fa6328d1ebbdf66ea3f85d182f92ed9e4cb470cb2c58b`

## `kan-final-narration.aiff`

Generated on 2026-05-01 with macOS text-to-speech from `submission/final-video-narration.txt`:

```bash
say -v Daniel -r 85 -o submission/video-raw/kan-final-narration.aiff -f submission/final-video-narration.txt
```

Purpose:

- Narration source for `submission/kan-final-demo-video.mp4`.
- Uses only claims already documented in the final writeup and evidence files.

## `zpk-final-narration.aiff`

Generated on 2026-05-01 with macOS text-to-speech from the updated ZPK narration:

```bash
say -v Daniel -r 92 -o submission/video-raw/zpk-final-narration.aiff -f submission/final-video-narration.txt
```

Purpose:

- Current narration source for `submission/kan-final-demo-video.mp4`.
- SHA-256: `07f748d3e35583ab084e8a545c58af718c48b337f9c1417c2942f06ebac93191`.
