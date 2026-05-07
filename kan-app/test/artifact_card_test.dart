import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/features/citizen/widgets/artifact_card.dart';
import 'package:kan_app/models/generated_artifact.dart';
import 'package:kan_app/services/platform_share_service.dart';

void main() {
  testWidgets('Compartir abre el share real con documento y siguientes pasos', (
    tester,
  ) async {
    final sharer = _RecordingSharer();
    final artifact = GeneratedArtifact(
      type: 'denuncia_mp',
      titulo: 'Denuncia formal para MINISTERIO PUBLICO',
      contenidoMd: 'Me amenazan por WhatsApp si no pago hoy.',
      camposClave: const {'caso': 'extorsion'},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArtifactCard(
            artifact: artifact,
            nextSteps: const ['Guarda capturas', 'No contestes ni pagues'],
            sharer: sharer,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Compartir'));
    await tester.pump();

    expect(sharer.title, 'Denuncia formal para MINISTERIO PUBLICO');
    expect(sharer.text, contains('Me amenazan por WhatsApp'));
    expect(sharer.text, contains(artifact.hashSha256));
    expect(sharer.text, contains('- Guarda capturas'));
    expect(find.text('Menu de compartir abierto'), findsOneWidget);
  });
}

class _RecordingSharer implements ArtifactSharer {
  String? title;
  String? text;

  @override
  Future<void> shareText({required String title, required String text}) async {
    this.title = title;
    this.text = text;
  }
}
