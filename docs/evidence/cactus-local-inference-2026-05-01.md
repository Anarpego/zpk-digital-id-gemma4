# Cactus Local Inference Evidence

Date: 2026-05-01

Device: Mac-hosted Android emulator `Medium_Phone_API_36.1`.

Build used:

```bash
cd kan-app
flutter build apk --debug \
  --dart-define=KAN_REASONER=cactus \
  --dart-define=KAN_CACTUS_MODEL=functiongemma-270m \
  --dart-define=KAN_CACTUS_ENABLE_TOOLS=false \
  --dart-define=KAN_CACTUS_TIMEOUT_SECONDS=180
```

Result:

- Cactus local completion succeeded with `functiongemma-270m`.
- UI trace screenshot: `kan-app/kan-cactus-270m-notools-trace.png`.
- Trace showed `reasoner_mode(cactus:functiongemma-270m) -> ok`.
- Trace showed `cactus.generateCompletion(local, functiongemma-270m) -> ok`.
- Metrics shown in UI: TTFT `926ms`, total `993ms`, `60.4 tok/s`.

Important limitation:

- The same `functiongemma-270m` run with Cactus tools enabled failed with `completion failed with code -1`.
- Trace screenshot: `kan-app/kan-cactus-270m-trace.png`.
- The successful no-tools response quality was poor (`Miêu chưa.<end_of_turn>`), so this is technical Cactus local-inference evidence, not final user-facing demo evidence.

Submission guidance:

- Claim: ZPK Digital ID can route to Cactus local inference on Android and records local model metrics.
- Do not claim: Cactus tool-calling is working in the app.
- Do not claim: This is Gemma 4 evidence. The verified Cactus catalog entry is FunctionGemma/Gemma 3 family, while Gemma 4 evidence is separately through the hosted `gemma-4-31b-it` path.
