# Embedded Offline Catalog Evidence

Date: 2026-05-01

Kan now loads synthetic breach fixtures from `kan-app/assets/breach_catalog.json` instead of relying only on hard-coded Dart maps. The file is bundled through `pubspec.yaml`, loaded by `LocalBreachCatalog.loadEmbeddedOrFallback()`, and cached for the app session.

Privacy claim:

- The asset contains only synthetic CUI values and no real PII.
- CUI verification runs on device.
- The UI tool trace exposes `load_breach_catalog(asset:assets/breach_catalog.json) -> ok` before local breach lookup.
- If asset loading fails, the app falls back to an in-memory synthetic catalog rather than blocking the demo.

Verified gates:

- `cd kan-app && dart format --set-exit-if-changed lib test`: pass.
- `cd kan-app && flutter analyze`: pass.
- `cd kan-app && flutter test`: pass, 15 tests.
- `cd kan-app && flutter build apk --debug`: pass.

Relevant tests:

- `test/services/local_breach_catalog_test.dart` verifies the bundled asset path and a third synthetic record.
- `test/widget_test.dart` verifies the offline demo trace includes the embedded catalog source.
- `kan-app/kan-embedded-catalog-trace.png` shows the live Android UI trace with `load_breach_catalog(asset:assets/breach_catalog.json) -> ok`.
