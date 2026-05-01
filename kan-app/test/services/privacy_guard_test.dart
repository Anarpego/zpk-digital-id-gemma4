import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/privacy_guard.dart';

void main() {
  test('allows redacted model prompts and records policy trace', () {
    final result = LocalBreachCatalog().verify('1234567890101');
    final report = const PrivacyGuard().requireRedactedModelPrompt(
      prompt:
          'coincidencias_locales=1; ciudadano=zpk-gt-aabb; escenario=victim',
      result: result,
    );

    expect(report.isAllowed, isTrue);
    expect(report.findings, isEmpty);
    expect(report.trace, contains('privacy_guard.raw_cui -> absent'));
    expect(
      report.trace,
      contains('privacy_guard.13_digit_identifier -> absent'),
    );
  });

  test('blocks raw CUI or unredacted 13 digit identifiers', () {
    final result = LocalBreachCatalog().verify('1234567890101');

    expect(
      () => const PrivacyGuard().requireRedactedModelPrompt(
        prompt: 'Enviar CUI 1234567890101 al modelo.',
        result: result,
      ),
      throwsA(
        isA<PrivacyGuardException>().having(
          (error) => error.findings,
          'findings',
          containsAll(['raw_cui_present', 'unredacted_13_digit_identifier']),
        ),
      ),
    );
  });

  test('can fail stricter policies on sensitive identity terms', () {
    final result = VerificationResult(
      cui: '9999999999999',
      matches: const [],
      checkedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    final report = const PrivacyGuard().inspectModelPrompt(
      prompt: 'telefono redactado',
      result: result,
      allowSensitiveTerms: false,
    );

    expect(report.isAllowed, isFalse);
    expect(report.findings, contains('sensitive_terms_present'));
  });
}
