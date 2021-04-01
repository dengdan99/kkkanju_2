import 'package:flutter/cupertino.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/utils/sp_helper.dart';

class AppInfoProvider with ChangeNotifier {
  String _themeColor = '';
  String get themeColor => _themeColor;

  void setTheme(String themeColor) {
    _themeColor = themeColor;
    SpHelper.putString(Constant.key_theme_color, themeColor);
    notifyListeners();
  }
}