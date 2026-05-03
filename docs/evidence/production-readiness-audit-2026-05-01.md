# Production Readiness Audit

Date: 2026-05-01

Objective: remove prototype limits where possible, make ZPK Digital ID behave
like an actual Android app, and strengthen the offline agentic Gemma 4 path for
the Gemma 4 Good Hackathon.

## Checklist

| Requirement | Evidence | Status |
| --- | --- | --- |
| Android app, not only scripts | `kan-app/`, `submission/live-demo/zpk-local-release.apk` | Done |
| Packaged LiteRT app artifact | `submission/live-demo/zpk-litert-release.apk` | Done |
| Local-first identity workflow | DID-style document, local credential, auth proof, recovery packet, revocation, audit archive | Done |
| Agentic workflow, not chatbot only | `agent.plan`, risk classification, privacy route, threat bulletins, signed ledger | Done |
| Offline Gemma 4 evidence | `docs/evidence/litert-gemma4-offline-2026-05-01.md` | Done on Mac |
| Android LiteRT integration | `litertlm-android`, native MethodChannel, status/download/warmup/generate methods | Done |
| Pre-device app proof for Gemma path | `./scripts/test_litert_agent_harness.sh` and app-agent harness evidence | Done |
| Explicit model installation flow | `Instalar Gemma offline`, download, status re-probe, warmup, install traces | Done |
| Model integrity before use | LiteRT status validates configured SHA-256 and reports `CORRUPT_MODEL` on mismatch | Done |
| Physical-device observability | runtime panel, copyable diagnostics, copyable traces, fail-closed error panel | Done |
| Wireless install without cable | Cloudflare/QR installer script and evidence | Done |
| Release build discipline | `./scripts/verify_release_build.sh` and `./scripts/verify_submission.sh` confirm public APKs do not use the Android debug certificate | Done |
| Repeatable CI gates | `.github/workflows/android-ci.yml` runs format, analyze, tests, APK build, LiteRT harness, release-signing gate | Done |
| No raw CUI to model | `PrivacyGuard`, JSON contract tests, evidence traces | Done |
| Submission package gates | `./scripts/package_demo.sh`, `./scripts/verify_submission.sh` | Done |
| Native Android offline generation | physical phone trace with `litert_gemma.generate(...) -> ok` | Blocked |

## Current Blocker

The available physical Android device is a Motorola G15:

```text
ZY32LL9926 device product:lamu_g model:moto_g15 device:lamu
RAM reported by app: 3869007872 bytes
required for Gemma proof: 6000000000 bytes
```

The Motorola installs the full Gemma 4 E2B LiteRT artifact into app-private
storage, but the app correctly reports `DEVICE_LOW_MEMORY` and keeps the
deterministic offline fallback visible. A higher-RAM physical Android device is
required to complete the final native Android offline Gemma 4 generation claim.

## Pass Criteria For Completion

The goal should be considered complete only after a physical phone produces
copyable traces containing:

```text
litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> AVAILABLE
litert_gemma.install.warmup(gemma-4-E2B-it-litertlm) -> READY
litert_gemma.warmup(gemma-4-E2B-it-litertlm) -> READY
litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok
agent_contract.schema(json) -> ok
agent_contract.safety_review(raw_cui=false) -> ok
privacy_guard.raw_cui -> absent
agent_ledger.verify(local) -> ok
```

Until then, the honest claim is: production-style Android app, offline Gemma 4
LiteRT generation on Mac/iOS, Android LiteRT bridge/model-install evidence,
Motorola G15 low-memory guard plus usable offline fallback, and a pre-device app
harness proving the Flutter UI consumes agentic Gemma output.
