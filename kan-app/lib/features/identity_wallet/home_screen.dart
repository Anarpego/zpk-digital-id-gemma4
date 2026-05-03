import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/kan_case.dart';
import '../../services/audit_archive.dart';
import '../../services/digital_identity_fabric.dart';
import '../../services/identity_protection_agent.dart';
import '../../services/kan_reasoner.dart';
import '../../services/legal_template_service.dart';
import '../../services/local_breach_catalog.dart';
import '../../services/local_authentication_service.dart';
import '../../services/local_deterministic_reasoner.dart';
import '../../services/recovery_packet_service.dart';
import '../../services/revocation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    Object? reasoner,
    this.reasonerLabel = 'Local deterministic',
    this.identityFabric,
    this.auditArchive,
    this.authenticationService,
  }) : reasoner = reasoner is KanReasoner
           ? reasoner
           : const LocalDeterministicReasoner();

  final KanReasoner reasoner;
  final String reasonerLabel;
  final DigitalIdentityFabric? identityFabric;
  final AuditArchive? auditArchive;
  final LocalAuthenticationService? authenticationService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController(text: '1234567890101');
  final _templates = const LegalTemplateService();
  final _agent = const IdentityProtectionAgent();
  late final DigitalIdentityFabric _trustFabric;
  late final RecoveryPacketService _packetService;
  late final RevocationService _revocationService;
  late final LocalAuthenticationService _authenticationService;
  late final AuditArchiveService _auditArchive;
  late final Future<LocalBreachCatalog> _catalog;

  CaseScenario _scenario = CaseScenario.discoveredVictim;
  VerificationResult? _result;
  ReasonedGuidance? _guidance;
  IdentityTrustReport? _trustReport;
  LocalAuthenticationProof? _authenticationProof;
  RecoveryPacket? _recoveryPacket;
  LocalRevocationReceipt? _revocationReceipt;
  AuditArchiveReceipt? _auditReceipt;
  AuditArchiveClearReceipt? _auditClearReceipt;
  String? _complaint;
  String? _auditError;
  String? _authenticationError;
  String? _caseError;
  ReasonerRuntimeInstallResult? _runtimeInstallResult;
  ReasonerRuntimeStatus? _runtimeInstallProgress;
  ReasonerRuntimeSelfTestResult? _runtimeSelfTestResult;
  String? _runtimeInstallError;
  String? _runtimeSelfTestError;
  late Future<ReasonerRuntimeStatus> _runtimeStatus;
  Timer? _runtimeInstallPoller;
  bool _isInstallingRuntime = false;
  bool _isRunningRuntimeSelfTest = false;
  bool _isVerifying = false;
  int _sectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _trustFabric = widget.identityFabric ?? const DigitalIdentityFabric();
    _packetService = RecoveryPacketService(identityFabric: _trustFabric);
    _revocationService = RevocationService(identityFabric: _trustFabric);
    _authenticationService =
        widget.authenticationService ??
        LocalAuthenticationService(identityFabric: _trustFabric);
    _auditArchive = AuditArchiveService(
      archive: widget.auditArchive ?? MemoryAuditArchive(),
    );
    _catalog = LocalBreachCatalog.loadEmbeddedOrFallback();
    _runtimeStatus = _loadRuntimeStatus();
  }

  @override
  void dispose() {
    _runtimeInstallPoller?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _caseError = null;
    });
    try {
      final catalog = await _catalog;
      final result = catalog.verify(_controller.text);
      final guidance = await widget.reasoner.explain(
        result: result,
        scenario: _scenario,
      );
      final assessment = _agent.assess(result: result, scenario: _scenario);
      final trustReport = await _trustFabric.evaluate(
        result: result,
        scenario: _scenario,
        assessment: assessment,
      );
      final complaint = result.isValidCui
          ? _templates.buildComplaint(result: result, scenario: _scenario)
          : _scenario.allowsNoCui
          ? _templates.buildInstitutionIntake(
              result: result,
              scenario: _scenario,
            )
          : null;
      final recoveryPacket = complaint == null
          ? null
          : await _packetService.build(
              result: result,
              scenario: _scenario,
              trustReport: trustReport,
              privateLocalComplaint: complaint,
            );
      AuditArchiveReceipt? auditReceipt;
      String? auditError;
      if (recoveryPacket != null) {
        try {
          auditReceipt = await _auditArchive.appendRecoveryAudit(
            result: result,
            scenario: _scenario,
            guidance: guidance,
            trustReport: trustReport,
            recoveryPacket: recoveryPacket,
          );
        } catch (error) {
          auditError = error.toString();
        }
      }

      setState(() {
        _result = result;
        _guidance = guidance;
        _trustReport = trustReport;
        _authenticationProof = null;
        _recoveryPacket = recoveryPacket;
        _revocationReceipt = null;
        _auditReceipt = auditReceipt;
        _auditClearReceipt = null;
        _complaint = complaint;
        _auditError = auditError;
        _authenticationError = null;
        _caseError = null;
        _isVerifying = false;
        _sectionIndex = _scenario.allowsNoCui ? 2 : 1;
      });
    } catch (error) {
      setState(() {
        _caseError = error.toString();
        _isVerifying = false;
        _sectionIndex = 1;
      });
    }
  }

  Future<ReasonerRuntimeStatus> _loadRuntimeStatus() {
    final reasoner = widget.reasoner;
    if (reasoner is ReasonerRuntimeProbe) {
      return (reasoner as ReasonerRuntimeProbe).runtimeStatus();
    }
    return Future.value(
      ReasonerRuntimeStatus(
        label: widget.reasonerLabel,
        state: 'READY',
        summary: 'Agente local disponible.',
        isOfflineCapable: true,
        isModelBacked: false,
        trace: const ['reasoner_runtime(local) -> ready'],
      ),
    );
  }

  void _refreshRuntimeStatus() {
    setState(() => _runtimeStatus = _loadRuntimeStatus());
  }

  Future<void> _installRuntimeAssets() async {
    final reasoner = widget.reasoner;
    if (reasoner is! ReasonerRuntimeInstaller) {
      return;
    }
    setState(() {
      _isInstallingRuntime = true;
      _runtimeInstallError = null;
      _runtimeInstallResult = null;
      _runtimeInstallProgress = null;
      _runtimeSelfTestError = null;
    });
    _runtimeInstallPoller?.cancel();
    _runtimeInstallPoller = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadRuntimeStatus()
          .then((status) {
            if (!mounted || !_isInstallingRuntime) {
              return;
            }
            setState(() {
              _runtimeInstallProgress = status;
              _runtimeStatus = Future.value(status);
            });
          })
          .catchError((_) {});
    });
    try {
      final result = await (reasoner as ReasonerRuntimeInstaller)
          .installRuntimeAssets();
      _runtimeInstallPoller?.cancel();
      setState(() {
        _runtimeInstallResult = result;
        _runtimeInstallError = null;
        _runtimeInstallProgress = null;
        _runtimeStatus = _loadRuntimeStatus();
        _isInstallingRuntime = false;
      });
    } catch (error) {
      _runtimeInstallPoller?.cancel();
      setState(() {
        _runtimeInstallError = error.toString();
        _runtimeInstallProgress = null;
        _isInstallingRuntime = false;
      });
    }
  }

  Future<void> _runRuntimeSelfTest() async {
    final reasoner = widget.reasoner;
    if (reasoner is! ReasonerRuntimeSelfTester) {
      return;
    }
    setState(() {
      _isRunningRuntimeSelfTest = true;
      _runtimeSelfTestError = null;
      _runtimeSelfTestResult = null;
    });
    try {
      final result = await (reasoner as ReasonerRuntimeSelfTester)
          .runRuntimeSelfTest();
      setState(() {
        _runtimeSelfTestResult = result;
        _runtimeSelfTestError = null;
        _isRunningRuntimeSelfTest = false;
      });
    } catch (error) {
      setState(() {
        _runtimeSelfTestError = error.toString();
        _runtimeSelfTestResult = null;
        _isRunningRuntimeSelfTest = false;
      });
    }
  }

  Future<void> _clearAuditArchive() async {
    try {
      final receipt = await _auditArchive.clearLocalArchive();
      setState(() {
        _auditReceipt = null;
        _auditClearReceipt = receipt;
        _auditError = null;
      });
    } catch (error) {
      setState(() => _auditError = error.toString());
    }
  }

  Future<void> _revokeLocalCredential() async {
    final result = _result;
    final trustReport = _trustReport;
    if (result == null || trustReport == null) {
      return;
    }
    final receipt = await _revocationService.revokeLocalCredential(
      result: result,
      scenario: _scenario,
      trustReport: trustReport,
      reason: 'citizen_requested_local_revocation',
    );
    setState(() {
      _revocationReceipt = receipt;
      _authenticationProof = null;
      _authenticationError = null;
    });
  }

  Future<void> _issueAuthenticationProof() async {
    final result = _result;
    final trustReport = _trustReport;
    if (result == null || trustReport == null) {
      return;
    }
    try {
      final proof = await _authenticationService.buildProof(
        result: result,
        scenario: _scenario,
        trustReport: trustReport,
        revocationReceipt: _revocationReceipt,
      );
      setState(() {
        _authenticationProof = proof;
        _authenticationError = null;
      });
    } catch (error) {
      setState(() {
        _authenticationProof = null;
        _authenticationError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZPK Digital ID'),
        actions: [
          const _StatusChip(icon: Icons.lock_outline, label: 'Wallet local'),
          const _StatusChip(icon: Icons.wifi_off_outlined, label: 'Sin red'),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _sectionIndex,
        onDestinationSelected: (index) {
          setState(() => _sectionIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism),
            label: 'Persona',
          ),
          NavigationDestination(
            icon: Icon(Icons.playlist_add_check_circle_outlined),
            selectedIcon: Icon(Icons.playlist_add_check_circle),
            label: 'Acciones',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: 'Institucion',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Evidencia',
          ),
          NavigationDestination(
            icon: Icon(Icons.memory_outlined),
            selectedIcon: Icon(Icons.memory),
            label: 'Motor',
          ),
        ],
      ),
      body: SafeArea(child: _buildSection(context)),
    );
  }

  Widget _buildSection(BuildContext context) {
    return switch (_sectionIndex) {
      0 => _buildHelpSection(context),
      1 => _buildActionSection(context),
      2 => _buildInstitutionSection(context),
      3 => _buildEvidenceSection(context),
      _ => _buildMotorSection(context),
    };
  }

  Widget _buildHelpSection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionHeader(
          icon: Icons.shield_outlined,
          title: 'Vista persona',
          subtitle:
              'Elija que necesita hacer: registrarse, recuperar acceso o proteger evidencia.',
        ),
        const SizedBox(height: 16),
        _CitizenStartPanel(
          scenario: _scenario,
          onScenarioChanged: (scenario) {
            setState(() => _scenario = scenario);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: _scenario.allowsNoCui ? 'CUI opcional' : 'CUI',
            helperText: _scenario.allowsNoCui
                ? 'Dejelo vacio para checklist sin credencial; ejemplo: 1234567890101'
                : 'Ejemplo para evaluacion: 1234567890101',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
        ),
        const SizedBox(height: 12),
        if (_scenario.allowsNoCui) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isVerifying
                  ? null
                  : () {
                      _controller.clear();
                      _verify();
                    },
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Continuar sin CUI'),
            ),
          ),
          const SizedBox(height: 4),
        ],
        FilledButton.icon(
          onPressed: _isVerifying ? null : _verify,
          icon: _isVerifying
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.verified_user_outlined),
          label: Text(
            _isVerifying ? 'Revisando en el telefono' : 'Ayudarme ahora',
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionHeader(
          icon: Icons.playlist_add_check_circle_outlined,
          title: 'Acciones del agente',
          subtitle:
              'Lo importante aparece primero. Los detalles estan en Evidencia.',
        ),
        const SizedBox(height: 16),
        if (_caseError != null)
          _CaseErrorPanel(error: _caseError!, onRetry: _verify)
        else if (_result == null)
          _EmptyState(
            color: color,
            message:
                'Elija una situacion en Persona y ejecute la revision local.',
          )
        else ...[
          _CitizenOutcomePanel(
            scenario: _scenario,
            result: _result!,
            guidance: _guidance!,
            trustReport: _trustReport!,
            recoveryPacket: _recoveryPacket,
          ),
          const SizedBox(height: 12),
          _GuidanceActionPanel(guidance: _guidance!),
          const SizedBox(height: 12),
          if (_result!.isValidCui) ...[
            _AuthenticationProofPanel(
              proof: _authenticationProof,
              error: _authenticationError,
              revocationReceipt: _revocationReceipt,
              onIssue: _issueAuthenticationProof,
            ),
            const SizedBox(height: 12),
            _RevocationPanel(
              receipt: _revocationReceipt,
              onRevoke: _revokeLocalCredential,
            ),
          ] else
            _NoCredentialPanel(scenario: _scenario),
        ],
      ],
    );
  }

  Widget _buildInstitutionSection(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionHeader(
          icon: Icons.account_balance_outlined,
          title: 'Mesa institucional ${_scenario.institutionName}',
          subtitle:
              'Hechos minimos, prueba firmada y ruta de atencion sin copiar DPI completo.',
        ),
        const SizedBox(height: 16),
        if (_result == null)
          _EmptyState(
            color: color,
            message:
                'Ejecute primero un caso en Persona para generar el paquete que revisaria la institucion.',
          )
        else
          _InstitutionAdminPanel(
            scenario: _scenario,
            result: _result!,
            guidance: _guidance!,
            trustReport: _trustReport!,
            recoveryPacket: _recoveryPacket,
          ),
      ],
    );
  }

  Widget _buildEvidenceSection(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const _SectionHeader(
          icon: Icons.inventory_2_outlined,
          title: 'Evidencia local',
          subtitle:
              'Pruebas, trazas y paquetes redactados para juez, institucion o auditoria.',
        ),
        const SizedBox(height: 16),
        if (_result == null)
          _EmptyState(
            color: color,
            message:
                'Todavia no hay evidencia. Ejecute una revision en Persona.',
          )
        else ...[
          _ResultPanel(result: _result!, scenario: _scenario),
          const SizedBox(height: 12),
          _GuidancePanel(guidance: _guidance!),
          const SizedBox(height: 12),
          _TrustFabricPanel(report: _trustReport!),
          const SizedBox(height: 12),
          if (_recoveryPacket != null) ...[
            _RecoveryPacketPanel(packet: _recoveryPacket!),
            const SizedBox(height: 12),
          ],
          if (_auditReceipt != null) ...[
            _AuditArchivePanel(
              receipt: _auditReceipt!,
              onClear: _clearAuditArchive,
            ),
            const SizedBox(height: 12),
          ] else if (_auditClearReceipt != null) ...[
            _AuditArchiveClearedPanel(receipt: _auditClearReceipt!),
            const SizedBox(height: 12),
          ] else if (_auditError != null) ...[
            _AuditArchiveErrorPanel(error: _auditError!),
            const SizedBox(height: 12),
          ],
          if (_complaint != null) _TemplatePreview(text: _complaint!),
        ],
      ],
    );
  }

  Widget _buildMotorSection(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        _SectionHeader(
          icon: Icons.memory_outlined,
          title: 'Motor offline',
          subtitle: widget.reasonerLabel,
        ),
        const SizedBox(height: 16),
        _RuntimeStatusPanel(
          status: _runtimeStatus,
          onRefresh: _refreshRuntimeStatus,
          onInstall: widget.reasoner is ReasonerRuntimeInstaller
              ? _installRuntimeAssets
              : null,
          onSelfTest: widget.reasoner is ReasonerRuntimeSelfTester
              ? _runRuntimeSelfTest
              : null,
          isInstalling: _isInstallingRuntime,
          isRunningSelfTest: _isRunningRuntimeSelfTest,
          installResult: _runtimeInstallResult,
          installProgress: _runtimeInstallProgress,
          installError: _runtimeInstallError,
          selfTestResult: _runtimeSelfTestResult,
          selfTestError: _runtimeSelfTestError,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: text.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuidanceActionPanel extends StatelessWidget {
  const _GuidanceActionPanel({required this.guidance});

  final ReasonedGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Que hacer ahora',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _RouteBadge(decision: guidance.routingDecision),
            const SizedBox(height: 8),
            _ReasonerExecutionBadge(guidance: guidance),
            const SizedBox(height: 8),
            _AgentExecutionProofPanel(guidance: guidance),
            const SizedBox(height: 10),
            for (final step in guidance.nextSteps)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.color,
    this.message = 'La verificacion local aparecera aqui.',
  });

  final ColorScheme color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}

class _CitizenStartPanel extends StatelessWidget {
  const _CitizenStartPanel({
    required this.scenario,
    required this.onScenarioChanged,
  });

  final CaseScenario scenario;
  final ValueChanged<CaseScenario> onScenarioChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Que paso?',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in _scenarioChoices)
                  ChoiceChip(
                    avatar: Icon(_scenarioIcon(option), size: 18),
                    selected: scenario == option,
                    label: Text(_scenarioChoiceLabel(option)),
                    onSelected: (_) => onScenarioChanged(option),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color.surface,
                border: Border.all(color: color.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_scenarioIcon(scenario), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _scenarioCitizenTitle(scenario),
                            style: text.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_scenarioCitizenSubtitle(scenario)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitizenOutcomePanel extends StatelessWidget {
  const _CitizenOutcomePanel({
    required this.scenario,
    required this.result,
    required this.guidance,
    required this.trustReport,
    required this.recoveryPacket,
  });

  final CaseScenario scenario;
  final VerificationResult result;
  final ReasonedGuidance guidance;
  final IdentityTrustReport trustReport;
  final RecoveryPacket? recoveryPacket;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: result.isExposed ? color.errorContainer : color.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.isExposed
                      ? Icons.priority_high_outlined
                      : Icons.check_circle_outline,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _citizenOutcomeTitle(scenario, result),
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_citizenOutcomeSummary(scenario, result, recoveryPacket)),
            const SizedBox(height: 12),
            Text('Siguiente paso recomendado', style: text.labelLarge),
            const SizedBox(height: 4),
            Text(_citizenNextStep(scenario, result)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                Chip(
                  avatar: Icon(Icons.visibility_off_outlined, size: 18),
                  label: Text('CUI no sale'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(Icons.wifi_off_outlined, size: 18),
                  label: Text('funciona sin red'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: Icon(Icons.draw_outlined, size: 18),
                  label: Text('paquete firmado'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copyCitizenSummary(context),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar resumen seguro'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyCitizenSummary(BuildContext context) async {
    final payload = [
      'Resumen seguro ZPK',
      'situacion=${scenario.shortCode}',
      'cui=${result.isValidCui ? 'redactado' : 'no_disponible'}',
      'coincidencias_locales=${result.matches.length}',
      'ruta=${guidance.routingDecision.route.traceCode}',
      'envia_pii=${guidance.routingDecision.sendsPersonalData}',
      'pseudonimo=${trustReport.credential.pseudonymousId}',
      if (recoveryPacket != null)
        'paquete_hash=${recoveryPacket!.redactedPacketHash.substring(0, 16)}',
      'siguiente=${_citizenNextStep(scenario, result)}',
      ...guidance.nextSteps.map((step) => 'paso=$step'),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: payload));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Resumen seguro copiado')));
    }
  }
}

class _NoCredentialPanel extends StatelessWidget {
  const _NoCredentialPanel({required this.scenario});

  final CaseScenario scenario;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Sin credencial emitida',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.no_accounts_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Este modo ayuda a preparar una visita a ${scenario.institutionName}. No firma autenticacion de identidad porque el CUI no fue confirmado.',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstitutionAdminPanel extends StatelessWidget {
  const _InstitutionAdminPanel({
    required this.scenario,
    required this.result,
    required this.guidance,
    required this.trustReport,
    required this.recoveryPacket,
  });

  final CaseScenario scenario;
  final VerificationResult result;
  final ReasonedGuidance guidance;
  final IdentityTrustReport trustReport;
  final RecoveryPacket? recoveryPacket;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final color = Theme.of(context).colorScheme;
    final canAccept = result.isValidCui && recoveryPacket != null;
    final decision = canAccept
        ? 'Aceptar paquete redactado y abrir seguimiento'
        : 'Atender como intake presencial sin credencial';

    return Card(
      elevation: 0,
      color: color.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_scenarioIcon(scenario)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bandeja ${scenario.institutionName}',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_institutionScenarioSummary(scenario)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.visibility_off_outlined, size: 18),
                  label: Text(result.isValidCui ? 'CUI redactado' : 'sin CUI'),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.verified_outlined, size: 18),
                  label: Text(
                    recoveryPacket == null ? 'sin firma' : 'firma local ok',
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.route_outlined, size: 18),
                  label: Text(guidance.routingDecision.route.label),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Revision de ventanilla', style: text.labelLarge),
            const SizedBox(height: 6),
            for (final item in _institutionChecklist(scenario, result))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text('Ruta de atencion', style: text.labelLarge),
            const SizedBox(height: 4),
            Text(decision),
            const SizedBox(height: 8),
            Text(
              'Pseudonimo: ${trustReport.credential.pseudonymousId}',
              style: text.bodySmall,
            ),
            if (recoveryPacket != null)
              Text(
                'Hash paquete: ${recoveryPacket!.redactedPacketHash.substring(0, 16)}',
                style: text.bodySmall,
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copyInstitutionPacket(context),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar paquete institucional'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyInstitutionPacket(BuildContext context) async {
    final payload = [
      'ZPK paquete institucional',
      'institucion=${scenario.institutionName}',
      'flujo=${scenario.shortCode}',
      'cui=${result.isValidCui ? 'redactado' : 'no_disponible'}',
      'pseudonimo=${trustReport.credential.pseudonymousId}',
      'ruta=${guidance.routingDecision.route.traceCode}',
      if (recoveryPacket != null)
        'paquete_hash=${recoveryPacket!.redactedPacketHash.substring(0, 16)}',
      ..._institutionChecklist(scenario, result).map((item) => 'check=$item'),
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: payload));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paquete institucional copiado')),
      );
    }
  }
}

const _scenarioChoices = [
  CaseScenario.igssRegistration,
  CaseScenario.satTaxAccess,
  CaseScenario.schoolEnrollment,
  CaseScenario.publicServiceBreach,
  CaseScenario.discoveredVictim,
  CaseScenario.remittanceFraud,
  CaseScenario.extortionThreat,
  CaseScenario.fieldAccess,
  CaseScenario.violenceCoercion,
  CaseScenario.suspicion,
  CaseScenario.preventive,
];

String _institutionScenarioSummary(CaseScenario scenario) => switch (scenario) {
  CaseScenario.igssRegistration =>
    'La ventanilla IGSS revisa si puede abrir orientacion, pedir documentos minimos y dar seguimiento sin recibir fotos completas por canales informales.',
  CaseScenario.satTaxAccess =>
    'La ventanilla SAT revisa solicitud de acceso, actualizacion o bloqueo preventivo con hechos redactados y presencia local.',
  CaseScenario.schoolEnrollment =>
    'Un centro educativo valida inscripcion, beca o constancia con prueba limitada y consentimiento del responsable.',
  CaseScenario.publicServiceBreach =>
    'La institucion revisa un tramite no reconocido con prueba de presencia y paquete redactado.',
  CaseScenario.fieldAccess =>
    'Personal en campo confirma acceso a escuela, salud o ayuda sin copiar todo el DPI.',
  _ =>
    'La institucion recibe solo hechos minimos, hash firmado y pseudonimo local para decidir siguiente paso.',
};

List<String> _institutionChecklist(
  CaseScenario scenario,
  VerificationResult result,
) {
  final base = [
    result.isValidCui
        ? 'Confirmar identidad en ventanilla o canal oficial; no guardar CUI completo en notas.'
        : 'Explicar documentos minimos y abrir intake presencial sin credencial ZPK.',
    'Verificar hash del paquete y pseudonimo antes de aceptar evidencia.',
  ];
  final specific = switch (scenario) {
    CaseScenario.igssRegistration => const [
      'Revisar afiliacion, patrono o expediente con documentos fisicos oficiales.',
      'Entregar numero de gestion y ruta de seguimiento.',
    ],
    CaseScenario.satTaxAccess => const [
      'Validar que el usuario use portal o ventanilla oficial SAT.',
      'Priorizar bloqueo preventivo si hay actividad tributaria no reconocida.',
    ],
    CaseScenario.schoolEnrollment => const [
      'Verificar responsable, estudiante y consentimiento sin replicar fotos de DPI.',
      'Registrar solo el minimo necesario para inscripcion, beca o constancia.',
    ],
    CaseScenario.publicServiceBreach => const [
      'Abrir revision del tramite o cuenta no reconocida.',
      'Solicitar correccion o congelamiento si hay riesgo de uso indebido.',
    ],
    CaseScenario.fieldAccess => const [
      'Aceptar prueba limitada offline y registrar entrega del servicio.',
      'Sincronizar solo estado agregado cuando vuelva la red.',
    ],
    _ => const [
      'Escalar a soporte humano si hay violencia, fraude o documentos comprometidos.',
      'Responder con canal oficial y evitar pedir datos completos por chat.',
    ],
  };
  return [...base, ...specific];
}

IconData _scenarioIcon(CaseScenario scenario) => switch (scenario) {
  CaseScenario.discoveredVictim => Icons.person_search_outlined,
  CaseScenario.extortionThreat => Icons.health_and_safety_outlined,
  CaseScenario.remittanceFraud => Icons.account_balance_wallet_outlined,
  CaseScenario.publicServiceBreach => Icons.account_balance_outlined,
  CaseScenario.igssRegistration => Icons.health_and_safety_outlined,
  CaseScenario.satTaxAccess => Icons.receipt_long_outlined,
  CaseScenario.schoolEnrollment => Icons.school_outlined,
  CaseScenario.fieldAccess => Icons.diversity_3_outlined,
  CaseScenario.violenceCoercion => Icons.volunteer_activism_outlined,
  CaseScenario.suspicion => Icons.help_outline,
  CaseScenario.preventive => Icons.shield_outlined,
};

String _scenarioChoiceLabel(CaseScenario scenario) => switch (scenario) {
  CaseScenario.discoveredVictim => 'DPI/datos',
  CaseScenario.extortionThreat => 'Amenazas',
  CaseScenario.remittanceFraud => 'Dinero',
  CaseScenario.publicServiceBreach => 'Tramite',
  CaseScenario.igssRegistration => 'IGSS',
  CaseScenario.satTaxAccess => 'SAT',
  CaseScenario.schoolEnrollment => 'Colegio',
  CaseScenario.fieldAccess => 'Campo',
  CaseScenario.violenceCoercion => 'Proteccion',
  CaseScenario.suspicion => 'Duda',
  CaseScenario.preventive => 'Prevenir',
};

String _scenarioCitizenTitle(CaseScenario scenario) => switch (scenario) {
  CaseScenario.discoveredVictim => 'Usaron mi DPI o mis datos',
  CaseScenario.extortionThreat => 'Me amenazan o me presionan',
  CaseScenario.remittanceFraud => 'Me quieren quitar dinero',
  CaseScenario.publicServiceBreach => 'Un tramite publico fallo',
  CaseScenario.igssRegistration => 'Necesito registrarme o recuperar IGSS',
  CaseScenario.satTaxAccess => 'Necesito entrar o actualizar SAT',
  CaseScenario.schoolEnrollment => 'Necesito inscripcion educativa',
  CaseScenario.fieldAccess => 'Necesito servicio sin internet',
  CaseScenario.violenceCoercion => 'Alguien me controla o amenaza',
  CaseScenario.suspicion => 'Algo se ve raro',
  CaseScenario.preventive => 'Quiero prevenir',
};

String _scenarioCitizenSubtitle(CaseScenario scenario) => switch (scenario) {
  CaseScenario.discoveredVictim =>
    'Tramite, cuenta, credito o registro que no reconozco.',
  CaseScenario.extortionThreat =>
    'Mensajes, llamadas o cobros con miedo o presion.',
  CaseScenario.remittanceFraud =>
    'Prestamo falso, empleo falso, remesa, SIM o banco.',
  CaseScenario.publicServiceBreach =>
    'Registro, portal o servicio publico con datos o acceso incorrecto.',
  CaseScenario.igssRegistration =>
    'Checklist para IGSS: registro, patrono, afiliacion o recuperacion.',
  CaseScenario.satTaxAccess =>
    'Acceso SAT, actualizacion de correo o bloqueo por actividad sospechosa.',
  CaseScenario.schoolEnrollment =>
    'Inscripcion, beca o validacion ante colegio/universidad.',
  CaseScenario.fieldAccess =>
    'Escuela, salud o ayuda necesita confirmar identidad en campo.',
  CaseScenario.violenceCoercion =>
    'Preservar evidencia y pedir apoyo sin exponer ubicacion ni documentos.',
  CaseScenario.suspicion => 'No se si es fraude; quiero revisar sin exponerme.',
  CaseScenario.preventive =>
    'Crear una prueba local antes de compartir documentos.',
};

String _citizenOutcomeTitle(CaseScenario scenario, VerificationResult result) {
  if (!result.isValidCui) {
    if (scenario.allowsNoCui) {
      return 'Checklist sin CUI para ${scenario.institutionName}';
    }
    return 'Primero corrijamos el CUI';
  }
  if (scenario == CaseScenario.extortionThreat) {
    return 'Prioridad: seguridad y evidencia';
  }
  if (scenario == CaseScenario.publicServiceBreach) {
    return 'Prioridad: recuperar tramite';
  }
  if (scenario == CaseScenario.igssRegistration) {
    return 'Prioridad: registro IGSS';
  }
  if (scenario == CaseScenario.satTaxAccess) {
    return 'Prioridad: acceso SAT seguro';
  }
  if (scenario == CaseScenario.schoolEnrollment) {
    return 'Prioridad: inscripcion educativa';
  }
  if (scenario == CaseScenario.fieldAccess) {
    return 'Prioridad: acceso sin copiar DPI';
  }
  if (scenario == CaseScenario.violenceCoercion) {
    return 'Prioridad: proteccion y evidencia';
  }
  if (result.isExposed) {
    return 'Hay riesgo de identidad';
  }
  return 'Identidad revisada en local';
}

String _citizenOutcomeSummary(
  CaseScenario scenario,
  VerificationResult result,
  RecoveryPacket? recoveryPacket,
) {
  if (!result.isValidCui) {
    if (scenario.allowsNoCui && recoveryPacket != null) {
      return 'Modo sin CUI: no se emite credencial, pero si se preparo checklist e intake redactado para ventanilla.';
    }
    return 'El agente detuvo documentos y pruebas hasta corregir el formato.';
  }
  if (recoveryPacket == null) {
    return 'La revision quedo local y sin paquete institucional.';
  }
  return 'Revision local hecha: riesgo clasificado, PII bloqueada y paquete redactado preparado.';
}

String _citizenNextStep(CaseScenario scenario, VerificationResult result) {
  if (!result.isValidCui) {
    if (scenario.allowsNoCui) {
      return 'No hay CUI confirmado. El agente prepara checklist e intake para ${scenario.institutionName}, no una credencial.';
    }
    return 'Revise que sean 13 digitos antes de generar documentos.';
  }
  return switch (scenario) {
    CaseScenario.extortionThreat =>
      'No responda bajo presion. Guarde capturas y comparta solo el resumen redactado con una persona o institucion de confianza.',
    CaseScenario.remittanceFraud =>
      'Contacte banco, telefonia o remesadora por canal oficial y use el paquete firmado para explicar el caso sin entregar el CUI completo.',
    CaseScenario.publicServiceBreach =>
      'Pida revision formal con el paquete redactado; la institucion ve hechos verificables, no el documento completo.',
    CaseScenario.igssRegistration =>
      'Use el paquete de intake para pedir orientacion IGSS por canal oficial sin mandar foto completa de documentos.',
    CaseScenario.satTaxAccess =>
      'Use el paquete redactado para recuperar acceso, actualizar correo o pedir bloqueo preventivo en SAT.',
    CaseScenario.schoolEnrollment =>
      'Presente el paquete limitado al centro educativo para revisar inscripcion, beca o constancia sin copiar todo el DPI.',
    CaseScenario.fieldAccess =>
      'Muestre la prueba limitada al personal de escuela, salud o brigada; evita copias completas de DPI en campo.',
    CaseScenario.violenceCoercion =>
      'Priorice seguridad fisica. Comparta solo el resumen seguro con una persona o institucion de confianza.',
    CaseScenario.discoveredVictim =>
      'Use el paquete redactado para pedir bloqueo, revision o recuperacion ante la institucion correspondiente.',
    CaseScenario.suspicion =>
      'No entregue documentos todavia. Revise senales, guarde evidencia y comparta solo hechos redactados.',
    CaseScenario.preventive =>
      'Use la prueba local cuando una institucion necesite confirmar identidad sin copiar todo el DPI.',
  };
}

class _RuntimeStatusPanel extends StatelessWidget {
  const _RuntimeStatusPanel({
    required this.status,
    required this.onRefresh,
    required this.onInstall,
    required this.onSelfTest,
    required this.isInstalling,
    required this.isRunningSelfTest,
    required this.installResult,
    required this.installProgress,
    required this.installError,
    required this.selfTestResult,
    required this.selfTestError,
  });

  final Future<ReasonerRuntimeStatus> status;
  final VoidCallback onRefresh;
  final VoidCallback? onInstall;
  final VoidCallback? onSelfTest;
  final bool isInstalling;
  final bool isRunningSelfTest;
  final ReasonerRuntimeInstallResult? installResult;
  final ReasonerRuntimeStatus? installProgress;
  final String? installError;
  final ReasonerRuntimeSelfTestResult? selfTestResult;
  final String? selfTestError;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return FutureBuilder<ReasonerRuntimeStatus>(
      future: status,
      builder: (context, snapshot) {
        final runtime = snapshot.data;
        final isReady = runtime?.isOfflineCapable ?? false;
        final progressRuntime = installProgress ?? runtime;
        final progressValue = _progressValue(progressRuntime);
        final canInstall = runtime != null && _canInstallRuntime(runtime);
        final canSelfTest = runtime != null && _canSelfTestRuntime(runtime);
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          color: isReady ? color.secondaryContainer : color.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      runtime?.isModelBacked ?? false
                          ? Icons.memory_outlined
                          : Icons.shield_outlined,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Motor agente offline',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Revisar estado',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState != ConnectionState.done) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Revisando runtime local.'),
                ] else if (snapshot.hasError) ...[
                  Text(
                    'No se pudo revisar el runtime: ${snapshot.error}',
                    style: text.bodySmall,
                  ),
                ] else if (runtime != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar: const Icon(
                          Icons.radio_button_checked,
                          size: 18,
                        ),
                        label: Text(runtime.state),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        avatar: const Icon(Icons.wifi_off_outlined, size: 18),
                        label: Text(_runtimeCapabilityLabel(runtime)),
                        visualDensity: VisualDensity.compact,
                      ),
                      Chip(
                        avatar: const Icon(Icons.psychology_outlined, size: 18),
                        label: Text(runtime.label),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(runtime.summary),
                  const Divider(height: 24),
                  for (final trace in runtime.trace)
                    Text(trace, style: text.bodySmall),
                  if (isInstalling && progressRuntime != null) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progressValue),
                    const SizedBox(height: 6),
                    Text(
                      _progressLabel(progressRuntime),
                      style: text.bodySmall,
                    ),
                  ],
                  if (installResult != null) ...[
                    const Divider(height: 24),
                    Text(
                      installResult!.summary,
                      style: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final trace in installResult!.trace)
                      Text(trace, style: text.bodySmall),
                  ],
                  if (installError != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Instalacion fallida: $installError',
                      style: text.bodySmall,
                    ),
                  ],
                  if (selfTestResult != null) ...[
                    const Divider(height: 24),
                    Text(
                      selfTestResult!.summary,
                      style: text.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    for (final trace in selfTestResult!.trace)
                      Text(trace, style: text.bodySmall),
                  ],
                  if (selfTestError != null) ...[
                    const Divider(height: 24),
                    Text(
                      'Prueba Gemma fallida: $selfTestError',
                      style: text.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onInstall != null && canInstall) ...[
                        FilledButton.icon(
                          onPressed: isInstalling ? null : onInstall,
                          icon: isInstalling
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.download_outlined),
                          label: Text(
                            isInstalling
                                ? 'Instalando Gemma'
                                : 'Instalar Gemma offline',
                          ),
                        ),
                      ],
                      if (onSelfTest != null && canSelfTest)
                        FilledButton.icon(
                          onPressed: isRunningSelfTest ? null : onSelfTest,
                          icon: isRunningSelfTest
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.fact_check_outlined),
                          label: Text(
                            isRunningSelfTest
                                ? 'Probando Gemma'
                                : 'Probar Gemma offline',
                          ),
                        ),
                      OutlinedButton.icon(
                        onPressed: () =>
                            _copyRuntimeDiagnostics(context, runtime),
                        icon: const Icon(Icons.copy_outlined),
                        label: const Text('Copiar diagnostico'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  double? _progressValue(ReasonerRuntimeStatus? runtime) {
    final downloaded = runtime?.downloadedBytes;
    final total = runtime?.totalBytes;
    if (downloaded == null || total == null || total <= 0) {
      return null;
    }
    return (downloaded / total).clamp(0, 1).toDouble();
  }

  String _progressLabel(ReasonerRuntimeStatus runtime) {
    final downloaded = runtime.downloadedBytes;
    final total = runtime.totalBytes;
    if (downloaded == null || total == null || total <= 0) {
      return 'Instalando modelo Gemma 4 en almacenamiento privado.';
    }
    return 'Descargado ${_formatBytes(downloaded)} de ${_formatBytes(total)}.';
  }

  String _formatBytes(int bytes) {
    const gib = 1024 * 1024 * 1024;
    const mib = 1024 * 1024;
    if (bytes >= gib) {
      return '${(bytes / gib).toStringAsFixed(2)} GB';
    }
    return '${(bytes / mib).toStringAsFixed(1)} MB';
  }

  bool _canInstallRuntime(ReasonerRuntimeStatus runtime) {
    return switch (runtime.state) {
      'DOWNLOADABLE' || 'MISSING_MODEL' || 'CORRUPT_MODEL' => true,
      _ => false,
    };
  }

  bool _canSelfTestRuntime(ReasonerRuntimeStatus runtime) {
    return runtime.isOfflineCapable && runtime.state == 'AVAILABLE';
  }

  String _runtimeCapabilityLabel(ReasonerRuntimeStatus runtime) {
    return switch (runtime.state) {
      'AVAILABLE' => 'sin red',
      'EMULATOR_UNSUPPORTED' => 'modelo instalado',
      'DEVICE_LOW_MEMORY' => 'hardware limitado',
      'DOWNLOADING' => 'descargando',
      'DOWNLOADABLE' || 'MISSING_MODEL' => 'requiere instalacion',
      'CORRUPT_MODEL' => 'reinstalar modelo',
      _ => 'modo respaldo',
    };
  }

  Future<void> _copyRuntimeDiagnostics(
    BuildContext context,
    ReasonerRuntimeStatus runtime,
  ) async {
    final payload = [
      'ZPK runtime diagnostic',
      'label=${runtime.label}',
      'state=${runtime.state}',
      'offline=${runtime.isOfflineCapable}',
      'model_backed=${runtime.isModelBacked}',
      runtime.summary,
      ...runtime.trace,
      if (installResult != null) ...[
        'install_status=${installResult!.status}',
        installResult!.summary,
        ...installResult!.trace,
      ],
      if (installProgress != null) ...[
        'install_progress_state=${installProgress!.state}',
        if (installProgress!.downloadedBytes != null)
          'install_progress_downloaded=${installProgress!.downloadedBytes}',
        if (installProgress!.totalBytes != null)
          'install_progress_total=${installProgress!.totalBytes}',
      ],
      if (installError != null) 'install_error=$installError',
      if (selfTestResult != null) ...[
        'self_test_status=${selfTestResult!.status}',
        selfTestResult!.summary,
        ...selfTestResult!.trace,
      ],
      if (selfTestError != null) 'self_test_error=$selfTestError',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: payload));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Diagnostico copiado')));
    }
  }
}

class _CaseErrorPanel extends StatelessWidget {
  const _CaseErrorPanel({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final normalized = error.replaceAll(RegExp(r'\s+'), ' ').trim();

    return Card(
      elevation: 0,
      color: color.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.report_problem_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Revision detenida',
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'El agente no publico una guia parcial. Copie el diagnostico para revisar LiteRT, modelo o contrato JSON.',
            ),
            const SizedBox(height: 8),
            SelectableText(
              normalized.length <= 500
                  ? normalized
                  : '${normalized.substring(0, 497)}...',
              style: text.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _copyError(context, normalized),
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copiar error'),
                ),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyError(BuildContext context, String normalized) async {
    await Clipboard.setData(
      ClipboardData(text: 'ZPK agent error\n$normalized'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error copiado')));
    }
  }
}

class _AuthenticationProofPanel extends StatelessWidget {
  const _AuthenticationProofPanel({
    required this.proof,
    required this.error,
    required this.revocationReceipt,
    required this.onIssue,
  });

  final LocalAuthenticationProof? proof;
  final String? error;
  final LocalRevocationReceipt? revocationReceipt;
  final VoidCallback onIssue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Autenticacion local',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.key_outlined),
              ],
            ),
            const SizedBox(height: 8),
            if (revocationReceipt != null) ...[
              Text(
                'Credencial revocada: no se emiten nuevas pruebas de autenticacion.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Revocacion: ${revocationReceipt!.revocationId}',
                style: text.bodySmall,
              ),
              const Divider(height: 24),
              const Text('auth.blocked(revocation) -> credential_revoked'),
            ] else if (proof == null) ...[
              Text(
                'Emite una prueba firmada para una institucion sin revelar CUI.',
                style: text.bodySmall,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(
                  'No se emitio la prueba. Active bloqueo de pantalla o autorice la verificacion local.',
                  style: text.bodySmall,
                ),
                Text(
                  'auth.device_presence(android-keyguard) -> denied',
                  style: text.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onIssue,
                icon: const Icon(Icons.key_outlined),
                label: const Text('Emitir prueba local'),
              ),
            ] else ...[
              Text(
                'Institucion: ${proof!.relyingParty}',
                style: text.bodySmall,
              ),
              Text(
                'Pseudonimo: ${proof!.pseudonymousId}',
                style: text.bodySmall,
              ),
              Text(
                'Reto: ${proof!.challenge.substring(0, 18)}',
                style: text.bodySmall,
              ),
              Text(
                'Hash: ${proof!.payloadHash.substring(0, 16)}',
                style: text.bodySmall,
              ),
              Text(
                'Firma: ${proof!.signature.substring(0, 16)} (${proof!.keyStore})',
                style: text.bodySmall,
              ),
              Text(
                'Expira: ${proof!.expiresInMinutes} min',
                style: text.bodySmall,
              ),
              Text(
                'Valida hasta: ${proof!.expiresAt.toLocal()}',
                style: text.bodySmall,
              ),
              const Divider(height: 24),
              for (final trace in proof!.trace)
                Text(trace, style: text.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrustFabricPanel extends StatelessWidget {
  const _TrustFabricPanel({required this.report});

  final IdentityTrustReport report;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Registro ZPK local',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.hub_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.fingerprint, size: 18),
                  label: Text(report.credential.pseudonymousId),
                  visualDensity: VisualDensity.compact,
                ),
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 18),
                  label: Text('${report.consentGrant.expiresInMinutes} min'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(report.recoveryStatus),
            const SizedBox(height: 10),
            Text('DID y credencial verificable local', style: text.labelLarge),
            const SizedBox(height: 4),
            Text('DID: ${report.didDocument['id']}', style: text.bodySmall),
            Text(
              'Prueba: ${report.consentGrant.localProof}',
              style: text.bodySmall,
            ),
            Text(
              'Divulgacion: ${report.selectiveDisclosureClaims.join(', ')}',
              style: text.bodySmall,
            ),
            const SizedBox(height: 10),
            Text('Paquete institucional', style: text.labelLarge),
            const SizedBox(height: 4),
            for (final item in report.institutionPacket)
              Text(item, style: text.bodySmall),
            const SizedBox(height: 10),
            Text('Escala Guatemala / LatAm', style: text.labelLarge),
            const SizedBox(height: 4),
            for (final note in report.interoperabilityNotes)
              Text(note, style: text.bodySmall),
            const Divider(height: 24),
            for (final trace in report.trace)
              Text(trace, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.scenario});

  final VerificationResult result;
  final CaseScenario scenario;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final icon = result.isExposed ? Icons.warning_amber : Icons.check_circle;
    final title = !result.isValidCui
        ? scenario.allowsNoCui
              ? 'Sin CUI a mano'
              : 'CUI invalido'
        : result.isExposed
        ? 'Coincidencia encontrada'
        : 'Sin coincidencia local';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: result.isExposed ? color.errorContainer : color.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (result.matches.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final match in result.matches)
                Text('${match.name}: ${match.exposedFields.join(', ')}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _GuidancePanel extends StatelessWidget {
  const _GuidancePanel({required this.guidance});

  final ReasonedGuidance guidance;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Guia de accion',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _RouteBadge(decision: guidance.routingDecision),
            const SizedBox(height: 8),
            _ReasonerExecutionBadge(guidance: guidance),
            const SizedBox(height: 8),
            _AgentExecutionProofPanel(guidance: guidance),
            const SizedBox(height: 10),
            Text(guidance.summary),
            const SizedBox(height: 12),
            for (final step in guidance.nextSteps)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.arrow_right, size: 20),
                    const SizedBox(width: 6),
                    Expanded(child: Text(step)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Text(
              'Trazas de herramientas',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 6),
            for (final trace in guidance.toolTrace)
              Text(trace, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copyAgentTrace(context, guidance),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar trazas'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyAgentTrace(
    BuildContext context,
    ReasonedGuidance guidance,
  ) async {
    final payload = [
      'ZPK agent trace',
      'used_local_only=${guidance.usedLocalOnly}',
      'route=${guidance.routingDecision.route.traceCode}',
      guidance.summary,
      ...guidance.toolTrace,
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: payload));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Trazas copiadas')));
    }
  }
}

class _ReasonerExecutionBadge extends StatelessWidget {
  const _ReasonerExecutionBadge({required this.guidance});

  final ReasonedGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final mode = _reasonerModeTrace(guidance.toolTrace);
    final isFallback = mode?.contains('fallback:') ?? false;
    final isGemmaOk =
        mode?.contains('litert-gemma') == true &&
        mode?.contains('-> ok') == true;
    final label = isGemmaOk
        ? 'Gemma 4 ejecuto la guia'
        : isFallback
        ? 'Respaldo offline ejecuto la guia'
        : 'Agente local ejecuto la guia';
    final icon = isGemmaOk
        ? Icons.psychology_outlined
        : isFallback
        ? Icons.memory_outlined
        : Icons.shield_outlined;
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }

  String? _reasonerModeTrace(List<String> trace) {
    for (final item in trace) {
      if (item.startsWith('reasoner_mode(')) {
        return item;
      }
    }
    return null;
  }
}

class _AgentExecutionProofPanel extends StatelessWidget {
  const _AgentExecutionProofPanel({required this.guidance});

  final ReasonedGuidance guidance;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final toolCount = _agentToolCount(guidance.toolTrace);
    final piiBlocked =
        !guidance.routingDecision.sendsPersonalData &&
        guidance.toolTrace.any(
          (trace) =>
              trace.contains('select_privacy_route') &&
              trace.contains('pii_block_ok'),
        );
    final contractOk = guidance.toolTrace.any(
      (trace) => trace == 'agent_contract.schema(json) -> ok',
    );
    final ledgerOk = guidance.toolTrace.any(
      (trace) => trace == 'agent_ledger.verify(local) -> ok',
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prueba agente local',
              style: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.account_tree_outlined, size: 18),
                  label: Text('$toolCount herramientas'),
                  visualDensity: VisualDensity.compact,
                ),
                _ProofChip(
                  ok: piiBlocked,
                  okLabel: 'PII bloqueada',
                  pendingLabel: 'revisar PII',
                ),
                _ProofChip(
                  ok: contractOk,
                  okLabel: 'JSON validado',
                  pendingLabel: 'sin JSON modelo',
                ),
                _ProofChip(
                  ok: ledgerOk,
                  okLabel: 'ledger firmado',
                  pendingLabel: 'ledger pendiente',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _agentToolCount(List<String> traces) {
    return traces
        .where(
          (trace) =>
              trace.startsWith('agent.plan(') ||
              trace.startsWith('validate_cui(') ||
              trace.startsWith('local_breach_lookup(') ||
              trace.startsWith('classify_identity_risk(') ||
              trace.startsWith('select_privacy_route(') ||
              trace.startsWith('preserve_evidence(') ||
              trace.startsWith('economic_fraud_triage(') ||
              trace.startsWith('institution_recovery_packet(') ||
              trace.startsWith('igss_registration_agent(') ||
              trace.startsWith('sat_access_agent(') ||
              trace.startsWith('education_enrollment_agent(') ||
              trace.startsWith('field_access_voucher(') ||
              trace.startsWith('coercion_safety_plan(') ||
              trace.startsWith('threat_bulletin.verify(') ||
              trace.startsWith('threat_bulletin.match(') ||
              trace.startsWith('threat_bulletin.action(') ||
              trace.startsWith('prepare_action_packet('),
        )
        .length;
  }
}

class _ProofChip extends StatelessWidget {
  const _ProofChip({
    required this.ok,
    required this.okLabel,
    required this.pendingLabel,
  });

  final bool ok;
  final String okLabel;
  final String pendingLabel;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        ok ? Icons.check_circle_outline : Icons.error_outline,
        size: 18,
      ),
      label: Text(ok ? okLabel : pendingLabel),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RouteBadge extends StatelessWidget {
  const _RouteBadge({required this.decision});

  final RoutingDecision decision;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Chip(
          avatar: const Icon(Icons.route_outlined, size: 18),
          label: Text(decision.route.label),
          visualDensity: VisualDensity.compact,
        ),
        Chip(
          avatar: const Icon(Icons.speed_outlined, size: 18),
          label: Text('${(decision.confidence * 100).round()}% confianza'),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _RevocationPanel extends StatelessWidget {
  const _RevocationPanel({required this.receipt, required this.onRevoke});

  final LocalRevocationReceipt? receipt;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Revocacion local',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.block_outlined),
              ],
            ),
            const SizedBox(height: 8),
            if (receipt == null) ...[
              Text(
                'La credencial puede revocarse en este dispositivo sin enviar CUI.',
                style: text.bodySmall,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRevoke,
                icon: const Icon(Icons.block_outlined),
                label: const Text('Revocar credencial local'),
              ),
            ] else ...[
              Text('ID: ${receipt!.revocationId}', style: text.bodySmall),
              Text(
                'Hash: ${receipt!.receiptHash.substring(0, 16)}',
                style: text.bodySmall,
              ),
              Text(
                'Firma: ${receipt!.signature.substring(0, 16)} (${receipt!.keyStore})',
                style: text.bodySmall,
              ),
              const Divider(height: 24),
              for (final trace in receipt!.trace)
                Text(trace, style: text.bodySmall),
              Text(
                'auth.blocked(revocation) -> credential_revoked',
                style: text.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RecoveryPacketPanel extends StatelessWidget {
  const _RecoveryPacketPanel({required this.packet});

  final RecoveryPacket packet;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final claims =
        packet.redactedSharePacket['selectiveDisclosureClaims'] as List<Object>;
    final institutionFacts =
        packet.redactedSharePacket['institutionFacts'] as List<Object>;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Paquete redactado firmado',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.ios_share_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hash: ${packet.redactedPacketHash.substring(0, 16)}',
              style: text.bodySmall,
            ),
            Text(
              'Firma: ${packet.signature.substring(0, 16)} (${packet.keyStore})',
              style: text.bodySmall,
            ),
            const SizedBox(height: 8),
            Text('Datos compartibles', style: text.labelLarge),
            const SizedBox(height: 4),
            Text(
              'Pseudonimo: ${packet.redactedSharePacket['citizenPseudonym']}',
              style: text.bodySmall,
            ),
            Text(
              'Coincidencias: ${packet.redactedSharePacket['localMatches']}',
              style: text.bodySmall,
            ),
            Text('Claims: ${claims.join(', ')}', style: text.bodySmall),
            Text(
              'Fuentes redactadas: ${institutionFacts.length}',
              style: text.bodySmall,
            ),
            const Divider(height: 24),
            for (final trace in packet.trace)
              Text(trace, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AuditArchivePanel extends StatelessWidget {
  const _AuditArchivePanel({required this.receipt, required this.onClear});

  final AuditArchiveReceipt receipt;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Archivo de auditoria local',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.inventory_2_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Text('Hash: ${receipt.recordHash.substring(0, 16)}'),
            Text('Ubicacion: ${receipt.location}', style: text.bodySmall),
            Text('Registros: ${receipt.recordCount}', style: text.bodySmall),
            const Divider(height: 24),
            for (final trace in receipt.trace)
              Text(trace, style: text.bodySmall),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Borrar archivo local'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditArchiveClearedPanel extends StatelessWidget {
  const _AuditArchiveClearedPanel({required this.receipt});

  final AuditArchiveClearReceipt receipt;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Archivo local borrado',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.delete_sweep_outlined),
              ],
            ),
            const SizedBox(height: 8),
            Text('Registros borrados: ${receipt.deletedCount}'),
            Text('Ubicacion: ${receipt.location}', style: text.bodySmall),
            const Divider(height: 24),
            for (final trace in receipt.trace)
              Text(trace, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AuditArchiveErrorPanel extends StatelessWidget {
  const _AuditArchiveErrorPanel({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: color.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No se pudo guardar el recibo de auditoria local: $error',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePreview extends StatelessWidget {
  const _TemplatePreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Denuncia lista',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.description_outlined),
              ],
            ),
            const SizedBox(height: 10),
            SelectableText(text),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
