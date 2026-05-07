# ZPK Digital ID: Offline Gemma 4 Identity Protection for Guatemala

**Selected Impact Track:** Digital Equity & Inclusivity

ZPK Digital ID addresses a national-scale problem: people need digital identity, but vulnerable institutions cannot guarantee that every registry, aid program, employer portal, school, bank, or public service will protect personal data perfectly. In Guatemala, a leaked DPI/CUI can become extortion, fake aid enrollment, SIM abuse, blocked public services, loan fraud, and bureaucratic confusion. ZPK turns that fear into a local phone workflow: explain what happened, let Gemma 4 reason privately, generate the right document, sign it locally, and hand only redacted proof to an institution.

The demo uses only synthetic data. It is not connected to RENAP, IGSS, SAT, Ministerio Publico, banks, or police systems. The product claim is narrower and stronger: an Android citizen/institution app proof that shows a privacy-preserving digital identity workflow can run locally, in Spanish, in low-trust infrastructure conditions.

## What The App Does

The app has a citizen mode and a ventanilla mode. A citizen can describe a problem in plain Spanish: identity recovery, IGSS registration, SAT access, school enrollment, extortion evidence, remittance fraud, suspicious messages, field access, or preventive wallet setup. The citizen does not need to know legal language or security terms.

For the final physical-device proof, the user entered a WhatsApp extortion case: a payment threat and a request for a card photo. On a connected Honor Android device, the release APK ran Gemma 4 E2B locally through LiteRT-LM, classified the case as `extorsion_telefono_sms`, looked up Guatemalan penal context, drafted a formal complaint for `MINISTERIO PUBLICO`, and signed the artifact with Android Keystore. The output card showed a SHA-256 hash and a `Hechos` section describing the WhatsApp threat and card-photo request. The same app can produce a QR-style redacted packet for a local institutional intake screen.

## How Gemma 4 Is Used

Gemma 4 is not used as a generic chatbot. ZPK implements a local ReAct-style agent. The model returns structured JSON tool calls; the app repairs common open-model input mistakes, runs local tools, shows the trace, and rejects unsafe or malformed output. The tool chain includes:

- `redact_pii`: blocks raw identifiers before model reasoning.
- `classify_case`: maps the user story to Guatemala-relevant workflows.
- `lookup_codigo_penal`, `lookup_codigo_trabajo`, `lookup_institucion`: grounded local lookup.
- `draft_denuncia`, `draft_solicitud`, `draft_sms_familia`: concrete documents.
- `sign_packet`: local cryptographic signature.

The final release test exercised this path on device. Gemma repeated some tool calls, which is realistic for a small local model. The loop handled it as a production system should: it kept the best valid artifact, applied a safe close, and invoked `sign_packet` automatically instead of failing or pretending success. This is the difference between a demo chatbot and an app-level agent harness.

## Verified Local Runtime

The submitted citizen APK is:

`submission/live-demo/zpk-citizen-gemma4-release.apk`

SHA-256:

`7eeacdcf57f659e52d0cefa571e0205793ebfa46dcc76c608a4617ef92e63acb`

The installed physical-device `base.apk` hash matched the same value. The model used by the release APK was:

`gemma-4-E2B-it.litertlm`

Size:

`2,583,085,056 bytes`

Model SHA-256:

`ab7838cdfc8f77e54d8ca45eadceb20452d9f01e4bfade03e5dce27911b27e42`

Evidence is included in `docs/evidence/honor-release-citizen-gemma-final-2026-05-07.xml`. It shows `Gemma 4 E2B local`, the tool sequence, Android Keystore signing, and the final complaint document. The release bridge copies the model from Android external app-private storage into internal app storage before LiteRT-LM loads it; this fixed a release-only native crash and makes the model path more reliable.

## Privacy And Trust Architecture

ZPK is local-first. The synthetic CUI/DPI and sensitive text stay on the device. The app includes a local breach/risk catalog, local threat bulletins, local document generation, local verification, and an encrypted audit archive. Hosted services are not required for the demonstrated citizen flow after model installation.

The trust fabric includes a DID-style local identity record, selective disclosure claims, short-lived consent proof, a signed recovery packet, a signed revocation receipt, and a local agent ledger. Release builds use Android Keystore by default for `sign_packet`; tests and debug builds use deterministic local signing so CI remains reproducible. Android hardening disables backup/data extraction, disallows cleartext traffic, and uses `FLAG_SECURE` to reduce accidental data exposure.

The institutional mode is deliberately limited: it verifies and displays redacted packets in a local ventanilla workflow. It does not claim official government integration. That boundary matters because the project is about safer identity infrastructure, not fake production authority.

## Adaptation Work

The repo includes an Unsloth-oriented adaptation pipeline: 12,000 synthetic Guatemala/Latin America SFT examples, 1,200 ReAct teacher traces, deterministic rewards for valid JSON, no PII leakage, offline boundary compliance, and actionable redacted handoff. Scripts are under `unsloth/` and run with `uv`; no system Python is required. I do not claim a trained adapter in the final app because the available 6 GB GPU hit memory limits. The dataset and reward harness are included as reproducible future work, not as a hidden claim.

## Why This Matters

ZPK targets Digital Equity & Inclusivity because the user is a person with little technical background who needs a phone to say: "What happened to me, what paper do I need, what data should not leave, and what can I safely show at a desk?" For Guatemala first, and later Central America and Latin America, this pattern can help people recover identity, report extortion, access public services, and reduce the blast radius of institutional breaches.

The main lesson is practical: local Gemma 4 plus strong app-level tools can turn fragile digital identity into an offline, explainable, citizen-owned workflow. The demo is honest about its limits, but the core engineering is real: a signed Android release, physical-device local Gemma 4 execution, visible tool calls, local signing, redacted packets, and a working citizen-to-institution path.

## Reproducibility

The repository includes the Flutter app, Android LiteRT-LM bridge, tests, synthetic catalogs, evidence files, packaged APKs, video assets, and adaptation data. Current local gates pass:

```bash
dart format lib test
flutter analyze
flutter test
./scripts/package_demo.sh
./scripts/verify_submission.sh
```

The final verifier reports a 100-second video, 1600x900 cover image, valid APK hashes, and a writeup under the 1,500-word limit.
