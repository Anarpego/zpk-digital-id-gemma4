import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/generated_artifact.dart';
import '../../../services/multimodal/tts_service.dart';
import '../../../services/platform_share_service.dart';

/// Tarjeta del documento generado al final del loop. Muestra titulo,
/// contenido completo y los botones para usarlo en la vida real.
class ArtifactCard extends StatelessWidget {
  const ArtifactCard({
    super.key,
    required this.artifact,
    required this.nextSteps,
    this.tts,
    this.onShowQr,
    this.sharer = const PlatformArtifactSharer(),
  });

  final GeneratedArtifact artifact;
  final List<String> nextSteps;
  final TtsService? tts;
  final VoidCallback? onShowQr;
  final ArtifactSharer sharer;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('artifact-card'),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    artifact.titulo,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              artifact.hashSha256,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Divider(height: 24),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: SelectableText(
                  artifact.contenidoMd,
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (nextSteps.isNotEmpty) ...[
              Text(
                'Siguientes pasos',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...nextSteps.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(s)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                ),
                if (tts != null)
                  OutlinedButton.icon(
                    onPressed: () => _speak(context),
                    icon: const Icon(Icons.volume_up_outlined, size: 18),
                    label: const Text('Escuchar'),
                  ),
                if (onShowQr != null)
                  OutlinedButton.icon(
                    onPressed: onShowQr,
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('QR firmado'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _share(context),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Compartir'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: artifact.contenidoMd));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Documento copiado')));
  }

  Future<void> _speak(BuildContext context) async {
    final svc = tts;
    if (svc == null) return;
    final preview = artifact.contenidoMd.length > 600
        ? '${artifact.contenidoMd.substring(0, 600)}... continua en pantalla'
        : artifact.contenidoMd;
    await svc.speak('${artifact.titulo}. $preview');
  }

  Future<void> _share(BuildContext context) async {
    try {
      await sharer.shareText(title: artifact.titulo, text: _shareBody());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Menu de compartir abierto')),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _shareBody()));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pude abrir compartir; documento copiado'),
        ),
      );
    }
  }

  String _shareBody() {
    final out = StringBuffer()
      ..writeln(artifact.titulo)
      ..writeln(artifact.hashSha256)
      ..writeln()
      ..writeln(artifact.contenidoMd.trim());
    if (nextSteps.isNotEmpty) {
      out
        ..writeln()
        ..writeln('Siguientes pasos:');
      for (final step in nextSteps) {
        out.writeln('- $step');
      }
    }
    return out.toString().trimRight();
  }
}
