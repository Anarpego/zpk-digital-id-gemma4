import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/features/citizen/citizen_home.dart';

void main() {
  testWidgets('renderiza pregunta inicial y boton de envio', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CitizenHome()));

    expect(find.text('Que te paso?'), findsOneWidget);
    expect(find.text('Ayudame ahora'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
  });

  testWidgets('correr el agente popula el panel con steps', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CitizenHome()));

    await tester.enterText(
      find.byType(TextField),
      'me dijeron que me van a matar si no pago',
    );
    await tester.tap(find.text('Ayudame ahora'));
    // Settle deja correr el stream completo (delay de 180ms entre steps).
    await tester.pumpAndSettle(const Duration(seconds: 30));

    expect(find.byKey(const ValueKey('agent-stream-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('artifact-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('privacy-diff-card')), findsOneWidget);
    expect(find.textContaining('extorsion'), findsAtLeast(1));
  });

  testWidgets('hay boton de mic y de camara visibles', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CitizenHome()));
    expect(find.byIcon(Icons.mic_none), findsOneWidget);
    expect(find.byIcon(Icons.photo_camera_outlined), findsOneWidget);
  });
}
