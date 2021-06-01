import 'package:flutter/material.dart';
import 'package:kkkanju_2/utils/ColorsUtil.dart';

class Constant {
  static const String default_theme_color = 'black';
  static const String key_theme_color = 'key_theme_color';
  static const String key_local_ip = 'key_local_ip';
  static const String key_guide = 'key_guide';
  static const String key_splash_model = 'key_splash_models';
  static const String key_current_source = 'key_current_source';
  static const String key_version_result = 'key_version_result';
  static const String key_wifi_auto_download = 'key_wifi_auto_download';
  static const String key_m3u8_to_mp4 = 'key_m3u8_to_mp4';
  static const String key_db_name = 'player.db';
  static const String key_home_page_data_cache = 'home_page_data_cache';
  static const String key_search_history = 'key_search_history';
}

Map<String, Color> themeColorMap = {
  'gray': Colors.grey,
  'blue': Colors.blue,
  'blueAccent': Colors.blueAccent,
  'cyan': Colors.cyan,
  'deepPurple': Colors.purple,
  'deepPurpleAccent': Colors.deepPurpleAccent,
  'deepOrange': Colors.orange,
  'green': Colors.green,
  'indigo': Colors.indigo,
  'indigoAccent': Colors.indigoAccent,
  'orange': Colors.orange,
  'purple': Colors.purple,
  'pink': Colors.pink,
  'red': Colors.red,
  'teal': Colors.teal,
  'black': ColorsUtil.hexColor(0x12121a),
};