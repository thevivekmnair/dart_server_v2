import 'dart:async';

import 'package:flutter/services.dart';

class DartServerPlugin {
  static const MethodChannel _channel =
      const MethodChannel('dart_server_plugin');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<Map> get enableHotspot async {
    final Map result = await _channel.invokeMethod('turnOnHotspot');
    if (result["ipadress"] == "null") {
      return null;
    } else {
      return result;
    }
  }

  static Future<Map<String, String>> get openFileManager async {
    Map<String, String> resultMap = {};
    final Map files = await _channel.invokeMethod('OpenFileManager');
    files.forEach((key, value) {
      resultMap.addAll({key: value});
    });
    if (resultMap.containsKey("null") && resultMap.containsValue("null")) {
      return null;
    }
    return resultMap;
  }
}
