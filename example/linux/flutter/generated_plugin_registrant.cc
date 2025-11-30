//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <gms_services/gms_services_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) gms_services_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "GmsServicesPlugin");
  gms_services_plugin_register_with_registrar(gms_services_registrar);
}
