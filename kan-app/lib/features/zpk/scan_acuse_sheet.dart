import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../services/multimodal/qr_service.dart';
import '../../services/zpk/institution_trust_list.dart';
import '../../services/zpk/packet_envelope.dart';
import '../../services/zpk/signature_verifier.dart';

/// Permite al ciudadano escanear un acuse firmado por la ventanilla y ver
/// la verificacion criptografica del lado institucional.
Future<PacketEnvelope?> scanAcuseFromInstitution(BuildContext context) async {
  final wire = await Navigator.of(
    context,
  ).push<String>(MaterialPageRoute(builder: (_) => const _AcuseScannerPage()));
  if (wire == null) return null;
  if (!QrService.looksLikeZpk(wire)) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese QR no es un acuse ZPK.')),
      );
    }
    return null;
  }
  final packet = QrService.decode(wire);
  final verifier = HmacSignatureVerifier(
    keyResolver: InstitutionTrustList.buildResolver(),
  );
  final result = verifier.verify(packet);
  if (!context.mounted) return null;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _AcuseResultSheet(packet: packet, result: result),
  );
  return packet;
}

class _AcuseScannerPage extends StatefulWidget {
  const _AcuseScannerPage();
  @override
  State<_AcuseScannerPage> createState() => _AcuseScannerPageState();
}

class _AcuseScannerPageState extends State<_AcuseScannerPage> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear acuse de ventanilla')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          final code = capture.barcodes.first.rawValue;
          if (code != null && mounted) {
            Navigator.of(context).pop(code);
          }
        },
      ),
    );
  }
}

class _AcuseResultSheet extends StatelessWidget {
  const _AcuseResultSheet({required this.packet, required this.result});
  final PacketEnvelope packet;
  final VerifyResult result;

  @override
  Widget build(BuildContext context) {
    final ok = result.isValid && packet.type == PacketType.acuse;
    final color = ok
        ? Theme.of(context).colorScheme.tertiaryContainer
        : Theme.of(context).colorScheme.errorContainer;
    return SafeArea(
      child: Container(
        color: color,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  ok ? 'Acuse valido' : 'Acuse invalido',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (!ok)
              Text(
                result.findings.isEmpty
                    ? 'El packet no es de tipo acuse.'
                    : 'Hallazgos: ${result.findings.join(", ")}',
                style: const TextStyle(fontSize: 12),
              ),
            const Divider(),
            _kv(
              'Institucion',
              InstitutionTrustList.labelFor(packet.issuer.keyId) ??
                  packet.issuer.label ??
                  packet.issuer.pseudo,
            ),
            _kv('Decision', packet.decision ?? '-'),
            _kv('Ticket', packet.ticket ?? '-'),
            _kv('En respuesta a', packet.inResponseTo ?? '-', mono: true),
            _kv('Fecha', packet.issuedAt.toIso8601String().substring(0, 19)),
            if (packet.nextStepText != null) ...[
              const SizedBox(height: 8),
              Text(
                packet.nextStepText!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
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

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
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
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    ),
  );
}
