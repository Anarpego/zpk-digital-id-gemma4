# Model Privacy Guard Evidence

Date: 2026-05-01

Purpose: make the agentic Gemma paths production-safer by enforcing redaction
in code before any model prompt is sent to hosted Gemma, Cactus local inference,
or ML Kit/AICore on-device Gemma.

## Implemented Controls

- `PrivacyGuard` blocks prompts containing the active raw CUI.
- It also blocks any unredacted 13-digit identifier pattern before generation.
- `ReasonerPromptBuilder` redacts stable local pseudonyms, DID fragments, and
  local proof values before hosted Gemma, Cactus, or ML Kit/AICore can receive
  a prompt.
- Hosted Gemma, Cactus local, and ML Kit/AICore reasoners now call the guard
  before invoking their model backend.
- The default offline demo includes visible guard traces:
  - `privacy_guard.raw_cui -> absent`
  - `privacy_guard.13_digit_identifier -> absent`
  - `privacy_guard.sensitive_terms -> policy_ok`
- If the guard fails, the model call is not made. In wrapped modes, the
  fallback reasoner returns the local deterministic flow.

## Verification

Commands run from `kan-app`:

- `flutter test test/services/privacy_guard_test.dart
  test/services/reasoner_prompt_builder_test.dart
  test/services/gemma_api_reasoner_test.dart test/widget_test.dart`: passed.
- `flutter test test/services/reasoner_prompt_builder_test.dart
  test/services/mlkit_gemma_reasoner_test.dart
  test/services/gemma_api_reasoner_test.dart`: passed after redacting local
  proof material from model prompts.
- `flutter analyze`: passed with no issues.
- `flutter test`: 44 tests passed.

## Non-Claims

This is a local application control, not a replacement for a national data
protection program, institutional audits, or legal review. It proves prompt
redaction enforcement in this app before model execution; it does not prove
successful offline Gemma 4 generation on unsupported emulator hardware.
