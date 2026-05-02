import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/local_breach_catalog.dart';
import 'package:kan_app/services/local_threat_bulletin_catalog.dart';

void main() {
  test('verifies embedded civic threat bulletin hashes', () {
    const catalog = LocalThreatBulletinCatalog();

    expect(catalog.verifiedCount, catalog.bulletins.length);
    expect(
      catalog.bulletins.map((bulletin) => bulletin.hasValidHash),
      everyElement(isTrue),
    );
  });

  test('matches verified bulletins without raw CUI', () {
    final result = LocalBreachCatalog().verify('1234567890101');
    final matches = const LocalThreatBulletinCatalog().match(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );

    expect(matches, isNotEmpty);
    expect(matches.first.bulletin.id, 'gt-dpi-fraud-ngo-2026-04');
    expect(matches.first.trace, isNot(contains(result.cui)));
    expect(matches.first.overlappingFields, contains('CUI'));
  });
}
