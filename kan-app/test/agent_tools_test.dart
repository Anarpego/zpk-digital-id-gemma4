import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/agent/tools/classify_case_tool.dart';
import 'package:kan_app/services/agent/tools/draft_denuncia_tool.dart';
import 'package:kan_app/services/agent/tools/draft_sms_familia_tool.dart';
import 'package:kan_app/services/agent/tools/draft_solicitud_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_codigo_penal_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_codigo_trabajo_tool.dart';
import 'package:kan_app/services/agent/tools/lookup_institucion_tool.dart';
import 'package:kan_app/services/agent/tools/redact_pii_tool.dart';
import 'package:kan_app/services/agent/tools/sign_packet_tool.dart';
import 'package:kan_app/services/identity_signer.dart';

void main() {
  group('RedactPiiTool', () {
    final tool = RedactPiiTool();

    test('redacta DPI de 13 digitos', () async {
      final r = await tool.call({'text': 'mi dpi es 1234567890123 ayuda'});
      expect(r.data['categories'], contains('dpi_cui'));
      expect((r.data['redacted_text'] as String), contains('[DPI_REDACTED]'));
      expect(
        (r.data['redacted_text'] as String),
        isNot(contains('1234567890123')),
      );
    });

    test('redacta telefono de 8 digitos', () async {
      final r = await tool.call({'text': 'llamame al 55512345 urgente'});
      expect(r.data['categories'], contains('telefono'));
    });

    test('redacta email', () async {
      final r = await tool.call({'text': 'mi correo es ana@correo.gt'});
      expect(r.data['categories'], contains('email'));
    });

    test('texto limpio no marca categorias', () async {
      final r = await tool.call({'text': 'me llego un mensaje raro'});
      expect((r.data['categories'] as List), isEmpty);
    });
  });

  group('ClassifyCaseTool', () {
    final tool = ClassifyCaseTool();

    test('clasifica extorsion por keywords', () async {
      final r = await tool.call({
        'text': 'me dijeron que me van a matar si no pago, vienen las maras',
      });
      expect(r.data['case_code'], 'extorsion_telefono_sms');
      expect(r.data['confidence'], greaterThan(0.0));
    });

    test('clasifica estafa de remesa', () async {
      final r = await tool.call({
        'text': 'me llego mensaje de Western Union sobre paquete retenido',
      });
      expect(r.data['case_code'], 'estafa_remesa');
    });

    test('clasifica IGSS sin DPI', () async {
      final r = await tool.call({
        'text':
            'perdi mi DPI y necesito atencion en IGSS para mi seguro social',
      });
      expect(r.data['case_code'], 'igss_sin_dpi');
    });

    test('clasifica SAT bloqueado', () async {
      final r = await tool.call({
        'text':
            'me bloqueo SAT y no puedo entrar a la agencia virtual con mi NIT',
      });
      expect(r.data['case_code'], 'sat_acceso_bloqueado');
    });

    test('clasifica despido sin prestaciones', () async {
      final r = await tool.call({
        'text':
            'me corrieron del trabajo sin pagar prestaciones ni liquidacion',
      });
      expect(r.data['case_code'], 'despido_sin_prestaciones');
    });

    test('texto neutro queda como unknown', () async {
      final r = await tool.call({'text': 'hola buen dia hace calor'});
      expect(r.data['case_code'], 'unknown');
    });
  });

  group('LookupCodigoPenalTool', () {
    final tool = LookupCodigoPenalTool();

    test('extorsion devuelve Art. 261', () async {
      final r = await tool.call({'category': 'extorsion'});
      expect(r.data['article'], 'Art. 261');
      expect(r.data['name'], 'Extorsion');
    });

    test('categoria desconocida marca found=false', () async {
      final r = await tool.call({'category': 'inventado'});
      expect(r.data['found'], isFalse);
    });
  });

  group('LookupCodigoTrabajoTool', () {
    final tool = LookupCodigoTrabajoTool();

    test('despido injustificado devuelve articulos', () async {
      final r = await tool.call({'situation': 'despido_injustificado'});
      expect(r.data['articles'], contains('Art. 76'));
    });
  });

  group('LookupInstitucionTool', () {
    final tool = LookupInstitucionTool();

    test('IGSS devuelve telefono y horario', () async {
      final r = await tool.call({'code': 'IGSS'});
      expect(r.data['phone'], '1522');
      expect(r.data['horario'], contains('Lunes'));
    });

    test('codigo desconocido marca found=false', () async {
      final r = await tool.call({'code': 'XYZ'});
      expect(r.data['found'], isFalse);
    });
  });

  group('DraftDenunciaTool', () {
    final tool = DraftDenunciaTool();

    test('genera artifact con fundamento legal cuando hay articulo', () async {
      final r = await tool.call({
        'institucion_destino': 'MINISTERIO PUBLICO',
        'caso_codigo': 'extorsion',
        'narrativa_redactada': 'narrativa redactada de prueba',
        'articulo_cp': 'Art. 261',
        'nombre_articulo': 'Extorsion',
        'pena': 'Prision de 6 a 12 anos',
        'pseudonimo': 'zpk:test',
      });
      expect(r.artifact, isNotNull);
      expect(r.artifact!.contenidoMd, contains('Art. 261'));
      expect(r.artifact!.contenidoMd, contains('Extorsion'));
      expect(r.artifact!.hashSha256, startsWith('sha256:'));
    });

    test('contenido no incluye datos sensibles del input', () async {
      final r = await tool.call({
        'institucion_destino': 'MP',
        'caso_codigo': 'extorsion',
        'narrativa_redactada': 'caso de prueba sin pii',
        'pseudonimo': 'zpk:test',
      });
      expect(r.artifact!.contenidoMd, isNot(contains('1234567890123')));
    });

    test('acepta variantes de campos que produce Gemma 4 on-device', () async {
      final r = await tool.call({
        'institution': 'MINISTERIO PUBLICO',
        'case_code': 'extorsion_telefono_sms',
        'original_text': 'Me amenazan por WhatsApp si no pago hoy.',
        'article': 'Art. 261',
        'name': 'Extorsion',
      });
      expect(r.artifact!.contenidoMd, contains('Me amenazan por WhatsApp'));
      expect(r.artifact!.contenidoMd, contains('Art. 261'));
      expect(r.artifact!.camposClave['caso'], 'extorsion_telefono_sms');
    });
  });

  group('DraftSolicitudTool', () {
    final tool = DraftSolicitudTool();

    test('marca atencion sin DPI cuando aplica', () async {
      final r = await tool.call({
        'institucion': 'IGSS',
        'motivo': 'sin DPI',
        'sin_dpi': true,
        'pseudonimo': 'zpk:test',
      });
      expect(r.artifact!.contenidoMd, contains('sin DPI'));
      expect(r.data['sin_dpi'], isTrue);
    });
  });

  group('DraftSmsFamiliaTool', () {
    final tool = DraftSmsFamiliaTool();

    test('genera sms para extorsion menor a 320 chars', () async {
      final r = await tool.call({'caso_codigo': 'extorsion_telefono_sms'});
      expect(r.artifact, isNotNull);
      expect(r.artifact!.contenidoMd.length, lessThanOrEqualTo(320));
      expect(r.artifact!.contenidoMd, contains('NO'));
    });
  });

  group('SignPacketTool', () {
    final signer = const LocalHmacIdentitySigner(
      issuerKeyId: 'test-key',
      issuerSecret: 'test-secret-strong',
    );
    final tool = SignPacketTool(signer: signer);

    test('firma contenido y devuelve hash + sig', () async {
      final r = await tool.call({'contenido': 'hola mundo'});
      expect(r.data['hash'], startsWith('sha256:'));
      expect((r.data['sig'] as String).length, greaterThan(20));
      expect(r.data['key_id'], 'test-key');
    });

    test('mismo contenido genera misma firma', () async {
      final a = await tool.call({'contenido': 'mismo input'});
      final b = await tool.call({'contenido': 'mismo input'});
      expect(a.data['sig'], b.data['sig']);
    });
  });
}
