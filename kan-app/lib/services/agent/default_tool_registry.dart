import 'package:flutter/foundation.dart';

import '../identity_signer.dart';
import 'tool_registry.dart';
import 'tools/classify_case_tool.dart';
import 'tools/draft_denuncia_tool.dart';
import 'tools/draft_sms_familia_tool.dart';
import 'tools/draft_solicitud_tool.dart';
import 'tools/lookup_codigo_penal_tool.dart';
import 'tools/lookup_codigo_trabajo_tool.dart';
import 'tools/lookup_institucion_tool.dart';
import 'tools/redact_pii_tool.dart';
import 'tools/sign_packet_tool.dart';

/// Construye el registry estandar con las 9 tools del Lote 1.
///
/// Compartido entre el reasoner Gemma (para conocer el schema y reparar
/// inputs invalidos) y el agent_loop (para ejecutar las tools).
ToolRegistry buildDefaultToolRegistry({IdentitySigner? signer}) {
  final r = ToolRegistry();
  r.registerAll([
    RedactPiiTool(),
    ClassifyCaseTool(),
    LookupCodigoPenalTool(),
    LookupCodigoTrabajoTool(),
    LookupInstitucionTool(),
    DraftDenunciaTool(),
    DraftSolicitudTool(),
    DraftSmsFamiliaTool(),
    SignPacketTool(signer: signer ?? _defaultSigner()),
  ]);
  return r;
}

const _useDeviceKeystoreSigning = bool.fromEnvironment(
  'KAN_DEVICE_KEYSTORE_SIGNING',
  defaultValue: kReleaseMode,
);

IdentitySigner _defaultSigner() {
  if (_useDeviceKeystoreSigning &&
      defaultTargetPlatform == TargetPlatform.android) {
    return const DeviceKeystoreIdentitySigner();
  }
  return const LocalHmacIdentitySigner(
    issuerKeyId: 'zpk-local-dev-hmac-key',
    issuerSecret: 'zpk-local-dev-secret-for-tests-only',
  );
}
