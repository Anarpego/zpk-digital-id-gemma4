# Final Video Script

Target length: 2:45-2:55.

Raw app footage: `submission/video-raw/kan-demo-flow.mp4`.

## 0:00-0:18 Problem

Visual: cover image, phone with Kan.

Voiceover:
When personal data leaks, many citizens are left with three questions: am I affected, what does it mean, and what do I do today? Kan is a local-first Android assistant for that moment.

## 0:18-0:50 Offline Check

Visual: app home screen, `Modo local`, synthetic CUI `1234567890101`.

Voiceover:
The demo uses synthetic data only. Kan loads an embedded breach catalog on the device. The CUI is checked locally, not sent to a server. When there is a match, the user sees plain Spanish instead of technical breach jargon.

## 0:50-1:20 Action

Visual: `Coincidencia encontrada`, `Guia de accion`, complaint draft.

Voiceover:
Kan does not stop at a chatbot answer. It creates next steps and a preliminary complaint draft the citizen can review, print, or share with someone they trust.

## 1:20-1:55 Gemma 4 And Routing

Visual: hosted Gemma 4 trace screenshot, routing/tool traces.

Voiceover:
For richer reasoning, Kan has a hosted Gemma 4 mode verified with `gemma-4-31b-it`. The routing trace records which path ran and whether personal data was sent. By default, sensitive checks stay local.

## 1:55-2:20 Cactus And Adaptation

Visual: Cactus local metrics screenshot, Unsloth scaffold files.

Voiceover:
The app also integrates Cactus for local model routing. Current Cactus evidence shows local inference metrics on Android, while tool-calling remains a known limitation. For adaptation, Kan includes a Training-Free GRPO-style experience prior and an Unsloth fine-tuning scaffold for Guatemalan legal Spanish.

## 2:20-2:50 Impact

Visual: generated document, local-mode badge, final cover.

Voiceover:
Kan targets Digital Equity and Safety. It is Spanish-first, Android-first, offline-first, and designed so privacy is visible. The goal is simple: help a citizen move from fear to a concrete next action.
