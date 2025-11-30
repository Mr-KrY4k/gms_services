
import 'gms_services_platform_interface.dart';

class GmsServices {
  Future<String?> getPlatformVersion() {
    return GmsServicesPlatform.instance.getPlatformVersion();
  }
}
