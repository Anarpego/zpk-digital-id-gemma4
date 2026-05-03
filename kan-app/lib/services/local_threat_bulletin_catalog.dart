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
    ThreatBulletin(
      id: 'gt-extortion-identity-safety-2026-05',
      sourceUrl: 'local://zpk/bulletins/gt-extortion-identity-safety-2026-05',
      publishedOn: '2026-05-02',
      region: 'Guatemala',
      riskPattern: 'extortion_identity_threat',
      affectedFields: ['CUI', 'telefono', 'direccion'],
      recommendedAction:
          'Preservar evidencia, no confrontar al agresor y preparar paquete redactado para denuncia y apoyo institucional.',
      sha256:
          'a40c7469773de73675213d5dc6fc708a9bf1953926e847f888f59ddb93167b07',
    ),
    ThreatBulletin(
      id: 'gt-remittance-loan-fraud-2026-05',
      sourceUrl: 'local://zpk/bulletins/gt-remittance-loan-fraud-2026-05',
      publishedOn: '2026-05-02',
      region: 'Guatemala',
      riskPattern: 'remittance_loan_employment_fraud',
      affectedFields: ['CUI', 'telefono', 'correo', 'nombre'],
      recommendedAction:
          'Activar alertas bancarias y telefonicas, documentar pagos y generar paquete para institucion financiera sin CUI completo.',
      sha256:
          'dc2e69eaeba446552b893800bb24f1a1c7f47e30e33587ca89b302f9528cfb6a',
    ),
    ThreatBulletin(
      id: 'gt-public-breach-recovery-2026-05',
      sourceUrl: 'local://zpk/bulletins/gt-public-breach-recovery-2026-05',
      publishedOn: '2026-05-02',
      region: 'Guatemala',
      riskPattern: 'institutional_breach_service_recovery',
      affectedFields: ['CUI', 'correo', 'direccion', 'tramite'],
      recommendedAction:
          'Generar paquete institucional redactado, prueba de presencia local y solicitud de revision sin copiar DPI completo.',
      sha256:
          '9d98030c01adfc686efef9f4ed1f2aca61a16e1806258426ba5a8cfff05c6947',
    ),
    ThreatBulletin(
      id: 'gt-field-access-offline-2026-05',
      sourceUrl: 'local://zpk/bulletins/gt-field-access-offline-2026-05',
      publishedOn: '2026-05-02',
      region: 'Guatemala',
      riskPattern: 'offline_school_clinic_aid_access',
      affectedFields: ['CUI', 'nombre', 'comunidad', 'fecha_nacimiento'],
      recommendedAction:
          'Emitir prueba local limitada para escuela, salud o ayuda humanitaria sin guardar documentos completos.',
      sha256:
          '30279c7b0bd3045ba1dbc3d9f8616399fae09852c09580dd8fa8cfbf609b441e',
    ),
    ThreatBulletin(
      id: 'gt-coercion-violence-identity-2026-05',
      sourceUrl: 'local://zpk/bulletins/gt-coercion-violence-identity-2026-05',
      publishedOn: '2026-05-02',
      region: 'Guatemala',
      riskPattern: 'coercion_violence_identity_safety',
      affectedFields: ['CUI', 'telefono', 'direccion', 'contacto_confianza'],
      recommendedAction:
          'Preservar evidencia local, reducir exposicion digital y preparar resumen seguro para apoyo presencial.',
      sha256:
          'a44f33a324bf879da5ad8f7ce5aa72081c2c5e201a6199f4c3e906caf0912dcd',
    ),
  ];

  int get verifiedCount =>
      bulletins.where((bulletin) => bulletin.hasValidHash).length;

  List<ThreatBulletinMatch> match({
    required VerificationResult result,
    required CaseScenario scenario,
  }) {
    if (!result.isValidCui && !scenario.allowsNoCui) {
      return const [];
    }

    final exposedFields = result.matches
        .expand((match) => match.exposedFields)
        .map(_normalizeField)
        .toSet();
    if (exposedFields.isEmpty) {
      switch (scenario) {
        case CaseScenario.extortionThreat:
          exposedFields.addAll(const {'cui', 'telefono', 'direccion'});
        case CaseScenario.remittanceFraud:
          exposedFields.addAll(const {'cui', 'telefono', 'correo', 'nombre'});
        case CaseScenario.publicServiceBreach:
          exposedFields.addAll(const {'cui', 'correo', 'direccion', 'tramite'});
        case CaseScenario.igssRegistration:
          exposedFields.addAll(const {
            'cui',
            'correo',
            'tramite',
            'historial_laboral',
          });
        case CaseScenario.satTaxAccess:
          exposedFields.addAll(const {'cui', 'correo', 'direccion', 'tramite'});
        case CaseScenario.schoolEnrollment:
          exposedFields.addAll(const {
            'cui',
            'nombre',
            'comunidad',
            'fecha_nacimiento',
          });
        case CaseScenario.fieldAccess:
          exposedFields.addAll(const {
            'cui',
            'nombre',
            'comunidad',
            'fecha_nacimiento',
          });
        case CaseScenario.violenceCoercion:
          exposedFields.addAll(const {
            'cui',
            'telefono',
            'direccion',
            'contacto_confianza',
          });
        case CaseScenario.suspicion:
        case CaseScenario.preventive:
          exposedFields.addAll(const {'cui', 'telefono', 'correo'});
        case CaseScenario.discoveredVictim:
          break;
      }
    }

    final matches = <ThreatBulletinMatch>[];
    for (final bulletin in bulletins.where((item) => item.hasValidHash)) {
      if (!_appliesToScenario(bulletin, scenario)) {
        continue;
      }
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

  static bool _appliesToScenario(
    ThreatBulletin bulletin,
    CaseScenario scenario,
  ) {
    if (bulletin.id == 'gt-extortion-identity-safety-2026-05') {
      return scenario == CaseScenario.extortionThreat;
    }
    if (bulletin.id == 'gt-remittance-loan-fraud-2026-05') {
      return scenario == CaseScenario.remittanceFraud;
    }
    if (bulletin.id == 'gt-public-breach-recovery-2026-05') {
      return scenario == CaseScenario.publicServiceBreach ||
          scenario == CaseScenario.igssRegistration ||
          scenario == CaseScenario.satTaxAccess ||
          scenario == CaseScenario.discoveredVictim;
    }
    if (bulletin.id == 'gt-field-access-offline-2026-05') {
      return scenario == CaseScenario.fieldAccess ||
          scenario == CaseScenario.schoolEnrollment ||
          scenario == CaseScenario.preventive;
    }
    if (bulletin.id == 'gt-coercion-violence-identity-2026-05') {
      return scenario == CaseScenario.violenceCoercion ||
          scenario == CaseScenario.extortionThreat;
    }
    return true;
  }
}
