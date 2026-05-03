# ZPK Digital ID Gemma 4 Good Submission Dataset

This upload folder is for a public Kaggle Dataset that can serve as the no-login submission artifact for the Gemma 4 Good Hackathon.

Contents:

- `kan-demo-package-final.zip`: local APK, LiteRT APK, static app page, final video, evidence docs, screenshots, final writeup, and adaptation pipeline.
- `kan-demo-package-final.zip.sha256`: checksum for the submission package.
- `kan-final-demo-video.mp4`: narrated video under 3 minutes.
- `media-gallery-cover.png`: 1600x900 cover image for the Kaggle media gallery.
- `ARTIFACT_MANIFEST.md`: checksums and submission checklist.
- `final-kaggle-writeup.md`: writeup text under 1,500 words.
- `KAGGLE_FORM.md`: copy/paste Kaggle form fields.

The app uses synthetic data only. It shows local ZPK identity registration, DID-style and Android Keystore-backed HMAC-SHA256 recovery artifacts, a signed agent ledger, selective disclosure claims, CUI risk lookup, and Spanish recovery guidance. The package also includes a LiteRT-mode APK for physical-device offline Gemma validation. It includes `.env.example` but not `.env`, and it does not embed a Gemini API key.

The `unsloth/` folder contains the adaptation pipeline: 12,000 validated synthetic Guatemala/LatAm SFT rows, train/validation/test splits, a dataset card, 1,200 RLKD-style teacher traces, SFT LoRA/QLoRA training code, optional GRPO training code, and deterministic safety rewards. No trained adapter is claimed in this dataset.
