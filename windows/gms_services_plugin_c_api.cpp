#include "include/gms_services/gms_services_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "gms_services_plugin.h"

void GmsServicesPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  gms_services::GmsServicesPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
