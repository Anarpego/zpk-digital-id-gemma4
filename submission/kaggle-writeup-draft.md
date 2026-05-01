# Kan: Local-First Breach Defense for Guatemalan Citizens

> Draft status: this writeup matches the current working prototype plus planned Gemma 4 integration. Before submission, replace bracketed notes with measured Cactus, Gemma 4, and Unsloth evidence.

## Problem

When a public or private institution leaks personal data in Guatemala, many citizens do not know whether they were affected, what the exposure means, or how to file a useful complaint. The people most harmed by identity theft are often the least served by legal and technical systems: rural users, older adults, and people who need guidance in plain Spanish rather than institutional language.

Kan is an Android-first assistant that turns breach response into three steps: detect, explain, and act. A citizen enters or scans their DPI/CUI, Kan checks a local breach catalog, explains the risk in accessible Spanish, and prepares a preliminary complaint document that stays on the device.

## Gemma 4 Use

Kan is designed around local-first inference plus verified Gemma 4 reasoning. The mobile app has a Cactus-backed reasoner boundary for on-device models, with deterministic mock mode for tests and demos before model download. The routing policy chooses between local tools, a local model, and a future abstract server route. It never sends CUI or personal data by default.

Current verified prototype evidence:

- Offline synthetic CUI verification works on Android.
- The breach catalog is bundled as an offline app asset, not fetched from a server.
- Local tool traces are visible in the UI.
- The app generates Spanish guidance and a complaint preview without a server.
- Cactus Flutter SDK is integrated as an optional adapter.
- Routing decisions show route, confidence, and PII status.
- Hosted Gemma 4 31B IT is integrated into the app path and verified on the Android emulator through the Gemini API.
- Cactus local inference is recorded on the Android emulator with `functiongemma-270m`, tools disabled, and visible TTFT/throughput metrics.

[Before final submission: improve Cactus output quality or present Cactus only as routing/metrics evidence. Do not claim Gemma 4 through Cactus unless a real Gemma 4 Cactus slug is verified.]

## Architecture

Kan prioritizes prize-winning evidence over unnecessary infrastructure. PostgreSQL 18 and Phoenix remain valid for production, but the hackathon demo starts with the strongest story: offline Android functionality that protects privacy even without connectivity.

The current app layers are:

- `LocalBreachCatalog`: bundled synthetic breach lookup with no real PII.
- `RoutingPolicy`: local tools vs local model vs abstract server decision.
- `KanReasoner`: interface shared by deterministic mock, Cactus, and hosted Gemma adapters.
- `LegalTemplateService`: local complaint preview.
- Flutter UI: Spanish-first workflow with visible local mode and tool traces.

The future server only receives abstract case descriptions with PII removed. This keeps the privacy claim concrete instead of rhetorical.

## Training-Free GRPO and Adaptation

Kan uses an experience prior inspired by Training-Free GRPO (`arXiv:2510.08191`) to improve tool-use behavior without paying for fine-tuning on every iteration. The current prior teaches three behaviors: verify locally before asking for data, separate simple explanation from legal steps, and fill documents only on-device.

This gives a cheap iteration loop now. If time allows, Unsloth fine-tuning will create a Gemma 4 adapter for Guatemalan legal Spanish, with a before/after benchmark against the same synthetic cases.

## Impact

Kan targets Digital Equity & Inclusivity because it reduces a complex breach-response process to a clear citizen flow. It also supports Safety & Trust through local-first processing, explicit PII routing, and a future post-quantum credential path with Bacab identity.

The demo story is simple: a citizen discovers their data may be exposed, verifies locally, receives plain Spanish guidance, and walks away with a complaint document ready to print or share.

## Current Limitations

The current repository is not final submission-ready. Hosted Gemma 4 app-mode evidence exists, and Cactus local inference is recorded, but Cactus tool-calling still fails and the small local model output is not good enough for the main demo. Unsloth training artifacts are not yet produced. The public video, public repo, live demo files, and final writeup need to use only measured claims.

Kan is intentionally scoped: one language, one strong Android demo, one citizen story, and no deployment work until the mobile evidence is compelling.
