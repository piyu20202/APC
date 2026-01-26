import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cybersource_inapp_platform_interface.dart';

/// An implementation of [CybersourceInappPlatform] that uses method channels.
class MethodChannelCybersourceInapp extends CybersourceInappPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('cybersource_inapp');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
