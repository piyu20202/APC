import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'cybersource_inapp_method_channel.dart';

abstract class CybersourceInappPlatform extends PlatformInterface {
  /// Constructs a CybersourceInappPlatform.
  CybersourceInappPlatform() : super(token: _token);

  static final Object _token = Object();

  static CybersourceInappPlatform _instance = MethodChannelCybersourceInapp();

  /// The default instance of [CybersourceInappPlatform] to use.
  ///
  /// Defaults to [MethodChannelCybersourceInapp].
  static CybersourceInappPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [CybersourceInappPlatform] when
  /// they register themselves.
  static set instance(CybersourceInappPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
