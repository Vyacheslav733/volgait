#include "generated_plugin_registrant.h"

#include <url_launcher_aurora/url_launcher_aurora_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  UrlLauncherAuroraPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("UrlLauncherAuroraPlugin"));
}
