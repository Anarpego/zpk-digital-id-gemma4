# Repository Guidelines

## Project Structure & Module Organization

This workspace contains `kan.md`, the implementation brief, and the active Flutter prototype in `kan-app/`. Prioritize demo reliability, privacy proof, and prize evidence.

Current layout:
- `kan-app/lib/`: Flutter app code. Put screens under `lib/features/`, services under `lib/services/`, models under `lib/models/`, and configuration under `lib/config/`.
- `kan-app/test/`: widget and service tests.
- `docs/`: technical evidence, routing notes, and model/API verification.
- `submission/`: Kaggle writeup, video script, and demo runbook drafts.
- Future `kan-server/`: Phoenix API code under `lib/kan/` and `lib/kan_web/`, migrations under `priv/repo/migrations/`, and tests under `test/`.

## Build, Test, and Development Commands

- `cd kan-app && flutter pub get`: install Flutter dependencies.
- `cd kan-app && dart format lib test`: format Dart code.
- `cd kan-app && flutter analyze`: run static analysis.
- `cd kan-app && flutter test`: run widget and service tests.
- `cd kan-app && flutter run`: run on the Mac Android emulator or a connected device.

Future server commands (`make dev-up`, `mix test`, `mix format`) apply only after `kan-server/` exists.

## Coding Style & Naming Conventions

Dart follows Effective Dart, strong null safety, and `dart format`. Use snake_case files, `PascalCase` classes, and `camelCase` members. Keep Spanish UI text clear.

Elixir code should use `mix format`, `Kan.`/`KanWeb.` namespaces, and `@doc`/`@spec` for public APIs. Migrations use `YYYYMMDDHHMMSS_description.exs`.

When adding dependencies, verify current stable versions and use the latest compatible release. Python tooling must run in a virtual environment; prefer `uv venv` and `uv run`, never system Python.

## Testing Guidelines

Add tests for new behavior. Flutter tests cover routing, reasoner selection, local breach lookup, generated guidance, and UI flows. Tests must not call real LLM APIs; use mocks or fixtures. Server tests, when added, should use ExUnit, Phoenix test helpers, and mocked AI clients.

## Commit & Pull Request Guidelines

Git history uses prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, and `chore:`. Keep commits focused and mention artifact changes when hashes, videos, APKs, or submission files regenerate.

PRs should include a focused summary, tests run, screenshots for UI changes, linked issue or task, and notes for privacy, security, or LLM-behavior changes.

## Security & Configuration Tips

Do not commit secrets, API keys, real PII, breach data, or generated private keys. Keep local secrets in `.env`-style files and document required variables without values. Post-quantum credential security is relevant to the future trust story, but it should not block the offline CUI verification MVP.
