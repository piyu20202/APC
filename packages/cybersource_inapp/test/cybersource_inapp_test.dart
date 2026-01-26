import 'package:flutter_test/flutter_test.dart';
import 'package:cybersource_inapp/cybersource_inapp.dart';
import 'package:cybersource_inapp/cybersource_inapp_platform_interface.dart';
import 'package:cybersource_inapp/cybersource_inapp_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockCybersourceInappPlatform
    with MockPlatformInterfaceMixin
    implements CybersourceInappPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final CybersourceInappPlatform initialPlatform = CybersourceInappPlatform.instance;

  test('$MethodChannelCybersourceInapp is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelCybersourceInapp>());
  });

  test('getPlatformVersion', () async {
    CybersourceInapp cybersourceInappPlugin = CybersourceInapp();
    MockCybersourceInappPlatform fakePlatform = MockCybersourceInappPlatform();
    CybersourceInappPlatform.instance = fakePlatform;

    expect(await cybersourceInappPlugin.getPlatformVersion(), '42');
  });
}
