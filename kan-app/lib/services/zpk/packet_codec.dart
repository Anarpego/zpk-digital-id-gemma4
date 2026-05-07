import 'dart:convert';
import 'dart:io';

import 'packet_envelope.dart';

/// Codec de transporte para PacketEnvelope.
///
/// Forma alambrica: `zpk1:` + base64url(gzip(canonicalJson(packet))).
///
/// Tamano objetivo: < 1 KB tras compresion para que entre en un solo QR
/// estandar sin tener que recurrir a multi-frame.
class PacketCodec {
  const PacketCodec();

  static const String prefix = 'zpk1:';

  String encode(PacketEnvelope packet) {
    final canonical = canonicalJsonEncode(packet.toJson());
    final bytes = utf8.encode(canonical);
    final gz = gzip.encode(bytes);
    final b64 = base64Url.encode(gz).replaceAll('=', '');
    return '$prefix$b64';
  }

  PacketEnvelope decode(String wire) {
    if (!wire.startsWith(prefix)) {
      throw const FormatException('Missing zpk1: prefix');
    }
    final raw = wire.substring(prefix.length);
    final padded = _padBase64(raw);
    final List<int> gz;
    try {
      gz = base64Url.decode(padded);
    } catch (_) {
      throw const FormatException('Invalid base64url payload');
    }
    final List<int> bytes;
    try {
      bytes = gzip.decode(gz);
    } catch (_) {
      throw const FormatException('Invalid gzip payload');
    }
    final canonical = utf8.decode(bytes);
    final json = jsonDecode(canonical);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('Decoded packet is not a JSON object');
    }
    return PacketEnvelope.fromJson(json);
  }

  String _padBase64(String s) {
    final mod = s.length % 4;
    if (mod == 0) return s;
    return s + ('=' * (4 - mod));
  }
}
