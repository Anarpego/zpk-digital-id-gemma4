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

ZPK Digital ID is a Flutter Android app with a citizen mode and an institutional ventanilla mode. The final release APK runs a local ReAct-style Gemma 4 E2B agent through a native Android LiteRT-LM bridge. The agent emits JSON tool calls, the app repairs common open-model input mistakes, runs local tools, keeps the best valid artifact if Gemma repeats tools, and signs the final packet locally. The verified physical-device flow on an Honor Android phone used `redact_pii`, `classify_case`, `lookup_codigo_penal`, `draft_denuncia`, and `sign_packet` to generate a formal Ministerio Publico complaint for a WhatsApp extortion case, then signed it with Android Keystore. The submitted APK and installed `base.apk` both hash to `7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`; the Gemma model is a 2,583,085,056-byte `gemma-4-E2B-it.litertlm` artifact with SHA-256 `ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`. Offline covers CUI validation, embedded breach lookup, threat bulletins, mission routing, document drafting, local signatures, redacted packet generation, and encrypted audit. The trust fabric includes a DID-style local identity record, selective disclosure claims, consent proof, signed recovery packet, signed revocation receipt, Android privacy hardening, JSON agent contracts, and a privacy guard that blocks raw CUI and 13-digit identifiers before model calls. The adaptation folder includes 12,000 synthetic Guatemala/LatAm SFT examples, 1,200 ReAct teacher traces, and reward code; no trained adapter is claimed.

## Prize Claims

- Main Track: working social-impact Android app with local sensitive-data verification, Spanish guidance, preliminary complaint packet, extortion/economic-fraud/public-service/field-access/coercion modes, physical-device local Gemma 4 E2B evidence, and visible privacy traces.
- Impact Track: Digital Equity & Inclusivity.
- Special Technology Track: claim LiteRT / AI Edge for physical-device local Gemma 4 E2B execution through LiteRT-LM.
- Safety & Trust angle: local privacy guard, redacted packet, Android Keystore signatures, revocation receipt, and safe-close agent loop.
- Unsloth / adaptation: claim dataset, SFT/GRPO scripts, ReAct teacher traces, and quality gates; do not claim a trained adapter unless a larger-GPU run produces adapter artifacts and before/after benchmarks.

## Public Upload Checklist

- [ ] Public GitHub repository URL is reachable without login.
- [ ] Demo ZIP URL is reachable without login.
- [ ] Video URL is reachable without login and plays under 3 minutes.
- [ ] Kaggle writeup is pasted from `submission/final-kaggle-writeup.md`.
- [ ] Media gallery includes `submission/media-gallery-cover.png`.
- [ ] No `.env` or API key is uploaded.
