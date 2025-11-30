import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'gms_services_platform_interface.dart';

/// An implementation of [GmsServicesPlatform] that uses method channels.
class MethodChannelGmsServices extends GmsServicesPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('gms_services');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
