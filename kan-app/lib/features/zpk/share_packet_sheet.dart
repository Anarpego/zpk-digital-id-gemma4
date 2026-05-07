import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/generated_artifact.dart';
import '../../services/multimodal/qr_service.dart';
import '../../services/zpk/institution_trust_list.dart';
import '../../services/zpk/packet_envelope.dart';
import '../../services/zpk/signature_verifier.dart';

/// Bottom sheet que arma el packet ZPK firmado a partir del artifact y lo
/// muestra como QR escaneable por una ventanilla institucional.
Future<void> showSharePacketSheet({
  required BuildContext context,
  required GeneratedArtifact artifact,
  required String caseCode,
  String? institutionLabel,
}) async {
  final packet = _buildPacket(
    artifact: artifact,
    caseCode: caseCode,
    institutionLabel: institutionLabel,
  );
  final wire = QrService.encode(packet);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _SharePacketSheet(wire: wire, packet: packet),
  );
}

PacketEnvelope _buildPacket({
  required GeneratedArtifact artifact,
  required String caseCode,
  String? institutionLabel,
}) {
  const citizenKeyId = 'zpk-citizen-demo-key';
  final citizenSecret = InstitutionTrustList.demoKeys[citizenKeyId]!;

  final unsigned = PacketEnvelope(
    type: PacketType.intake,
    caseCode: caseCode,
    issuedAt: DateTime.now(),
    issuer: PacketIssuer(
      kind: PacketIssuerKind.citizen,
      pseudo: artifact.camposClave['pseudonimo'] ?? 'zpk:citizen-local',
      keyId: citizenKeyId,
      label: 'Ciudadano local',
    ),
    audience: institutionLabel != null
        ? PacketAudience(institution: institutionLabel)
        : null,
    fields: {
      'titulo': artifact.titulo,
      'caso': caseCode,
      ...artifact.camposClave,
    },
    redacted: const [
      'cui',
      'telefono',
      'direccion_completa',
      'fecha_nacimiento',
    ],
    artifactRef: PacketArtifactRef(
      type: artifact.type,
      hash: artifact.hashSha256,
    ),
    policy: PacketPolicy(
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      singleUse: true,
    ),
  );

  final sig = HmacSignatureVerifier.signWithSecret(
    packet: unsigned,
    secret: citizenSecret,
  );
  return unsigned.withSig(sig);
}

class _SharePacketSheet extends StatelessWidget {
  const _SharePacketSheet({required this.wire, required this.packet});

  final String wire;
  final PacketEnvelope packet;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QR firmado del paquete',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'La ventanilla escanea esto. Verifica firma en su telefono. '
              'Cero red.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: QrImageView(
                  data: wire,
                  version: QrVersions.auto,
                  size: 280,
                  errorCorrectionLevel: QrService.errorCorrectionLevel,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _MetaRow(label: 'Tipo', value: packet.type.code),
            _MetaRow(label: 'Caso', value: packet.caseCode),
            _MetaRow(
              label: 'Pseudonimo',
              value: packet.issuer.pseudo,
              mono: true,
            ),
            _MetaRow(
              label: 'Hash artifact',
              value: packet.artifactRef?.hash ?? '-',
              mono: true,
            ),
            _MetaRow(label: 'Tamano payload', value: '${wire.length} chars'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.mono = false});
  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontFamily: mono ? 'monospace' : null,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
