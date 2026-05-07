import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/multimodal/qr_service.dart';
import '../../services/zpk/institution_trust_list.dart';
import '../../services/zpk/packet_envelope.dart';
import '../../services/zpk/signature_verifier.dart';
import 'widgets/received_packet_card.dart';

/// Modo Ventanilla: el funcionario escanea el QR del ciudadano, verifica
/// firma localmente, decide atender / firmar acuse / rechazar.
///
/// Esta es la otra cara del protocolo ZPK. Misma APK, otro rol.
class VentanillaHome extends StatefulWidget {
  const VentanillaHome({
    super.key,
    this.institutionKeyId = 'igss-mesa-demo-key',
    this.institutionLabel = 'IGSS — Mesa Quetzaltenango',
    this.onExitToCitizen,
  });

  final String institutionKeyId;
  final String institutionLabel;
  final VoidCallback? onExitToCitizen;

  @override
  State<VentanillaHome> createState() => _VentanillaHomeState();
}

class _VentanillaHomeState extends State<VentanillaHome> {
  final _verifier = HmacSignatureVerifier(
    keyResolver: InstitutionTrustList.buildResolver(),
  );
  PacketEnvelope? _received;
  VerifyResult? _result;
  PacketEnvelope? _acuse;
  String? _acuseWire;
  final List<_LedgerEntry> _ledger = [];

  Future<void> _openScanner() async {
    final wire = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const _ScannerPage()));
    if (wire == null || !mounted) return;
    if (!QrService.looksLikeZpk(wire)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ese QR no es un packet ZPK.')),
      );
      return;
    }
    try {
      final packet = QrService.decode(wire);
      final result = _verifier.verify(packet);
      setState(() {
        _received = packet;
        _result = result;
        _acuse = null;
        _acuseWire = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No pude leer el packet: $e')));
    }
  }

  void _signAcuse() {
    final packet = _received;
    if (packet == null) return;
    final secret = InstitutionTrustList.demoKeys[widget.institutionKeyId];
    if (secret == null) return;

    final unsigned = PacketEnvelope(
      type: PacketType.acuse,
      caseCode: packet.caseCode,
      issuedAt: DateTime.now(),
      issuer: PacketIssuer(
        kind: PacketIssuerKind.institution,
        pseudo: 'zpk:${widget.institutionKeyId}',
        keyId: widget.institutionKeyId,
        label: widget.institutionLabel,
      ),
      audience: PacketAudience(institution: packet.issuer.pseudo),
      inResponseTo: packet.hash(),
      decision: 'atendido',
      ticket: 'TKT-${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
      nextStepText: 'Presentarse en la mesa con identificacion alterna.',
    );
    final sig = HmacSignatureVerifier.signWithSecret(
      packet: unsigned,
      secret: secret,
    );
    final signed = unsigned.withSig(sig);
    final wire = QrService.encode(signed);
    setState(() {
      _acuse = signed;
      _acuseWire = wire;
      _ledger.insert(
        0,
        _LedgerEntry(
          when: DateTime.now(),
          ticket: signed.ticket!,
          caseCode: signed.caseCode,
          pseudo: packet.issuer.pseudo,
        ),
      );
    });
  }

  void _reject() {
    final packet = _received;
    if (packet == null) return;
    setState(() {
      _ledger.insert(
        0,
        _LedgerEntry(
          when: DateTime.now(),
          ticket: 'RECHAZO-${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
          caseCode: packet.caseCode,
          pseudo: packet.issuer.pseudo,
          rejected: true,
        ),
      );
      _received = null;
      _result = null;
      _acuse = null;
      _acuseWire = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        title: Text(widget.institutionLabel),
        actions: [
          if (widget.onExitToCitizen != null)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'Volver a Modo Ciudadano',
              onPressed: widget.onExitToCitizen,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Escanear QR del ciudadano',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_received != null && _result != null) ...[
                ReceivedPacketCard(
                  packet: _received!,
                  verifyResult: _result!,
                  onSignAcuse: _signAcuse,
                  onReject: _reject,
                ),
                const SizedBox(height: 16),
              ],
              if (_acuse != null && _acuseWire != null) ...[
                _AcuseCard(packet: _acuse!, wire: _acuseWire!),
                const SizedBox(height: 16),
              ],
              if (_ledger.isNotEmpty) ...[
                Text(
                  'Atenciones de hoy (${_ledger.length})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Column(
                    children: _ledger
                        .map(
                          (e) => ListTile(
                            dense: true,
                            leading: Icon(
                              e.rejected ? Icons.cancel : Icons.check_circle,
                              color: e.rejected ? Colors.red : Colors.green,
                            ),
                            title: Text(
                              e.ticket,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                            subtitle: Text('${e.caseCode} · ${e.pseudo}'),
                            trailing: Text(
                              '${e.when.hour.toString().padLeft(2, '0')}:${e.when.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerEntry {
  _LedgerEntry({
    required this.when,
    required this.ticket,
    required this.caseCode,
    required this.pseudo,
    this.rejected = false,
  });
  final DateTime when;
  final String ticket;
  final String caseCode;
  final String pseudo;
  final bool rejected;
}

class _AcuseCard extends StatelessWidget {
  const _AcuseCard({required this.packet, required this.wire});
  final PacketEnvelope packet;
  final String wire;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('acuse-card'),
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Acuse firmado para el ciudadano',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ticket: ${packet.ticket}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: wire,
                version: QrVersions.auto,
                size: 240,
                errorCorrectionLevel: QrService.errorCorrectionLevel,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pidale al ciudadano que escanee este QR.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();
  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
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
      appBar: AppBar(title: const Text('Escanear QR')),
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
