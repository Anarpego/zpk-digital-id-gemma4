import 'package:flutter/services.dart';

abstract interface class ArtifactSharer {
  Future<void> shareText({required String title, required String text});
}

class PlatformArtifactSharer implements ArtifactSharer {
  const PlatformArtifactSharer({
    MethodChannel channel = const MethodChannel(
      'gt.kan.kan_app/platform_share',
    ),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<void> shareText({required String title, required String text}) async {
    await _channel.invokeMethod<void>('shareText', {
      'title': title,
      'text': text,
    });
  }
}
