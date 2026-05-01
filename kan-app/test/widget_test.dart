import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kan_app/main.dart';

void main() {
  testWidgets('offline demo verifies exposed synthetic CUI', (tester) async {
    await tester.pumpWidget(const KanApp());

    expect(find.text('Kan'), findsOneWidget);
    expect(find.text('Modo local'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.verified_user_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Coincidencia encontrada'), findsOneWidget);
    expect(
      find.textContaining(
        'load_breach_catalog(asset:assets/breach_catalog.json)',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('verify_dpi_in_local_leaks(local)'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('Denuncia lista'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid CUI stays local and does not generate document', (
    tester,
  ) async {
    await tester.pumpWidget(const KanApp());

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    await tester.ensureVisible(find.text('Verificar y generar guia'));
    await tester.tap(find.text('Verificar y generar guia'));
    await _pumpUntilFound(tester, find.text('CUI invalido'));
    await tester.drag(find.byType(ListView), const Offset(0, -240));
    await tester.pump();

    if (find.text('CUI invalido').evaluate().isEmpty) {
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .join(' | ');
      fail('Expected invalid CUI panel. Visible text: $texts');
    }

    expect(find.text('CUI invalido'), findsOneWidget);
    expect(
      find.textContaining('No se consulto ningun servidor'),
      findsOneWidget,
    );
    expect(find.text('Denuncia lista'), findsNothing);
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
}
