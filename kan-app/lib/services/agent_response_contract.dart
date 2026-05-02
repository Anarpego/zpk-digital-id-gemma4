import 'dart:convert';

import '../models/kan_case.dart';

class ModelAgentResponse {
  const ModelAgentResponse({
    required this.summary,
    required this.nextSteps,
    required this.trace,
  });

  final String summary;
  final List<String> nextSteps;
  final List<String> trace;
}

class AgentResponseContract {
  const AgentResponseContract();

  ModelAgentResponse parse({
    required String text,
    required VerificationResult result,
  }) {
    final decoded = jsonDecode(_jsonObjectFrom(text));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Agent response must be a JSON object.');
    }
    final summary = _requiredString(decoded, 'summary', result);
    final nationalScaleNote = _requiredString(
      decoded,
      'national_scale_note',
      result,
    );
    final safetyReview = decoded['safety_review'];
    if (safetyReview is! Map<String, dynamic>) {
      throw const FormatException('Agent response missing safety_review.');
    }
    if (safetyReview['raw_cui_included'] != false) {
      throw const FormatException('Agent response failed raw CUI self-check.');
    }
    final nextSteps = _requiredStringList(decoded, 'next_steps', result);
    if (nextSteps.length < 2 || nextSteps.length > 5) {
      throw const FormatException('Agent response needs 2 to 5 next steps.');
    }

    return ModelAgentResponse(
      summary: '$summary\n\n$nationalScaleNote',
      nextSteps: nextSteps,
      trace: const [
        'agent_contract.schema(json) -> ok',
        'agent_contract.safety_review(raw_cui=false) -> ok',
      ],
    );
  }

  String _jsonObjectFrom(String text) {
    final trimmed = text.trim();
    final fenced = RegExp(
      r'```(?:json)?\s*([\s\S]*?)\s*```',
      multiLine: true,
    ).firstMatch(trimmed);
    final candidate = fenced?.group(1)?.trim() ?? trimmed;
    final start = candidate.indexOf('{');
    final end = candidate.lastIndexOf('}');
    if (start == -1 || end <= start) {
      throw const FormatException('Agent response missing JSON object.');
    }
    return candidate.substring(start, end + 1);
  }

  String _requiredString(
    Map<String, dynamic> object,
    String key,
    VerificationResult result,
  ) {
    final value = object[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Agent response missing $key.');
    }
    return _withoutPersonalIdentifier(value.trim(), result);
  }

  List<String> _requiredStringList(
    Map<String, dynamic> object,
    String key,
    VerificationResult result,
  ) {
    final value = object[key];
    if (value is! List) {
      throw FormatException('Agent response missing $key.');
    }
    return value
        .map((item) {
          if (item is! String || item.trim().isEmpty) {
            throw FormatException('Agent response has invalid $key item.');
          }
          return _withoutPersonalIdentifier(item.trim(), result);
        })
        .toList(growable: false);
  }

  String _withoutPersonalIdentifier(String value, VerificationResult result) {
    if (value.contains(result.cui) || RegExp(r'\b\d{13}\b').hasMatch(value)) {
      throw const FormatException('Agent response leaked an identifier.');
    }
    return value;
  }
}
