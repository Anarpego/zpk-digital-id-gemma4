# Final Video Evidence

Date: 2026-05-01

Rendered file:

- `submission/kan-final-demo-video.mp4`
- Size: about 4.9 MB.
- Duration: about 1:40, under the 3-minute Kaggle video limit.
- Format: portrait MP4, H.264 video with AAC narration audio.
- SHA-256: `a01f26b7c8ef747415d7bb51280d1fabc82f0f27a6c7749b01494674ded6c5e1`

Source assets:

- `submission/video-raw/zpk-demo-flow.mp4`: Android emulator screen recording of the ZPK Digital ID flow.
- `submission/final-video-narration.txt`: narration text derived from the final script.
- `submission/video-raw/zpk-final-narration.aiff`: macOS text-to-speech narration source.
- `submission/final-video-captions.srt`: caption draft.

Commands used:

```bash
say -v Daniel -r 92 -o submission/video-raw/zpk-final-narration.aiff -f submission/final-video-narration.txt
uv run --with imageio-ffmpeg python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"
```

The final render used the uv-managed `imageio-ffmpeg` binary to combine the raw phone recording and narration with `-movflags +faststart`. No system Python was used.

Verification:

- `file submission/kan-final-demo-video.mp4` reports ISO Media MP4.
- ffmpeg reports one H.264 video stream and one AAC audio stream.
- The video has not been uploaded publicly yet.
