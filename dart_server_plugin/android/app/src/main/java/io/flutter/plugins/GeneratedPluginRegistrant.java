package io.flutter.plugins;

import io.flutter.plugin.common.PluginRegistry;
import com.dart_server_plugin.dart_server_plugin.DartServerPlugin;

/**
 * Generated file. Do not edit.
 */
public final class GeneratedPluginRegistrant {
  public static void registerWith(PluginRegistry registry) {
    if (alreadyRegisteredWith(registry)) {
      return;
    }
    DartServerPlugin.registerWith(registry.registrarFor("com.dart_server_plugin.dart_server_plugin.DartServerPlugin"));
  }

  private static boolean alreadyRegisteredWith(PluginRegistry registry) {
    final String key = GeneratedPluginRegistrant.class.getCanonicalName();
    if (registry.hasPlugin(key)) {
      return true;
    }
    registry.registrarFor(key);
    return false;
  }
}
