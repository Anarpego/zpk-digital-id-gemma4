import 'package:flutter/services.dart';

class DevicePresenceResult {
  const DevicePresenceResult({
    required this.verified,
    required this.method,
    required this.trace,
  });

  final bool verified;
  final String method;
  final List<String> trace;
}

abstract interface class DevicePresenceGate {
  Future<DevicePresenceResult> verify({required String reason});
}

class PlatformDevicePresenceGate implements DevicePresenceGate {
  const PlatformDevicePresenceGate({
    MethodChannel channel = const MethodChannel('gt.kan.kan_app/device_auth'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<DevicePresenceResult> verify({required String reason}) async {
    final response = await _channel.invokeMapMethod<String, Object?>(
      'confirm',
      {'reason': reason},
    );
    final verified = response?['verified'] == true;
    final method = response?['method']?.toString() ?? 'android-keyguard';
    return DevicePresenceResult(
      verified: verified,
      method: method,
      trace: [
        'auth.device_presence($method) -> ${verified ? 'verified' : 'denied'}',
      ],
    );
  }
}

class BypassDevicePresenceGate implements DevicePresenceGate {
  const BypassDevicePresenceGate({this.method = 'dart-test-bypass'});

  final String method;

  @override
  Future<DevicePresenceResult> verify({required String reason}) async =>
      DevicePresenceResult(
        verified: true,
        method: method,
        trace: ['auth.device_presence($method) -> verified'],
      );
}
