import 'package:flutter/material.dart';

import '../../../services/zpk/institution_trust_list.dart';
import '../../../services/zpk/packet_envelope.dart';
import '../../../services/zpk/signature_verifier.dart';
import 'field_diff_view.dart';

/// Tarjeta principal de la ventanilla: muestra el packet recibido, el
/// resultado de la verificacion criptografica y los botones de accion.
class ReceivedPacketCard extends StatelessWidget {
  const ReceivedPacketCard({
    super.key,
    required this.packet,
    required this.verifyResult,
    this.onSignAcuse,
    this.onReject,
  });

  final PacketEnvelope packet;
  final VerifyResult verifyResult;
  final VoidCallback? onSignAcuse;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final ok = verifyResult.isValid;
    final color = ok
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    return Card(
      key: const ValueKey('received-packet-card'),
      elevation: 0,
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  ok ? Icons.verified : Icons.gpp_bad,
                  color: ok ? Colors.green.shade800 : Colors.red.shade800,
                ),
                const SizedBox(width: 8),
                Text(
                  ok ? 'Firma valida' : 'Firma invalida',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!ok)
              Text(
                'Hallazgos: ${verifyResult.findings.join(", ")}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            const Divider(height: 20),
            _row('Tipo', packet.type.code),
            _row('Caso', packet.caseCode),
            _row('Pseudonimo', packet.issuer.pseudo, mono: true),
            _row('KeyId', packet.issuer.keyId, mono: true),
            _row(
              'Conocido en trust list',
              InstitutionTrustList.demoKeys.containsKey(packet.issuer.keyId)
                  ? 'si'
                  : 'no',
            ),
            _row('Hash artifact', packet.artifactRef?.hash ?? '-', mono: true),
            _row('Emitido', packet.issuedAt.toIso8601String().substring(0, 19)),
            if (packet.policy?.expiresAt != null)
              _row(
                'Expira',
                packet.policy!.expiresAt!.toIso8601String().substring(0, 19),
              ),
            const SizedBox(height: 12),
            FieldDiffView(packet: packet),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: ok ? onSignAcuse : null,
                  icon: const Icon(Icons.draw, size: 18),
                  label: const Text('Firmar acuse'),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('Rechazar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              k,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
