import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

import '../models/kan_case.dart';

class ThreatBulletin {
  const ThreatBulletin({
    required this.id,
    required this.sourceUrl,
    required this.publishedOn,
    required this.region,
    required this.riskPattern,
    required this.affectedFields,
    required this.recommendedAction,
    required this.sha256,
    this.trustedKeyId = 'zpk-civic-bulletin-pack-2026-05',
  });

  final String id;
  final String sourceUrl;
  final String publishedOn;
  final String region;
  final String riskPattern;
  final List<String> affectedFields;
  final String recommendedAction;
  final String sha256;
  final String trustedKeyId;

  String get canonicalPayload => [
    id,
    sourceUrl,
    publishedOn,
    region,
    riskPattern,
    affectedFields.join(','),
    recommendedAction,
  ].join('|');

  String get computedSha256 =>
      crypto.sha256.convert(utf8.encode(canonicalPayload)).toString();

  bool get hasValidHash => computedSha256 == sha256;
}

class ThreatBulletinMatch {
  const ThreatBulletinMatch({
    required this.bulletin,
    required this.overlappingFields,
  });

  final ThreatBulletin bulletin;
  final List<String> overlappingFields;

  String get trace =>
      'threat_bulletin.match(${bulletin.id}) -> ${overlappingFields.join('+')}';
}

class LocalThreatBulletinCatalog {
  const LocalThreatBulletinCatalog({this.bulletins = fallbackBulletins});

  final List<ThreatBulletin> bulletins;

  static const fallbackBulletins = [
    ThreatBulletin(
      id: 'gt-dpi-fraud-ngo-2026-04',
      sourceUrl: 'local://zpk/bulletins/gt-dpi-fraud-ngo-2026-04',
      publishedOn: '2026-04-28',
      region: 'Guatemala',
      riskPattern: 'dpi_photo_identity_theft',
      affectedFields: ['CUI', 'nombre', 'telefono', 'direccion'],
      recommendedAction:
          'Preparar denuncia preliminar, alertas bancarias y bloqueo preventivo de tramites no reconocidos.',
      sha256:
          '494f8fc910dd769400eecd5fd6c8b7679312fd1a67ac8167a91e1903630456f3',
    ),
    ThreatBulletin(
      id: 'latam-sim-swap-cui-2026-04',
      sourceUrl: 'local://zpk/bulletins/latam-sim-swap-cui-2026-04',
      publishedOn: '2026-04-30',
      region: 'America Latina',
      riskPattern: 'sim_swap_identity_recovery',
      affectedFields: ['CUI', 'telefono', 'correo'],
      recommendedAction:
          'Recomendar cambio de claves, bloqueo SIM preventivo y verificacion de cuentas vinculadas.',
      sha256:
          '158f93f4e07f151b20c67842d057fc714fcc0537bd13dfd8493b7f8e157d0ac0',
    ),
    ThreatBulletin(
      id: 'gt-public-services-account-takeover-2026-05',
      sourceUrl:
          'local://zpk/bulletins/gt-public-services-account-takeover-2026-05',
      publishedOn: '2026-05-01',
      region: 'Guatemala',
      riskPattern: 'public_services_account_takeover',
      affectedFields: ['CUI', 'correo', 'direccion'],
      recommendedAction:
          'Generar paquete redacted para institucion y conservar evidencia local cifrada.',
      sha256:
          'e699418df9642c71f7d451e1560f568e8f1fe80c0fe1cca3149513617ccfee6b',
    ),
  ];

  int get verifiedCount =>
      bulletins.where((bulletin) => bulletin.hasValidHash).length;

  List<ThreatBulletinMatch> match({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    if (!result.isValidCui) {
      return const [];
    }

    final exposedFields = result.matches
        .expand((match) => match.exposedFields)
        .map(_normalizeField)
        .toSet();
    if (exposedFields.isEmpty && scenario == CaseScenario.preventive) {
      exposedFields.addAll(const {'cui', 'telefono', 'correo'});
    }

    final matches = <ThreatBulletinMatch>[];
    for (final bulletin in bulletins.where((item) => item.hasValidHash)) {
      final overlap = bulletin.affectedFields
          .where((field) => exposedFields.contains(_normalizeField(field)))
          .toList();
      if (overlap.isNotEmpty) {
        matches.add(
          ThreatBulletinMatch(bulletin: bulletin, overlappingFields: overlap),
        );
      }
    }

    matches.sort((a, b) {
      final overlapCompare = b.overlappingFields.length.compareTo(
        a.overlappingFields.length,
      );
      if (overlapCompare != 0) {
        return overlapCompare;
      }
      final countryCompare = _countryRank(
        a.bulletin.region,
      ).compareTo(_countryRank(b.bulletin.region));
      if (countryCompare != 0) {
        return countryCompare;
      }
      return b.bulletin.publishedOn.compareTo(a.bulletin.publishedOn);
    });
    return matches.take(2).toList(growable: false);
  }

  static int _countryRank(String region) => region == 'Guatemala' ? 0 : 1;

  static String _normalizeField(String field) => field.toLowerCase().trim();
}
