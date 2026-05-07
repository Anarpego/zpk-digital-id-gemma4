import 'package:qr_flutter/qr_flutter.dart' show QrErrorCorrectLevel;

import '../zpk/packet_codec.dart';
import '../zpk/packet_envelope.dart';

/// Helper estatico que adapta packet_codec a lo que mobile_scanner /
/// qr_flutter necesitan. Centraliza prefijo, encoding y nivel de correccion.
class QrService {
  static const PacketCodec _codec = PacketCodec();
  static const int errorCorrectionLevel = QrErrorCorrectLevel.M;

  /// Encode envelope -> string listo para qr_flutter.
  static String encode(PacketEnvelope packet) => _codec.encode(packet);

  /// Decode payload escaneado por mobile_scanner -> envelope.
  static PacketEnvelope decode(String wire) => _codec.decode(wire);

  /// Heuristica para detectar si un string escaneado es un packet ZPK
  /// (descarta QRs de URLs, vCards, etc.).
  static bool looksLikeZpk(String wire) => wire.startsWith(PacketCodec.prefix);
}
