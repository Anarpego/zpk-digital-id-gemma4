# Kaggle Submission Fields

Use these fields for the final Kaggle submission. Replace placeholder URLs only after the public repository, demo ZIP, and video have been uploaded.

## Title

Kan: Local-First Breach Defense for Guatemalan Citizens

## Subtitle

An Android-first Gemma 4 assistant that checks synthetic breach exposure locally, explains risk in plain Spanish, and prepares a preliminary complaint draft without sending CUI to a server.

## Impact Track

Digital Equity & Inclusivity

## Repository URL

`TODO_PUBLIC_REPO_URL`

## Live Demo URL

`TODO_PUBLIC_DEMO_ZIP_OR_DATASET_URL`

Recommended artifact: `submission/dist/kan-demo-package-20260501T172959Z.zip`.

## Video URL

`TODO_PUBLIC_VIDEO_URL`

Recommended artifact: `submission/kan-final-demo-video.mp4`.

## Short Summary

Kan helps Guatemalan citizens answer three urgent questions after a data leak: am I affected, what does it mean, and what can I do today? The demo uses only synthetic data. It verifies a CUI against an embedded local breach catalog, explains the result in Spanish, and generates a preliminary complaint draft on device.

## Technical Summary

Kan is a Flutter Android app with three reasoner modes: deterministic local mode for reliable offline demos, Cactus local mode for on-device model-routing evidence, and hosted Gemma 4 mode verified with `gemma-4-31b-it`. The default APK keeps sensitive checks local and shows trace events for catalog loading, lookup, routing, and document generation. Evidence includes Android screenshots, passing Flutter tests, a Gemma 4 API smoke test, Cactus local-inference metrics, and a documented Unsloth training attempt that reached Gemma 4 E2B load/tokenization before failing on the available 6 GB GPU.

## Prize Claims

- Main Track: working social-impact prototype with Android app, local verification, Spanish guidance, document draft, hosted Gemma 4 evidence, and visible privacy traces.
- Impact Track: Digital Equity & Inclusivity.
- Cactus special prize: claim cautiously as partial local-inference/routing evidence only.
- Unsloth special prize: do not claim unless a larger GPU produces an adapter and before/after benchmark.

## Public Upload Checklist

- [ ] Public GitHub repository URL is reachable without login.
- [ ] Demo ZIP URL is reachable without login.
- [ ] Video URL is reachable without login and plays under 3 minutes.
- [ ] Kaggle writeup is pasted from `submission/final-kaggle-writeup.md`.
- [ ] Media gallery includes `submission/media-gallery-cover.svg` or a rendered version of it.
- [ ] No `.env` or API key is uploaded.
