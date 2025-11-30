#ifndef FLUTTER_PLUGIN_GMS_SERVICES_PLUGIN_H_
#define FLUTTER_PLUGIN_GMS_SERVICES_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace gms_services {

class GmsServicesPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  GmsServicesPlugin();

  virtual ~GmsServicesPlugin();

  // Disallow copy and assign.
  GmsServicesPlugin(const GmsServicesPlugin&) = delete;
  GmsServicesPlugin& operator=(const GmsServicesPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace gms_services

#endif  // FLUTTER_PLUGIN_GMS_SERVICES_PLUGIN_H_
