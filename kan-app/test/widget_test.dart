import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/config/app_config.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/device_presence_gate.dart';
import 'package:kan_app/services/kan_reasoner.dart';
import 'package:kan_app/services/litert_gemma_reasoner.dart';
import 'package:kan_app/services/local_authentication_service.dart';
import 'package:kan_app/services/local_deterministic_reasoner.dart';

import 'package:kan_app/main.dart';
import 'test_identity_fabric.dart';

void main() {
  const litertChannel = MethodChannel('gt.kan.kan_app/litert_gemma');
  const litertJson = '''
{
  "summary": "Gemma 4 local desde prueba Flutter.",
  "next_steps": [
    "Guardar evidencia redactada.",
    "Presentar paquete firmado local."
  ],
  "national_scale_note": "El flujo escala con agentes municipales sin centralizar CUI.",
  "safety_review": {
    "raw_cui_included": false,
    "needs_human_review": true
  }
}
''';

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(litertChannel, null);
  });

  testWidgets('offline app verifies exposed synthetic CUI', (tester) async {
    await tester.pumpWidget(const _TestKanApp());

    expect(find.text('ZPK Digital ID'), findsOneWidget);
    expect(find.text('Wallet local'), findsOneWidget);
    expect(find.text('Persona'), findsOneWidget);
    expect(find.text('Acciones'), findsOneWidget);
    expect(find.text('Institucion'), findsOneWidget);
    expect(find.text('Evidencia'), findsOneWidget);
    expect(find.text('Motor'), findsOneWidget);

    await _tapRegister(tester);
    await tester.pumpAndSettle();
    expect(find.text('Hay riesgo de identidad'), findsOneWidget);

    await _openSection(tester, 'Evidencia');
    expect(find.text('Coincidencia encontrada'), findsOneWidget);
    await _dragUntilFound(
      tester,
      find.textContaining(
        'local_breach_lookup(asset:assets/breach_catalog.json)',
      ),
      const Offset(0, -500),
    );
    expect(
      find.textContaining(
        'local_breach_lookup(asset:assets/breach_catalog.json)',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('trust_fabric.issue_consent(local, 15m)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('privacy_guard.raw_cui -> absent'),
      findsOneWidget,
    );
    expect(
      find.textContaining('threat_bulletin.verify(offline_hash_pack)'),
      findsOneWidget,
    );
    expect(find.textContaining('threat_bulletin.match'), findsOneWidget);
    expect(find.textContaining('agent_ledger.sign'), findsOneWidget);
    expect(
      find.textContaining('agent_ledger.verify(local) -> ok'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Registro ZPK local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Registro ZPK local'), findsOneWidget);

    await _openSection(tester, 'Acciones');
    await _dragUntilFound(
      tester,
      find.text('Prueba agente local'),
      const Offset(0, -300),
    );
    expect(find.text('Agente local ejecuto la guia'), findsOneWidget);
    expect(find.textContaining('herramientas'), findsOneWidget);
    expect(find.text('PII bloqueada'), findsOneWidget);
    expect(find.text('sin JSON modelo'), findsOneWidget);
    expect(find.text('ledger firmado'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Emitir prueba local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapVisibleText(tester, 'Emitir prueba local');
    await tester.pumpAndSettle();
    expect(find.textContaining('auth.sign'), findsOneWidget);
    expect(find.textContaining('auth.verify(local) -> ok'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Revocar credencial local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await _tapVisibleText(tester, 'Revocar credencial local');
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.textContaining('auth.blocked(revocation)'),
      const Offset(0, -500),
    );
    expect(
      find.textContaining('auth.blocked(revocation) -> credential_revoked'),
      findsWidgets,
    );

    await _openSection(tester, 'Evidencia');
    await tester.scrollUntilVisible(
      find.text('Paquete redactado firmado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Paquete redactado firmado'), findsOneWidget);
    expect(find.textContaining('recovery_packet.sign'), findsOneWidget);
    expect(
      find.textContaining('recovery_packet.verify(local) -> ok'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Archivo de auditoria local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Archivo de auditoria local'), findsOneWidget);
    expect(
      find.textContaining('audit_archive.raw_cui -> omitted'),
      findsOneWidget,
    );
    expect(find.textContaining('audit_archive.append'), findsOneWidget);
    await _tapVisibleText(tester, 'Borrar archivo local');
    await tester.pumpAndSettle();
    expect(find.text('Archivo local borrado'), findsOneWidget);
    expect(
      find.textContaining('audit_archive.clear(memory) -> 1'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid CUI stays local and does not generate document', (
    tester,
  ) async {
    await tester.pumpWidget(const _TestKanApp());

    await tester.scrollUntilVisible(
      find.byType(TextField),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    await _tapRegister(tester);
    await _pumpUntilFound(tester, find.text('CUI invalido'));
    await _openSection(tester, 'Evidencia');

    expect(find.text('CUI invalido'), findsOneWidget);
    expect(find.textContaining('No se consulto ningun servidor'), findsWidgets);
    expect(find.text('Denuncia lista'), findsNothing);
  });

  testWidgets('institutional intake works without CUI', (tester) async {
    await tester.pumpWidget(const _TestKanApp());

    await tester.scrollUntilVisible(
      find.text('IGSS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find
          .ancestor(of: find.text('IGSS'), matching: find.byType(ChoiceChip))
          .first,
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.text('CUI opcional'), findsOneWidget);
    expect(find.text('Necesito registrarme o recuperar IGSS'), findsOneWidget);

    await _tapVisibleText(tester, 'Continuar sin CUI');
    await tester.pumpAndSettle();
    await _openSection(tester, 'Institucion');

    expect(find.text('Bandeja IGSS'), findsOneWidget);
    expect(find.text('sin CUI'), findsOneWidget);
    expect(find.text('Ruta de atencion'), findsOneWidget);
    expect(
      find.text('Atender como intake presencial sin credencial'),
      findsOneWidget,
    );
    expect(find.textContaining('igss_registration_agent'), findsNothing);

    await _openSection(tester, 'Evidencia');
    expect(find.text('Sin CUI a mano'), findsOneWidget);
    await _dragUntilFound(
      tester,
      find.textContaining('igss_registration_agent'),
      const Offset(0, -500),
    );
    expect(find.textContaining('igss_registration_agent'), findsOneWidget);
  });

  testWidgets('authentication proof denial fails closed in UI', (tester) async {
    await tester.pumpWidget(const _DeniedAuthKanApp());

    await _tapRegister(tester);
    await tester.pumpAndSettle();
    await _tapVisibleText(tester, 'Emitir prueba local');
    await tester.pumpAndSettle();

    expect(find.textContaining('No se emitio la prueba'), findsOneWidget);
    expect(
      find.textContaining('auth.device_presence(android-keyguard) -> denied'),
      findsOneWidget,
    );
    expect(find.textContaining('auth.sign'), findsNothing);
  });

  testWidgets('reasoner failure stops safely and exposes diagnostics', (
    tester,
  ) async {
    await tester.pumpWidget(const _ThrowingKanApp());

    await _tapRegister(tester);
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.text('Revision detenida'),
      const Offset(0, -300),
    );

    expect(find.text('Revision detenida'), findsOneWidget);
    expect(find.textContaining('LiteRT native decode failed'), findsOneWidget);
    expect(find.text('Copiar error'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('LiteRT Gemma mode shows runtime status and uses agent JSON', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(litertChannel, (call) async {
          return switch (call.method) {
            'status' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
              'modelSizeBytes': 2400000000,
            },
            'warmup' => {'status': 'READY', 'model': 'gemma-4-E2B-it-litertlm'},
            'generate' => {
              'text': litertJson,
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await tester.pumpWidget(const _LiteRtKanApp());
    await tester.pumpAndSettle();

    await _openSection(tester, 'Motor');

    expect(find.text('Motor agente offline'), findsOneWidget);
    expect(
      find.textContaining(
        'litert_gemma.runtime_status(gemma-4-E2B-it-litertlm) -> AVAILABLE',
      ),
      findsOneWidget,
    );
    expect(find.text('Copiar diagnostico'), findsOneWidget);
    expect(find.text('Probar Gemma offline'), findsOneWidget);

    await _tapVisibleText(tester, 'Probar Gemma offline');
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.textContaining('Gemma 4 genero JSON valido offline'),
      const Offset(0, -300),
    );

    expect(
      find.textContaining('Gemma 4 genero JSON valido offline'),
      findsOneWidget,
    );
    expect(
      find.textContaining('privacy_guard.self_test_raw_cui -> absent'),
      findsOneWidget,
    );

    await _openSection(tester, 'Persona');
    await _tapRegister(tester);
    await tester.pumpAndSettle();
    await _openSection(tester, 'Evidencia');
    await _dragUntilFound(
      tester,
      find.text('Prueba agente local'),
      const Offset(0, -300),
    );
    expect(find.text('Gemma 4 ejecuto la guia'), findsOneWidget);
    expect(find.text('PII bloqueada'), findsOneWidget);
    expect(find.text('JSON validado'), findsOneWidget);
    expect(find.text('ledger firmado'), findsOneWidget);
    await _dragUntilFound(
      tester,
      find.textContaining('Gemma 4 local desde prueba Flutter.'),
      const Offset(0, -500),
    );

    expect(
      find.textContaining('Gemma 4 local desde prueba Flutter.'),
      findsOneWidget,
    );
    await _dragUntilFound(
      tester,
      find.textContaining('litert_gemma.generate(gemma-4-E2B-it-litertlm)'),
      const Offset(0, -300),
    );
    expect(
      find.textContaining('litert_gemma.generate(gemma-4-E2B-it-litertlm)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('agent_contract.schema(json) -> ok'),
      findsOneWidget,
    );
    await _dragUntilFound(
      tester,
      find.text('Copiar trazas'),
      const Offset(0, -300),
    );
    expect(find.text('Copiar trazas'), findsOneWidget);
  });

  testWidgets('LiteRT Gemma mode installs downloadable runtime before a case', (
    tester,
  ) async {
    var statusCalls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(litertChannel, (call) async {
          return switch (call.method) {
            'status' => {
              'status': statusCalls++ < 2 ? 'MISSING_MODEL' : 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
            },
            'downloadModel' => {
              'status': 'AVAILABLE',
              'model': 'gemma-4-E2B-it-litertlm',
              'sha256': 'ab7838',
              'bytes': 2583085056,
            },
            'warmup' => {'status': 'READY', 'model': 'gemma-4-E2B-it-litertlm'},
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await tester.pumpWidget(const _LiteRtKanApp());
    await tester.pumpAndSettle();

    await _openSection(tester, 'Motor');

    expect(find.text('Instalar Gemma offline'), findsOneWidget);
    await _tapVisibleText(tester, 'Instalar Gemma offline');
    await tester.pumpAndSettle();
    await _dragUntilFound(
      tester,
      find.textContaining('Gemma 4 quedo instalado y calentado'),
      const Offset(0, -300),
    );

    expect(
      find.textContaining('Gemma 4 quedo instalado y calentado'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'litert_gemma.install.warmup(gemma-4-E2B-it-litertlm) -> READY',
      ),
      findsOneWidget,
    );
  });

  testWidgets('LiteRT Gemma emulator guard does not offer dead-end actions', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(litertChannel, (call) async {
          return switch (call.method) {
            'status' => {
              'status': 'EMULATOR_UNSUPPORTED',
              'model': 'gemma-4-E2B-it-litertlm',
              'modelSizeBytes': 2583085056,
              'runtimeGuard': 'android-emulator-native-litertlm',
            },
            _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
          };
        });

    await tester.pumpWidget(const _LiteRtKanApp());
    await tester.pumpAndSettle();

    await _openSection(tester, 'Motor');

    expect(find.text('EMULATOR_UNSUPPORTED'), findsOneWidget);
    expect(find.text('modelo instalado'), findsOneWidget);
    expect(find.text('Instalar Gemma offline'), findsNothing);
    expect(find.text('Probar Gemma offline'), findsNothing);
    expect(
      find.textContaining('Use un dispositivo ARM64 fisico'),
      findsOneWidget,
    );
  });

  testWidgets(
    'LiteRT Gemma low-memory guard exposes fallback without self-test',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(litertChannel, (call) async {
            return switch (call.method) {
              'status' => {
                'status': 'DEVICE_LOW_MEMORY',
                'model': 'gemma-4-E2B-it-litertlm',
                'modelSizeBytes': 2583085056,
                'deviceRamBytes': 3869007872,
                'requiredRamBytes': 6000000000,
              },
              _ => throw PlatformException(code: 'NOT_IMPLEMENTED'),
            };
          });

      await tester.pumpWidget(const _LiteRtKanApp());
      await tester.pumpAndSettle();

      await _openSection(tester, 'Motor');

      expect(find.text('DEVICE_LOW_MEMORY'), findsOneWidget);
      expect(find.text('hardware limitado'), findsOneWidget);
      expect(find.text('Instalar Gemma offline'), findsNothing);
      expect(find.text('Probar Gemma offline'), findsNothing);
      expect(
        find.textContaining('Respaldo offline disponible'),
        findsOneWidget,
      );
      expect(
        find.textContaining('runtime.local_deterministic -> ready'),
        findsOneWidget,
      );
      expect(
        find.textContaining('runtime.network_required -> false'),
        findsOneWidget,
      );
    },
  );
}

class _TestKanApp extends StatelessWidget {
  const _TestKanApp();

  @override
  Widget build(BuildContext context) => const KanApp(
    reasoner: LocalDeterministicReasoner(identityFabric: testIdentityFabric),
    identityFabric: testIdentityFabric,
    authenticationService: LocalAuthenticationService(
      identityFabric: testIdentityFabric,
      devicePresenceGate: BypassDevicePresenceGate(),
    ),
  );
}

class _DeniedAuthKanApp extends StatelessWidget {
  const _DeniedAuthKanApp();

  @override
  Widget build(BuildContext context) => const KanApp(
    reasoner: LocalDeterministicReasoner(identityFabric: testIdentityFabric),
    identityFabric: testIdentityFabric,
    authenticationService: LocalAuthenticationService(
      identityFabric: testIdentityFabric,
      devicePresenceGate: _DeniedDevicePresenceGate(),
    ),
  );
}

class _LiteRtKanApp extends StatelessWidget {
  const _LiteRtKanApp();

  @override
  Widget build(BuildContext context) => const KanApp(
    config: AppConfig(
      reasonerMode: ReasonerMode.litertGemma,
      cactusModel: 'functiongemma-270m-pro',
      cactusTimeoutSeconds: 45,
      cactusEnableTools: true,
      geminiApiKey: '',
      geminiModel: 'gemma-4-31b-it',
      mlKitTimeoutSeconds: 120,
      litertModelPath:
          '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
      litertModelUrl: 'https://example.test/models/gemma-4-E2B-it.litertlm',
      litertModelSha256: 'ab7838',
      litertTimeoutSeconds: 180,
      flutterGemmaModelUrl:
          'https://example.test/models/gemma-4-E2B-it.litertlm',
      flutterGemmaModelId: 'gemma-4-E2B-it.litertlm',
      flutterGemmaTimeoutSeconds: 300,
    ),
    identityFabric: testIdentityFabric,
    reasoner: FallbackReasoner(
      primary: LiteRtGemmaReasoner(
        modelPath:
            '/data/user/0/gt.kan.kan_app/files/models/gemma-4-E2B-it.litertlm',
        modelUrl: 'https://example.test/models/gemma-4-E2B-it.litertlm',
        modelSha256: 'ab7838',
        identityFabric: testIdentityFabric,
      ),
      fallback: LocalDeterministicReasoner(identityFabric: testIdentityFabric),
      primaryLabel: 'litert-gemma:gemma-4-e2b-it',
    ),
    authenticationService: LocalAuthenticationService(
      identityFabric: testIdentityFabric,
      devicePresenceGate: BypassDevicePresenceGate(),
    ),
  );
}

class _ThrowingKanApp extends StatelessWidget {
  const _ThrowingKanApp();

  @override
  Widget build(BuildContext context) => const KanApp(
    reasoner: _ThrowingReasoner(),
    identityFabric: testIdentityFabric,
    authenticationService: LocalAuthenticationService(
      identityFabric: testIdentityFabric,
      devicePresenceGate: BypassDevicePresenceGate(),
    ),
  );
}

class _ThrowingReasoner implements KanReasoner {
  const _ThrowingReasoner();

  @override
  Future<ReasonedGuidance> explain({
    required VerificationResult result,
    required CaseScenario scenario,
  }) async {
    throw StateError('LiteRT native decode failed: OpenCL sampler unavailable');
  }
}

class _DeniedDevicePresenceGate implements DevicePresenceGate {
  const _DeniedDevicePresenceGate();

  @override
  Future<DevicePresenceResult> verify({required String reason}) async =>
      const DevicePresenceResult(
        verified: false,
        method: 'android-keyguard',
        trace: ['auth.device_presence(android-keyguard) -> denied'],
      );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> _tapRegister(WidgetTester tester) async {
  await _openSection(tester, 'Persona');
  final button = find.text('Ayudarme ahora');
  await tester.scrollUntilVisible(
    button,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button, warnIfMissed: false);
}

Future<void> _openSection(WidgetTester tester, String label) async {
  final section = find.text(label).last;
  await tester.tap(section, warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _tapVisibleText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  final centers = <String>[];
  for (var i = 0; i < 24; i++) {
    if (finder.evaluate().isEmpty) {
      centers.add('missing');
      await tester.dragFrom(const Offset(400, 300), const Offset(0, -300));
      await tester.pumpAndSettle();
      continue;
    }
    final button = find.ancestor(
      of: finder,
      matching: find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
    );
    final target = button.evaluate().isEmpty ? finder : button.last;
    final center = tester.getCenter(target);
    centers.add(center.toString());
    if (center.dy > 40 && center.dy < 500) {
      await tester.tap(target, warnIfMissed: false);
      return;
    }
    await tester.dragFrom(
      const Offset(400, 300),
      center.dy >= 500 ? const Offset(0, -160) : const Offset(0, 160),
    );
    await tester.pumpAndSettle();
  }
  final visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail(
    'Expected visible text button "$text". Centers: ${centers.join(' -> ')}. Visible text: $visibleTexts',
  );
}

Future<void> _dragUntilFound(
  WidgetTester tester,
  Finder finder,
  Offset offset,
) async {
  for (var i = 0; i < 12; i++) {
    await tester.drag(find.byType(ListView), offset);
    await tester.pumpAndSettle();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  final visibleTexts = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail('Expected to find $finder after dragging. Visible text: $visibleTexts');
}
