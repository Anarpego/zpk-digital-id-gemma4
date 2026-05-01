import 'package:flutter/material.dart';

import '../../models/kan_case.dart';
import '../../services/audit_archive.dart';
import '../../services/digital_identity_fabric.dart';
import '../../services/identity_protection_agent.dart';
import '../../services/kan_reasoner.dart';
import '../../services/legal_template_service.dart';
import '../../services/local_breach_catalog.dart';
import '../../services/local_authentication_service.dart';
import '../../services/mock_reasoner.dart';
import '../../services/recovery_packet_service.dart';
import '../../services/revocation_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    Object? reasoner,
    this.reasonerLabel = 'Mock local',
    this.identityFabric,
    this.auditArchive,
  }) : reasoner = reasoner is KanReasoner ? reasoner : const MockReasoner();

  final KanReasoner reasoner;
  final String reasonerLabel;
  final DigitalIdentityFabric? identityFabric;
  final AuditArchive? auditArchive;

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
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _trustFabric = widget.identityFabric ?? const DigitalIdentityFabric();
    _packetService = RecoveryPacketService(identityFabric: _trustFabric);
    _revocationService = RevocationService(identityFabric: _trustFabric);
    _authenticationService = LocalAuthenticationService(
      identityFabric: _trustFabric,
    );
    _auditArchive = AuditArchiveService(
      archive: widget.auditArchive ?? MemoryAuditArchive(),
    );
    _catalog = LocalBreachCatalog.loadEmbeddedOrFallback();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
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
      _isVerifying = false;
    });
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
    });
  }

  Future<void> _issueAuthenticationProof() async {
    final result = _result;
    final trustReport = _trustReport;
    if (result == null || trustReport == null) {
      return;
    }
    final proof = await _authenticationService.buildProof(
      result: result,
      scenario: _scenario,
      trustReport: trustReport,
      revocationReceipt: _revocationReceipt,
    );
    setState(() => _authenticationProof = proof);
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZPK Digital ID'),
        actions: [
          const _StatusChip(icon: Icons.lock_outline, label: 'Wallet local'),
          _StatusChip(icon: Icons.memory_outlined, label: widget.reasonerLabel),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Registre, proteja y recupere identidad',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo ZPK con datos sinteticos. El CUI se queda en el dispositivo y solo salen pruebas redactadas.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SegmentedButton<CaseScenario>(
              segments: CaseScenario.values
                  .map(
                    (scenario) => ButtonSegment(
                      value: scenario,
                      label: Text(scenario.label),
                    ),
                  )
                  .toList(),
              selected: {_scenario},
              onSelectionChanged: (selection) {
                setState(() => _scenario = selection.first);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'CUI de prueba',
                helperText: 'Use 1234567890101 para una coincidencia sintetica',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isVerifying ? null : _verify,
              icon: _isVerifying
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(
                _isVerifying
                    ? 'Registrando en local'
                    : 'Registrar ZPK y generar guia',
              ),
            ),
            const SizedBox(height: 20),
            if (_result == null)
              _EmptyState(color: color)
            else ...[
              _ResultPanel(result: _result!),
              const SizedBox(height: 12),
              _GuidancePanel(guidance: _guidance!),
              const SizedBox(height: 12),
              _TrustFabricPanel(report: _trustReport!),
              const SizedBox(height: 12),
              _AuthenticationProofPanel(
                proof: _authenticationProof,
                revocationReceipt: _revocationReceipt,
                onIssue: _issueAuthenticationProof,
              ),
              const SizedBox(height: 12),
              _RevocationPanel(
                receipt: _revocationReceipt,
                onRevoke: _revokeLocalCredential,
              ),
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
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.color});

  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline),
            SizedBox(width: 12),
            Expanded(child: Text('La verificacion local aparecera aqui.')),
          ],
        ),
      ),
    );
  }
}

class _AuthenticationProofPanel extends StatelessWidget {
  const _AuthenticationProofPanel({
    required this.proof,
    required this.revocationReceipt,
    required this.onIssue,
  });

  final LocalAuthenticationProof? proof;
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
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onIssue,
                icon: const Icon(Icons.key_outlined),
                label: const Text('Probar autenticacion local'),
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
            Text('DID y credencial verificable demo', style: text.labelLarge),
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
  const _ResultPanel({required this.result});

  final VerificationResult result;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final icon = result.isExposed ? Icons.warning_amber : Icons.check_circle;
    final title = !result.isValidCui
        ? 'CUI invalido'
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
          ],
        ),
      ),
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
