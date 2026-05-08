# Public Submission Audit - 2026-05-08

This audit records the public state after publishing the repository and GitHub
Release for the Gemma 4 Good Hackathon handoff.

## Objective

Ship ZPK Digital ID as a real Android app submission, not a prototype-only
demo: local-first identity protection for Guatemala, offline agentic Gemma 4
execution, public code, public demo artifacts, and clear manual Kaggle
submission materials.

## Checklist

| Requirement | Evidence | Status |
|---|---|---|
| Public code repository | `https://github.com/Anarpego/zpk-digital-id-gemma4` returns HTTP 200 without login | Done |
| Public release / live demo | `https://github.com/Anarpego/zpk-digital-id-gemma4/releases/tag/v2026.05.07-kaggle` returns HTTP 200 | Done |
| Main and release tag aligned | `git ls-remote origin refs/heads/main refs/tags/v2026.05.07-kaggle` returns the same commit for both refs | Done |
| Demo package available | `kan-demo-package-final.zip` release asset is uploaded and direct URL returns HTTP 200 | Done |
| Demo package integrity | Release asset digest and local verifier use SHA-256 `8fc6a6f8f2a11e5285644a178dc35f99d256babedd8321b3bd2ae27346d85eca` | Done |
| Primary APK available | `zpk-citizen-gemma4-release.apk` release asset is uploaded | Done |
| Primary APK integrity | SHA-256 `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb` | Done |
| Media cover available | `media-gallery-cover.png` release asset is uploaded, SHA-256 `bf8cefade54d486c626b9b4b5b95cffff9e6e589870f09735a0f5ff38569d947` | Done |
| Video file available for manual YouTube upload | `submission/kan-final-demo-video.mp4`, 100 seconds, SHA-256 `e33a3a93d1d86da8a091a3435509e09f4ffd8d944a8ff811d49735ebd03fe3e6` | Done locally and in release |
| YouTube upload | User explicitly kept this manual | Manual remaining |
| Kaggle writeup | `submission/final-kaggle-writeup.md`, 977 words, under 1,500-word limit | Done |
| Kaggle form copy | `submission/KAGGLE_FORM.md` includes public repo and live demo links; only YouTube URL remains manual | Done |
| YouTube copy | `submission/YOUTUBE_DESCRIPTION.md` includes public repo, release, ZIP, APK, and checksums | Done |
| Local verifier | `./scripts/verify_submission.sh` passed after final package update | Done |
| Kaggle submission | User explicitly requested manual submission only | Manual remaining |

## Current Public URLs

- Repository: `https://github.com/Anarpego/zpk-digital-id-gemma4`
- Release / live demo: `https://github.com/Anarpego/zpk-digital-id-gemma4/releases/tag/v2026.05.07-kaggle`
- ZIP: `https://github.com/Anarpego/zpk-digital-id-gemma4/releases/download/v2026.05.07-kaggle/kan-demo-package-final.zip`
- APK: `https://github.com/Anarpego/zpk-digital-id-gemma4/releases/download/v2026.05.07-kaggle/zpk-citizen-gemma4-release.apk`

## Remaining Manual Actions

1. Upload `submission/kan-final-demo-video.mp4` to YouTube as public or
   unlisted.
2. Paste the YouTube URL into Kaggle.
3. Attach `submission/media-gallery-cover.png` and any additional screenshots
   in the Kaggle media gallery.
4. Paste the writeup and links from `submission/KAGGLE_FORM.md`.
5. Submit manually on Kaggle.

No Kaggle submission was performed from this machine.
