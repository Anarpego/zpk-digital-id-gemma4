import 'package:flutter/material.dart';

import '../../../services/zpk/packet_envelope.dart';

/// Muestra los campos del packet recibido vs los que el ciudadano omitio
/// (redacted). El ojo del funcionario debe entender en 2 segundos que la
/// institucion solo recibio lo minimo necesario.
class FieldDiffView extends StatelessWidget {
  const FieldDiffView({super.key, required this.packet});

  final PacketEnvelope packet;

  @override
  Widget build(BuildContext context) {
    final received = packet.fields.entries.toList();
    final redacted = packet.redacted;

    return Card(
      key: const ValueKey('field-diff-view'),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campos del paquete',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Recibidos (${received.length})',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            ...received.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(
                            context,
                          ).style.copyWith(fontSize: 13),
                          children: [
                            TextSpan(
                              text: '${e.key}: ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(text: e.value.toString()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (redacted.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Omitidos por el ciudadano (${redacted.length})',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              ...redacted.map(
                (k) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, size: 16, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          k,
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const Text(
                        '[REDACTADO]',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
