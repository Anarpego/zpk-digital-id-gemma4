import 'package:flutter_test/flutter_test.dart';
import 'package:kan_app/models/kan_case.dart';
import 'package:kan_app/services/identity_protection_agent.dart';
import 'package:kan_app/services/local_breach_catalog.dart';

void main() {
  test('classifies exposed identity cases and blocks PII remote routing', () {
    final result = LocalBreachCatalog().verify('1234567890101');
    final assessment = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.discoveredVictim,
    );

    expect(assessment.riskLevel, IdentityRiskLevel.critical);
    expect(assessment.route.sendsPersonalData, isFalse);
    expect(
      assessment.toolTrace,
      contains('select_privacy_route(local_model) -> pii_block_ok'),
    );
    expect(
      assessment.toolTrace,
      contains('threat_bulletin.verify(offline_hash_pack) -> 8/8_hash_ok'),
    );
    expect(
      assessment.toolTrace,
      contains(
        'threat_bulletin.match(CUI+correo+nombre+telefono) -> gt-dpi-fraud-ngo-2026-04,latam-sim-swap-cui-2026-04',
      ),
    );
    expect(assessment.toPromptBlock(), contains('plan_guatemala'));
    expect(assessment.toPromptBlock(), contains('patron_latam'));
    expect(
      assessment.toPromptBlock(),
      contains('boletines_publicos_verificados'),
    );
    expect(assessment.toPromptBlock(), isNot(contains(result.cui)));
  });

  test('adds offline action tools for extortion and economic fraud', () {
    final result = LocalBreachCatalog().verify('1111111111111');

    final extortion = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.extortionThreat,
    );
    expect(extortion.riskLevel, IdentityRiskLevel.critical);
    expect(
      extortion.toolTrace,
      contains(
        'preserve_evidence(threat_or_extortion) -> sealed_local_timeline+redacted_report',
      ),
    );
    expect(
      extortion.toolTrace,
      contains(
        'prepare_action_packet(guatemala_extortion_evidence) -> safety_steps+sealed_evidence+redacted_complaint',
      ),
    );

    final fraud = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.remittanceFraud,
    );
    expect(fraud.riskLevel, IdentityRiskLevel.high);
    expect(
      fraud.toolTrace,
      contains(
        'economic_fraud_triage(loan_remittance_employment_scam) -> freeze_checklist+institution_packet',
      ),
    );
  });

  test('adds institutional scale tools for public services and field access', () {
    final result = LocalBreachCatalog().verify('1111111111111');

    final publicService = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.publicServiceBreach,
    );
    expect(publicService.riskLevel, IdentityRiskLevel.high);
    expect(
      publicService.toolTrace,
      contains(
        'institution_recovery_packet(public_service_or_registry_breach) -> redacted_claim+presence_proof+review_request',
      ),
    );

    final fieldAccess = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.fieldAccess,
    );
    expect(fieldAccess.riskLevel, IdentityRiskLevel.high);
    expect(
      fieldAccess.toolTrace,
      contains(
        'field_access_voucher(school_clinic_aid_without_connectivity) -> limited_claim+offline_qr+no_document_copy',
      ),
    );

    final igss = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.igssRegistration,
    );
    expect(igss.riskLevel, IdentityRiskLevel.high);
    expect(
      igss.toolTrace,
      contains(
        'igss_registration_agent(social_security_registration_or_recovery) -> eligibility_checklist+presence_proof+institution_intake',
      ),
    );

    final sat = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.satTaxAccess,
    );
    expect(
      sat.toolTrace,
      contains(
        'sat_access_agent(tax_portal_access_or_update) -> portal_safety_check+redacted_update_packet',
      ),
    );

    final school = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.schoolEnrollment,
    );
    expect(
      school.toolTrace,
      contains(
        'education_enrollment_agent(school_or_university_registration) -> guardian_consent+limited_student_claim+institution_intake',
      ),
    );

    final protection = const IdentityProtectionAgent().assess(
      result: result,
      scenario: CaseScenario.violenceCoercion,
    );
    expect(protection.riskLevel, IdentityRiskLevel.critical);
    expect(
      protection.toolTrace,
      contains(
        'coercion_safety_plan(identity_threat_with_personal_safety_risk) -> sealed_timeline+safe_contact_summary',
      ),
    );
  });

  test(
    'allows institution intake without CUI but does not emit identity risk proof',
    () {
      final result = LocalBreachCatalog().verify('');
      final assessment = const IdentityProtectionAgent().assess(
        result: result,
        scenario: CaseScenario.igssRegistration,
      );

      expect(assessment.riskLevel, IdentityRiskLevel.medium);
      expect(assessment.route.route, InferenceRoute.localGemma);
      expect(
        assessment.toolTrace,
        contains('validate_cui(local_only) -> not_available_checklist_only'),
      );
      expect(
        assessment.toolTrace,
        contains(
          'prepare_action_packet(guatemala_igss_registration) -> igss_checklist+redacted_intake+appointment_packet',
        ),
      );
    },
  );
}
