# Kaggle Submission Fields

Use these fields for the final Kaggle submission. Fill the URL fields only after the public repository, submission ZIP, and video have been uploaded.

## Title

ZPK Digital ID: Local-First Identity Protection for Guatemala

## Subtitle

An Android-first digital identity wallet that helps citizens register, recover access, and hand off redacted proof to institutions such as IGSS, SAT, and schools while protecting CUI/DPI data with local Gemma 4 reasoning and Android Keystore-signed proofs.

## Impact Track

Digital Equity & Inclusivity

## Repository URL

Paste the public GitHub repository URL after upload.

## Live Demo URL

Paste the public submission ZIP, release asset, or Kaggle Dataset URL after upload.

Recommended artifact: `submission/dist/kan-demo-package-final.zip`.

## Video URL

Paste the public video URL after upload.

Recommended artifact: `submission/kan-final-demo-video.mp4`.

## Short Summary

ZPK Digital ID targets a national-scale problem: citizens need digital identity and authentication, but vulnerable countries cannot assume every registry, aid program, employer portal, bank, telco, or institution will protect personal data perfectly. The app gives both a citizen view and an institutional intake view. A person can choose IGSS registration/recovery, SAT access/update, school or university enrollment, identity recovery, extortion evidence, economic fraud/remittances, public-service recovery, field access, coercion safety, suspicion, or prevention. With a synthetic CUI, ZPK creates a pseudonymous local credential and signed redacted packet. Without a CUI, institution flows generate only checklist and intake, not a false credential.

## Technical Summary

ZPK Digital ID is a Flutter Android app with five reasoner modes: deterministic local mode for reliable offline operation, Cactus local mode for on-device model-routing evidence, hosted Gemma 4 mode verified with `gemma-4-31b-it`, ML Kit/AICore mode that includes ML Kit/AICore status probing plus model download/warmup before generation and fails closed on the Mac emulator when GenAI is unavailable, and Android LiteRT-LM mode that loads the Gemma 4 E2B artifact from app-private storage. It also includes real offline Gemma 4 E2B smoke paths on Mac LiteRT-LM with `HF_HUB_OFFLINE=1` and iOS/Apple Silicon FlutterGemma, plus a LiteRT app-agent harness that proves the Flutter app renders Gemma JSON guidance and LiteRT generation traces through the Android channel. On a physical Motorola G15, the APK installed the 2,583,085,056-byte model into app-private storage and reported `DEVICE_LOW_MEMORY` because the phone has 3.86 GB RAM versus the app's 6 GB generation safety gate; the Motor view now shows `Respaldo offline disponible`, `runtime.local_deterministic -> ready`, and `runtime.network_required -> false` instead of pretending Gemma generated it. Offline covers CUI validation, embedded breach lookup, 8/8 hash-verified threat bulletins, mission routing, identity proofs, authentication, revocation, redacted packet generation, and encrypted audit. The trust fabric includes a DID-style document, Android Keystore-backed HMAC-SHA256 recovery credential, Android device-presence-gated verifier-enforced allowlisted expiring local authentication proof, signed SHA-256 agent ledger, signed redacted recovery packet, revocation receipt, selective disclosure, 15-minute consent proof, Android privacy hardening, citizen-clearable app-internal audit archive sealed with AES-GCM and Android Keystore, validated JSON agent-response contracts, and a privacy guard that blocks raw CUI and 13-digit identifiers before any model. The adaptation pipeline includes 12,000 validated synthetic Guatemala/LatAm SFT examples, 1,200 structured RLKD-style teacher traces, SFT LoRA/QLoRA code, optional GRPO code, and deterministic rewards for JSON validity, no PII leakage, offline boundary, and redacted handoff.

## Prize Claims

- Main Track: working social-impact Android app with local sensitive-data verification, Spanish guidance, preliminary complaint packet, extortion/economic-fraud/public-service/field-access/coercion modes, hosted Gemma 4 evidence, LiteRT-LM offline Gemma 4 evidence, and visible privacy traces.
- Impact Track: Digital Equity & Inclusivity.
- Cactus special prize: claim cautiously as partial local-inference/routing evidence only.
- Offline Gemma 4: claim LiteRT-LM local generation on Mac, iOS/Apple Silicon FlutterGemma evidence, Android LiteRT-LM bridge/model-install evidence, and Motorola G15 `DEVICE_LOW_MEMORY` safety gate; do not claim successful Android in-app generation unless a higher-RAM physical device produces `litert_gemma.generate(...) -> ok`.
- Unsloth / adaptation: claim dataset, SFT/GRPO scripts, RLKD-style teacher traces, and quality gates; do not claim a trained adapter unless the Linux GPU run produces adapter artifacts and before/after benchmarks.

## Public Upload Checklist

- [ ] Public GitHub repository URL is reachable without login.
- [ ] Demo ZIP URL is reachable without login.
- [ ] Video URL is reachable without login and plays under 3 minutes.
- [ ] Kaggle writeup is pasted from `submission/final-kaggle-writeup.md`.
- [ ] Media gallery includes `submission/media-gallery-cover.png`.
- [ ] No `.env` or API key is uploaded.
