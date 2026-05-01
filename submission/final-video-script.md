# Final Video Script

Target length: under 3:00.

Raw app footage: `submission/video-raw/zpk-demo-flow.mp4`.
Rendered video: `submission/kan-final-demo-video.mp4`.
Narration text: `submission/final-video-narration.txt`.

## 0:00-0:18 Problem

Visual: cover image, phone with ZPK Digital ID.

Voiceover:
In Guatemala, digital identity must work even when institutions, aid programs, or employer portals leak personal data. ZPK Digital ID is a local-first Android wallet for that reality.

## 0:18-0:50 Offline Check

Visual: app home screen, `Wallet local`, synthetic CUI `1234567890101`.

Voiceover:
The demo uses synthetic data only. A citizen enters a test CUI, and ZPK registers a pseudonymous identity on the device. The raw CUI is not sent to a server.

## 0:50-1:20 Action

Visual: `Registro ZPK local`, DID-style credential, selective disclosure claims.

Voiceover:
The local agent checks risk, chooses a privacy route, and creates a DID-style document, an HMAC-SHA256-signed recovery credential, selective disclosure claims, and a 15-minute consent proof.

## 1:20-1:55 Gemma 4 And Routing

Visual: hosted Gemma 4 trace screenshot, routing/tool traces.

Voiceover:
For richer reasoning, ZPK has a hosted Gemma 4 mode verified with `gemma-4-31b-it`. The prompt receives redacted facts, not the raw CUI. The trace records which tools ran and whether personal data stayed local.

## 1:55-2:20 Cactus And Adaptation

Visual: Cactus local metrics screenshot, Unsloth scaffold files.

Voiceover:
The app also integrates Cactus for local model routing. Current Cactus evidence shows local inference metrics on Android, while tool-calling remains a known limitation. For adaptation, ZPK includes a Training-Free GRPO-style experience prior and an Unsloth fine-tuning scaffold for Guatemalan legal Spanish.

## 2:20-2:50 Impact

Visual: generated document, local-mode badge, final cover.

Voiceover:
ZPK targets Digital Equity and Safety. It is Spanish-first, Android-first, offline-first, and designed so privacy is visible. This is an offline testbed for safer national digital identity in Guatemala and a pattern that can extend across Latin America.
