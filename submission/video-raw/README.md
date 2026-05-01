# Raw Video Assets

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

## `zpk-final-narration.aiff`

Generated on 2026-05-01 with macOS text-to-speech from the updated ZPK narration:

```bash
say -v Daniel -r 92 -o submission/video-raw/zpk-final-narration.aiff -f submission/final-video-narration.txt
```

Purpose:

- Current narration source for `submission/kan-final-demo-video.mp4`.
- SHA-256: `39abcc9e39676f2e11a052667a4bbf50f33ee048fea7edb3008a81d04e88a7f5`.
