# 3-Minute Video Script Draft

> Draft status: update the model benchmark lines after real Cactus and Gemma 4 testing.

## 0:00-0:20 Problem

Show a phone in Spanish.

Voiceover: "When personal data leaks, the hardest question for many citizens is not technical. It is: am I affected, what does it mean, and what do I do today?"

Visual: headline-style breach context, then a citizen holding a DPI without exposing real personal data.

## 0:20-0:55 Kan Flow

Open Kan on Android. Show "Modo local".

Voiceover: "Kan checks a local breach catalog on the device. The CUI is not sent to a server."

Enter synthetic CUI `1234567890101`. Tap "Verificar y generar guia".

Show result: "Coincidencia encontrada".

## 0:55-1:30 Local Model / Gemma 4 Evidence

Show routing chips: "Modelo local" and confidence. Then cut to hosted mode showing "Gemma 4 API" and the trace line `gemma_api.generateContent(gemma-4-31b-it) -> ok`.

Voiceover: "Kan routes tasks. Simple checks stay in local tools. Explanations can use a local model. Hosted Gemma 4 31B IT is available for richer reasoning, and the trace records exactly which path ran."

[Final video: insert measured Cactus local-model clip if successful. Keep Gemma 4 API evidence separate from Cactus evidence.]

## 1:30-2:05 Action

Scroll to "Guia de accion" and "Denuncia lista".

Voiceover: "The user receives plain Spanish steps and a preliminary complaint document. Personal data is filled locally."

Show tool trace:

- `verify_dpi_in_local_leaks(local)`
- `load_breach_catalog(asset:assets/breach_catalog.json)`
- `routing_decision(local_model)`
- `fill_legal_template(local)`

## 2:05-2:35 Adaptation

Show a short side-by-side: base prompt behavior vs Kan experience prior.

Voiceover: "We use a Training-Free GRPO-style experience prior to improve tool use before expensive fine-tuning. If time allows, the same cases become an Unsloth dataset for a Guatemalan legal Spanish adapter."

## 2:35-3:00 Impact

Show the generated document and the local-mode badge again.

Voiceover: "Kan is built for Digital Equity and Safety: Spanish-first, Android-first, offline-first, and designed so privacy is visible. A citizen does not leave with a chatbot answer. They leave with the next action."
