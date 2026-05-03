# LiteRT Gemma 4 App Agent Harness

Date: 2026-05-01

Purpose: verify the app uses the offline Gemma 4 agent path before a physical
device run. This is not a substitute for native device inference; it is a
pre-device harness that exercises the Flutter app, LiteRT reasoner, JSON agent
contract, privacy guard, fallback wrapper, and UI trace rendering through a
mocked Android MethodChannel.

Command:

```bash
./scripts/test_litert_agent_harness.sh
```

Result:

```text
All tests passed.
```

Coverage added:

- Runtime panel shows `Motor agente offline`.
- LiteRT status is rendered in app UI:
  `litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> AVAILABLE`.
- The app calls `status`, `warmup`, and `generate` through
  `gt.kan.kan_app/litert_gemma`.
- The returned Gemma JSON is parsed by `AgentResponseContract`.
- The user-facing guidance is taken from the Gemma JSON, not from the local
  deterministic fallback.
- The mocked MethodChannel trace includes
  `litert_gemma.generate(gemma-4-E2B-it-litertlm) -> ok` and
  `agent_contract.schema(json) -> ok`.
- Runtime diagnostics and agent traces are copyable from the UI, so a physical
  phone run can be inspected without USB logcat or screenshots.
- If the reasoner throws, the app stops safely with `Revision detenida`,
  shows the error, and offers `Copiar error` plus retry instead of spinning or
  showing partial guidance.
- If the model is not installed but an HTTPS model URL is configured, the app
  shows `Instalar Gemma offline`, calls `downloadModel`, re-probes status, warms
  the runtime, and records install traces before a citizen case is run.
- If a model file already exists, the Android status path validates the
  configured SHA-256 before marking it `AVAILABLE`; a mismatch reports
  `CORRUPT_MODEL` and blocks generation.

Boundary:

- This harness proves the app consumes agentic Gemma output correctly before
  using a physical device.
- The real Android emulator still fails closed during native generation because
  the virtual GPU/OpenCL stack is unavailable.
- A physical Android device is still required for the final claim:
  `litert_gemma.generate(...) -> ok` from native LiteRT-LM.
