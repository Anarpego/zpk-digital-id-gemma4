import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../services/agent/agent_step.dart';

/// Renderiza el timeline del agent loop como una serie de chips/tarjetas
/// que aparecen una a una a medida que llegan por el stream.
///
/// Es la pieza que hace visible el "razonamiento" del agente — convierte
/// "presione un boton y aparecio magia" en "vi al agente trabajar".
class AgentStreamPanel extends StatelessWidget {
  const AgentStreamPanel({super.key, required this.steps, this.label});

  final List<AgentStep> steps;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      key: const ValueKey('agent-stream-panel'),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Agente razonando',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (label != null)
                  Text(
                    label!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall!.copyWith(color: Colors.black54),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...steps.map(_buildStep),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(AgentStep step) {
    return switch (step) {
      PlanStep p => _Row(
        icon: Icons.psychology_outlined,
        text: p.content,
        italic: true,
      ),
      ToolCallStep t => _ToolChip(tool: t.tool, input: t.input),
      ObservationStep o => _Row(
        icon: Icons.check_circle_outline,
        text: o.content,
      ),
      FinalStep f => _Row(
        icon: Icons.task_alt,
        text: 'Listo: ${f.summary}',
        bold: true,
      ),
      ErrorStep e => _Row(
        icon: Icons.warning_amber,
        text: e.message,
        error: true,
      ),
    };
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.text,
    this.italic = false,
    this.bold = false,
    this.error = false,
  });

  final IconData icon;
  final String text;
  final bool italic;
  final bool bold;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: error ? Colors.red.shade700 : Colors.black54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: base.copyWith(
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                color: error ? Colors.red.shade800 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolChip extends StatelessWidget {
  const _ToolChip({required this.tool, required this.input});
  final String tool;
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context) {
    final compact = jsonEncode(input);
    final shortInput = compact.length > 60
        ? '${compact.substring(0, 57)}...'
        : compact;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.handyman_outlined, size: 18, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tool,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Text(
                  shortInput,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
