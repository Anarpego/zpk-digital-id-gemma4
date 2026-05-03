# On-Device Gemma 4 Runtime Plan

Date: 2026-05-01

## Why ML Kit/AICore Was Unavailable

The current `mlkit-gemma` mode uses Android ML Kit GenAI Prompt API through
system AICore. That path depends on a device-provisioned AICore feature and
model runtime. The available `Medium_Phone_API_36.1` emulator reports
`UNAVAILABLE`, so the app correctly fails closed and falls back locally.

This does not contradict AI Edge Gallery articles showing Gemma 4 running
offline. AI Edge Gallery uses Google AI Edge / LiteRT-LM with downloaded Gemma 4
model artifacts. It is not the same runtime surface as ML Kit Prompt API.

## Implemented Android LiteRT-LM Path

ZPK now includes a Flutter/Android LiteRT-LM bridge using Google AI Edge
`com.google.ai.edge.litertlm:litertlm-android:0.10.2`:

- `KAN_REASONER=litert-gemma`
- `KAN_LITERT_MODEL_PATH=/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm`
- optional `KAN_LITERT_MODEL_URL` for in-app HTTPS model download
- optional `KAN_LITERT_MODEL_SHA256` for hash verification before loading

The app enforces the same `PrivacyGuard` and `AgentResponseContract` used by
hosted Gemma, Cactus, and ML Kit/AICore modes.

## Emulator Result

The Mac emulator accepted the APK, loaded `liblitertlm_jni.so`, memory-mapped
the 2.4 GB Gemma 4 E2B `.litertlm` artifact from app-private storage, created
Gemma 4 runtime settings, and reached `RunPrefillAsync status: OK` plus
`RunDecodeAsync`.

The emulator did not produce final generation because its virtual GPU/OpenCL
stack is incomplete:

```text
model_assets: model_path: /data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm
RunPrefillAsync status: OK
RunDecodeAsync
OpenCL sampler not available
```

## Current Claim Boundary

Until a physical device produces `litert_gemma.generate(...) -> ok` or
`mlkit_gemma.generateContent(...) -> ok`, the submission should claim:

- verified hosted Gemma 4 through `gemma-4-31b-it`
- verified Mac offline LiteRT-LM Gemma 4 E2B generation
- integrated Android LiteRT-LM bridge that loads the Gemma 4 E2B artifact and
  fails closed on the emulator OpenCL limitation
- integrated ML Kit/AICore status probing and fail-closed fallback
- offline local identity workflow with signed ledgers, redacted packets, and
  hash-verified civic threat bulletins

It should not claim successful Android in-app Gemma 4 generation yet.
