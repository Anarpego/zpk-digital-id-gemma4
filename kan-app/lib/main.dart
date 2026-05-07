import 'package:flutter/material.dart';

import 'config/app_config.dart';
import 'features/citizen/citizen_home.dart';
import 'features/identity_wallet/home_screen.dart';
import 'features/institution/ventanilla_home.dart';
import 'services/agent/agent_reasoner.dart';
import 'services/agent/default_tool_registry.dart';
import 'services/agent/litert_gemma_agent_reasoner.dart';
import 'services/agent/tool_registry.dart';
import 'services/audit_archive.dart';
import 'services/local_authentication_service.dart';
import 'services/digital_identity_fabric.dart';
import 'services/reasoner_factory.dart';

/// Pantallas de inicio soportadas. Se selecciona por dart-define
/// `KAN_HOME=citizen` o `KAN_HOME=classic` (default classic para no romper
/// el verificador UIAutomator existente).
enum HomeMode { classic, citizen }

const _homeModeRaw = String.fromEnvironment(
  'KAN_HOME',
  defaultValue: 'classic',
);
const HomeMode kHomeMode = _homeModeRaw == 'citizen'
    ? HomeMode.citizen
    : HomeMode.classic;

void main() {
  const config = AppConfig.fromEnvironment();
  const identityFabric = DigitalIdentityFabric.device();
  final reasoner = const ReasonerFactory(
    identityFabric: identityFabric,
  ).build(config);
  final toolRegistry = buildDefaultToolRegistry();
  final agentReasoner = _buildAgentReasoner(config, toolRegistry);
  runApp(
    KanApp(
      config: config,
      reasoner: reasoner,
      agentReasoner: agentReasoner,
      toolRegistry: toolRegistry,
      identityFabric: identityFabric,
      auditArchive: const NativeAuditArchive(),
    ),
  );
}

/// Selecciona el [AgentReasoner] del loop ReAct nuevo segun config.
///
/// Si Gemma esta configurado, lo conecta con el [registry] para que el
/// adapter pueda reparar inputs invalidos (validate-then-repair pattern,
/// inspirado en CommandCodeAI/DeepSeek). Sin registry, falla cerrado.
AgentReasoner? _buildAgentReasoner(AppConfig config, ToolRegistry registry) {
  if (config.reasonerMode == ReasonerMode.litertGemma &&
      config.litertModelPath.trim().isNotEmpty) {
    return LiteRtGemmaAgentReasoner(
      modelPath: config.litertModelPath,
      modelSha256: config.litertModelSha256,
      timeout: Duration(seconds: config.litertTimeoutSeconds),
      toolRegistry: registry,
    );
  }
  return null;
}

class KanApp extends StatelessWidget {
  const KanApp({
    super.key,
    AppConfig? config,
    this.reasoner,
    this.agentReasoner,
    this.toolRegistry,
    this.identityFabric,
    this.auditArchive,
    this.authenticationService,
  }) : config = config ?? const AppConfig.fromEnvironment();

  final AppConfig config;
  final Object? reasoner;
  final AgentReasoner? agentReasoner;
  final ToolRegistry? toolRegistry;
  final DigitalIdentityFabric? identityFabric;
  final AuditArchive? auditArchive;
  final LocalAuthenticationService? authenticationService;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xff006d5b);

    final classicHome = HomeScreen(
      reasoner: reasoner,
      reasonerLabel: config.label,
      identityFabric: identityFabric,
      auditArchive: auditArchive,
      authenticationService: authenticationService,
    );

    final home = kHomeMode == HomeMode.citizen
        ? Builder(
            builder: (context) => CitizenHome(
              reasoner: agentReasoner,
              toolRegistry: toolRegistry,
              onOpenAdvancedMode: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute<void>(builder: (_) => classicHome));
              },
              onOpenVentanilla: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => VentanillaHome(
                      onExitToCitizen: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                );
              },
            ),
          )
        : classicHome;

    return MaterialApp(
      title: 'ZPK Digital ID',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7f7f2),
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
