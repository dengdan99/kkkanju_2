import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kkkanju_2/common/constant.dart';
import 'package:kkkanju_2/common/kk_colors.dart';
import 'package:kkkanju_2/pages/splash_page.dart';
import 'package:kkkanju_2/provider/app_info.dart';
import 'package:kkkanju_2/provider/category.dart';
import 'package:kkkanju_2/provider/download_task.dart';
import 'package:kkkanju_2/provider/source.dart';
import 'package:kkkanju_2/router/application.dart';
import 'package:kkkanju_2/router/routers.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  MyApp() {
    final router = FluroRouter();
    Routers.configureRoutes(router);
    Application.router = router;
  }

  @override
  Widget build(BuildContext context) {
    Color _themeColor;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppInfoProvider()),
        ChangeNotifierProvider(create: (_) => SourceProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => DownloadTaskProvider()),
      ],
      child: Consumer<AppInfoProvider>(
        builder: (context, appInfo, _) {
//          String colorKey = appInfo.themeColor;
          String colorKey = 'black';
          if (themeColorMap[colorKey] != null) {
            _themeColor = themeColorMap[colorKey];
          }

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            onGenerateRoute: Application.router.generator,
            theme: ThemeData.light().copyWith(
              appBarTheme: AppBarTheme(
                brightness: Brightness.dark,
              ),
              backgroundColor: _themeColor,
              primaryColor: _themeColor,
              accentColor: Colors.white,
              indicatorColor: Colors.white,
              textTheme: TextTheme(
                headline1: TextStyle(fontSize: 44.0, fontWeight: FontWeight.bold, color: KkColors.greyInBalck),
                headline6: TextStyle(fontSize: 20.0, color: KkColors.primaryWhite),
                bodyText1: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: KkColors.greyInBalck),
                bodyText2: TextStyle(fontSize: 14.0, fontFamily: 'Hind', color: KkColors.greyInBalck),
              ),
            ),
            builder: BotToastInit(),
            home: SplashPage(),
          );
        },
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  /// 创建全局变量，flutter会根据系统平台自动读取第五步下载的对应配置文件
  final FirebaseAnalytics analytics = FirebaseAnalytics();
  final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  /// 状态栏高亮
  SystemUiOverlayStyle systemUiOverlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
//      statusBarBrightness: Brightness.light,
//      statusBarIconBrightness: Brightness.light
  );
  SystemChrome.setSystemUIOverlayStyle(systemUiOverlayStyle);

  runApp(MyApp());
}
