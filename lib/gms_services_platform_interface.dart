import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'gms_services_method_channel.dart';

abstract class GmsServicesPlatform extends PlatformInterface {
  /// Constructs a GmsServicesPlatform.
  GmsServicesPlatform() : super(token: _token);

  static final Object _token = Object();

  static GmsServicesPlatform _instance = MethodChannelGmsServices();

  /// The default instance of [GmsServicesPlatform] to use.
  ///
  /// Defaults to [MethodChannelGmsServices].
  static GmsServicesPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [GmsServicesPlatform] when
  /// they register themselves.
  static set instance(GmsServicesPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
