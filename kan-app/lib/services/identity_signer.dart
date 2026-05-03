import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';

abstract interface class IdentitySigner {
  String get issuerKeyId;

  Future<IdentitySignature> signCanonical(String canonicalPayload);
}

class IdentitySignature {
  const IdentitySignature({
    required this.proofValue,
    required this.keyStore,
    required this.proofSuite,
  });

  final String proofValue;
  final String keyStore;
  final String proofSuite;
}

class LocalHmacIdentitySigner implements IdentitySigner {
  const LocalHmacIdentitySigner({
    required this.issuerKeyId,
    required this.issuerSecret,
    this.keyStore = 'dart-local-hmac',
  });

  @override
  final String issuerKeyId;
  final String issuerSecret;
  final String keyStore;

  @override
  Future<IdentitySignature> signCanonical(String canonicalPayload) async {
    final hmac = Hmac(sha256, utf8.encode(issuerSecret));
    return IdentitySignature(
      proofValue: hmac.convert(utf8.encode(canonicalPayload)).toString(),
      keyStore: keyStore,
      proofSuite: 'HmacSha256Signature2026',
    );
  }
}

class DeviceKeystoreIdentitySigner implements IdentitySigner {
  const DeviceKeystoreIdentitySigner({
    this.issuerKeyId = 'zpk-android-keystore-issuer-key-2026-05',
    MethodChannel channel = const MethodChannel(
      'gt.kan.kan_app/identity_keystore',
    ),
  }) : _channel = channel;

  @override
  final String issuerKeyId;
  final MethodChannel _channel;

  @override
  Future<IdentitySignature> signCanonical(String canonicalPayload) async {
    final response = await _channel.invokeMapMethod<String, Object?>(
      'signHmacSha256',
      {'keyId': issuerKeyId, 'payload': canonicalPayload},
    );
    final proofValue = response?['proofValue'] as String?;
    if (proofValue == null || proofValue.isEmpty) {
      throw const FormatException('Android Keystore returned no proof value.');
    }
    return IdentitySignature(
      proofValue: proofValue,
      keyStore: response?['keyStore'] as String? ?? 'android-keystore',
      proofSuite:
          response?['proofSuite'] as String? ?? 'HmacSha256Signature2026',
    );
  }
}
