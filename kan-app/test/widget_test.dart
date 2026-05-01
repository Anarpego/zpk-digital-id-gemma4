import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kan_app/main.dart';

void main() {
  testWidgets('offline demo verifies exposed synthetic CUI', (tester) async {
    await tester.pumpWidget(const KanApp());

    expect(find.text('ZPK Digital ID'), findsOneWidget);
    expect(find.text('Wallet local'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.verified_user_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Coincidencia encontrada'), findsOneWidget);
    expect(
      find.textContaining(
        'local_breach_lookup(asset:assets/breach_catalog.json)',
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('trust_fabric.issue_consent(local, 15m)'),
      findsOneWidget,
    );
    expect(
      find.textContaining('privacy_guard.raw_cui -> absent'),
      findsOneWidget,
    );
    expect(find.textContaining('agent_ledger.sign'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Registro ZPK local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Registro ZPK local'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Paquete redactado firmado'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Paquete redactado firmado'), findsOneWidget);
    expect(find.textContaining('recovery_packet.sign'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Archivo de auditoria local'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Archivo de auditoria local'), findsOneWidget);
    expect(
      find.textContaining('audit_archive.raw_cui -> omitted'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('invalid CUI stays local and does not generate document', (
    tester,
  ) async {
    await tester.pumpWidget(const KanApp());

    await tester.enterText(find.byType(TextField), '123');
    await tester.pump();
    await tester.ensureVisible(find.text('Registrar ZPK y generar guia'));
    await tester.tap(find.text('Registrar ZPK y generar guia'));
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
