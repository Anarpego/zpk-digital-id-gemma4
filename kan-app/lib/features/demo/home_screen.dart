import 'package:flutter/material.dart';

import '../../models/kan_case.dart';
import '../../services/kan_reasoner.dart';
import '../../services/legal_template_service.dart';
import '../../services/local_breach_catalog.dart';
import '../../services/mock_reasoner.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    Object? reasoner,
    this.reasonerLabel = 'Mock local',
  }) : reasoner = reasoner is KanReasoner ? reasoner : const MockReasoner();

  final KanReasoner reasoner;
  final String reasonerLabel;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController(text: '1234567890101');
  final _templates = const LegalTemplateService();
  late final Future<LocalBreachCatalog> _catalog;

  CaseScenario _scenario = CaseScenario.discoveredVictim;
  VerificationResult? _result;
  ReasonedGuidance? _guidance;
  String? _complaint;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
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
    final complaint = result.isValidCui
        ? _templates.buildComplaint(result: result, scenario: _scenario)
        : null;

    setState(() {
      _result = result;
      _guidance = guidance;
      _complaint = complaint;
      _isVerifying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kan'),
        actions: [
          const _StatusChip(icon: Icons.lock_outline, label: 'Modo local'),
          _StatusChip(icon: Icons.memory_outlined, label: widget.reasonerLabel),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              'Verifique un DPI y prepare una denuncia',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Demo con datos sinteticos. El CUI se procesa en el dispositivo.',
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
                    ? 'Verificando en local'
                    : 'Verificar y generar guia',
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
