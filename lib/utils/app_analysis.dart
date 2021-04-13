import 'package:flutter/cupertino.dart';

class AppAnalysis extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.settings.name != null) {
//      UmengCommonSdk.onPageStart(route.settings.name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic> previousRoute) {
    if (route.settings.name != null) {
//      UmengCommonSdk.onPageStart(route.settings.name);
    }
  }
}