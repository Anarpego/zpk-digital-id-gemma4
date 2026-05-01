import '../models/kan_case.dart';

class PrivacyGuardReport {
  const PrivacyGuardReport({
    required this.isAllowed,
    required this.findings,
    required this.trace,
  });

  final bool isAllowed;
  final List<String> findings;
  final List<String> trace;
}

class PrivacyGuardException implements Exception {
  const PrivacyGuardException(this.findings);

  final List<String> findings;

  @override
  String toString() => 'PrivacyGuardException: ${findings.join(', ')}';
}

class PrivacyGuard {
  const PrivacyGuard();

  static final _digits13 = RegExp(r'(?<!\d)\d{13}(?!\d)');
  static final _sensitiveTerms = RegExp(
    r'\b(cui|dpi|telefono|tel[eé]fono|direccion|direcci[oó]n|correo)\b',
    caseSensitive: false,
  );

  PrivacyGuardReport inspectModelPrompt({
    required String prompt,
    required VerificationResult result,
    required bool allowSensitiveTerms,
  }) {
    final findings = <String>[];
    final compactPrompt = prompt.replaceAll(RegExp(r'\s+'), ' ');

    if (result.cui.isNotEmpty && compactPrompt.contains(result.cui)) {
      findings.add('raw_cui_present');
    }
    if (_digits13.hasMatch(compactPrompt)) {
      findings.add('unredacted_13_digit_identifier');
    }
    if (!allowSensitiveTerms && _sensitiveTerms.hasMatch(compactPrompt)) {
      findings.add('sensitive_terms_present');
    }

    final uniqueFindings = findings.toSet().toList()..sort();
    return PrivacyGuardReport(
      isAllowed: uniqueFindings.isEmpty,
      findings: uniqueFindings,
      trace: [
        'privacy_guard.raw_cui -> ${uniqueFindings.contains('raw_cui_present') ? 'blocked' : 'absent'}',
        'privacy_guard.13_digit_identifier -> ${uniqueFindings.contains('unredacted_13_digit_identifier') ? 'blocked' : 'absent'}',
        'privacy_guard.sensitive_terms -> ${uniqueFindings.contains('sensitive_terms_present') ? 'blocked' : 'policy_ok'}',
      ],
    );
  }

  PrivacyGuardReport requireRedactedModelPrompt({
    required String prompt,
    required VerificationResult result,
    bool allowSensitiveTerms = true,
  }) {
    final report = inspectModelPrompt(
      prompt: prompt,
      result: result,
      allowSensitiveTerms: allowSensitiveTerms,
    );
    if (!report.isAllowed) {
      throw PrivacyGuardException(report.findings);
    }
    return report;
  }
}
