import 'package:flutter_test/flutter_test.dart';
import 'package:gms_services/gms_services.dart';
import 'package:gms_services/gms_services_platform_interface.dart';
import 'package:gms_services/gms_services_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGmsServicesPlatform
    with MockPlatformInterfaceMixin
    implements GmsServicesPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GmsServicesPlatform initialPlatform = GmsServicesPlatform.instance;

  test('$MethodChannelGmsServices is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGmsServices>());
  });

  test('getPlatformVersion', () async {
    GmsServices gmsServicesPlugin = GmsServices();
    MockGmsServicesPlatform fakePlatform = MockGmsServicesPlatform();
    GmsServicesPlatform.instance = fakePlatform;

    expect(await gmsServicesPlugin.getPlatformVersion(), '42');
  });
}
