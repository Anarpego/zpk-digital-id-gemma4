import 'package:kan_app/services/digital_identity_fabric.dart';
import 'package:kan_app/services/identity_signer.dart';

const testIdentityFabric = DigitalIdentityFabric(
  signer: LocalHmacIdentitySigner(
    issuerKeyId: 'zpk-test-issuer-key-2026-05',
    issuerSecret: 'zpk-test-suite-fixture-secret-2026-05',
    keyStore: 'dart-test-hmac',
  ),
);
