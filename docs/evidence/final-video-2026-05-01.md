# Final Video Evidence

Date: 2026-05-01

Rendered file:

- `submission/kan-final-demo-video.mp4`
- Size: about 4.5 MB.
- Duration: about 1:43, under the 3-minute Kaggle video limit.
- Format: portrait MP4, H.264 video with AAC narration audio.

Source assets:

- `submission/video-raw/kan-demo-flow.mp4`: Android emulator screen recording.
- `submission/final-video-narration.txt`: narration text derived from the final script.
- `submission/video-raw/kan-final-narration.aiff`: macOS text-to-speech narration source.
- `submission/final-video-captions.srt`: caption draft.

Commands used:

```bash
say -v Daniel -r 85 -o submission/video-raw/kan-final-narration.aiff -f submission/final-video-narration.txt
uv run --with imageio-ffmpeg python -c "import imageio_ffmpeg; print(imageio_ffmpeg.get_ffmpeg_exe())"
```

The final render used the uv-managed `imageio-ffmpeg` binary to combine the raw phone recording and narration. No system Python was used.

Verification:

- `file submission/kan-final-demo-video.mp4` reports ISO Media MP4.
- ffmpeg reports one H.264 video stream and one AAC audio stream.
- The video has not been uploaded publicly yet.
