import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/agent/tool_input_repair.dart';
import 'package:kan_app/services/agent/tools/classify_case_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_codigo_penal_tool.dart';
import 'package:kan_app/services/agent/tools/redact_pii_tool.dart';

void main() {
  final repair = ToolInputRepair();

  group('passthrough', () {
    test('input ya bien formado pasa sin cambios', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: {'text': 'hola'});
      expect(out.kind, RepairKind.passthrough);
      expect(out.input, {'text': 'hola'});
    });
  });

  group('bare-string-wrap', () {
    test('redact_pii recibe string -> wrap como {text: string}', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: 'me amenazan');
      expect(out.kind, RepairKind.repaired);
      expect(out.input, {'text': 'me amenazan'});
      expect(out.notes.first, 'wrapped_bare_string_as_text');
    });

    test('classify_case recibe string -> wrap como {text: string}', () {
      final out = repair.repair(
        tool: ClassifyCaseTool(),
        raw: 'me dijieron que me van a matar si no pago',
      );
      expect(out.kind, RepairKind.repaired);
      expect(out.input!['text'], 'me dijieron que me van a matar si no pago');
    });

    test(
      'lookup_codigo_penal recibe string -> wrap como {category: string}',
      () {
        final out = repair.repair(
          tool: LookupCodigoPenalTool(),
          raw: 'extorsion',
        );
        expect(out.kind, RepairKind.repaired);
        expect(out.input, {'category': 'extorsion'});
      },
    );
  });

  group('stringified-json-parse', () {
    test('string que es JSON valido se parsea', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: '{"text":"foo"}');
      expect(out.kind, RepairKind.repaired);
      expect(out.input, {'text': 'foo'});
      expect(out.notes.first, 'parsed_stringified_json_object');
    });
  });

  group('singleton-array-unwrap', () {
    test('lista de un elemento -> unwrap a primary key', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: ['hola']);
      expect(out.kind, RepairKind.repaired);
      expect(out.input, {'text': 'hola'});
    });
  });

  group('null-input', () {
    test('null se reemplaza con object vacio', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: null);
      expect(out.kind, RepairKind.repaired);
      expect(out.input, isEmpty);
    });
  });

  group('unrepairable', () {
    test('numero solo es unrepairable', () {
      final out = repair.repair(tool: RedactPiiTool(), raw: 42);
      expect(out.kind, RepairKind.unrepairable);
      expect(out.ok, isFalse);
    });
  });
}
