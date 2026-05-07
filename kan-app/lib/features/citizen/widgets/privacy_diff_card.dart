import 'package:flutter/material.dart';

/// Tarjeta plegable que muestra al ciudadano que datos suyos NO salieron del
/// telefono. Convierte la promesa de privacidad en evidencia visible.
class PrivacyDiffCard extends StatelessWidget {
  const PrivacyDiffCard({
    super.key,
    required this.redactedCategories,
    this.redactedCount = 0,
  });

  /// Lista de categorias que el privacy_guard bloqueo, p.ej. ['dpi_cui', 'telefono'].
  final List<String> redactedCategories;
  final int redactedCount;

  static const _labels = <String, String>{
    'dpi_cui': 'Tu DPI/CUI',
    'telefono': 'Tu telefono',
    'email': 'Tu email',
    'direccion': 'Tu direccion completa',
  };

  @override
  Widget build(BuildContext context) {
    final hasRedactions = redactedCategories.isNotEmpty;
    final color = hasRedactions
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.surfaceContainerLow;
    return Card(
      key: const ValueKey('privacy-diff-card'),
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.shield_outlined),
        title: Text(
          hasRedactions
              ? 'Datos bloqueados antes de pensar'
              : 'No se detectaron datos sensibles',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: hasRedactions
            ? Text(
                '${redactedCategories.length} categoria(s) protegida(s)',
                style: const TextStyle(fontSize: 12),
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: hasRedactions
                  ? redactedCategories.map(_renderCategory).toList()
                  : [
                      const Text(
                        'No detecte DPI, telefono, email ni direcciones en lo que escribiste. '
                        'Si el documento final menciona algun dato sensible, fue porque lo '
                        'agrego una herramienta local del agente con autorizacion explicita.',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderCategory(String code) {
    final label = _labels[code] ?? code;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.lock, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
          ),
          const Text(
            '[BLOQUEADO]',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
