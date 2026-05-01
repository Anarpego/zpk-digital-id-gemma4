import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads breach records from bundled offline asset', () async {
    final catalog = await LocalBreachCatalog.loadEmbedded(
      bundle: rootBundle,
      now: DateTime.utc(2026, 5),
    );

    final result = catalog.verify('3012345670101');

    expect(result.isExposed, isTrue);
    expect(result.catalogSource, 'asset:assets/breach_catalog.json');
    expect(result.matches.single.slug, 'banco-social-fake-ngo-2026-04');
  });

  test('detects exposed synthetic CUI locally', () {
    final result = LocalBreachCatalog().verify('1234 56789 0101');

    expect(result.isValidCui, isTrue);
    expect(result.isExposed, isTrue);
    expect(result.catalogSource, 'memory');
    expect(result.matches.single.slug, 'mintrab-tu-empleo-2026-04');
  });

  test('normalizes unknown valid CUI without false positives', () {
    final result = LocalBreachCatalog().verify('1111111111111');

    expect(result.isValidCui, isTrue);
    expect(result.isExposed, isFalse);
  });
}
