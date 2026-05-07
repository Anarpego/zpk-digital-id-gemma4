import 'signature_verifier.dart';

/// Trust list del piloto offline: claves que el Modo Ventanilla y el Modo
/// Ciudadano usan para verificar firmas localmente durante el hackathon.
///
/// Honesto: HMAC es simetrico, asi que estos "trust public keys" son en
/// realidad secretos compartidos. En produccion nacional debe migrarse a
/// firmas asimetricas/certificados y publicar solo la parte publica.
///
/// El `citizen-demo-key` es una clave interna del piloto. En produccion cada
/// ciudadano tendria su keypair propio anclado al dispositivo o a una
/// credencial emitida por autoridad confiable.
class InstitutionTrustList {
  static const Map<String, String> demoKeys = {
    'zpk-citizen-demo-key': 'zpk-demo-secret-please-replace-in-prod',
    'igss-mesa-demo-key': 'igss-demo-shared-secret-2026',
    'sat-mesa-demo-key': 'sat-demo-shared-secret-2026',
    'mp-mesa-demo-key': 'mp-demo-shared-secret-2026',
    'mtps-mesa-demo-key': 'mtps-demo-shared-secret-2026',
    'pdh-mesa-demo-key': 'pdh-demo-shared-secret-2026',
    'colegio-mesa-demo-key': 'colegio-demo-shared-secret-2026',
    'pnc-mesa-demo-key': 'pnc-demo-shared-secret-2026',
    'profeco-mesa-demo-key': 'profeco-demo-shared-secret-2026',
    'renap-mesa-demo-key': 'renap-demo-shared-secret-2026',
  };

  static const Map<String, String> labels = {
    'igss-mesa-demo-key': 'IGSS - Mesa piloto',
    'sat-mesa-demo-key': 'SAT - Mesa piloto',
    'mp-mesa-demo-key': 'Ministerio Publico - Mesa piloto',
    'mtps-mesa-demo-key': 'MTPS - Mesa piloto',
    'pdh-mesa-demo-key': 'PDH - Mesa piloto',
    'colegio-mesa-demo-key': 'Colegio - Mesa piloto',
    'pnc-mesa-demo-key': 'PNC - Mesa piloto',
    'profeco-mesa-demo-key': 'DIACO/PROFECO - Mesa piloto',
    'renap-mesa-demo-key': 'RENAP - Mesa piloto',
  };

  static StaticKeyResolver buildResolver() => StaticKeyResolver(demoKeys);

  static String? labelFor(String keyId) => labels[keyId];

  static bool isInstitutionKey(String keyId) =>
      keyId.endsWith('-mesa-demo-key');

  static bool isCitizenKey(String keyId) => keyId.startsWith('zpk-citizen-');
}
